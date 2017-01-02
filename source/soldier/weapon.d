module soldier.weapon;

import spine.skeleton;
import spine.animation;
import spine.dsfml;
import scene: atlas;
import soldier.animation;
import std.container;
import std.range;

class HoldWeapon
{
    private SoldierAnimation soldierAnimation;
    private BaseWeapon weapon;

    this(SoldierAnimation soldierState)
    {
        soldierAnimation = soldierState;

        weaponsRange = weaponList.cycle;

        weapon = weaponList[0];
    }

    typeof(weaponList.cycle) weaponsRange;

    package SkeletonInstanceDrawable skeleton() { return weapon.skeleton; }

    void update(float deltaTime)
    {
        weapon.state.update(deltaTime);
        weapon.state.apply(weapon.skeleton);
        weapon.skeleton.updateWorldTransform();
    }

    void beginReload()
    {
        soldierAnimation.setAnimation(AnimationType.Reload2Hands1, false, 1);
    }

    private void changeWeapon(BaseWeapon weapon)
    {
        import std.stdio; writeln("Changing to ", weapon);

        this.weapon = weapon;

        soldierAnimation.setAnimation(weapon.holdingAnimation, false, 1);
    }

    void nextWeapon()
    {
        changeWeapon(weaponsRange.front);

        weaponsRange.popFront;
    }
}

static private BaseWeapon[] weaponList()
{
    static BaseWeapon[] _weaponList;

    if(_weaponList is null)
    {
        _weaponList ~= (new Ak74);
        _weaponList ~= (new Grenade);
    }

    return _weaponList;
}

enum HoldType
{
    ONE_HAND,
    TWO_HANDS,
    TWO_HANDS_BP,
    HANDGUN,
    THROWABLE,
    KNIFE
}

abstract class BaseWeapon
{
    private SkeletonData skeletonData;
    private AnimationStateData stateData;

    private SkeletonInstanceDrawable skeleton;
    private AnimationStateInstance state;

    this()
    {
        skeletonData = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("weapon-black");
        stateData = new AnimationStateData(skeletonData);

        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
    }

    HoldType holdType() const;

    AnimationType holdingAnimation() const
    {
        with(HoldType)
        with(AnimationType)
        switch(holdType)
        {
            case THROWABLE:
                return HoldThrowable;

            case HANDGUN:
                return AimWeapon1Hand;

            default:
                return AimWeapon2Hands;
        }
    }
}

abstract class Throwing : BaseWeapon
{
    override HoldType holdType() const { return HoldType.THROWABLE; }
}

class Ak74 : BaseWeapon
{
    override HoldType holdType() const { return HoldType.TWO_HANDS; }
}

class Grenade : Throwing
{
    override HoldType holdType() const { return HoldType.THROWABLE; }
}
