module gdx_atlas;

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
    string imageName;
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

                        imageName ~= l;

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
                    }
                    break;
            }
        }
    }
}

unittest
{
    auto atlas = new TextureAtlas("resources/textures/GAME.atlas");
}
