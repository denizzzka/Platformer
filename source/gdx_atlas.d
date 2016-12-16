module gdx_atlas;

import dsfml.graphics;

struct Region
{
    
}

enum ReadState
{
    SEARCH_NEW,
    NAME,
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

        foreach(l; lines)
        {
            import std.conv: to;

            string line = l.to!string;

            if(state == ReadState.SEARCH_NEW && l != "")
            {
                state = ReadState.NAME;

                import misc: loadTexture;

                pages ~= loadTexture(path~line);
            }
        }
    }
}

unittest
{
    auto atlas = new TextureAtlas("resources/textures/", "GAME.atlas");
}
