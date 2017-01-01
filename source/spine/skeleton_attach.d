module spine.skeleton_attach;

import spine.skeleton;
import std.string: toStringz;
import std.exception: enforce;

package static SkeletonInstance[size_t] attachedSkeletons;

alias SkAtt = spSkeletonAttachment_unofficial;

void setAttachment(SkeletonInstance si, string name, Slot slot, SkeletonInstance addingSkeleton)
{
    with(si)
    {
        const skeletonIdx = attachedSkeletons.length;
        attachedSkeletons[skeletonIdx] = addingSkeleton;

        SkAtt* attachment = createSkeletonAttachment(name, skeletonIdx);

        spSlot_setAttachment(slot, &attachment._super);
    }
}

// TODO: it is need to add ability removing of attach
private SkAtt* createSkeletonAttachment(string name, size_t attachedSkeletonIdx)
{
    SkAtt* sa = cast(SkAtt*) spineCalloc(SkAtt.sizeof, 1, __FILE__, __LINE__);

    _spAttachment_init(&sa._super, name.toStringz, spAttachmentType.SKELETON, &disposeSkeletonAttachment);
    sa.attachedSkeletonIdx = attachedSkeletonIdx;

    return sa;
}

private extern (C) void disposeSkeletonAttachment(spAttachment* attachment)
{
	SkAtt* self = cast(SkAtt*) attachment;

	_spAttachment_deinit(attachment);
    _free(self);
}

private void* spineCalloc(size_t num, size_t size, string fileName, int line)
{
    assert(size > 0);

    auto ret = _calloc(num, size, fileName.toStringz, line);

    enforce(ret !is null);

    return ret;
}

package extern (C):

struct spSkeletonAttachment_unofficial
{
    spAttachment _super;
    alias _super this;

    size_t attachedSkeletonIdx;
}

private:

void* _calloc (size_t num, size_t size, const(char)* file, int line);
void _free (void* ptr);

void _spAttachment_init (spAttachment* self, const(char)* name, spAttachmentType type, void function(spAttachment* self) dispose);
void _spAttachment_deinit (spAttachment* self);

void spSlot_setAttachment (spSlot* self, spAttachment* attachment);
