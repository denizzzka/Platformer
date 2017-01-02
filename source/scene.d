module scene;

import spine.atlas;
import spine.dsfml;

static package Atlas atlas;

static this()
{
    enforceSmooth = true;
    atlas = new Atlas("resources/textures/GAME.atlas");
    enforceSmooth = false;
}
