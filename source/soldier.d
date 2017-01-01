module soldier;

import spine.atlas;
import spine.skeleton;
import spine.animation;
import spine.dsfml;
import dsfml.graphics: RenderTarget, RenderStates;
import map;
import physics;
import math;
import controls_reader;
debug(weapons) import std.stdio: writeln;

enum PhysicalState
{
    Stay,
    Run,
    RunBackwards,
    MoveUp,
    MoveDown,
    Jump,
    Sit,
    Crawl,
    CrawlBackwards,
}

class Soldier
{
    static private Atlas atlas;
    static public SkeletonData skeletonData;
    static private AnimationStateData stateData;

    static private AnimationType[] stayAnimations;
    static private AnimationType[] sitAnimations;

    private SkeletonInstanceDrawable skeleton;
    private AnimationStateInstance state;

    private static SkeletonData ak74data;
    private static AnimationStateData stateDataAK74;

    private SkeletonInstanceDrawable skeletonAK74;
    private AnimationStateInstance stateAK74;

    PhysicalObject physicalObject;
    alias physicalObject this;

    PhysicalState movingState;
    const float groundSpeedScale = 1.0;

    private vec2f _aimingDirection;
    private static const int spineHandsBoneIdx;
    private static const int spineHeadBoneIdx;
    private static const int spineSlotPrimaryIdx;

    private Slot holderPrimary;

    struct AnimationProperty
    {
        string spineName;
        float mixDuration;
    }

    enum AnimationType : AnimationProperty
    {
        Stay = AnimationProperty("stay", 0.2),
        MoveForward = AnimationProperty("move-forward", 0.2),
        MoveBackward = AnimationProperty("move-backward", 0.2),
        Fly = AnimationProperty("fly", 0.6),
        Sit = AnimationProperty("sit", 0.2),
        SitForward = AnimationProperty("sit-forward", 0.2),
        SitBackward = AnimationProperty("sit-backward", 0.2)
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
        skeletonData.defaultSkin = skeletonData.findSkin("xmas");
        spineHandsBoneIdx = skeletonData.findBoneIndex("root-hands");
        spineHeadBoneIdx = skeletonData.findBoneIndex("head-root");
        spineSlotPrimaryIdx = skeletonData.findSlotIndex("slot-primary");

        stateData = new AnimationStateData(skeletonData);

        readAnimations();

        with(AnimationType)
        {
            stayAnimations = [Stay, MoveForward, MoveBackward, Fly];
            sitAnimations = [Sit, SitForward, SitBackward];
        }

        mixAnimationsWithEachOther(stayAnimations);
        mixAnimationsWithEachOther(sitAnimations);

        ak74data = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        ak74data.defaultSkin = ak74data.findSkin("weapon-black");
        stateDataAK74 = new AnimationStateData(ak74data);
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
        skeleton.setAttachment("slot-primary", "watergun-skin");
        holderPrimary = skeleton.getSlotByIndex(spineSlotPrimaryIdx);

        state = new AnimationStateInstance(stateData);
        setAnimation(AnimationType.Stay);

        physicalObject = new PhysicalObject(map);
        physicalObject.aabb = box2f(-15, 0, 15, 50);

        groundSpeedScale = 2.0;

        skeletonAK74 = new SkeletonInstanceDrawable(ak74data);
        stateAK74 = new AnimationStateInstance(stateDataAK74);

        import spine.skeleton_attach;
        setAttachment(skeleton, "ak-74 gun", holderPrimary, skeletonAK74);
    }

    void update(in float deltaTime)
    {
        const bool looksToRight = aimingDirection.isRightDirection;

        skeleton.flipX = !looksToRight; // FIXME: зависит от направления осей графики
        skeleton.flipY = true; // FIXME: зависит от направления осей графики

        skeletonAK74.flipX = !looksToRight; // FIXME: зависит от направления осей графики
        skeletonAK74.flipY = true; // FIXME: зависит от направления осей графики

        auto oldPhysicalState = movingState;

        const float g_force = 1200.0f;
        auto acceleration = readKeys(g_force);

        _aimingDirection = controls.worldMouseCoords - position;
        debug(weapons) writeln("aim dir=", aimingDirection);

        if(acceleration.isRightDirection != looksToRight)
        {
            if(movingState == PhysicalState.Run)
                movingState = PhysicalState.RunBackwards;
            else if(movingState == PhysicalState.Crawl)
                movingState = PhysicalState.CrawlBackwards;
        }

        doMotion(acceleration, deltaTime, g_force);

        if(movingState != oldPhysicalState)
        {
            state.timeScale = groundSpeedScale;
            updateAnimation();
        }

        state.update(deltaTime);
        state.apply(skeleton);
        updateSkeletonAimingDirection();
        skeleton.updateWorldTransform();

        stateAK74.update(deltaTime);
        stateAK74.apply(skeletonAK74);
        skeletonAK74.updateWorldTransform();
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

            case RunBackwards:
                setAnimation(AnimationType.MoveBackward);
                break;

            case Jump:
                setAnimation(AnimationType.Fly);
                break;

            case Sit:
                setAnimation(AnimationType.Sit);
                break;

            case CrawlBackwards:
                setAnimation(AnimationType.SitBackward);
                break;

            case Crawl:
                setAnimation(AnimationType.SitForward);
                break;
        }
    }

    private void updateSkeletonAimingDirection()
    {
        import std.math;

        auto hands = skeleton.getBoneByIndex(spineHandsBoneIdx);
        auto head = skeleton.getBoneByIndex(spineHeadBoneIdx);

        // FIXME: дальнейший код зависит от направления осей графики
        auto angle = atan(aimingDirection.x / aimingDirection.y);

        if(angle >= 0)
        {
            if(aimingDirection.y < 0 && aimingDirection.x == 0)
                angle = 0;
            else
                angle = angle - PI;
        }

        if(aimingDirection.x < 0)
            angle = -(angle + PI);

        const spineDefaultRotation = PI/2;
        auto degrees = (angle + spineDefaultRotation) * (180 / PI);

        hands.rotation = degrees;
        head.rotation = degrees;
        holderPrimary.bone.rotation = skeleton.flipX ? degrees : -degrees;

        debug(weapons) writeln("aim x=", aimingDirection.x, " y=", aimingDirection.y, " aim angle=", angle, " degrees=", degrees);
        debug(weapons) writeln("holder.bone:", *holderPrimary.bone);
    }

    private vec2f renderCenter() const
    {
        with(PhysicalState)
        final switch(movingState)
        {
            case Stay:
            case Run:
            case RunBackwards:
            case MoveUp:
            case MoveDown:
            case Jump:
                return vec2f(0, 24);

            case Sit:
            case Crawl:
            case CrawlBackwards:
                return vec2f(0, 14);
        }
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates = RenderStates.Default)
    {
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

        if(!unitState == UnitState.OnFly)
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
                acceleration.x += groundSpeed * (physicalObject.rightDirection ? rightVec.x : leftVec.x);

                if(!physicalObject.unitState == UnitState.OnFly)
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
                if(physicalObject.unitState == UnitState.OnLadder)
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
                if(isTouchesLadder)
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
        }

        return acceleration;
    }

    vec2f aimingDirection() const
    {
        return _aimingDirection;
    }
}

unittest
{
    auto m = new Map("test_map/map_1");
    auto s = new Soldier(m);
}
