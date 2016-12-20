module spine.skeleton;

import spine.atlas;
import std.string: toStringz;

class Skeleton
{
    private spSkeleton* skeleton;

    this(string filename, Atlas atlas, float scale)
    {
        spSkeletonJson* json = spSkeletonJson_create(atlas.atlas);
        spSkeletonData* data = spSkeletonJson_readSkeletonDataFile(json, filename.toStringz);
        assert(data);
        spSkeletonJson_dispose(json);
        skeleton = spSkeleton_create(data);
    }

    ~this()
    {
        spSkeleton_dispose(skeleton);
    }
}

private extern(C):

struct spSkeleton;

struct spSkeletonData;

struct spSkeletonJson;

spSkeletonJson* spSkeletonJson_create(spAtlas* atlas);
void spSkeletonJson_dispose(spSkeletonJson* json);

spSkeletonData* spSkeletonJson_readSkeletonDataFile(spSkeletonJson*, const(char)* path);

spSkeleton* spSkeleton_create (spSkeletonData* data);

void spSkeleton_dispose (spSkeleton* self);
