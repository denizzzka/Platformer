module soldier.weapon;

import spine.skeleton;
import spine.animation;
import spine.dsfml;
import scene: atlas;
import soldier.soldier: Soldier;
import soldier.animation;
import std.container;
import std.range;

class HoldWeapon
{
    private Soldier soldier;

    private BaseWeapon weapon;
    private BaseWeapon[] availableWeapons;
    typeof(availableWeapons.cycle) weaponsRange;

    this(Soldier soldier)
    {
        this.soldier = soldier;

        foreach(ref w; weaponList)
            availableWeapons ~= w.createInstanceOfWeapon;

        weaponsRange = availableWeapons.cycle;

        changeWeapon(weaponsRange.front);
    }

    package SkeletonInstanceDrawable skeleton() { return weapon.skeleton; }

    void update(float deltaTime)
    {
        weapon.state.update(deltaTime);
        weapon.state.apply(weapon.skeleton);
        weapon.skeleton.updateWorldTransform();
    }

    void beginReload()
    {
        soldier.state.setAnimation(AnimationType.Reload2Hands1, false, 1);
    }

    private void changeWeapon(BaseWeapon weapon)
    {
        import spine.skeleton_attach;
        import std.stdio; writeln("Changing to ", weapon);

        this.weapon = weapon;

        weapon.skeleton.flipY = soldier.skeleton.flipY; // FIXME: зависит от направления осей графики

        setAttachment(soldier.skeleton, "weapon", soldier.holderPrimary, weapon.skeleton);

        soldier.state.setAnimation(weapon.holdingAnimation, false, 1);
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
        _weaponList ~= new Ak74;
        _weaponList ~= new Colt;
        _weaponList ~= new Grenade;
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

    BaseWeapon createInstanceOfWeapon();

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

abstract class HandGun : BaseWeapon
{
    override HoldType holdType() const { return HoldType.HANDGUN; }
}

abstract class Throwing : BaseWeapon
{
    override HoldType holdType() const { return HoldType.THROWABLE; }
}

class Ak74 : BaseWeapon
{
    this()
    {
        skeletonData = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("weapon-black");
        stateData = new AnimationStateData(skeletonData);

        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
    }

    override Ak74 createInstanceOfWeapon()
    {
        auto ret = new Ak74;

        return ret;
    }

    override HoldType holdType() const { return HoldType.TWO_HANDS; }
}

class Colt : HandGun
{
    this()
    {
        skeletonData = new SkeletonData("resources/animations/weapon-colt.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("weapon-pro");
        stateData = new AnimationStateData(skeletonData);

        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
    }

    override Colt createInstanceOfWeapon()
    {
        auto ret = new Colt;

        return ret;
    }
}

class Grenade : Throwing
{
    this()
    {
        skeletonData = new SkeletonData("resources/animations/grenade-he.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("throwable-default");
        stateData = new AnimationStateData(skeletonData);

        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
    }

    override Grenade createInstanceOfWeapon()
    {
        auto ret = new Grenade;

        return ret;
    }
}
