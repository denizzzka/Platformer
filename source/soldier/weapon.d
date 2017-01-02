module soldier.weapon;

import spine.skeleton;
import spine.animation;
import spine.dsfml;
import scene: atlas;

struct SoldierWeaponAnimations
{
    Animation reload;
}

class Weapon
{
    private static SkeletonData ak74data;
    private static AnimationStateData stateDataAK74;

    private SoldierWeaponAnimations animations;

    private SkeletonInstanceDrawable skeletonAK74;
    private AnimationStateInstance stateAK74;

    static this()
    {
        ak74data = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        ak74data.defaultSkin = ak74data.findSkin("weapon-black");
        stateDataAK74 = new AnimationStateData(ak74data);
    }

    this()
    {
        skeletonAK74 = new SkeletonInstanceDrawable(ak74data);
        stateAK74 = new AnimationStateInstance(stateDataAK74);
    }

    package SkeletonInstanceDrawable skeleton() { return skeletonAK74; }
    package AnimationStateInstance state() { return stateAK74; }

    void update(float deltaTime)
    {
        state.update(deltaTime);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
    }
}
