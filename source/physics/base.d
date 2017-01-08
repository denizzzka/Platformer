module physics;

import map;
import math;
debug(physics) import std.stdio;
debug(physics) import std.conv: to;

enum CollisionState // TODO: remove it?
{
    Default,
    TouchesOneWay,
    PushesLeftSlope,
    PushesRightSlope,
    PushesBlock,
    TouchesLadder
}

enum UnitState
{
    OnFly,
    OnLadder,
    OnGround
}

struct States
{
    UnitState unitState;
    bool rightDirection = false;
    CollisionState collisionStateX;
    CollisionState collisionStateY;
}

abstract class PhysicalObjectBase
{
    const Map _map;

    vec2f position;
    vec2f speed = vec2f(0, 0);

    States states;
    debug States oldStates;
    debug vec2f oldSpeed;
    alias states this;

    private bool laddersSupportEnabled;

    void unitState(UnitState u){ states.unitState = u; }
    UnitState unitState() const { return states.unitState; }

    void collisionStateX(CollisionState cs){ states.collisionStateX = cs; }
    void collisionStateY(CollisionState cs){ states.collisionStateY = cs; }

    CollisionState collisionStateX() const { return states.collisionStateX; }
    CollisionState collisionStateY() const { return states.collisionStateY; }

    this(in Map m, bool laddersSupportEnabled)
    {
        _map = m;
        this.laddersSupportEnabled = laddersSupportEnabled;
    }

    box2f aabb() const;

    box2f worldAabb() const
    {
        return box2f(aabb.translate(position));
    }

    box2i worldAabbTiled() const
    {
        return fBox2tiledBox(worldAabb);
    }

    private box2i fBox2tiledBox(box2f b) const
    {
        box2i ret;

        ret.min = _map.worldCoordsToTileCoords(b.min);
        ret.max = _map.worldCoordsToTileCoords(b.max);

        return ret;
    }

    vec2i tileCoords() const
    {
        return _map.worldCoordsToTileCoords(position);
    }

    bool isTouchesLadder() const
    {
        return
            unitState == UnitState.OnLadder ||
            collisionStateY == CollisionState.TouchesLadder;
    }

    void doMotion(in vec2f appendSpeed, const float dt, const float g_force)
    {
        // FIXME: special ladder case (dirty hack)
        if(isTouchesLadder && appendSpeed.isDownDirection)
            unitState = UnitState.OnLadder;

        update(dt, g_force);

        motionAppendSpeed(appendSpeed, dt, g_force);
    }

    void update(const float dt, const float g_force)
    {
        debug oldStates = states;
        debug oldSpeed = speed;

        motionRoutineX(dt);
        motionRoutineY(dt);

        debug(physics)
        if(oldStates != states)
        {
            writeln("state: ", states, " coords=", position, " speed=", speed);
        }

        updateUnitState();
    }

    private void motionRoutineX(float dt)
    {
        if(speed.x != 0)
        {
            position.x += speed.x * dt;

            vec2i blameTileCoords;
            collisionStateX = checkCollisionX(blameTileCoords);

            if(collisionStateX.isBlock)
            {
                if(speed.isRightDirection)
                    position.x = blameTileCoords.x * _map.tileSize.x - aabb.max.x - 1 /*"1" is "do not touch right tiles"*/; // FIXME: зависит от направления осей графики
                else
                    position.x = (blameTileCoords.x + 1) * _map.tileSize.x - aabb.min.x; // FIXME: зависит от направления осей графики

                speed.x = 0;

                debug(physics) writeln("Push into block on X coord");
            }
            else if(unitState == UnitState.OnFly && collisionStateX == CollisionState.TouchesLadder)
            {
                unitState = UnitState.OnLadder;

                debug(physics) writeln("Flight into ladder");
            }
        }
    }

    private void motionRoutineY(in float dt)
    {
        // do motion
        position.y += speed.y * dt;

        // collision check
        if(speed.y != 0)
        {
            vec2i blameTileCoords;
            collisionStateY = checkCollisionY(blameTileCoords);

            // ground collider
            if(speed.isDownDirection && unitState != UnitState.OnGround)
            {
                if(collisionStateY.canStanding)
                {
                    speed.y = 0;

                    // need to place unit on top of the tile?
                    if
                    (
                        unitState == UnitState.OnFly || // falls to the ground or top of the ladder
                        collisionStateY != CollisionState.TouchesLadder // bumps to the ground by moving down on ladder
                    )
                    {
                        position.y = blameTileCoords.y * _map.tileSize.y - aabb.max.y - 1 /*"1" is "do not touch bottom tiles"*/; // FIXME: зависит от направления осей графики

                        unitState = UnitState.OnGround;

                        debug(physics) writeln("Floor bump");
                    }
                }
            }

            // ceiling collider
            if(speed.isUpDirection && unitState != UnitState.OnGround)
            {
                if(!collisionStateY.isOneWay)
                {
                    speed.y = 0; // speed damping due to bumping by head

                    if(collisionStateY != CollisionState.TouchesLadder)
                    {
                        position.y = (blameTileCoords.y + 1) * _map.tileSize.y - aabb.min.y; // FIXME: зависит от направления осей графики

                        debug(physics) writeln("Ceiling bump");
                    }
                    else
                    {
                        unitState = UnitState.OnLadder;

                        debug(physics) writeln("Cling to the ladder");
                    }
                }
            }
        }
    }

