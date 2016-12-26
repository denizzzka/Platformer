module physics;

import map;
import math;

enum TilesState // TODO: rename to PhysicalState?
{
    Default,
    PushesWall
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

        position.y += acceleration.y * deltaTime;

        tileType = checkCollisionY();

        // collide with ceiling
        if(acceleration.y < 0)
        {
            if(tileType == PhysLayer.TileType.Block)
                acceleration.y = 0; // speed damping due to the head
        }

        // collide with ground
        if(acceleration.y > 0)
        {
            if(tileType == PhysLayer.TileType.Block)
                acceleration.y = 0; // ground

            onGround = true;
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

    private PhysLayer.TileType checkCollisionX()
    {
        vec2f start = position;

        if(acceleration.x < 0) // move left
            start += aabb.min;

        if(acceleration.x > 0) // move right
            start += aabb.max - aabb.height;

        return checkCollision(start, start + aabb.height);
    }

    private PhysLayer.TileType checkCollisionY()
    {
        vec2f start = position;

        if(acceleration.y < 0) // move up
            start += aabb.min + aabb.height;

        if(acceleration.y > 0) // move down
            start += aabb.min;

        return checkCollision(start, start + aabb.width);
    }

    private PhysLayer.TileType checkCollision(vec2f start, vec2f end)
    {
        return checkCollision(_map.worldCoordsToTileCoords(start), _map.worldCoordsToTileCoords(end));
    }

    private PhysLayer.TileType checkCollision(vec2i startTile, vec2i endTile)
    {
        PhysLayer.TileType ret = PhysLayer.TileType.Empty;

        foreach(y; startTile.y .. endTile.y)
            foreach(x; startTile.x .. endTile.x)
            {
                auto type = _map.tileTypeByTileCoords(vec2i(x, y));

                with(PhysLayer.TileType)
                final switch(type)
                {
                    case Block:
                    case SlopeLeft:
                    case SlopeRight:
                        return Block;

                    case Ladder:
                        ret = Ladder;
                        break;

                    case OneWay:
                        if(ret == Empty)
                            ret = OneWay;
                        break;

                    case Empty:
                        break;
                }
            }

        return ret;
    }
}

private bool isGround(PhysLayer.TileType t) pure
{
    return t != PhysLayer.TileType.Empty;
}

private bool isOneWay(PhysLayer.TileType t) pure
{
    return  t == PhysLayer.TileType.OneWay ||
            t == PhysLayer.TileType.Empty ||
            t == PhysLayer.TileType.Ladder;
}
