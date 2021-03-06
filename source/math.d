module math;

public import gfm.math;

alias vec2i = gfm.math.vec2i;
alias vec2f = gfm.math.vec2f;

alias box2i = ImprovedBox!(gfm.math.box2i);
alias box2f = ImprovedBox!(gfm.math.box2f);

immutable leftVec = vec2i(-1, 0);
immutable rightVec = vec2i(1, 0);
immutable upVec = vec2i(0, -1);
immutable downVec = vec2i(0, 1);

bool isLeftDirection(T)(T v){ return v.x < 0; }
bool isRightDirection(T)(T v){ return v.x > 0; }
bool isUpDirection(T)(T v){ return v.y < 0; }
bool isDownDirection(T)(T v){ return v.y > 0; }

struct ImprovedBox(B) // TODO: переделать это в temlate с функциями, расширяющими B
{
    B box;
    alias box this;

    alias V = typeof(box.min);
    alias T = typeof(V.x);

    this(B)(B b)
    {
        box = b;
    }

    this(T v1, T v2, T v3, T v4)
    {
        box = B(v1, v2, v3 ,v4);
    }

    this(V min, V max)
    {
        box.min = min;
        box.max = max;
    }

    auto width() const
    {
        return V(box.width, 0);
    }

    auto height() const
    {
        return V(0, box.height);
    }

    ImprovedBox flipY() const
    {
        ImprovedBox b = this;

        b.max.y *= -1;

        return b;
    }

    ImprovedBox sort() const
    out(ret)
    {
        assert(ret.isSorted);
    }
    body
    {
        return ImprovedBox
            (
                min.x < max.x ? min.x : max.x,
                min.y < max.y ? min.y : max.y,
                min.x > max.x ? min.x : max.x,
                min.y > max.y ? min.y : max.y
            );
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
    static assert(is(typeof(g) == const (gfm.math.box2i)));

    auto d2 = g.gfm_dsfml;
    assert(d2 == d);
    static assert(is(typeof(d2) == const IntRect));
}

vec2f rotated(inout vec2f s, float angle)
{
    import std.math;

    vec2f ret;

    with(s)
    {
        ret.x = x * cos(angle) - y * sin(angle);
        ret.y = y * cos(angle) + x * sin(angle);
    }

    return ret;
}

T rad2deg(T)(T radians) pure
{
    import std.math;

    return radians * 180.0 / PI;
}

T deg2rad(T)(T degrees) pure
{
    import std.math;

    return degrees * PI / 180.0;
}
