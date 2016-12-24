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

    TilesState tilesState;
    bool onGround;
    bool rightDirection = false;

    this(Map m)
    {
        _map = m;
    }

    void doMotion(Vector2f doAcceleration, float deltaTime)
    {
        import std.math: sqrt;

        const float g_force = 400.0f * deltaTime * deltaTime;

        if(onGround)
        {
            // only on the ground unit can change its speed and direction
            acceleration = doAcceleration;

            if(acceleration.y > 0) // prevent settling through the ground
                acceleration.y = 0;

            if(acceleration.y < 0) // beginning jump
                onGround = false;
        }

        position += acceleration;

        const Vector2i tileCoords = _map.worldCoordsToTileCoords(position);
        const PhysLayer.TileType type = _map.tileTypeByTileCoords(tileCoords);

        if(type == PhysLayer.TileType.Empty)
            onGround = false;

        if(!onGround)
        {
            // collide with ground
            if(acceleration.y > 0 && type != PhysLayer.TileType.Empty)
            {
                position.y = _map.tileSize.y * tileCoords.y; // fell to upper side of this block
                onGround = true;
            }
        }

        if(onGround)
        {
            acceleration.x = 0; // unit automatically stops on the ground
        }
        else
        {
            acceleration.y += g_force;
        }
    }
}
