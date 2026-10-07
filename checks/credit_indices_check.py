# Credit indices -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the root finder, the integrator, the normal
# CDF and the random numbers are written out below.
from math import exp, log, sqrt, cos, pi

R, r, T, DT, NQ = 0.40, 0.05, 5.0, 0.25, 20   # recovery, riskless rate, years, quarter, 20 fee dates
NOTIONAL, NAMES, COUPON = 10_000_000.0, 125, 0.01
QUOTES = [0.0080] * 100 + [0.0300] * 25          # 100 names at 80 bp, 25 at 300 bp
TRADED = 0.0117                                  # the index's own quoted spread on the screen

def annuity(lam):                                # road 1: add up twenty survival-weighted quarters
    return sum(DT * exp(-(r + lam) * DT * i) for i in range(1, NQ + 1))
def annuity_geom(lam):                           # road 2: the same sum as a geometric series
    x = exp(-(r + lam) * DT)
    return DT * x * (1 - x ** NQ) / (1 - x)
def protection(lam, rec=R):                      # (1-R) times the integral of lam e^{-(r+lam)t}
    k = r + lam
    return (1 - rec) * lam / k * (1 - exp(-k * T))
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3
def bisect(f, lo, hi):                           # f(lo) < 0 < f(hi); halve 200 times
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def hazard_for(s, rec=R): return bisect(lambda l: protection(l, rec) / annuity(l) - s, 1e-12, 5.0)
def upfront_flat(q): return (q - COUPON) * annuity(hazard_for(q))   # the one-name quoting convention

def index_legs(quotes, rec=R):                   # road 1: closed-form legs, summed name by name
    lams = [hazard_for(s, rec) for s in quotes]
    return sum(protection(l, rec) for l in lams) / NAMES, sum(annuity(l) for l in lams) / NAMES, lams
def intrinsic(quotes, rec=R):
    P, A, _ = index_legs(quotes, rec)
    return P / A

MASK, state = (1 << 64) - 1, 20260928
def rand():                                      # splitmix64, the same stream as the Rust check
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(rand())) * cos(2.0 * pi * rand())
def ncdf(x):                                     # normal CDF from a Chebyshev fit to erfc, error < 1.2e-7
    z = abs(x) / sqrt(2.0)
    t = 1.0 / (1.0 + 0.5 * z)
    e = t * exp(-z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (0.09678418 + t * (-0.18628806
        + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587 + t * (-0.82215223 + t * 0.17087277)))))))))
    return 1.0 - 0.5 * e if x >= 0 else 0.5 * e

cum = [0.0]
for i in range(1, NQ + 1): cum.append(cum[-1] + DT * exp(-r * DT * i))

def simulate(lams, s, rho, paths):               # road 3: default times for all 125 names, path by path
    sv = sv2 = sp = sa = 0.0
    for _ in range(paths):
        z, p, a = gauss(), 0.0, 0.0
        for lam in lams:
            u = rand() if rho == 0 else ncdf(-(sqrt(rho) * z + sqrt(1 - rho) * gauss()))
            tau = -log(u) / lam
            a += cum[min(int(tau / DT), NQ)]
            if tau <= T: p += (1 - R) * exp(-r * tau)
        v = (p - s * a) / NAMES                  # index value per $1 at spread s on this path
        sv += v; sv2 += v * v; sp += p; sa += a
    m = sv / paths
    return m, sqrt((sv2 / paths - m * m) / paths), sp / sa

# ---- the 125 legs, two ways ----
P, A, lams = index_legs(QUOTES)
l_t, l_w = lams[0], lams[-1]
P_simp = sum(simpson(lambda t: (1 - R) * l * exp(-(r + l) * t), 0.0, T) for l in lams) / NAMES
A_geom = sum(annuity_geom(l) for l in lams) / NAMES
s_I = P_simp / A_geom                            # road 2: total protection over total annuity
s_w = sum(s * annuity(l) for s, l in zip(QUOTES, lams)) / sum(annuity(l) for l in lams)
s_avg = sum(QUOTES) / NAMES
w_wide = 25 * annuity(l_w) / (NAMES * A)
U_sum = sum(protection(l) - COUPON * annuity(l) for l in lams) / NAMES
U_trd = upfront_flat(TRADED)
m0, se0, q0 = simulate(lams, s_I, 0.0, 100000)
m2, se2, q2 = simulate(lams, s_I, 0.20, 100000)
# ---- one wide name defaults at 40% recovery ----
jtd = (1 - R) / NAMES - (protection(l_w) - COUPON * annuity(l_w)) / NAMES
s_after = intrinsic(QUOTES[:-1])                 # 124 names left; weights unchanged, 1/125 each

