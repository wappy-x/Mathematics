# Valuing an existing CDS -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the root finders, the integrator and the
# random numbers are written out below.
from math import exp, log

R, r, T, DT = 0.40, 0.05, 5.0, 0.25        # recovery, riskless rate, years left, premium period
NOTIONAL, NQ = 10_000_000.0, 20            # $10m, twenty quarterly premium dates

def annuity(lam, n=NQ):                    # road 1: add up n survival-weighted, discounted quarters
    return sum(DT * exp(-(r + lam) * DT * i) for i in range(1, n + 1))
def annuity_geom(lam, n=NQ):               # road 2: the same sum as a geometric series
    x = exp(-(r + lam) * DT)
    return DT * x * (1 - x ** n) / (1 - x)
def protection(lam, t_end=T, rec=R):       # (1-R) times the integral of lam e^{-(r+lam)t}, closed form
    k = r + lam
    return (1 - rec) * lam / k * (1 - exp(-k * t_end))
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

def par(lam, rec=R): return protection(lam, T, rec) / annuity(lam)
def curve_legs(hz, n=NQ):                  # piecewise hazard: hz[0] to 1y, hz[1] to 3y, hz[2] to 5y
    H = P = A = 0.0
    for i in range(1, n + 1):
        h = hz[0 if i <= 4 else 1 if i <= 12 else 2]; k = r + h
        P += (1 - R) * h / k * exp(-r * DT * (i - 1) - H) * (1 - exp(-k * DT))
        H += h * DT; A += DT * exp(-r * DT * i - H)
    return P, A
def bisect(f, lo, hi):                     # f(lo) < 0 < f(hi); halve 200 times
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def newton(f, x, h=1e-7):                  # a second, unrelated root finder
    for _ in range(40):
        x -= f(x) / ((f(x + h) - f(x - h)) / (2 * h))
    return x
def hazard_for(s, rec=R): return bisect(lambda l: par(l, rec) - s, 1e-12, 5.0)
def upfront(lam, c, rec=R): return protection(lam, T, rec) - c * annuity(lam)

MASK, state = (1 << 64) - 1, 20260928
def rand():                                # splitmix64, the same stream as the Rust check
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0

cum = [0.0]
for i in range(1, NQ + 1): cum.append(cum[-1] + DT * exp(-r * DT * i))

def simulate(lam, c, paths=2_000_000):       # road 3: draw default times, pay both legs path by path
    sv = sv2 = sa = 0.0
    for _ in range(paths):
        tau = -log(rand()) / lam
        a = cum[min(int(tau / DT), NQ)]            # premiums paid on dates before default
        v = ((1 - R) * exp(-r * tau) if tau <= T else 0.0) - c * a
        sv += v; sv2 += v * v; sa += a
    m = sv / paths
    return m, ((sv2 / paths - m * m) / paths) ** 0.5, sa / paths

# ---- the old trade: protection bought at 120 bp, par is now 200 bp, five years left ----
c, s_now = 0.012, 0.020
lam = hazard_for(s_now)
A, A_g = annuity(lam), annuity_geom(lam)
x = exp(-(r + lam) * DT)
P = protection(lam)
P_simp = simpson(lambda t: (1 - R) * lam * exp(-(r + lam) * t), 0.0, T)
V = (s_now - c) * A                        # road 1: the card's formula
V_legs = P_simp - c * A_g                  # road 2: the two legs, each by its own method
V_mc, V_se, A_mc = simulate(lam, c)        # road 3: simulation
V100 = (s_now - 0.01) * A                  # the same name, struck at the 100 bp standard coupon

# ---- fixed coupon plus upfront: a name quoted at 250 bp ----
q = 0.025
lam_q = hazard_for(q)
A_q = annuity(lam_q)
U100, U500 = (q - 0.01) * A_q, (q - 0.05) * A_q
U_mc, U_se, _ = simulate(lam_q, 0.01)
back_b = par(bisect(lambda l: upfront(l, 0.01) - U100, 1e-12, 5.0))
back_n = par(newton(lambda l: upfront(l, 0.01) - U100, 0.05))
back_5 = par(bisect(lambda l: upfront(l, 0.05) - U500, 1e-12, 5.0))
A_free = annuity(0.0)
hz = []                                    # the bootstrapped curve: quotes 120, 200, 250 bp at 1, 3, 5 years
for n, s in ((4, 0.012), (12, 0.020), (20, 0.025)):
    hz.append(bisect(lambda h: (lambda p, a: p / a)(*curve_legs(hz + [h] * 3, n)) - s, 1e-12, 5.0))
P_c, A_c = curve_legs(hz)
U_c = P_c - 0.01 * A_c

