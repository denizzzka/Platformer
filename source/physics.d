module physics;

import map;
import math;
debug(physics) import std.stdio;

enum CollisionState // TODO: remove it?
{
    Default,
    TouchesOneWay,
    PushesLeftSlope,
    PushesRightSlope,
    PushesBlock,
    TouchesLadder
}

struct States
{
    bool onGround;
    bool rightDirection = false;
    CollisionState collisionStateX;
    CollisionState collisionStateY;
}

class PhysicalObject
{
    const Map _map;

    vec2f position;
    vec2f speed = vec2f(0, 0);
    private box2f _aabb;

    States states;
    debug States oldStates;
    alias states this;

    this(Map m)
    {
        _map = m;
    }

    void aabb(box2f b)
    {
        if(upVec.y < 0)
            _aabb = b.flipY.sort;
        else
            _aabb = b;
    }

    box2f aabb() const { return _aabb; }

    // TODO: remove it
    box2i aabbTiled() const
    {
        box2i b;

        b.min = _map.worldCoordsToTileCoords(aabb.min);
        b.max = _map.worldCoordsToTileCoords(aabb.max);

        return b;
    }

    box2i worldAabbTiled() const
    {
        box2i b;

        b.min = _map.worldCoordsToTileCoords(position + aabb.min);
        b.max = _map.worldCoordsToTileCoords(position + aabb.max);

        return b;
    }

    vec2i tileCoords() const
    {
        return _map.worldCoordsToTileCoords(position);
    }

    void doMotion(in vec2f appendSpeed, const float dt, const float g_force)
    {
        motionRoutineX(dt);
        motionRoutineY(dt);
        motionAppendSpeed(appendSpeed, dt, g_force);

        //~ // vertical
        //~ {
            //~ position.y += speed.y * deltaTime;

            //~ if(speed.y == 0)
            //~ {
                //~ vec2i blameTileCoords;
                //~ auto bottomTileType = checkCollisionY(position + down, false, blameTileCoords);

                //~ onGround = bottomTileType.canStanding;
            //~ }
            //~ else
            //~ {
                //~ {
                    //~ const bool movesUp = speed.isUp;
                    //~ vec2i blameTileCoords;
                    //~ auto tileType = checkCollisionY(position, movesUp, blameTileCoords);

                    //~ if(movesUp)
                    //~ {
                        //~ onGround = false;

                        //~ if(!tileType.isOneWay) // collide with ceiling
                        //~ {
                            //~ position.y = (blameTileCoords.y + 1) * _map.tileSize.y - aabb.max.y;
                            //~ speed.y = 0; // speed damping due to the head
                        //~ }
                    //~ }
                    //~ else // moves down
                    //~ {
                        //~ if(tileType.canStanding)
                        //~ {
                            //~ if(!onGround)
                            //~ {
                                //~ position.y = blameTileCoords.y * _map.tileSize.y - aabb.min.y - 1 /*"1" is "do not touch bottom tiles"*/;
                                //~ speed.y = 0;
                                //~ onGround = true;
                            //~ }
                        //~ }
                        //~ else
                        //~ {
                            //~ onGround = false;
                        //~ }
                    //~ }
                //~ }
            //~ }
        //~ }

        //~ if(onGround)
        //~ {
            //~ // only on the ground unit can change its speed and direction
            //~ speed = doAcceleration;
        //~ }
        //~ else
        //~ {
            //~ speed.y += g_force * deltaTime;
        //~ }
    }

    private void motionRoutineX(float dt)
    {
        if(speed.x != 0)
        {
            position.x += speed.x * dt;

            debug oldStates.collisionStateX = collisionStateX;

            vec2i blameTileCoords;
            collisionStateX = checkCollisionX(blameTileCoords);

            if(collisionStateX == CollisionState.PushesBlock)
            {
                if(speed.isRightDirection)
                    position.x = blameTileCoords.x * _map.tileSize.x - aabb.max.x;
                else
                    position.x = (blameTileCoords.x + 1) * _map.tileSize.x - aabb.min.x;

                speed.x = 0;
            }
        }
    }

    private void motionRoutineY(in float dt)
    {
        if(speed.y == 0)
            return;

        position.y += speed.y * dt;

        debug oldStates.onGround = onGround;

        if(speed.isUpDirection)
        {
            onGround = false;
        }

        if(!onGround)
        {
            // collisions check
            debug oldStates.collisionStateY = collisionStateY;

            vec2i blameTileCoords;
            collisionStateY = checkCollisionY(blameTileCoords);

            if(speed.isDownDirection)
            {
                if(collisionStateY.canStanding)
                {
                    position.y = blameTileCoords.y * _map.tileSize.y - aabb.max.y - 1 /*"1" is "do not touch bottom tiles"*/;
                    speed.y = 0;
                    onGround = true;
                }
            }
        }
    }

    private void motionAppendSpeed(in vec2f appendSpeed, in float dt, in float g_force)
    {
        if(onGround)
        {
            // only on the ground unit can change its speed and direction
            speed = appendSpeed;
        }
        else
        {
            speed.y += g_force * dt;
        }
    }

    private CollisionState checkCollisionX(out vec2i blameTileCoords) const
    {
        assert(speed.x != 0);

        box2i box = worldAabbTiled;
        vec2i start;

        if(speed.isLeftDirection)
            start = box.min;
        else // move right
            start = box.min + box.width;

        return checkCollision(start, start + box.height, blameTileCoords);
    }

    private CollisionState checkCollisionY(out vec2i blameTileCoords) const
    {
        assert(speed.y != 0);

        box2i box = worldAabbTiled;
        vec2i start;

        if(speed.isUpDirection)
            start = box.min;
        else // moves down
            start = box.min + box.height;

        return checkCollision(start, start + box.width, blameTileCoords);
    }

    // TODO: delete it
    private CollisionState checkCollision(vec2f start, vec2f end, out vec2i blameTileCoords) const
    {
        return checkCollision(_map.worldCoordsToTileCoords(start), _map.worldCoordsToTileCoords(end), blameTileCoords);
    }

    private CollisionState checkCollisionForFullAABB(out vec2i blameTileCoords) const
    {
        auto b = aabbTiled.translate(tileCoords);

        assert(b.size.x >= 0);
        assert(b.size.y <= 0);

        PhysLayer.TileType ret = PhysLayer.TileType.Empty;

        with(PhysLayer.TileType)
        with(CollisionState)
        {
            foreach(y; b.max.y .. b.min.y + 1)
            {
                foreach(x; b.min.x .. b.max.x + 1)
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
                    return TouchesLadder;

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
                    return TouchesLadder;

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
            t == CollisionState.TouchesLadder ||
            t == CollisionState.PushesLeftSlope ||
            t == CollisionState.PushesRightSlope ||
            t == CollisionState.TouchesOneWay;
}

private bool isOneWay(CollisionState t) pure
{
    return  t == CollisionState.TouchesOneWay ||
            t == CollisionState.PushesLeftSlope ||
            t == CollisionState.PushesRightSlope ||
            t == CollisionState.TouchesLadder ||
            t == CollisionState.Default;
}
