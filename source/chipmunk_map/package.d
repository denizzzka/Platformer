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

    void update(float dt)
    {
        cpSpaceStep(space, dt);
    }

    Nullable!vec2f checkCollision(vec2f from, vec2f to)
    {
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
