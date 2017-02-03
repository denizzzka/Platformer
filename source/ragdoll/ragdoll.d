module ragdoll;

import spine.skeleton;
import spine.skeleton_bounds;
import dchip.all;
import std.conv: to;
import math;
import chipmunk_map.gfm_interaction;
import chipmunk_map.extensions;
import chipmunk_map.chipbodyclass;
import std.array;
debug import dsfml.graphics;
debug import std.stdio;

private struct RagdollBody
{
    spBone* bone;
    ChipBody _body;

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
            f("head"),
            f("leg1"),
            f("leg2"),
            f("knee1"),
            f("knee2"),
            f("foot1"),
            f("foot2"),
            f("hand1"),
            f("hand2"),
            f("palm1"),
            f("palm2"),
            f("holder-primary"),
            f("holder-secondary"),
        ];

        assert(fixturesIdx.length > 0);

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
            ChipBody currBody = currRagdollBody is null ? null : currRagdollBody._body;

            import std.algorithm.searching;

            auto found = find!("a == b")(fixtures, currBone);

            // adding new body
            if(found.length != 0)
            {
                assert(found.length >= 1);

                RagdollBody* oldBody = currRagdollBody;

                currBody = new ChipBody(space);

                currBody.setAngle = (
                    currBone.worldRotation * spineAngleMirrorFactor
                ).deg2rad;

                RagdollBody newB;
                newB.bone = currBone;
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

                    const float angle = oldBody._body.a - currBody._body.a;
                    const float bias = PI_2 / 2;

                    space.cpSpaceAddConstraint(
                        cpRotaryLimitJointNew(
                            currBody,
                            oldBody._body,
                            angle - bias,
                            angle + bias
                        )
                    );
                }

                currRagdollBody = &bodies[$-1];
            }

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
    }

    private RagdollBody* findRagdollBody(const(spBone)* bone)
    {
        do
        {
            foreach(ref rb; bodies)
                if(rb.bone == bone)
                    return &rb;

            bone = bone.parent;
        }
        while(bone !is null);

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
        cpSpaceStep(space, dt);

        foreach(i, ref ragdollBody; bodies)
        {
            float worldDegAngle = ragdollBody._body.a.rad2deg * spineAngleMirrorFactor;

            if(i != 0)
            {
                assert(ragdollBody.parent !is null);

                worldDegAngle -= ragdollBody.bone.parent.worldRotation;
            }

            ragdollBody.bone.rotation = worldDegAngle;
        }

        skeleton.x = bodies[0]._body.p.x - rootOffset.x;
        skeleton.y = bodies[0]._body.p.y - rootOffset.y;
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
                    auto shape = bodyToAdd.addShape(slot, spineAngleIsMirorred, spineAngleMirrorFactor, skeleton);

                    space.cpSpaceAddShape(shape);
                }
            }
        }
    }

    debug void draw(RenderTarget target, RenderStates states)
    {
        // draw all bodies of space
        {
            space.forEachBody(
                (_body)
                {
                    enum radius = 50;
                    auto c = new CircleShape(radius, 30);
                    c.position = (_body.p.gfm_chip - radius).gfm_dsfml;
                    c.fillColor = Color.Transparent;
                    c.outlineColor = Color.Green;
                    c.outlineThickness = 1;

                    Vertex[2] v;
                    v[0] = _body.p.gfm_chip.gfm_dsfml.Vertex(Color.Green);

                    auto vect = _body.rot.gfm_chip.normalized * radius;
                    vect += _body.p.gfm_chip;

                    v[1] = vect.gfm_dsfml.Vertex(Color.Green);

                    target.draw(c, states);
                    target.draw(v, PrimitiveType.Lines, states);
                }
            );
        }

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
                        drawArgs.target.draw(points, PrimitiveType.LinesStrip, drawArgs.states);
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

    private bool spineAngleIsMirorred() const
    {
        return skeleton.flipX != skeleton.flipY;
    }

    private float spineAngleMirrorFactor() const
    {
        return spineAngleIsMirorred ? -1 : 1;
    }
}

private void flipVect(ref vec2f v, in SkeletonInstance sk)
{
    v.x *= sk.flipX ? -1 : 1;
    v.y *= sk.flipY ? -1 : 1;
}

private cpShape* addShape(cpBody* _body, in spSlot* slot, in bool angleIsMirorred, in float mirrorFactor, in SkeletonInstance sk)
{
    auto att  = cast(spBoundingBoxAttachment*) slot.attachment;

    assert(att._super.bonesCount == 0);

    cpVect[] v;

    for(auto verticeIdx = 0; verticeIdx < att._super.verticesCount; verticeIdx += 2)
    {
        auto vertice = vec2f(
                att._super.vertices[verticeIdx],
                att._super.vertices[verticeIdx + 1]
            );

        // наклоняем точку сообразно наклону кости, к которой она привязана
        vertice = vertice.rotated(slot.bone.worldRotation.deg2rad -_body.a * mirrorFactor);

        // отражаем по каждой из осей если скелет отражён по этой оси
        vertice.flipVect(sk);

        // расположение относительно начала кости
        auto offset = vec2f(
                slot.bone.worldX - _body.p.x,
                slot.bone.worldY - _body.p.y
            );

        // доворачиваем назад на угол, на который уже повёрнуто тело, к которому будет прикреплена кривая
        offset = offset.rotated(-_body.a);

        vertice += offset;

        {
            import std.array: insertInPlace;

            if(!angleIsMirorred)
                v.insertInPlace(0, vertice.gfm_chip);
            else
                v ~= vertice.gfm_chip;
        }
    }

    cpShape* shape = cpPolyShapeNew(_body, v.length.to!int, v.ptr, cpvzero);
    shape.cpShapeSetElasticity = 0.1f;
    shape.cpShapeSetFriction = 0.5f;
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
