# A digital from a call spread, and the skew term -- the check behind the card.
# Standard library only. The normal CDF is a series written out, the integral is
# Simpson's rule, the random numbers come from a 64-bit xorshift written here.
from math import log, sqrt, exp, pi, cos

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                  # 0.5 + phi(x)(x + x^3/3 + x^5/15 + ...)
    term, total, n = x, x, 1
    while abs(term) > 1e-18 and n < 999:
        term *= x * x / (2 * n + 1); total += term; n += 1
    return 0.5 + phi(x) * total

S, K, r, q, sig, T, s = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, -0.0004
D0 = exp(-r * T)                                           # discount factor D(T)
def d12(S, K, v, T):
    d1 = (log(S / K) + (r - q + 0.5 * v * v) * T) / (v * sqrt(T))
    return d1, d1 - v * sqrt(T)
def call(K, v, S=S, T=T):
    d1, d2 = d12(S, K, v, T); return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def put(K, v, S=S, T=T):
    d1, d2 = d12(S, K, v, T); return K * exp(-r * T) * N(-d2) - S * exp(-q * T) * N(-d1)
def digital(K, v, T=T): return exp(-r * T) * N(d12(S, K, v, T)[1])
def vega(K, v, T=T): return S * exp(-q * T) * phi(d12(S, K, v, T)[0]) * sqrt(T)
def smile(K, s=s): return sig + s * (K - 100.0)            # vol falls 0.04 points per $1 of strike
def mcall(K, s=s, T=T): return call(K, smile(K, s), T=T)
def mput(K, s=s): return put(K, smile(K, s))
def skewed(K, s=s, T=T): return digital(K, smile(K, s), T) - vega(K, smile(K, s), T) * s
def spread(f, K, h): return (f(K - h) - f(K + h)) / (2 * h)

flat = lambda k: call(k, sig)
D, h = digital(K, sig), 0.01
cs1, cst, one = spread(flat, K, 1.0), spread(flat, K, h), flat(K) - flat(K + 1)
d1, d2 = d12(S, K, sig, T)
M = 4000; a, b = -d2, 8.0; w = (b - a) / M                  # road 3: Simpson over z > -d2
simp = D0 * w / 3 * sum((1 if i in (0, M) else 4 if i % 2 else 2) * phi(a + i * w) for i in range(M + 1))
x, hits, n = 88172645463325252, 0, 200000                 # road 4: simulate S_T
def rnd():
    global x
    x ^= (x << 13) & 0xFFFFFFFFFFFFFFFF; x ^= x >> 7; x ^= (x << 17) & 0xFFFFFFFFFFFFFFFF
    return ((x >> 11) + 0.5) / 9007199254740992.0
