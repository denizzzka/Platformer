module spine.dsfml.draw_region;

import spine.atlas;
import spine.dsfml.textures_storage;
import dsfml.graphics;

private VertexArray vertexArray;

static this()
{
    vertexArray = new VertexArray(PrimitiveType.Triangles, 4);
}

void draw(spAtlasRegion* sp_atlasRegion, RenderTarget target, RenderStates states)
{
    //~ Texture texture;
    //~ Vertex[4] vertices;
    //~ Vertex vertex;
    //~ float[4] worldVertices;

    //~ size_t textureNum = cast(size_t) sp_atlasRegion.page.rendererObject;
    //~ texture = loadedTextures[textureNum];
    //~ assert(texture);

    //~ Color _c = Color.Red; // colorize(sp_skeleton_protected, slot);

    //~ Vector2u size = texture.getSize();

    //~ vertexArray.clear();

    //~ with(spVertexIndex)
    //~ {
        //~ with(vertices[0])
        //~ {
            //~ color = _c;
            //~ position.x = worldVertices[X1];
            //~ position.y = worldVertices[Y1];
            //~ debug(spine_dsfml) writeln("worldVertices[X1]=", worldVertices[X1]);
            //~ assert(!worldVertices[X1].isNaN);
            //~ texCoords.x = regionAttachment.uvs[X1] * size.x;
            //~ texCoords.y = regionAttachment.uvs[Y1] * size.y;
            //~ assert(worldVertices[X1] != float.nan);
            //~ assert(position.x != float.nan);
        //~ }

        //~ with(vertices[1])
        //~ {
            //~ color = _c;
            //~ position.x = worldVertices[X2];
            //~ position.y = worldVertices[Y2];
            //~ texCoords.x = regionAttachment.uvs[X2] * size.x;
            //~ texCoords.y = regionAttachment.uvs[Y2] * size.y;
        //~ }

        //~ with(vertices[2])
        //~ {
            //~ color = _c;
            //~ position.x = worldVertices[X3];
            //~ position.y = worldVertices[Y3];
            //~ texCoords.x = regionAttachment.uvs[X3] * size.x;
            //~ texCoords.y = regionAttachment.uvs[Y3] * size.y;
        //~ }

        //~ with(vertices[3]) {
            //~ color = _c;
            //~ position.x = worldVertices[X4];
            //~ position.y = worldVertices[Y4];
            //~ texCoords.x = regionAttachment.uvs[X4] * size.x;
            //~ texCoords.y = regionAttachment.uvs[Y4] * size.y;
        //~ }
    //~ }

    //~ with(vertexArray)
    //~ {
        //~ append(vertices[0]);
        //~ append(vertices[1]);
        //~ append(vertices[2]);
        //~ append(vertices[0]);
        //~ append(vertices[2]);
        //~ append(vertices[3]);
    //~ }

    //~ if(texture !is null)
    //~ {
        //~ // SMFL doesn't handle batching for us, so we'll just force a single texture per skeleton.
        //~ states.texture = texture;
        //~ debug(spine_dsfml) writeln("Used texture at ", &texture);
    //~ }
}
