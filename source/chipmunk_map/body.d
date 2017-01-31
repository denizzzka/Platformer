module chipmunk_map.chipbodyclass;

import dchip.all;
import chipmunk_map.extensions;

class ChipBody
{
    private cpBody* __body;

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
        cpBodyDestroy(_body);

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
            cpShapeDestroy(s);
            cpShapeFree(s);
        }

        cpBodyFree(_body);
    }
}
