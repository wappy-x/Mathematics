# Where structural models break: Merton's spread curve, its vanishing short end, and two fixes.
from math import exp, log, sqrt, pi, cos

def N(x):                                    # standard normal CDF, written here
    if x < -3.0:                             # far tail: continued fraction for the Mills ratio
        a, cf = -x, 0.0
        for k in range(80, 0, -1):
            cf = k / (a + cf)
        return exp(-0.5 * x * x) / sqrt(2 * pi) / (a + cf)
    if x > 3.0:
        return 1.0 - N(-x)
    term, total, k = x, x, 0                 # series: 1/2 + phi(x) * sum x^(2k+1) / (1*3*...*(2k+1))
    while abs(term) > 1e-17:
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + exp(-0.5 * x * x) / sqrt(2 * pi) * total

def put(V, D, r, s, T):                      # the default put: what the lenders give up
    d1 = (log(V / D) + (r + 0.5 * s * s) * T) / (s * sqrt(T))
    return D * exp(-r * T) * N(-(d1 - s * sqrt(T))) - V * N(-d1)

def spread(P, D, r, T):                      # annualised yield gap of the risky debt, in basis points
    return -log(1.0 - max(P, 0.0) / (D * exp(-r * T))) / T * 1e4

def put_by_integral(V, D, r, s, T, n=4000):  # road 2: integrate the lenders' loss against the bell curve
    m, w = (r - 0.5 * s * s) * T, s * sqrt(T)
    top = (log(D / V) - m) / w               # above this z the firm repays in full
    f = lambda z: (D - V * exp(m + w * z)) * exp(-0.5 * z * z) / sqrt(2 * pi)
    h = (top + 12.0) / n
    tot = f(-12.0) + f(top) + sum((4 if i % 2 else 2) * f(-12.0 + i * h) for i in range(1, n))
    return exp(-r * T) * tot * h / 3.0

def jump_put(V, D, r, s, T, lam, mu, dl):   # Merton's jump model: a Poisson-weighted sum of smooth puts
    k = exp(mu + 0.5 * dl * dl) - 1.0
    lp, tot, w = lam * (1 + k), 0.0, exp(-lam * (1 + k) * T)
    for n in range(60):
        tot += w * put(V, D, r - lam * k + n * log(1 + k) / T, sqrt(s * s + n * dl * dl / T), T)
        w *= lp * T / (n + 1)
    return tot

def jump_limit(V, D, lam, mu, dl):          # road 3: short-end spread = jump rate x average loss per jump
    d1 = (log(V / D) + mu + dl * dl) / dl
    return lam * (D * N(-(d1 - dl)) - V * exp(mu + 0.5 * dl * dl) * N(-d1)) / D * 1e4

def hazard_spread(hz, R, T):                 # zero bond, flat hazard, recovery R of face paid at maturity
    q = exp(-hz * T)
    return -log(q + R * (1 - q)) / T * 1e4

