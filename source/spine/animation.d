module spine.animation;

import spine.skeleton;
import std.string: toStringz;

class Animation
{
    private spAnimation* sp_animation;

    this(spAnimation* a)
    {
        sp_animation = a;
    }

    ~this()
    {
        spAnimation_dispose(sp_animation);
    }

    void apply(SkeletonInstance skeleton, float time, bool loop)
    {
        assert(0, "unimplemented");

        //spAnimation_apply();
    }
}

class AnimationStateData
{
    package spAnimationStateData* stateData;
    alias stateData this;

    package this(SkeletonData sd)
    {
        stateData = spAnimationStateData_create(sd.sp_skeletonData);
    }

    ~this()
    {
        spAnimationStateData_dispose(stateData);
    }
}

class AnimationStateInstance
{
    private AnimationStateData stateData;
    package spAnimationState* state;
    alias state this;

    float timeScale;

    package this(AnimationStateData asd)
    {
        stateData = asd;
        state = spAnimationState_create(stateData);
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
        spAnimationState_apply(state, skeleton);
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
