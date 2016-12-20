module spine.sfml;

import spine.atlas;
import dsfml.graphics;

private extern(C):

void _spAtlasPage_createTexture(spAtlasPage* self, const(char)* path)
{
	//~ Texture* texture = textures::LoadTexture(path);
	//~ self->width = texture->width;
	//~ self->height = texture->height;
	//~ self->rendererObject = texture;
}

void _spAtlasPage_disposeTexture(spAtlasPage* self)
{
	//~ Texture* texture = (Texture*)self->rendererObject;
	//~ render::ReleaseTexture(texture);
}