state = [88172645463325252]
def unif():                                  # xorshift64*: our own random numbers
    x = state[0]
    x ^= x >> 12; x ^= (x << 25) & 0xFFFFFFFFFFFFFFFF; x ^= x >> 27
    state[0] = x
    return (((x * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) * 2.0**-53 + 2.0**-54
def normal():
    return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
def row(label, v, fmt=".4f"):
    print(f"{label:<38}{v:>14{fmt}}")

V, D, r, s = 100.0, 80.0, 0.05, 0.20
lam, mu, dl = 0.10, -0.30, 0.15             # jumps: one per ten years on average, log size -0.30 +- 0.15
hz, R = 0.02, 0.40                          # flat hazard 2% a year, 40% recovery
k = exp(mu + 0.5 * dl * dl) - 1.0

print("house firm, one year")
d2y = (log(V / D) + (r - 0.5 * s * s)) / s
row("default put", put(V, D, r, s, 1.0), ".6f")
row("risk-neutral default prob N(-d2)", N(-d2y), ".6f")
row("spread, bp", spread(put(V, D, r, s, 1.0), D, r, 1.0))
print("spread, bp: D=80 formula | D=80 integral | D=65 | D=90 | jumps | hazard")
rows = []
for lab, T in zip(["1m", "3m", "6m", "1y", "2y", "3y", "5y", "7y", "10y"], [1/12, .25, .5, 1., 2., 3., 5., 7., 10.]):
    a, b = spread(put(V, D, r, s, T), D, r, T), spread(put_by_integral(V, D, r, s, T), D, r, T)
    lo, hi = spread(put(V, 65.0, r, s, T), 65.0, r, T), spread(put(V, 90.0, r, s, T), 90.0, r, T)
    j, h = spread(jump_put(V, D, r, s, T, lam, mu, dl), D, r, T), hazard_spread(hz, R, T)
    rows.append((a, b, j, h))
    print(f"{lab:>4}{a:>9.2f}{b:>11.6f}{lo:>9.2f}{hi:>9.2f}{j:>9.2f}{h:>9.2f}")

print("why the short end vanishes: one month")
T = 1 / 12
d2m = (log(V / D) + (r - 0.5 * s * s) * T) / (s * sqrt(T))
ceiling = N(-d2m) / (T * (1 - N(-d2m))) * 1e4
nu, b = r - 0.5 * s * s, log(D / V)
hit = N((b - nu * T) / (s * sqrt(T))) + (D / V) ** (2 * nu / (s * s)) * N((b + nu * T) / (s * sqrt(T)))
row("drop needed ln(100/80)", log(V / D), ".6f")
row("one-month sd of log assets", s * sqrt(T), ".6f")
row("d2, standard deviations away", d2m, ".6f")
row("default prob N(-d2)", N(-d2m), ".8f")
row("first-passage prob, barrier 80", hit, ".8f")
row("ceiling N(-d2)/(T(1-N(-d2))), bp", ceiling)
row("default prob N(-d2), one week", N(-(log(V / D) + nu / 52) / (s * sqrt(1 / 52))), ".3e")

lo_, hi_, g = 0.5, 6.0, (sqrt(5) - 1) / 2   # road for the hump: golden-section search for its top
f = lambda t: -spread(put(V, D, r, s, t), D, r, t)
for _ in range(80):
    x1, x2 = hi_ - g * (hi_ - lo_), lo_ + g * (hi_ - lo_)
    if f(x1) < f(x2): hi_ = x2
    else: lo_ = x1
Tpk = 0.5 * (lo_ + hi_)
row("hump peaks at, years", Tpk)
row("peak spread, bp", -f(Tpk))

print("the short end with a fix, bp")
jl = jump_limit(V, D, lam, mu, dl)
row("jumps: spread, one day", spread(jump_put(V, D, r, s, 1 / 365, lam, mu, dl), D, r, 1 / 365))
row("jumps: limit lam x E[loss]/D", jl)
row("hazard: spread, one day", hazard_spread(hz, R, 1 / 365))
row("hazard: limit hz(1-R)", hz * (1 - R) * 1e4)

n, sm, sj, sh = 200000, 0.0, 0.0, 0.0      # road 4: simulate one year of assets, and ten years of hazard
for _ in range(n):
    z = normal()
    L, u, jumps = exp(-lam), unif(), 0      # Poisson count by multiplying uniforms
    while u > L:
        jumps += 1; u *= unif()
    y = sum(mu + dl * normal() for _ in range(jumps))
    sm += max(D - V * exp(r - 0.5 * s * s + s * z), 0.0)
    sj += max(D - V * exp(r - lam * k - 0.5 * s * s + s * z + y), 0.0)
    sh += 1.0 if -log(unif()) / hz > 10.0 else R   # default time drawn from the flat hazard
mc_m, mc_j = spread(exp(-r) * sm / n, D, r, 1.0), spread(exp(-r) * sj / n, D, r, 1.0)
mc_h = -log(sh / n) / 10.0 * 1e4
row("simulated 1y spread, smooth", mc_m, ".2f")
row("simulated 1y spread, jumps", mc_j, ".2f")
row("simulated 10y hazard spread", mc_h, ".2f")

print("what breaks")
row("2y gap not divided by T, bp", rows[4][0] * 2)
row("N(-d2) read as the 1y spread, bp", N(-d2y) * 1e4)
row("jumps, drift not corrected, 1y, bp", spread(jump_put(V * exp(lam * k), D, r, s, 1.0, lam, mu, dl), D, r, 1.0))

assert all(abs(a - b) < 1e-6 for a, b, _, _ in rows),   "integral road must match the formula"
assert abs(rows[3][0] - 90.713) < 0.01,                  "house example: 90.7 bp at one year"
assert rows[0][0] < ceiling,                             "one-month spread must sit under its Mills ceiling"
assert abs(rows[0][2] - jl) < 2.0,                       "one-month jump spread near the one-jump limit"
assert abs(mc_m - rows[3][0]) < 4.0,                     "simulation agrees with Merton at one year"
assert abs(mc_j - rows[3][2]) < 5.0,                     "simulation agrees with the jump series at one year"
assert abs(mc_h - rows[8][3]) < 1.0,                     "simulated default times agree with the hazard bond"
assert all(a < -f(Tpk) for a, _, _, _ in rows),          "no grid maturity beats the golden-section peak"
print("ALL CHECKS PASS")
