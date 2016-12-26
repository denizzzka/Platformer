module soldier;

import spine.atlas;
import spine.skeleton;
import spine.animation;
import spine.dsfml;
import dsfml.graphics: RenderTarget, RenderStates;
import map;
import physics;
import math;

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

    static private AnimationType[] stayAnimations;
    static private AnimationType[] sitAnimations;

    private SkeletonInstanceDrawable skeleton;
    private AnimationStateInstance state;

    PhysicalObject physicalObject;
    alias physicalObject this;

    PhysicalState movingState;
    const float groundSpeedScale = 1.0;

    struct AnimationProperty
    {
        string spineName;
        float mixDuration;
    }

    enum AnimationType : AnimationProperty
    {
        Stay = AnimationProperty("stay", 0.2),
        MoveForward = AnimationProperty("move-forward", 0.2),
        Fly = AnimationProperty("fly", 0.6),
        Sit = AnimationProperty("sit", 0.2),
        SitForward = AnimationProperty("sit-forward", 0.2)
    }

    private struct AvailableAnimation
    {
        AnimationType type;
        Animation animation;
    }

    static AvailableAnimation[] availableAnimations;

    static this()
    {
        atlas = new Atlas("resources/textures/GAME.atlas");
        skeletonData = new SkeletonData("resources/animations/actor_pretty.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("green");

        stateData = new AnimationStateData(skeletonData);

        readAnimations();

        with(AnimationType)
        {
            stayAnimations = [Stay, MoveForward, Fly];
            sitAnimations = [Sit, SitForward];
        }

        mixAnimationsWithEachOther(stayAnimations);
        mixAnimationsWithEachOther(sitAnimations);
    }

    private static void readAnimations()
    {
        import std.traits: EnumMembers;

        foreach(type; EnumMembers!AnimationType)
        {
            AvailableAnimation a;

            a.type = type;
            a.animation = skeletonData.findAnimation(type.spineName);

            availableAnimations ~= a;
        }
    }

    private static ref Animation findAnimationByType(AnimationType type)
    {
        foreach(ref a; availableAnimations)
            if(a.type == type)
                return a.animation;

        assert(0);
    }

    private static void mixAnimationsWithEachOther(AnimationType[] animations)
    {
        foreach(ref a1; animations)
            foreach(ref a2; animations)
                if(a1 != a2)
                    stateData.setMix(findAnimationByType(a1), findAnimationByType(a2), a2.mixDuration);
    }

    private void setAnimation(AnimationType animationType)
    {
        foreach(ref a; availableAnimations)
            if(a.type == animationType)
                state.setAnimation(0, a.animation, true);
    }

    this(Map map)
    {
        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
        setAnimation(AnimationType.Stay);
        physicalObject = new PhysicalObject(map);
        physicalObject.aabb.box = box2f(-20, 0, 20, 50);

        groundSpeedScale = 2.0;
    }

    void update(float deltaTime)
    {
        skeleton.flipX = !rightDirection;
        skeleton.flipY = true;

        auto oldPhysicalState = movingState;

        const float g_force = 1200.0f;
        auto acceleration = readKeys(g_force);
        doMotion(acceleration, deltaTime, g_force);

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
                setAnimation(AnimationType.Stay);
                break;

            case Run:
            case MoveUp:
            case MoveDown:
                setAnimation(AnimationType.MoveForward);
                break;

            case Jump:
                setAnimation(AnimationType.Fly);
                break;

            case Sit:
                setAnimation(AnimationType.Sit);
                break;

            case Crawl:
                setAnimation(AnimationType.SitForward);
                break;
        }
    }

    private vec2f renderCenter() const
    {
        with(PhysicalState)
        final switch(movingState)
        {
            case Stay:
            case Run:
            case MoveUp:
            case MoveDown:
            case Jump:
                return vec2f(0, 24);

            case Sit:
            case Crawl:
                return vec2f(0, 14);
        }
    }

    void draw(RenderTarget renderTarget)
    {
        RenderStates renderStates = RenderStates();
        auto tr = position - renderCenter;
        renderStates.transform.translate(tr.x, tr.y);
        skeleton.draw(renderTarget, renderStates);
    }

    /// params: g_force used only for jump force calculation
    private vec2f readKeys(const float g_force)
    {
        import std.math: sqrt;
        import dsfml.window: Keyboard;

        const float jumpHeight = 50.0;
        const float jumpForce = sqrt(2.0 * g_force * jumpHeight);
        const float groundSpeed = 85.0f * groundSpeedScale;

        PhysicalState oldPhysicalState = movingState;

        if(physicalObject.onGround)
            movingState = PhysicalState.Stay;
        else
            movingState = PhysicalState.Jump;

        vec2f acceleration = vec2f(0, 0);

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
