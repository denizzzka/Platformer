module physics;

import map;
import dsfml.system;
import dsfml.window.keyboard;

enum PhysicalState // TODO: move it to Soldier?
{
    Stay,
    Run,
    MoveUp,
    MoveDown,
    Jump,
    Sit,
    Crawl
}

enum TilesState // TODO: rename to PhysicalState?
{
    Default,
    PushesWall
}

struct PhysicalProperties
{
    TilesState tilesState;
    bool onGround;
    bool rightDirection = false;
    PhysicalState movingState = PhysicalState.Stay;
}

class PhysicalObject
{
    const Map _map;

    Vector2f position;
    Vector2f acceleration = Vector2f(0, 0);

    PhysicalProperties _prevPhysProps;
    PhysicalProperties physProps;
    alias physProps this;

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
            acceleration = doAcceleration;
            acceleration.y = 0; // prevent moving down on the ground
        }

        position += acceleration;

        const Vector2i tileCoords = _map.worldCoordsToTileCoords(position);
        const PhysLayer.TileType type = _map.tileTypeByTileCoords(tileCoords);

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
            acceleration.x = 0;
            acceleration.y = 0;
        }
        else
        {
            acceleration.y += g_force;
        }
    }

    bool updateAndStateTest(float deltaTime)
    {
        import std.math: sqrt;

        const float g_force = 400.0f * deltaTime * deltaTime;
        const float jumpHeight = 50.0;
        const float jumpForce = sqrt(2.0 * g_force * jumpHeight);
        const float groundSpeed = 80.0f * deltaTime;

        movingState = PhysicalState.Stay;

        alias kp = Keyboard.isKeyPressed;

        with(Keyboard.Key)
        {
            if(kp(A))
            {
                rightDirection = false;

                if(onGround)
                {
                    movingState = PhysicalState.Run;
                    acceleration.x = -groundSpeed;
                }
            }

            if(kp(D))
            {
                rightDirection = true;

                if(onGround)
                {
                    movingState = PhysicalState.Run;
                    acceleration.x = groundSpeed;
                }
            }

            if(kp(W) && onGround)
            {
                onGround = false;
                acceleration.y -= jumpForce;
            }

            if(kp(S) && onGround)
            {
                if(kp(A) || kp(D))
                {
                    movingState = PhysicalState.Crawl;
                    acceleration.x *= 0.5;
                }
                else
                    movingState = PhysicalState.Sit;
            }
        }

        position += acceleration;

        // ground collide
        {
            Vector2i tileCoords = _map.worldCoordsToTileCoords(position);
            PhysLayer.TileType type = _map.tileTypeByTileCoords(tileCoords);

            if(!onGround)
            {
                if(acceleration.y > 0 && type != PhysLayer.TileType.Empty)
                {
                    position.y = _map.tileSize.y * tileCoords.y;
                    onGround = true;
                }
            }
            else
            {
                if(type == PhysLayer.TileType.Empty)
                {
                    onGround = false;
                }
            }
        }

        if(onGround)
        {
            acceleration.x = 0;
            acceleration.y = 0;
        }
        else
        {
            acceleration.y += g_force;
        }

        if(!onGround)
            movingState = PhysicalState.Jump;

        if(movingState == _prevPhysProps.movingState)
        {
            return false;
        }
        else
        {
            _prevPhysProps.movingState = movingState;

            return true;
        }
    }
}
