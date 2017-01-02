module soldier.weapon;

import spine.skeleton;
import spine.animation;
import spine.dsfml;
import soldier.soldier;

struct SoldierWeaponAnimations
{
    Animation reload;
}

class Weapon
{
    private static SkeletonData ak74data;
    private static AnimationStateData stateDataAK74;

    private SoldierWeaponAnimations animations;

    package SkeletonInstanceDrawable skeletonAK74;
    package AnimationStateInstance stateAK74;

    static this()
    {
        ak74data = new SkeletonData("resources/animations/weapon-ak74.json", atlas);
        ak74data.defaultSkin = ak74data.findSkin("weapon-black");
        stateDataAK74 = new AnimationStateData(ak74data);
    }
}