rows = [
    ("house: par spread at hazard 2%, bp", 1e4 * par(0.02), 4), ("house: annuity at hazard 2%", annuity(0.02), 6),
    ("hazard that prices 200 bp", lam, 6), ("  credit-triangle guess 0.02/0.6", 0.02 / 0.6, 6),
    ("x = e^-(r+lam)/4", x, 6), ("x^20", x ** 20, 6),
    ("annuity, 20-term sum", A, 6), ("annuity, geometric series", A_g, 6), ("annuity, simulated", A_mc, 6),
    ("protection leg, closed form", P, 6), ("protection leg, Simpson", P_simp, 6), ("premium leg at 120 bp", c * A, 6),
    ("1 value per $1, (s - c) A", V, 6), ("2 value per $1, P - c A", V_legs, 6),
    ("3 value per $1, simulated", V_mc, 6), ("  simulation standard error", V_se, 6),
    ("value on $10m", V * NOTIONAL, 2), ("100 bp contract on $10m", V100 * NOTIONAL, 2),
    ("  difference", (V100 - V) * NOTIONAL, 2), ("  20 bp x annuity x $10m", 0.002 * A * NOTIONAL, 2),
    ("hazard that prices 250 bp", lam_q, 6), ("annuity at 250 bp", A_q, 6),
    ("upfront %, coupon 100", 100 * U100, 4), ("upfront $ on $10m, coupon 100", U100 * NOTIONAL, 2),
    ("price, coupon 100", 100 * (1 - U100), 4), ("upfront %, coupon 100, simulated", 100 * U_mc, 4),
    ("  simulation standard error %", 100 * U_se, 4), ("upfront %, coupon 500", 100 * U500, 4),
    ("back to bp: bisection, coupon 100", 1e4 * back_b, 6), ("back to bp: Newton, coupon 100", 1e4 * back_n, 6),
    ("back to bp: bisection, coupon 500", 1e4 * back_5, 6), ("riskless annuity (hazard 0)", A_free, 6),
    ("lowest upfront %, coupon 100", -100 * 0.01 * A_free, 4), ("lowest upfront %, coupon 500", -100 * 0.05 * A_free, 4),
    ("highest upfront %, 1 - R", 100 * (1 - R), 4), ("curve annuity to 5y", A_c, 6),
    ("curve upfront %, 250 bp, coupon 100", 100 * U_c, 4), ("curve upfront $ on $10m", U_c * NOTIONAL, 2),
    ("wrong: inception annuity, $", 0.008 * annuity(0.02) * NOTIONAL, 2),
    ("wrong: riskless annuity, $", 0.008 * A_free * NOTIONAL, 2), ("wrong: 80 bp x 5 years, $", 0.008 * 5 * NOTIONAL, 2),
    ("wrong: coupon's hazard in upfront %", 100 * 0.015 * annuity(hazard_for(0.01)), 4),
    ("try: R = 25%, upfront %, coupon 100", 100 * 0.015 * annuity(hazard_for(q, 0.25)), 4),
    ("try: par falls to 80 bp, $", -0.004 * annuity(hazard_for(0.008)) * NOTIONAL, 2),
]
for name, v, d in rows:
    print(f"{name:<38} {v:>16.{d}f}")
print(f"{'curve hazards 0-1y, 1-3y, 3-5y':<38} " + " ".join(f"{h:.6f}" for h in hz))
spreads = [50 * k for k in range(1, 9)]
print("chart, par today bp " + " ".join(f"{s:7d}" for s in spreads))
print("chart, value $k     " + " ".join(f"{(s / 1e4 - c) * annuity(hazard_for(s / 1e4)) * 10000:7.2f}" for s in spreads))
print("chart, frozen $k    " + " ".join(f"{(s / 1e4 - c) * annuity(0.02) * 10000:7.2f}" for s in spreads))
years = [5, 4, 3, 2, 1, 0]
print("chart, years left   " + " ".join(f"{y:7d}" for y in years))
print("chart, mark $k      " + " ".join(f"{(protection(lam, y) - c * annuity(lam, 4 * y)) * 10000:7.2f}" for y in years))
quotes = [50 * k for k in range(1, 13)]
print("chart, quote bp     " + " ".join(f"{s:6d}" for s in quotes))
print("chart, up% c=100    " + " ".join(f"{100 * (s / 1e4 - 0.01) * annuity(hazard_for(s / 1e4)):6.2f}" for s in quotes))
print("chart, up% c=500    " + " ".join(f"{100 * (s / 1e4 - 0.05) * annuity(hazard_for(s / 1e4)):6.2f}" for s in quotes))

assert abs(par(0.02) - 0.01210561519) < 1e-10,   "house par spread, 121.06 bp"
assert abs(V - V_legs) < 1e-10,                   "formula vs legs priced by Simpson and the geometric series"
assert abs(V_mc - V) < 4 * V_se,                  "simulation lands within 4 standard errors"
assert abs(U_mc - U100) < 4 * U_se,               "simulated upfront within 4 standard errors"
assert abs(A_mc - A) < 0.01,                      "simulated premium stream vs the annuity sum"
assert abs(back_b - q) < 1e-12 and abs(back_n - q) < 1e-12, "two root finders return the 250 bp quote"
assert abs(back_5 - q) < 1e-12,                   "coupon 500 round trip returns 250 bp"
assert abs(A_c - 4.027235) < 1e-6 and abs(P_c / A_c - q) < 1e-12, "curve matches the bootstrap card"
assert abs(U_c - 0.0604) < 5e-5 and U_c > U100,   "curve upfront 6.04%, above the flat 5.95%"
print("ALL CHECKS PASS")
