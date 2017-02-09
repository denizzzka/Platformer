module spine.dsfml2.textures_storage;

import spine.atlas;
import dsfml.graphics;

bool enforceSmooth = false;

public static Texture[size_t] loadedTextures; // FIXME: need package modifier
private static size_t texturesCount = 0;

private extern(C):

void _spAtlasPage_createTexture(spAtlasPage* self, const(char)* path)
{
    import misc: loadTexture;
    import std.string: fromStringz;
    import std.conv: to;

    Texture t = loadTexture(path.fromStringz.to!string);

	if (enforceSmooth || self.magFilter == spAtlasFilter.SP_ATLAS_LINEAR)
        t.setSmooth(true);

	if (self.uWrap == spAtlasWrap.SP_ATLAS_REPEAT && self.vWrap == spAtlasWrap.SP_ATLAS_REPEAT)
        t.setRepeated = true;

	self.width = t.getSize.x;
	self.height = t.getSize.y;
	self.rendererObject = cast(void*) texturesCount;

    loadedTextures[texturesCount] = t;

    texturesCount++;
}

void _spAtlasPage_disposeTexture(spAtlasPage* self)
{
    size_t textureNum = cast(size_t) self.rendererObject;

    loadedTextures.remove(textureNum);
}
