module gdx_atlas;

import std.file: readText;

void atlasRead(string filePath)
{
    string text = readText(filePath);
}

unittest
{
    string path = "resources/textures/GAME.atlas";
    atlasRead(path);
}
