module skeleton;

import std.json;
import std.exception: enforce;
import gfm.math: vec2f;

struct Bone
{
    Bone* parent;
    Bone[] children;

    float rotation;
    vec2f coords;
    vec2f scale;
}

class Skeleton
{
    this(string fileName)
    {
        import std.file: readText;

        Bone*[string] bonesNames;

        auto json = fileName.readText.parseJSON;

        foreach(i, j; json["bones"].array)
        {
            enforce(!(i == 0 && ("parent" in j)), "root must not contain parent");

            auto b = new Bone;
            if(i) b.parent = bonesNames[j["parent"].str];
            b.rotation = j.optionalJson("rotation", 0);
            b.coords.x = j.optionalJson("x", 0);
            b.coords.y = j.optionalJson("y", 0);
            b.scale.x = j.optionalJson("scaleX", 1);
            b.scale.y = j.optionalJson("scaleY", 1);

            bonesNames[j["name"].str] = b;
        }
    }
}

unittest
{
    auto sk = new Skeleton("resources/animations/actor_pretty.json");
}

private float optionalJson(JSONValue json, string name, float defaultValue)
{
    if(auto val = (name in json))
    {
        return val.floating;
    }
    else
    {
        return defaultValue;
    }
}
