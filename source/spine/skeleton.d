module spine.skeleton;

import spine.atlas;
import spine.animation;
import std.string: toStringz;

class Skeleton
{
    package spSkeleton* skeleton;
    private AnimationState state;

    this(string filename, Atlas atlas, float scale)
    {
        spSkeletonJson* json = spSkeletonJson_create(atlas.atlas);
        spSkeletonData* data = spSkeletonJson_readSkeletonDataFile(json, filename.toStringz);
        assert(data);
        spSkeletonJson_dispose(json);
        skeleton = spSkeleton_create(data);

        state = new AnimationState(data);
    }

    ~this()
    {
        spSkeleton_dispose(skeleton);
    }
}

extern(C):

struct spSkeletonData;

private:

struct spSkeleton;

struct spSkeletonJson;

spSkeletonJson* spSkeletonJson_create(spAtlas* atlas);
void spSkeletonJson_dispose(spSkeletonJson* json);

spSkeletonData* spSkeletonJson_readSkeletonDataFile(spSkeletonJson*, const(char)* path);

spSkeleton* spSkeleton_create (spSkeletonData* data);

void spSkeleton_dispose (spSkeleton* self);

void spSkeleton_setToSetupPose (const(spSkeleton)* self);
