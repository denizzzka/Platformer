module soldier.soldier;

import scene: atlas;
import soldier.weapon;
import soldier.animation;
import spine.skeleton;
import spine.animation;
import spine.dsfml;
import dsfml.graphics: RenderTarget, RenderStates;
import map;
import physics;
import math;
import controls_reader;
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

class Soldier
{
    static public SkeletonData skeletonData;

    private SkeletonInstanceDrawable skeleton;
    private SoldierAnimation state;

    HoldWeapon weapon;
    static SoldierWeaponAnimations weaponAnimations;

    PhysicalObject physicalObject;
    alias physicalObject this;

    PhysicalState movingState;
    const float groundSpeedScale = 1.0;

    private vec2f _aimingDirection;
    private static const int spineHandsBoneIdx;
    private static const int spineHeadBoneIdx;
    private static const int spineSlotPrimaryIdx;

    private Slot holderPrimary;

    static this()
    {
        skeletonData = new SkeletonData("resources/animations/actor_pretty.json", atlas);
        SoldierAnimation.init(skeletonData);

        skeletonData.defaultSkin = skeletonData.findSkin("xmas");
        spineHandsBoneIdx = skeletonData.findBoneIndex("root-hands");
        spineHeadBoneIdx = skeletonData.findBoneIndex("head-root");
        spineSlotPrimaryIdx = skeletonData.findSlotIndex("slot-primary");

        weaponAnimations.reload = skeletonData.findAnimation("reload-2hands-1");
    }

    this(Map map)
    {
        skeleton = new SkeletonInstanceDrawable(skeletonData);
        skeleton.flipY = true; // FIXME: зависит от направления осей графики
        holderPrimary = skeleton.getSlotByIndex(spineSlotPrimaryIdx);

        state = new SoldierAnimation();

        physicalObject = new PhysicalObject(map);
        physicalObject.aabb = box2f(-15, 0, 15, 50);

        groundSpeedScale = 2.0;

        weapon = new HoldWeapon(weaponAnimations);
        weapon.skeleton.flipY = skeleton.flipY;

        import spine.skeleton_attach;
        setAttachment(skeleton, "weapon", holderPrimary, weapon.skeleton);
    }

    void update(in float deltaTime)
    {
        const bool looksToRight = aimingDirection.isRightDirection;

        skeleton.flipX = !looksToRight; // FIXME: зависит от направления осей графики

        weapon.skeleton.flipX = skeleton.flipX;

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

        doMotion(acceleration, deltaTime, g_force);

        if(movingState != oldPhysicalState)
        {
            state.state.timeScale = groundSpeedScale;
            updateAnimation();
        }

        state.state.update(deltaTime);
        state.state.apply(skeleton);
        updateSkeletonAimingDirection();
        skeleton.updateWorldTransform();

        weapon.update(deltaTime);
    }

    private void updateAnimation()
    {
        with(PhysicalState)
        with(state)
        final switch(movingState)
        {
            case Stay:
                setAnimation(AnimationType.Stay);
                break;

            case Run:
            case MoveUp:
            case MoveDown:
                setAnimation(AnimationType.MoveForward);
                break;

            case RunBackwards:
                setAnimation(AnimationType.MoveBackward);
                break;

            case Jump:
                setAnimation(AnimationType.Fly);
                break;

            case Sit:
                setAnimation(AnimationType.Sit);
                break;

            case CrawlBackwards:
                setAnimation(AnimationType.SitBackward);
                break;

            case Crawl:
                setAnimation(AnimationType.SitForward);
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
        holderPrimary.bone.rotation = weapon.skeleton.flipX ? degrees : -degrees;

        debug(weapons) writeln("aim x=", aimingDirection.x, " y=", aimingDirection.y, " aim angle=", angle, " degrees=", degrees);
        debug(weapons) writeln("holder.bone:", *holderPrimary.bone);
    }

    private vec2f renderCenter() const
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
        auto tr = position - renderCenter;
        renderStates.transform.translate(tr.x, tr.y);

        skeleton.draw(renderTarget, renderStates);
    }

    /// params: g_force used only for jump force calculation
    private vec2f readKeys(const float g_force)
    {
        import std.math: sqrt;
        import dsfml.window: Keyboard;

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
                physicalObject.rightDirection = toRight;
                acceleration.x += groundSpeed * (physicalObject.rightDirection ? rightVec.x : leftVec.x);

                if(!physicalObject.unitState == UnitState.OnFly)
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
                if(physicalObject.unitState == UnitState.OnLadder)
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
                weapon.beginReload(state.state);
            }

            if(kp(RBracket))
            {
                weapon.nextWeapon(state.state);
            }
        }

        return acceleration;
    }

    vec2f aimingDirection() const
    {
        return _aimingDirection;
    }
}

unittest
{
    auto m = new Map("test_map/map_1");
    auto s = new Soldier(m);
}
