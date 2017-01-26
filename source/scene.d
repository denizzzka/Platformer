module scene;

import spine.atlas;
import spine.dsfml;
import dsfml.graphics: RenderTarget, RenderStates, RenderWindow;
import dsfml.system.clock;
import dsfml.audio: Listener;
import map;
import math;
import core.time: to;
import std.conv: to;
import particles.bullets;
import particles.blood;
import chipmunk_map;

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

interface SceneDamageableObject : SceneObject
{
    void decreaseHealth(float h);
    bool isDead() const;
    bool checkIfBulletHit(inout Bullet b);
}

class Scene
{
    private Map _sceneMap;

    private size_t[SceneObject] objects;
    private size_t objectCounter;

    private SceneObject[] toRemove;

    private SceneDamageableObject[] damageableObjects;

    public Bullets bullets;
    public Blood blood;

    private Clock frameClock;
    vec2f currViewPosition = vec2f(0, 0);

    private float _currentTime = 0;

    ChipmunkMap physMap;

    this(Map m)
    {
        _sceneMap = m;

        bullets = new Bullets(this);
        blood = new Blood(this);
        frameClock = new Clock();
        physMap = new ChipmunkMap(m);
    }

    Map sceneMap(){ return _sceneMap; }

    void add(SceneObject obj)
    {
        objects[obj] = objectCounter;
        objectCounter++;
    }

    void addDamageable(SceneDamageableObject o)
    {
        add(o);

        damageableObjects ~= o;
    }

    void removeBeforeNextDraw(SceneObject obj)
    {
        toRemove ~= obj;
    }

    void update()
    {
        TickDuration td = frameClock.restart.to!TickDuration;
        float seconds = td.to!("seconds", float);

        foreach(ref o; objects.byKey)
            o.update(seconds);

        bullets.removeDead();
        bullets.update(seconds);

        foreach(ref o; damageableObjects)
            bullets.checkHit(o);

        blood.update(seconds);
        blood.removeDead();

        _currentTime += seconds;
    }

    void draw(RenderWindow wnd, RenderStates renderStates)
    {
        // remove objects
        {
            foreach(ref o; toRemove)
                objects.remove(o);

            toRemove.length = 0;
        }

        void drawUnitsOnMapCallback()
        {
            bullets.draw(wnd, renderStates);

            blood.draw(wnd, renderStates);

            foreach(ref o; objects.byKey)
                o.draw(wnd, renderStates);
        }

        sceneMap.registerUnitsDrawCallback(&drawUnitsOnMapCallback);
        sceneMap.draw(wnd, currViewPosition);

        {
            import dsfml.system: Vector3f;

            vec2f pos = currViewPosition + wnd.size.gfm_dsfml / 2;
            Listener.Position = Vector3f(pos.x, pos.y, 0);
        }
    }

    float currentTime() const
    {
        return _currentTime;
    }

    private vec2f worldToScreenCoords(vec2f worldCoords) const
    {
        return worldCoords - currViewPosition;
    }
}
