module bullets.storage;

import scene: SceneObject;
import map: Map;
import bullets.bullet;
import dsfml.graphics;

class Bullets: SceneObject
{
    private Map _map;

    private Bullet[size_t] bullets;
    private size_t count;

    this(Map m)
    {
        _map = m;
    }

    void add(Bullet b)
    {
        bullets[count] = b;
        count++;
    }

    private void remove(size_t num)
    {
        bullets.remove(num);
    }

    void update(float dt)
    {
        const float g_force = 1200.0f; // FIXME: это нужно хранить в сцене

        foreach(size_t i, ref b; bullets)
        {
            b.doMotion(dt, g_force);

            b.timeToLive -= dt;

            if(b.timeToLive <= 0)
                remove(i);
        }
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        foreach(ref b; bullets)
            b.draw(renderTarget, renderStates);
    }
}
