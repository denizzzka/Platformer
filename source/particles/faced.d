module particles.faced;

import particles.storage;
import scene;
import map: Map;
import map.segment_intersection;
import std.typecons: Nullable;

/// Theese particles can collide with scene objects
class PhysParticles(Particle) : ParticlesStorage!Particle
{
    package Scene scene;

    this(Scene sc)
    {
        scene = sc;
    }

    void update(float dt)
    {
        super.update(dt);

        callForEach(
                (ref Particle b)
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
}

struct FacedParticle
{
    vec2f prevPosition;
    vec2f position = vec2f(0, 0);
    vec2f speed = vec2f(1, 1);
    float windage = 1;
    float timeToLive = 10;
    float distanceToLive = 10000;

    void markAsRemoved()
    {
        timeToLive = 0;
    }

    bool isRemoved()
    {
        return timeToLive <= 0 || distanceToLive <= 0;
    }

    void update(float dt)
    {
        immutable float g_force = 1200.0f; // FIXME: это нужно хранить в сцене

        prevPosition = position;
        position += speed * dt;
        speed -= speed * windage * dt;

        speed.y += g_force * dt;

        timeToLive -= dt;
        distanceToLive -= (position - prevPosition).length;
    }

    Nullable!vec2f getBlockCollisionCoords(in Map m)
    {
        return checkBlockCollision(m, prevPosition, position);
    }
}

unittest
{
    import particles.storage;

    auto ps = new PhysParticles!FacedParticle(null);
    ps.add(FacedParticle());
}
