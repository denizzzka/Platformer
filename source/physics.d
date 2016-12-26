module physics;

import map;
import dsfml.system;

enum TilesState // TODO: rename to PhysicalState?
{
    Default,
    PushesWall
}

class PhysicalObject
{
    const Map _map;

    Vector2f position;
    Vector2f acceleration = Vector2f(0, 0);

    PhysLayer.TileType tileType = PhysLayer.TileType.Empty;
    TilesState tilesState;
    bool onGround;
    bool rightDirection = false;

    this(Map m)
    {
        _map = m;
    }

    void doMotion(const Vector2f doAcceleration, const float deltaTime, const float g_force)
    {
        position += acceleration * deltaTime;

        const Vector2i tileCoords = _map.worldCoordsToTileCoords(position);
        tileType = _map.tileTypeByTileCoords(tileCoords);

        if(tileType == PhysLayer.TileType.Empty)
            onGround = false;

        if(!onGround)
        {
            // collide with ground
            if(acceleration.y > 0 && tileType.isGround)
            {
                position.y = _map.tileSize.y * tileCoords.y; // fell to upper side of this block
                onGround = true;
            }
        }

        // collide with walls
        if(acceleration.x > 0)
        {
            Vector2i rightTileCoords = tileCoords;
            rightTileCoords.y -= 1;

            auto tt = _map.tileTypeByTileCoords(rightTileCoords);

            if(tt == PhysLayer.TileType.Block)
                position.x = _map.tileSize.x * rightTileCoords.x - 1;
        }

        if(acceleration.x < 0)
        {
            Vector2i leftTileCoords = tileCoords;
            leftTileCoords.y -= 1;

            auto tt = _map.tileTypeByTileCoords(leftTileCoords);

            if(tt == PhysLayer.TileType.Block)
                position.x = _map.tileSize.x * (leftTileCoords.x + 1);
        }

        if(onGround)
        {
            // only on the ground unit can change its speed and direction
            acceleration = doAcceleration;

            if(tileType != PhysLayer.TileType.Ladder)
            {
                // prevent settling through the ground
                if(acceleration.y > 0)
                    acceleration.y = 0;

                // beginning jump
                if(acceleration.y < 0)
                    onGround = false;
            }
        }
        else
        {
            acceleration.y += g_force * deltaTime;
        }
    }
}

private bool isGround(PhysLayer.TileType t) pure
{
//    return t == PhysLayer.TileType.Block || t == PhysLayer.TileType.OneWay;
    return t != PhysLayer.TileType.Empty;
}

import gfm.math;
import std.traits;

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
