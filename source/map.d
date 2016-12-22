module map;

import dsfml.graphics;
import std.exception: enforce;
import std.conv: to;
import gfm.math: box2f;
import misc: loadTexture;

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
    Vector2i layerSize;
    float opacity = 1;
    float scale = 1; /// scale factor
    ushort[] spriteNumbers; // for tile layers only
    Sprite image; // for image layers only
    float parallax = 1;
    void delegate() postDrawCallback;

    private size_t coords2index(Vector2i coords)
    {
        auto ret = layerSize.x * coords.y + coords.x;

        assert(ret < spriteNumbers.length);

        return ret;
    }
}

class Map
{
    const string fileName;
    const Vector2i tileSize;
    Layer[] layers;
    Texture[] tilesets;
    Sprite[] tileSprites;

    this(string mapName)
    {
        this.fileName = "resources/maps/"~mapName~".json";

        auto j = loadJsonDocument(fileName);

        enforce(j["version"].integer = 1, "Map file version mismatch");

        tileSize = Vector2i(
                j["tilewidth"].integer.to!int,
                j["tileheight"].integer.to!int
            );

        foreach(ts; j["tilesets"].array)
        {
            if("image" in ts)
            {
                auto tileset = loadTexture("resources/maps/test_map/"~ts["image"].str);

                int tileWidth = ts["tilewidth"].integer.to!int;
                int tileHeight = ts["tileheight"].integer.to!int;

                size_t columns = tileset.getSize.x / tileWidth;
                size_t rows = tileset.getSize.y / tileHeight;

                enforce(columns * rows == ts["tilecount"].integer);

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

        foreach(l; j["layers"].array)
        {
            Layer layer;

            layer.name = l["name"].str;

            // Need because TME or JSON library isn't respects JSON float convention
            import misc: getFloat = getFloatFromJson;

            layer.opacity = getFloat(l, "opacity", 1);
            layer.offset.x = getFloat(l, "offsetx", 0);
            layer.offset.y = getFloat(l, "offsety", 0);

            auto properties = ("properties" in l);
            if(properties !is null)
            {
                layer.parallax = getFloat(*properties, "parallax", 1);
                layer.scale = getFloat(*properties, "scale", 1);
            }

            if(l["type"].str == "tilelayer")
            {
                layer.type = Layer.Type.TILES;

                layer.layerSize.x = l["width"].integer.to!uint;
                layer.layerSize.y = l["height"].integer.to!uint;

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

                foreach(d; l["data"].array)
                {
                    layer.spriteNumbers ~= d.integer.to!ushort;
                }

            }
            else if(l["type"].str == "imagelayer")
            {
                layer.type = Layer.Type.IMAGE;

                auto img = loadTexture("resources/maps/test_map/"~l["image"].str);
                layer.image = new Sprite(img);
                layer.image.position = layer.offset;
                layer.image.scale = Vector2f(layer.scale, layer.scale);
                layer.image.color = Color(255, 255, 255, (255 * layer.opacity).to!ubyte);
            }
            else assert(0);

            layers ~= layer;
        }

        destroy(j);
    }

    /// corner - top left corner of scene
    void draw(RenderWindow window, Vector2f corner)
    {
        foreach(lay; layers)
        {
            window.view = new View(FloatRect(corner * lay.parallax, Vector2f(window.size)));

            if(lay.type == Layer.Type.TILES)
            {
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
                {
                    foreach(x; cornerTile.x .. latestTile.x)
                    {
                        if(
                            x >= 0 && x < lay.layerSize.x &&
                            y >= 0 && y < lay.layerSize.y
                        )
                        {
                            auto coords = Vector2i(x, y);

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
                    }
                }
            }
            else if(lay.type == Layer.Type.IMAGE)
            {
                window.draw(lay.image);
            }
            else assert(0);

            if(lay.postDrawCallback !is null)
                lay.postDrawCallback();
        }
    }

    /// Sets name of the layer. After render of that layer callback will be called.
    void registerDrawCallback(string layerName, void delegate() callback)
    {
        foreach(ref l; layers)
        {
            if(l.name == layerName)
            {
                l.postDrawCallback = callback;
                break;
            }
        }
    }
}

unittest
{
    auto map = new Map("test_map/map_1");
}

import std.json;

private JSONValue loadJsonDocument(string fileName)
{
    import std.file: readText;

    return fileName.readText.parseJSON;
}
