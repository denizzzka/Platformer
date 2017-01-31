module ragdoll;

import spine.skeleton;
import spine.skeleton_bounds;
import dchip.all;
import std.conv: to;
import math;
import chipmunk_map.gfm_interaction;
import std.array;
debug import dsfml.graphics;
debug import std.stdio;

private struct RagdollBody
{
    spBone*[] bones;
    cpBody* _body;

    RagdollBody* parent;
}

class Ragdoll
{
    private cpSpace* space;
    private SkeletonInstance skeleton;
    private RagdollBody[] bodies;
    private vec2f rootOffset;

    this(cpSpace* sp, SkeletonInstance si)
    {
        space = sp;
        skeleton = si;
    }

    void read()
    {
        // load all skeleton bones into physical bodies
        assert(skeleton.getSkeletonData.findBoneIndex("root") == 0);

        auto f = &skeleton.getSkeletonData.findBoneIndex;

        immutable size_t[] fixturesIdx = [
            f("root"),
            //~ f("head"),
            //~ f("leg1"),
            //~ f("leg2"),
            //~ f("knee1"),
            //~ f("knee2"),
            //~ f("foot1"),
            //~ f("foot2"),
            f("hand1"),
            //~ f("hand2"),
            //~ f("palm1"),
            //~ f("palm2"),
            //~ f("holder-primary"),
            //~ f("holder-secondary"),
        ];

        spBone*[] fixtures;
        fixtures.length = 0;

        foreach(idx; fixturesIdx)
            fixtures ~= skeleton.getBoneByIndex(idx);

        rootOffset = vec2f(
                skeleton.getRootBone.worldX - skeleton.x,
                skeleton.getRootBone.worldY - skeleton.y
            );

        bodies.length = 0;

        void recursive(RagdollBody* currRagdollBody, spBone* currBone)
        {
            cpBody* currBody = currRagdollBody is null ? null : currRagdollBody._body;

            import std.algorithm.searching;

            auto found = find!("a == b")(fixtures, currBone);

            // adding new body
            if(found.length != 0)
            {
                assert(found.length >= 1);

                RagdollBody* oldBody = currRagdollBody;

                currBody = space.cpSpaceAddBody(cpBodyNew(1.0f, 10.0f));
                currBody.setAngle = (currBone.worldRotation - 90).deg2rad;

                RagdollBody newB;
                newB._body = currBody;
                newB.parent = oldBody;

                bodies ~= newB;

                currBody.cpBodySetPos = cpv(
                        currBone.worldX,
                        currBone.worldY
                    );

                if(oldBody !is null)
                {
                    space.cpSpaceAddConstraint(
                        cpPivotJointNew(
                            currBody,
                            oldBody._body,
                            currBody.p
                        )
                    );
                }

                currRagdollBody = &bodies[$-1];
            }

            currRagdollBody.bones ~= currBone;
            checkForAttachment(currBone, currBody);

            foreach(idx; 0 .. skeleton.getSpSkeleton.bonesCount)
            {
                spBone* bone = skeleton.getSpSkeleton.bones[idx];

                if(bone.parent == currBone)
                    recursive(currRagdollBody, bone);
            }
        }

        recursive(null, skeleton.getRootBone);

        assert(fixturesIdx.length == bodies.length);

        version(assert)
        {
            size_t bonesCount = 0;

            foreach(ref b; bodies)
                bonesCount += b.bones.length;

            writeln(bonesCount, " ", skeleton.getSpSkeleton.bonesCount);
            assert(bonesCount == skeleton.getSpSkeleton.bonesCount);
        }
    }

    private RagdollBody* findRagdollBody(in spBone* bone)
    {
        foreach(ref rb; bodies)
            foreach(ref b; rb.bones)
                if(b == bone)
                    return &rb;

        return null;
    }

    void applyImpulse(in spBone* bone, vec2f impulse)
    {
        auto rb = findRagdollBody(bone);
        assert(rb !is null);

        rb._body.apply_impulse(impulse.gfm_chip, cpvzero);
    }

