module spine.skeleton_attach;

import spine.skeleton;
import std.string: toStringz;
import std.exception: enforce;

private static SkeletonInstance[size_t] attachedSkeletons;

void setAttachment(SkeletonInstance si, size_t slotIdx, SkeletonInstance addingSkeleton)
{
    with(si)
    {
        assert(slotIdx >= 0);
        assert(slotIdx < sp_skeleton.slotsCount);

        spSlot* slot = sp_skeleton.slots[slotIdx];

        spAttachment* attachment = cast(spAttachment*) spineMalloc(spAttachment.sizeof, __FILE__, __LINE__);
    }
}

// int spSkeleton_setAttachment (spSkeleton* self, const char* slotName, const char* attachmentName);

private void* spineMalloc(size_t size, string fileName, int line)
{
    assert(size > 0);

    auto ret = _malloc(size, fileName.toStringz, line);

    enforce(ret !is null);

    return ret;
}

private extern (C):

void* _malloc (size_t size, const(char)* file, int line);

void spSlot_setAttachment (spSlot* self, spAttachment* attachment);
