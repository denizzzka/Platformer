module spine.skeleton;

import spine.atlas;
import spine.animation;
import std.string: toStringz;

class SkeletonData
{
    package spSkeletonData* skeletonData;

    this(string filename, Atlas atlas, float scale)
    {
        spSkeletonJson* json = spSkeletonJson_create(atlas.atlas);
        skeletonData = spSkeletonJson_readSkeletonDataFile(json, filename.toStringz);
        assert(skeletonData);
        spSkeletonJson_dispose(json);
    }

    ~this()
    {
        spSkeletonData_dispose(skeletonData);
    }

    SkeletonInstance createInstance()
    {
        return new SkeletonInstance(skeletonData);
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

struct spSlot
{
	const(void)* data; //spSlotData
	const(void)* bone; //spBone
	float r, g, b, a;
	const(void)* attachment; //spAttachment

	int attachmentVerticesCapacity;
	int attachmentVerticesCount;
	float* attachmentVertices;
}

struct spSkeleton
{
    const(spSkeletonData)* data;

    int bonesCount;
    void** bones; //spBone
    const(void)* root; //spBone

    int slotsCount;
    spSlot** slots;
    spSlot** drawOrder;

    int ikConstraintsCount;
    void** ikConstraints; //spIkConstraint

    int transformConstraintsCount;
    void** transformConstraints; //spTransformConstraint

    int pathConstraintsCount;
    void** pathConstraints; //spPathConstraint

    const(void)* skin; //spSkin
    float r, g, b, a;
    float time;
    int/*bool*/flipX, flipY;
    float x, y;
}

struct spSkeletonJson;

spSkeletonData* spSkeletonJson_readSkeletonDataFile(spSkeletonJson*, const(char)* path);
void spSkeletonData_dispose (spSkeletonData* self);

spSkeletonJson* spSkeletonJson_create(spAtlas* atlas);
void spSkeletonJson_dispose(spSkeletonJson* json);

spSkeleton* spSkeleton_create (spSkeletonData* data);

void spSkeleton_dispose (spSkeleton* self);

void spSkeleton_setToSetupPose (const(spSkeleton)* self);
