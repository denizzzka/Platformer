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

package extern(C):

enum spTransformMode
{
	SP_TRANSFORMMODE_NORMAL,
	SP_TRANSFORMMODE_ONLYTRANSLATION,
	SP_TRANSFORMMODE_NOROTATIONORREFLECTION,
	SP_TRANSFORMMODE_NOSCALE,
	SP_TRANSFORMMODE_NOSCALEORREFLECTION
};

struct spBoneData
{
	const int index;
	const (char*) name;
	const (spBoneData*) parent;
	float length;
	float x, y, rotation, scaleX, scaleY, shearX, shearY;
	spTransformMode transformMode;
}

struct spSkin;
struct spEventData;
struct spAnimation;
struct spIkConstraintData;
struct spTransformConstraintData;
struct spPathConstraintData;

struct spSkeletonData
{
	const (char)* __version;
	const (char)* hash;
	float width, height;

	int bonesCount;
	spBoneData** bones;

	int slotsCount;
	spSlotData** slots;

	int skinsCount;
	spSkin** skins;
	spSkin* defaultSkin;

	int eventsCount;
	spEventData** events;

	int animationsCount;
	spAnimation** animations;

	int ikConstraintsCount;
	spIkConstraintData** ikConstraints;

	int transformConstraintsCount;
	spTransformConstraintData** transformConstraints;

	int pathConstraintsCount;
	spPathConstraintData** pathConstraints;
}

enum spAttachmentType
{
	SP_ATTACHMENT_REGION,
	SP_ATTACHMENT_BOUNDING_BOX,
	SP_ATTACHMENT_MESH,
	SP_ATTACHMENT_LINKED_MESH,
	SP_ATTACHMENT_PATH
}

struct spAttachment
{
	const(char*) name;
	const spAttachmentType type;
	const(void*) vtable;
	void* attachmentLoader;
}

enum spBlendMode
{
	SP_BLEND_MODE_NORMAL,
    SP_BLEND_MODE_ADDITIVE,
    SP_BLEND_MODE_MULTIPLY,
    SP_BLEND_MODE_SCREEN
}

struct spSlotData
{
	const int index;
	const(char*) name;
	const(void*) boneData; //spBoneData
	const(char*) attachmentName;
	float r, g, b, a;
	spBlendMode blendMode;
}

struct spSlot
{
	const(spSlotData)* data;
	const(void)* bone; //spBone
	float r, g, b, a;
	const(spAttachment)* attachment;

	int attachmentVerticesCapacity;
	int attachmentVerticesCount;
	float* attachmentVertices;
}

private:

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
