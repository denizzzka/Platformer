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
    }

    void read()
    {
        _cpBodies.length = 0;
        _spBones.length = 0;

        cpBody*[spBone*] _bodies;

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

            cpBody* currBody = space.cpSpaceAddBody(cpBodyNew(1.0f, 10.0f));
            currBody.cpBodySetPos = cpv(currBone.worldX, currBone.worldY);
            currBody.setAngle = currBone.rotation.deg2rad;

            _cpBodies ~= currBody;
            _spBones ~= currBone;
            _bodies[currBone] = currBody;
        }

        // join bodies
        foreach(i; 0 .. skeleton.getSpSkeleton.bonesCount)
        {
            spBone* currBone = skeleton.getSpSkeleton.bones[i];

            while(currBone !is null)
            {
                if(currBone.parent !is null)
                {
                    auto currBody = (currBone in _bodies);
                    auto parentBody = (currBone.parent in _bodies);

                    assert(currBody !is null);
                    assert(parentBody !is null);

                    space.cpSpaceAddConstraint(cpPivotJointNew(*currBody, *parentBody, cpv(currBone.parent.worldX, currBone.parent.worldY)));
                }

                currBone = currBone.parent;
            }
        }
    }

    debug void applyImpulse()
    {
        _cpBodies[5].apply_impulse(cpv(-20, 0), cpv(-1, -5));
    }

    void update(float dt)
    {
        assert(_spBones.length);

        cpSpaceStep(space, dt);

        foreach(i, b; _spBones)
        {
            b.rotation = _cpBodies[i].a.rad2deg;
        }

        skeleton.updateWorldTransform();

        foreach(i, b; _spBones)
        {
            b.worldX = _cpBodies[i].p.x;
            b.worldY = _cpBodies[i].p.y;
        }
    }

    debug void draw(RenderTarget target, RenderStates states)
    {
        foreach(ref v; _spBones)
        {
            const(spBone)* curr = v;
            Vertex[] points;

            while(curr !is null)
            {
                if(curr.parent !is null)
                {
                    auto s = vec2f(curr.worldX, curr.worldY);
                    auto f = vec2f(curr.parent.worldX, curr.parent.worldY);

                    points ~= s.gfm_dsfml.Vertex(Color.Blue);
                    points ~= f.gfm_dsfml.Vertex(Color.Green);
                }

                curr = curr.parent;
            }

            target.draw(points, PrimitiveType.Lines, states);
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
