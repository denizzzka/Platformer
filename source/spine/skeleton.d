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

    SkeletonInstance createInstance() //FIXME: remove it
    {
        return new SkeletonInstance(this);
    }
}

class SkeletonInstance
{
    spSkeleton* skeleton;
    alias skeleton this;

    package this(SkeletonData sd)
    {
        skeleton = spSkeleton_create(sd.skeletonData);
    }

    ~this()
    {
        spSkeleton_dispose (skeleton);
    }

    void update(float deltaTime)
    {
        spSkeleton_update(skeleton, deltaTime);
    }

    void updateWorldTransform()
    {
        spSkeleton_updateWorldTransform(skeleton);
    }
}

package extern(C):

enum spTransformMode
{
	NORMAL,
	ONLYTRANSLATION,
	NOROTATIONORREFLECTION,
	NOSCALE,
	NOSCALEORREFLECTION
};

struct spBoneData
{
	const int index;
	const (char*) name;
	const (spBoneData*) parent;
	float length=0;
	float x=0, y=0, rotation=0, scaleX=0, scaleY=0, shearX=0, shearY=0;
	spTransformMode transformMode = spTransformMode.NORMAL;
}

struct spBone
{
	const(spBoneData)* data;
	const(spSkeleton)* skeleton;
	const(spBone)* parent;
	int childrenCount;
	const(spBone)** children;
	float x=0, y=0, rotation=0, scaleX=0, scaleY=0, shearX=0, shearY=0;
	float ax=0, ay=0, arotation=0, ascaleX=0, ascaleY=0, ashearX=0, ashearY=0;
	int /*bool*/ appliedValid;

	float a=0, b=0, worldX=0;
	float c=0, d=0, worldY=0;

	int/*bool*/ sorted;
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
	REGION,
	BOUNDING_BOX,
	MESH,
	LINKED_MESH,
	PATH
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
	NORMAL,
    ADDITIVE,
    MULTIPLY,
    SCREEN
}

struct spSlotData
{
	const int index;
	const(char*) name;
	const(spBoneData*) boneData;
	const(char*) attachmentName;
	float r, g, b, a;
	spBlendMode blendMode;
}

struct spSlot
{
	const(spSlotData)* data;
	const(spBone)* bone;
	float r, g, b, a;
	const(spAttachment)* attachment;

	int attachmentVerticesCapacity;
	int attachmentVerticesCount;
	float* attachmentVertices;
}

struct spSkeleton
{
    const(spSkeletonData)* data;

    int bonesCount;
    spBone** bones;
    const(spBone)* root;

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

void spSkeleton_update (spSkeleton* self, float deltaTime);

void spSkeleton_updateWorldTransform (const(spSkeleton)* self);

private:

struct spSkeletonJson;

spSkeletonData* spSkeletonJson_readSkeletonDataFile(spSkeletonJson*, const(char)* path);
void spSkeletonData_dispose (spSkeletonData* self);

spSkeletonJson* spSkeletonJson_create(spAtlas* atlas);
void spSkeletonJson_dispose(spSkeletonJson* json);

spSkeleton* spSkeleton_create (spSkeletonData* data);

void spSkeleton_dispose (spSkeleton* self);

void spSkeleton_setToSetupPose (const(spSkeleton)* self);
