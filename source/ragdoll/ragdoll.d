module ragdoll;

import spine.skeleton;
import spine.skeleton_bounds;
import spine.atlas: spRegionAttachment;
import dchip.all;
import std.conv: to;
import math;
import chipmunk_map.gfm_interaction;

class Ragdoll
{
    private cpSpace* space;
    private SkeletonInstance skeleton;
    cpBody*[] _cpBodies;
    spBone*[] _spBones;

    this(cpSpace* sp, SkeletonInstance si)
    {
        space = sp;
        skeleton = si;

        _cpBodies.length = 0;
        _spBones.length = 0;

        foreach(i; 0 .. si.getSpSkeleton.slotsCount)
        {
            auto slot = si.getSpSkeleton.slots[i];

            if(slot.attachment !is null && slot.attachment.type == spAttachmentType.REGION)
            {
                spRegionAttachment* att = cast(spRegionAttachment*) slot.attachment;

                cpBody* _body = space.cpSpaceAddBody(cpBodyNew(1.0f, cpMomentForBox(1.0f, att.width, att.height)));

                cpv absolutePos = cpv(slot.bone.worldX, slot.bone.worldY);
                _body.cpBodySetPos = absolutePos;

                vec2f[4] _v;
                cpVect[_v.length] v;

                _v[0] = vec2f(0, 0);
                _v[1] = vec2f(0, att.height);
                _v[2] = vec2f(att.width, att.height);
                _v[3] = vec2f(att.width, 0);

                foreach(n, ref vect; _v)
                    v[n] = vect.rotated(att.rotation.deg2rad).gfm_chip;

                cpShape* shape = cpPolyShapeNew(_body, v.length.to!int, v.ptr, cpvzero);
                shape.cpShapeSetElasticity = 0.0f;
                shape.cpShapeSetFriction = 0.0f;

                _cpBodies ~= _body;
                _spBones ~= slot.bone;
            }
        }
    }

    void update(float dt)
    {
        assert(_spBones.length);

        cpSpaceStep(space, dt);

        foreach(i, b; _spBones)
        {
            b.worldX = _cpBodies[i].p.x;
            b.worldY = _cpBodies[i].p.y;
        }
    }
}

unittest
{
    import spine.atlas;
    import spine.skeleton;
    import spine.skeleton_bounds;

    auto a = new Atlas("resources/textures/GAME.atlas");
    auto sd = new SkeletonData("resources/animations/actor_pretty.json", a);
    sd.defaultSkin = sd.findSkin("default");

    auto si1 = new SkeletonInstance(sd);

    auto space = cpSpaceNew();
    auto r = new Ragdoll(space, si1);
    r.update(0.3);

    auto bounds = new SkeletonBounds;
    bounds.update(si1, false);
}
