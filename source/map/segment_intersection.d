module map.segment_intersection;

import map;
import math;
import std.typecons: Nullable;

Nullable!vec2f checkBlockCollision(in Map m, vec2f from, vec2f to)
{
    vec2f dir = to - from;
    float ratio = dir.y / dir.x;

    for(
        float x = from.x;
        (dir.x >= 0 && x <= to.x) ||
        (dir.x < 0 && x >= to.x);
        x += m.tileSize.x * dir.normalized.x
    )
    {
        float y = x * ratio;

        vec2f coords = vec2f(x, y);

        if(m.tileTypeByWorldCoords(coords).isBulletproof)
        {
            return Nullable!vec2f(coords);
        }
    }

    Nullable!vec2f ret;

    return ret;
}

bool isBulletproof(PhysLayer.TileType t) pure
{
    return  t == PhysLayer.TileType.OneWay ||
            t == PhysLayer.TileType.Block ||
            t == PhysLayer.TileType.SlopeLeft ||
            t == PhysLayer.TileType.SlopeRight;
}
