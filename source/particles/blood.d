module particles.blood;

import particles.faced;
import scene;
import math;
import dsfml.graphics;
import std.random;

class Blood : PhysParticles!BloodDrop
{
    this(Scene sc)
    {
        super(sc);
    }

    void createSpray(vec2f start, vec2f speed)
    {
        immutable int num = 20;

        foreach(i; 0 .. num)
        {
            BloodDrop b;

            b.position = start;
            b.speed = speed * uniform(0.1f, 0.4f);
            b.windage = 0.9;
            b.timeToLive = 2;
            b.distanceToLive = 300;

            enum halfAngle = PI_4 / 2;
            float angle = uniform(-halfAngle, halfAngle);

            b.speed = b.speed.rotated(angle);

            super.scene.blood.add(b);
        }
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        callForEach( (ref BloodDrop b){ b.draw(renderTarget, renderStates); } );
    }
}

struct BloodDrop
{
    FacedParticle _super;
    alias _super this;

    Color color = Color.Red;

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        immutable size = vec2f(2, 2).gfm_dsfml;

        auto r = new RectangleShape(size);

        r.position = position.gfm_dsfml;
        r.fillColor = color;
        r.outlineColor = color;

        r.draw(renderTarget, renderStates);
    }
}
