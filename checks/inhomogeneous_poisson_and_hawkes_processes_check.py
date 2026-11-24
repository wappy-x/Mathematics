# Time-varying Poisson and Hawkes -- the check behind the card.  Standard library only.
# Part A: calls at rate 4 + 3 sin(2 pi t/24) an hour, t in hours after midnight.  The expected count
# to noon by formula and by Simpson's rule; simulated by thinning and by stretching time.
# Part B: Hawkes calls, base rate 2 an hour, each call adds 1 an hour to the rate, fading at rate 2
# an hour, so each call triggers 0.5 more on average.  Long-run rate and cluster size by a fixed point,
# a geometric series and the Borel law; simulated by thinning the rate and by building family trees.
from math import sin, cos, exp, log, pi, sqrt
from bisect import bisect_right
M64 = (1 << 64) - 1
class Rng:                                        # SplitMix64, written out
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def expo(self, rate): return -log(1.0 - self.u()) / rate
    def poisson(self, mean):                      # inversion: walk up the cumulative chances
        u, k, p = self.u(), 0, exp(-mean)
        c = p
        while u > c: k += 1; p *= mean / k; c += p
        return k
def rate(t): return 4.0 + 3.0 * sin(2.0 * pi * t / 24.0)
def big_lam(t): return 4.0 * t + (36.0 / pi) * (1.0 - cos(pi * t / 12.0))   # expected calls by t
def stats(xs):
    m = sum(xs) / len(xs); v = sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
    return m, v, sqrt(v / len(xs))
T, PEAK, R = 12.0, 7.0, 10000
exact = big_lam(T)
n = 1200; h = T / n; cum = [0.0]                   # Simpson's rule on the rate, step by step: cum[i] = Lambda(i h)
for i in range(n): cum.append(cum[-1] + (rate(i * h) + 4 * rate((i + 0.5) * h) + rate((i + 1) * h)) * h / 6)
print(f"A base part 4 x 12                  {4 * T:10.4f}")
print(f"A wave part 72/pi                   {72 / pi:10.4f}")
print(f"A expected calls to noon, formula   {exact:10.4f}")
print(f"A expected calls to noon, Simpson   {cum[-1]:10.4f}")
print(f"A expected calls in 24 hours        {big_lam(24.0):10.4f}")
print(f"A spread of the noon count sqrt     {sqrt(exact):10.4f}")
print(f"A proposals at peak 7 x 12          {PEAK * T:10.4f}")
print(f"A share of proposals kept           {exact / (PEAK * T):10.4f}")
print("A rate by hour 0..24  " + " ".join(f"{rate(k):.2f}" for k in range(25)))
rng = Rng(20261123)
def thin(prop):                                   # propose at rate prop, keep with chance rate/prop
    t, kept, made = 0.0, 0, 0
    while True:
        t += rng.expo(prop)
        if t > T: return kept, made
        made += 1
        if rng.u() * prop < min(rate(t), prop): kept += 1
runs = [thin(PEAK) for _ in range(R)]
m1, v1, se1 = stats([k for k, _ in runs]); mp, _, _ = stats([d for _, d in runs])
def stretched():                                  # unit-rate gaps, each total mapped back to a time through cum
    s, k = 0.0, [0, 0]
    while True:
        s += rng.expo(1.0)
        i = bisect_right(cum, s)                  # cum[i - 1] <= s < cum[i]
        if i > n: return k                        # the mapped time is past noon
        t = (i - 1 + (s - cum[i - 1]) / (cum[i] - cum[i - 1])) * h   # Lambda(t) = s, straight line between steps
        k[t > 3.0] += 1                           # before 3 am, or from 3 am to noon
st = [stretched() for _ in range(R)]
m2, v2, se2 = stats([a + b for a, b in st]); m3, _, se3 = stats([a for a, _ in st])
print(f"A sim thinning: mean {m1:.3f} se {se1:.3f}  variance {v1:.2f}  proposals {mp:.3f}")
print(f"A sim stretched time: mean {m2:.3f} se {se2:.3f}  variance {v2:.2f}  before 3 am {m3:.3f} se {se3:.3f}  (Lambda(3) {big_lam(3.0):.4f}, even spread {exact / 4:.4f})")
simp_low = sum((min(rate(i * h), 5) + 4 * min(rate((i + 0.5) * h), 5) + min(rate((i + 1) * h), 5)) * h / 6 for i in range(n))  # wrong: 5
print(f"A wrong: rate at noon x 12          {rate(12.0) * T:10.4f}")
print(f"A wrong: keep every peak proposal   {PEAK * T:10.4f}")
print(f"A wrong: propose at 5, not 7        {simp_low:10.4f}")
MU, NB, BETA = 2.0, 0.5, 2.0                      # base rate, branching ratio, fade rate
JUMP = NB * BETA                                  # each call lifts the rate by 1 an hour
lam = MU
for _ in range(60): lam = MU + NB * lam            # fixed point of rate = base + n x rate
series = sum(NB ** k for k in range(60))
print(f"B long-run rate mu/(1-n)            {MU / (1 - NB):10.4f}")
print(f"B fixed-point iteration             {lam:10.4f}")
print(f"B mean cluster 1/(1-n)              {1 / (1 - NB):10.4f}")
print(f"B geometric series 1+n+n^2+...      {series:10.4f}")
print("B series partial sums  " + " ".join(f"{sum(NB ** j for j in range(k + 1)):.4f}" for k in range(6)))
borel, lf = [], 0.0                               # Borel law: P(k) = e^-nk (nk)^(k-1) / k!
for k in range(1, 4001):
    lf += log(k); borel.append(exp(-NB * k + (k - 1) * log(NB * k) - lf))
