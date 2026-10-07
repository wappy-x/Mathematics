# Spread options on futures: Margrabe (zero strike) and Kirk (with a strike).
# Standard library only.  The normal CDF, the integrator and the random numbers
# are written here; nothing imported already knows the answer.
from math import log, sqrt, exp, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 == 1 else 2.0) * f(a + i * h)
    return s * h / 3.0

def N(x):                                                         # bell-curve area left of x
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 400)

def black(F, K, v, D):                  # Black-76 call; v = volatility times root-time
    if v <= 0.0: return D * max(F - K, 0.0)
    d1 = (log(F / K) + 0.5 * v * v) / v
    return D * (F * N(d1) - K * N(d1 - v))

def ratio_vol(s1, s2, rho): return sqrt(max(s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2, 0.0))

def margrabe(F1, F2, s1, s2, rho, T, D):                          # road 1, zero strike
    return black(F1, F2, ratio_vol(s1, s2, rho) * sqrt(T), D)

def kirk_vol(F2, K, s1, s2, rho):
    a = F2 / (F2 + K)                    # crude's share of "crude plus strike"
    return ratio_vol(s1, s2 * a, rho)

def kirk(F1, F2, K, s1, s2, rho, T, D):                           # road 2, with a strike
    return black(F1, F2 + K, kirk_vol(F2, K, s1, s2, rho) * sqrt(T), D)

def by_integral(F1, F2, K, s1, s2, rho, T, D):
    # Road 3: fix crude's shock z, gasoline is then lognormal on its own; average over z.
    rt, c = sqrt(T), sqrt(1.0 - rho * rho)
    def f(z):
        F2T = F2 * exp(-0.5 * s2 * s2 * T + s2 * rt * z)
        m = F1 * exp(-0.5 * s1 * s1 * T * rho * rho + s1 * rt * rho * z)   # gasoline's mean given z
        return black(m, F2T + K, s1 * rt * c, 1.0) * phi(z)
    return D * simpson(f, -8.0, 8.0, 2000)

class Rng:                                                        # splitmix64, written out
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        z ^= z >> 31
        return ((z >> 11) + 0.5) / 9007199254740992.0

def monte_carlo(F1, F2, strikes, s1, s2, rho, T, D, n, seed):
    # Road 4: correlated terminal prices, z2 = rho g1 + sqrt(1 - rho^2) g2 (Cholesky).
    rng, rt, c = Rng(seed), sqrt(T), sqrt(1.0 - rho * rho)
    sums, sq = [0.0] * len(strikes), [0.0] * len(strikes)
    for _ in range(n):
        r = sqrt(-2.0 * log(rng.u())); w = 2.0 * pi * rng.u()
        g1, g2 = r * cos(w), r * sin(w)
        A = F1 * exp(-0.5 * s1 * s1 * T + s1 * rt * g1)
        B = F2 * exp(-0.5 * s2 * s2 * T + s2 * rt * (rho * g1 + c * g2))
        for j, K in enumerate(strikes):
            p = max(A - B - K, 0.0); sums[j] += p; sq[j] += p * p
    out = []
    for j in range(len(strikes)):
        mean = sums[j] / n
        out.append((D * mean, D * sqrt((sq[j] / n - mean * mean) / n)))
    return out

