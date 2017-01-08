module soldier.physics;

import map;
import math;
public import physics;

class PhysicalObject : PhysicalObjectBase
{
    private box2f _aabb;

    this(in Map m)
    {
        super(m, true);
    }

    void aabb(box2f b)
    {
        if(upVec.y < 0)
            _aabb = b.flipY.sort;
        else
            _aabb = b;
    }

    override box2f aabb() const { return _aabb; }
}
