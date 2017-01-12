module soldier.animation;

import spine.skeleton;
import spine.animation;

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
    SitBackward = AnimationProperty("sit-backward", 0.2),

    HoldWeapon2Hands = AnimationProperty("hold-weapon-2hands", 0.2),
    HoldThrowable = AnimationProperty("hold-throwable", 0.2),

    AimWeapon1Hand = AnimationProperty("aim-weapon-1hand", 0.2),
    AimWeapon2Hands = AnimationProperty("aim-weapon-2hands", 0.2),
    AimWeapon2HandsBp = AnimationProperty("aim-weapon-2hands-bp", 0.2),

    ShotHoldWeapon2Hands = AnimationProperty("shoot-hold-weapon-2hands", 0.0),
    HitThrowable = AnimationProperty("hit-throwable", 0.0),

    Reload2Hands1 = AnimationProperty("reload-2hands-1", 0.2),
}

private struct AvailableAnimation
{
    AnimationType type;
    Animation animation;
}

class SoldierAnimation
{
    static package SkeletonData skeletonData;
    static private AnimationStateData stateData;

    static AvailableAnimation[] availableAnimations;

    package AnimationStateInstance state;

    static void init(SkeletonData skeletonData)
    {
        this.skeletonData = skeletonData;

        readAnimations(skeletonData);
        stateData = new AnimationStateData(skeletonData);

        with(AnimationType)
        {
            auto stayAnimations = [Stay, MoveForward, MoveBackward, Fly];
            auto sitAnimations = [Sit, SitForward, SitBackward];
            auto aimAnimations = [AimWeapon1Hand, AimWeapon2Hands, AimWeapon2HandsBp, HoldThrowable];

            mixAnimationsWithEachOther(stayAnimations);
            mixAnimationsWithEachOther(sitAnimations);
            mixAnimationsWithEachOther(aimAnimations);
        }
    }

    private static void readAnimations(SkeletonData skeletonData)
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

    private static void mixAnimationsWithEachOther(AnimationType[] animations)
    {
        foreach(ref a1; animations)
            foreach(ref a2; animations)
                if(a1 != a2)
                    stateData.setMix(findAnimationByType(a1), findAnimationByType(a2), a2.mixDuration);
    }

    private static ref Animation findAnimationByType(AnimationType type)
    {
        foreach(ref a; availableAnimations)
            if(a.type == type)
                return a.animation;

        assert(0);
    }

    this()
    {
        state = new AnimationStateInstance(stateData);

        state.addListener(
            (state, type, entry, event)
            {
                if(type == spEventType.SP_ANIMATION_EVENT)
                {
                    if(event)
                    {
                        import std.stdio;
                        writeln("Event! ", *event);
                    }
                }
            }
        );

        setAnimation(AnimationType.Stay);
    }

    void setAnimation(AnimationType animationType, bool loop = true, int trackNum = 0)
    {
        foreach(ref a; availableAnimations)
            if(a.type == animationType)
            {
                state.setAnimation(trackNum, a.animation, loop);
                break;
            }
    }

    void addAnimation(int trackNum, AnimationType animationType, bool loop, float delay)
    {
        foreach(ref a; availableAnimations)
            if(a.type == animationType)
            {
                state.addAnimation(trackNum, a.animation, loop, delay);
                break;
            }
    }
}
