module bullets.storage;

import scene;
import math;
import bullets.bullet;
import dsfml.graphics;

class Bullets: SceneObject
{
    private Scene scene;

    private Bullet[] bullets;

    this(Scene sc)
    {
        scene = sc;
    }

    void add(Bullet b)
    {
        bullets ~= b;
    }

    void callForEach(void delegate(ref Bullet b) dg)
    {
        foreach(ref b; bullets)
            dg(b);
    }

    void update(float dt)
    {
        const float g_force = 1200.0f; // FIXME: это нужно хранить в сцене

        Bullet[] buf;

        foreach(ref b; bullets)
        {
            if(b.timeToLive > 0)
            {
                b.doMotion(dt, g_force);

                b.timeToLive -= dt;

                auto coll = b.getBlockCollisionCoords(scene.sceneMap);

                if(!coll.isNull)
                {
                    b.position = coll;
                    b.timeToLive = 0;
                }

                buf ~= b;
            }
        }

        bullets = buf;
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        foreach(ref b; bullets)
            b.draw(renderTarget, renderStates);
    }
}
