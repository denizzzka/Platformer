module gdx_atlas;

import dsfml.graphics;
import gfm.math: vec2f;

struct Region
{
    size_t textureIdx;
    vec2f coords;
    vec2f offset;
}

enum ReadState
{
    SEARCH_NEW,
    PAGE_DATA,
    READ_REGION
}

class TextureAtlas
{
    Texture[] pages;
    Region[string] regions;

    this(string path, string file)
    {
        import std.stdio: File;

        auto lines = File(path~file).byLine();

        ReadState state = ReadState.SEARCH_NEW;

        foreach(__l; lines)
        {
            import std.conv: to;

            string l = __l.to!string;

            Region* currRegion = null;

            final switch(state)
            {
                case ReadState.SEARCH_NEW:
                    if(__l.length > 0)
                    {
                        import misc: loadTexture;

                        pages ~= loadTexture(path~l);

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
                        import std.stdio; writeln(l);
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
                    if(__l.length == 0) // end of page
                        state = ReadState.SEARCH_NEW;
                    else if(__l[0] != ' ')
                    {
                        state = ReadState.PAGE_DATA;
                        goto case ReadState.PAGE_DATA;
                    }
                    else
                    {
                        // TODO: read region data into currRegion
                        assert(currRegion);
                    }
                    break;
            }
        }
    }
}

unittest
{
    auto atlas = new TextureAtlas("resources/textures/", "GAME.atlas");
}
