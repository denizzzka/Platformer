module physics;

import map;
import math;

enum CollisionState
{
    Default,
    PushesBlock,
    TouchesOneWay,
    TouchesLadder
}

struct ImprovedBox
{
    box2f box;
    alias box this;

    vec2f width() const
    {
        return vec2f(box.width, 0);
    }

    vec2f height() const
    {
        return vec2f(0, box.height);
    }
}

class PhysicalObject
{
    const Map _map;

    vec2f position;
    vec2f acceleration = vec2f(0, 0);
    ImprovedBox aabb;

    bool onGround;
    bool rightDirection = false;

    this(Map m)
    {
        _map = m;
    }

    void doMotion(const vec2f doAcceleration, const float deltaTime, const float g_force)
    {
        // horizontal
        {
            position.x += acceleration.x * deltaTime;

            auto tileType = checkCollisionX();

            // collide with walls
            if(acceleration.x < 0)
            {
                if(tileType == PhysLayer.TileType.Block)
                {
                    acceleration.x = 0; // FIXME temporary
                }
            }

            if(acceleration.x > 0)
            {
                if(tileType == PhysLayer.TileType.Block)
                {
                    acceleration.x = 0; // FIXME temporary
                }
            }
        }

        // vertical
        {
            position.y += acceleration.y * deltaTime;

            auto tileType = checkCollisionY();

            if(tileType.isGround)
            {
                onGround = true;
                acceleration.y = 0;
            }
            else
            {
                onGround = false;

                if(acceleration.y < 0)
                {
                    onGround = false;

                    // collide with ceiling
                    if(!tileType.isOneWay)
                        acceleration.y = 0; // speed damping due to the head
                }

                if(acceleration.y > 0)
                {
                    // collide with ground
                    if(tileType.isGround)
                    {
                        acceleration.y = 0; // ground
                        onGround = true;
                    }
                }
            }
        }

        if(onGround)
        {
            // only on the ground unit can change its speed and direction
            acceleration = doAcceleration;
        }
        else
        {
            acceleration.y += g_force * deltaTime;
        }
    }

    private CollisionState checkCollisionX()
    {
        vec2f start = position;

        if(acceleration.x < 0) // move left
            start += aabb.min;

        if(acceleration.x > 0) // move right
            start += aabb.max - aabb.height;

        return checkCollision(start, start + aabb.height);
    }

    private CollisionState checkCollisionY()
    {
        vec2f start = position;

        if(acceleration.y < 0) // move up
            start += aabb.min + aabb.height;

        if(acceleration.y > 0) // move down
            start += aabb.min;

        import std.stdio;
        writeln(start);
        writeln(aabb);

        return checkCollision(start, start + aabb.width);
    }

    private CollisionState checkCollision(vec2f start, vec2f end)
    {
        return checkCollision(_map.worldCoordsToTileCoords(start), _map.worldCoordsToTileCoords(end));
    }

    private CollisionState checkCollision(vec2i startTile, vec2i endTile)
    {
        import std.stdio;
        writeln("startTile=", startTile);
        writeln("endTile=", endTile);

        auto ret = CollisionState.Default;

        foreach(y; startTile.y .. endTile.y + 1)
            foreach(x; startTile.x .. endTile.x + 1)
            {
                auto type = _map.tileTypeByTileCoords(vec2i(x, y));

                with(PhysLayer.TileType)
                with(CollisionState)
                final switch(type)
                {
                    case Block:
                    case SlopeLeft:
                    case SlopeRight:
                        return PushesBlock;

                    case OneWay:
                        ret = TouchesOneWay;
                        break;

                    case Ladder:
                        if(ret == Empty)
                            ret = TouchesLadder;
                        break;

                    case Empty:
                        break;
                }
            }

        writeln("tile ====", ret);

        return ret;
    }
}

private bool isGround(CollisionState t) pure
{
    return t != CollisionState.Default;
}

private bool isOneWay(CollisionState t) pure
{
    return  t == CollisionState.TouchesOneWay ||
            t == CollisionState.Default;
}
