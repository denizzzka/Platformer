module spine.skeleton;

import spine.atlas;
import std.string: toStringz;

class Skeleton
{
    private spSkeleton* skeleton;
    private spAnimationState* state;
    private spAnimationStateData* stateData;

    this(string filename, Atlas atlas, float scale)
    {
        spSkeletonJson* json = spSkeletonJson_create(atlas.atlas);
        spSkeletonData* data = spSkeletonJson_readSkeletonDataFile(json, filename.toStringz);
        assert(data);
        spSkeletonJson_dispose(json);
        skeleton = spSkeleton_create(data);

        stateData = spAnimationStateData_create(data);
        state = spAnimationState_create(stateData);
    }

    ~this()
    {
        spSkeleton_dispose(skeleton);
        spAnimationState_dispose(state);
        spAnimationStateData_dispose(stateData);
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

struct spAnimationStateData;

struct spAnimationState;

spAnimationStateData* spAnimationStateData_create (spSkeletonData* skeletonData);
void spAnimationStateData_dispose (spAnimationStateData* self);

/* @param data May be 0 for no mixing. */
spAnimationState* spAnimationState_create (spAnimationStateData* data);
void spAnimationState_dispose (spAnimationState* self);
