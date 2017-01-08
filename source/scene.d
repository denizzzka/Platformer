module scene;

import spine.atlas;
import spine.dsfml;
import dsfml.graphics: RenderTarget, RenderStates, RenderWindow;
import dsfml.system.clock;
import map;
import math: vec2f;
import core.time: to;
import std.conv: to;
import bullets: Bullets;

static Atlas atlas()
{
    static Atlas atlas;

    if(atlas is null)
    {
        enforceSmooth = true;
        atlas = new Atlas("resources/textures/GAME.atlas");
        enforceSmooth = false;
    }

    return atlas;
}

interface SceneObject
{
    void update(float dt);
    void draw(RenderTarget renderTarget, RenderStates renderStates);
}

class Scene
{
    private Map _sceneMap;

    private size_t[SceneObject] objects;
    private size_t objectCounter;

    public Bullets bullets;
    private Clock frameClock;
    vec2f currViewPosition = vec2f(0, 0);

    this(Map m)
    {
        _sceneMap = m;

        bullets = new Bullets(_sceneMap);
        frameClock = new Clock();
    }

    Map sceneMap(){ return _sceneMap; }

    void add(SceneObject obj)
    {
        objects[obj] = objectCounter;
        objectCounter++;
    }

    void remove(SceneObject obj)
    {
        objects.remove(obj);
    }

    void update()
    {
        TickDuration td = frameClock.restart.to!TickDuration;
        float seconds = td.to!("seconds", float);

        foreach(ref o; objects.byKey)
            o.update(seconds);

        bullets.update(seconds);
    }

    void draw(RenderWindow wnd, RenderStates renderStates)
    {
        void drawUnitsOnMapCallback()
        {
            bullets.draw(wnd, renderStates);

            foreach(ref o; objects.byKey)
                o.draw(wnd, renderStates);
        }

        sceneMap.registerUnitsDrawCallback(&drawUnitsOnMapCallback);
        sceneMap.draw(wnd, currViewPosition);
    }
}
