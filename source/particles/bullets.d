module particles.bullets;

import particles.faced;
import scene;
import math: gfm_dsfml;
import dsfml.graphics;

class Bullets : PhysParticles!Bullet
{
    this(Scene sc)
    {
        super(sc);
    }

    void checkHit(SceneDamageableObject o)
    {
        callForEach(
            (ref Bullet b)
            {
                if(o.checkIfBulletHit(b))
                {
                    b.markAsRemoved();

                    super.scene.blood.createSpray(b.position, b.speed);
                }
            }
        );
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        callForEach( (ref Bullet b){ b.draw(renderTarget, renderStates); } );
    }
}

struct Bullet
{
    FacedParticle _super;
    alias _super this;

    SceneObject owner;

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        Vertex start = prevPosition.gfm_dsfml;
        Vertex end = position.gfm_dsfml;

        renderTarget.draw([start, end], PrimitiveType.Lines, renderStates);
    }
}
