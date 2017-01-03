module bullet;

import math;
import map;

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
