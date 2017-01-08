module soldier.physics;

import map;
import math;
public import physics;

class PhysicalPerson : PhysicalObjectBase
{
    private box2f _aabb;

    this(in Map m)
    {
        super(m, true);
    }

    override float friction() const { return 0; }

    void aabb(box2f b)
    {
        if(upVec.y < 0)
            _aabb = b.flipY.sort;
        else
            _aabb = b;
    }

    override box2f aabb() const { return _aabb; }
}
