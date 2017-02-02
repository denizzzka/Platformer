module chipmunk_map.chipbodyclass;

import dchip.all;
import chipmunk_map.extensions;
debug import std.stdio;

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
        _space = space;
    }

    ~this()
    {
        space.purgeBodyFromSpace(_body);
    }

    cpSpace* space()
    {
        return _space;
    }
}

private void purgeBodyFromSpace(cpSpace* space, cpBody* _body)
{
    //~ cpConstraint*[] constraints;
    //~ cpShape*[] shapes;
    //~ size_t shapesCount;

    // fill
    //~ {
        //~ _body.cpBodyEachShape(
            //~ (cpBody* bdy, cpShape* shape, void* data)
            //~ {
                //~ auto _shapes = cast(cpShape*[]*) data;
                //~ *_shapes ~= shape;
            //~ },
            //~ cast(void*) &shapes
        //~ );

        //~ _body.forEachShape(
            //~ (bdy, shape)
            //~ {
                //~ shapes[shapesCount] = shape;
                //~ shapesCount++;
            //~ }
        //~ );
    //~ }

    //~ // remove stuff from space
    //~ {
        //~ foreach(c; constraints)
            //~ space.cpSpaceRemoveConstraint(c);

        //~ foreach(s; shapes)
            //~ space.cpSpaceRemoveShape(s);

        space.cpSpaceRemoveBody(_body);
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
