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

struct ImprovedBox(T)
{
    Box!(T, 2) box;
    alias box this;

    alias V = typeof(box.min);

    auto width() const
    {
        return V(box.width, 0);
    }

    auto height() const
    {
        return V(0, box.height);
    }
}

class PhysicalObject
{
    const Map _map;

    vec2f position;
    vec2f acceleration = vec2f(0, 0);
    ImprovedBox!float aabb;

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

            // collide with walls
            if(acceleration.x != 0)
            {
                vec2i blameTileCoords;
                CollisionState tileType = checkCollisionX(blameTileCoords);

import std.stdio; writeln(blameTileCoords, " ", tileType);

                if(tileType == CollisionState.PushesBlock)
                {
                    if(acceleration.x > 0)
                        position.x = blameTileCoords.x * _map.tileSize.x - aabb.max.x;
                    else
                        position.x = (blameTileCoords.x + 1) * _map.tileSize.x - aabb.min.x;

                    acceleration.x = 0;
                }
            }
        }

        // vertical
        {
            position.y += acceleration.y * deltaTime;

            //~ if(acceleration.y == 0)
                //~ acceleration.y = 0.000_000_000_1; // ground checking dirty hack

            if(acceleration.y != 0)
            {
                vec2i blameTileCoords;
                auto tileType = checkCollisionY(blameTileCoords);

                // fall
                if(acceleration.y > 0)
                {
                    if(tileType.isGround)
                    {
                        position.y = blameTileCoords.y * _map.tileSize.y - aabb.min.y;
                        acceleration.y = 0;
                        onGround = true;
                    }
                    else
                    {
                        onGround = false;
                    }
                }
                else
                {
                    onGround = false;

                    // collide with ceiling
                    if(!tileType.isOneWay)
                    {
                        position.y = (blameTileCoords.y + 1) * _map.tileSize.y - aabb.max.y;
                        acceleration.y = 0; // speed damping due to the head
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

    private CollisionState checkCollisionX(out vec2i blameTileCoords)
    {
        assert(acceleration.x != 0);

        vec2f start = position;

        if(acceleration.x < 0) // move left
            start += aabb.max - aabb.width;

        if(acceleration.x > 0) // move right
            start += aabb.max;

        return checkCollision(start, start - aabb.height, blameTileCoords);
    }

    private CollisionState checkCollisionY(out vec2i blameTileCoords)
    {
        assert(acceleration.y != 0);

        vec2f start = position;

        if(acceleration.y < 0) // move up
            start += aabb.min + aabb.height;

        if(acceleration.y > 0) // move down
            start += aabb.min;

        return checkCollision(start, start + aabb.width, blameTileCoords);
    }

    private CollisionState checkCollision(vec2f start, vec2f end, out vec2i blameTileCoords)
    {
        return checkCollision(_map.worldCoordsToTileCoords(start), _map.worldCoordsToTileCoords(end), blameTileCoords);
    }

    private CollisionState checkCollision(vec2i startTile, vec2i endTile, out vec2i blameTileCoords)
    {
        version(assert) auto dir = endTile - startTile;
        assert(dir.x >= 0);
        assert(dir.y >= 0);

        auto ret = CollisionState.Default;

        foreach(y; startTile.y .. endTile.y + 1)
            foreach(x; startTile.x .. endTile.x + 1)
            {
                vec2i coords = vec2i(x, y);
                auto type = _map.tileTypeByTileCoords(coords);

                with(PhysLayer.TileType)
                with(CollisionState)
                final switch(type)
                {
                    case Block:
                    case SlopeLeft:
                    case SlopeRight:
                        blameTileCoords = coords;
                        return PushesBlock;

                    case OneWay:
                        blameTileCoords = coords;
                        ret = TouchesOneWay;
                        break;

                    case Ladder:
                        if(ret == Empty)
                        {
                            blameTileCoords = coords;
                            ret = TouchesLadder;
                        }
                        break;

                    case Empty:
                        break;
                }
            }

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
