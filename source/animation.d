module animation;

import skeleton;

class Animated
{
    Skeleton skeleton;

    this(string fileName)
    {
        skeleton = new Skeleton(fileName);
    }
}

unittest
{
    auto a = new Animated("resources/animations/actor_pretty.json");
}
