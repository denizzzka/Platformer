module chipmunk_map;

import map;
import math;
import dchip.all;
import std.typecons: Nullable;

// FIXME: many memory leaks

class ChipmunkMap
{
    private cpSpace* space;

    this(Map m)
    {
        space = cpSpaceNew();
        space.staticBody = cpBodyNewStatic();

        auto l = m.physLayer;

        foreach(y; 0 .. l.layerSize.y)
        {
            foreach(x; 0 .. l.layerSize.x)
            {
                auto tileCoords = vec2i(x, y);

                if(m.tileTypeByTileCoords(tileCoords).isBulletproof)
                {
                    vec2f wS = m.tileCoordsToWorldCoords(tileCoords);
                    vec2f wE = wS + m.tileSize;

                    cpVect[4] v;
                    v[0] = cpVect(wS.x, wS.y);
                    v[1] = cpVect(wS.x, wE.y);
                    v[2] = cpVect(wE.x, wE.y);
                    v[3] = cpVect(wE.x, wS.y);

                    cpShape* shape = cpPolyShapeNew(space.staticBody, 4, v.ptr, cpvzero);

                    space.staticBody.cpBodyAddShape(shape);
                }
            }
        }
    }

    ~this()
    {
        cpSpaceFree(space);
    }

    //~ private static collisionCallback

    void update(float dt)
    {
        cpSpaceStep(space, dt);
    }

    Nullable!vec2f checkCollision(vec2f from, vec2f to)
    {
        cpVect cFrom = from.gfm_chip;
        cpVect cTo = to.gfm_chip;

        Nullable!vec2f ret;

        return ret;
    }
}

private bool isBulletproof(PhysLayer.TileType t) pure
{
    return  t == PhysLayer.TileType.OneWay ||
            t == PhysLayer.TileType.Block ||
            t == PhysLayer.TileType.SlopeLeft ||
            t == PhysLayer.TileType.SlopeRight;
}

import std.traits;

/// gfm and chipmunk interaction
/// params:
/// Vs - source vector
/// Vr - result vector
private auto gfm_chip(Vs)(Vs s)
if(
    is(Vs == cpVect) ||
    (isInstanceOf!(gfm.math.Vector, Vs) && Vs.v.length == 2)
)
{
    alias T = Unqual!(typeof(Vs.x));

    static if(is(Vs == cpVect))
    {
        alias Vdest = Vector!(T, 2);
    }
    else static if(isInstanceOf!(gfm.math.Vector, Vs) && Vs.v.length == 2)
    {
        alias Vdest = cpVect;
    }
    else
    {
        static assert(0);
    }

    alias R = CopyConstness!(Vs, Vdest);

    return R(s.x, s.y);
}
