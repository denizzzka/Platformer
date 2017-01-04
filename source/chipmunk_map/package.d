module chipmunk_map;

import map;
import math;
import dchip.all;

class ChipmunkMap
{
    private cpSpace space;

    this(Map m)
    {
        space.staticBody = cpBodyNewStatic;

        auto l = m.physLayer;

        foreach(y; 0 .. l.layerSize.y)
        {
            foreach(x; 0 .. l.layerSize.x)
            {
                if(l.getTileByCoords(vec2i(x, y)).isBulletproof)
                {
                }
            }
        }
    }
}

private bool isBulletproof(PhysLayer.TileType t) pure
{
    return  t == PhysLayer.TileType.OneWay ||
            t == PhysLayer.TileType.Block ||
            t == PhysLayer.TileType.SlopeLeft ||
            t == PhysLayer.TileType.SlopeRight;
}
