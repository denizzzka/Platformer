module soldier;

struct Bone
{
    Bone* parent;
    Bone[] children;

    float angle;
}
