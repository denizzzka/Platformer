module particles.bullets;

import particles.storage;
import particles.faced;
import math;
import scene;
import map;
import map.segment_intersection;
import std.typecons: Nullable;
import dsfml.graphics;

class Bullets : ParticlesStorage!Bullet
{
    private Scene scene;

    this(Scene sc)
    {
        scene = sc;
    }

    void update(float dt)
    {
        super.update(dt);

        callForEach(
                (ref Bullet b)
                {
                    auto coll = b.getBlockCollisionCoords(scene.sceneMap);

                    if(!coll.isNull)
                    {
                        b.position = coll;
                        b.markAsRemoved();
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