for _ in range(n // 2):
    u1, u2 = rnd(), rnd(); rad = sqrt(-2.0 * log(u1))
    for z in (rad * cos(2 * pi * u2), -rad * cos(2 * pi * u2)):
        hits += S * exp((r - q - 0.5 * sig * sig) * T + sig * sqrt(T) * z) > K
mc, se = D0 * hits / n, D0 * sqrt(hits / n * (1 - hits / n) / n)
pflat = (put(K + 1, sig) - put(K - 1, sig)) / 2

V = vega(K, sig); Vb = (call(K, sig + 1e-4) - call(K, sig - 1e-4)) / 2e-4
corr, Dsk = -V * s, skewed(K)
mcs1, mcst = spread(mcall, K, 1.0), spread(mcall, K, h)
mpst = -spread(mput, K, h)
lo, hi = mcall(K) - mcall(K + 1), mcall(K - 1) - mcall(K)
ddelta = D0 * phi(d2) / (S * sig * sqrt(T))
cdelta = lambda k, S1: (call(k, sig, S=S1 + 1e-3) - call(k, sig, S=S1 - 1e-3)) / 2e-3
sdelta = (cdelta(K - 1, S) - cdelta(K + 1, S)) / 2
dvega = -D0 * phi(d2) * d1 / sig
svega = (vega(K - 1, sig) - vega(K + 1, sig)) / 2

rows = [("d1", d1), ("d2", d2), ("N(d2)", N(d2)), ("discount e^-rT", D0),
    ("1 digital e^-rT N(d2)", D), ("2 spread (C(99)-C(101))/2", cs1), ("  C(99)", flat(99)), ("  C(101)", flat(101)),
    ("  spread, h = 0.01", cst), ("3 Simpson over z > -d2", simp), ("4 simulated, 200000 paths", mc), ("  std error", se),
    ("digital put e^-rT N(-d2)", D0 * N(-d2)), ("  put spread (P(101)-P(99))/2", pflat), ("  call + put", cs1 + pflat),
    ("vega at 100, formula", V), ("  vega by bump", Vb), ("skew slope dsigma/dK", s), ("skew term -vega x slope", corr),
    ("market vol at 99", smile(99)), ("market vol at 101", smile(101)),
    ("5 skewed digital, formula", Dsk), ("6 market spread, h = 1", mcs1), ("  market spread, h = 0.01", mcst),
    ("  market digital put", mpst), ("  call + put", mcst + mpst), ("  lower C(100)-C(101)", lo), ("  upper C(99)-C(100)", hi),
    ("greek: digital delta", ddelta), ("  spread delta", sdelta), ("greek: digital vega", dvega), ("  spread vega", svega),
    ("wrong: strike vol, no skew", D), ("wrong: N(d1)", D0 * N(d1)), ("wrong: slope in points", D - V * (-0.04)),
    ("wrong: sign flipped", D + V * s), ("wrong: no divide by width", mcall(99) - mcall(101)),
    ("wrong: one-sided 100/101", one),
    ("try: slope -0.0008", skewed(K, -0.0008)), ("try: K = 110, term", -vega(110, smile(110)) * s),
    ("try: T = 0.25, term", -vega(K, sig, 0.25) * s), ("try: h = 5 spread", spread(flat, K, 5.0))]
for name, v in rows: print(f"{name:<30} {v:>12.6f}")
print("width     centered miss   one-sided miss")
miss = []
for hh in (2.0, 1.0, 0.5, 0.25):
    miss.append(spread(flat, K, hh) - D)
    print(f"{hh:5.2f} {miss[-1]:16.9f} {(flat(K) - flat(K + hh)) / hh - D:16.9f}")
ks = [80.0 + 5 * i for i in range(9)]
print("chart, strike         " + " ".join(f"{k:6.0f}" for k in ks))
print("chart, flat, cents    " + " ".join(f"{100 * digital(k, sig):6.2f}" for k in ks))
print("chart, strike vol     " + " ".join(f"{100 * digital(k, smile(k)):6.2f}" for k in ks))
print("chart, market, cents  " + " ".join(f"{100 * skewed(k):6.2f}" for k in ks))
xs = [97.0, 98.0, 99.0, 99.5, 100.0, 100.5, 101.0, 102.0, 103.0]
print("chart, S_T            " + " ".join(f"{v:6.1f}" for v in xs))
print("chart, ramp           " + " ".join(f"{(max(v - 99, 0) - max(v - 101, 0)) / 2:6.2f}" for v in xs))
print("chart, step           " + " ".join(f"{1.0 if v > K else 0.0:6.2f}" for v in xs))

assert abs(cst - D) < 1e-8, "tight flat spread vs e^-rT N(d2)"
assert abs(simp - D) < 1e-10, "Simpson road vs the series CDF"
assert abs(mc - D) < 4 * se, "simulation within 4 standard errors"
assert abs(Vb - V) < 1e-6, "bumped vega vs formula"
assert abs(mcst - Dsk) < 1e-7, "tight market spread vs digital + skew term"
assert abs(mcst + mpst - exp(-r * T)) < 1e-8, "market call + put digitals = one discounted dollar"
assert lo < mcst < hi, "market digital inside the two one-sided spreads"
assert flat(K) - flat(K + 1) < simp < flat(K - 1) - flat(K), "flat digital inside the sandwich"
assert all(3.8 < miss[i] / miss[i + 1] < 4.1 for i in range(3)), "centered miss quarters as width halves"
assert abs(sdelta - ddelta) < 1e-4, "spread delta near digital delta"
assert abs(svega - dvega) < 1e-3, "spread vega near digital vega"
print("ALL CHECKS PASS")
