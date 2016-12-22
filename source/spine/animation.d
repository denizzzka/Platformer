module spine.animation;

import spine.skeleton;
import std.string: toStringz;

class AnimationStateData
{
    private SkeletonData skeletonData;
    package spAnimationStateData* sp_animationStateData;

    this(SkeletonData sd)
    {
        skeletonData = sd;
        sp_animationStateData = spAnimationStateData_create(skeletonData.sp_skeletonData);

        assert(sp_animationStateData);
    }

    ~this()
    {
        spAnimationStateData_dispose(sp_animationStateData);
    }
}

class AnimationStateInstance
{
    package spAnimationState* state;
    alias state this;

    private AnimationStateData stateData;
    float timeScale;

    this(AnimationStateData asd)
    {
        stateData = asd;
        state = spAnimationState_create(stateData.sp_animationStateData);

        assert(state);
    }

    ~this()
    {
        spAnimationState_dispose(state);
    }

    void update(float deltaTime)
    {
        spAnimationState_update(state, deltaTime * timeScale);
    }

    void apply(SkeletonInstance skeleton)
    {
        spAnimationState_apply(state, skeleton.sp_skeleton);
    }

    void setAnimationByName(int trackIndex, string animationName, int loop)
    {
        spAnimationState_setAnimationByName(state, trackIndex, animationName.toStringz, loop);
    }
}

private extern(C):

struct spEvent;

void spAnimation_apply (const(spAnimation)* self, spSkeleton* skeleton, float lastTime, float time, int loop,
		spEvent** events, int* eventsCount, float alpha, int /*boolean*/ setupPose, int /*boolean*/ mixingOut);

struct spAnimationState;

struct spAnimationStateData;

/* @param data May be 0 for no mixing. */
spAnimationState* spAnimationState_create (spAnimationStateData* data);
void spAnimationState_dispose (spAnimationState* self);

spAnimationStateData* spAnimationStateData_create (spSkeletonData* skeletonData);
void spAnimationStateData_dispose (spAnimationStateData* self);

struct spTrackEntry;

/** Set the current animation. Any queued animations are cleared. */
spTrackEntry* spAnimationState_setAnimationByName (spAnimationState* self, int trackIndex, const(char)* animationName, int/*bool*/loop);

void spAnimationState_update (spAnimationState* self, float delta);

void spAnimationState_apply (spAnimationState* self, spSkeleton* skeleton);
