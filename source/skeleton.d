module skeleton;

import std.json;
import std.exception: enforce;
import gfm.math: vec2f;
import misc: getFloatFromJson;

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

struct BezierCurve
{
    float cx1;
    float cy1;
    float cx2;
    float cy2;
}

enum CurveType
{
    LINEAR,
    STEPPED,
    BEZIER
}

struct Keyframe
{
    float time;
    CurveType curveType = CurveType.LINEAR;
}

struct RotateKeyframe
{
    Keyframe keyframe;
    alias keyframe this;

    float rotate;
}

struct TranslateKeyframe
{
    Keyframe keyframe;
    alias keyframe this;

    vec2f translate;
}

struct Timeline
{
    RotateKeyframe[] rotations;
    TranslateKeyframe[] translations;
}

class Skeleton
{
    Bone root;
    Slot[] slots;
    Timeline[] timelines;

    this(string fileName)
    {
        import std.file: readText;

        Bone*[string] bonesNames;
        Slot*[string] slotsNames;
        Timeline*[string] timelinesNames;

        auto json = fileName.readText.parseJSON;

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

        foreach(i, j; json["slots"].array)
        {
            slots.length++;
            slotsNames[j["name"].str] = &slots[$-1];

            slots[$-1].bone = bonesNames[j["bone"].str];
        }

        foreach(keyName, j; json["animations"].object)
        {
            timelines.length++;
            Timeline* timeline = &timelines[$-1];
            timelinesNames[keyName] = timeline;

            foreach(boneName, boneJson; j["bones"].object)
            {
                foreach(timelineType, keyframeData; boneJson.object)
                {
                    switch(timelineType)
                    {
                        case "rotate":
                            foreach(t; keyframeData.array)
                            {
                                RotateKeyframe k;
                                k.time = t.getFloatFromJson("time", 0);
                                BezierCurve bezier;
                                k.curveType = t.curveTypeRead(bezier);
                                k.rotate = t.getFloatFromJson("angle", 0);

                                timeline.rotations ~= k;
                            }
                            break;

                        case "translate":
                            foreach(t; keyframeData.array)
                            {
                                TranslateKeyframe k;
                                k.time = t.getFloatFromJson("time", 0);
                                k.translate.x = t.getFloatFromJson("x", 0);
                                k.translate.y = t.getFloatFromJson("y", 0);

                                timeline.translations ~= k;
                            }
                            break;

                        default:
                            enforce(0, "Unknown timeline type: "~timelineType);
                    }
                }
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

private CurveType curveTypeRead(JSONValue j, out BezierCurve bezier)
{
    auto v = ("curve" in j);

    if(v == null)
    {
        return CurveType.LINEAR;
    }
    else
    {
        if(v.type == JSON_TYPE.STRING)
        {
            switch(v.str)
            {
                case "linear":
                    return CurveType.LINEAR;

                case "stepped":
                    return CurveType.STEPPED;

                default:
                    assert(0, "Unsupported curve type: "~v.str);
            }
        }
        else
        {
            bezier.cx1 = v.array[0].getFloatFromJson;
            bezier.cy1 = v.array[1].getFloatFromJson;
            bezier.cx2 = v.array[2].getFloatFromJson;
            bezier.cy1 = v.array[3].getFloatFromJson;

            return CurveType.BEZIER;
        }
    }
}
