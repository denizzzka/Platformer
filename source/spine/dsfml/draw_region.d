module spine.dsfml.draw_region;

import math;
import spine.atlas;
import spine.dsfml.textures_storage;
import scene.scene: atlas;
import dsfml.graphics;

class RegionDrawable : Drawable
{
    Sprite sprite;

    this(string regionName)
    {
        spAtlasRegion* region = atlas.findRegion(regionName);
        const textureNum = cast(size_t) region.page.rendererObject;

        Texture texture = loadedTextures[textureNum];
        assert(texture !is null);

        sprite = new Sprite(texture);
        assert(sprite !is null);

        with(region)
            sprite.textureRect = IntRect(x, y, width, height);
    }

    vec2f size()
    {
        with(sprite.textureRect)
            return vec2f(width, height);
    }

    void draw(RenderTarget target, RenderStates states)
    {
        target.draw(sprite, states);
    }
}
