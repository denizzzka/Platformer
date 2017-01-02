module soldier.weapon;

import spine.skeleton;
import spine.animation;
import spine.dsfml;
import scene: atlas;
import soldier.animation;
import std.container;
import std.range;

struct SoldierWeaponAnimations
{
    AnimationType reload;
}

class HoldWeapon
{
    private static SkeletonData ak74data;
    private static AnimationStateData stateDataAK74;

    private SoldierAnimation soldierAnimation;
    private SoldierWeaponAnimations weaponHandleAnimations;

    private SkeletonInstanceDrawable skeletonAK74;
    private AnimationStateInstance stateAK74;

    private BaseWeapon weapon;

    static this()
    {
        ak74data = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        ak74data.defaultSkin = ak74data.findSkin("weapon-black");
        stateDataAK74 = new AnimationStateData(ak74data);
    }

    this(SoldierAnimation soldierState, SoldierWeaponAnimations a)
    {
        soldierAnimation = soldierState;
        weaponHandleAnimations = a;

        skeletonAK74 = new SkeletonInstanceDrawable(ak74data);
        stateAK74 = new AnimationStateInstance(stateDataAK74);

        weaponsRange = weaponList.cycle;
    }

    typeof(weaponList.cycle) weaponsRange;

    package SkeletonInstanceDrawable skeleton() { return skeletonAK74; }
    package AnimationStateInstance state() { return stateAK74; }

    void update(float deltaTime)
    {
        state.update(deltaTime);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
    }

    void beginReload()
    {
        soldierAnimation.setAnimation(weaponHandleAnimations.reload, false, 5);
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

static private BaseWeapon[] weaponList;

static this()
{
    weaponList ~= (new Ak74);
    weaponList ~= (new Grenade);
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
