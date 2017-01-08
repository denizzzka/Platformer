module soldier.weapon;

import spine.skeleton;
import spine.animation;
import spine.dsfml;
import scene: atlas, Scene;
import soldier.soldier: Soldier;
import soldier.animation;
import std.container;
import std.range;
import bullets;
debug import std.stdio: writeln;
import math: vec2f;

class HoldWeapon
{
    private Soldier soldier;

    private BaseWeapon weapon;
    private BaseWeapon[] availableWeapons;
    typeof(availableWeapons.cycle) weaponsRange;
    private Bone fireBone;

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

        weapon.skeleton.flipY = soldier.skeleton.flipY;

        setAttachment(soldier.skeleton, "weapon", soldier.holderPrimary, weapon.skeleton);

        soldier.state.setAnimation(weapon.holdingAnimation, false, 1);

        {
            auto fireBoneIdx = weapon.skeletonData.findBoneIndex("fire-bone");
            fireBone = weapon.skeleton.getBoneByIndex(fireBoneIdx);
        }
    }

    void nextWeapon()
    {
        changeWeapon(weaponsRange.front);

        weaponsRange.popFront;
    }

    private vec2f fireSourcePoint() const
    {
        import std.math;

        // need to rotate fireBone coords because attached sceletons aren't calculates its world coords
        auto angle = atan(soldier.aimingDirection.y / soldier.aimingDirection.x);

        const sn = sin(angle);
        const cs = cos(angle);

        auto ret = vec2f(
                fireBone.worldX * cs - fireBone.worldY * sn,
                fireBone.worldX * sn + fireBone.worldY * cs
            );

        return ret;
    }

    void fire()
    {
        vec2f pos = soldier.position - soldier.renderCenter + // FIXME: зависит от направления осей графики
            vec2f( // holder coords
                soldier.holderPrimary.bone.worldX,
                soldier.holderPrimary.bone.worldY
            ) + fireSourcePoint;

        weapon.fire(soldier._scene, pos, soldier.aimingDirection);

        debug(weapons_fire) writeln("fireBone:", fireBone);
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

    void fire(Scene sc, vec2f pos, vec2f dir)
    {
        Bullet b;

        b.timeToLive = 10;
        b.windage = 0.90;
        b.speed = dir.normalized * 5000;
        b.position = pos;

        sc.bullets.add(b);
    }
}

abstract class HandGun : BaseWeapon
{
    override HoldType holdType() const { return HoldType.HANDGUN; }
}

abstract class Throwing : BaseWeapon
{
    override HoldType holdType() const { return HoldType.THROWABLE; }

    override void fire(Scene sc, vec2f pos, vec2f dir)
    {
        import soldier.grenade: Grenade;

        auto g = new Grenade(sc.sceneMap, pos, dir);

        sc.add(g);
    }
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
