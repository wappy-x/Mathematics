# Delta-gamma VaR and the Cornish-Fisher quantile -- the check behind the card.
# Standard library only.  The normal CDF is a series, the inverse is bisection,
# the integral is Simpson's rule, the random numbers are splitmix64 + Box-Muller.
from math import log, sqrt, exp, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                   # 0.5 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    if x > 8.5: return 1.0
    if x < -8.5: return 0.0
    term, tot, k = x, x, 0
    while abs(term) > 1e-17 * abs(tot):
        k += 1; term *= x * x / (2 * k + 1); tot += term
    return 0.5 + phi(x) * tot
def bisect(f, lo, hi, it=60):               # f(lo) < 0 < f(hi)
    for _ in range(it):
        m = 0.5 * (lo + hi)
        if f(m) < 0: lo = m
        else: hi = m
    return 0.5 * (lo + hi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
def call(S, T=T):                           # T years to expiry; T - 1/252 is one day later
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))
d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
n_calls = 100000.0                          # 1,000 contracts of 100 shares
dlt, gam = exp(-q * T) * N(d1), exp(-q * T) * phi(d1) / (S * sig * sqrt(T))
b = 0.01
dlt_bump = (call(S + b) - call(S - b)) / (2 * b)
gam_bump = (call(S + b) - 2 * call(S) + call(S - b)) / (b * b)
D, G = n_calls * dlt, n_calls * gam          # the calls' combined delta and gamma
sd_bk, sd_bd = 1e7 * 0.019, 5e6 * 0.005      # basket and bonds: one-day sd in dollars
v1, C0 = sqrt(sd_bk ** 2 + sd_bd ** 2), call(S)
z = bisect(lambda x: N(x) - 0.99, 0.0, 10.0)

def moments(D, G, s, v):                    # loss L = -(D X + G X^2 / 2) - W
    mu = -0.5 * G * s * s
    var = D * D * s * s + 0.5 * G * G * s ** 4 + v * v
    m3 = -(3 * D * D * G * s ** 4 + G ** 3 * s ** 6)
    k4 = 12 * D * D * G * G * s ** 6 + 3 * G ** 4 * s ** 8
    return mu, sqrt(var), m3 / var ** 1.5, k4 / var ** 2
def cf_var(mu, sd, g1, g2, z=z):
    w = z + (z * z - 1) * g1 / 6 + (z ** 3 - 3 * z) * g2 / 24 - (2 * z ** 3 - 5 * z) * g1 * g1 / 36
    return mu + sd * w, w
def exact_var(D, G, s, v):                  # P(L > x) = integral of phi(u) N((-x - D s u - G s^2 u^2/2)/v)
    tail = lambda x: simpson(lambda u: phi(u) * N((-x - D * s * u - 0.5 * G * s * s * u * u) / v), -8, 8, 800)
    return bisect(lambda x: 0.01 - tail(x), 0.0, 5e6, 45)
def rows_for(days, sign=1.0):
    s, v = S * sig * sqrt(days / 252), v1 * sqrt(days)
    Dx, Gx = sign * D, sign * G
    mu, sd, g1, g2 = moments(Dx, Gx, s, v)
    return z * v, z * sqrt(v * v + Dx * Dx * s * s), cf_var(mu, sd, g1, g2)[0], exact_var(Dx, Gx, s, v)

s1 = S * sig * sqrt(1 / 252)
mu, sd, g1, g2 = moments(D, G, s1, v1)
# independent road to the moments: integrate powers of the loss over X and W by Simpson
def raw(k):
    inner = lambda u: phi(u) * simpson(lambda t: phi(t) * (-(D * s1 * u + 0.5 * G * s1 * s1 * u * u) - v1 * t) ** k, -8, 8, 200)
    return simpson(inner, -8, 8, 200)
