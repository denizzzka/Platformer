module ragdoll;

import spine.skeleton;
import spine.skeleton_bounds;
import dchip.all;
import std.conv: to;

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

        cpBody*[spBone*] bones;

        foreach(i; 0 .. si.getSpSkeleton.slotsCount)
        {
            auto slot = si.getSpSkeleton.slots[i];

            cpBody* _body;

            {
                cpBody** res = (slot.bone in bones);

                if(res !is null)
                {
                    _body = *res;
                }
                else
                {
                    _body = space.cpSpaceAddBody(cpBodyNew(1.0f, cpMomentForBox(1.0f, 30.0f, 30.0f)));
                    _body.cpBodySetPos = cpv(slot.bone.x, slot.bone.y);

                    bones[slot.bone] = _body;
                    _cpBodies ~= _body;
                    _spBones ~= slot.bone;
                }
            }

            if(slot.attachment !is null && slot.attachment.type == spAttachmentType.BOUNDING_BOX)
            {
                cpVect[] v;

                spBoundingBoxAttachment* att = cast(spBoundingBoxAttachment*) slot.attachment;

                for(int n = att._super.verticesCount - 2; n >= 0; n -= 2)
                    v ~= cpVect(att._super.vertices[n], att._super.vertices[n+1]);

                cpShape* shape = cpPolyShapeNew(_body, v.length.to!int, v.ptr, cpvzero);
                shape.cpShapeSetElasticity = 0.0f;
                shape.cpShapeSetFriction = 0.8f;

                _body.cpBodyAddShape(shape);
            }
        }
    }

    void update(float dt)
    {
        cpSpaceStep(space, dt);

        foreach(i, b; _spBones)
        {
            b.x = _cpBodies[i].p.x;
            b.x = _cpBodies[i].p.y;

            //~ import std.stdio;
            //~ writeln(b.toString);
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
