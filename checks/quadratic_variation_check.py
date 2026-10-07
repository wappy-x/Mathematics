# Quadratic variation -- the check behind the card.  Only math is imported.
# A pollen grain's position W_t, in micrometres after t seconds, is Brownian
# motion: a step over dt seconds is normal, mean 0, variance dt square um.
# Road 1: the formulas E[Q_n] = t, Var Q_n = 2 t^2 / n, E[V_n] = sqrt(2 n t / pi).
# Road 2: the normal's moments E[Z^2], E[Z^4], E|Z| by Simpson's rule.
# Road 3: 400 seeded paths of 10000 steps, coarsened to 1000, 100, 10 steps.
import math
M64 = (1 << 64) - 1
SEED, PATHS, FINE, T, MU = 20260930, 400, 10000, 1.0, 3.0
GRIDS = (10, 100, 1000, 10000)

class SplitMix64:                              # the wing's generator, written out
    def __init__(self, seed): self.s = seed
    def unit(self):                            # a uniform draw in [0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def normals(self, k):                      # Box-Muller, both outputs used
        out = []
        while len(out) < k:
            r = math.sqrt(-2.0 * math.log(1.0 - self.unit()))
            a = 2.0 * math.pi * self.unit()
            out += [r * math.cos(a), r * math.sin(a)]
        return out

def simpson(f, a, b, m=4000):
    h, s = (b - a) / m, f(a) + f(b)
    for i in range(1, m):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

def coarsen(steps, b):                         # add b consecutive steps into one
    out = []
    for i in range(0, len(steps), b):
        s = 0.0
        for x in steps[i:i + b]: s += x
        out.append(s)
    return out

def sq_abs(steps):                             # sum of squares, sum of sizes
    q = v = 0.0
    for x in steps: q += x * x; v += abs(x)
    return q, v

def mean_se(xs):
    m = 0.0
    for x in xs: m += x
    m /= len(xs)
    s = 0.0
    for x in xs: s += (x - m) * (x - m)
    return m, math.sqrt(s / (len(xs) - 1) / len(xs))

phi = lambda z: math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi)
ez2 = simpson(lambda z: z * z * phi(z), -12.0, 12.0)
ez4 = simpson(lambda z: z * z * z * z * phi(z), -12.0, 12.0)
eaz = 2.0 * simpson(lambda z: z * phi(z), 0.0, 12.0)

gen = SplitMix64(SEED)
Q = {n: [] for n in GRIDS}; V = {n: [] for n in GRIDS}
left, right, w2, drift = [], [], [], []
for p in range(PATHS):
    by = {FINE: [z * math.sqrt(T / FINE) for z in gen.normals(FINE)]}
    by[1000] = coarsen(by[FINE], 10); by[100] = coarsen(by[1000], 10); by[10] = coarsen(by[100], 10)
    for n in GRIDS:
        q, v = sq_abs(by[n]); Q[n].append(q); V[n].append(v)
    w, l, r = 0.0, 0.0, 0.0
    path = [0.0]
    for x in by[1000]:
        l += 2.0 * w * x; w += x; r += 2.0 * w * x; path.append(w)
    left.append(l); right.append(r); w2.append(w * w)
    drift.append(sq_abs([MU * T / 1000 + x for x in by[1000]])[0])
    if p == 0: path1, steps1 = path, by[1000]

print(f"seed {SEED}, {PATHS} paths, {FINE} steps each, t = {T:.1f} seconds")
print(f"{'road 2, Simpson: E[Z^2], E[Z^4], E|Z|':<44}{ez2:10.6f}{ez4:10.6f}{eaz:10.6f}")
print(f"{'road 1, formula sd of Q at n = 1000':<44}{math.sqrt(2.0 * T * T / 1000):10.6f}")
print(f"{'road 2, sd from Simpson moments, n = 1000':<44}{math.sqrt((ez4 - ez2 * ez2) / 1000):10.6f}")
q1, v1 = sq_abs(steps1)
print(f"{'path 1, n = 1000: sum of squared steps':<44}{q1:10.6f}")
print(f"{'path 1, n = 1000: sum of step sizes':<44}{v1:10.6f}")
print(f"{'path 1, n = 1000: largest step size':<44}{max(abs(x) for x in steps1):10.6f}")
print(f"{'house scale, 1000 s at one step a second':<44}{1000.0 * q1:10.3f}")
rmss = []
print("     n   Q path1   V path1    mean Q   se    rms err   se    formula   mean V    se    formula")
for n in GRIDS:
    mq, sq = mean_se(Q[n]); mv, sv = mean_se(V[n])
    d = [(x - T) * (x - T) for x in Q[n]]
    md, sd = mean_se(d); rms = math.sqrt(md); rmss.append(rms)
    print(f"{n:>6}{Q[n][0]:10.4f}{V[n][0]:10.3f}{mq:10.4f}{sq:7.4f}{rms:9.4f}{sd / (2.0 * rms):7.4f}"
          f"{T * math.sqrt(2.0 / n):10.4f}{mv:10.3f}{sv:7.3f}{math.sqrt(2.0 * n * T / math.pi):10.3f}")
    assert abs(md - 2.0 * T * T / n) < 4.0 * sd, "variance of Q must match 2 t^2 / n"
    assert abs(mv - math.sqrt(n * T) * eaz) < 4.0 * sv, "mean V must match sqrt(n t) E|Z|"
