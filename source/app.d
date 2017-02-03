import dsfml.graphics: RenderWindow, RenderStates;
import dlangui.platforms.dsfml.dsfmlapp : DSFMLWindow, DSFMLPlatform, initDSFMLApp, dsfmlPlatform, uninitDSFMLApp;
import myui;
import map;
import scene;
import soldier.soldier;
import dsfml.window;
import math: vec2f;
import controls_reader;
import ver.packageVersion;
import std.stdio: writeln;
import core.memory;

void main(string[] args)
{
    writeln("Version ", packageVersion ," built ", packageTimestamp);

    initDSFMLApp();

    auto window = new RenderWindow(VideoMode(800, 600, 32), "Hello DSFML!", Window.Style.Titlebar | Window.Style.Close | Window.Style.Resize);
    window.setFramerateLimit(60);

    DSFMLWindow w = dsfmlPlatform.registerWindow(window);
    // create some widget to show in window
    w.mainWidget = createMainWidget();

    auto testMap = new Map("test_map/map_1");
    auto testScene = new Scene(testMap);
    auto soldier = new Soldier(testScene);
    soldier.position = vec2f(500, 100);

    testScene.addDamageable(soldier);

    {
        auto target = new Soldier(testScene);
        target.skin = "green";
        target.position = vec2f(600, 100);

        testScene.addDamageable(target);
    }

    GC.disable;

    while (window.isOpen())
    {
        Event event;
        
        while(window.pollEvent(event))
        {
			switch(event.type)
			{
				case event.EventType.Closed:
					window.close();
					break;

				default:
					break;
            }
        }

        enum increment = 15;

        with(Keyboard.Key)
        with(testScene)
        {
            alias kp = Keyboard.isKeyPressed;

            if(kp(Left)) currViewPosition.x -= increment;
            if(kp(Right)) currViewPosition.x += increment;
            if(kp(Up)) currViewPosition.y -= increment;
            if(kp(Down)) currViewPosition.y += increment;
        }

        if (!window.isOpen())
            break;

        controls.update(testScene.currViewPosition, window);
        testScene.update();

        window.clear();

        GC.collect;

		testScene.draw(w.wnd, RenderStates.Default);

        window.display();
    }

    //destroy(w);
    uninitDSFMLApp();
}
