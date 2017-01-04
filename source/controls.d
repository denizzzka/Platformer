module controls_reader;

import math;
import dsfml.graphics: RenderWindow;
import dsfml.window.mouse;

class Controls
{
    private vec2f _windowCorner;
    private vec2i _mouseCoords;

    private this()
    {
    }

    void update(vec2f windowCorner, RenderWindow window)
    {
        _windowCorner = windowCorner;
        _mouseCoords = Mouse.getPosition(window).gfm_dsfml;
    }

    /// relative to window
    vec2i mouseCoords() const
    {
        return _mouseCoords;
    }

    vec2f worldMouseCoords() const
    {
        return _windowCorner + mouseCoords;
    }
}

static Controls controls;

static this()
{
    controls = new Controls;
}
