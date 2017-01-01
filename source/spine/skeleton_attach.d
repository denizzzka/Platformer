module spine.skeleton_attach;

import spine.skeleton;
import std.string: toStringz;
import std.exception: enforce;

private static SkeletonInstance[size_t] attachedSkeletons;

alias SkAtt = spSkeletonAttachment_unofficial;

void setAttachment(SkeletonInstance si, size_t slotIdx, SkeletonInstance addingSkeleton)
{
    with(si)
    {
        assert(slotIdx >= 0);
        assert(slotIdx < sp_skeleton.slotsCount);

        const skeletonIdx = attachedSkeletons.length;
        attachedSkeletons[skeletonIdx] = addingSkeleton;

        spSlot* slot = sp_skeleton.slots[slotIdx];

        SkAtt* attachment = createSkeletonAttachment("asd", skeletonIdx);
    }
}

private SkAtt* createSkeletonAttachment(string name, size_t attachedSkeletonIdx)
{
    SkAtt* sa = cast(SkAtt*) spineCalloc(SkAtt.sizeof, 1, __FILE__, __LINE__);

    sa.name = name.toStringz;
    sa.type = spAttachmentType.SKELETON;
    sa.attachmentLoader = null; // FIXME
    sa.attachedSkeletonIdx = attachedSkeletonIdx;

    return sa;
}

private void* spineMalloc(size_t size, string fileName, int line)
{
    assert(size > 0);

    auto ret = _malloc(size, fileName.toStringz, line);

    enforce(ret !is null);

    return ret;
}

private void* spineCalloc(size_t num, size_t size, string fileName, int line)
{
    assert(size > 0);

    auto ret = _calloc(num, size, fileName.toStringz, line);

    enforce(ret !is null);

    return ret;
}

private extern (C):

struct spAttachmentLoader
{
	const(char)* error1;
	const(char)* error2;

	const void* vtable;
}

struct _spAttachmentLoaderVtable
{
	spAttachment* function(spAttachmentLoader* self, spSkin* skin, spAttachmentType type, const(char)* name, const(char)* path) createAttachment;
	void function(spAttachmentLoader* self, spAttachment*) configureAttachment;
	void function(spAttachmentLoader* self, spAttachment*) disposeAttachment;
	void function(spAttachmentLoader* self) dispose;
}

struct spSkeletonAttachment_unofficial
{
    spAttachment _super;
    alias _super this;

    size_t attachedSkeletonIdx;
}

void* _malloc (size_t size, const(char)* file, int line);
void* _calloc (size_t num, size_t size, const(char)* file, int line);

spAttachment* spAttachmentLoader_createAttachment (spAttachmentLoader* self, spSkin* skin, spAttachmentType type, const(char)* name, const(char)* path);
void spSlot_setAttachment (spSlot* self, spAttachment* attachment);
