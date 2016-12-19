module misc;

import dsfml.graphics;
import std.exception: enforce;

Texture loadTexture(string path)
{
    auto tileset = new Texture;
    enforce(tileset.loadFromFile(path));

    return tileset;
}

import std.json;

// Need because TME or JSON library isn't respects JSON float convention
float getFloatFromJson(JSONValue j, string fieldName, float defaultValue)
{
    import std.conv: to;

    auto json = (fieldName in j);

    if(json is null)
    {
        return defaultValue;
    }
    else
    {
        if(json.type == JSON_TYPE.FLOAT)
            return json.floating;
        else if(json.type == JSON_TYPE.INTEGER)
            return json.integer.to!float;
        else assert(0);
    }
}
