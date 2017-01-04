module map.segment_intersection;

import map;
import math;
import std.typecons: Nullable;

Nullable!vec2f checkBlockCollision(in Map m, vec2f from, vec2f to)
{
    const vec2f dir = to - from;
    const int minTileSize = m.tileSize.x < m.tileSize.y ? m.tileSize.x : m.tileSize.y;
    const vec2f increment = dir.normalized * minTileSize - 1;

    for(
        auto curr = from;
        (dir.x >= 0 && curr.x <= to.x) ||
        (dir.x < 0 && curr.x >= to.x);
        curr += increment
    )
    {
        vec2f coords = curr;

        auto t = m.tileTypeByWorldCoords(coords);

        if(t.isBulletproof)
        {
            import std.stdio;
            writeln("found collision with ", t, " coords=", coords, " dir=", dir);

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
