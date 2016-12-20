module spine.sfml;

import spine.atlas;
import dsfml.graphics;

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

unittest
{
    import spine.atlas;

    auto a = new Atlas("resources/textures/GAME.atlas");
    destroy(a);
}
