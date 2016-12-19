module skeleton;

import std.json;
import std.exception: enforce;
import gfm.math: vec2f;
import misc: getFloatFromJson;

struct Bone
{
    debug string name;
    Bone[] children;

    float rotation;
    vec2f coords;
    vec2f scale;
    debug float length;

    Timeline[] animations;
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
    BezierCurve bezier;

    void fillCommonFromJson(in JSONValue j)
    {
        time = j.getFloatFromJson("time", 0);
        curveType = j.curveTypeRead(bezier);
    }
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

struct Timepoint
{
    Bone* bone;
    RotateKeyframe rotate; // TODO: rename struct to Rotate
    TranslateKeyframe translate; // TODO: rename struct to Translate
}

class Skeleton
{
    Bone root;
    //~ Slot[] slots;
    size_t[string] animationsByNames;

    this(string fileName)
    {
        import std.file: readText;

        Bone*[string] bonesByNames;
        Slot*[string] slotsByNames;

        auto json = fileName.readText.parseJSON;

        foreach(i, j; json["bones"].array)
        {
            enforce(!(i == 0 && ("parent" in j)), "root must not contain parent");

            Bone* b;

            if(i)
            {
                Bone* parent = *(j["parent"].str in bonesByNames);
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

            bonesByNames[j["name"].str] = b;
            debug b.name = j["name"].str;
            import std.stdio; writeln(b.name, " b=");
        }

        //~ foreach(i, j; json["slots"].array)
        //~ {
            //~ slots.length++;
            //~ slotsByNames[j["name"].str] = &slots[$-1];

            //~ slots[$-1].bone = bonesByNames[j["bone"].str];
        //~ }

        foreach(animationName, j; json["animations"].object)
        {
            animationsByNames[animationName] = animationsByNames.length;

            foreach(boneName; bonesByNames.byKey)
            {
                Bone* bone = *(boneName in bonesByNames);
                bone.animations.length++;
                Timeline* timeline = &bone.animations[$-1];

                auto boneJson = (boneName in j["bones"].object);

                if(boneJson is null) // animation isn't specified for this bone, using default timeline values
                {
                    import std.stdio; writeln("Adding ", boneName, " using default. length=", bone.animations.length, " ptr=", bone);
                    continue;
                }

                foreach(timelineType, keyframeData; boneJson.object)
                {
                    switch(timelineType)
                    {
                        case "rotate":
                            foreach(t; keyframeData.array)
                            {
                                timeline.rotations.length++;
                                RotateKeyframe* k = &timeline.rotations[$-1];
                                k.fillCommonFromJson(t);
                                k.rotate = t.getFloatFromJson("angle", 0);
                            }
                            break;

                        case "translate":
                            foreach(t; keyframeData.array)
                            {
                                timeline.translations.length++;
                                TranslateKeyframe* k = &timeline.translations[$-1];
                                k.fillCommonFromJson(t);
                                k.translate.x = t.getFloatFromJson("x", 0);
                                k.translate.y = t.getFloatFromJson("y", 0);
                            }
                            break;

                        default:
                            enforce(0, "Unknown timeline type: "~timelineType);
                    }
                }

                import std.stdio;
                writeln("root=", root.animations.length, ", Adding ", boneName, ", length=", bone.animations.length, " ptr=", bone);
            }
        }
    }

    void callRecursive(string animationName, float time, void delegate(Timepoint) dg)
    {
        auto animation = (animationName in animationsByNames);
        assert(animation);

        Timepoint tp;
        tp.bone = &root;
        tp.rotate.time = time;
        tp.translate.time = time;

        callRecursive(*animation, dg, tp);
    }

    void callRecursive(in size_t animationIdx, void delegate(Timepoint) dg, Timepoint timepoint)
    {
        import std.stdio;

        writeln(">> ", timepoint.bone.animations.length, " bone_name=", timepoint.bone.name, " ptr=", timepoint.bone, " children:");

        foreach(ref chi; timepoint.bone.children)
            writeln(chi.name);

        auto timeline = timepoint.bone.animations[animationIdx];

        dg(timepoint);

        foreach(ref tp; timepoint.bone.children)
        {
            timepoint.bone = &tp;
            callRecursive(animationIdx, dg, timepoint);
        }
    }
}

unittest
{
    auto sk = new Skeleton("resources/animations/actor_pretty.json");

    import std.stdio;
    sk.callRecursive("run-forward", 1, (tp){});
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
