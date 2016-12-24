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

    private SkeletonInstanceDrawable skeleton;
    private AnimationStateInstance state;

    PhysicalObject physicalObject;
    alias physicalObject this;

    PhysicalState movingState;

    static this()
    {
        atlas = new Atlas("resources/textures/GAME.atlas");
        skeletonData = new SkeletonData("resources/animations/actor_pretty.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("green");

        stateData = new AnimationStateData(skeletonData);
        enum duration = 0.2;
        stateData.setMixByName("stay", "run-forward", duration);
        stateData.setMixByName("run-forward", "stay", duration);
        stateData.setMixByName("jump", "run-forward", duration);
        stateData.setMixByName("run-forward", "jump", duration);
        stateData.setMixByName("stay", "jump", duration);
        stateData.setMixByName("jump", "stay", duration);
        stateData.setMixByName("sit", "sit-forward", duration);
        stateData.setMixByName("sit-forward", "sit", duration);
    }

    this(Map map)
    {
        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
        state.setAnimationByName(0, "stay", true);
        physicalObject = new PhysicalObject(map);
    }

    void update(float deltaTime)
    {
        skeleton.flipX = !rightDirection;
        skeleton.flipY = true;

        auto oldPhysicalState = movingState;

        auto acceleration = readKeys(deltaTime);
        doMotion(acceleration, deltaTime);

        if(movingState != oldPhysicalState)
            updateAnimation();

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
                state.setAnimationByName(0, "run-forward", true);
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

    private Vector2f readKeys(float deltaTime)
    {
        const float g_force = 400.0f * deltaTime * deltaTime;
        const float jumpHeight = 50.0;
        const float jumpForce = sqrt(2.0 * g_force * jumpHeight);
        const float groundSpeed = 80.0f * deltaTime;

        PhysicalState oldPhysicalState = movingState;
        movingState = PhysicalState.Stay;
        Vector2f acceleration = Vector2f(0, 0);

        alias kp = Keyboard.isKeyPressed;

        with(Keyboard.Key)
        {
            if(kp(A))
            {
                rightDirection = false;
                acceleration.x -= groundSpeed;
                movingState = PhysicalState.Run;
            }

            if(kp(D))
            {
                rightDirection = true;
                acceleration.x += groundSpeed;
                movingState = PhysicalState.Run;
            }

            if(kp(W))
            {
                acceleration.y -= jumpForce;
                movingState = PhysicalState.Jump;
            }

            if(kp(S) && onGround)
            {
                if(kp(A) || kp(D))
                {
                    movingState = PhysicalState.Crawl;
                    acceleration.x *= 0.5;
                }
                else
                {
                    movingState = PhysicalState.Sit;
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
