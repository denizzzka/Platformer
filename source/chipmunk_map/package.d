module chipmunk_map;

import map;
import math;
import dchip.all;

class ChipmunkMap
{
    this(Map m)
    {
        auto l = m.physLayer;

        foreach(y; 0 .. l.layerSize.y)
            foreach(x; 0 .. l.layerSize.x)
            {
                //~ l.getTileByCoords(vec2i(x, y));
            }
    }
}
