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

        space.gravity = cpv(0, 100); //TODO: должно храниться в сцене
        space.damping = 0.6;
        space.idleSpeedThreshold = 2.0;
        space.sleepTimeThreshold = 0.05;

        space.staticBody = cpBodyNewStatic();

        cpVect[4] corners;
        corners[0] = cpVect(0, 0);
        corners[1] = cpVect(0, m.tileSize.y);
        corners[2] = cpVect(m.tileSize.x, m.tileSize.y);
        corners[3] = cpVect(m.tileSize.x, 0);

        auto l = m.physLayer;

        foreach(y; 0 .. l.layerSize.y)
        {
            foreach(x; 0 .. l.layerSize.x)
            {
                auto tileCoords = vec2i(x, y);

                if(m.tileTypeByTileCoords(tileCoords).isBulletproof)
                {
                    vec2f offset = m.tileCoordsToWorldCoords(tileCoords);

                    cpShape* shape = cpPolyShapeNew(space.staticBody, corners.length, corners.ptr, offset.gfm_chip);
                    shape.cpShapeSetElasticity = 0.1f;
                    shape.cpShapeSetFriction = 0.1f;

                    space.cpSpaceAddShape(shape);
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
