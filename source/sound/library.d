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
    private dsfml.audio.Sound sound;
    import dsfml.system: Vector3f;

    this(dsfml.audio.SoundBuffer s)
    {
        sound = new dsfml.audio.Sound(s);

        sound.attenuation = 1.5f;
        sound.minDistance = 100.0f;
    }

    void play(vec2f screenCoords)
    {
        sound.position = Vector3f(screenCoords.x, screenCoords.y, 0);
        sound.play();
    }
}
