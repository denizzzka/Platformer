module scene.explosion;

import scene.scene;
import math;
import dsfml.graphics;

class ExplosionSprite : SceneObject
{
    private float ttl = 1.0f;
    private vec2f coords;
    private Scene scene;

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
        auto c = new CircleShape(15, 30);

        c.position = coords.gfm_dsfml;
        c.fillColor = Color.Transparent;
        c.outlineColor = Color.Green;
        c.outlineThickness = 1;

        target.draw(c, states);
    }
}
