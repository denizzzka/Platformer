module bullets;

import particles.storage;
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
    vec2f prevPosition;
    vec2f position = vec2f(0, 0);
    vec2f speed = vec2f(1, 1);
    float windage = 1;
    float timeToLive = 10;

    SceneObject owner;

    void markAsRemoved()
    {
        timeToLive = 0;
    }

    bool isRemoved()
    {
        return timeToLive <= 0;
    }

    void update(float dt)
    {
        immutable float g_force = 1200.0f; // FIXME: это нужно хранить в сцене

        prevPosition = position;
        position += speed * dt;
        speed *= windage;

        speed.y += g_force * dt;

        timeToLive -= dt;
    }

    Nullable!vec2f getBlockCollisionCoords(in Map m)
    {
        return checkBlockCollision(m, prevPosition, position);
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        Vertex start = prevPosition.gfm_dsfml;
        Vertex end = position.gfm_dsfml;

        renderTarget.draw([start, end], PrimitiveType.Lines, renderStates);
    }
}
