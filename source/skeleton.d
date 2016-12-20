module skeleton;

import std.json;
import std.exception: enforce;
import gfm.math: vec2f;
import misc: getFloatFromJson;
import std.stdio;

struct Bone
{
    string name; // TODO: make it available only for debug
    Bone[] children;

    float rotation;
    vec2f coords;
    vec2f scale;
    debug float length;

    Timeline[] animations;

    Bone* addEmptyChild()
    {
        children ~= Bone();

        return &children[$-1];
    }
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
    float rotate;
    vec2f translate;
}

class Skeleton
{
    Bone root;
    size_t[string] animationsByNames;

    this(string fileName)
    {
        import std.file: readText;

        auto json = fileName.readText.parseJSON;

        foreach(i, j; json["bones"].array)
        {
            enforce(!(i == 0 && ("parent" in j)), "root must not contain any parent");

            Bone* b;
            string name = j["name"].str;

            if(name == "root")
            {
                b = &root;
            }
            else
            {
                Bone* parent = findBone(j["parent"].str);
                b = parent.addEmptyChild;

                debug(skeleton)
                    writeln("Parent for next bone is ", parent.name, ", parent.ptr=", parent);
            }

            b.rotation = j.optionalJson("rotation", 0);
            b.coords.x = j.optionalJson("x", 0);
            b.coords.y = j.optionalJson("y", 0);
            b.scale.x = j.optionalJson("scaleX", 1);
            b.scale.y = j.optionalJson("scaleY", 1);
            debug b.length = j.optionalJson("length", 0);
            debug b.name = name;

            debug(skeleton)
                writeln("Added bone ", b.name, ", ptr=", b);
        }

        foreach(animationName, j; json["animations"].object)
        {
            animationsByNames[animationName] = animationsByNames.length;

            foreach(ref bone; getBonesList())
            {
                assert(bone);

                string boneName = bone.name;

                bone.animations.length++;
                Timeline* timeline = &bone.animations[$-1];

                auto boneJson = (boneName in j["bones"].object);

                debug(skeleton)
                    write("Animation ", animationName, " bone=", boneName, " bone.animations.length=", bone.animations.length, " ptr=", bone);

                if(boneJson is null) // animation isn't specified for this bone, using default timeline values
                {
                    debug(skeleton)
                        writeln(" using default.");

                    continue;
                }
                else
                {
                    debug(skeleton)
                        writeln("");
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
            }
        }
    }

    private void treeTraversal(void delegate(Bone*, size_t) dg, Bone* curr, size_t depth = 0)
    {
        dg(curr, depth);

        foreach(ref c; curr.children)
            treeTraversal(dg, &c, depth + 1);
    }

    debug override string toString()
    {
        string ret;

        void getBoneString(Bone* b, size_t depth)
        {
            foreach(i; 0 .. depth)
                ret~="  ";

            import std.conv: to;
            ret ~= b.name~" ptr="~b.to!string~" children.length="~b.children.length.to!string~"\n";
        }

        treeTraversal(&getBoneString, &root);

        return ret;
    }

    private Bone* findBone(string name)
    {
        Bone* ret;

        treeTraversal(
                (bone, lvl)
                {
                    if(bone.name == name)
                    {
                        ret = bone;
                        return;
                    }
                },
                &root
            );

        return ret;
    }

    private Bone*[] getBonesList()
    {
        Bone*[] ret;

        treeTraversal(
                (bone, lvl)
                {
                    ret ~= bone;
                },
                &root
            );

        return ret;
    }

    void calcTimepoint(string animationName, float time, void delegate(Bone*, Timepoint) dg)
    {
        auto animationIdx = animationsByNames[animationName];

        Timepoint rootTp;

        void boneDg(Bone* bone, size_t lvl)
        {
            Timepoint tp = rootTp;
            //~ tp.rotate.rotate = bone.animations[animationIdx].rotations[0].rotate;
            //~ tp.translate.translate = bone.animations[animationIdx].translations[0].translate;

            dg(bone, tp);
        }

        treeTraversal(&boneDg, &root);
    }
}

unittest
{
    auto sk = new Skeleton("resources/animations/actor_pretty.json");

    debug(skeleton)
        writeln(sk);

    sk.calcTimepoint("run-forward", 1, (bone, tp){});
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
