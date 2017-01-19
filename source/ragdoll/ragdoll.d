module ragdoll;

import spine.skeleton;
import spine.skeleton_bounds;
import dchip.all;
import std.conv: to;

class Ragdoll
{
    private cpSpace* space;
    private SkeletonInstance skeleton;

    this(cpSpace* sp, SkeletonInstance si)
    {
        space = sp;
        skeleton = si;

        foreach(i; 0 .. si.getSpSkeleton.slotsCount)
        {
            auto slot = si.getSpSkeleton.slots[i];

            if(slot.attachment !is null && slot.attachment.type == spAttachmentType.BOUNDING_BOX)
            {
                cpBody* _body = space.cpSpaceAddBody(cpBodyNew(1.0f, cpMomentForBox(1.0f, 30.0f, 30.0f)));
                _body.cpBodySetPos = cpv(slot.bone.worldX, slot.bone.worldY);

                cpVect[] v;

                spBoundingBoxAttachment* att = cast(spBoundingBoxAttachment*) slot.attachment;

                for(int n = att._super.verticesCount - 2; n >= 0; n -= 2)
                    v ~= cpVect(att._super.vertices[n], att._super.vertices[n+1]);

                cpShape* shape = cpPolyShapeNew(_body, v.length.to!int, v.ptr, cpvzero);

                space.staticBody.cpBodyAddShape(shape);

                shape.cpShapeSetElasticity = 0.0f;
                shape.cpShapeSetFriction = 0.8f;
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

    auto bounds = new SkeletonBounds;
    bounds.update(si1, false);
}
