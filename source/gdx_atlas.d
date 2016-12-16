module gdx_atlas;

import gfm.math: vec2f;
import std.regex;

struct Region
{
    size_t textureIdx;
    vec2f coords;
    vec2f size;
}

enum ReadState
{
    SEARCH_NEW,
    PAGE_DATA,
    READ_REGION
}

class TextureAtlas
{
    string[] texturesNames;
    Region[string] regions;

    this(string path)
    {
        import std.stdio: File;

        auto lines = File(path).byLine();

        ReadState state = ReadState.SEARCH_NEW;
        Region* currRegion = null;

        foreach(__l; lines)
        {
            import std.conv: to;

            string l = __l.to!string;

            final switch(state)
            {
                case ReadState.SEARCH_NEW:
                    if(__l.length > 0)
                    {
                        import misc: loadTexture;

                        texturesNames ~= l;

                        state = ReadState.PAGE_DATA;
                    }
                    break;

                case ReadState.PAGE_DATA:
                    import std.string: indexOf;

                    if(__l.length == 0) // end of page
                    {
                        state = ReadState.SEARCH_NEW;
                    }
                    else if(l.indexOf(l, ' ') == -1) // line without spaces is a region name
                    {
                        // Creating new region
                        Region region;
                        region.textureIdx = texturesNames.length - 1;
                        regions[l] = region;
                        currRegion = &regions[l];

                        state = ReadState.READ_REGION;
                    }
                    else // its variable line
                    {
                        // nothing to do here - all region variables are optional by now
                    }
                    break;

                case ReadState.READ_REGION:
                    assert(currRegion);

                    if(__l.length == 0) // end of page
                    {
                        state = ReadState.SEARCH_NEW;
                    }
                    else if(__l[0] != ' ') // end of region
                    {
                        state = ReadState.PAGE_DATA;
                        goto case ReadState.PAGE_DATA;
                    }
                    else
                    {
                        // TODO: read region data into currRegion
                        auto rgx = ctRegex!(`^  (.+): (.+)$`);
                        auto m = l.matchAll(rgx);

                        string name = m.front[1];
                        string value = m.front[2];

                        switch(name)
                        {
                            case "xy":
                                currRegion.coords = parseCoords(value);
                                break;

                            case "size":
                                currRegion.size = parseCoords(value);
                                break;

                            default:
                                break;
                        }
                    }
                    break;
            }
        }
    }
}

unittest
{
    auto a = new TextureAtlas("resources/textures/GAME.atlas");

    assert(a.texturesNames.length == 1);
    assert(a.texturesNames[0] == "GAME.png");
    assert(a.regions["watergun-skin"].textureIdx == 0);
    assert(a.regions["watergun-skin"].coords == vec2f(283, 92));
    assert(a.regions["watergun-skin"].size == vec2f(68, 30));
}

private vec2f parseCoords(string s)
{
    import std.conv: to;

    auto rgx = ctRegex!(`^(.+), (.+)$`);
    auto m = s.matchAll(rgx);

    vec2f ret;

    ret.x = m.front[1].to!float;
    ret.y = m.front[2].to!float;

    return ret;
}
