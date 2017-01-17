module sound.library;

import dsfml.audio;
public import dsfml.audio.sound;

private SoundBuffer[] soundBuffers;

Sound loadSound(string name)
{
    SoundBuffer b = new SoundBuffer;
    b.loadFromFile(name);

    soundBuffers ~= b;

    return new Sound(b);
}
