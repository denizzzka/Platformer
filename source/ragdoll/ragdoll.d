module ragdoll;

import spine.skeleton;
import spine.skeleton_bounds;
import spine.atlas: spRegionAttachment;
import dchip.all;
import std.conv: to;
import math;
import chipmunk_map.gfm_interaction;
debug import dsfml.graphics;
debug import std.stdio;

private struct RagdollBone
{
    spBone* bone;
    cpBody* _body;

    size_t parentIdx;
}

class Ragdoll
{
    private cpSpace* space;
    private SkeletonInstance skeleton;
    RagdollBone[] bones;
    spRegionAttachment*[] _spRegionAttachments;

    this(cpSpace* sp, SkeletonInstance si)
    {
        space = sp;
        skeleton = si;
    }

    void read()
    {
        _spRegionAttachments.length = 0;

        size_t[spBone*] _bodies;

        //~ foreach(i; 0 .. si.getSpSkeleton.slotsCount)
        //~ foreach(i; 0 .. 0)
        //~ {
            //~ auto slot = skeleton.getSpSkeleton.slots[i];

            //~ if(slot.attachment !is null && slot.attachment.type == spAttachmentType.REGION)
            //~ {
                //~ spRegionAttachment* att = cast(spRegionAttachment*) slot.attachment;

                //~ cpBody* _body = space.cpSpaceAddBody(cpBodyNew(1.0f, 10.0f/*cpMomentForBox(1.0f, att.width, att.height)*/));

                //~ _body.cpBodySetPos = cpv(slot.bone.worldX, slot.bone.worldY);
                //~ _body.setAngle((att.rotation + 180).deg2rad);

                //~ assert(att.width > 0);
                //~ assert(att.height > 0);

                //~ cpVect[4] _v;

                //~ _v[0] = cpv(0, 0);
                //~ _v[1] = cpv(0, att.height);
                //~ _v[2] = cpv(att.width, att.height);
                //~ _v[3] = cpv(att.width, 0);

                //~ cpShape* shape = cpPolyShapeNew(_body, _v.length.to!int, _v.ptr, cpvzero);
                //~ shape.cpShapeSetElasticity = 0.0f;
                //~ shape.cpShapeSetFriction = 0.0f;

                //~ _cpBodies ~= _body;
                //~ _spBones ~= slot.bone;
                //~ _bodies[slot.bone] = _body;
            //~ }
        //~ }

        // load all skeleton bones into physical bodies
        foreach(i; 0 .. skeleton.getSpSkeleton.bonesCount)
        {
            spBone* currBone = skeleton.getSpSkeleton.bones[i];

            cpBody* currBody = space.cpSpaceAddBody(cpBodyNew(1.0f, 100.0f));
            currBody.cpBodySetPos = cpv(currBone.worldX, currBone.worldY);
            currBody.setAngle = currBone.rotation.deg2rad;

            _bodies[currBone] = bones.length;
            bones ~= RagdollBone(currBone, currBody);
        }

        // join bodies
        foreach(ref b; bones)
        {
            spBone* currBone = b.bone;

            while(currBone !is null)
            {
                if(currBone.parent !is null)
                {
                    auto currIdx = (currBone in _bodies);
                    auto parentIdx = (currBone.parent in _bodies);

                    b.parentIdx = *parentIdx;

                    auto currBody = bones[*currIdx]._body;
                    auto parentBody = bones[*parentIdx]._body;

                    space.cpSpaceAddConstraint(
                        cpPivotJointNew(
                            currBody,
                            parentBody,
                            cpv(
                                currBone.parent.worldX,
                                currBone.parent.worldY
                            )
                        )
                    );
                }

                currBone = currBone.parent;
            }
        }

        //~ foreach(i; 0 .. skeleton.getSpSkeleton.slotsCount)
        //~ {
            //~ auto slot = skeleton.getSpSkeleton.slots[i];

            //~ if(slot.attachment !is null && slot.attachment.type == spAttachmentType.REGION)
            //~ {
                //~ spRegionAttachment* att = cast(spRegionAttachment*) slot.attachment;

                //~ if(slot.bone.parent !is null)
                //~ {
                    //~ cpBody* currBody = _bodies[slot.bone];
                    //~ cpBody* parentBody = _bodies[slot.bone.parent];

                    //~ space.cpSpaceAddConstraint(cpRotaryLimitJointNew(currBody, parentBody, 0.0f, 10.0f.deg2rad));
                //~ }
            //~ }
        //~ }
    }

    debug void applyImpulse()
    {
        bones[4]._body.apply_impulse(cpv(-20, 0), cpv(-1, -5));
    }

    void update(float dt)
    {
        cpSpaceStep(space, dt);

        foreach(ref b; bones)
        {
            if(b.bone.parent !is null)
            {
                RagdollBone* parent = &bones[b.parentIdx];

                b.bone.rotation = (b._body.a - parent._body.a).rad2deg + 90;
            }
        }

        skeleton.updateWorldTransform();

        // специальное поведение для косточек, к которым прикреплены картинки
        //~ foreach(i; 0 .. skeleton.getSpSkeleton.slotsCount)
        //~ {
            //~ auto slot = skeleton.getSpSkeleton.slots[i];

            //~ if(slot.attachment !is null && slot.attachment.type == spAttachmentType.REGION)
            //~ {
                //~ spRegionAttachment* att = cast(spRegionAttachment*) slot.attachment;

                //~ att.rotation = slot.bone.rotation;
            //~ }
        //~ }

        foreach(ref b; bones)
        {
            b.bone.worldX = b._body.p.x;
            b.bone.worldY = b._body.p.y;
        }
    }

    debug void draw(RenderTarget target, RenderStates states)
    {
        //~ foreach(ref v; _spBones)
        //~ {
            //~ const(spBone)* curr = v;
            //~ Vertex[] points;

            //~ while(curr !is null)
            //~ {
                //~ if(curr.parent !is null)
                //~ {
                    //~ auto s = vec2f(curr.worldX, curr.worldY);
                    //~ auto f = vec2f(curr.parent.worldX, curr.parent.worldY);

                    //~ points ~= s.gfm_dsfml.Vertex(Color.Blue);
                    //~ points ~= f.gfm_dsfml.Vertex(Color.Green);
                //~ }

                //~ curr = curr.parent;
            //~ }

            //~ target.draw(points, PrimitiveType.Lines, states);
        //~ }

        // рисуем только родителей слотов
        foreach(i; 0 .. skeleton.getSpSkeleton.slotsCount)
        {
            auto slot = skeleton.getSpSkeleton.slots[i];

            if(slot.attachment !is null && slot.attachment.type == spAttachmentType.REGION)
            {
                if(slot.bone.parent !is null)
                {
                    Vertex[] points;
                    auto curr = slot.bone;

                    auto s = vec2f(curr.worldX, curr.worldY);
                    auto f = vec2f(curr.parent.worldX, curr.parent.worldY);

                    points ~= s.gfm_dsfml.Vertex(Color.Blue);
                    points ~= f.gfm_dsfml.Vertex(Color.Green);

                    target.draw(points, PrimitiveType.Lines, states);
                }
            }
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
    r.read();
    r.update(0.3);

    auto bounds = new SkeletonBounds;
    bounds.update(si1, false);
}
