module spine.skeleton;

import spine.atlas;
import spine.animation;
import std.string: toStringz;

class SkeletonData
{
    package spSkeletonData* skeleton;

    this(string filename, Atlas atlas, float scale)
    {
        spSkeletonJson* json = spSkeletonJson_create(atlas.atlas);
        skeleton = spSkeletonJson_readSkeletonDataFile(json, filename.toStringz);
        assert(skeleton);
        spSkeletonJson_dispose(json);
    }

    ~this()
    {
        spSkeletonData_dispose(skeleton);
    }

    SkeletonInstance createInstance()
    {
        return new SkeletonInstance(skeleton);
    }
}

class SkeletonInstance
{
    spSkeleton* skeleton;

    private this(spSkeletonData* skeletonData)
    {
        skeleton = spSkeleton_create(skeletonData);
    }

    ~this()
    {
        spSkeleton_dispose (skeleton);
    }
}

extern(C):

struct spSkeletonData;

private:

struct spSkeleton;

struct spSkeletonJson;

spSkeletonData* spSkeletonJson_readSkeletonDataFile(spSkeletonJson*, const(char)* path);
void spSkeletonData_dispose (spSkeletonData* self);

spSkeletonJson* spSkeletonJson_create(spAtlas* atlas);
void spSkeletonJson_dispose(spSkeletonJson* json);

spSkeleton* spSkeleton_create (spSkeletonData* data);

void spSkeleton_dispose (spSkeleton* self);

void spSkeleton_setToSetupPose (const(spSkeleton)* self);
