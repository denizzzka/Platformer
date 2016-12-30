module weapons.weapon;

import math;
import spine.skeleton;

class Weapon
{
    vec2f aimingDirection;
    SkeletonInstance skeletonInstance;

    this(SkeletonInstance si)
    {
        skeletonInstance = si;
    }
}
