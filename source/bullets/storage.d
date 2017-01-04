module bullets.storage;

import scene: SceneObject;
import math;
import map: Map;
import bullets.bullet;
import dsfml.graphics;

class Bullets: SceneObject
{
    private Map _map;

    private Bullet[] bullets;

    this(Map m)
    {
        _map = m;
    }

    void add(Bullet b)
    {
        bullets ~= b;
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

                auto coll = b.getBlockCollisionCoords(_map);

                if(!coll.isNull)
                {
                    b.position = coll;
                    b.speed = vec2f(0, 0);
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
