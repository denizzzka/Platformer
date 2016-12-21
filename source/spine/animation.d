module spine.animation;

import spine.skeleton;

class AnimationStateData
{
    package spAnimationStateData* stateData;
    alias stateData this;

    package this(SkeletonData sd)
    {
        stateData = spAnimationStateData_create(sd.skeletonData);
    }

    ~this()
    {
        spAnimationStateData_dispose(stateData);
    }

    AnimationStateInstance createInstance()
    {
        return new AnimationStateInstance(this);
    }
}

class AnimationStateInstance
{
    package spAnimationState* state;
    alias state this;

    package this(AnimationStateData asd)
    {
        state = spAnimationState_create(asd);
    }

    ~this()
    {
        spAnimationState_dispose(state);
    }
}

private extern(C):

struct spAnimationState;

struct spAnimationStateData;

/* @param data May be 0 for no mixing. */
spAnimationState* spAnimationState_create (spAnimationStateData* data);
void spAnimationState_dispose (spAnimationState* self);

spAnimationStateData* spAnimationStateData_create (spSkeletonData* skeletonData);
void spAnimationStateData_dispose (spAnimationStateData* self);

struct spTrackEntry;

/** Set the current animation. Any queued animations are cleared. */
spTrackEntry* spAnimationState_setAnimationByName (spAnimationState* self, int trackIndex, const char* animationName, int/*bool*/loop);
