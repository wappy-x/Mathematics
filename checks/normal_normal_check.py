# Normal-normal update -- the check behind the card. Standard library only.
# Roads: (1) the precision-weighted formula, (2) one reading at a time,
# (3) prior times likelihood integrated on a grid by Simpson's rule, no algebra,
# (4) a seeded simulation of 100,000 sensors drawn from the prior.
import math

M0, V0, S2 = 20.0, 0.25, 1.0            # prior centre, prior variance, noise variance (deg C)
YS = [21.3, 19.8, 22.1, 20.9, 21.4]     # five readings
Z95 = 1.96                              # 95 percent of a normal lies within 1.96 sds

def update(m0, v0, s2, ys):             # road 1: precisions add, means are weighted by precision
    a0, ad = 1 / v0, len(ys) / s2
    ybar = sum(ys) / len(ys)
    return (a0 * m0 + ad * ybar) / (a0 + ad), 1 / (a0 + ad), a0, ad, ybar
def dens(x, m, v):
    return math.exp(-(x - m) ** 2 / (2 * v)) / math.sqrt(2 * math.pi * v)
def phi_cdf(x):                          # standard normal area left of x, by the erf series
    t, total, k = x / math.sqrt(2), 0.0, 0
    term = t
    while abs(term) > 1e-17:
        total += term / (2 * k + 1)
        k += 1
        term *= -t * t / k
    return 0.5 + total / math.sqrt(math.pi)
def simpson(f, lo, hi, n):
    h = (hi - lo) / n
    s = f(lo) + f(hi)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(lo + i * h)
    return s * h / 3
class SplitMix64:
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return z ^ (z >> 31)
    def unif(self): return ((self.next() >> 11) + 0.5) / 2.0 ** 53
    def normal(self):                    # Box-Muller, one draw per call
        u1, u2 = self.unif(), self.unif()
        return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)

# ---- road 1: the formula ----
mn, vn, a0, ad, ybar = update(M0, V0, S2, YS)
pv = vn + S2
print(f"house, readings sum {sum(YS):.1f}, average {ybar:.4f}")
print(f"house, prior precision {a0:.4f}, data precision {ad:.4f}, total {a0 + ad:.4f}")
print(f"house, weight on prior {a0 / (a0 + ad):.4f}, weight on data {ad / (a0 + ad):.4f}")
print(f"road 1 formula, posterior mean {mn:.4f}, variance {vn:.4f}, sd {math.sqrt(vn):.4f}")
print(f"road 1 formula, predictive variance {pv:.4f}, sd {math.sqrt(pv):.4f}")
print(f"band, Phi(1.96) {phi_cdf(Z95):.4f}")
print(f"band, 95% for the true temperature {mn - Z95 * math.sqrt(vn):.3f} to {mn + Z95 * math.sqrt(vn):.3f}")
print(f"band, 95% for the next reading {mn - Z95 * math.sqrt(pv):.3f} to {mn + Z95 * math.sqrt(pv):.3f}")

# ---- road 2: one reading at a time ----
m, v = M0, V0
for i, y in enumerate(YS, 1):
    m, v, *_ = update(m, v, S2, [y])
    print(f"road 2 sequential, after reading {i} ({y}): mean {m:.4f}, sd {math.sqrt(v):.4f}")
assert abs(m - mn) < 1e-12 and abs(v - vn) < 1e-12

# ---- road 3: prior times likelihood on a grid, then integrate ----
def unnorm(t):
    return dens(t, M0, V0) * math.prod(dens(y, t, S2) for y in YS)
LO, HI, N = 14.0, 27.0, 2000
evid = simpson(unnorm, LO, HI, N)
gmean = simpson(lambda t: t * unnorm(t), LO, HI, N) / evid
gvar = simpson(lambda t: (t - gmean) ** 2 * unnorm(t), LO, HI, N) / evid
post = lambda t: unnorm(t) / evid
pred = lambda y: simpson(lambda t: post(t) * dens(y, t, S2), 17.0, 24.5, 300)
gpv = simpson(lambda y: (y - gmean) ** 2 * pred(y), 13.0, 28.0, 300)
print(f"road 3 grid, posterior mean {gmean:.4f}, variance {gvar:.4f}, predictive variance {gpv:.4f}")
assert abs(gmean - mn) < 1e-6 and abs(gvar - vn) < 1e-6 and abs(gpv - pv) < 1e-4