print("chart, rms err x sqrt(n): " + " ".join(f"{r * math.sqrt(n):.2f}" for r, n in zip(rmss, GRIDS)) + f"   sqrt(2): {math.sqrt(2.0):.2f}")
print("chart, path 1 sizes: " + " ".join(f"{V[n][0]:.2f}" for n in GRIDS) + "   squares: " + " ".join(f"{Q[n][0]:.2f}" for n in GRIDS))
mq, sq = mean_se(Q[1000])
assert abs(mq - T) < 4.0 * sq, "mean of Q at n = 1000 must be t"
assert abs(ez4 - 3.0) < 1e-9, "Simpson's E[Z^4] must be the normal's 3"

print("smooth path sin(2 pi t):  n   Q   n*Q   2n sin^2(pi/n)   V")
for n in GRIDS:
    q, v = sq_abs([math.sin(2 * math.pi * k / n) - math.sin(2 * math.pi * (k - 1) / n) for k in range(1, n + 1)])
    sp = math.sin(math.pi / n); exact = 2.0 * n * sp * sp
    print(f"  {n:>6}{q:12.6f}{n * q:10.4f}{exact:12.6f}{v:10.4f}")
    assert abs(q - exact) < 1e-12, "direct sum must match the closed form"
print(f"{'  limit of n*Q, 2 pi^2':<44}{2.0 * math.pi * math.pi:10.4f}")

ml, sl = mean_se(left); mr, sr = mean_se(right); mw, sw = mean_se(w2)
print(f"{'path 1: W_1^2, left sum, right sum':<44}{w2[0]:10.4f}{left[0]:10.4f}{right[0]:10.4f}")
print(f"{'path 1: W_1^2 - left sum, (right - left)/2':<44}{w2[0] - left[0]:10.4f}{(right[0] - left[0]) / 2:10.4f}")
print(f"{'400 paths: mean W_1^2 (se)':<44}{mw:10.4f}{sw:10.4f}")
print(f"{'400 paths: mean left sum (se)':<44}{ml:10.4f}{sl:10.4f}")
print(f"{'400 paths: mean right sum (se)':<44}{mr:10.4f}{sr:10.4f}")
assert abs(ml) < 4.0 * sl, "the left-point sum must average 0, not W_1^2"
assert abs(mr - 2.0 * T) < 4.0 * sr, "the right-point sum must average 2t"
md, sd = mean_se(drift)
print(f"{f'drift {MU:.1f} um/s, n = 1000: path 1, mean (se)':<44}{drift[0]:10.4f}{md:10.4f}{sd:10.4f}")
print(f"{'  formula t + mu^2 t^2 / n':<44}{T + MU * MU * T * T / 1000:10.4f}")
assert abs(md - (T + MU * MU * T * T / 1000)) < 4.0 * sd, "drift adds only mu^2 t^2 / n"

best = [0.0] * len(path1)                      # cut points chosen after seeing path 1
for j in range(1, len(path1)):
    b = 0.0
    for i in range(j):
        e = path1[j] - path1[i]; c = best[i] + e * e
        if c > b: b = c
    best[j] = b
print(f"{'path 1: best partition of the 1000-step grid':<44}{best[-1]:10.4f}")
print("figure, path 1 at t = 0.00, 0.05, ..., 1.00:")
print(" ".join(f"{path1[k]:.2f}" for k in range(0, 1001, 50)))
print("ALL CHECKS PASS")
