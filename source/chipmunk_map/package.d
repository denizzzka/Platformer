module chipmunk_map;

import map;
import map.segment_intersection: isBulletproof;
import math;
import dchip.all;
public import chipmunk_map.gfm_interaction;

// FIXME: many memory leaks

class ChipmunkMap
{
    public cpSpace* space;

    this(Map m)
    {
        space = cpSpaceNew();

        space.gravity = cpv(0, 1);

        space.staticBody = cpBodyNewStatic();

        auto l = m.physLayer;

        foreach(y; 0 .. l.layerSize.y)
        {
            foreach(x; 0 .. l.layerSize.x)
            {
                auto tileCoords = vec2i(x, y);

                if(m.tileTypeByTileCoords(tileCoords).isBulletproof)
                {
                    cpVect[4] v;
                    v[0] = cpVect(0, 0);
                    v[1] = cpVect(0, m.tileSize.y);
                    v[2] = cpVect(m.tileSize.x, m.tileSize.y);
                    v[3] = cpVect(m.tileSize.x, 0);

                    vec2f offset = m.tileCoordsToWorldCoords(tileCoords);

                    cpShape* shape = cpPolyShapeNew(space.staticBody, v.length, v.ptr, offset.gfm_chip);
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
}
