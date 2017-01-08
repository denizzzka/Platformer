module soldier.grenade;

import map;
import math;
public import physics;
import scene;
import dsfml.graphics;

class PhysicalPerson : PhysicalObjectBase, SceneObject
{
    private box2f _aabb;

    this(in Map m)
    {
        super(m, false);
    }

    override box2f aabb() const
    {
        box2f ret;

        ret.min = vec2f(-4.5, -4.5);
        ret.max = vec2f(4.5, 4.5);

        return _aabb;
    }

    void update(float dt)
    {
        super.update(dt, 1200.0f); // FIXME: это нужно хранить в сцене
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        auto circle = new CircleShape(3, 10);

        circle.fillColor = Color.Blue;

        renderStates.transform.translate(position.x, position.y);

        renderTarget.draw(circle);
    }
}
