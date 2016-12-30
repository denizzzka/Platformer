module weapons.weapon;

import math;
import spine.skeleton;
import controls_reader;
debug(weapon) import std.stdio;

class Weapon
{
    private SkeletonInstance skeletonInstance;
    private vec2f _aimingTo; /// world coords

    this(SkeletonInstance si)
    {
        skeletonInstance = si;
    }

    vec2f aimingTo() const
    {
        return _aimingTo;
    }

    void update()
    {
        _aimingTo = controls.worldMouseCoords;

        debug(weapon) writeln("aim dir=", aimingTo);
    }
}
