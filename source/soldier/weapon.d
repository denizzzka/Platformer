module soldier.weapon;

import spine.skeleton;
import spine.animation;
import spine.dsfml;
import scene: atlas, Scene, SceneObject;
import soldier.soldier: Soldier;
import soldier.animation;
import std.container;
import std.range;
debug import std.stdio: writeln;
import math: vec2f;
import sound.library;
import std.conv: to;

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
        if(weapon.isReloadable)
        {
            auto reloadableGun = cast(BaseGun) weapon;

            reloadableGun.reload();
            soldier.state.setAnimation(1, reloadableGun.reloadAnimation, false);
        }
    }

    private void changeWeapon(BaseWeapon weapon)
    {
        import spine.skeleton_attach;
        import std.stdio; writeln("Changing to ", weapon);

        this.weapon = weapon;

        weapon.skeleton.flipY = soldier.skeleton.flipY;

        setAttachment(soldier.skeleton, "weapon", soldier.holderPrimary, weapon.skeleton);

        soldier.state.setAnimation(1, weapon.holdingAnimation, true);

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

    private vec2f fireSourceOffset() const
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
        if(weapon.canShot(soldier._scene.currentTime))
            shot();
    }

    private void shot()
    {
        vec2f pos = vec2f( // holder coords
                soldier.holderPrimary.bone.worldX,
                soldier.holderPrimary.bone.worldY
            ) + fireSourceOffset;

        weapon.shot(soldier._scene, soldier, pos, soldier.speed, soldier.aimingDirection);

        soldier.state.setAnimation(1, weapon.fireAnimation, false);
        soldier.state.addAnimation(1, weapon.holdingAnimation, true, 0.0f);

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
    bool isReloadable() const;

    AnimationType holdingAnimation() const;
    AnimationType fireAnimation() const;

    bool canShot(float currentTime) const { return true; }
    void shot(Scene sc, SceneObject owner, vec2f pos, vec2f launcherSpeed, vec2f dir);
}

abstract class BaseGun : BaseWeapon
{
    private float prevShootTime = -float.infinity;
    private Sound reloadSound;

    this()
    {
        reloadSound = loadSound("resources/sounds/ak74-reload.flac");
    }

    override bool isReloadable() const { return true; }

    override bool canShot(float currentTime) const
    {
        return prevShootTime + 0.1 <= currentTime;
    }

    override void shot(Scene sc, SceneObject owner, vec2f pos, vec2f launcherSpeed, vec2f dir)
    {
        import particles.bullets: Bullet;

        Bullet b;

        b.timeToLive = 10;
        b.windage = 0.90;
        b.speed = dir.normalized * 5000;
        b.position = pos;
        b.owner = owner;

        sc.bullets.add(b);

        prevShootTime = sc.currentTime;
    }

    void reload()
    {
        reloadSound.play();
    }

    AnimationType reloadAnimation() const { return AnimationType.Reload2Hands1; }
}

abstract class HandGun : BaseGun
{
    this()
    {
        reloadSound = loadSound("resources/sounds/ak74-reload-fast.flac");
    }

    override void reload()
    {
        reloadSound.play();
    }

    override HoldType holdType() const { return HoldType.HANDGUN; }
    override AnimationType holdingAnimation() const { return AnimationType.HoldWeapon1Hand; }
    override AnimationType fireAnimation() const { return AnimationType.ShotHoldWeapon1Hand; }
    override AnimationType reloadAnimation() const { return AnimationType.Reload2Hands2; }
}

abstract class Throwing : BaseWeapon
{
    override bool isReloadable() const { return false; }
    override HoldType holdType() const { return HoldType.THROWABLE; }
    override AnimationType holdingAnimation() const { return AnimationType.HoldThrowable; }
    override AnimationType fireAnimation() const { return AnimationType.HitThrowable; }

    override void shot(Scene sc, SceneObject owner, vec2f pos, vec2f speed, vec2f dir)
    {
        import soldier.grenade: Grenade;

        auto g = new Grenade(sc, pos, speed, dir);
    }
}

class Ak74 : BaseGun
{
    private Sound[] fireSounds;

    this()
    {
        skeletonData = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("weapon-black");
        stateData = new AnimationStateData(skeletonData);

        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);

        foreach(i; 1 .. 7)
            fireSounds ~= loadSound("resources/sounds/ak74-shoot-"~i.to!string~".flac");
    }

    override Ak74 createInstanceOfWeapon()
    {
        auto ret = new Ak74;

        return ret;
    }

    override HoldType holdType() const { return HoldType.TWO_HANDS; }
    override AnimationType holdingAnimation() const { return AnimationType.HoldWeapon2Hands; }
    override AnimationType fireAnimation() const { return AnimationType.ShotHoldWeapon2Hands; }

    override void shot(Scene sc, SceneObject owner, vec2f pos, vec2f speed, vec2f dir)
    {
        import std.random;

        super.shot(sc, owner, pos, speed, dir);

        size_t soundNum = uniform(0, fireSounds.length);
        fireSounds[soundNum].play();
    }
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
