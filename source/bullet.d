module bullet;

import math;
import map;
import dsfml.graphics;

struct Bullet
{
    vec2f position = vec2f(0, 0);
    vec2f speed = vec2f(1, 1);
    float lengthProportion = 1;
    float windage = 1;
}

void doMotion(Map m, Bullet b, float dt, float g_force)
{
    with(b)
    {
        position += speed * dt;
        speed *= windage;

        speed.y += g_force * dt;
    }
}

void draw(Bullet b, RenderTarget renderTarget, RenderStates renderStates)
{
    with(b)
    {
        Vertex start = position.gfm_dsfml;
        Vertex end = (position + speed).gfm_dsfml;

        renderTarget.draw([start, end], PrimitiveType.Lines, renderStates);
    }
}