print("B Borel P(cluster=1..4)  " + " ".join(f"{p:.4f}" for p in borel[:4]))
bmean = sum((k + 1) * p for k, p in enumerate(borel))
bsq = sum((k + 1) ** 2 * p for k, p in enumerate(borel))
print(f"B Borel total {sum(borel):.6f}  mean {bmean:.6f}  variance {bsq - bmean ** 2:.6f}")
print(f"B long-window variance per hour 2 E[S^2]  {MU * bsq:.4f}")
var12 = 4 * T + 12.0 * (T - (1 - exp(-T)))        # stationary 12-hour variance, covariance 6 e^-|s|
empty12 = 4 * T - 2 * (1 - exp(-T))               # mean 12-hour count from an empty start
print(f"B 12-hour count: mean {4 * T:.4f}  variance {var12:.4f}  Poisson would say {4 * T:.4f}")
print(f"B 12-hour mean from an empty start {empty12:.4f};  rate after 1 hour {4 - 2 * exp(-1):.4f}")
def hawkes(hor):                                  # thinning on the rate, which only fades between calls
    t, x, ev = 0.0, 0.0, []
    while True:
        bound = MU + x; w = rng.expo(bound); t += w
        if t > hor: return ev
        x *= exp(-BETA * w)
        if rng.u() * bound < MU + x: ev.append(t); x += JUMP
H = 12.0 * 8400                                   # 8400 half-days
ev = hawkes(H)
wins = [0] * int(H / T)
for e in ev: wins[int(e / T)] += 1
mw, vw, sew = stats(wins)
print(f"B sim thinning, {H:.0f} hours: rate {len(ev) / H:.4f} se {4 / sqrt(H):.4f}  12-hour variance {vw:.2f}")
e12, _, se12 = stats([len(hawkes(T)) for _ in range(R)])
print(f"B sim empty start, 12 hours: mean {e12:.3f} se {se12:.3f}")
sizes, inside, t, bygen = [], 0, 0.0, [0] * 5    # family trees: immigrants, then children
while True:
    t += rng.expo(MU)
    if t > H: break
    gen, size, d = [t], 0, 0
    while gen:
        size += len(gen); inside += sum(1 for g in gen if g <= H)
        if d < 5: bygen[d] += len(gen)
        gen = [g + rng.expo(BETA) for g in gen for _ in range(rng.poisson(NB))]; d += 1
    sizes.append(size)
ms, vs, ses = stats(sizes)
ones = sum(1 for s in sizes if s == 1) / len(sizes)
print(f"B sim trees: {len(sizes)} clusters  mean {ms:.4f} se {ses:.4f}  variance {vs:.3f}")
print(f"B sim trees: lone calls {ones:.4f}  rate {inside / H:.4f}")
print("B rate by generation, formula  " + " ".join(f"{MU * NB ** d:.4f}" for d in range(5)))
print("B rate by generation, trees    " + " ".join(f"{c / H:.4f}" for c in bygen))
near = [e for e in ev if 92 < e < 106]
print("B rate on hours 100-106 every 12 min  " + " ".join(
    f"{MU + sum(JUMP * exp(-BETA * (s - e)) for e in near if e < s):.2f}" for s in [100 + 0.2 * i for i in range(31)]))
for i, c in enumerate([e for e in near if e > 100][:5]):
    before = MU + sum(JUMP * exp(-BETA * (c - e)) for e in near if e < c)
    print(f"B story call {i + 1} at hour 100 + {c - 100:.2f}  rate before {before:.2f}  after {before + JUMP:.2f}")
print("B calls on hours 100-106  " + " ".join(f"{e - 100:.2f}" for e in near if e > 100))
top = max((MU + sum(JUMP * exp(-BETA * (c - e)) for e in near if e <= c), c) for c in near if c > 100)
print(f"B top rate on hours 100-106: {top[0]:.2f}, just after the call at hour 100 + {top[1] - 100:.2f}")
print(f"B wrong: first generation only mu(1+n)  {MU * (1 + NB):.4f}")
print(f"B try: n = 0.9   rate {MU / 0.1:.4f}  cluster {1 / 0.1:.4f}")
assert abs(cum[-1] - exact) < 1e-9, "Simpson against the closed form"
assert abs(m1 - exact) < 4 * se1 and abs(m2 - exact) < 4 * se2, "both simulations hit 70.92"
assert abs(m3 - big_lam(3.0)) < 4 * se3, "stretched clock: calls before 3 am hit Lambda(3)"
assert abs(v1 / m1 - 1) < 0.05, "thinned count is Poisson: variance equals mean"
assert abs(lam - MU / (1 - NB)) < 1e-12 and abs(bmean - 1 / (1 - NB)) < 1e-9, "fixed point, Borel mean"
assert abs(len(ev) / H - 4) < 4 * 4 / sqrt(H) and abs(inside / H - 4) < 0.05, "both Hawkes roads give 4"
assert abs(ms - 2) < 4 * ses and abs(ones - borel[0]) < 0.005, "cluster mean 2, lone share e^-0.5"
assert abs(vw / var12 - 1) < 0.1 and abs(e12 - empty12) < 4 * se12, "12-hour variance and empty start"
print("ALL CHECKS PASS")
