module weapons.weapon;

import math;
import soldier;
import controls_reader;
debug(weapons) import std.stdio;

class Weapon
{
    private Soldier soldier;
    private vec2f _aimingDirection;

    private static int rootHandsIdx;

    static this()
    {
        rootHandsIdx = Soldier.skeletonData.findBoneIndex("root-hands");
    }

    this(Soldier s)
    {
        soldier = s;
    }

    vec2f aimingDirection() const
    {
        return _aimingDirection;
    }

    void update()
    {
        _aimingDirection = controls.worldMouseCoords - soldier.position;

        debug(weapons) writeln("aim dir=", aimingDirection);
    }
}
