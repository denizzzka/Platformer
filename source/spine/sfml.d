module spine.sfml;

import spine.atlas;
import spine.skeleton;
import dsfml.graphics;
import dsfml.graphics.drawable;

class SkeletonInstanceDrawable : Drawable
{
    SkeletonInstance skeleton;
    alias skeleton this;

    this(SkeletonInstance si)
    {
        skeleton = si;
    }

    void draw(RenderTarget renderTarget, RenderStates renderStates = RenderStates())
    {
        for (int i = 0; i < skeleton.skeleton.slotsCount; ++i){}
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