# ---- the house crack spread: gasoline 100, crude 90 USD/bbl, vols 30% and 25%, rho 0.5, six months, 5% ----
F1, F2, s1, s2, rho, T, r = 100.0, 90.0, 0.30, 0.25, 0.5, 0.5, 0.05
D = exp(-r * T)
sig = ratio_vol(s1, s2, rho); v = sig * sqrt(T)
d1 = (log(F1 / F2) + 0.5 * v * v) / v; d2 = d1 - v
M = margrabe(F1, F2, s1, s2, rho, T, D)
M_int = by_integral(F1, F2, 0.0, s1, s2, rho, T, D)
kv = kirk_vol(F2, 10.0, s1, s2, rho)
Kk = kirk(F1, F2, 10.0, s1, s2, rho, T, D)
K_int = by_integral(F1, F2, 10.0, s1, s2, rho, T, D)
(mc0, se0), (mc10, se10) = monte_carlo(F1, F2, (0.0, 10.0), s1, s2, rho, T, D, 400000, 20260927)
h = 0.01
dg_bump = (margrabe(F1 + h, F2, s1, s2, rho, T, D) - margrabe(F1 - h, F2, s1, s2, rho, T, D)) / (2 * h)
dc_bump = (margrabe(F1, F2 + h, s1, s2, rho, T, D) - margrabe(F1, F2 - h, s1, s2, rho, T, D)) / (2 * h)
drho = (margrabe(F1, F2, s1, s2, rho + 0.01, T, D) - margrabe(F1, F2, s1, s2, rho - 0.01, T, D)) / 2.0
drho_an = D * F1 * phi(d1) * sqrt(T) * (-s1 * s2 / sig) * 0.01   # vega times d(sigma)/d(rho), per 0.01
rows = [("ratio vol sigma", sig), ("discount D = e^-rT", D), ("d1", d1), ("d2", d2),
    ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("gasoline half D F1 N(d1)", D * F1 * N(d1)),
    ("crude half    D F2 N(d2)", D * F2 * N(d2)),
    ("1 Margrabe, K = 0", M), ("3 integral, K = 0", M_int), ("4 Monte Carlo, K = 0", mc0), ("  MC std error", se0),
    ("margined quote, K = 0 (no D)", M / D),
    ("Kirk weight a = F2/(F2+K)", F2 / (F2 + 10.0)), ("Kirk vol", kv),
    ("2 Kirk, K = 10", Kk), ("3 integral, K = 10", K_int), ("4 Monte Carlo, K = 10", mc10), ("  MC std error", se10),
    ("  Kirk minus integral", Kk - K_int), ("  Kirk minus MC", Kk - mc10),
    ("  (MC - integral) / std error", (mc10 - K_int) / se10),
    ("delta gasoline D N(d1)", D * N(d1)), ("  by bump", dg_bump),
    ("delta crude -D N(d2)", -D * N(d2)), ("  by bump", dc_bump),
    ("per +0.01 correlation, formula", drho_an), ("  by bump", drho),
    ("wrong: +2 rho in the ratio vol", black(F1, F2, sqrt(s1 * s1 + s2 * s2 + 2 * rho * s1 * s2) * sqrt(T), D)),
    ("wrong: correlation dropped (rho 0)", margrabe(F1, F2, s1, s2, 0.0, T, D)),
    ("wrong: Kirk, crude vol not scaled", black(F1, F2 + 10.0, sig * sqrt(T), D)),
    ("wrong: Margrabe minus D K", M - D * 10.0),
    ("try: rho = 0.9, K = 0", margrabe(F1, F2, s1, s2, 0.9, T, D)),
    ("try: T = 1, K = 10, Kirk", kirk(F1, F2, 10.0, s1, s2, rho, 1.0, exp(-r))),
    ("try: T = 1, K = 10, integral", by_integral(F1, F2, 10.0, s1, s2, rho, 1.0, exp(-r))),
    ("try: vols 30/30, rho = 1", margrabe(F1, F2, s1, s1, 1.0, T, D)),
    ("try: rho -0.5, K=20, Kirk - exact", kirk(F1, F2, 20.0, s1, s2, -0.5, T, D) - by_integral(F1, F2, 20.0, s1, s2, -0.5, T, D))]
for name, x in rows: print(f"{name:<36} {x:>12.6f}")
print("strike  Kirk      integral  Kirk-int(cents)")
for K in (0.0, 5.0, 10.0, 20.0, 30.0):
    a, b = kirk(F1, F2, K, s1, s2, rho, T, D), by_integral(F1, F2, K, s1, s2, rho, T, D)
    print(f"{K:>6.0f}  {a:8.4f}  {b:8.4f}  {100 * (a - b):+8.4f}")
rhos = (-0.9, -0.6, -0.3, 0.0, 0.3, 0.5, 0.6, 0.9)
print("chart, rho      " + " ".join(f"{x:6.1f}" for x in rhos))
print("chart, K = 0    " + " ".join(f"{margrabe(F1, F2, s1, s2, x, T, D):6.2f}" for x in rhos))
print("chart, K = 10   " + " ".join(f"{kirk(F1, F2, 10.0, s1, s2, x, T, D):6.2f}" for x in rhos))
xs = (-10.0, -5.0, 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0)
print("chart, spread   " + " ".join(f"{x:6.0f}" for x in xs))
print("chart, pay K=0  " + " ".join(f"{max(x, 0.0):6.2f}" for x in xs))
print("chart, pay K=10 " + " ".join(f"{max(x - 10.0, 0.0):6.2f}" for x in xs))
print("chart, profit   " + " ".join(f"{max(x - 10.0, 0.0) - Kk / D:6.2f}" for x in xs))
assert abs(M - 13.153108728969) < 1e-6, "Margrabe vs the shelf's house number"
assert abs(M_int - M) < 1e-6, "integral road lands on Margrabe at zero strike"
assert abs(mc0 - M) < 4.0 * se0, "simulation within four standard errors of Margrabe"
assert abs(Kk - K_int) < 1e-5, "Kirk within a thousandth of a cent of the integral at strike 10"
assert abs(mc10 - K_int) < 4.0 * se10, "simulation within four standard errors of the integral"
assert abs(dg_bump - D * N(d1)) < 1e-6, "bumped gasoline delta vs D N(d1)"
assert abs(drho - drho_an) < 1e-4, "bumped correlation sensitivity vs vega times d(sigma)/d(rho)"
print("ALL CHECKS PASS")
