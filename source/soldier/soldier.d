module soldier.soldier;

import scene: atlas;
import soldier.physics;
import soldier.weapon;
import soldier.animation;
import spine.skeleton;
import spine.animation;
import spine.dsfml;
import dsfml.graphics: RenderTarget, RenderStates;
import map;
import math;
import controls_reader;
import scene;
import particles.bullets;
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

class Soldier : SceneDamageableObject
{
    static public SkeletonData skeletonData;

    package Scene _scene;

    package SkeletonInstanceDrawable skeleton;
    package SoldierAnimation state;

    HoldWeapon weaponHolder;

    PhysicalPerson physicalPerson;
    alias physicalPerson this;

    PhysicalState movingState;
    const float groundSpeedScale = 1.0;

    private vec2f _aimingDirection;
    private static const int spineHandsBoneIdx;
    private static const int spineHeadBoneIdx;
    private static const int spineSlotPrimaryIdx;

    package Slot holderPrimary;

    static this()
    {
        skeletonData = new SkeletonData("resources/animations/actor_pretty.json", atlas);
        SoldierAnimation.init(skeletonData);

        spineHandsBoneIdx = skeletonData.findBoneIndex("root-hands");
        spineHeadBoneIdx = skeletonData.findBoneIndex("head-root");
        spineSlotPrimaryIdx = skeletonData.findSlotIndex("slot-primary");
    }

    this(Scene placeToScene)
    {
        _scene = placeToScene;
        skeleton = new SkeletonInstanceDrawable(skeletonData);

        skeleton.setSkin(skeletonData.findSkin("xmas"));

        skeleton.flipY = true; // FIXME: зависит от направления осей графики
        holderPrimary = skeleton.getSlotByIndex(spineSlotPrimaryIdx);

        state = new SoldierAnimation();

        physicalPerson = new PhysicalPerson(_scene.sceneMap);
        physicalPerson.aabb = box2f(-15, 0, 15, 50);

        groundSpeedScale = 2.0;

        weaponHolder = new HoldWeapon(this);
    }

    private void skeletonPosition(vec2f pos)
    {
        skeleton.x = pos.x;
        skeleton.y = pos.y;
    }

    void update(float deltaTime)
    {
        const bool looksToRight = aimingDirection.isRightDirection;

        skeleton.flipX = !looksToRight; // FIXME: зависит от направления осей графики

        weaponHolder.skeleton.flipX = skeleton.flipX;

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

        applyMotion(acceleration, deltaTime, g_force);

        skeletonPosition = position - renderCenter;

        if(movingState != oldPhysicalState)
        {
            state.state.timeScale = groundSpeedScale;
            updateAnimation();
        }

        state.state.update(deltaTime);
        state.state.apply(skeleton);
        updateSkeletonAimingDirection();
        skeleton.updateWorldTransform();

        weaponHolder.update(deltaTime);
    }

    private void updateAnimation()
    {
        with(PhysicalState)
        with(state)
        final switch(movingState)
        {
            case Stay:
                setAnimation(0, AnimationType.Stay, true);
                break;

            case Run:
            case MoveUp:
            case MoveDown:
                setAnimation(0, AnimationType.MoveForward, true);
                break;

            case RunBackwards:
                setAnimation(0, AnimationType.MoveBackward, true);
                break;

            case Jump:
                setAnimation(0, AnimationType.Fly, true);
                break;

            case Sit:
                setAnimation(0, AnimationType.Sit, true);
                break;

            case CrawlBackwards:
                setAnimation(0, AnimationType.SitBackward, true);
                break;

            case Crawl:
                setAnimation(0, AnimationType.SitForward, true);
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
        holderPrimary.bone.rotation = weaponHolder.skeleton.flipX ? degrees : -degrees;

        debug(weapons) writeln("aim x=", aimingDirection.x, " y=", aimingDirection.y, " aim angle=", angle, " degrees=", degrees);
        debug(weapons) writeln("holder.bone:", *holderPrimary.bone);
    }

    package vec2f renderCenter() const
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
        skeleton.draw(renderTarget, renderStates);
    }

    /// params: g_force used only for jump force calculation
    private vec2f readKeys(const float g_force)
    {
        import std.math: sqrt;
        import dsfml.window: Keyboard, Mouse;

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
                physicalPerson.states.rightDirection = toRight;
                acceleration.x += groundSpeed * (physicalPerson.states.rightDirection ? rightVec.x : leftVec.x);

                if(!physicalPerson.unitState == UnitState.OnFly)
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
                if(physicalPerson.unitState == UnitState.OnLadder)
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

            if(kp(R))
            {
                weaponHolder.beginReload();
            }

            if(kp(RBracket))
            {
                weaponHolder.nextWeapon();
            }

            if(Mouse.isButtonPressed(Mouse.Button.Left))
            {
                weaponHolder.fire();
            }
        }

        return acceleration;
    }

    vec2f aimingDirection() const
    {
        return _aimingDirection;
    }

    bool checkIfBulletHit(Bullet b)
    {
        import soldier.injuries;

        return checkBulletHit(this, b) !is null;
    }

    vec2f soundScreenCoords() const
    {
        return _scene.calcSoundPosition(position);
    }
}

unittest
{
    auto m = new Map("test_map/map_1");
    auto sc = new Scene(m);
    auto s = new Soldier(sc);
}
