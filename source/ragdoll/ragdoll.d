module ragdoll;

import spine.skeleton;
import chipmunk_map;
import dchip.all;

class Ragdoll
{
    private ChipmunkMap chipmunkMap;
    private SkeletonInstance skeleton;

    this(ChipmunkMap cmap, SkeletonInstance si)
    {
        chipmunkMap = cmap;
        skeleton = si;

        foreach(i; 0 .. si.getSpSkeleton.bonesCount)
        {
        }
    }
}
