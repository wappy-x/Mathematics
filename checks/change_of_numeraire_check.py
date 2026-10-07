# Change of numeraire -- the check behind the card.  Standard library only.
# A share with no dividend: S0 = 100, strike K = 100, bank rate r = 0.05,
# volatility sig = 0.20, real-world drift mu = 0.08, T = 1 year.
# Claim: N(d1) is the chance that S_T > K under the share measure Q^S.
# Roads: the formula; Simpson's rule on the reweighted Q-density; a binomial
# tree summed over every node; a seeded simulation under P, Q and Q^S.
from math import exp, log, sqrt, pi, cos

S0, K, r, sig, mu, T, q = 100.0, 100.0, 0.05, 0.20, 0.08, 1.0, 0.02
vt, grow = sig * sqrt(T), exp(r * T)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def Ncdf(x):  # series: 1/2 + phi(x) * (x + x^3/3 + x^5/(3*5) + ...)
    term, total, n = x, x, 0
    while abs(term) > 1e-17:
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total
def simpson(f, a, b, n=4000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def ST(z, drift): return S0 * exp((drift - 0.5 * sig * sig) * T + vt * z)
def bisect(f, lo, hi):
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) < 0) == (f(mid) < 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

# Road 1: the formula
d1 = (log(S0 / K) + (r + 0.5 * sig * sig) * T) / vt
d2, dP = d1 - vt, (log(S0 / K) + (mu - 0.5 * sig * sig) * T) / vt
N1, N2, NP = Ncdf(d1), Ncdf(d2), Ncdf(dP)
call = S0 * N1 - K * exp(-r * T) * N2
# Road 2: integrate the density Z = S_T/(S0 e^rT) against Q's bell curve, no d1 used
zs = bisect(lambda z: ST(z, r) - K, -10.0, 10.0)        # exercise boundary in Q's z
Z = lambda z: ST(z, r) / (S0 * grow)
pS_int = simpson(lambda z: Z(z) * phi(z), zs, 10.0)
mass = simpson(lambda z: Z(z) * phi(z), -10.0, 10.0)
call_int = exp(-r * T) * simpson(lambda z: (ST(z, r) - K) * phi(z), zs, 10.0)
mass_q = simpson(lambda z: ST(z, r - q) / (S0 * grow) * phi(z), -10.0, 10.0)
assert abs(pS_int - N1) < 1e-9
assert abs(mass - 1.0) < 1e-9                            # Z is a true density
assert abs(call_int - call) < 1e-8
assert abs(mass_q - exp(-q * T)) < 1e-9
assert abs(mass_q - 1.0) > 0.01                          # not a probability measure
rows = [("d1", d1), ("d2", d2), ("dP (real-world drift)", dP),
        ("N(d1)  formula", N1), ("N(d2)  Q chance S_T > K", N2), ("N(dP)  P chance S_T > K", NP),
        ("boundary z* by bisection", zs), ("  -d2", -d2),
        ("Q^S chance by Simpson", pS_int), ("E^Q[Z] by Simpson", mass),
        ("call by Simpson", call_int), ("call  S0 N(d1) - K e^-rT N(d2)", call),
        ("share leg  S0 N(d1)", S0 * N1), ("cash leg  K e^-rT N(d2)", K * exp(-r * T) * N2),
        ("lambda  (mu - r)/sig", (mu - r) / sig), ("Q^S drift  r + sig^2", r + sig * sig),
        ("log drift P    mu - sig^2/2", mu - 0.5 * sig * sig), ("log drift Q    r - sig^2/2", r - 0.5 * sig * sig),
        ("log drift Q^S  r + sig^2/2", r + 0.5 * sig * sig), ("sig^2", sig * sig), ("sig^2/2", 0.5 * sig * sig)]
for name, v in rows: print(f"{name:<34} {v:>12.6f}")
# Road 3: binomial tree, every node.  Dollar price of the share leg vs share-measure chance.
u1s = exp(vt); p1 = (grow - 1.0 / u1s) / (u1s - 1.0 / u1s)
for name, v in (("one step: up factor u", u1s), ("one step: down factor d", 1.0 / u1s),
                ("one step: Q up chance p", p1), ("one step: Q^S up chance p u e^-rT", p1 * u1s / grow)):
    print(f"{name:<34} {v:>12.6f}")
print("tree   n   dollars/S0   Q^S chance   error vs N(d1)")
errs = []
for n in (25, 101, 401, 1601):
    dt = T / n
    u = exp(sig * sqrt(dt))
    p = (exp(r * dt) - 1.0 / u) / (u - 1.0 / u)
    pS = p * u / exp(r * dt)                            # the share-measure up chance
    lc, dollars, chanceS = 0.0, 0.0, 0.0
    for j in range(n + 1):
        if j > 0: lc += log(n - j + 1) - log(j)
        if (2 * j - n) * sig * sqrt(dt) > log(K / S0):
            Sj = S0 * u ** (2 * j - n)
            dollars += exp(-r * T) * Sj * exp(lc + j * log(p) + (n - j) * log(1 - p))
            chanceS += exp(lc + j * log(pS) + (n - j) * log(1 - pS))
    assert abs(dollars / S0 - chanceS) < 1e-12
    errs.append(chanceS - N1)
    print(f"tree {n:>5} {dollars / S0:>11.6f} {chanceS:>12.6f} {chanceS - N1:>14.6f}")
assert abs(errs[-1]) < 2e-3
assert abs(errs[-1]) < abs(errs[0])
# Road 4: seeded simulation.  SplitMix64, Box-Muller (cosine half), seed 20260930.
state = 20260930
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((x ^ (x >> 31)) >> 11) * 2.0 ** -53
M, lam = 200000, (mu - r) / sig
acc = [[0.0, 0.0] for _ in range(4)]
for _ in range(M):
    u1, u2 = 1.0 - rnd(), rnd()
    z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
    sq, ss, sp = ST(z, r), ST(z, r + sig * sig), ST(z, mu)
    L = exp(-lam * sqrt(T) * z - 0.5 * lam * lam * T)     # dQ/dP on this path
    xs = (sq / (S0 * grow) * (sq > K), 1.0 * (ss > K), L * sp / (S0 * grow) * (sp > K), 1.0 * (sp > K))
    for k in range(4):
        acc[k][0] += xs[k]; acc[k][1] += xs[k] * xs[k]
labels = ("sim Q, weighted by Z", "sim Q^S, plain count", "sim P, weighted by L Z", "sim P, plain count")
targets = (N1, N1, N1, NP)
print("simulation, 200000 draws          estimate     std error")
for k in range(4):
    m = acc[k][0] / M
    se = sqrt((acc[k][1] / M - m * m) / M)
    assert abs(m - targets[k]) < 4 * se
    print(f"{labels[k]:<30} {m:>12.6f} {se:>12.6f}")
print(f"{'dividend share, E^Q[Z] q=0.02':<34} {mass_q:>12.6f}")
print(f"{'wrong: share leg with N(d2)':<34} {S0 * N2:>12.6f}")
print(f"{'wrong: share leg with N(dP)':<34} {S0 * NP:>12.6f}")
print(f"{'wrong: P tilted by S_T/(S0 e^muT)':<34} {S0 * Ncdf(dP + vt):>12.6f}")
xs = list(range(50, 171, 10))
fQ = [phi((log(s / S0) - (r - 0.5 * sig * sig) * T) / vt) / (s * vt) for s in xs]
print("chart S_T  " + " ".join(f"{s}" for s in xs))
print("chart Q    " + " ".join(f"{100 * f:.2f}" for f in fQ))
print("chart Q^S  " + " ".join(f"{100 * f * s / (S0 * grow):.2f}" for f, s in zip(fQ, xs)))
def dd(S, K, sg): return (log(S / K) + (r + 0.5 * sg * sg) * T) / (sg * sqrt(T))
for name, v in (("try: sig = 0.40, d1", dd(S0, K, 0.4)), ("try: sig = 0.40, d2", dd(S0, K, 0.4) - 0.4 * sqrt(T)),
                ("try: sig = 0.40, N(d1)", Ncdf(dd(S0, K, 0.4))), ("try: sig = 0.40, N(d2)", Ncdf(dd(S0, K, 0.4) - 0.4 * sqrt(T))),
                ("try: K = 120, N(d1)", Ncdf(dd(S0, 120.0, sig))), ("try: K = 120, N(d2)", Ncdf(dd(S0, 120.0, sig) - vt))):
    print(f"{name:<34} {v:>12.6f}")
print(f"{'curves cross at forward S0 e^rT':<34} {S0 * grow:>12.6f}")
