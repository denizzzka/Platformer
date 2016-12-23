module soldier;

import spine.atlas;
import spine.skeleton;
import spine.animation;
import spine.dsfml;
import dsfml.graphics;

enum SoldierState
{
    Stay,
    Run,
    MoveUp,
    MoveDown,
    Jump
}

class Soldier
{
    static private Atlas atlas;
    static private SkeletonData skeletonData;
    static private AnimationStateData stateData;

    private SkeletonInstanceDrawable skeleton;
    private AnimationStateInstance state;

    Vector2f position = Vector2f(0, 0);

    SoldierState movingState;
    bool rightDirection = false;

    static this()
    {
        atlas = new Atlas("resources/textures/GAME.atlas");
        skeletonData = new SkeletonData("resources/animations/actor_pretty.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("green");
        stateData = new AnimationStateData(skeletonData);
    }

    this()
    {
        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
        state.setAnimationByName(0, "run-forward", 1);
    }

    void setAnimation(string animationName)
    {
        state.setAnimationByName(0, animationName, 1);
    }

    void update()
    {
        immutable float deltaTime = 1.0 / 24;

        skeleton.flipX = !rightDirection;
        skeleton.flipY = true;

        skeleton.update(deltaTime);
        state.update(deltaTime);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
    }

    void draw(RenderTarget renderTarget)
    {
        RenderStates renderStates = RenderStates();
        renderStates.transform.translate(position.x, position.y);
        skeleton.draw(renderTarget, renderStates);
    }
}

unittest
{
    auto s = new Soldier();
}
