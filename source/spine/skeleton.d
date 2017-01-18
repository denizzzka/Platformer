module spine.skeleton;

import spine.atlas;
import std.string: toStringz;
import std.exception: enforce;

class SkeletonData
{
    package spSkeletonData* sp_skeletonData;

    this(string filename, Atlas atlas)
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

    const (spSkeletonData)* getSpSkeletonData() const
    {
        return sp_skeletonData;
    }

    Skin findSkin(string name)
    {
        Skin ret;

        ret.skin = spSkeletonData_findSkin(sp_skeletonData, name.toStringz);

        return ret;
    }

    void defaultSkin(Skin s)
    {
        sp_skeletonData.defaultSkin = s.skin;
    }

    int findBoneIndex(string boneName) const
    {
        int idx = spSkeletonData_findBoneIndex(sp_skeletonData, boneName.toStringz);

        enforce(idx >= 0, "Bone not found");

        return idx;
    }

    int findSlotIndex(string slotName) const
    {
        int idx = spSkeletonData_findSlotIndex(sp_skeletonData, slotName.toStringz);

        enforce(idx >= 0, "Slot not found");

        return idx;
    }

    package spSlotData* findSlotByIndex(int idx)
    {
        assert(idx >= 0);
        assert(idx < sp_skeletonData.slotsCount);

        return sp_skeletonData.slots[idx];
    }
}

struct Skin
{
    spSkin* skin; // TODO: rename to sp_skin
}

struct Bone
{
    spBone* bone;
    alias bone this;

    this(inout(spBone)* b)
    {
	bone = cast(spBone*) b;
    }
}

struct Slot
{
    spSlot* slot;
    alias slot this;
}

class SkeletonInstance
{
    private SkeletonData skeletonData;
    package spSkeleton* sp_skeleton;

    this(SkeletonData sd)
    {
        skeletonData = sd;
        sp_skeleton = spSkeleton_create(skeletonData.sp_skeletonData);

        assert(sp_skeleton);
    }

    ~this()
    {
        spSkeleton_dispose (sp_skeleton);
    }

    const (spSkeleton*) getSpSkeleton() const
    {
	return sp_skeleton;
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

    bool flipX(bool b){ sp_skeleton.flipX = b; return b; }
    bool flipY(bool b){ sp_skeleton.flipY = b; return b; }

    bool flipX() const { return sp_skeleton.flipX != 0; }
    bool flipY() const { return sp_skeleton.flipY != 0; }

    void x(float x){ sp_skeleton.x = x; }
    void y(float y){ sp_skeleton.y = y; }

    Bone getRootBone()
    {
	return Bone(sp_skeleton.root);
    }

    Bone getBoneByIndex(int idx)
    {
        assert(idx >= 0);
        assert(idx < sp_skeleton.bonesCount);

        Bone ret;

        ret.bone = sp_skeleton.bones[idx];

        return ret;
    }

    Slot getSlotByIndex(int idx)
    {
        assert(idx >= 0);
        assert(idx < sp_skeleton.slotsCount);

        Slot ret;
        ret.slot = sp_skeleton.slots[idx];

        return ret;
    }

    /// @param attachmentName May be null
    package spAttachment* getAttachmentForSlotIndex(int slotIdx, string attachmentName)
    {
        spAttachment* ret = spSkeleton_getAttachmentForSlotIndex(sp_skeleton, slotIdx, attachmentName.toStringz);

        enforce(ret !is null, "Slot or attachment is not found");

        return ret;
    }

    /// @param attachmentName May be null
    void setAttachment(string slotName, string attachmentName)
    {
        auto ret = spSkeleton_setAttachment(sp_skeleton, slotName.toStringz, attachmentName.toStringz);

        enforce(ret != 0, "Slot or attachment is not found");
    }

    void setSkin(Skin skin)
    {
	spSkeleton_setSkin(sp_skeleton, skin.skin);
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
	PATH,
    SKELETON = 1000 /// Unofficial type
}

struct spAttachment
{
	const(char)* name;
	spAttachmentType type = spAttachmentType.REGION;
	void* vtable;
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
	spBone* bone;
	float r=0, g=0, b=0, a=0;
	const(spAttachment)* attachment;

	int attachmentVerticesCapacity;
	int attachmentVerticesCount;
	float* attachmentVertices;
}

struct spSkeleton
{
    const spSkeletonData* data;

    int bonesCount;
    spBone** bones;
    const spBone* root;

    int slotsCount;
    spSlot** slots;
    spSlot** drawOrder;

    int ikConstraintsCount;
    spIkConstraint** ikConstraints;

    int transformConstraintsCount;
    spTransformConstraint** transformConstraints;

    int pathConstraintsCount;
    spPathConstraint** pathConstraints;

    const spSkin* skin;
    float r=0, g=0, b=0, a=0;
    float time=0;
    int/*bool*/flipX=0, flipY=0;
    float x=0, y=0;
}

void spSkeleton_update (spSkeleton* self, float deltaTime);

void spSkeleton_updateWorldTransform (const(spSkeleton)* self);

private:

struct spSkeletonJson;

spSkeletonJson* spSkeletonJson_create(spAtlas* atlas);
void spSkeletonJson_dispose(spSkeletonJson* json);

spSkeletonData* spSkeletonJson_readSkeletonDataFile(spSkeletonJson*, const(char)* path);
void spSkeletonData_dispose (spSkeletonData* self);
spSkin* spSkeletonData_findSkin (const(spSkeletonData)* self, const(char)* skinName);
int spSkeletonData_findBoneIndex (const(spSkeletonData)* self, const(char)* boneName);
int spSkeletonData_findSlotIndex (const(spSkeletonData)* self, const(char)* slotName);

spSkeleton* spSkeleton_create (spSkeletonData* data);
void spSkeleton_dispose (spSkeleton* self);

void spSkeleton_setToSetupPose (const(spSkeleton)* self);
void spSkeleton_setSkin (spSkeleton* self, spSkin* skin);
spAttachment* spSkeleton_getAttachmentForSlotIndex (const(spSkeleton)* self, int slotIndex, const(char)* attachmentName);
int spSkeleton_setAttachment (spSkeleton* self, const(char)* slotName, const(char)* attachmentName);
