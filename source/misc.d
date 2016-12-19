module misc;

import dsfml.graphics;
import std.exception: enforce;
import std.json;
import std.conv: to;

Texture loadTexture(string path)
{
    auto tileset = new Texture;
    enforce(tileset.loadFromFile(path));

    return tileset;
}

/// Need because TME or JSON library isn't respects JSON float convention
float getFloatFromJson(JSONValue j, string fieldName, float defaultValue)
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
