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
    package AnimationStateInstance state;
    alias state this;

    this(SkeletonData skeletonData)
    {
        auto stateData = new AnimationStateData(skeletonData);
        state = new AnimationStateInstance(stateData);
    }
}
