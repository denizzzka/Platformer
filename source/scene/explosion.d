module scene.explosion;

import scene.scene;
import math;
import spine.dsfml.draw_region;
import dsfml.graphics;

class ExplosionSprite : SceneObject
{
    private static RegionDrawable sprite;

    private float ttl = 2.0f;
    private vec2f coords;
    private Scene scene;

    static this()
    {
        sprite = new RegionDrawable("explosion");
    }

    this(Scene sc, vec2f _coords)
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
        import std.stdio;
        writeln(pos);

        states.transform.translate(pos.x, pos.y);

        sprite.draw(target, states);
    }
}