rows = [
    ("house: par spread at hazard 2%, bp", 1e4 * protection(0.02) / annuity(0.02), 4),
    ("hazard, 80 bp name", l_t, 6), ("hazard, 300 bp name", l_w, 6),
    ("annuity, 80 bp name", annuity(l_t), 6), ("annuity, 300 bp name", annuity(l_w), 6),
    ("protection leg, 80 bp name", protection(l_t), 6), ("protection leg, 300 bp name", protection(l_w), 6),
    ("index protection leg per $1", P, 6), ("  same, Simpson", P_simp, 6),
    ("index annuity per $1", A, 6), ("  same, geometric series", A_geom, 6),
    ("1 intrinsic spread, P / A, bp", 1e4 * s_I, 4), ("2 annuity-weighted quotes, bp", 1e4 * s_w, 4),
    ("plain average of quotes, bp", 1e4 * s_avg, 4),
    ("share of the 300 bp names, headcount", 25 / NAMES, 4), ("share of the 300 bp names, weighted", w_wide, 4),
    ("3 simulated value at s_I, independent", m0, 7), ("  standard error, independent", se0, 7),
    ("  simulated spread, independent, bp", 1e4 * q0, 4),
    ("3 simulated value at s_I, rho = 20%", m2, 7), ("  standard error, rho = 20%", se2, 7),
    ("  simulated spread, rho = 20%, bp", 1e4 * q2, 4),
    ("intrinsic upfront %, sum of 125 legs", 100 * U_sum, 4), ("  (s_I - c) x index annuity, %", 100 * (s_I - COUPON) * A, 4),
    ("intrinsic upfront $ on $10m", U_sum * NOTIONAL, 2),
    ("flat conversion of s_I, upfront %", 100 * upfront_flat(s_I), 4),
    ("traded quote, bp", 1e4 * TRADED, 4), ("traded upfront %, flat conversion", 100 * U_trd, 4),
    ("traded upfront $ on $10m", U_trd * NOTIONAL, 2), ("skew, traded - intrinsic, bp", 1e4 * (TRADED - s_I), 4),
    ("skew in upfront $ on $10m", (U_trd - U_sum) * NOTIONAL, 2),
    ("slice per name $", NOTIONAL / NAMES, 2),
    ("default: payout % of notional", 100 * (1 - R) / NAMES, 4), ("default: payout $", (1 - R) / NAMES * NOTIONAL, 2),
    ("default: notional left $", NOTIONAL * (NAMES - 1) / NAMES, 2),
    ("coupon per quarter before $", COUPON * DT * NOTIONAL, 2), ("coupon per quarter after $", COUPON * DT * NOTIONAL * (NAMES - 1) / NAMES, 2),
    ("default: legs of that name given up $", (protection(l_w) - COUPON * annuity(l_w)) / NAMES * NOTIONAL, 2),
    ("default: net gain to buyer $", jtd * NOTIONAL, 2), ("intrinsic after default, bp", 1e4 * s_after, 4),
    ("wrong: skew against plain average, bp", 1e4 * (TRADED - s_avg), 4),
    ("wrong: payout with no recovery, %", 100 / NAMES, 4),
    ("wrong: upfront from plain average, %", 100 * upfront_flat(s_avg), 4),
    ("try: R = 25%, intrinsic, bp", 1e4 * intrinsic(QUOTES, 0.25), 4),
    ("try: a tight name defaults, bp", 1e4 * intrinsic(QUOTES[1:]), 4),
    ("try: all 125 at 124 bp, bp", 1e4 * intrinsic([0.0124] * NAMES), 4),
]
for name, v, d in rows:
    print(f"{name:<40} {v:>14.{d}f}")
wide = [100 * k for k in range(1, 9)]
chart_i = [1e4 * intrinsic([0.008] * 100 + [w / 1e4] * 25) for w in wide]
print("chart, wide names bp " + " ".join(f"{w:7d}" for w in wide))
print("chart, intrinsic bp  " + " ".join(f"{v:7.2f}" for v in chart_i))
print("chart, average bp    " + " ".join(f"{(8000 + 25 * w) / 125:7.2f}" for w in wide))

assert abs(protection(0.02) / annuity(0.02) - 0.01210561519) < 1e-10, "house par spread, 121.06 bp"
assert abs(s_I - s_w) < 1e-12, "Simpson legs vs annuity-weighted quotes"
assert round(1e4 * s_I, 1) == 121.0 and s_I < s_avg, "the syllabus's 121.0 bp, below the 124 bp average"
assert abs(U_sum - (s_I - COUPON) * A) < 1e-12, "sum of 125 upfronts vs one index upfront"
assert abs(m0) < 4 * se0 and abs(m2) < 4 * se2, "both simulations price the index at zero at s_I"
assert all(c < (8000 + 25 * w) / 125 for c, w in zip(chart_i, wide)), "intrinsic below average"
assert s_after < s_I < intrinsic(QUOTES[1:]), "a wide default lowers s_I, a tight one raises it"
assert all(annuity(hazard_for(k * 20e-4)) > annuity(hazard_for((k + 1) * 20e-4)) for k in range(1, 50)), "A(s) falls"
print("ALL CHECKS PASS")
