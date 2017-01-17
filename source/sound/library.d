module sound.library;

import dsfml.audio;
public import dsfml.audio.sound;
import std.exception: enforce;

private SoundBuffer[] soundBuffers;

Sound loadSound(string name)
{
    SoundBuffer b = new SoundBuffer;

    enforce(b.loadFromFile(name), "Sound "~name~" is not found");

    soundBuffers ~= b;

    return new Sound(b);
}
