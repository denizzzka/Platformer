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

    AimWeapon1Hand = AnimationProperty("aim-weapon-1hand", 0.2),
    AimWeapon2Hands = AnimationProperty("aim-weapon-2hands", 0.2),
    AimWeapon2HandsBp = AnimationProperty("aim-weapon-2hands-bp", 0.2),
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

    static private AnimationType[] stayAnimations;
    static private AnimationType[] sitAnimations;
    static private AnimationType[] holdAnimations;

    static void init(SkeletonData skeletonData)
    {
        this.skeletonData = skeletonData;

        readAnimations(skeletonData);
        stateData = new AnimationStateData(skeletonData);

        with(AnimationType)
        {
            stayAnimations = [Stay, MoveForward, MoveBackward, Fly];
            sitAnimations = [Sit, SitForward, SitBackward];
            holdAnimations = [AimWeapon1Hand, AimWeapon2Hands, AimWeapon2HandsBp];
        }

        mixAnimationsWithEachOther(stayAnimations);
        mixAnimationsWithEachOther(sitAnimations);
        mixAnimationsWithEachOther(holdAnimations);
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

    package AnimationStateInstance state;
    alias state this;

    this()
    {
        auto stateData = new AnimationStateData(skeletonData);
        state = new AnimationStateInstance(stateData);
    }
}
