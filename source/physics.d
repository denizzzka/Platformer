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

struct PhysicalObject
{
    Vector2f position;
    Vector2f acceleration = Vector2f(0, 0);

    bool onGround = false;
    PhysicalState movingState = PhysicalState.Stay;
    PhysicalState _prevMovingState = PhysicalState.Stay;
    bool rightDirection = false;

    bool updateAndStateTest()
    {
        enum jumpForce = -10;
        enum g_force = 1.0;
        enum groundSpeed = 3.5;
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
                acceleration.y = jumpForce;
            }

            if(kp(S) && onGround)
            {
                if(kp(A) || kp(D))
                    movingState = PhysicalState.Crawl;
                else
                    movingState = PhysicalState.Sit;
            }
        }

        position += acceleration;

        if(!onGround && position.y > 300)
        {
            position.y = 300;
            onGround = true;
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
