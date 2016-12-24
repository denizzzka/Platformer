module soldier;

import spine.atlas;
import spine.skeleton;
import spine.animation;
import spine.dsfml;
import dsfml.graphics;
import map;
import physics;

class Soldier
{
    static private Atlas atlas;
    static private SkeletonData skeletonData;
    static private AnimationStateData stateData;

    private SkeletonInstanceDrawable skeleton;
    private AnimationStateInstance state;

    PhysicalObject physicalObject;
    alias physicalObject this;

    static this()
    {
        atlas = new Atlas("resources/textures/GAME.atlas");
        skeletonData = new SkeletonData("resources/animations/actor_pretty.json", atlas);
        skeletonData.defaultSkin = skeletonData.findSkin("green");

        stateData = new AnimationStateData(skeletonData);
        enum duration = 0.2;
        stateData.setMixByName("stay", "run-forward", duration);
        stateData.setMixByName("run-forward", "stay", duration);
        stateData.setMixByName("jump", "run-forward", duration);
        stateData.setMixByName("run-forward", "jump", duration);
        stateData.setMixByName("stay", "jump", duration);
        stateData.setMixByName("jump", "stay", duration);
        stateData.setMixByName("stay", "sit", duration);
        stateData.setMixByName("sit", "stay", duration);
    }

    this(Map map)
    {
        skeleton = new SkeletonInstanceDrawable(skeletonData);
        state = new AnimationStateInstance(stateData);
        state.setAnimationByName(0, "stay", true);
        physicalObject = new PhysicalObject(map);
    }

    void update(float deltaTime)
    {
        skeleton.flipX = !rightDirection;
        skeleton.flipY = true;

        if(physicalObject.updateAndStateTest(deltaTime))
        {
            with(PhysicalState)
            final switch(physicalObject.movingState)
            {
                case Stay:
                    state.setAnimationByName(0, "stay", true);
                    break;

                case Run:
                case MoveUp:
                case MoveDown:
                    state.setAnimationByName(0, "run-forward", true);
                    break;

                case Jump:
                    state.setAnimationByName(0, "fly", true);
                    break;

                case Sit:
                    state.setAnimationByName(0, "sit", true);
                    break;

                case Crawl:
                    state.setAnimationByName(0, "sit-forward", true);
                    break;
            }
        }

        skeleton.update(deltaTime);
        state.update(deltaTime);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
    }

    private Vector2f renderCenter() const
    {
        with(PhysicalState)
        final switch(physicalObject.movingState)
        {
            case Stay:
            case Run:
            case MoveUp:
            case MoveDown:
            case Jump:
                return Vector2f(0, 24);

            case Sit:
            case Crawl:
                return Vector2f(0, 14);
        }
    }

    void draw(RenderTarget renderTarget)
    {
        RenderStates renderStates = RenderStates();
        auto tr = position - renderCenter;
        renderStates.transform.translate(tr.x, tr.y);
        skeleton.draw(renderTarget, renderStates);
    }
}

unittest
{
    auto m = new Map("test_map/map_1");
    auto s = new Soldier(m);
}
