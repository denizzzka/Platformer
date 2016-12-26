module physics;

import map;
import dsfml.system;
import dsfml.window.keyboard;

enum TilesState // TODO: rename to PhysicalState?
{
    Default,
    PushesWall
}

class PhysicalObject
{
    const Map _map;

    Vector2f position;
    Vector2f acceleration = Vector2f(0, 0);

    PhysLayer.TileType tileType = PhysLayer.TileType.Empty;
    TilesState tilesState;
    bool onGround;
    bool rightDirection = false;

    this(Map m)
    {
        _map = m;
    }

    void doMotion(Vector2f doAcceleration, float g_force_dt)
    {
        position += acceleration;

        const Vector2i tileCoords = _map.worldCoordsToTileCoords(position);
        tileType = _map.tileTypeByTileCoords(tileCoords);

        if(tileType == PhysLayer.TileType.Empty)
            onGround = false;

        if(!onGround)
        {
            // collide with ground
            if(acceleration.y > 0 && tileType != PhysLayer.TileType.Empty)
            {
                position.y = _map.tileSize.y * tileCoords.y; // fell to upper side of this block
                onGround = true;
            }
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
            acceleration.y += g_force_dt;
        }
    }
}
