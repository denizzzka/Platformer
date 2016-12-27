module physics;

import map;
import math;

enum CollisionState // TODO: remove it?
{
    Default,
    TouchesOneWay,
    PushesLeftSlope,
    PushesRightSlope,
    PushesBlock,
    TouchesLadder
}

struct ImprovedBox(T)
{
    T box;
    alias box this;

    alias V = typeof(box.min);

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

class PhysicalObject
{
    const Map _map;

    vec2f position;
    vec2f acceleration = vec2f(0, 0);
    ImprovedBox!box2f aabb;

    bool onGround;
    bool onLadder;
    bool rightDirection = false;

    this(Map m)
    {
        _map = m;
    }

    ImprovedBox!box2i aabbTiled() const
    {
        ImprovedBox!box2i b;

        b.min = _map.worldCoordsToTileCoords(aabb.min);
        b.max = _map.worldCoordsToTileCoords(aabb.max);

        return b;
    }

    vec2i tileCoords() const
    {
        return _map.worldCoordsToTileCoords(position);
    }

    void doMotion(const vec2f doAcceleration, const float deltaTime, const float g_force)
    {
        // horizontal
        {
            position.x += acceleration.x * deltaTime;

            if(acceleration.x != 0)
            {
                vec2i blameTileCoords;
                CollisionState tileType = checkCollisionX(blameTileCoords);

                if(tileType == CollisionState.PushesLeftSlope && onGround)
                {
                    position.y -= acceleration.x * deltaTime;
                }
                else if(tileType == CollisionState.PushesBlock)
                {
                    if(acceleration.x > 0)
                        position.x = blameTileCoords.x * _map.tileSize.x - aabb.max.x - 1;
                    else
                        position.x = (blameTileCoords.x + 1) * _map.tileSize.x - aabb.min.x;

                    acceleration.x = 0;

                    import std.stdio;
                    writeln("pushes block!");
                }
            }
        }

        // vertical
        {
            position.y += acceleration.y * deltaTime;

            if(acceleration.y == 0)
            {
                vec2i blameTileCoords;
                auto bottomTileType = checkCollisionY(position + down, false, blameTileCoords);

                onGround = bottomTileType.canStanding;

                if(!onGround)
                    onLadder = false;

                if(bottomTileType == CollisionState.TouchesLadder)
                    onLadder = true;
            }
            else
            {
                // check what unit is still on ladder
                if(onLadder)
                {
                    vec2i tmp;
                    auto aabbStrictestTile = checkCollisionForFullAABB(tmp);

                    onLadder = (aabbStrictestTile == CollisionState.TouchesLadder);
                }

                {
                    const bool movesUp = acceleration.y < 0;
                    vec2i blameTileCoords;
                    auto tileType = checkCollisionY(position, movesUp, blameTileCoords);

                    if(tileType == CollisionState.TouchesLadder)
                    {
                        onLadder = true;
                        onGround = true;
                    }

                    if(movesUp)
                    {
                        onGround = onLadder; // it is jump or ladder

                        if(!tileType.isOneWay) // collide with ceiling
                        {
                            position.y = (blameTileCoords.y + 1) * _map.tileSize.y - aabb.max.y;
                            acceleration.y = 0; // speed damping due to the head
                        }
                    }
                    else // moves down
                    {
                        if(tileType.canStanding)
                        {
                            if(!onGround || tileType != CollisionState.TouchesLadder)
                            {
                                position.y = blameTileCoords.y * _map.tileSize.y - aabb.min.y - 1 /*"1" is "do not touch bottom tiles"*/;
                                acceleration.y = 0;
                                onGround = true;
                                onLadder = false;
                            }
                        }
                        else
                        {
                            onGround = false;
                            onLadder = false;
                        }
                    }
                }
            }
        }

        if(onGround)
        {
            // only on the ground unit can change its speed and direction
            acceleration = doAcceleration;
        }
        else
        {
            acceleration.y += g_force * deltaTime;
        }

        assert(!(onLadder && !onGround));
    }

    private CollisionState checkCollisionX(out vec2i blameTileCoords) const
    {
        assert(acceleration.x != 0);

        vec2f start = position;

        if(acceleration.x < 0) // move left
            start += aabb.max - aabb.width;
        else // move right
            start += aabb.max;

        return checkCollision(start, start - aabb.height, blameTileCoords);
    }

    private CollisionState checkCollisionY(vec2f start, bool movesUp, out vec2i blameTileCoords) const
    {
        if(movesUp)
            start += aabb.min + aabb.height;
        else // moves down
            start += aabb.min;

        return checkCollision(start, start + aabb.width, blameTileCoords);
    }

    private CollisionState checkCollision(vec2f start, vec2f end, out vec2i blameTileCoords) const
    {
        return checkCollision(_map.worldCoordsToTileCoords(start), _map.worldCoordsToTileCoords(end), blameTileCoords);
    }

    private CollisionState checkCollisionForFullAABB(out vec2i blameTileCoords) const
    {
        auto b = aabbTiled.translate(tileCoords);

        assert(b.size.x >= 0);
        assert(b.size.y <= 0);

        PhysLayer.TileType ret = PhysLayer.TileType.Empty;

        with(PhysLayer.TileType)
        with(CollisionState)
        {
            foreach(y; b.max.y .. b.min.y + 1)
            {
                foreach(x; b.min.x .. b.max.x + 1)
                {
                    vec2i coords = vec2i(x, y);
                    auto type = _map.tileTypeByTileCoords(coords);

                    if(type > ret)
                    {
                        ret = type;
                        blameTileCoords = coords;
                    }
                }
            }

            final switch(ret)
            {
                case Ladder:
                    return TouchesLadder;

                case Block:
                    return PushesBlock;

                case SlopeLeft:
                    return PushesLeftSlope;

                case SlopeRight:
                    return PushesLeftSlope;

                case OneWay:
                    return TouchesOneWay;

                case Empty:
                    return Default;
            }
        }
    }

    private CollisionState checkCollision(vec2i startTile, vec2i endTile, out vec2i blameTileCoords) const
    {
        version(assert) auto dir = endTile - startTile;
        assert(dir.x >= 0);
        assert(dir.y >= 0);

        PhysLayer.TileType ret = PhysLayer.TileType.Empty;

        with(PhysLayer.TileType)
        with(CollisionState)
        {
            foreach(y; startTile.y .. endTile.y + 1)
            {
                foreach(x; startTile.x .. endTile.x + 1)
                {
                    vec2i coords = vec2i(x, y);
                    auto type = _map.tileTypeByTileCoords(coords);

                    if(type > ret)
                    {
                        ret = type;
                        blameTileCoords = coords;
                    }
                }
            }

            final switch(ret)
            {
                case Ladder:
                    return TouchesLadder;

                case Block:
                    return PushesBlock;

                case SlopeLeft:
                    return PushesLeftSlope;

                case SlopeRight:
                    return PushesLeftSlope;

                case OneWay:
                    return TouchesOneWay;

                case Empty:
                    return Default;
            }
        }
    }
}

private bool canStanding(CollisionState t) pure
{
    return  t == CollisionState.PushesBlock ||
            t == CollisionState.TouchesLadder ||
            t == CollisionState.PushesLeftSlope ||
            t == CollisionState.PushesRightSlope ||
            t == CollisionState.TouchesOneWay;
}

private bool isOneWay(CollisionState t) pure
{
    return  t == CollisionState.TouchesOneWay ||
            t == CollisionState.PushesLeftSlope ||
            t == CollisionState.PushesRightSlope ||
            t == CollisionState.TouchesLadder ||
            t == CollisionState.Default;
}
