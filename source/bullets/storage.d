module bullets.storage;

import scene: SceneObject;
import map: Map;
import bullets.bullet;
import dsfml.graphics;

class Bullets: SceneObject
{
    private Map _map;

    public Bullet[] bullets;

    this(Map m)
    {
        _map = m;
    }

    void update(float dt)
    {
        const float g_force = 1200.0f; // FIXME: это нужно хранить в сцене

        foreach(ref b; bullets)
            b.doMotion(_map, dt, g_force);
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        foreach(ref b; bullets)
            b.draw(renderTarget, renderStates);
    }
}