e1, e2, e3, e4 = raw(1), raw(2), raw(3), raw(4)
c2 = e2 - e1 ** 2
c3 = e3 - 3 * e1 * e2 + 2 * e1 ** 3
c4 = e4 - 4 * e1 * e3 + 6 * e1 * e1 * e2 - 3 * e1 ** 4
g1_int, g2_int = c3 / c2 ** 1.5, (c4 - 3 * c2 * c2) / c2 ** 2
base, dn, cf, ex = rows_for(1)
w = cf_var(mu, sd, g1, g2)[1]
mom_normal = mu + sd * z                    # keep gamma's mean and spread, ignore the shape
_, dn_s, cf_s, ex_s = rows_for(1, -1.0)     # the same calls, sold
# Monte Carlo, full revaluation: draw Acme's move, reprice every call at S + X;
# the rest of the book is normal and independent, so average its tail chance exactly
state = 20260928
def u01():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((x ^ (x >> 31)) >> 11) / 9007199254740992.0
M = 20000
xs = []
for i in range(M // 2):
    rad, ang = sqrt(-2 * log(1.0 - u01())), 2 * pi * u01()
    xs += [s1 * rad * cos(ang), s1 * rad * sin(ang)]
full = [n_calls * (call(S + x) - C0) for x in xs]
quad = [D * x + 0.5 * G * x * x for x in xs]
mc_var = lambda P: bisect(lambda y: 0.01 - sum(N((-y - p) / v1) for p in P) / M, 0.0, 5e6, 45)
mc_full, mc_quad = mc_var(full), mc_var(quad)

# what breaks
no_mean = cf_var(0.0, sd, g1, g2)[0]
kurt_not_excess = cf_var(mu, sd, g1, g2 + 3)[0]
pnl_skew = cf_var(mu, sd, -g1, g2)[0]
m2 = moments(D, 2 * G, s1, v1)
no_half = cf_var(*m2)[0]

out = [("s, Acme one-day move sd ($)", s1), ("delta per call", dlt), ("  by bump", dlt_bump),
       ("gamma per call", gam), ("  by bump", gam_bump), ("calls' delta D (shares)", D),
       ("calls' gamma G (shares per $)", G), ("call price today ($)", C0), ("calls' value today ($)", n_calls * C0), ("calls' one-day time decay ($)", n_calls * (call(S, T - 1 / 252) - C0)), ("basket sd ($)", sd_bk), ("bonds sd ($)", sd_bd),
       ("v, rest of book sd ($)", v1), ("D s, delta part sd ($)", D * s1), ("G s^2/sqrt2, gamma part sd", G * s1 * s1 / sqrt(2)), ("z, 99% point", z),
       ("loss mean mu", mu), ("loss sd", sd), ("loss skew g1", g1), ("  by integration", g1_int),
       ("loss excess kurtosis g2", g2), ("  by integration", g2_int), ("Cornish-Fisher w", w), ("  skew term", (z * z - 1) * g1 / 6),
       ("  kurtosis term", (z ** 3 - 3 * z) * g2 / 24), ("  skew-squared term", -(2 * z ** 3 - 5 * z) * g1 * g1 / 36),
       ("VaR without calls", base), ("VaR delta-normal", dn), ("VaR normal with dg mean, sd", mom_normal),
       ("VaR Cornish-Fisher", cf), ("VaR exact delta-gamma", ex), ("VaR MC delta-gamma", mc_quad),
       ("VaR MC full revaluation", mc_full),
       ("calls add: delta-normal", dn - base), ("calls add: Cornish-Fisher", cf - base),
       ("calls add: exact delta-gamma", ex - base), ("calls add: MC full reval", mc_full - base),
       ("sold: VaR delta-normal", dn_s), ("sold: VaR Cornish-Fisher", cf_s), ("sold: VaR exact", ex_s),
       ("wrong: forgot the mean", no_mean), ("wrong: kurtosis not excess", kurt_not_excess),
       ("wrong: P&L skew for loss skew", pnl_skew), ("wrong: gamma without the half", no_half)]
for name, val in out:
    print(f"{name:<32} {val:>14.2f}" if abs(val) >= 1000 else f"{name:<32} {val:>14.6f}")
print("horizon  add: delta-normal  Cornish-Fisher  exact   (thousands of $)")
for days in (1, 5, 10, 20):
    bs, dns, cfs, exs = rows_for(days)
    print(f"{days:>7d}  {(dns - bs) / 1e3:17.2f} {(cfs - bs) / 1e3:15.2f} {(exs - bs) / 1e3:7.2f}")
print("bars, $ thousands: none, d-normal, d-g normal, CF, full reval " + " ".join(f"{x / 1e3:.2f}" for x in (base, dn, mom_normal, cf, mc_full)))
moves = [-10.0, -7.5, -5.0, -2.5, 0.0, 2.5, 5.0, 7.5, 10.0]
print("chart, Acme move ($)  " + " ".join(f"{x:7.1f}" for x in moves))
print("chart, full reprice   " + " ".join(f"{n_calls * (call(S + x) - C0) / 1e3:7.2f}" for x in moves))
print("chart, delta only     " + " ".join(f"{D * x / 1e3:7.2f}" for x in moves))
print("chart, delta-gamma    " + " ".join(f"{(D * x + 0.5 * G * x * x) / 1e3:7.2f}" for x in moves))

assert abs(dlt - dlt_bump) < 1e-7, "delta vs bump-and-reprice"
assert abs(gam - gam_bump) < 1e-5, "gamma vs bump-and-reprice"
assert abs(g1 - g1_int) < 1e-6, "skew formula vs integration"
assert abs(g2 - g2_int) < 1e-6, "kurtosis formula vs integration"
assert abs(cf - ex) < 1.0, "Cornish-Fisher within $1 of the exact delta-gamma quantile"
assert abs(mc_quad - ex) < 300.0, "Monte Carlo on the quadratic vs the Simpson integral"
assert abs(mc_full - mc_quad) < 100.0, "full revaluation vs delta-gamma on the same draws"
assert dn > ex, "long gamma thins the loss tail"
assert dn_s < ex_s, "short gamma fattens it"
print("ALL CHECKS PASS")
