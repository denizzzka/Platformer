module skeleton;

import std.json;
import std.exception: enforce;
import gfm.math: vec2f;

struct Bone
{
    Bone[] children;

    float rotation;
    vec2f coords;
    vec2f scale;
    debug float length;
}

struct Slot
{
    Bone* bone;
}

class Skeleton
{
    Bone root;
    Slot[] slots;

    this(string fileName)
    {
        import std.file: readText;

        Bone*[string] bonesNames;
        Slot*[string] slotsNames;

        auto json = fileName.readText.parseJSON;

        {

            foreach(i, j; json["bones"].array)
            {
                enforce(!(i == 0 && ("parent" in j)), "root must not contain parent");

                Bone* b;

                if(i)
                {
                    Bone* parent = *(j["parent"].str in bonesNames);
                    parent.children.length++;
                    b = &parent.children[$-1];
                }
                else
                {
                    b = &root;
                }

                b.rotation = j.optionalJson("rotation", 0);
                b.coords.x = j.optionalJson("x", 0);
                b.coords.y = j.optionalJson("y", 0);
                b.scale.x = j.optionalJson("scaleX", 1);
                b.scale.y = j.optionalJson("scaleY", 1);
                debug b.length = j.optionalJson("length", 0);

                bonesNames[j["name"].str] = b;
            }
        }

        {
            foreach(i, j; json["slots"].array)
            {
                slots.length++;
                slotsNames[j["name"].str] = &slots[$-1];

                slots[$-1].bone = bonesNames[j["bone"].str];

            }
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