    private void updateUnitState()
    {
        // flags set
        if(unitState == UnitState.OnFly && collisionStateY == CollisionState.TouchesLadder)
        {
            unitState = UnitState.OnLadder;
        }
        else if(unitState == UnitState.OnLadder) // check if unit is still on ladder
        {
            if
            (
                (speed.x != 0 && (collisionStateX != CollisionState.TouchesLadder)) ||
                (speed.y != 0 && (collisionStateY != CollisionState.TouchesLadder))
            )
            {
                // special full ladder AABB mode check
                vec2i blameTileCoords;

                if(!checkLadderForFullAABB(blameTileCoords))
                    unitState = UnitState.OnFly;
            }
        }
        else if(unitState == UnitState.OnGround)
        {
            if(speed.isUpDirection)
            {
                unitState = UnitState.OnFly;
            }
            else
            {
                // check if unit is still on ground
                vec2i blameTileCoords;
                collisionStateY = checkCollisionY(blameTileCoords, true);

                if(!collisionStateY.canStanding)
                    unitState = UnitState.OnFly;
            }
        }
    }

    private void motionAppendSpeed(in vec2f appendSpeed, in float dt, in float g_force)
    {
        if(unitState != UnitState.OnFly)
        {
            // only on the ground unit can change its speed and direction
            speed = appendSpeed;

            if(unitState == UnitState.OnGround && speed.isDownDirection)
                speed.y = 0;
        }
        else
        {
            speed.x += appendSpeed.x * 0.01; // tiny opportunity to turning in the flight

            speed.y += g_force * dt;
        }
    }

    private CollisionState checkCollisionX(out vec2i blameTileCoords) const
    {
        assert(speed.x != 0);

        box2f aabb = worldAabb;
        // опускаем верхнюю грань пониже чтобы не тормозить об потолок
        aabb.min.y += 3; // FIXME: зависит от направления осей графики

        box2i box = fBox2tiledBox(aabb);
        vec2i start;

        if(speed.isLeftDirection) // FIXME: зависит от направления осей графики
            start = box.min;
        else // move right
            start = box.min + box.width;

        return checkCollision(start, start + box.height, blameTileCoords);
    }

    private CollisionState checkCollisionY(out vec2i blameTileCoords, bool checkBottomLine = false) const
    {
        assert(checkBottomLine || speed.y != 0);

        box2i box = worldAabbTiled;
        vec2i start;

        if(checkBottomLine)
            start = box.min + box.height + vec2i(0, 1); // FIXME: зависит от направления осей графики
        else if(speed.isUpDirection)
            start = box.min; // FIXME: зависит от направления осей графики
        else // moves down
            start = box.min + box.height; // FIXME: зависит от направления осей графики

        return checkCollision(start, start + box.width, blameTileCoords);
    }

    private bool checkLadderForFullAABB(out vec2i blameTileCoords) const
    {
        const b = worldAabbTiled;

        // FIXME: зависит от направления осей графики
        assert(b.size.x >= 0);
        assert(b.size.y >= 0);

        PhysLayer.TileType ret = PhysLayer.TileType.Empty;

        with(PhysLayer.TileType)
        {
            foreach(y; b.min.y .. b.max.y + 1)
            {
                foreach(x; b.min.x .. b.max.x + 1)
                {
                    vec2i coords = vec2i(x, y);
                    auto type = _map.tileTypeByTileCoords(coords);

                    if(type == Ladder)
                    {
                        blameTileCoords = coords;
                        return true;
                    }
                }
            }
        }

        return false;
    }

    private CollisionState checkCollision(vec2i startTile, vec2i endTile, out vec2i blameTileCoords) const
    {
        version(assert) auto dir = endTile - startTile;
        assert(dir.x >= 0);
        assert(dir.y >= 0);

        PhysLayer.TileType ret = PhysLayer.TileType.Empty;

        with(PhysLayer.TileType)
        with(CollisionState)
        {
            foreach(y; startTile.y .. endTile.y + 1)
            {
                foreach(x; startTile.x .. endTile.x + 1)
                {
                    vec2i coords = vec2i(x, y);
                    auto type = _map.tileTypeByTileCoords(coords);

                    if(type > ret)
                    {
                        ret = type;
                        blameTileCoords = coords;
                    }
                }
            }

            final switch(ret)
            {
                case Ladder:
                    if(laddersSupportEnabled)
                        return TouchesLadder;
                    else
                        return Default;

                case Block:
                    return PushesBlock;

                case SlopeLeft:
                    return PushesLeftSlope;

                case SlopeRight:
                    return PushesLeftSlope;

                case OneWay:
                    return TouchesOneWay;

                case Empty:
                    return Default;
            }
        }
    }
}

private bool canStanding(CollisionState t) pure
{
    return  t == CollisionState.PushesBlock ||
            t == CollisionState.PushesLeftSlope ||
            t == CollisionState.PushesRightSlope ||
            t == CollisionState.TouchesLadder ||
            t == CollisionState.TouchesOneWay;
}

private bool isBlock(CollisionState t) pure
{
    return  t == CollisionState.PushesBlock ||
            t == CollisionState.PushesLeftSlope ||
            t == CollisionState.PushesRightSlope;
}

private bool isOneWay(CollisionState t) pure
{
    return  t == CollisionState.TouchesOneWay ||
            t == CollisionState.PushesLeftSlope ||
            t == CollisionState.PushesRightSlope ||
            t == CollisionState.Default;
}
