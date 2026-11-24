# Scale function, speed measure and boundaries -- the check behind the card.
# Standard library only.  A CIR rate dr = kappa(theta - r)dt + sigma sqrt(r) dW,
# pull 0.5 a year, level 0.04, noise 0.30 or 0.10.  Three roads: scale and speed
# integrals, finite differences on the generator, and a simulation.
from math import exp, log, sqrt, cos, pi
KAPPA, THETA, X0, TOP, DU = 0.5, 0.04, 0.04, 0.08, log(2) / 800
XS = [X0 * exp(j * DU) for j in range(-800 * 60, 800 * 6 + 1)]  # 4%/2^60 .. 4% x 2^6
I0 = 800 * 60                                                   # index of 4% in XS
idx = lambda x: I0 + round(log(x / X0) / DU)                    # grid index of a level
def cir(sig, th=THETA):
    return (lambda x: KAPPA * (th - x)), (lambda x: sig * sqrt(max(x, 0.0)))
def trap(f, i, j):  # integral of f(x) dx from XS[i] to XS[j] (dx = x du), trapezoid
    return sum(0.5 * (f(k) * XS[k] + f(k - 1) * XS[k - 1]) * DU for k in range(i + 1, j + 1))
class Diffusion:  # scale density s, scale function S, speed density m on the grid
    def __init__(self, mu, sd):
        q = [2 * mu(x) / sd(x) ** 2 * x for x in XS]            # 2 mu / sd^2, times dx/du
        ls = [0.0] * len(XS)
        for i in range(I0 + 1, len(XS)): ls[i] = ls[i - 1] - 0.5 * (q[i] + q[i - 1]) * DU
        for i in range(I0 - 1, -1, -1): ls[i] = ls[i + 1] + 0.5 * (q[i] + q[i + 1]) * DU
        self.s = [exp(v) for v in ls]                           # s(4%) = 1
        self.m = [2 / (sd(x) ** 2 * v) for x, v in zip(XS, self.s)]
        self.S = [0.0] * len(XS)                                # S(4%) = 0
        w = [v * x * DU for v, x in zip(self.s, XS)]             # s dx on each grid step
        for i in range(I0 + 1, len(XS)): self.S[i] = self.S[i - 1] + 0.5 * (w[i] + w[i - 1])
        for i in range(I0 - 1, -1, -1): self.S[i] = self.S[i + 1] - 0.5 * (w[i] + w[i + 1])
    def tests(self, k):  # Feller's two integrals at zero, the edge cut at 4%/2^k
        e, S, m = I0 - 800 * k, self.S, self.m
        arrive = trap(lambda i: (S[i] - S[e]) * m[i], e, I0)       # A: can the edge be reached?
        depart = trap(lambda i: (S[I0] - S[i]) * m[i], e, I0)      # D: can a path start there?
        return -S[e], trap(lambda i: m[i], e, I0), arrive, depart
    def band(self, b, x, zero_reached):  # band (0, b) from x: P(zero first), mean exit time
        S, m, ib, ix = self.S, self.m, idx(b), idx(x)
        if not zero_reached:                                    # S(0) = -infinity: G = S(b) - S(max)
            return 0.0, trap(lambda i: (S[ib] - S[max(i, ix)]) * m[i], 0, ib)
        S0 = S[0]; W = S[ib] - S0
        G = lambda i: (S[min(i, ix)] - S0) * (S[ib] - S[max(i, ix)]) / W
        return (S[ib] - S[ix]) / W, trap(lambda i: G(i) * m[i], 0, ib)
    def law(self):  # normalised speed density: mean, sd, chance below 0.5%
        Z = trap(lambda i: self.m[i], 0, len(XS) - 1)
        mean = trap(lambda i: XS[i] * self.m[i], 0, len(XS) - 1) / Z
        var = trap(lambda i: (XS[i] - mean) ** 2 * self.m[i], 0, len(XS) - 1) / Z
        return Z, mean, sqrt(var), trap(lambda i: self.m[i], 0, idx(X0 / 8)) / Z
def uniform_band(mu, sd, a, b, x, n):  # the same formulas on an even grid, for any band
    h = (b - a) / n; ys = [a + i * h for i in range(n + 1)]; ls, S = [0.0], [0.0]
    for i in range(1, n + 1): ls.append(ls[-1] - h * (mu(ys[i]) / sd(ys[i]) ** 2 + mu(ys[i - 1]) / sd(ys[i - 1]) ** 2))
    s = [exp(v) for v in ls]; m = [2 / (sd(y) ** 2 * v) for y, v in zip(ys, s)]
    for i in range(1, n + 1): S.append(S[-1] + 0.5 * h * (s[i] + s[i - 1]))
    ix = round((x - a) / h); G = [S[min(i, ix)] * (S[n] - S[max(i, ix)]) / S[n] * m[i] for i in range(n + 1)]
    return S[ix] / S[n], h * (sum(G) - 0.5 * (G[0] + G[n]))
