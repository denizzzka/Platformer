module physics;

import map;
import math;

enum TilesState // TODO: rename to PhysicalState?
{
    Default,
    PushesWall
}

class PhysicalObject
{
    const Map _map;

    vec2f position;
    vec2f acceleration = vec2f(0, 0);
    box2f aabb;

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
        }

        // collide with ceiling
        if(!onGround)
        {
            if(acceleration.y < 0 && tileType.isGround)
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
}

private bool isGround(PhysLayer.TileType t) pure
{
//    return t == PhysLayer.TileType.Block || t == PhysLayer.TileType.OneWay;
    return t != PhysLayer.TileType.Empty;
}
