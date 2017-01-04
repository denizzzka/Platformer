module map.segment_intersection;

import map;
import math;
import std.typecons: Nullable;

Nullable!vec2f checkBlockCollision(in Map m, in vec2f from, in vec2f to)
{
    const vec2f dir = to - from;
    const int minTileSize = m.tileSize.x < m.tileSize.y ? m.tileSize.x : m.tileSize.y;
    const vec2f increment = dir.normalized * (minTileSize - 1);

    vec2f curr = from;

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
        {
            curr.x += increment.x;

            vec2i tileCoords = m.worldCoordsToTileCoords(curr);
            tileCoords.x += (dir.x >= 0 ? 0 : -1);
            auto t = m.tileTypeByTileCoords(tileCoords);

            if(t.isBulletproof)
            {
                Nullable!vec2f ret = curr;

                if(dir.x >= 0)
                    ret.x = tileCoords.x * m.tileSize.x;
                else
                    ret.x = (tileCoords.x + 1) * m.tileSize.x;

                float newDirX = ret.x - from.x;
                float ratio = dir.x / newDirX;
                ret.y = from.y + dir.y / ratio;

                return ret;
            }
        }

        {
            curr.y += increment.y;

            vec2i tileCoords = m.worldCoordsToTileCoords(curr);
            tileCoords.y += (dir.y >= 0 ? 0 : -1);
            auto t = m.tileTypeByTileCoords(tileCoords);

            if(t.isBulletproof)
            {
                Nullable!vec2f ret = curr;

                if(dir.y >= 0)
                    ret.y = tileCoords.y * m.tileSize.y;
                else
                    ret.y = (tileCoords.y + 1) * m.tileSize.y;

                float newDirY = ret.y - from.y;
                float ratio = dir.y / newDirY;
                ret.x = from.x + dir.x / ratio;

                return ret;
            }
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
