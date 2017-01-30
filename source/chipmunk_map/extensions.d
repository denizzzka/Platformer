module chipmunk_map.extensions;

import dchip.all;
import std.conv: to;

debug void forEachShapeVertice(cpShape* shape, void delegate(ref cpVect verts) dg)
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
