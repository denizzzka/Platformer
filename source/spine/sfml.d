module spine.sfml;

import spine.atlas;
import spine.skeleton;
import dsfml.graphics;
import dsfml.graphics.drawable;

class SkeletonInstanceDrawable : Drawable
{
    SkeletonInstance skeleton;
    alias skeleton this;

    VertexArray vertexArray;

    this(SkeletonInstance si)
    {
        skeleton = si;
        vertexArray = new VertexArray(PrimitiveType.Triangles, skeleton.skeleton.bonesCount * 4);
    }

    void draw(RenderTarget target, RenderStates states = RenderStates())
    {
        vertexArray.clear();

        Vertex[4] vertices;
        Vertex vertex;

        foreach(i; 0 .. skeleton.skeleton.slotsCount)
        {
            spSlot* slot = skeleton.skeleton.drawOrder[i];
            const spAttachment* attachment = slot.attachment;

            if(attachment is null)
                continue;

            BlendMode blend;
            switch(slot.data.blendMode)
            {
                case spBlendMode.SP_BLEND_MODE_ADDITIVE:
                    blend = BlendMode.Add;
                    break;

                case spBlendMode.SP_BLEND_MODE_MULTIPLY:
                    blend = BlendMode.Multiply;
                    break;

                case spBlendMode.SP_BLEND_MODE_SCREEN:
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

            //~ if(attachment)
            //~ {
                //~ texture = attachment.rendererObject.page.rendererObject;
                //~ regionAttachment.computeWorldVertices(slot.bone, worldVertices);

                //~ auto r = to!ubyte(skeleton.r * slot.r * 255f);
                //~ auto g = to!ubyte(skeleton.g * slot.g * 255f);
                //~ auto b = to!ubyte(skeleton.b * slot.b * 255f);
                //~ auto a = to!ubyte(skeleton.a * slot.a * 255f);

                //~ Vector2u size = texture.getSize();
                //~ with(vertices[0]){
                    //~ color.r = r;
                    //~ color.g = g;
                    //~ color.b = b;
                    //~ color.a = a;
                    //~ position.x = worldVertices[X1];
                    //~ position.y = worldVertices[Y1];
                    //~ texCoords.x = regionAttachment.uvs[X1] * size.x;
                    //~ texCoords.y = regionAttachment.uvs[Y1] * size.y;
                //~ }
                //~ with(vertices[1]) {
                    //~ color.r = r;
                    //~ color.g = g;
                    //~ color.b = b;
                    //~ color.a = a;
                    //~ position.x = worldVertices[X2];
                    //~ position.y = worldVertices[Y2];
                    //~ texCoords.x = regionAttachment.uvs[X2] * size.x;
                    //~ texCoords.y = regionAttachment.uvs[Y2] * size.y;
                //~ }
                //~ with(vertices[2]){
                    //~ color.r = r;
                    //~ color.g = g;
                    //~ color.b = b;
                    //~ color.a = a;
                    //~ position.x = worldVertices[X3];
                    //~ position.y = worldVertices[Y3];
                    //~ texCoords.x = regionAttachment.uvs[X3] * size.x;
                    //~ texCoords.y = regionAttachment.uvs[Y3] * size.y;
                //~ }
                //~ with(vertices[3]) {
                    //~ color.r = r;
                    //~ color.g = g;
                    //~ color.b = b;
                    //~ color.a = a;
                    //~ position.x = worldVertices[X4];
                    //~ position.y = worldVertices[Y4];
                    //~ texCoords.x = regionAttachment.uvs[X4] * size.x;
                    //~ texCoords.y = regionAttachment.uvs[Y4] * size.y;
                //~ }

                //~ with(vertexArray) {
                    //~ append(vertices[0]);
                    //~ append(vertices[1]);
                    //~ append(vertices[2]);
                    //~ append(vertices[0]);
                    //~ append(vertices[2]);
                    //~ append(vertices[3]);
                //~ }
            //~ }
                //~ else if(cast(MeshAttachment)attachment){
                //~ MeshAttachment mesh = cast(MeshAttachment)attachment;
                //~ texture = cast(Texture)(cast(AtlasRegion)mesh.rendererObject).page.rendererObject;
                //~ mesh.computeWorldVertices(slot, worldVertices);

                //~ vertex.color.r = to!ubyte(skeleton.r * slot.r * 255f);
                //~ vertex.color.g = to!ubyte(skeleton.g * slot.g * 255f);
                //~ vertex.color.b = to!ubyte(skeleton.b * slot.b * 255f);
                //~ vertex.color.a = to!ubyte(skeleton.a * slot.a * 255f);

                //~ Vector2u size = texture.getSize();
                //~ for(int j = 0; j < mesh.triangles.length; j++) {
                    //~ int index = mesh.triangles[j] << 1;
                    //~ vertex.position.x = worldVertices[index];
                    //~ vertex.position.y = worldVertices[index + 1];
                    //~ vertex.texCoords.x = mesh.uvs[index] * size.x;
                    //~ vertex.texCoords.y = mesh.uvs[index + 1] * size.y;
                    //~ vertexArray.append(vertex);
                //~ }

            //~ } else if(cast(SkinnedMeshAttachment)attachment) {
                //~ SkinnedMeshAttachment mesh = cast(SkinnedMeshAttachment)attachment;
                //~ texture = cast(Texture)(cast(AtlasRegion)mesh.rendererObject).page.rendererObject;
                //~ mesh.computeWorldVertices(slot, worldVertices);

                //~ vertex.color.r = to!ubyte(skeleton.r * slot.r * 255f);
                //~ vertex.color.g = to!ubyte(skeleton.g * slot.g * 255f);
                //~ vertex.color.b = to!ubyte(skeleton.b * slot.b * 255f);
                //~ vertex.color.a = to!ubyte(skeleton.a * slot.a * 255f);

                //~ Vector2u size = texture.getSize();
                //~ for(int j = 0; j < mesh.triangles.length; j++) {
                    //~ int index = mesh.triangles[j] << 1;
                    //~ vertex.position.x = worldVertices[index];
                    //~ vertex.position.y = worldVertices[index + 1];
                    //~ vertex.texCoords.x = mesh.uvs[index] * size.x;
                    //~ vertex.texCoords.y = mesh.uvs[index + 1] * size.y;
                    //~ vertexArray.append(vertex);
                //~ }
            //~ }

            //~ if(texture !is null) {
                //~ states.texture = texture;
            //~ }
        }

        //target.draw(vertexArray, states);
    }
}

SkeletonInstanceDrawable createDrawableInstance(SkeletonData sd) @property
{
    return new SkeletonInstanceDrawable(sd.createInstance);
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