    void update(float dt)
    {
        //~ cpSpaceStep(space, dt);

        foreach(i, ref ragdollBody; bodies)
        {
            if(i == 0)
            {
                assert(ragdollBody.parent is null);

                ragdollBody.bones[0].rotation = -ragdollBody._body.a.rad2deg + 90;
            }
            else
            {
                RagdollBody* parent = ragdollBody.parent;

                ragdollBody.bones[0].rotation = -(ragdollBody._body.a - parent._body.a).rad2deg + 90;
            }
        }

        skeleton.x = bodies[0]._body.p.x - rootOffset.x;
        skeleton.y = bodies[0]._body.p.y - rootOffset.y;

        skeleton.updateWorldTransform();
    }

    private void checkForAttachment(in spBone* bone, cpBody* bodyToAdd)
    {
        foreach(idx; 0 .. skeleton.getSpSkeleton.slotsCount)
        {
            auto slot = skeleton.getSpSkeleton.slots[idx];

            if(slot.bone == bone)
            {
                if(slot.attachment !is null && slot.attachment.type == spAttachmentType.BOUNDING_BOX)
                {
                    auto shape = bodyToAdd.addShape(slot);

                    space.cpSpaceAddShape(shape);
                }
            }
        }
    }

    debug void draw(RenderTarget target, RenderStates states)
    {
        foreach(ref ragdollBody; bodies)
        {
            // draw shapes
            {
                import chipmunk_map.extensions;

                struct DrawArgs
                {
                    RenderTarget target;
                    RenderStates states;
                }

                DrawArgs drawArgs;
                drawArgs.target = target;
                drawArgs.states = states;

                ragdollBody._body.cpBodyEachShape
                (
                    (bdy, shape, data)
                    {
                        cpVect[] vertices;

                        shape.forEachShapeVertice
                        (
                            (ref cpVect v)
                            {
                                vertices ~= v;
                            }
                        );

                        Vertex[] points;

                        foreach(ref v; vertices)
                            points ~= v.gfm_chip.gfm_dsfml.Vertex(Color.Blue);

                        if(vertices.length > 0)
                            points ~= vertices[0].gfm_chip.gfm_dsfml.Vertex(Color.Blue);

                        DrawArgs* drawArgs = cast(DrawArgs*) data;
                        //~ drawArgs.target.draw(points, PrimitiveType.LinesStrip, drawArgs.states);
                    },
                    cast(void*) &drawArgs
                );
            }

            // draw bones connections
            foreach(idx; 0 .. skeleton.getSpSkeleton.bonesCount)
            {
                const spBone* curr = skeleton.getSpSkeleton.bones[idx];

                Vertex[] points;

                if(curr.parent !is null)
                {
                    auto s = vec2f(curr.worldX, curr.worldY);
                    auto f = vec2f(curr.parent.worldX, curr.parent.worldY);

                    points ~= s.gfm_dsfml.Vertex(Color.Red);
                    points ~= f.gfm_dsfml.Vertex(Color.Red);
                }

                target.draw(points, PrimitiveType.Lines, states);
            }
        }
    }
}

private cpShape* addShape(cpBody* _body, in spSlot* slot)
{
    auto att  = cast(spBoundingBoxAttachment*) slot.attachment;

    assert(att._super.bonesCount == 0);

    cpVect[] v;

    for(auto verticeIdx = att._super.verticesCount - 2; verticeIdx >= 0;  verticeIdx -= 2)
    {
        auto vertice = vec2f(
                att._super.vertices[verticeIdx],
                att._super.vertices[verticeIdx + 1]
            );

        vertice = vertice.rotated(-((slot.bone.worldRotation + 0).deg2rad + _body.a));

        auto offset = vec2f(
                slot.bone.worldX - _body.p.x,
                slot.bone.worldY - _body.p.y
            );

        vertice += offset;

        v ~= vertice.gfm_chip;
    }

    cpShape* shape = cpPolyShapeNew(_body, v.length.to!int, v.ptr, cpvzero);
    //~ shape.cpShapeSetElasticity = 0.0f;
    shape.cpShapeSetFriction = 10.0f;
    shape.group = 1;

    return shape;
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
