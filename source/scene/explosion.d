module scene.explosion;

import scene.scene;
import math;
import spine.dsfml.draw_region;
import dsfml.graphics;

class ExplosionSprite : SceneObject
{
    private static RegionDrawable sprite;

    enum maxTTL = 0.1f;
    private float ttl = maxTTL;
    private const vec2f coords;
    private Scene scene;

    static this()
    {
        sprite = new RegionDrawable("explosion");
    }

    this(Scene sc, in vec2f _coords)
    {
        scene = sc;
        coords = _coords;
    }

    void update(float dt)
    {
        ttl -= dt;

        if(ttl <= 0)
            scene.removeBeforeNextDraw(this);
    }

    void draw(RenderTarget target, RenderStates states)
    {
        vec2f pos = coords - vec2f(sprite.size.x, sprite.size.y) / 2;

        states.transform.translate(pos.x, pos.y);

        sprite.draw(target, states, ttl / maxTTL);
    }
}
