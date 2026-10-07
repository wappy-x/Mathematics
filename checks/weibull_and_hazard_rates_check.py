# Weibull and hazard rates -- the check behind the card.  Only math primitives.
# Light bulbs.  Wear-out: shape K = 3, scale ETA = 1000 burning hours, set beside
# shapes 0.5 and 1 at the same scale.  A bathtub batch: a flaw (shape 0.5, scale
# 10000 h) races wear, and the bulb dies at whichever strikes first.
# Roads: the closed form exp(-(t/eta)^k); a product of survived slices that never
# calls exp; Simpson and a Stirling series for the mean; a seeded simulation.
from math import exp, log, sqrt, pi
K, ETA, FK, FETA, M64 = 3.0, 1000.0, 0.5, 10000.0, (1 << 64) - 1

def surv(t, k=K, eta=ETA):            # road one: S(t) = exp(-(t/eta)^k)
    return exp(-(t / eta) ** k)

def hazard(t, k=K, eta=ETA):          # h(t) = (k/eta) (t/eta)^(k-1)
    return k / eta * (t / eta) ** (k - 1)

def slices(t, d, k=K, eta=ETA):       # road two: survive each slice of d hours in turn
    s = 1.0
    for j in range(round(t / d)):
        s *= 1.0 - hazard((j + 0.5) * d, k, eta) * d
    return s

def simpson(g, a, b, n):              # area under g from a to b
    w = (b - a) / n
    tot = g(a) + g(b)
    for j in range(1, n):
        tot += (4.0 if j % 2 else 2.0) * g(a + j * w)
    return tot * w / 3.0

def gamma(x):                         # Stirling's series at x + 10, stepped back down
    z, shift = x + 10.0, 1.0
    for j in range(10):
        shift *= x + j
    lg = (z - 0.5) * log(z) - z + 0.5 * log(2 * pi) + 1 / (12 * z) - 1 / (360 * z ** 3) + 1 / (1260 * z ** 5)
    return exp(lg) / shift

class SplitMix64:                     # the same random numbers in both languages
    def __init__(self, seed):
        self.s = seed
    def uniform(self):                # strictly between 0 and 1
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0

def counted_hazard(lives, t, w):      # failures in (t - w/2, t + w/2] per hour, per bulb alive
    alive = sum(x > t - w / 2 for x in lives)
    p = sum(t - w / 2 < x <= t + w / 2 for x in lives) / alive
    return p / w, sqrt(p * (1 - p) / alive) / w

def pct(xs):
    return ", ".join(f"{100 * x:.2f}" for x in xs)

print(f"wear-out bulbs: shape {K}, scale {ETA} hours")
print(f"S(500) = {surv(500):.4f}; S(1000) = {surv(1000):.4f}; failed by 1000 h = {1 - surv(1000):.4f}")
print(f"h(500) = {1000 * hazard(500):.2f} per 1000 h; h(1000) = {1000 * hazard(1000):.2f} per 1000 h")
print(f"median = {ETA * log(2) ** (1 / K):.2f} h")
for k in (0.5, 1.0, 3.0):
    print(f"shape {k}: h(200) = {1000 * hazard(200, k):.3f}, h(800) = {1000 * hazard(800, k):.3f} per 1000 h; "
          f"200 h fresh {surv(200, k):.4f}, 200 more after 800 h {surv(1000, k) / surv(800, k):.4f}")
print("slices, shape 3, S(1000) with 100, 10, 1 h slices: "
      + ", ".join(f"{slices(1000, d):.4f}" for d in (100.0, 10.0, 1.0)) + f"; exact {surv(1000):.4f}")
print(f"slices, shape 0.5, S(1000) with 1 h and 0.01 h slices: {slices(1000, 1.0, 0.5):.4f}, "
      f"{slices(1000, 0.01, 0.5):.4f}; exact {surv(1000, 0.5):.4f}")
gk = gamma(1 + 1 / K)
area = simpson(surv, 0.0, 4000.0, 4000)
print(f"mean by Stirling: 1000 x Gamma(1 + 1/{K:g}) = 1000 x {gk:.6f} = {ETA * gk:.2f} h")
print(f"mean by Simpson, area under S(t) to 4000 h = {area:.2f} h")
print(f"Gamma(3) = {gamma(3.0):.6f} and Gamma(2) = {gamma(2.0):.6f} (should be 2 and 1)")
print(f"10 bulbs in series, shape 3: scale 1000 x 10^(-1/3) = {ETA * 10 ** (-1 / K):.2f} h")

a, b = FK / FETA ** FK, K / ETA ** K  # bathtub: flaw a t^(-1/2) plus wear b t^2
def bath(t):
    return hazard(t, FK, FETA) + hazard(t)
lo, hi = 1.0, 1000.0                  # ternary search for the lowest hazard
for _ in range(200):
    m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    lo, hi = (lo, m2) if bath(m1) < bath(m2) else (m1, hi)
