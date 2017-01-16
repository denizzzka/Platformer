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

    void update(A...)(A a)
    {
        callForEach( (ref Particle p){ p.update(a); } );
    }

    void removeDead()
    {

        Particle[] aliveParticles;

        callForEach(
                (ref Particle p)
                {
                    if(!p.isRemoved)
                        aliveParticles ~= p;

                    particles = aliveParticles;
                }
            );
    }
}

unittest
{
    struct DumbParticle
    {
        private bool removed;

        void markAsRemoved(){ removed = true; }
        bool isRemoved(){ return removed; }
        void update(float a, int b){ assert(a == 1); assert(b == 2); }
    }

    auto ps = new ParticlesStorage!DumbParticle;
    ps.add(DumbParticle());
    ps.update(1, 2);
}
