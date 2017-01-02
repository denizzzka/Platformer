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

    private SoldierWeaponAnimations animations;
    private SoldierAnimation soldierAnimation;

    private SkeletonInstanceDrawable skeletonAK74;
    private AnimationStateInstance stateAK74;

    static this()
    {
        ak74data = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        ak74data.defaultSkin = ak74data.findSkin("weapon-black");
        stateDataAK74 = new AnimationStateData(ak74data);
    }

    this(SoldierAnimation soldierState, SoldierWeaponAnimations a)
    {
        soldierAnimation = soldierState;
        animations = a;

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
        soldierAnimation.setAnimation(animations.reload, false, 1);
    }

    private void changeWeapon(BaseWeapon weapon)
    {
        import std.stdio; writeln("Changing to ", weapon);
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
    THROWABLE,
    KNIFE
}

abstract class BaseWeapon
{
    HoldType holdType() const;
}

class Ak74 : BaseWeapon
{
    override HoldType holdType() const { return HoldType.TWO_HANDS; }
}

class Grenade : BaseWeapon
{
    override HoldType holdType() const { return HoldType.THROWABLE; }
}
