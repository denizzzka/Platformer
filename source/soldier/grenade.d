module soldier.grenade;

import map;
import math;
public import physics;
import scene;
import dsfml.graphics;

class Grenade : PhysicalObjectBase, SceneObject
{
    private box2f _aabb;

    this(in Map m, vec2f startPosition, vec2f direction)
    {
        position = startPosition;
        speed = direction.normalized * 100;

        super(m, false);
    }

    override box2f aabb() const
    {
        return box2f(-4.5, 0, 4.5, 9).flipY.sort; // FIXME: зависит от направления осей графики
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
