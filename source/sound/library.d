module sound.library;

static import dsfml.audio;
public import dsfml.audio.sound;
import std.exception: enforce;
import math;

private dsfml.audio.SoundBuffer[] soundBuffers;

Sound loadSound(string name)
{
    auto b = new dsfml.audio.SoundBuffer;

    enforce(b.loadFromFile(name), "Sound "~name~" is not found");

    soundBuffers ~= b;

    return Sound(b);
}

struct Sound
{
    dsfml.audio.Sound sound;

    this(dsfml.audio.SoundBuffer s)
    {
        sound = new dsfml.audio.Sound(s);
    }

    void play(vec2f screenCoords)
    {
        import dsfml.system: Vector3f;

        sound.position = Vector3f(screenCoords.x, screenCoords.y, 0);
        sound.play();
    }
}
