module soldier.grenade;

import math;
public import physics;
import scene;
import dsfml.graphics;

class Grenade : PhysicalObjectBase, SceneObject
{
    private Scene scene;

    private float timeCounter = 2;

    this(Scene sc, vec2f startPosition, vec2f launcherSpeed, vec2f direction)
    {
        scene = sc;

        position = startPosition;
        speed = launcherSpeed + direction.normalized * 300;

        super(scene.sceneMap, false);

        scene.add(this);
    }

    override box2f aabb() const
    {
        return box2f(-4.5, 0, 4.5, 9).flipY.sort; // FIXME: зависит от направления осей графики
    }

    void update(float dt)
    {
        timeCounter -= dt;

        if(timeCounter <= 0)
            scene.removeBeforeNextDraw(this);
        else
            super.doMotion(vec2f(0, 0), dt, 1200.0f); // FIXME: это нужно хранить в сцене
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        auto circle = new CircleShape(3, 10);

        circle.position = position.gfm_dsfml;
        circle.fillColor = Color(139, 69, 19);

        renderTarget.draw(circle);
    }
}
