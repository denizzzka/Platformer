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

    vec2f width()
    {
        return vec2f(box.width, 0);
    }

    vec2f height()
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

    PhysLayer.TileType tileType = PhysLayer.TileType.Empty;
    TilesState tilesState;
    bool onGround;
    bool rightDirection = false;

    this(Map m)
    {
        _map = m;
    }

    void doMotion(const vec2f doAcceleration, const float deltaTime, const float g_force)
    {
        position += acceleration * deltaTime;
        const vec2i tileCoords = _map.worldCoordsToTileCoords(position);
        tileType = _map.tileTypeByTileCoords(tileCoords);

        if(tileType == PhysLayer.TileType.Empty)
            onGround = false;

        if(!onGround)
        {
            // collide with ground
            if(acceleration.y > 0 && tileType.isGround)
            {
                position.y = _map.tileSize.y * tileCoords.y; // fell to upper side of this block
                onGround = true;
            }

            // collide with ceiling
            if(acceleration.y < 0 && !tileType.isOneWay)
            {
                position.y = _map.tileSize.y * (tileCoords.y + 1); // fell to down side of this block
                acceleration.y = 0; // speed damping due to the head
            }
        }

        // collide with walls
        if(acceleration.x > 0)
        {
            vec2i rightTileCoords = tileCoords;
            rightTileCoords.y -= 1;

            auto tt = _map.tileTypeByTileCoords(rightTileCoords);

            if(tt == PhysLayer.TileType.Block)
                position.x = _map.tileSize.x * rightTileCoords.x - 1;
        }

        if(acceleration.x < 0)
        {
            vec2i leftTileCoords = tileCoords;
            leftTileCoords.y -= 1;

            auto tt = _map.tileTypeByTileCoords(leftTileCoords);

            if(tt == PhysLayer.TileType.Block)
                position.x = _map.tileSize.x * (leftTileCoords.x + 1);
        }

        if(onGround)
        {
            // only on the ground unit can change its speed and direction
            acceleration = doAcceleration;

            if(tileType != PhysLayer.TileType.Ladder)
            {
                // prevent settling through the ground
                if(acceleration.y > 0)
                    acceleration.y = 0;

                // beginning jump
                if(acceleration.y < 0)
                    onGround = false;
            }
        }
        else
        {
            acceleration.y += g_force * deltaTime;
        }
    }

    private void doMotionX(const float doAcceleration, const float deltaTime)
    {
        position.x += acceleration.x * deltaTime;

        PhysLayer.TileType type;

        vec2f start;

        if(acceleration.x < 0) // move left
        {
            start = position + aabb.min;
        }

        type = checkCollision(start, start + aabb.height);
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
