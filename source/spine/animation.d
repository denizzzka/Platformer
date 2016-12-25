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

    void setMixByName(string fromName, string toName, float duration)
    {
        spAnimationStateData_setMixByName(
                sp_animationStateData,
                fromName.toStringz,
                toName.toStringz,
                duration
            );
    }
}

class AnimationStateInstance
{
    private AnimationStateData stateData;
    package spAnimationState* sp_animationState;

    this(AnimationStateData asd)
    {
        stateData = asd;
        sp_animationState = spAnimationState_create(stateData.sp_animationStateData);

        assert(sp_animationState);
    }

    ~this()
    {
        spAnimationState_dispose(sp_animationState);
    }

    void update(float deltaTime)
    {
        spAnimationState_update(sp_animationState, deltaTime);
    }

    void apply(SkeletonInstance skeleton)
    {
        spAnimationState_apply(sp_animationState, skeleton.sp_skeleton);
    }

    void setAnimationByName(int trackIndex, string animationName, bool loop)
    {
        spAnimationState_setAnimationByName(sp_animationState, trackIndex, animationName.toStringz, loop ? 1 : 0);
    }

    void addAnimationByName(int trackIndex, string animationName, bool loop, float delay)
    {
        spAnimationState_addAnimationByName(sp_animationState, trackIndex, animationName.toStringz, loop ? 1 : 0, delay);
    }

    void timeScale(float t)
    {
        sp_animationState.timeScale = t;
    }
}

private extern(C):

enum spEventType
{
    SP_ANIMATION_START,
    SP_ANIMATION_INTERRUPT,
    SP_ANIMATION_END,
    SP_ANIMATION_COMPLETE,
    SP_ANIMATION_DISPOSE,
    SP_ANIMATION_EVENT
}

struct spEvent;

void spAnimation_apply (const(spAnimation)* self, spSkeleton* skeleton, float lastTime, float time, int loop,
		spEvent** events, int* eventsCount, float alpha, int /*boolean*/ setupPose, int /*boolean*/ mixingOut);

alias spAnimationStateListener = void function(spAnimationState* state, spEventType type, spTrackEntry* entry, spEvent* event);

struct spAnimationState
{
	const(spAnimationStateData)* data;

	int tracksCount;
	spTrackEntry** tracks;

	spAnimationStateListener listener;

	float timeScale = 0;

	void* rendererObject;
}

struct spAnimationStateData;

spAnimationStateData* spAnimationStateData_create (spSkeletonData* skeletonData);
void spAnimationStateData_dispose (spAnimationStateData* self);

void spAnimationStateData_setMixByName (spAnimationStateData* self, const(char)* fromName, const(char)* toName, float duration);

/* @param data May be 0 for no mixing. */
spAnimationState* spAnimationState_create (spAnimationStateData* data);
void spAnimationState_dispose (spAnimationState* self);

struct spTrackEntry;

/** Set the current animation. Any queued animations are cleared. */
spTrackEntry* spAnimationState_setAnimationByName (spAnimationState* self, int trackIndex, const(char)* animationName, int/*bool*/loop);

/** Adds an animation to be played delay seconds after the current or last queued animation, taking into account any mix duration. */
spTrackEntry* spAnimationState_addAnimationByName (spAnimationState* self, int trackIndex, const(char)* animationName, int/*bool*/loop, float delay);

void spAnimationState_update (spAnimationState* self, float delta);

void spAnimationState_apply (spAnimationState* self, spSkeleton* skeleton);
