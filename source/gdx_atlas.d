module gdx_atlas;

import dsfml.graphics;

struct Region
{
    
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

    this(string path, string file)
    {
        import std.stdio: File;

        auto lines = File(path~file).byLine();

        ReadState state = ReadState.SEARCH_NEW;

        foreach(__l; lines)
        {
            import std.conv: to;

            string l = __l.to!string;

            final switch(state)
            {
                case ReadState.SEARCH_NEW:
                    if(l != "")
                    {
                        import misc: loadTexture;

                        pages ~= loadTexture(path~l);

                        state = ReadState.PAGE_DATA;
                    }
                    break;

                case ReadState.PAGE_DATA:
                    import std.string: indexOf;

                    if(l == "") // end of page
                    {
                        state = ReadState.SEARCH_NEW;
                    }
                    else if(l.indexOf(l, ' ') == -1) // line without spaces is a region name
                    {
                        // TODO: create new region

                        state = ReadState.READ_REGION;
                    }
                    else // its variable line
                    {
                        // nothing to do here - all region variables are optional by now
                    }
                    break;

                case ReadState.READ_REGION:
                    if(l == "") // end of page
                        state = ReadState.SEARCH_NEW;
                    else if(l[0] != ' ')
                    {
                        state = ReadState.PAGE_DATA;
                        goto case ReadState.PAGE_DATA;
                    }
                    else
                    {
                        // TODO: read region data
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
