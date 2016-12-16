module gdx_atlas;

import dsfml.graphics;

struct Page
{
    
}

class TextureAtlas
{
    Texture[] pages;

    this(string filePath)
    {
        import std.stdio: File;

        auto lines = File(filePath).byLine();

        foreach(l; lines)
        {
        }
    }
}

unittest
{
    string path = "resources/textures/GAME.atlas";
    auto atlas = new TextureAtlas(path);
}
