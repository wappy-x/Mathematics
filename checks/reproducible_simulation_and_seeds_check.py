# Seeds -- the check behind the card.  Standard library only, no random module:
# the generator is SplitMix64, written out.  Roads: the Python and Rust runs pin
# each other's numbers; the overlap formula meets brute force on a toy generator;
# the first output on the Random numbers card; estimates held to a few standard errors.
import math, struct
M64, GAMMA, MASTER = 2**64 - 1, 0x9E3779B97F4A7C15, 20261111
WORKERS, DARTS = 4, 100000                     # darts per worker, two draws per dart

def mix(z):                                    # SplitMix64's scrambler
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

class Stream:                                  # one stream: a counter stepped by GAMMA, then mixed
    def __init__(self, state): self.state, self.used = state & M64, 0
    def next(self):
        self.state = (self.state + GAMMA) & M64
        self.used += 1
        return mix(self.state)
    def u(self): return (self.next() >> 11) * 2.0**-53   # top 53 bits: exact in both languages

class Lcg:                                     # the 32-bit LCG of the Monte Carlo pricing card
    def __init__(self, seed): self.x = seed
    def u(self):
        self.x = (1664525 * self.x + 1013904223) % 2**32
        return (self.x + 0.5) / 2**32

def seeds(master, n):                          # stream seeds: the first n outputs from the master
    g = Stream(master)
    return [g.next() for _ in range(n)]

def darts(g, n, starts=None):                  # n darts at the unit square
    hits, dist = 0, []
    for _ in range(n):
        if starts is not None: starts.add(g.state)
        x, y = g.u(), g.u()
        hits += x * x + y * y < 1.0
        dist.append(math.sqrt(x * x + y * y))
    return hits, dist

def total(xs):                                 # plain left-to-right sum (Python's sum() compensates)
    s = 0.0
    for x in xs: s += x
    return s

def disc_mean(g, n):                           # part A: n points in the unit disc, by rejection
    tot, got = 0.0, 0
    while got < n:
        x, y = 2 * g.u() - 1, 2 * g.u() - 1
        if x * x + y * y < 1.0:
            tot, got = tot + math.sqrt(x * x + y * y), got + 1
    return tot / n

def two_parts(n_a, shared):                    # part A, then part B: 10000 darts for pi
    s = seeds(MASTER, 2)
    a = Stream(s[0])
    b = a if shared else Stream(s[1])
    mean_a = disc_mean(a, n_a)
    used = a.used
    return mean_a, used, 4 * darts(b, 10000)[0] / 10000

bits = lambda x: struct.pack(">d", x).hex()
pi_se = lambda h, n: 4 * math.sqrt(h / n * (1 - h / n) / n)
print(f"splitmix64,seed 0,first output {Stream(0).next():016x},Random numbers card e220a8397b1dcdaf")
s = seeds(MASTER, WORKERS)
print(f"streams,master seed {MASTER},stream seeds {', '.join(f'{x:016x}' for x in s)}")
runs = [darts(Stream(x), DARTS) for x in s]
hits = [h for h, _ in runs]
n, H = WORKERS * DARTS, sum(hits)
est, se = 4 * H / n, pi_se(H, n)
for k in range(WORKERS):
    print(f"worker {k},{DARTS} darts,hits {hits[k]},estimate {4 * hits[k] / DARTS:.5f}")
print(f"answer,pi from {n} darts,hits {H},share {H / n:.5f},estimate {est:.5f},se {se:.5f},bits {bits(est)}")
print(f"answer,pi {math.pi:.5f},estimate below pi by {math.pi - est:.5f}")
print(f"record,generator splitmix64,master seed {MASTER},streams {WORKERS} seeded from the master,"
      f"draws {2 * n},answer {est:.5f} +- {se:.5f}")
ginv = GAMMA
for _ in range(6): ginv = ginv * (2 - GAMMA * ginv) & M64   # Newton: GAMMA's inverse mod 2^64
pos = [x * ginv & M64 for x in s]              # where each stream starts on the 2^64 loop
gap = min((pos[j] - pos[i]) & M64 for i in range(WORKERS) for j in range(WORKERS) if i != j)
L = 2 * DARTS
print(f"loop,gamma x inverse mod 2^64 = {GAMMA * ginv & M64},nearest two stream starts {gap} draws apart,"
      f"each stream uses {L}")