def fd(mu, sd, a, b, x, rhs, fa, fb, n, entrance=False):  # road 2: L f = rhs on a grid
    h = (b - a) / n; lo, di, up, r = [0.0] * (n + 1), [1.0] * (n + 1), [0.0] * (n + 1), [0.0] * (n + 1)
    r[0], r[n] = fa, fb
    if entrance: di[0], up[0], r[0] = -mu(a) / h, mu(a) / h, rhs  # no noise at 0: drift only
    for i in range(1, n):
        y = a + i * h; D, C = 0.5 * sd(y) ** 2 / h ** 2, mu(y) / (2 * h)
        lo[i], di[i], up[i], r[i] = D - C, -2 * D, D + C, rhs
    for i in range(1, n + 1):
        w = lo[i] / di[i - 1]; di[i] -= w * up[i - 1]; r[i] -= w * r[i - 1]
    f = [0.0] * (n + 1); f[n] = r[n] / di[n]
    for i in range(n - 1, -1, -1): f[i] = (r[i] - up[i] * f[i + 1]) / di[i]
    return f[round((x - a) / h)]
ST = [0x2026]
def nxt():  # splitmix64, then a uniform on (0, 1]
    ST[0] = (ST[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ST[0]; z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0 ** 53
def simulate(sig, h, paths):  # road 3: Euler, stop on leaving (0, 8%)
    hits, total = 0, 0.0
    for _ in range(paths):
        r, t = X0, 0.0
        while 0.0 < r < TOP:
            z = sqrt(-2 * log(nxt())) * cos(2 * pi * nxt())
            r += KAPPA * (THETA - r) * h + sig * sqrt(r * h) * z; t += h
        hits += r <= 0.0; total += t
    p = hits / paths
    return p, sqrt(p * (1 - p) / paths), total / paths
f4 = lambda v: f"{v:.4f}"
print("CIR rate: pull 0.5 a year, level 4%, start 4%, band 0 to 8%")
cases = [("noise 0.30", 0.3, THETA), ("noise 0.10", 0.1, THETA), ("level 0, noise 0.30", 0.3, 0.0)]
D = {}
for name, sg, th in cases:
    D[name] = Diffusion(*cir(sg, th))
    nu = 2 * KAPPA * th / sg ** 2
    print(f"{name}: Feller ratio 2 x 0.5 x {th:.2f} / {sg ** 2:.2f} = {nu:.4f}; near 0, s ~ x^{0 - nu:.4f}, m ~ x^{nu - 1:.4f}")
print("Feller's tests at zero, cut at 4%/2^k: k | S(4%)-S(cut) | M(cut,4%) | A | D")
T = {}
for name, sg, th in cases:
    for k in (10, 20, 40):
        T[name, k] = D[name].tests(k)
        print(f"  {name:<20} {k:>2} " + " ".join(f"{v:>11.4g}" for v in T[name, k]))
finite = lambda a, b, c: abs(c - b) < 0.5 * abs(b - a)  # 20 more halvings add little
kinds = {(1, 1): "regular", (1, 0): "exit", (0, 1): "entrance", (0, 0): "natural"}
verdict = {}
for name in D:  # A finite <=> zero is reached; D finite <=> the rate can start at zero
    fa, fdp = (finite(*[T[name, k][j] for k in (10, 20, 40)]) for j in (2, 3))
    verdict[name] = kinds[fa, fdp]; print(f"  {name}: zero is {verdict[name]}")
d3 = D["noise 0.30"]
inf = [trap(lambda i: d3.S[i] * d3.m[i], I0, I0 + 800 * k) for k in (2, 4, 6)]
print("D at infinity, noise 0.30, cut at 16%, 64%, 256%:", ", ".join(f4(v) for v in inf), "-> natural")
p3, g3 = d3.band(TOP, X0, True)
p1, g1 = D["noise 0.10"].band(TOP, X0, False)
mu3, sd3 = cir(0.3); mu1, sd1 = cir(0.1)
fp3, fg3 = fd(mu3, sd3, 0, TOP, X0, 0, 1, 0, 20000), fd(mu3, sd3, 0, TOP, X0, -1, 0, 0, 20000)
fg1 = fd(mu1, sd1, 0, TOP, X0, -1, 0, 0, 20000, True)
mp, mse, mt = simulate(0.3, 0.001, 4000)
print(f"noise 0.30, P(zero before 8%): scale {p3:.4f}, finite differences {fp3:.4f}, simulation {mp:.4f} +/- {mse:.4f}")
print(f"noise 0.30, mean exit time (years): speed {g3:.4f}, finite differences {fg3:.4f}, simulation {mt:.4f}")
print(f"noise 0.10, P(zero before 8%) {p1:.4f}; mean time to 8% (years): speed {g1:.4f}, finite differences {fg1:.4f}")
ou = (lambda x: KAPPA * (THETA - x)), (lambda x: 0.02)
op, og = uniform_band(*ou, 0.04, 0.08, 0.06, 4000)
fop, fog = fd(*ou, 0.04, 0.08, 0.06, 0, 0, 1, 4000), fd(*ou, 0.04, 0.08, 0.06, -1, 0, 0, 4000)
print(f"OU band 4% to 8% from 6%: P(8% first) {op:.6f} (fd {fop:.6f}), mean exit {og:.6f} years (fd {fog:.6f})")
L = {}
for name, sg in (("noise 0.30", 0.3), ("noise 0.10", 0.1)):
    L[name] = D[name].law(); Z, mean, sd, low = L[name]
    print(f"stationary, {name}: mean {mean:.4f}, sd {sd:.4f}; moments: mean {THETA:.4f}, "
          f"variance {THETA * sg ** 2 / (2 * KAPPA):.4f}, sd {sqrt(THETA * sg ** 2 / (2 * KAPPA)):.4f}; P(rate < 0.5%) {low:.4f}")
def density(x, sg):  # stationary density per percentage point, s in closed form
    nu, beta = 2 * KAPPA * THETA / sg ** 2, 2 * KAPPA / sg ** 2
    return 0.01 * 2 / (sg ** 2 * x * (x / X0) ** -nu * exp(beta * (x - X0))) / L[f"noise {sg:.2f}"][0]
grid = [0.005 * j for j in range(1, 21)]
for sg in (0.3, 0.1): print(f"chart, density per point, noise {sg:.2f}:", " ".join(f"{density(x, sg):.3f}" for x in grid))
Zw = trap(lambda i: 1 / d3.s[i], 0, len(XS) - 1)
mean_w = trap(lambda i: XS[i] / d3.s[i], 0, len(XS) - 1) / Zw
print(f"breaks: ratio with sigma not squared, noise 0.10: {2 * KAPPA * THETA / 0.1:.4f}; "
      f"straight-line chance {(TOP - X0) / TOP:.4f}; density 1/s, noise 0.30: mean {mean_w:.4f}")
print("try: noise 0.20, S(4%)-S(cut) at k = 10, 20, 40:", ", ".join(f4(Diffusion(*cir(0.2)).tests(k)[0]) for k in (10, 20, 40)))
print(f"try: level 2%, noise 0.30, P(zero first) {Diffusion(*cir(0.3, 0.02)).band(TOP, X0, True)[0]:.4f}; "
      f"band 0 to 16%, P(zero first) {d3.band(0.16, X0, True)[0]:.4f}")
print(f"try: simulation with 100 steps a year, P(zero first) {simulate(0.3, 0.01, 4000)[0]:.4f}")
nu3 = 2 * KAPPA * THETA / 0.09
assert abs(d3.s[idx(TOP)] - 2 ** -nu3 * exp(TOP / 0.09 - X0 / 0.09)) < 1e-6  # s in closed form
assert [verdict[n] for n in D] == ["regular", "entrance", "exit"]
assert abs(p3 - fp3) < 2e-3 and abs(g3 - fg3) < 5e-3 and abs(g1 - fg1) < 1e-3  # road 1 vs road 2
assert abs(p3 - mp) < 3 * mse and abs(g3 - mt) < 0.03                           # road 1 vs road 3
assert abs(op - fop) < 1e-5 and abs(og - fog) < 1e-5
for name, sg in (("noise 0.30", 0.3), ("noise 0.10", 0.1)):                    # speed vs moments
    assert abs(L[name][1] - THETA) < 1e-5 and abs(L[name][2] - sqrt(THETA * sg ** 2 / (2 * KAPPA))) < 1e-5
print("ALL CHECKS PASS")
