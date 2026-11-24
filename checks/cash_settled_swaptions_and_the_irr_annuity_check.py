# Cash-settled swaptions and the IRR annuity -- the check behind the card.  Standard library only.
# The bell-curve area, the integrator and the random numbers are all written here;
# nothing imported already knows a swaption price.
from math import log, sqrt, exp, cos, pi

FWD = [0.050, 0.046, 0.043, 0.041, 0.040, 0.039]    # one-year forward rates, years 1..6
L, K, SIG, T, N = 10_000_000.0, 0.043, 0.30, 1.0, 5  # notional, strike, volatility, expiry, swap years
MASK = (1 << 64) - 1

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def simpson(f, a, b, n):                                 # area under f from a to b, n even slices
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def ncdf(x):                                             # N(x): bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)

D = [1.0]                                                # D[i]: today's price of 1 dollar at year i
for f in FWD: D.append(D[-1] / (1.0 + f))
A = sum(D[2:7])                                          # physical annuity from the curve, years 2..6
F = (D[1] - D[6]) / A                                    # forward swap rate

def irr(s): return sum((1 + s) ** -i for i in range(1, N + 1))            # cash annuity a(s)
def irr1(s): return sum(-i * (1 + s) ** (-i - 1) for i in range(1, N + 1))  # its slope a'(s)
def irr2(s): return sum(i * (i + 1) * (1 + s) ** (-i - 2) for i in range(1, N + 1))  # its bend a''(s)

AL0 = 1.0 / N                                            # linear TSR: 1/A_T = AL0 + B s
B = (D[1] / A - AL0) / F                                 # chosen so today's D(1) is repriced
def m(s): return irr(s) * (AL0 + B * s)                  # cash annuity counted in physical annuities
def m1(s): return irr1(s) * (AL0 + B * s) + irr(s) * B
def m2(s): return irr2(s) * (AL0 + B * s) + 2 * irr1(s) * B

def avg(g, sig=SIG, n=20000):                            # road 1: average of g(S) under the annuity measure,
    v = sig * sqrt(T)                                    # split at zk, where S = K and the payoff kinks
    zk = (log(K / F) + 0.5 * v * v) / v
    f = lambda z: g(F * exp(-0.5 * v * v + v * z)) * phi(z)
    return simpson(f, -10.0, zk, n // 2) + simpson(f, zk, 10.0, n // 2)

def black(k, sig=SIG):                                   # physical payer, receiver per unit annuity
    v = sig * sqrt(T)
    d1 = (log(F / k) + 0.5 * v * v) / v
    d2 = d1 - v
    return F * ncdf(d1) - k * ncdf(d2), k * ncdf(-d2) - F * ncdf(-d1)

pay_c = L * A * avg(lambda s: m(s) * max(s - K, 0.0))
rec_c = L * A * avg(lambda s: m(s) * max(K - s, 0.0))
pay_p, rec_p = (L * A * x for x in black(K))
swap = L * A * (F - K)                                   # the forward swap, physical
# road 2: static replication by physical swaptions, g = g'(K) (s-K)+ + integral of g''(k) (s-k)+ dk
pay_r = L * A * (m(K) * black(K)[0] + simpson(lambda k: (m2(k) * (k - K) + 2 * m1(k)) * black(k)[0], K, 0.30, 1200))
rec_r = L * A * (m(K) * black(K)[1] + simpson(lambda k: (m2(k) * (K - k) - 2 * m1(k)) * black(k)[1], 1e-6, K, 600))

state = 20261123
def uniform():                                           # xorshift64*, then a number in (0, 1)
    global state
    state ^= state >> 12
    state ^= (state << 25) & MASK
    state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & MASK) >> 11) / 9007199254740992.0 + 1.0 / 18014398509481984.0

def by_simulation(paths):                                # road 3: draw swap rates, average the cash payoff
    v = SIG * sqrt(T)                                    # minus the physical one, then add the physical
    tot = tot2 = 0.0                                     # payer's Black price (a control variate)
    for _ in range(paths):
        z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
        s = F * exp(-0.5 * v * v + v * z)
        p = (m(s) - 1.0) * max(s - K, 0.0)
        tot += p; tot2 += p * p
    mu = tot / paths
    return L * A * (black(K)[0] + mu), L * A * sqrt((tot2 / paths - mu * mu) / paths)

mc, se = by_simulation(200_000)
gap = (pay_c - rec_c) - swap
bp = L * A * 1e-4                                        # dollars per basis point a year of annuity
h, H2 = 1e-5, 1e-4                                     # nudges for slope and bend
mkt = L * D[1] * irr(F)                                  # market formula: a(F), discounted to expiry
lo, hi = 0.0, 0.10                                       # peak of m: bisect for the zero of its slope m'
for _ in range(60):
    mid = 0.5 * (lo + hi)
    if m1(mid) > 0: lo = mid
    else: hi = mid
