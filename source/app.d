import dsfml.graphics;
import dlangui.platforms.dsfml.dsfmlapp : DSFMLWindow, DSFMLPlatform, initDSFMLApp, dsfmlPlatform, uninitDSFMLApp;
import myui;
import map;
import soldier;

void main(string[] args)
{
	auto testMap = new Map("test_map/map_1");

    auto soldier = new Soldier();

    initDSFMLApp();

    auto window = new RenderWindow(VideoMode(800, 600, 32), "Hello DSFML!", Window.Style.Titlebar | Window.Style.Close | Window.Style.Resize);
    window.setFramerateLimit(24);

    DSFMLWindow w = dsfmlPlatform.registerWindow(window);
    // create some widget to show in window
    w.mainWidget = createMainWidget();

    
    auto head = new CircleShape(100);
    head.fillColor = Color.Green;
    head.position = Vector2f(300,100);
    
    auto leftEye = new CircleShape(10);
    leftEye.fillColor = Color.Blue;
    leftEye.position = Vector2f(350,150);
    
    auto rightEye = new CircleShape(10);
    rightEye.fillColor = Color.Blue;
    rightEye.position = Vector2f(430,150);
    
    auto smile = new CircleShape(30);
    smile.fillColor = Color.Red;
    smile.position = Vector2f(368,200);
    
    auto smileCover = new RectangleShape(Vector2f(60,30));
    smileCover.fillColor = Color.Green;
    smileCover.position = Vector2f(368,200);

	Vector2f currViewPosition = Vector2f(0, 0);

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

				case Event.EventType.KeyPressed:
					enum increment = 15;

					switch(event.key.code)
					{
						case Keyboard.Key.D:
							currViewPosition.x += increment;
							break;

						case Keyboard.Key.A:
							currViewPosition.x -= increment;
							break;

						case Keyboard.Key.W:
							currViewPosition.y -= increment;
							break;

						case Keyboard.Key.S:
							currViewPosition.y += increment;
							break;

						default:
							break;
					}
					break;

				default:
					break;
            }
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

        soldier.position = currViewPosition + Vector2f(150, 200);
        soldier.update;
        soldier.draw(w.wnd);

        //~ w.draw();

        window.display();
    }

    //destroy(w);
    uninitDSFMLApp();
}
