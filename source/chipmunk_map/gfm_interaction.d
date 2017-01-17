module chipmunk_map.gfm_interaction;

import math;
import dchip.all;
import std.traits;

/// gfm and chipmunk interaction
auto gfm_chip(Vs)(Vs s)
if(
    is(Vs == cpVect) ||
    (isInstanceOf!(gfm.math.Vector, Vs) && Vs.v.length == 2)
)
{
    alias T = Unqual!(typeof(Vs.x));

    static if(is(Vs == cpVect))
    {
        alias Vdest = Vector!(T, 2);
    }
    else static if(isInstanceOf!(gfm.math.Vector, Vs) && Vs.v.length == 2)
    {
        alias Vdest = cpVect;
    }
    else
    {
        static assert(0);
    }

    alias R = CopyConstness!(Vs, Vdest);

    return R(s.x, s.y);
}
