module particles.blood;

import particles.faced;
import scene;
import math;
import dsfml.graphics;

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
            b.speed = speed * 0.2;
            b.windage = 0.8;
            b.timeToLive = 2;
            b.distanceToLive = 1000;

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

    SceneObject owner;

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        Vertex start = prevPosition.gfm_dsfml;
        Vertex end = position.gfm_dsfml;

        start.color = Color.Red;
        end.color = Color.Red;

        renderTarget.draw([start, end], PrimitiveType.Lines, renderStates);
    }
}
