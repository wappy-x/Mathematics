# MCMC as a tool: fit wet-day chance p, Weibull shape k and scale c (mm) to 200 synthetic rainfall days.
# Roads: 1 the exact Beta posterior for p; 2 a 2-D grid for (k, c), no randomness;
# 3 seeded Metropolis chains (SplitMix64, Box-Muller), tuned, run four at a time, error bars by batch means.
from math import exp, log, sqrt, cos, pi, floor
M64 = (1 << 64) - 1
class Rng:
    def __init__(s, seed): s.s = seed
    def u(s):
        s.s = (s.s + 0x9E3779B97F4A7C15) & M64
        z = s.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def n(s):
        u1 = s.u(); u2 = s.u()
        return sqrt(-2.0 * log(1.0 - u1)) * cos(2.0 * pi * u2)
def tot(v):                                   # plain left-to-right sum, the same in Rust
    s = 0.0
    for x in v: s += x
    return s
def out(k, *v, d=4): print(f"{k:<40}" + "".join(f" {x:.{d}f}" for x in v))
# ---- the data: 200 days, wet with chance 0.35, wet amounts Weibull(shape 0.75, scale 6 mm), to 0.1 mm ----
R = Rng(2026); DAYS = []
for day in range(200):
    if R.u() < 0.35: DAYS.append(max(0.1, floor(10 * 6.0 * (-log(1 - R.u())) ** (1 / 0.75) + 0.5) / 10))
    else: DAYS.append(0.0)
WET = [x for x in DAYS if x > 0]; NW = len(WET); ND = len(DAYS); SL = tot(log(x) for x in WET)
print(f"{'data: days, wet days, total mm':<40} {ND} {NW} {tot(WET):.1f}"); out("data: mean and largest wet-day mm", tot(WET) / NW, max(WET), d=1)
def logf(p, k, c):                            # log posterior up to a constant, flat prior on a box
    if not (0 < p < 1 and 0 < k < 5 and 0 < c < 100): return -1e300
    return (NW * log(p) + (ND - NW) * log(1 - p) + NW * log(k) - NW * k * log(c) + (k - 1) * SL
            - tot((x / c) ** k for x in WET))
def over25(p, k, c): return p * exp(-(25.0 / c) ** k)   # chance a day brings more than 25 mm
# ---- road 1: p alone has an exact Beta posterior ----
a1, b1 = NW + 1, ND - NW + 1
pm = a1 / (a1 + b1); psd = sqrt(a1 * b1 / ((a1 + b1) ** 2 * (a1 + b1 + 1)))
out("exact p: mean, sd", pm, psd)
# ---- road 2: (k, c) on a 161 x 361 grid, k 0.40 to 1.20, c 2 to 20 mm ----
GK = [0.40 + 0.005 * i for i in range(161)]; GC = [2.0 + 0.05 * j for j in range(361)]
L = [[logf(pm, k, c) for c in GC] for k in GK]; top = max(map(max, L))
G = [[exp(v - top) for v in r] for r in L]; T = tot(tot(r) for r in G)
def gE(h): return tot(G[i][j] * h(GK[i], GC[j]) for i in range(161) for j in range(361)) / T
gk, gc = gE(lambda k, c: k), gE(lambda k, c: c)
gks, gcs = sqrt(gE(lambda k, c: (k - gk) * (k - gk))), sqrt(gE(lambda k, c: (c - gc) * (c - gc)))
grho = gE(lambda k, c: (k - gk) * (c - gc)) / (gks * gcs)
g25 = pm * gE(lambda k, c: exp(-(25.0 / c) ** k))   # p is independent of (k, c), so the average splits
out("grid k: mean, sd", gk, gks); out("grid c: mean, sd", gc, gcs); out("grid corr(k, c)", grho)
out("grid P(day > 25 mm)", g25, d=5)
# ---- road 3: random-walk Metropolis ----
def chain(seed, th, step, n):
    R = Rng(seed); lf = logf(*th); xs = []; acc = 0
    for t in range(n):
        prop = [th[i] + step[i] * R.n() for i in range(3)]
        lp = logf(*prop)
        if log(1.0 - R.u()) < lp - lf: th, lf, acc = prop, lp, acc + 1
        xs.append(th)
    return xs, acc / n
def sd(v): m = tot(v) / len(v); return sqrt(tot((x - m) * (x - m) for x in v) / (len(v) - 1))
def bm(cs, per=25):                           # batch means over several chains: mean, Monte Carlo SE, ESS
    bs = []
    for c in cs:
        Lb = len(c) // per; bs += [tot(c[q * Lb:(q + 1) * Lb]) / Lb for q in range(per)]
    allv = [x for c in cs for x in c]; m = tot(allv) / len(allv); se = sd(bs) / sqrt(len(bs)); r = sd(allv) / se
    return m, se, r * r
