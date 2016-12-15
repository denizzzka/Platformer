module map;

import gfm.math.vector: vec2ui;
import dsfml.graphics;
import std.exception: enforce;
import std.conv: to;

struct Layer
{
    vec2ui tileSize;
    float opacity;
    ushort[] spriteNumbers;
}

class Map
{
    const string fileName;
    Layer[] layers;
    Texture[] tilesets;
    Sprite[] tileSprites;

    this(string mapName)
    {
        this.fileName = "resources/maps/"~mapName~".json";

        auto j = loadJsonDocument(fileName);

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
            if("data" in l)
            {
                Layer layer;

                foreach(d; l["data"].array)
                {
                    layer.spriteNumbers ~= d.integer.to!ushort;
                }

                layers ~= layer;
            }
        }

        destroy(j);
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
