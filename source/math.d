module math;

public import gfm.math;

alias vec2i = gfm.math.vec2i;
alias vec2f = gfm.math.vec2f;

alias box2i = gfm.math.box2i;
alias box2f = gfm.math.box2f;

import std.traits;
import dsfml.system;
import dsfml.graphics.rect;

/// gfm and dsfml interaction
/// params:
/// Vs - source vector
/// Vr - result vector
auto gfm_dsfml(Vs)(Vs s)
if(
    isInstanceOf!(dsfml.system.vector2.Vector2, Vs) ||
    (isInstanceOf!(gfm.math.Vector, Vs) && Vs.v.length == 2)
)
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
        static assert(0);
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

auto gfm_dsfml(Bs)(Bs s)
if(isInstanceOf!(dsfml.graphics.rect.Rect, Bs))
{
    alias T = Unqual!(typeof(Bs.left));
    alias Bdest = Box!(T, 2);
    alias R = CopyConstness!(Bs, Bdest);

    return R(s.left, s.top, s.left + s.width, s.top + s.height);
}

unittest
{
    // g means gfm vector type
    // d means dsfml vector type
    const d = const IntRect(10, 10, 100,100);
    auto g = d.gfm_dsfml;

    assert(g.min.x == d.left);
    assert(g.min.y == d.top);
    assert(g.width == d.width);
    assert(g.height == d.height);
    static assert(is(typeof(g) == const box2i));
}

//~ auto gfm_dsfml(Bs)(Bs s)
//~ if(
    //~ isInstanceOf!(dsfml.graphics.rect.Rect, Bs) ||
    //~ (isInstanceOf!(gfm.math.Box, Bs) && Bs.bound_t.v.length == 2)
//~ )
//~ {
    //~ alias T = Unqual!(typeof(Bs.x));

    //~ static if(isInstanceOf!(dsfml.graphics.rect.Rect, Bs))
    //~ {
        //~ alias Bdest = Box!(T, 2);
    //~ }
    //~ else static if(isInstanceOf!(gfm.math.Box, Bs) && Bs.bound_t.v.length == 2)
    //~ {
        //~ alias Bdest = Rect!(T);
    //~ }
    //~ else
    //~ {
        //~ static assert(0);
    //~ }

    //~ alias R = CopyConstness!(Bs, Bdest);

    //~ return R(s.x, s.y);
//~ }
