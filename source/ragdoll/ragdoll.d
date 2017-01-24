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

    this(cpSpace* sp, SkeletonInstance si)
    {
        space = sp;
        skeleton = si;
    }

    void read()
    {
        // load all skeleton bones into physical bodies
        size_t rootIdx = skeleton.getSkeletonData.findBoneIndex("root");
        assert(rootIdx == 0);

        size_t leg1 = skeleton.getSkeletonData.findBoneIndex("leg1");
        size_t leg2 = skeleton.getSkeletonData.findBoneIndex("leg2");

        immutable size_t[] fixturesIdx = [rootIdx, leg1];

        spBone*[] fixtures;
        fixtures.length = 0;

        foreach(idx; fixturesIdx)
            fixtures ~= skeleton.getBoneByIndex(idx);

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
                currBody.cpBodySetPos = cpv(currBone.worldX, currBone.worldY);
                currBody.setAngle = currBone.worldRotation.deg2rad;

                RagdollBody newB;
                newB._body = currBody;
                newB.parent = oldBody;

                bodies ~= newB;

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

            foreach(idx; 0 .. skeleton.getSpSkeleton.bonesCount)
            {
                spBone* bone = skeleton.getSpSkeleton.bones[idx];

                if(bone.parent == currBone)
                    recursive(currRagdollBody, bone);
            }
        }

        recursive(null, skeleton.getRootBone);
    }

    void applyImpulse()
    {
        //~ bodies[0]._body.apply_impulse(cpv(10, 0), cpv(-10, 5));
        bodies[1]._body.apply_impulse(cpv(10, 0), cpv(-10, -10));
    }

    void update(float dt)
    {
        cpSpaceStep(space, dt);

        foreach(i, ref ragdollBody; bodies)
        {
            foreach(ref bone; ragdollBody.bones)
            {
                if(i == 0)
                {
                    assert(ragdollBody.parent is null);

                    bone.rotation = ragdollBody._body.a.rad2deg;
                }
                else
                {
                    RagdollBody* parent = ragdollBody.parent;

                    bone.rotation = (ragdollBody._body.a - parent._body.a).rad2deg;
                }
            }
        }

        skeleton.updateWorldTransform();

        //~ skeleton.getRootBone.worldX = bodies[0]._body.p.x;
        //~ skeleton.getRootBone.worldY = bodies[0]._body.p.y;
    }

    debug void draw(RenderTarget target, RenderStates states)
    {
        foreach(ref const ragdollBody; bodies)
        {
            foreach(ref const curr; ragdollBody.bones)
            {
                Vertex[] points;

                if(curr.parent !is null)
                {
                    auto s = vec2f(curr.worldX, curr.worldY);
                    auto f = vec2f(curr.parent.worldX, curr.parent.worldY);

                    points ~= s.gfm_dsfml.Vertex(Color.Blue);
                    points ~= f.gfm_dsfml.Vertex(Color.Green);
                }

                target.draw(points, PrimitiveType.Lines, states);
            }
        }
    }
}

private void setLocalPosition(spBone* bone, vec2f worldPosition)
{
    float x;
    float y;

    bone.worldToLocal(worldPosition.x, worldPosition.y, x, y);

    bone.x = x;
    bone.y = y;
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
