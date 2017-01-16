module particles.storage;

class ParticlesStorage(Particle)
{
    private Particle[] particles;

    void add(Particle p)
    {
        particles ~= p;
    }

    void markAsRemoved(ref Particle p)
    {
        p.markAsRemoved();
    }

    bool isRemoved(ref Particle p)
    {
        return p.isRemoved();
    }

    void callForEach(void delegate(ref Particle p) dg)
    {
        foreach(ref p; particles)
            dg(p);
    }

    void update(float dt)
    {
        callForEach( (ref Particle p){ p.update(dt); } );
    }
}

unittest
{
    struct DumbParticle
    {
        private bool removed;

        void markAsRemoved(){ removed = true; }
        bool isRemoved(){ return removed; }
        void update(float dt){}
    }

    auto ps = new ParticlesStorage!DumbParticle;
}
