module map;

import dsfml.graphics;
import std.exception: enforce;
import std.conv: to;
import gfm.math: box2f;

struct Layer
{
    string name;
    Vector2f offset = Vector2f(0, 0);
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

                layer.name = l["name"].str;
                layer.layerSize.x = l["width"].integer.to!uint;
                layer.layerSize.y = l["height"].integer.to!uint;

                {
                    // Need because TME or JSON library isn't respects JSON float convention
                    float getOffset(JSONValue j, string fieldName)
                    {
                        if(auto json = fieldName in l)
                        {
                            if(json.type == JSON_TYPE.FLOAT)
                                return json.floating;
                            else
                                return json.integer.to!float;
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    if("offsetx" in l) layer.offset.x = getOffset(l["offsetx"], "offsetx");
                    if("offsety" in l) layer.offset.y = getOffset(l["offsety"], "offsety");

                    enforce(
                            layer.offset.x >= 0 &&
                            layer.offset.y >= 0,
                            "Layer "~layer.name~" have negative offset"
                        );

                    enforce(
                            layer.offset.x < tileSize.x &&
                            layer.offset.y < tileSize.y,
                            "Layer "~layer.name~" offset is too big"
                        );
                }

                foreach(d; l["data"].array)
                {
                    layer.spriteNumbers ~= d.integer.to!ushort;
                }

                layers ~= layer;
            }
        }

        destroy(j);
    }

    /// corner - top left corner of scene
    void draw(RenderWindow window, Vector2f corner)
    {
        Vector2i cornerTile = Vector2i(
                corner.x.to!int / tileSize.x,
                corner.y.to!int / tileSize.y
            );

        window.view = new View(FloatRect(corner, Vector2f(window.size)));

        foreach(lay; layers)
        {
            foreach(y; cornerTile.y .. lay.layerSize.y)
            {
                foreach(x; cornerTile.x .. lay.layerSize.x)
                {
                    if(!(x < 0 || y < 0))
                    {
                        auto coords = Vector2i(x, y);

                        auto idx = lay.coords2index(coords);
                        auto spriteNumber = lay.spriteNumbers[idx];

                        if(spriteNumber != 0)
                        {
                            auto sprite = &tileSprites[spriteNumber - 1];
                            auto pos = Vector2f(coords.x * tileSize.x + lay.offset.x, coords.y * tileSize.y + lay.offset.y);

                            sprite.position = pos;

                            window.draw(*sprite);
                        }
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