# ---- road 4: simulate sensors whose true temperature is drawn from the prior ----
rng, NS = SplitMix64(20260929), 100000
sq = {"prior centre": [], "reading average": [], "posterior mean": [], "next reading": [], "shared error": []}
narrow = wide = 0
half_n, half_w = Z95 * math.sqrt(vn), Z95 * math.sqrt(pv)
for _ in range(NS):
    theta = M0 + math.sqrt(V0) * rng.normal()
    own = [rng.normal() for _ in YS]
    shared = rng.normal()
    ys = [theta + e * math.sqrt(S2) for e in own]
    ysh = [theta + math.sqrt(S2 / 2) * (shared + e) for e in own]   # same spread, errors correlated 0.5
    m1 = update(M0, V0, S2, ys)[0]
    ynew = theta + math.sqrt(S2) * rng.normal()
    sq["prior centre"].append((M0 - theta) ** 2)
    sq["reading average"].append((sum(ys) / len(ys) - theta) ** 2)
    sq["posterior mean"].append((m1 - theta) ** 2)
    sq["next reading"].append((ynew - m1) ** 2)
    sq["shared error"].append((update(M0, V0, S2, ysh)[0] - theta) ** 2)
    narrow += abs(ynew - m1) <= half_n
    wide += abs(ynew - m1) <= half_w
w0, wd = a0 / (a0 + ad), ad / (a0 + ad)
exact = {"prior centre": V0, "reading average": S2 / len(YS), "posterior mean": vn, "next reading": pv,
         "shared error": w0 ** 2 * V0 + wd ** 2 * (S2 / 2 + S2 / 2 / len(YS))}
for k, xs in sq.items():
    mean = sum(xs) / NS
    se = math.sqrt(sum((x - mean) ** 2 for x in xs) / (NS - 1) / NS)
    print(f"road 4 simulation, mean squared error of {k}: {mean:.4f} (se {se:.4f}), exact {exact[k]:.4f}")
    assert abs(mean - exact[k]) < 4 * se
for lab, hits, half in (("posterior-only band", narrow, half_n), ("predictive band", wide, half_w)):
    p_th = 2 * phi_cdf(half / math.sqrt(pv)) - 1
    p_sim, se = hits / NS, math.sqrt(hits / NS * (1 - hits / NS) / NS)
    print(f"road 4 simulation, {lab} +-{half:.4f} catches {p_sim:.4f} (se {se:.4f}), exact {p_th:.4f}")
    assert abs(p_sim - p_th) < 4 * se

# ---- what breaks ----
print(f"breaks, variances used as weights: mean {(V0 * M0 + S2 / len(YS) * ybar) / (V0 + S2 / len(YS)):.4f}")
m5, v5, *_ = update(M0, V0, S2, [ybar])
print(f"breaks, five readings counted as one: mean {m5:.4f}, sd {math.sqrt(v5):.4f}")
print(f"breaks, shared error: claimed sd {math.sqrt(vn):.4f}, actual sd {math.sqrt(exact['shared error']):.4f}")

# ---- try changing ----
mt, vt, *_ = update(M0, 25.0, S2, YS)
print(f"try, prior sd 5: mean {mt:.4f}, sd {math.sqrt(vt):.4f}")
mt, vt, *_ = update(M0, 0.01, S2, YS)
print(f"try, prior sd 0.1: mean {mt:.4f}, sd {math.sqrt(vt):.4f}")
mt, vt, *_ = update(M0, V0, S2, [ybar] * 20)
print(f"try, 20 readings averaging 21.1: mean {mt:.4f}, sd {math.sqrt(vt):.4f}, predictive sd {math.sqrt(vt + S2):.4f}")

# ---- chart points and figure ----
g1 = [19.0 + 0.25 * i for i in range(15)]
print("chart1, x " + ", ".join(f"{t:.2f}" for t in g1))
for lab, c, var in (("prior", M0, V0), ("readings", ybar, S2 / len(YS)), ("posterior", mn, vn)):
    print(f"chart1, {lab} " + ", ".join(f"{dens(t, c, var):.2f}" for t in g1))
g2 = [18.0 + 0.25 * i for i in range(21)]
print("chart2, x " + ", ".join(f"{t:.2f}" for t in g2))
print("chart2, posterior " + ", ".join(f"{dens(t, mn, vn):.2f}" for t in g2))
print("chart2, predictive " + ", ".join(f"{dens(t, mn, pv):.2f}" for t in g2))
print("chart2, grid predictive " + ", ".join(f"{pred(t):.2f}" for t in g2))
xs = lambda t: 40 + (t - 19.5) * 112
print(f"figure, prior at x {xs(M0):.1f}, readings at x {xs(ybar):.1f}, pivot at x {xs(mn):.1f}, "
      f"block heights {16 * a0:.1f} and {16 * ad:.1f}")
print("ALL CHECKS PASS")
