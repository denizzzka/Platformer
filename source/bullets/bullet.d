module bullets.bullet;

import math;
import map;
import map.segment_intersection;
import dsfml.graphics;
import std.typecons: Nullable;

struct Bullet
{
    vec2f prevPosition;
    vec2f position = vec2f(0, 0);
    vec2f speed = vec2f(1, 1);
    float windage = 1;
    float timeToLive = 10;

    import scene;
    SceneObject owner;
}

void doMotion(ref Bullet b, in float dt, in float g_force)
{
    with(b)
    {
        prevPosition = position;
        position += speed * dt;
        speed *= windage;

        speed.y += g_force * dt;
    }
}

Nullable!vec2f getBlockCollisionCoords(in Bullet b, in Map m)
{
    return checkBlockCollision(m, b.prevPosition, b.position);
}

void draw(ref Bullet b, RenderTarget renderTarget, RenderStates renderStates)
{
    with(b)
    {
        Vertex start = prevPosition.gfm_dsfml;
        Vertex end = position.gfm_dsfml;

        renderTarget.draw([start, end], PrimitiveType.Lines, renderStates);
    }
}
