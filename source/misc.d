module misc;

import dsfml.graphics;
import std.exception: enforce;
import std.json;
import vibe.data.json;
import std.conv: to;

Texture loadTexture(string path)
{
    auto tileset = new Texture;
    enforce(tileset.loadFromFile(path));

    return tileset;
}

/// Need because TME or JSON library isn't respects JSON float convention
float getFloatFromJson(inout JSONValue j, string fieldName, float defaultValue)
{
    auto json = (fieldName in j);

    if(json is null)
        return defaultValue;
    else
        return getFloatFromJson(json);
}

/// ditto
float getFloatFromJson(T)(inout T json)
if(is(T == JSONValue) || is(T == JSONValue*))
{
    if(json.type == JSON_TYPE.FLOAT)
        return json.floating;
    else if(json.type == JSON_TYPE.INTEGER)
        return json.integer.to!float;
    else assert(0);
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
