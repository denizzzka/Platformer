module math;

public import gfm.math;

alias vec2i = gfm.math.vec2i;
alias vec2f = gfm.math.vec2f;

import std.traits;
import dsfml.system;

/// gfm and dsfml interaction
/// params:
/// Vs - source vector
/// Vr - result vector
auto gfm_dsfml(Vs)(Vs s)
if(isNumeric!(typeof(Vs.x)))
{
    alias T = Unqual!(typeof(Vs.x));

    static if(isInstanceOf!(dsfml.system.Vector2, Vs))
    {
        alias Vdest = Vector!(T, 2);
    }
    else static if(isInstanceOf!(gfm.math.Vector, Vs) && Vs.v.length == 2)
    {
        alias Vdest = Vector2!(T);
    }
    else
    {
        static assert(0, "Unsupported source type");
    }

    alias R = CopyConstness!(Vs, Vdest);

    return R(s.x, s.y);
}

unittest
{
    // g means gfm vector type
    // d means dsfml vector type
    {
        vec2i g = vec2i(1, 2);
        Vector2i d = g.gfm_dsfml;

        assert(d.x == g.x);
        assert(d.y == g.y);
    }
    {
        Vector2i d = Vector2i(1, 2);
        vec2i g = d.gfm_dsfml;

        assert(d.x == g.x);
        assert(d.y == g.y);
    }
    {
        const vec2f g = vec2i(1, 2);
        auto d = g.gfm_dsfml;

        static assert(is(typeof(d) == const Vector2f));
    }
    {
        const Vector2i d = Vector2i(1, 2);
        auto g = d.gfm_dsfml;

        static assert(is(typeof(g) == const vec2i));
    }
}
