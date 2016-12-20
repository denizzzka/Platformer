module spine.animation;

import spine.skeleton;

class AnimationStateData
{
    private spAnimationStateData* stateData;

    package this(spSkeletonData* skeletonData)
    {
        stateData = spAnimationStateData_create(skeletonData);
    }

    ~this()
    {
        spAnimationStateData_dispose(stateData);
    }

    AnimationStateInstance createInstance()
    {
        return new AnimationStateInstance(stateData);
    }
}

class AnimationStateInstance
{
    private spAnimationState* state;

    package this(spAnimationStateData* stateData)
    {
        state = spAnimationState_create(stateData);
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
