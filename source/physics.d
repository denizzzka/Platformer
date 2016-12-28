module physics;

import map;
import math;

enum CollisionState // TODO: remove it?
{
    Default,
    TouchesOneWay,
    PushesLeftSlope,
    PushesRightSlope,
    PushesBlock,
    TouchesLadder
}

class PhysicalObject
{
    const Map _map;

    vec2f position;
    vec2f acceleration = vec2f(0, 0);
    box2f _aabb;

    bool onGround;
    bool rightDirection = false;

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

    box2i aabbTiled() const
    {
        box2i b;

        b.min = _map.worldCoordsToTileCoords(aabb.min);
        b.max = _map.worldCoordsToTileCoords(aabb.max);

        return b;
    }

    vec2i tileCoords() const
    {
        return _map.worldCoordsToTileCoords(position);
    }

    void doMotion(in vec2f doAcceleration, const float dt, const float g_force)
    {
        motionRoutineX(dt);
        motionRoutineY(dt);
        motionAppendAcceleration(doAcceleration, dt, g_force);

        //~ // vertical
        //~ {
            //~ position.y += acceleration.y * deltaTime;

            //~ if(acceleration.y == 0)
            //~ {
                //~ vec2i blameTileCoords;
                //~ auto bottomTileType = checkCollisionY(position + down, false, blameTileCoords);

                //~ onGround = bottomTileType.canStanding;
            //~ }
            //~ else
            //~ {
                //~ {
                    //~ const bool movesUp = acceleration.isUp;
                    //~ vec2i blameTileCoords;
                    //~ auto tileType = checkCollisionY(position, movesUp, blameTileCoords);

                    //~ if(movesUp)
                    //~ {
                        //~ onGround = false;

                        //~ if(!tileType.isOneWay) // collide with ceiling
                        //~ {
                            //~ position.y = (blameTileCoords.y + 1) * _map.tileSize.y - aabb.max.y;
                            //~ acceleration.y = 0; // speed damping due to the head
                        //~ }
                    //~ }
                    //~ else // moves down
                    //~ {
                        //~ if(tileType.canStanding)
                        //~ {
                            //~ if(!onGround)
                            //~ {
                                //~ position.y = blameTileCoords.y * _map.tileSize.y - aabb.min.y - 1 /*"1" is "do not touch bottom tiles"*/;
                                //~ acceleration.y = 0;
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
            //~ acceleration = doAcceleration;
        //~ }
        //~ else
        //~ {
            //~ acceleration.y += g_force * deltaTime;
        //~ }
    }

    private void motionRoutineX(float dt)
    {
        position.x += acceleration.x * dt;

        //~ if(acceleration.x != 0)
        //~ {
            //~ vec2i blameTileCoords;
            //~ CollisionState tileType = checkCollisionX(blameTileCoords);

            //~ if(tileType == CollisionState.PushesLeftSlope && onGround)
            //~ {
                //~ position.y -= acceleration.x * dt;
            //~ }
            //~ else if(tileType == CollisionState.PushesBlock)
            //~ {
                //~ if(acceleration.x > 0)
                    //~ position.x = blameTileCoords.x * _map.tileSize.x - aabb.max.x - 1;
                //~ else
                    //~ position.x = (blameTileCoords.x + 1) * _map.tileSize.x - aabb.min.x;

                //~ acceleration.x = 0;

                //~ import std.stdio;
                //~ writeln("pushes block!");
            //~ }
        //~ }
    }

    private void motionRoutineY(float dt)
    {
        position.y += acceleration.y * dt;

        if(position.y > 500)
        {
            position.y = 500;
            acceleration.y = 0;
            onGround = true;
        }
        else
        {
            onGround = false;
        }
    }

    private void motionAppendAcceleration(in vec2f doAcceleration, in float dt, in float g_force)
    {
        if(onGround)
        {
            // only on the ground unit can change its speed and direction
            acceleration = doAcceleration;
        }
        else
        {
            acceleration.y += g_force * dt;
        }
    }

    private CollisionState checkCollisionX(out vec2i blameTileCoords) const
    {
        assert(acceleration.x != 0);

        vec2f start = position;

        if(acceleration.x < 0) // move left
            start += aabb.max - aabb.width;
        else // move right
            start += aabb.max;

        return checkCollision(start, start - aabb.height, blameTileCoords);
    }

    private CollisionState checkCollisionY(vec2f start, bool movesUp, out vec2i blameTileCoords) const
    {
        if(movesUp)
            start += aabb.min + aabb.height;
        else // moves down
            start += aabb.min;

        return checkCollision(start, start + aabb.width, blameTileCoords);
    }

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
