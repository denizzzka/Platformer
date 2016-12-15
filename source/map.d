module map;

import gfm.math.vector: vec2ui;
import dsfml.graphics;
import std.exception: enforce;

struct Layer
{
    vec2ui tileSize;
    float opacity;
    Sprite[] tiles;
}

class Map
{
    const string fileName;
    Layer[] Layers;
    Texture[] tilesets;

    this(string mapName)
    {
        import std.path;

        this.fileName = "resources/maps/"~mapName~".json";

        auto j = loadJsonDocument(fileName);

        foreach(ts; j["tilesets"].array)
        {
            if("image" in ts)
            {
                string path = "resources/maps/test_map/"~ts["image"].str;
                tilesets ~= new Texture;

                enforce(tilesets[$-1].loadFromFile(path));
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
