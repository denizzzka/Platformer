module map.segment_intersection;

import map;
import math;
import std.typecons: Nullable;

Nullable!vec2f checkBlockCollision(in Map m, vec2f from, vec2f to)
{
    vec2f dir = to - from;
    int minTileSize = m.tileSize.x < m.tileSize.y ? m.tileSize.x : m.tileSize.y;
    int increment = minTileSize * (dir.x >= 0 ? 1 : -1);
    float ratio = dir.y / dir.x;

    for(
        float x = from.x;
        (dir.x >= 0 && x <= to.x) ||
        (dir.x < 0 && x >= to.x);
        x += increment
    )
    {
        float y = from.y + x * ratio;

        vec2f coords = vec2f(x, y);

        auto t = m.tileTypeByWorldCoords(coords);

        if(t.isBulletproof)
        {
            import std.stdio;
            writeln("found collision with ", t, " coords=", coords, " dir=", dir, " ratio=", ratio);

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
