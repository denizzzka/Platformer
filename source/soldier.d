module soldier;

import spine.atlas;
import spine.skeleton;
import spine.animation;
import spine.dsfml;
import dsfml.graphics;
import map;
import physics;

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

class Soldier
{
    static private Atlas atlas;
    static private SkeletonData skeletonData;
    static private AnimationStateData stateData;

    static private Animation[] stayAnimations;
    static private Animation[] sitAnimations;

    private SkeletonInstanceDrawable skeleton;
    private AnimationStateInstance state;

    PhysicalObject physicalObject;
    alias physicalObject this;

    PhysicalState movingState;

    const float groundSpeedScale = 1.0;

    static this()
    {
        atlas = new Atlas("resources/textures/GAME.atlas");
        skeletonData = new SkeletonData("resources/animations/actor_pretty.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("green");

        stateData = new AnimationStateData(skeletonData);
        enum duration = 0.2;

        stayAnimations = readAnimations(["stay", "move-forward", "jump"]);
        sitAnimations = readAnimations(["sit", "sit-forward"]);

        // надо отметить низкие и высокие позы флагом и между собой внутри этих групп анимации перемиксовать
        stateData.setMixByName("stay", "move-forward", duration);
        stateData.setMixByName("move-forward", "stay", duration);

        stateData.setMixByName("jump", "move-forward", duration);
        stateData.setMixByName("move-forward", "jump", duration);

        stateData.setMixByName("stay", "jump", duration);
        stateData.setMixByName("jump", "stay", duration);

        stateData.setMixByName("sit", "sit-forward", duration);
        stateData.setMixByName("sit-forward", "sit", duration);
    }

    static Animation[] readAnimations(string[] names)
    {
        Animation[] ret;

        foreach(ref name; names)
            ret ~= skeletonData.findAnimation(name);

        return ret;
    }

    this(Map map)
    {
        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
        state.setAnimationByName(0, "stay", true);
        physicalObject = new PhysicalObject(map);

        groundSpeedScale = 2.0;
    }

    void update(float deltaTime)
    {
        skeleton.flipX = !rightDirection;
        skeleton.flipY = true;

        auto oldPhysicalState = movingState;

        const float g_force_dt = 1200.0f * deltaTime * deltaTime;
        auto acceleration = readKeys(deltaTime, g_force_dt);
        doMotion(acceleration, g_force_dt);

        if(movingState != oldPhysicalState)
        {
            state.timeScale = groundSpeedScale;
            updateAnimation();
        }

        skeleton.update(deltaTime);
        state.update(deltaTime);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
    }

    private void updateAnimation()
    {
        with(PhysicalState)
        final switch(movingState)
        {
            case Stay:
                state.setAnimationByName(0, "stay", true);
                break;

            case Run:
            case MoveUp:
            case MoveDown:
                state.setAnimationByName(0, "move-forward", true);
                break;

            case Jump:
                state.setAnimationByName(0, "fly", true);
                break;

            case Sit:
                state.setAnimationByName(0, "sit", true);
                break;

            case Crawl:
                state.setAnimationByName(0, "sit-forward", true);
                break;
        }
    }

    private Vector2f renderCenter() const
    {
        with(PhysicalState)
        final switch(movingState)
        {
            case Stay:
            case Run:
            case MoveUp:
            case MoveDown:
            case Jump:
                return Vector2f(0, 24);

            case Sit:
            case Crawl:
                return Vector2f(0, 14);
        }
    }

    void draw(RenderTarget renderTarget)
    {
        RenderStates renderStates = RenderStates();
        auto tr = position - renderCenter;
        renderStates.transform.translate(tr.x, tr.y);
        skeleton.draw(renderTarget, renderStates);
    }

    private Vector2f readKeys(float deltaTime, const float g_force_dt)
    {
        const float jumpHeight = 50.0;
        const float jumpForce = sqrt(2.0 * g_force_dt * jumpHeight);
        const float groundSpeed = 85.0f * deltaTime * groundSpeedScale;

        PhysicalState oldPhysicalState = movingState;

        if(physicalObject.onGround)
            movingState = PhysicalState.Stay;
        else
            movingState = PhysicalState.Jump;

        Vector2f acceleration = Vector2f(0, 0);

        alias kp = Keyboard.isKeyPressed;

        with(Keyboard.Key)
        {
            void horisontalMove(bool toRight)
            {
                physicalObject.rightDirection = toRight;
                acceleration.x += groundSpeed * (physicalObject.rightDirection ? 1 : -1);

                if(physicalObject.onGround)
                    movingState = PhysicalState.Run;
                else
                    movingState = PhysicalState.Jump;
            }

            if(kp(A))
            {
                horisontalMove(false);
            }

            if(kp(D))
            {
                horisontalMove(true);
            }

            if(kp(W))
            {
                if(physicalObject.tileType == PhysLayer.TileType.Ladder)
                {
                    acceleration.y -= groundSpeed;
                }
                else
                {
                    acceleration.y -= jumpForce;
                    movingState = PhysicalState.Jump;
                }
            }

            if(kp(S))
            {
                if(onGround)
                {
                    if(physicalObject.tileType == PhysLayer.TileType.Ladder)
                    {
                        acceleration.y += groundSpeed;
                    }
                    else if(kp(A) || kp(D))
                    {
                        movingState = PhysicalState.Crawl;
                        acceleration.x *= 0.5;
                    }
                    else
                    {
                        movingState = PhysicalState.Sit;
                    }
                }
                else
                {
                    acceleration.y += groundSpeed;
                }
            }
        }

        return acceleration;
    }
}

unittest
{
    auto m = new Map("test_map/map_1");
    auto s = new Soldier(m);
}
