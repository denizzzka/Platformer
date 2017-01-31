module chipmunk_map.chipbodyclass;

import dchip.all;
import chipmunk_map.extensions;

class ChipBody
{
    private cpBody* __body;
    private cpSpace* _space;

    cpBody* _body()
    {
        return __body;
    }

    alias _body this;

    this(cpSpace* space)
    {
        __body = space.cpSpaceAddBody(cpBodyNew(1.0f, 10.0f));
    }

    ~this()
    {
        {
            cpConstraint*[] constraints;
            constraints.length = 0;

            _body.forEachConstraint(
                (_body, c)
                {
                    constraints ~= c;
                }
            );

            foreach(c; constraints)
            {
                space.cpSpaceRemoveConstraint(c);
                cpConstraintDestroy(c);
                cpConstraintFree(c);
            }
        }

        {
            cpShape*[] shapes;
            shapes.length = 0;

            _body.forEachShape(
                (_body, shape)
                {
                    shapes ~= shape;
                }
            );

            foreach(s; shapes)
            {
                space.cpSpaceRemoveShape(s);
                cpShapeDestroy(s);
                cpShapeFree(s);
            }
        }

        space.cpSpaceRemoveBody(_body);
        cpBodyDestroy(_body);
        cpBodyFree(_body);
    }

    cpSpace* space()
    {
        return _space;
    }
}
