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
