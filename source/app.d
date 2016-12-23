import dsfml.graphics;
import dlangui.platforms.dsfml.dsfmlapp : DSFMLWindow, DSFMLPlatform, initDSFMLApp, dsfmlPlatform, uninitDSFMLApp;
import myui;
import map;
import soldier;
import dsfml.window.keyboard;

void main(string[] args)
{
	auto testMap = new Map("test_map/map_1");

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

    auto soldier = new Soldier();
    soldier.position = Vector2f(150, 300);

    void soldierDrawCallback()
    {
        soldier.update;
        soldier.draw(w.wnd);
    }

    testMap.registerDrawCallback("main", &soldierDrawCallback);

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

            if(kp(A)) currViewPosition.x -= increment;
            if(kp(D)) currViewPosition.x += increment;
            if(kp(W)) currViewPosition.y -= increment;
            if(kp(S)) currViewPosition.y += increment;
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

        static moveRight = false;

        if(moveRight)
            soldier.position.x += 15;
        else
            soldier.position.x -= 3.15;

        if(soldier.position.x > 400) moveRight = false;
        if(soldier.position.x < 100) moveRight = true;

        //~ w.draw();

        window.display();
    }

    //destroy(w);
    uninitDSFMLApp();
}
