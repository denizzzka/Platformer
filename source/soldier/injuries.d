module soldier.injuries;

import soldier.soldier;
import bullets: Bullet;
import spine.skeleton_bounds;
import math;

/// returns bounding box name or null
package string checkBulletHit(Soldier soldier, in Bullet b)
{
    import std.string: fromStringz;
    import std.conv: to;

    if(b.owner != soldier)
    {
        auto bounds = new SkeletonBounds;

        bounds.update(soldier.skeleton, true);

        if(aabbIntersectsSegment(bounds, b.prevPosition, b.position))
        {
            const boundingBox = intersectsSegment(bounds, b.prevPosition, b.position);

            if(boundingBox != null)
            {
                return boundingBox._super._super.name.fromStringz.to!string;
            }
        }
    }

    return null;
}

private bool aabbIntersectsSegment(SkeletonBounds b, vec2f v1, vec2f v2)
{
    return b.aabbIntersectsSegment(v1.x, v1.y, v2.x, v2.y);
}

private spBoundingBoxAttachment* intersectsSegment(SkeletonBounds b, vec2f v1, vec2f v2)
{
    return b.intersectsSegment(v1.x, v1.y, v2.x, v2.y);
}