def rhat(cs):                                 # Gelman-Rubin: spread between chains against spread within
    m = len(cs); N = len(cs[0]); mus = [tot(c) / N for c in cs]; g = tot(mus) / m
    B = N * tot((x - g) * (x - g) for x in mus) / (m - 1); Wv = tot(sd(c) * sd(c) for c in cs) / m
    return sqrt(((N - 1) / N * Wv + B / N) / Wv)
step = [0.1, 0.1, 0.1]; th = [0.5, 1.0, 5.0]                  # tuning: a guess, then 2.38/sqrt(3) x pilot sd
for rnd in range(1, 4):
    xs, acc = chain(100 + rnd, th, step, 2000)
    out(f"tune round {rnd}: steps p k c, accept", *step, acc)
    half = xs[1000:]; th = half[-1]
    step = [2.38 / sqrt(3) * sd([x[i] for x in half]) for i in range(3)]
out("tuned steps p k c", *step)
out("rule 2.38/sqrt(3); times exact sd p k c", 2.38 / sqrt(3), *[2.38 / sqrt(3) * v for v in (psd, gks, gcs)])
START = [pm, gk, gc]; tests = {}
for name, st in [("one step 0.1 for all", [0.1] * 3), ("one step 1.0 for all", [1.0] * 3),
                 ("tuned x 0.1", [s * 0.1 for s in step]), ("tuned", step), ("tuned x 10", [s * 10 for s in step])]:
    xs, acc = chain(7, START, st, 10000); tests[name] = (acc, bm([[x[2] for x in xs]])[2])
    print(f"{name + ': accept, ESS of c':<40} {acc:.4f} {tests[name][1]:.0f}")
STARTS = [[0.10, 0.30, 2.0], [0.80, 2.00, 20.0], [0.50, 1.20, 3.0], [0.20, 0.50, 15.0]]
runs = []
for i, s0 in enumerate(STARTS):
    xs, acc = chain(11 + i, s0, step, 12000); runs.append(xs)
    out(f"chain {i + 1} from p k c, accept", *s0, acc)
early = [[[x[j] for x in xs[:100]] for xs in runs] for j in range(3)]
kept = [[[x[j] for x in xs[2000:]] for xs in runs] for j in range(3)]
out("R-hat p k c, first 100 steps", *[rhat(e) for e in early])
out("R-hat p k c, 10,000 kept after 2,000", *[rhat(e) for e in kept])
same = [chain(31 + i, [0.35, 0.75, 20.0], step, 100)[0] for i in range(4)]
out("4 chains all from c=20: R-hat c, mean c", rhat([[x[2] for x in xs] for xs in same]),
    tot(x[2] for xs in same for x in xs) / 400)
rep = {}
for j, name in enumerate(["p", "k", "c"]):
    allv = [x for c in kept[j] for x in c]; m, se, ess = bm(kept[j]); rep[name] = (m, sd(allv), se)
    out(f"report {name}: mean, sd, MCSE, naive SE", m, sd(allv), se, sd(allv) / sqrt(40000)); out(f"  ESS of {name} out of 40,000; N/ESS", ess, 40000 / ess, d=1)
q = [[over25(*x) for x in xs[2000:]] for xs in runs]; m25, se25, _ = bm(q)
out("report P(>25 mm): mean, sd, MCSE", m25, sd([x for c in q for x in c]), se25, d=5)
out("  as about 1 day in", 1 / m25, d=1)
out("plug-in P(>25 mm) at the means", over25(rep["p"][0], rep["k"][0], rep["c"][0]), d=5)
print(f"{'chart, step':<19}" + "".join(f"{t:6d}" for t in range(0, 301, 20)))
for i in (0, 1):
    print(f"{'chart, c from ' + format(STARTS[i][2], '.1f'):<19}" + "".join(f"{runs[i][t][2]:6.2f}" for t in range(0, 301, 20)))
assert abs(rep["p"][0] - pm) < 4 * rep["p"][2], "chains' p against the exact Beta mean"
assert abs(rep["k"][0] - gk) < 4 * rep["k"][2], "chains' k against the grid"
assert abs(rep["c"][0] - gc) < 4 * rep["c"][2], "chains' c against the grid"
assert abs(m25 - g25) < 4 * se25, "P(day > 25 mm) against the grid"
assert abs(rep["p"][1] / psd - 1) < 0.05, "posterior sd of p against the Beta formula"
assert abs(rep["c"][1] / gcs - 1) < 0.05, "posterior sd of c against the grid"
assert max(rhat(e) for e in early) > 1.1, "R-hat flags the scattered starts"
assert max(rhat(e) for e in kept) < 1.01, "R-hat clears after burn-in"
assert 0.15 < tests["tuned"][0] < 0.5, "tuned acceptance in the workable band"
assert tests["tuned"][1] > 10 * tests["one step 0.1 for all"][1], "per-parameter steps beat one shared step"
assert abs(gk - 0.75) < 3 * gks, "grid posterior covers the generator's shape k = 0.75"
assert abs(gc - 6.0) < 3 * gcs, "grid posterior covers the generator's scale c = 6 mm"
print("ALL CHECKS PASS")
