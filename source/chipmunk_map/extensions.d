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

debug alias bodyDelegate = void delegate(ref cpBody);

debug private void bodyIterFunction(cpBody* bdy, void* data)
{
    auto dg = cast(bodyDelegate*) data;

    (*dg)(*bdy);
}

debug void forEachBody(cpSpace* space, void delegate(ref cpBody) dg)
{
    cpSpaceEachBody(space, &bodyIterFunction, cast(void*) &dg);
}
