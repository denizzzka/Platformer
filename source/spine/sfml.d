module spine.sfml;

import spine.atlas;
import spine.skeleton;
import spine.animation;
import dsfml.graphics;
import dsfml.graphics.drawable;
debug(dsfml) import std.stdio;

enum SPINE_MESH_VERTEX_COUNT_MAX = 1000;

class SkeletonInstanceDrawable : Drawable
{
    SkeletonInstance skeleton;
    alias skeleton this;

    AnimationStateInstance animation;
    VertexArray vertexArray;
    float[SPINE_MESH_VERTEX_COUNT_MAX] worldVertices;

    this(SkeletonInstance si, AnimationStateInstance asi)
    {
        skeleton = si;
        animation = asi;
        vertexArray = new VertexArray(PrimitiveType.Triangles, skeleton.skeleton.bonesCount * 4);
    }

    void draw(RenderTarget target, RenderStates states = RenderStates())
    {
        debug(dsfml) writeln("spine.dsfml.SkeletonInstanceDrawable.draw()");
        vertexArray.clear();

        Vertex[4] vertices;
        Vertex vertex;

        foreach(i; 0 .. skeleton.skeleton.slotsCount)
        {
            debug(dsfml) writeln("slot num=", i);

            spSlot* slot = skeleton.skeleton.drawOrder[i];
            const spAttachment* attachment = slot.attachment;

            if(attachment is null) continue;

            BlendMode blend;

            switch(slot.data.blendMode)
            {
                case spBlendMode.ADDITIVE:
                    blend = BlendMode.Add;
                    break;

                case spBlendMode.MULTIPLY:
                    blend = BlendMode.Multiply;
                    break;

                case spBlendMode.SCREEN: // Unsupported, fall through.
                default:
                    blend = BlendMode.Alpha;
            }

            if(states.blendMode != blend)
            {
                target.draw(vertexArray, states);
                vertexArray.clear();
                states.blendMode = blend;
            }

            Texture texture;

            if(attachment.type == spAttachmentType.REGION)
            {
                debug(dsfml) writeln("draw region");

                spRegionAttachment* regionAttachment = cast(spRegionAttachment*) attachment;
                texture = cast(Texture)(cast(spAtlasRegion*)regionAttachment.rendererObject).page.rendererObject;

                debug(dsfml) writeln("call computeWorldVertices");
                spRegionAttachment_computeWorldVertices(regionAttachment, slot.bone, worldVertices.ptr);

                debug(dsfml) writeln("call colorize");
                Color _c = colorize(skeleton, slot);

                debug(dsfml) writeln("call texture.getSize()");
                Vector2u size = texture.getSize();

                debug(dsfml) writeln("fill vertices");

                with(spVertexIndex)
                {
                    with(vertices[0])
                    {
                        color = _c;
                        position.x = worldVertices[X1];
                        position.y = worldVertices[Y1];
                        texCoords.x = regionAttachment.uvs[X1] * size.x;
                        texCoords.y = regionAttachment.uvs[Y1] * size.y;
                    }

                    with(vertices[1])
                    {
                        color = _c;
                        position.x = worldVertices[X2];
                        position.y = worldVertices[Y2];
                        texCoords.x = regionAttachment.uvs[X2] * size.x;
                        texCoords.y = regionAttachment.uvs[Y2] * size.y;
                    }

                    with(vertices[2])
                    {
                        color = _c;
                        position.x = worldVertices[X3];
                        position.y = worldVertices[Y3];
                        texCoords.x = regionAttachment.uvs[X3] * size.x;
                        texCoords.y = regionAttachment.uvs[Y3] * size.y;
                    }

                    with(vertices[3]) {
                        color = _c;
                        position.x = worldVertices[X4];
                        position.y = worldVertices[Y4];
                        texCoords.x = regionAttachment.uvs[X4] * size.x;
                        texCoords.y = regionAttachment.uvs[Y4] * size.y;
                    }
                }

                with(vertexArray)
                {
                    append(vertices[0]);
                    append(vertices[1]);
                    append(vertices[2]);
                    append(vertices[0]);
                    append(vertices[2]);
                    append(vertices[3]);
                }
            }
            else if(attachment.type == spAttachmentType.MESH)
            {
                debug(dsfml) writeln("draw mesh");

                spMeshAttachment* mesh = cast(spMeshAttachment*) attachment;

                if (mesh._super.worldVerticesLength > SPINE_MESH_VERTEX_COUNT_MAX) continue;
                texture = cast(Texture)(cast(spAtlasRegion*)mesh.rendererObject).page.rendererObject;
                spMeshAttachment_computeWorldVertices(mesh, slot, worldVertices.ptr);

                vertex.color = colorize(skeleton, slot);
                Vector2u size = texture.getSize();

                foreach(_i; 0 .. mesh.trianglesCount)
                {
                    int index = mesh.triangles[_i] << 1;
                    vertex.position.x = worldVertices[index];
                    vertex.position.y = worldVertices[index + 1];
                    vertex.texCoords.x = mesh.uvs[index] * size.x;
                    vertex.texCoords.y = mesh.uvs[index + 1] * size.y;
                    vertexArray.append(vertex);
                }
            }

            if(texture !is null)
            {
                // SMFL doesn't handle batching for us, so we'll just force a single texture per skeleton.
                states.texture = texture;
            }
        }

        debug(dsfml) writeln("call SFML draw");
        target.draw(vertexArray, states);
    }
}

SkeletonInstanceDrawable createDrawableInstance(SkeletonData sd) @property
{
    auto stateData = new AnimationStateData(sd);
	auto stateInst = new AnimationStateInstance(stateData);

    return new SkeletonInstanceDrawable(sd.createInstance, stateInst);
}

unittest
{
    import spine.atlas;
    import spine.skeleton;

    auto a = new Atlas("resources/textures/GAME.atlas");
    auto sd = new SkeletonData("resources/animations/actor_pretty.json", a, 1);
    auto si1 = sd.createInstance;
    auto si2 = sd.createDrawableInstance;

    destroy(a);
    destroy(sd);
    destroy(si1);
    destroy(si2);
}

Color colorize(spSkeleton* skeleton,  spSlot* slot)
{
    import std.conv: to;

    Color ret;

    with(ret)
    {
        r = (skeleton.r * slot.r * 255.0f).to!ubyte;
        g = (skeleton.g * slot.g * 255.0f).to!ubyte;
        b = (skeleton.b * slot.b * 255.0f).to!ubyte;
        a = (skeleton.a * slot.a * 255.0f).to!ubyte;
    }

    return ret;
}

private extern(C):

void _spAtlasPage_createTexture(spAtlasPage* self, const(char)* path)
{
    import misc: loadTexture;
    import std.string: fromStringz;
    import std.conv: to;

    Texture t = loadTexture(path.fromStringz.to!string);

	self.width = t.getSize.x;
	self.height = t.getSize.y;
	self.rendererObject = cast(void*) t;
}

void _spAtlasPage_disposeTexture(spAtlasPage* self)
{
    Texture t = cast(Texture) self.rendererObject;
    destroy(t);
}

void spRegionAttachment_computeWorldVertices (spRegionAttachment* self, const(spBone)* bone, float* vertices);

void spMeshAttachment_computeWorldVertices (spMeshAttachment* self, spSlot* slot, float* worldVertices);
