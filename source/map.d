module map;

import dsfml.graphics;
import std.exception: enforce;
import std.conv: to;

struct Layer
{
    Vector2i layerSize;
    float opacity;
    ushort[] spriteNumbers;

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
                string path = "resources/maps/test_map/"~ts["image"].str;

                auto tileset = new Texture;
                enforce(tileset.loadFromFile(path));

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
            if(l["type"].str == "tilelayer")
            {
                Layer layer;

                layer.layerSize.x = l["width"].integer.to!uint;
                layer.layerSize.y = l["height"].integer.to!uint;

                foreach(d; l["data"].array)
                {
                    layer.spriteNumbers ~= d.integer.to!ushort;
                }

                layers ~= layer;
            }
        }

        destroy(j);
    }

    void draw(RenderWindow window)
    {
        foreach(lay; layers)
        {
            foreach(y; 0..lay.layerSize.y)
            {
                foreach(x; 0..lay.layerSize.x)
                {
                    auto coords = Vector2i(x, y);

                    auto idx = lay.coords2index(coords);
                    auto spriteNumber = lay.spriteNumbers[idx];

                    if(spriteNumber != 0)
                    {
                        auto sprite = &tileSprites[spriteNumber - 1];
                        auto pos = Vector2f(coords.x * tileSize.x, coords.y * tileSize.y);

                        sprite.position = pos;

                        window.draw(*sprite);
                    }
                }
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
