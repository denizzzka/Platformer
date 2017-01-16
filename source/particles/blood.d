module particles.blood;

import particles.faced;
import scene;
import math;
import dsfml.graphics;
import std.random;
import std.conv: to;

class Blood : PhysParticles!BloodDrop
{
    this(Scene sc)
    {
        super(sc);
    }

    void createSpray(vec2f start, vec2f speed)
    {
        immutable int num = 50;

        foreach(i; 0 .. num)
        {
            BloodDrop b;

            b.position = start;
            b.color = Color(uniform(100, 255).to!ubyte, 0, 0);
            b.speed = speed * uniform(0.7f, 1.0f) * 0.15;
            b.windage = 0.97;
            b.timeToLive = 2;
            b.distanceToLive = 300;

            enum halfAngle = PI_4 / 6;
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
