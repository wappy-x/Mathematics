# Correlation Greeks and implied correlation -- the check behind the card.
# Standard library only.  Nothing imported holds an answer: the bell-curve area
# is a series written out here, the integrals are Simpson's rule, the root finder
# is bisection, and the random numbers come from a generator written out here.
from math import cos, exp, log, pi, sin, sqrt
S0, K, R, Q, SIG, T, RHO, W = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 0.5, 0.5
MU, V, DISC = (R - Q - 0.5 * SIG * SIG) * T, SIG * sqrt(T), exp(-R * T)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def N(x):                                          # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term = total = x                               # x + x^3/3 + x^5/(3*5) + ...
    for k in range(1, 160):
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + phi(x) * total
def lncall(m, s, k):                   # E[(e^X - k)+] when X is normal, mean m, spread s
    if k <= 0.0: return exp(m + 0.5 * s * s) - k
    if s < 1e-12: return max(exp(m) - k, 0.0)
    d1 = (m + s * s - log(k)) / s
    return exp(m + 0.5 * s * s) * N(d1) - k * N(d1 - s)
def bs(s, vol):                        # one-asset call: the index quoted at one vol
    return DISC * lncall(log(s) + (R - Q - 0.5 * vol * vol) * T, vol * sqrt(T), K)
def simpson(f, a, b, n=200):
    h, tot = (b - a) / n, f(a) + f(b)
    for i in range(1, n): tot += (4 if i % 2 else 2) * f(a + i * h)
    return tot * h / 3.0
def exact(s1, s2, rho):
    # Road 1: fix share 1's draw z, price share 2 in closed form given z, add up over z.
    sc = V * sqrt(max(1.0 - rho * rho, 0.0))       # share 2's leftover spread once z is known
    zk = (log(K / s1) - MU) / V                    # share 1 ends exactly at the strike here
    s1T = lambda z: s1 * exp(MU + V * z)
    m2 = lambda z: log(s2) + MU + V * rho * z
    bask = lambda z: phi(z) * lncall(m2(z) + log(W), sc, K - W * s1T(z))
    best = lambda z: phi(z) * (max(s1T(z) - K, 0.0) + lncall(m2(z), sc, max(s1T(z), K)))
    worst = lambda z: phi(z) * (lncall(m2(z), sc, K) - lncall(m2(z), sc, s1T(z)))
    both = lambda f: simpson(f, -9.0, zk) + simpson(f, zk, 9.0)
    return [DISC * both(bask), DISC * both(best), DISC * simpson(worst, zk, 9.0)]
def normals(n, seed):
    # Road 2 draws: a 64-bit linear congruential generator, then Box-Muller.
    x, out = seed, []
    def u():
        nonlocal x
        x = (6364136223846793005 * x + 1442695040888963407) % 2 ** 64
        return ((x >> 11) + 0.5) / 2.0 ** 53
    for _ in range(n):
        a, b = sqrt(-2.0 * log(u())), 2.0 * pi * u()
        out.append((a * cos(b), a * sin(b)))
    return out
def mc(rho, zs):                       # antithetic pairs: each draw also used sign-flipped
    s, s2, c = [0.0] * 3, [0.0] * 3, sqrt(1.0 - rho * rho)
    for z1, z2 in zs:
        p = [0.0] * 3
        for g in (0.5, -0.5):
            a = S0 * exp(MU + 2 * V * g * z1)
            b = S0 * exp(MU + 2 * V * g * (rho * z1 + c * z2))
            p = [p[0] + 0.5 * max(W * a + W * b - K, 0.0), p[1] + 0.5 * max(max(a, b) - K, 0.0),
                 p[2] + 0.5 * max(min(a, b) - K, 0.0)]
        s, s2 = [x + y for x, y in zip(s, p)], [x + y * y for x, y in zip(s2, p)]
    n = len(zs)
    return [DISC * x / n for x in s], [DISC * sqrt((y / n - (x / n) ** 2) / n) for x, y in zip(s, s2)]
def ivol(rho): return sqrt(2 * W * W * SIG * SIG + 2 * W * W * rho * SIG * SIG)
def bisect(f, a, b):                   # f(a) < 0 < f(b), f rising
    for _ in range(100):
        m = 0.5 * (a + b)
        a, b = (m, b) if f(m) < 0.0 else (a, m)
    return 0.5 * (a + b)
def row(label, *vals): print(f"{label:<34}" + "".join(f"{v:>11.6f}" for v in vals))
NAMES = ("basket", "best-of", "worst-of")

