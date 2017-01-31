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
        cpConstraint*[] constraints;
        constraints.length = 0;

        cpShape*[] shapes;
        shapes.length = 0;

        // fill
        {
            //~ _body.forEachConstraint(
                //~ (_body, c)
                //~ {
                    //~ constraints ~= c;
                //~ }
            //~ );

            _body.forEachShape(
                (_body, shape)
                {
                    shapes ~= shape;
                }
            );
        }

        //~ // remove stuff from space
        //~ {
            //~ foreach(c; constraints)
                //~ space.cpSpaceRemoveConstraint(c);

            //~ foreach(s; shapes)
                //~ space.cpSpaceRemoveShape(s);

            //~ space.cpSpaceRemoveBody(_body);
        //~ }

        //~ // free objects
        //~ {
            //~ foreach(c; constraints)
                //~ cpConstraintFree(c);

            //~ foreach(s; shapes)
                //~ cpShapeFree(s);

            //~ cpBodyFree(_body);
        //~ }
    }

    cpSpace* space()
    {
        return _space;
    }
}
