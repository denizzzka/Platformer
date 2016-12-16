module misc;

import dsfml.graphics;
import std.exception: enforce;

Texture loadTexture(string path)
{
    auto tileset = new Texture;
    enforce(tileset.loadFromFile(path));

    return tileset;
}
