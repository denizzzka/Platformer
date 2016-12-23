module map;

import dsfml.graphics;
import std.exception: enforce;
import std.conv: to;
import gfm.math: box2f;
import misc: loadTexture;
import vibe.data.json;

struct Layer
{
    enum Type
    {
        TILES,
        IMAGE
    }

    Type type;
    string name;
    Vector2f offset = Vector2f(0, 0);
    Vector2i layerSize; //TODO: it is equal for all tiles layers, need to move it to Map
    float opacity = 1;
    float scale = 1; /// scale factor
    ushort[] spriteNumbers; // for tile layers only
    Sprite image; // for image layers only
    float parallax = 1;
    bool drawUnits;
}

private size_t coords2index(T)(T s, Vector2i coords)
if(is(T == Layer) || is(T == PhysLayer))
{
    auto ret = s.layerSize.x * coords.y + coords.x;

    assert(ret < s.spriteNumbers.length);

    return ret;
}

struct PhysLayer
{
    enum TileType : ubyte
    {
        Empty,
        Block,
        OneWay,
        Stair,
        SlopeLeft,
        SlopeRight
    }

    TileType[] tiles;
    alias spriteNumbers = tiles;
    Vector2i layerSize;
}

class Map
{
    const string fileName;
    const Vector2i tileSize;
    Layer[] layers;
    Texture[] tilesets;
    Sprite[] tileSprites;
    PhysLayer physLayer;
    void delegate() unitsDrawCallback;

    this(string mapName)
    {
        this.fileName = "resources/maps/"~mapName~".json";

        Json j = loadJsonDocument(fileName);

        enforce(j["version"].get!int == 1, "Map file version mismatch");

        tileSize = Vector2i(
                j["tilewidth"].get!int,
                j["tileheight"].get!int
            );

        foreach(ts; j["tilesets"])
        {
            if("image" in ts)
            {
                auto tileset = loadTexture("resources/maps/test_map/"~ts["image"].get!string);

                int tileWidth = ts["tilewidth"].get!int;
                int tileHeight = ts["tileheight"].get!int;

                size_t columns = tileset.getSize.x / tileWidth;
                size_t rows = tileset.getSize.y / tileHeight;

                enforce(columns * rows == ts["tilecount"].get!int);

                for(int y; y < rows; y++)
                {
                    for(int x; x < columns; x++)
                    {
                        IntRect rect;

                        rect.top = y * tileHeight;
                        rect.left = x * tileWidth;

                        rect.height = tileHeight;
                        rect.width = tileWidth;

                        tileSprites ~= new Sprite(tileset);
                        tileSprites[$-1].textureRect = rect;
                    }
                }

                tilesets ~= tileset;
            }
        }

        foreach(l; j["layers"])
        {
            Layer layer;
            PhysLayer.TileType[ushort] physTilesMapping;
            bool isPhysLayer = false;

            layer.name = l["name"].get!string;

            // Need because TME or JSON library isn't respects JSON float convention
            import misc: getF = getFromJson;

            layer.opacity = getF(l, "opacity", 1);
            layer.offset.x = getF(l, "offsetx", 0);
            layer.offset.y = getF(l, "offsety", 0);

            Json properties = l["properties"];
            if(properties.type != Json.Type.undefined)
            {
                isPhysLayer = getF(properties, "solid", false);
                layer.drawUnits = getF(properties, "units", false);
                layer.parallax = getF(properties, "parallax", 1.0f);
                layer.scale = getF(properties, "scale", 1.0f);
            }

            if(l["type"].get!string == "tilelayer")
            {
                layer.type = Layer.Type.TILES;

                layer.layerSize.x = l["width"].get!uint;
                layer.layerSize.y = l["height"].get!uint;

                enforce(
                        layer.offset.x <= 0 &&
                        layer.offset.y <= 0,
                        "Layer "~layer.name~" have positive offset"
                    );

                enforce(
                        layer.offset.x > -tileSize.x &&
                        layer.offset.y > -tileSize.y,
                        "Layer "~layer.name~" offset is too big"
                    );

                layer.spriteNumbers.length = l["data"].length;

                foreach(size_t n, d; l["data"])
                {
                    layer.spriteNumbers[n] = d.get!ushort;

                    if(isPhysLayer)
                    {
                        physLayer.tiles.length = layer.spriteNumbers.length;
                        physLayer.layerSize = layer.layerSize;

                        foreach(i, ref tile; physLayer.tiles)
                        {
                            auto spriteNum = layer.spriteNumbers[i];

                            if(spriteNum != 0)
                            {
                                PhysLayer.TileType* foundType = (spriteNum in physTilesMapping);

                                if(foundType)
                                    tile = *foundType;
                                else
                                    tile = PhysLayer.TileType.Block;
                            }
                        }
                    }
                }

            }
            else if(l["type"].get!string == "imagelayer")
            {
                layer.type = Layer.Type.IMAGE;

                auto img = loadTexture("resources/maps/test_map/"~l["image"].get!string);
                layer.image = new Sprite(img);
                layer.image.position = layer.offset;
                layer.image.scale = Vector2f(layer.scale, layer.scale);
                layer.image.color = Color(255, 255, 255, (255 * layer.opacity).to!ubyte);
            }
            else assert(0);

            // Search special types of tiles (slopes, stairs, etc). Used for physics.
            if(layer.name == "__solid")
            {
                enforce(layer.layerSize.y >= 5, "__solid layer is too small");

                void mapType(PhysLayer.TileType type, int lineNumber)
                {
                    foreach(x; 0 .. layer.layerSize.x)
                    {
                        size_t tileIdx = layer.coords2index(Vector2i(x, lineNumber));
                        ushort spriteNum = layer.spriteNumbers[tileIdx];
                        physTilesMapping[spriteNum] = type;
                    }
                }

                with(PhysLayer.TileType)
                {
                    mapType(OneWay, 0);
                    mapType(Stair, 1);
                    mapType(SlopeLeft, 2);
                    mapType(SlopeRight, 3);
                    mapType(SlopeRight, 4);
                }
            }
            else
            {
                layers ~= layer;
            }
        }
    }

