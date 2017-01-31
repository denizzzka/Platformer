module chipmunk_map.extensions;

import dchip.all;
import std.conv: to;

debug void forEachShapeVertice(cpShape* shape, void delegate(ref cpVect) dg)
{
    with(cpShapeType)
    switch (shape.klass.type)
    {
        case CP_POLY_SHAPE:
        {
            cpPolyShape* poly = cast(cpPolyShape*) shape;

            foreach(i; 0 .. poly.numVerts)
                dg(poly.tVerts[i]);

            break;
        }

        default:
            assert(0, "Unsupported shape type "~shape.klass.type.to!string);
    }
}

debug void forEachBody(cpSpace* space, void delegate(cpBody*) dg)
{
    static void iteratorFunc(cpBody* bdy, void* data)
    {
        auto dg = cast(void delegate(cpBody*)*) data;

        (*dg)(bdy);
    }

    cpSpaceEachBody(space, &iteratorFunc, cast(void*) &dg);
}

void forEachShape(cpBody* _body, void delegate(cpBody*, cpShape*) dg)
{
    static void iteratorFunc(cpBody* bdy, cpShape* shape, void* data)
    {
        auto _dg = cast(void delegate(cpBody*, cpShape*)*) data;

        (*_dg)(bdy, shape);
    }

    cpBodyEachShape(_body, &iteratorFunc, cast(void*) &dg);
}

void forEachConstraint(cpBody* _body, void delegate(cpBody*, cpConstraint*) dg)
{
    static void iteratorFunc(cpBody* bdy, cpConstraint* constraint, void* data)
    {
        auto dg = cast(void delegate(cpBody*, cpConstraint*)*) data;

        (*dg)(bdy, constraint);
    }

    cpBodyEachConstraint(_body, &iteratorFunc, cast(void*) &dg);
}

void forEachArbiter(cpBody* _body, void delegate(cpBody*, cpArbiter*) dg)
{
    static void iteratorFunc(cpBody* bdy, cpArbiter* ar, void* data)
    {
        auto dg = cast(void delegate(cpBody*, cpArbiter*)*) data;

        (*dg)(bdy, ar);
    }

    cpBodyEachArbiter(_body, &iteratorFunc, cast(void*) &dg);
}
