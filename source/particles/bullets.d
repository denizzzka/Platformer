module particles.bullets;

import particles.storage;
import math;
import scene: SceneObject;

alias Bullets = ParticlesStorage!Bullet;

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
        speed = vec2f(0, 0);
    }

    bool isRemoved()
    {
        return timeToLive == 0 && speed == vec2f(0, 0);
    }

    void update(float dt)
    {
        immutable float g_force = 1200.0f; // FIXME: это нужно хранить в сцене

        prevPosition = position;
        position += speed * dt;
        speed *= windage;

        speed.y += g_force * dt;
    }
}