zero_vol = L * A * (m(F) - 1) * (F - K)
tilt, bend = L * A * avg(lambda s: m(s) * (s - F)), L * A * (F - K) * (avg(m) - m(F))
rows = [("annuity A, curve", A), ("F, forward swap rate", F), ("TSR intercept 1/n", AL0), ("TSR slope b", B),
        ("cash annuity a(F)", irr(F)), ("forward annuity A/D(1)", A / D[1]), ("multiplier m(F)", m(F)),
        ("a'(F), formula", irr1(F)), ("a'(F), nudge", (irr(F + h) - irr(F - h)) / (2 * h)),
        ("a''(F), formula", irr2(F)), ("a''(F), nudge", (irr(F + H2) - 2 * irr(F) + irr(F - H2)) / (H2 * H2)),
        ("TSR check: A x avg of 1/A_T", A * avg(lambda s: AL0 + B * s)), ("  D(1)", D[1]),
        ("average multiplier E[m]", avg(m)), ("peak of m, swap rate", lo),
        ("physical payer, Black", pay_p), ("physical receiver, Black", rec_p),
        ("1 cash payer, Simpson", pay_c), ("2 cash payer, replication", pay_r), ("3 cash payer, simulation", mc),
        ("  simulation std error", se), ("  simulation gap, std errors", (pay_c - mc) / se),
        ("cash receiver, Simpson", rec_c), ("cash receiver, replication", rec_r),
        ("cash payer - receiver, Simpson", pay_c - rec_c), ("  same, replication", pay_r - rec_r),
        ("L A times one bp", bp), ("forward swap L A (F - K)", swap), ("parity gap, dollars", gap), ("parity gap, bp", gap / bp),
        ("  zero-vol part L A (m(F)-1)(F-K)", zero_vol), ("  volatility part", gap - zero_vol),
        ("    tilt: L A E[m(S)(S - F)]", tilt), ("    bend: L A (F - K)(E[m] - m(F))", bend),
        ("cash premium over physical, payer", pay_c - pay_p),
        ("market formula payer", mkt * black(K)[0]), ("market formula receiver", mkt * black(K)[1]),
        ("  market minus TSR, payer", mkt * black(K)[0] - pay_c),
        ("wrong: cash annuity not discounted", L * irr(F) * black(K)[0]),
        ("wrong: annuity from i = 0", L * A * avg(lambda s: irr(s) * (1 + s) * (AL0 + B * s) * max(s - K, 0.0))),
        ("wrong: receiver = payer - swap", pay_c - swap),
        ("try: strike = F, cash pay - rec", L * A * avg(lambda s: m(s) * (s - F))),
        ("try: intercept 0, cash payer", L * A * avg(lambda s: irr(s) * D[1] / (A * F) * s * max(s - K, 0.0)))]
for name, v in rows:
    print(f"{name:<36} {v:>16.6f}")
for sg in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]:
    g = L * A * avg(lambda s: m(s) * (s - K), sg, 8000) - swap
    print(f"sigma {sg:.1f}: gap dollars, bp       {g:>12.2f} {g / bp:>9.4f}")
ss = [0.02 + 0.01 * i for i in range(7)]
print("chart, swap rate at expiry %   " + " ".join(f"{100 * s:6.1f}" for s in ss))
print("chart, cash annuity a(S)       " + " ".join(f"{irr(s):6.3f}" for s in ss))
print("chart, TSR annuity 1/(1/n+bS)  " + " ".join(f"{1 / (AL0 + B * s):6.3f}" for s in ss))
print("chart, m(S) - 1, percent       " + " ".join(f"{100 * (m(s) - 1):6.3f}" for s in ss))

assert abs(pay_r - pay_c) < 0.001,                  "cash payer: replication = direct average"
assert abs(rec_r - rec_c) < 0.001,                  "cash receiver: replication = direct average"
assert abs(mc - pay_c) < 4.0 * se,                  "simulation within four standard errors"
assert abs(mc - pay_p) > 20.0 * se,                 "simulation tells the cash price from the physical"
assert abs(tilt + bend - (gap - zero_vol)) < 1e-3, "volatility part = tilt + bend"
assert lo < F and m(lo) > max(m(lo - 1e-3), m(lo + 1e-3)), "m peaks just below the forward"
assert abs(irr1(F) - (irr(F + h) - irr(F - h)) / (2 * h)) < 1e-6, "IRR annuity slope"
assert abs(irr2(F) - (irr(F + H2) - 2 * irr(F) + irr(F - H2)) / (H2 * H2)) < 1e-3, "IRR annuity bend"
assert abs(A * avg(lambda s: AL0 + B * s) - D[1]) < 1e-9, "TSR reprices the expiry bond"
assert abs((pay_p - rec_p) - swap) < 0.01,          "physical parity holds"
assert gap < -100.0,                                "cash parity misses the forward swap"
print("ALL CHECKS PASS")
