module map.segment_intersection;

import map;
import math;
import std.typecons: Nullable;

Nullable!vec2f checkSegmentCollision(in Map m, in vec2f from, in vec2f to)
{
    const vec2f dir = to - from;
    const int minTileSize = m.tileSize.x < m.tileSize.y ? m.tileSize.x : m.tileSize.y;
    const vec2f increment = dir.normalized * (minTileSize - 1);

    vec2f curr = from;
    Nullable!vec2f ret;

    while
    (
        (
            (dir.x > 0 && curr.x <= to.x) ||
            (dir.x < 0 && curr.x >= to.x)
        )
        &&
        (
            (dir.y > 0 && curr.y <= to.y) ||
            (dir.y < 0 && curr.y >= to.y)
        )
    )
    {
        ret = m.checkPointCollision(curr, dir);

        if(!ret.isNull)
            break;

        curr += increment;
    }

    return ret;
}

Nullable!vec2f checkPointCollision(in Map m, in vec2f point, in vec2f dir)
{
    /// one pixel forward direction
    const dirNormX = vec2f(dir.x >= 0 ? 1 : -1, 0);
    const dirNormY = vec2f(0, dir.y >= 0 ? 1 : -1); /// ditto

    {
        vec2i tileCoords = m.worldCoordsToTileCoords(point + dirNormX);
        auto t = m.tileTypeByTileCoords(tileCoords);

        if(t.isBulletproof)
        {
            Nullable!vec2f ret = point;

            if(dir.x >= 0)
                ret.x = tileCoords.x * m.tileSize.x;
            else
                ret.x = (tileCoords.x + 1) * m.tileSize.x;

            float newDirX = ret.x - point.x;
            float ratio = dir.x / newDirX;
            ret.y = point.y + dir.y / ratio;

            return ret;
        }
    }

    {
        vec2i tileCoords = m.worldCoordsToTileCoords(point + dirNormY);
        auto t = m.tileTypeByTileCoords(tileCoords);

        if(t.isBulletproof)
        {
            Nullable!vec2f ret = point;

            if(dir.y >= 0)
                ret.y = tileCoords.y * m.tileSize.y;
            else
                ret.y = (tileCoords.y + 1) * m.tileSize.y;

            float newDirY = ret.y - point.y;
            float ratio = dir.y / newDirY;
            ret.x = point.x + dir.x / ratio;

            return ret;
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
