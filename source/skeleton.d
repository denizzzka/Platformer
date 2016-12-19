module skeleton;

struct Bone
{
    Bone* parent;
    Bone[] children;

    float angle;
}

class Skeleton
{
    this(string fileName)
    {
        import std.json;
        import std.file: readText;

        auto json = fileName.readText.parseJSON;
    }
}
