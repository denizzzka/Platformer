import dsfml.graphics;
import dlangui.platforms.dsfml.dsfmlapp : DSFMLWindow, DSFMLPlatform, initDSFMLApp, dsfmlPlatform, uninitDSFMLApp;
import myui;
import map;
import soldier;
import dsfml.window;
import dsfml.system.clock;
import std.conv: to;
import core.time: to;
import math: vec2f;

void main(string[] args)
{
	auto testMap = new Map("test_map/map_1");

    initDSFMLApp();

    auto window = new RenderWindow(VideoMode(800, 600, 32), "Hello DSFML!", Window.Style.Titlebar | Window.Style.Close | Window.Style.Resize);
    window.setFramerateLimit(60);

    DSFMLWindow w = dsfmlPlatform.registerWindow(window);
    // create some widget to show in window
    w.mainWidget = createMainWidget();

	vec2f currViewPosition = vec2f(0, 0);

    Clock frameClock = new Clock();

    auto soldier = new Soldier(testMap);
    soldier.position = vec2f(700, 300);

    void soldierDrawCallback()
    {
        TickDuration td = frameClock.restart.to!TickDuration;
        soldier.update(td.to!("seconds", float));
        soldier.draw(w.wnd);
    }

    testMap.registerUnitsDrawCallback(&soldierDrawCallback);

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
        {
            alias kp = Keyboard.isKeyPressed;

            if(kp(Left)) currViewPosition.x -= increment;
            if(kp(Right)) currViewPosition.x += increment;
            if(kp(Up)) currViewPosition.y -= increment;
            if(kp(Down)) currViewPosition.y += increment;
        }

        if (!window.isOpen())
            break;
        
        window.clear();
        
        //~ window.draw(head);
        //~ window.draw(leftEye);
        //~ window.draw(rightEye);
        //~ window.draw(smile);
        //~ window.draw(smileCover);

		testMap.draw(w.wnd, currViewPosition);

        //~ w.draw();

        window.display();
    }

    //destroy(w);
    uninitDSFMLApp();
}