print("--- 1. prices at correlation 0.5, two roads ---        basket    best-of   worst-of")
base, zs = exact(S0, S0, RHO), normals(100000, 20260924)
row("road 1: Simpson over one share", *base)
(m0, se), (mup, _), (mdn, _) = mc(RHO, zs), mc(RHO + 0.01, zs), mc(RHO - 0.01, zs)
row("road 2: simulation, 200000 paths", *m0)
row("  its standard error", *se)
row("one-share call (Black-Scholes)", bs(S0, SIG))
print("--- 2. correlation Greeks, per 0.01 of correlation ---")
up, dn = exact(S0, S0, RHO + 0.01), exact(S0, S0, RHO - 0.01)
crho = [(u - d) / 2.0 for u, d in zip(up, dn)]
row("bump rho +-0.01, Simpson", *crho)
cmc = [(u - d) / 2.0 for u, d in zip(mup, mdn)]
row("bump rho +-0.01, simulation, same draws", *cmc)
fresh = mc(RHO + 0.01, normals(100000, 7))[0]
row("same, fresh draws for the up price", *[(u - d) / 2.0 for u, d in zip(fresh, mdn)])
h = 1.0
pp, pm, mp, mm = (exact(S0 + a, S0 + b, RHO) for a, b in ((h, h), (h, -h), (-h, h), (-h, -h)))
xg = [(a - b - c + d) / (4 * h * h) for a, b, c, d in zip(pp, pm, mp, mm)]
row("cross-gamma, bump both shares +-1", *xg)
row("bridge factor sigma1 sigma2 T S1 S2", SIG * SIG * T * S0 * S0)
bridge = [SIG * SIG * T * S0 * S0 * g / 100.0 for g in xg]
row("sigma1 sigma2 T S1 S2 cross-gamma /100", *bridge)
row("best-of + worst-of, per 0.01", crho[1] + crho[2])
vega = (bs(S0, ivol(RHO) + 1e-4) - bs(S0, ivol(RHO) - 1e-4)) / 2e-4
dvol = 2 * W * W * SIG * SIG / (2.0 * ivol(RHO))
row("basket as index: vega, dvol/drho", vega, dvol)
row("  vega x dvol/drho /100", vega * dvol / 100.0)
print("--- 3. the index-variance identity ---")
row("variance: own, own, cross at 0.5", W * W * SIG * SIG, W * W * SIG * SIG, 2 * W * W * RHO * SIG * SIG)
row("index vol at rho 0, 0.5, 1", ivol(0.0), ivol(RHO), ivol(1.0))
row("index call at 17.32% vol / exact basket", bs(S0, ivol(RHO)), base[0])
print("--- 4. implied correlation from an index quote ---")
p18 = bs(S0, 0.18)
row("index call quoted at 18% vol, dollars", p18)
row("18%: variance, less own terms, per rho", 0.18 ** 2, 0.18 ** 2 - 2 * W * W * SIG * SIG, 2 * W * W * SIG * SIG)
row("lowest average rho, 2 and 50 names", -1.0 / (2 - 1), -1.0 / (50 - 1))
vol_back = bisect(lambda v: bs(S0, v) - p18, 0.01, 1.0)
rho_a = (vol_back ** 2 - 2 * W * W * SIG * SIG) / (2 * W * W * SIG * SIG)
row("road A: price -> vol -> identity", vol_back, rho_a)
rho_b = bisect(lambda p: bs(S0, ivol(p)) - p18, -1.0, 1.0)
row("road B: bisect rho on the price", rho_b)
rho_c = bisect(lambda p: exact(S0, S0, p)[0] - p18, -0.99, 0.99)
row("road C: bisect rho, exact basket", rho_c)
row("wrong: interpolate vols, not variances", (0.18 - ivol(0.0)) / (ivol(1.0) - ivol(0.0)))
p25 = bs(S0, 0.25)
row("quote at 25%: dollars, ceiling dollars", p25, bs(S0, ivol(1.0)))
print("  25% quote: price above the rho = 1 ceiling, so no implied correlation" if p25 > bs(S0, ivol(1.0)) else "  25% has a root")
row("wrong: average the vols, index call", bs(S0, 0.20))
tu, td = exact(S0, S0, 0.91), exact(S0, S0, 0.89)
row("try: rho 0.9, prices", *exact(S0, S0, 0.9))
row("try: rho 0.9, per 0.01", *[(u - d) / 2.0 for u, d in zip(tu, td)])
row("try: quotes 16% and 14%, implied rho", *[(v * v - 2 * W * W * SIG * SIG) / (2 * W * W * SIG * SIG) for v in (0.16, 0.14)])
print("--- 5. chart points ---")
grid = [-1.0 + 0.25 * i for i in range(9)]
print("chart, rho      " + " ".join(f"{g:6.2f}" for g in grid))
print("chart, vol %    " + " ".join(f"{100 * ivol(g):6.2f}" for g in grid))
cg = [-0.5 + 0.25 * i for i in range(7)]
print("chart2, rho     " + " ".join(f"{g:6.2f}" for g in cg))
cols = [exact(S0, S0, g) for g in cg]
for j, nm in enumerate(NAMES): print(f"chart2, {nm:<8}" + " ".join(f"{c[j]:6.2f}" for c in cols))

assert all(abs(b - m) < 3 * e for b, m, e in zip(base, m0, se)), "Simpson vs simulation"
assert abs(base[1] + base[2] - 2 * bs(S0, SIG)) < 1e-5, "best + worst = two calls, by separate integrals"
assert all(abs(c - b) < 2e-4 for c, b in zip(crho, bridge)), "rho bump vs cross-gamma bridge"
assert all(abs(c - m) < 1e-3 for c, m in zip(crho, cmc)), "rho Greek: Simpson vs simulation"
assert abs(rho_a - 0.62) < 1e-9 and abs(rho_c - rho_a) < 5e-3, "implied rho: hand value; identity vs exact basket"
assert abs(rho_b - rho_a) < 1e-9, "two roads to implied rho"
assert abs(vega * dvol / 100.0 - crho[0]) < 1e-3, "index view of the basket's rho Greek"
assert all(abs(v - bs(S0, SIG)) < 1e-5 for v in cols[-1]), "at rho = 1 all three are the one-share call"
print("ALL CHECKS PASS")
