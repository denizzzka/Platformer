module gdx_atlas;

import std.file: readText;

class TextureAtlas
{
    this(string filePath)
    {
        string text = readText(filePath);
    }
}

unittest
{
    string path = "resources/textures/GAME.atlas";
    auto atlas = new TextureAtlas(path);
}
