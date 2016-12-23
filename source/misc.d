module misc;

import dsfml.graphics;
import std.exception: enforce;
import vibe.data.json;
import std.conv: to;

Texture loadTexture(string path)
{
    auto tileset = new Texture;
    enforce(tileset.loadFromFile(path));

    return tileset;
}

/// ditto
T getFromJson(T)(inout Json j, string fieldName, T defaultValue)
{
    auto json = j[fieldName];

    if(json.type == Json.Type.undefined)
        return defaultValue;
    else
        return json.to!T;
}
