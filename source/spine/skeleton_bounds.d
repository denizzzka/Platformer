module spine.skeleton_bounds;

import spine.skeleton;

class SkeletonBounds
{
    private spSkeletonBounds* sp_skeletonBounds;

    this()
    {
        sp_skeletonBounds = spSkeletonBounds_create();
    }

    ~this()
    {
        spSkeletonBounds_dispose(sp_skeletonBounds);
    }

    void update(SkeletonInstance sk, bool updateAabb)
    {
        spSkeletonBounds_update(sp_skeletonBounds, sk.sp_skeleton, updateAabb);
    }

    float minX() const { return sp_skeletonBounds.minX; }
    float minY() const { return sp_skeletonBounds.minY; }
    float maxX() const { return sp_skeletonBounds.maxX; }
    float maxY() const { return sp_skeletonBounds.maxY; }

    /** Returns true if the axis aligned bounding box intersects the line segment. */
    bool aabbIntersectsSegment(float x1, float y1, float x2, float y2)
    {
        return spSkeletonBounds_aabbIntersectsSegment(sp_skeletonBounds, x1, y1, x2, y2) != 0;
    }

    /** Returns the first bounding box attachment that contains the line segment, or null. When doing many checks, it is usually
     * more efficient to only call this method if spSkeletonBounds_aabbIntersectsSegment returns true. */
    spBoundingBoxAttachment* intersectsSegment(float x1, float y1, float x2, float y2)
    {
        return spSkeletonBounds_intersectsSegment(sp_skeletonBounds, x1, y1, x2, y2);
    }
}

private extern(C):

struct spSkeletonBounds
{
	int count;
	spBoundingBoxAttachment** boundingBoxes;
	spPolygon** polygons;

	float minX, minY, maxX, maxY;
}

struct spBoundingBoxAttachment;
struct spPolygon;

spSkeletonBounds* spSkeletonBounds_create ();
void spSkeletonBounds_dispose (spSkeletonBounds* self);
void spSkeletonBounds_update (spSkeletonBounds* self, spSkeleton* skeleton, int/*bool*/updateAabb);

int/*bool*/spSkeletonBounds_aabbIntersectsSegment (spSkeletonBounds* self, float x1, float y1, float x2, float y2);
spBoundingBoxAttachment* spSkeletonBounds_intersectsSegment (spSkeletonBounds* self, float x1, float y1, float x2, float y2);