tstar = (a / (4 * b)) ** 0.4          # where the slope -a/2 t^(-3/2) + 2 b t is zero
print(f"bathtub: flaw hazard {1000 * a:.0f}/sqrt(t) per 1000 h, wear 3 (t/1000)^2 per 1000 h")
print(f"bathtub low point: search {lo:.1f} h, algebra {tstar:.1f} h, hazard {1000 * bath(tstar):.3f} per 1000 h")
print(f"bathtub survival S(100) = {surv(100, FK, FETA) * surv(100):.4f}; S(1000) = {surv(1000, FK, FETA) * surv(1000):.4f}")

rng, N = SplitMix64(2026), 40000
wear, both = [], []
for _ in range(N):                    # each bulb draws a wear life and a flaw life
    w = ETA * (-log(rng.uniform())) ** (1 / K)
    f = FETA * (-log(rng.uniform())) ** (1 / FK)
    wear.append(w)
    both.append(min(w, f))
mw = sum(wear) / N
sew = sqrt(sum((x - mw) ** 2 for x in wear) / (N - 1) / N)
print(f"simulated, seed 2026, {N} bulbs: mean wear life {mw:.2f} h (se {sew:.2f})")
hz = [counted_hazard(wear, t, 20.0) for t in (500.0, 1000.0)]
print("simulated wear hazard at 500 h, 1000 h: "
      + "; ".join(f"{1000 * h:.2f} (se {1000 * s:.2f})" for h, s in hz) + " per 1000 h")
ks = []
for j in range(20):                   # Weibull plot slope in 20 batches of 2000 bulbs
    batch = wear[2000 * j: 2000 * (j + 1)]
    s5, s10 = (sum(x > t for x in batch) / 2000 for t in (500.0, 1000.0))
    ks.append(log(log(s10) / log(s5)) / log(2))
mk = sum(ks) / 20
sek = sqrt(sum((x - mk) ** 2 for x in ks) / 19 / 20)
print(f"shape read off the Weibull plot, 20 batches: {mk:.3f} (se {sek:.3f})")
sb = [sum(x > t for x in both) / N for t in (100.0, 1000.0)]
seb = [sqrt(p * (1 - p) / N) for p in sb]
print(f"simulated bathtub S(100) = {sb[0]:.4f} (se {seb[0]:.4f}); S(1000) = {sb[1]:.4f} (se {seb[1]:.4f})")
hb = [counted_hazard(both, t, 20.0) for t in (100.0, 1000.0)]
print("simulated bathtub hazard at 100 h, 1000 h: "
      + "; ".join(f"{1000 * h:.2f} (se {1000 * s:.2f})" for h, s in hb) + " per 1000 h; "
      + f"sum of hazards {1000 * bath(100):.2f}, {1000 * bath(1000):.2f}")

grid = [50 * i for i in range(1, 21)]
print("figure, hours: " + ", ".join(str(t) for t in grid))
print("figure, flaw per 1000 h: " + ", ".join(f"{1000 * hazard(t, FK, FETA):.2f}" for t in grid))
print("figure, wear per 1000 h: " + ", ".join(f"{1000 * hazard(t):.2f}" for t in grid))
print("figure, total per 1000 h: " + ", ".join(f"{1000 * bath(t):.2f}" for t in grid))
sg = [200 * i for i in range(11)]
print("figure, hours: " + ", ".join(str(t) for t in sg))
for k in (0.5, 1.0, 3.0):
    print(f"figure, S shape {k} %: " + pct([surv(t, k) for t in sg]))
print(f"mistake, exponential with the same mean: 200 more after 800 h = {exp(-200 / (ETA * gk)):.4f}")
print(f"mistake, fresh survival used at 800 h: {surv(200):.4f}, not {surv(1000) / surv(800):.4f}")
print(f"mistake, h(1000) x 200 h as a chance: {hazard(1000) * 200:.4f}; true 1 - S(1200)/S(1000) = "
      f"{1 - surv(1200) / surv(1000):.4f}")
sx = [surv(t, FK, FETA) * surv(t) for t in (100.0, 1000.0)]
print(f"mistake, one Weibull through the bathtub at 100 h and 1000 h: shape {log(log(sx[1]) / log(sx[0])) / log(10):.3f}")
assert abs(slices(1000, 1.0) - surv(1000)) < 1e-3 < abs(slices(1000, 100.0) - surv(1000))
assert abs(slices(1000, 0.01, 0.5) - surv(1000, 0.5)) < 1e-3
assert abs(ETA * gk - area) < 1e-6 and abs(gamma(3.0) - 2.0) < 1e-10  # Stirling vs Simpson
assert abs(lo - tstar) < 1e-3                                        # search vs algebra
assert abs(mw - ETA * gk) < 4 * sew and abs(mk - K) < 4 * sek       # simulation vs formula
assert all(abs(h - hazard(t)) < 4 * s for (h, s), t in zip(hz, (500.0, 1000.0)))
assert all(abs(p - x) < 4 * s for p, s, x in zip(sb, seb, sx))    # product rule vs count
assert all(abs(h - bath(t)) < 4 * s for (h, s), t in zip(hb, (100.0, 1000.0)))
print("ALL CHECKS PASS")
