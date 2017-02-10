module scene.explosion;

import scene.scene;
import math;
import spine.dsfml.draw_region;
import dsfml.graphics;

class ExplosionSprite : SceneObject
{
    private float ttl = 1.0f;
    private vec2f coords;
    private Scene scene;
    private RegionDrawable sprite;

    this(Scene sc, vec2f _coords)
    {
        scene = sc;
        coords = _coords;
        sprite = new RegionDrawable("explosion", _coords);
    }

    void update(float dt)
    {
        ttl -= dt;

        if(ttl <= 0)
            scene.removeBeforeNextDraw(this);
    }

    void draw(RenderTarget target, RenderStates states)
    {
        sprite.draw(target, states);
    }
}
