module soldier.grenade;

import math;
public import physics;
import scene.scene;
import spine.skeleton;
import spine.animation;
import spine.dsfml.drawable_skeleton;
import dsfml.graphics;
import sound.library;

class Grenade : PhysicalObjectBase, SceneObject
{
    private Scene scene;

    private float timeCounter = 2;

    private SkeletonData skeletonData;
    private SkeletonDrawable skeleton;

    private AnimationStateData stateData;
    private AnimationStateInstance state;

    private float rotationSpeed;

    static private Sound explosionSound;

    static this()
    {
        explosionSound = loadSound("resources/sounds/explosion.flac");
    }

    this(Scene sc, vec2f startPosition, vec2f launcherSpeed, vec2f direction)
    {
        scene = sc;

        position = startPosition;
        speed = launcherSpeed + direction.normalized * 500;
        rotationSpeed = speed.length / 30;

        super(scene.sceneMap, false);

        scene.add(this);

        {
            skeletonData = new SkeletonData("resources/animations/grenade-he.json", atlas);
            skeletonData.defaultSkin = skeletonData.findSkin("throwable-default");
            stateData = new AnimationStateData(skeletonData);

            skeleton = new SkeletonDrawable(skeletonData);
            state = new AnimationStateInstance(stateData);
        }
    }

    override float rebound() const { return 0.45; }
    override float friction() const { return 0.15; }

    immutable float radius = 5;

    override box2f aabb() const
    {
        return box2f(-radius, -radius, radius, radius); // FIXME: зависит от направления осей графики
    }

    void update(float dt)
    {
        timeCounter -= dt;

        if(timeCounter <= 0)
        {
            beginExplosion();
        }
        else
        {
            super.update(dt, scene.g_force);

            if(states.unitState == UnitState.OnGround)
            {
                rotationSpeed = abs(speed.x / 4.0);
            }

            skeleton.getBoneByIndex(0).rotation += rotationSpeed * (speed.x >= 0 ? 1 : -1);
        }

        {
            state.update(dt);
            state.apply(skeleton);
            skeleton.updateWorldTransform();
        }
    }

    void beginExplosion()
    {
        scene.removeBeforeNextDraw(this);

        enum splintersNum = 50;

        for(float a = 0; a < 2 * PI; a += 2 * PI / splintersNum)
        {
            import particles.bullets: Bullet;

            vec2f dir;

            dir.x = cos(a);
            dir.y = -sin(a);

            Bullet b;

            b.timeToLive = 10;
            b.distanceToLive = 100;
            b.windage = 1.0;
            b.speed = dir * 50000;
            b.position = position;

            scene.bullets.add(b);
        }

        explosionSound.play(position);

        {
            import scene.explosion: ExplosionSprite;

            scene.add(new ExplosionSprite(scene, position));
        }
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        immutable renderCenter = vec2f(0, 0);

        auto tr = position - renderCenter;
        renderStates.transform.translate(tr.x, tr.y);

        skeleton.draw(renderTarget, renderStates);
    }
}
