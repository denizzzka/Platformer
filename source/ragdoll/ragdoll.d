module ragdoll;

import spine.skeleton;
import spine.skeleton_bounds;
import dchip.all;
import std.conv: to;

class Ragdoll
{
    private cpSpace* space;
    private SkeletonInstance skeleton;
    private cpBody*[] bodies;

    this(cpSpace* sp, SkeletonInstance si)
    {
        space = sp;
        skeleton = si;
        bodies.length = 0; // TODO: странный баг происходит если эту инициализацию убрать

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
                shape.cpShapeSetElasticity = 0.0f;
                shape.cpShapeSetFriction = 0.8f;

                _body.cpBodyAddShape(shape);

                bodies ~= _body;
            }
        }
    }

    void updateSkeleton()
    {
        assert(bodies.length == skeleton.getSpSkeleton.slotsCount);

        foreach(size_t i, ref _body; bodies)
        {
            skeleton.getSpSkeleton.bones[i].worldX = _body.p.x;
            skeleton.getSpSkeleton.bones[i].worldY = _body.p.y;
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
