module math;

public import gfm.math;

alias vec2i = gfm.math.vec2i;
alias vec2f = gfm.math.vec2f;

alias box2i = ImprovedBox!(gfm.math.box2i);
alias box2f = ImprovedBox!(gfm.math.box2f);

immutable left = vec2i(-1, 0);
immutable right = vec2i(1, 0);
immutable up = vec2i(0, -1);
immutable down = vec2i(0, 1);

bool isUp(T)(T v){ return v.y < 0; }
bool isDown(T)(T v){ return v.y > 0; }

struct ImprovedBox(B)
{
    B box;
    alias box this;

    alias V = typeof(box.min);
    alias T = typeof(V.x);

    this(T v1, T v2, T v3, T v4)
    {
        box = B(v1, v2, v3 ,v4);
    }

    auto width() const
    {
        return V(box.width, 0);
    }

    auto height() const
    {
        return V(0, box.height);
    }

    void flipY()
    {
        box.max.y *= -1;
    }
}

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

auto gfm_dsfml(Bs)(Bs s)
if(isInstanceOf!(gfm.math.Box, Bs) && Bs.bound_t.v.length == 2)
{
    alias T = Unqual!(typeof(Bs.min.x));
    alias Bdest = Rect!(T);
    alias R = CopyConstness!(Bs, Bdest);

    return R(s.min.x, s.min.y, s.width, s.height);
}

unittest
{
    // d means dsfml vector type
    // g means gfm vector type
    const d = const IntRect(10, 10, 100,100);
    auto g = d.gfm_dsfml;

    assert(g.min.x == d.left);
    assert(g.min.y == d.top);
    assert(g.width == d.width);
    assert(g.height == d.height);
    static assert(is(typeof(g) == const box2i));

    auto d2 = g.gfm_dsfml;
    assert(d2 == d);
    static assert(is(typeof(d2) == const IntRect));
}
