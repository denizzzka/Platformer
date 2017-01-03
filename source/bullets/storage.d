module bullets.storage;

import scene: SceneObject;
import bullets.bullet;
import dsfml.graphics;

class Bullets: SceneObject
{
    Bullet[] bullets;

    void update(float dt)
    {
        //~ foreach(ref b; bullets)
            //~ b.doMotion(renderTarget, renderStates);
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates)
    {
        foreach(ref b; bullets)
            b.draw(renderTarget, renderStates);
    }
}
