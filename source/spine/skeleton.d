module spine.skeleton;

import spine.atlas;
import std.string: toStringz;

class SkeletonData
{
    package spSkeletonData* sp_skeletonData;

    this(string filename, Atlas atlas, float scale)
    {
        spSkeletonJson* json = spSkeletonJson_create(atlas.atlas);
        sp_skeletonData = spSkeletonJson_readSkeletonDataFile(json, filename.toStringz);
        assert(sp_skeletonData);
        spSkeletonJson_dispose(json);
    }

    ~this()
    {
        spSkeletonData_dispose(sp_skeletonData);
    }
}

class SkeletonInstance
{
    package spSkeleton* sp_skeleton;
    alias sp_skeleton this;

    private SkeletonData skeletonData;

    package this(SkeletonData sd)
    {
        skeletonData = sd;
        sp_skeleton = spSkeleton_create(skeletonData.sp_skeletonData);

        assert(sp_skeleton);
    }

    ~this()
    {
        spSkeleton_dispose (sp_skeleton);
    }

    void update(float deltaTime)
    {
        spSkeleton_update(sp_skeleton, deltaTime);
    }

    void updateWorldTransform()
    {
        spSkeleton_updateWorldTransform(sp_skeleton);
    }

    void setToSetupPose()
    {
        spSkeleton_setToSetupPose(sp_skeleton);
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

    string toString() const
    {
        import std.conv: to;

        return
            "length="~length.to!string~"\n"~
            "rotation="~rotation.to!string~"\n"~
            "scaleX="~scaleX.to!string~"\n"~
            "scaleY="~scaleY.to!string~"\n"~
            "shearX="~shearX.to!string~"\n"~
            "shearY="~shearY.to!string~"\n"~
            "x="~x.to!string~"\n"~
            "y="~y.to!string;
    }
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

    string toString() const
    {
        import std.conv: to;

        return
            "rotation="~rotation.to!string~"\n"~
            "arotation="~arotation.to!string~"\n"~
            "a="~a.to!string~"\n"~
            "b="~b.to!string~"\n"~
            "c="~c.to!string~"\n"~
            "d="~d.to!string~"\n"~
            "worldX="~worldX.to!string~"\n"~
            "worldY="~worldY.to!string;
    }
}

struct spSkin;
struct spEventData;
struct spAnimation;
struct spIkConstraint;
struct spIkConstraintData;
struct spTransformConstraint;
struct spTransformConstraintData;
struct spPathConstraint;
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
	const spAttachmentType type = spAttachmentType.REGION;
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
	float r=0, g=0, b=0, a=0;
	spBlendMode blendMode = spBlendMode.NORMAL;
}

struct spSlot
{
	const(spSlotData)* data;
	const(spBone)* bone;
	float r=0, g=0, b=0, a=0;
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
    spIkConstraint** ikConstraints;

    int transformConstraintsCount;
    spTransformConstraint** transformConstraints;

    int pathConstraintsCount;
    spPathConstraint** pathConstraints;

    const(spSkin)* skin;
    float r=0, g=0, b=0, a=0;
    float time=0;
    int/*bool*/flipX=0, flipY=0;
    float x=0, y=0;
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
