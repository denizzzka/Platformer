module soldier.grenade;

import math;
public import physics;
import scene;
import dsfml.graphics;

class Grenade : PhysicalObjectBase, SceneObject
{
    private Scene scene;

    private float timeCounter = 2;

    this(Scene sc, vec2f startPosition, vec2f launcherSpeed, vec2f direction)
    {
        scene = sc;

        position = startPosition;
        speed = launcherSpeed + direction.normalized * 500;

        super(scene.sceneMap, false);

        scene.add(this);
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
            beginExplosion();
        else
            super.update(dt, 1200.0f); // FIXME: это нужно хранить в сцене
    }

    void beginExplosion()
    {
        scene.removeBeforeNextDraw(this);

        enum splintersNum = 50;

        for(float a = 0; a < 2 * PI; a += 2 * PI / splintersNum)
        {
            import bullets;

            vec2f dir;

            dir.x = cos(a);
            dir.y = -sin(a);

            Bullet b;

            b.timeToLive = 2;
            b.windage = 0.90;
            b.speed = dir * 1000;
            b.position = position;

            scene.bullets.add(b);
        }
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        auto circle = new CircleShape(radius, 10);

        circle.position = (position - vec2f(radius, radius)).gfm_dsfml;
        circle.fillColor = Color.Black;

        renderTarget.draw(circle);
    }
}