    /// corner - top left corner of scene
    void draw(RenderWindow window, Vector2f corner)
    {
        foreach(lay; layers)
        {
            window.view = new View(FloatRect(corner * lay.parallax, Vector2f(window.size)));

            if(lay.type == Layer.Type.TILES)
            {
                renderTilesLayer(lay, window, corner,
                    (coords)
                    {
                        auto idx = lay.coords2index(coords);
                        auto spriteNumber = lay.spriteNumbers[idx];

                        if(spriteNumber != 0)
                        {
                            auto sprite = &tileSprites[spriteNumber - 1];
                            auto pos = Vector2f(coords.x * tileSize.x + lay.offset.x, coords.y * tileSize.y + lay.offset.y);

                            sprite.position = pos;
                            sprite.color = Color(255, 255, 255, (255 * lay.opacity).to!ubyte);

                            window.draw(*sprite);
                        }
                    }
                );
            }
            else if(lay.type == Layer.Type.IMAGE)
            {
                window.draw(lay.image);
            }
            else assert(0);

            if(lay.drawUnits && unitsDrawCallback !is null)
                unitsDrawCallback();
        }
    }

    /// corner - top left corner of scene
    private void renderTilesLayer(Layer lay, RenderWindow window, Vector2f corner, void delegate(Vector2i coords) renderer)
    {
        assert(lay.type == Layer.Type.TILES);

        window.view = new View(FloatRect(corner * lay.parallax, Vector2f(window.size)));

        Vector2i cornerTile = Vector2i(
                corner.x.to!int / tileSize.x,
                corner.y.to!int / tileSize.y
            );

        Vector2i tilesScreenSize = window.size;
        {
            tilesScreenSize.x /= tileSize.x;
            tilesScreenSize.y /= tileSize.y;

            tilesScreenSize.x += 2;
            tilesScreenSize.y += 2;
        }

        Vector2i latestTile = cornerTile + tilesScreenSize;

        foreach(y; cornerTile.y .. latestTile.y)
            foreach(x; cornerTile.x .. latestTile.x)
                if(
                    x >= 0 && x < lay.layerSize.x &&
                    y >= 0 && y < lay.layerSize.y
                )
                {
                    renderer(Vector2i(x, y));
                }
    }

    /// After render layer with option units=true this callback will be called.
    void registerUnitsDrawCallback(void delegate() callback)
    {
        enforce(unitsDrawCallback is null);

        unitsDrawCallback = callback;
    }

    private Vector2i worldCoordsToTileCoords(Vector2f w) @property
    {
        import std.math: floor;
        import std.conv: to;

        return Vector2i(w.x.floor.to!int / tileSize.x, w.y.floor.to!int / tileSize.y);
    }

    PhysLayer.TileType tileTypeByWorldCoords(Vector2f worldCoords)
    {
        Vector2i tileCoords = worldCoordsToTileCoords(worldCoords);
        return physLayer.tiles[physLayer.coords2index(tileCoords)];
    }
}

unittest
{
    auto m = new Map("test_map/map_1");
    assert(m.tileTypeByWorldCoords(Vector2f(0, 0)) == PhysLayer.TileType.Empty);
    assert(m.tileTypeByWorldCoords(Vector2f(50, 50)) == PhysLayer.TileType.Empty);
    assert(m.tileTypeByWorldCoords(Vector2f(20, 25 * 18)) == PhysLayer.TileType.Block);

    //~ import std.stdio;
    //~ writeln(m.tileTypeByWorldCoords(Vector2f(17 * 18, 21 * 18)));
    //~ assert(m.tileTypeByWorldCoords(Vector2f(17 * 18, 21 * 18)) == PhysLayer.TileType.SlopeLeft);
}

private Json loadJsonDocument(string fileName)
{
    import std.file: readText;

    return fileName.readText.parseJsonString;
}
