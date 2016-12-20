module spine.atlas;

import std.string: toStringz;
import std.exception;

class Atlas
{
    private spAtlas* atlas;

    this(string filename)
    {
        atlas = spAtlas_createFromFile(filename.toStringz, null);

        enforce(atlas);
    }

    ~this()
    {
        spAtlas_dispose(atlas);
    }
}

extern(C):

enum spAtlasFormat
{
	SP_ATLAS_UNKNOWN_FORMAT,
	SP_ATLAS_ALPHA,
	SP_ATLAS_INTENSITY,
	SP_ATLAS_LUMINANCE_ALPHA,
	SP_ATLAS_RGB565,
	SP_ATLAS_RGBA4444,
	SP_ATLAS_RGB888,
	SP_ATLAS_RGBA8888
};

enum spAtlasFilter
{
	SP_ATLAS_UNKNOWN_FILTER,
	SP_ATLAS_NEAREST,
	SP_ATLAS_LINEAR,
	SP_ATLAS_MIPMAP,
	SP_ATLAS_MIPMAP_NEAREST_NEAREST,
	SP_ATLAS_MIPMAP_LINEAR_NEAREST,
	SP_ATLAS_MIPMAP_NEAREST_LINEAR,
	SP_ATLAS_MIPMAP_LINEAR_LINEAR
};

enum spAtlasWrap
{
	SP_ATLAS_MIRROREDREPEAT,
	SP_ATLAS_CLAMPTOEDGE,
	SP_ATLAS_REPEAT
};

struct spAtlasPage
{
	const spAtlas* atlas;
	const char* name;
	spAtlasFormat format;
	spAtlasFilter minFilter, magFilter;
	spAtlasWrap uWrap, vWrap;

	void* rendererObject;
	int width, height;

	spAtlasPage* next;
};

private:

struct spAtlas;

spAtlas* spAtlas_createFromFile (const(char)* path, void* rendererObject);

void spAtlas_dispose (spAtlas* atlas);

char* _spUtil_readFile(const(char)* path, int* length)
{
    return _readFile(path, length);
}

char* _readFile (const(char)* path, int* length);