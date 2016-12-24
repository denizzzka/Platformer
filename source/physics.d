module physics;

import map;
import dsfml.system;
import dsfml.window.keyboard;

enum PhysicalState
{
    Stay,
    Run,
    MoveUp,
    MoveDown,
    Jump,
    Sit,
    Crawl
}

class PhysicalObject
{
    const Map _map;

    Vector2f position;
    Vector2f acceleration = Vector2f(0, 0);

    bool onGround = false;
    PhysicalState movingState = PhysicalState.Stay;
    PhysicalState _prevMovingState = PhysicalState.Stay;
    bool rightDirection = false;

    this(Map m)
    {
        _map = m;
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

        if(movingState == _prevMovingState)
        {
            return false;
        }
        else
        {
            _prevMovingState = movingState;

            return true;
        }
    }
}