pair = (2 * L - 1) / 2**64
print(f"overlap bound,{WORKERS} streams of {L},pairs {WORKERS * (WORKERS - 1) // 2},2L - 1 = {2 * L - 1},per pair {pair:.1e},any pair {WORKERS * (WORKERS - 1) / 2 * pair:.1e}")
big = 10000 * 9999 / 2 * (2 * 10**9 - 1)
print(f"overlap bound,10000 streams of 10^9,pairs {10000 * 9999 // 2},64-bit loop {big / 2**64:.5f} (1 in {2**64 / big:.0f}),"
      f"128-bit loop {big / 2**128:.1e}")
seg = lambda x: {x := (5 * x + 3) % 256 for _ in range(10)}   # toy loop of 256, segments of 10
segs = [seg(x) for x in range(256)]
clash = sum(1 for a in segs for b in segs if a & b)
print(f"toy,(5x + 3) mod 256,ordered seed pairs whose 10-draw segments share a state {clash} of 65536,"
      f"formula 256 x 19 = {256 * 19},probability {clash / 65536:.4f}")
d_ser = total(d for _, ds in runs for d in ds) / n
d_par = total(total(ds) for _, ds in runs) / n
d_rev = total(d for _, ds in runs[::-1] for d in ds) / n   # one pass, workers in reverse order
exact = (math.sqrt(2) + math.log(1 + math.sqrt(2))) / 3
key = lambda x: struct.unpack(">q", struct.pack(">d", x))[0]   # a double's 64 bits as a whole number
print(f"sum order,mean distance one pass {d_ser!r},four partial sums {d_par!r},apart by {abs(key(d_ser) - key(d_par))} ulp,exact {exact:.5f}")
print(f"sum order,one pass with the workers in reverse order {d_rev!r},apart by {abs(key(d_ser) - key(d_rev))} ulp")
same = [darts(Stream(MASTER), DARTS)[0] for _ in range(WORKERS)]
print(f"mistake,every worker seeded {MASTER},hits {same},estimate {4 * sum(same) / n:.5f},"
      f"claimed se {pi_se(sum(same), n):.5f},true se {pi_se(same[0], DARTS):.5f}")
starts, hb = set(), 0
for k in range(WORKERS):
    hb += darts(Stream(MASTER + k * DARTS * GAMMA), DARTS, starts)[0]   # jumped by darts, not draws
print(f"mistake,jump ahead by {DARTS} draws not {L},distinct darts {len(starts)} of {n},estimate {4 * hb / n:.5f}")
hl = darts(Lcg(MASTER), n)[0]
print(f"mistake,seed {MASTER} recorded without its generator,32-bit LCG gives {4 * hl / n:.5f}")
p1, p2, p3, p4 = two_parts(10000, True), two_parts(5000, True), two_parts(10000, False), two_parts(5000, False)
for name, (pa, pb) in [("one shared stream", (p1, p2)), ("own streams", (p3, p4))]:
    print(f"parts,{name},A 10000 points used {pa[1]} draws,B {pa[2]:.4f},A 5000 points used {pb[1]} draws,B {pb[2]:.4f}")
print(f"parts,A mean distance in the disc {p3[0]:.5f},exact 2/3")
assert Stream(0).next() == 0xE220A8397B1DCDAF                   # as on the Random numbers card
assert H == 314064 and bits(est) == "40092007dd441355"          # pinned by the Rust run
assert abs(est - math.pi) < 4 * se                              # pi, within 4 standard errors
assert abs(d_ser - exact) < 4 * 0.29 / math.sqrt(n)             # closed form, sd about 0.285
assert abs(p3[0] - 2 / 3) < 4 * 0.24 / 100                      # disc: sd about 0.236
assert GAMMA * ginv & M64 == 1                                  # Newton found the inverse
assert gap > L                                                  # no two streams can meet
assert clash == 256 * (2 * 10 - 1)                              # brute force = (2L - 1) per seed
assert 0 < abs(d_ser - d_par) < 1e-14 and 0 < abs(d_ser - d_rev) < 1e-14   # order moves bits
assert same == [same[0]] * WORKERS and len(set(hits)) == WORKERS   # one seed: 4 copies; own: 4 runs
assert len(starts) == n - (WORKERS - 1) * DARTS // 2            # half of each block repeated
assert p3[2] == p4[2] and p1[2] != p2[2]                        # own stream: B does not move
assert p3[2] != 4 * darts(Stream(s[0]), 10000)[0] / 10000       # and B's stream is not A's
print("ALL CHECKS PASS")
