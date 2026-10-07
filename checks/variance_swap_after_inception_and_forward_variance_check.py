# Marking a running variance swap, and forward variance between two expiries, by several roads.
import math
S, r, q, T, t, DAYS = 100.0, 0.05, 0.02, 1.0, 0.5, 252
KVOL, NVEGA = 20.0, 100000.0          # strike in vol points; vega notional, dollars per vol point
NVAR = NVEGA / (2 * KVOL)             # variance notional: dollars per variance point (vol point squared)
N = NVAR * 1e4                        # the same notional per unit of decimal variance
KVAR, DONE, IMP = 0.04, 0.18, 0.20    # strike; realised vol so far; implied vol for the rest
tau = T - t; D = math.exp(-r * tau)    # time left, and the discount factor over it
def ncdf(x):                          # own bell-curve area: 0.5 + pdf(x) (x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9: return 0.0 if x < 0 else 1.0
    s, term, n = x, x, 1
    while abs(term) > 1e-17 * abs(s):
        n += 2; term *= x * x / n; s += term
    return 0.5 + s * math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)
def bs(s, k, sig, ta, call):
    v = sig * math.sqrt(ta); d1 = (math.log(s / k) + (r - q + 0.5 * sig * sig) * ta) / v; d2 = d1 - v
    if call: return s * math.exp(-q * ta) * ncdf(d1) - k * math.exp(-r * ta) * ncdf(d2)
    return k * math.exp(-r * ta) * ncdf(-d2) - s * math.exp(-q * ta) * ncdf(-d1)
def simpson(f, a, b, n):
    h, acc = (b - a) / n, 0.0
    for i in range(n + 1):
        acc += (1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h)
    return h / 3 * acc
def strip_pv(s, f0, sig, ta, width, n):  # out-of-the-money puts and calls weighted 1/K^2, strikes K = f0 e^x
    g = lambda x: bs(s, f0 * math.exp(x), sig, ta, x > 0) / (f0 * math.exp(x))
    return simpson(g, -width, 0.0, n) + simpson(g, 0.0, width, n)
def strip_var(sig, ta):               # road 2: fair variance of a swap from the strip, no formula for it
    f0 = S * math.exp((r - q) * ta)
    return 2 * math.exp(r * ta) / ta * strip_pv(S, f0, sig, ta, 12 * sig * math.sqrt(ta), 400)
def mark(done, imp_var, ta=tau):      # road 1: the marking formula
    return math.exp(-r * ta) * N * ((T - ta) / T * done ** 2 + ta / T * imp_var - KVAR)
p = lambda label, x, d=6: print(f"{label:<44}{x:>16.{d}f}")
p("variance notional, $ per variance point", NVAR, 2)
p("  the same, $ per unit of decimal variance", N, 0)
p("discount factor D for the last half-year", D)
rem = strip_var(IMP, tau)
p("remaining fair variance, strip of options", rem)
p("realised so far, as total variance", t / T * DONE ** 2)
p("expected total variance at expiry", t / T * DONE ** 2 + tau / T * rem)
p("  short of the 0.04 strike by", KVAR - (t / T * DONE ** 2 + tau / T * rem))
m1, m2 = mark(DONE, IMP ** 2), mark(DONE, rem)
p("1 mark, formula", m1, 2)
p("2 mark, strip for the rest", m2, 2)
M64 = (1 << 64) - 1
state = 20260927
def u01():                            # splitmix64 random numbers, then a uniform in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
dt = 1.0 / DAYS; mu = (r - q - 0.5 * IMP ** 2) * dt; vs = IMP * math.sqrt(dt)
paths, left, acc = 20000, DAYS // 2, DONE ** 2 * t   # 126 trading days left; squared returns so far
tot = tot2 = 0.0
for _ in range(paths):
    ss = 0.0
    for _ in range(left // 2):        # Box-Muller: two bell-curve draws per pair of uniforms
        rad = math.sqrt(-2 * math.log(u01())); ang = 2 * math.pi * u01()
        a, b = mu + vs * rad * math.cos(ang), mu + vs * rad * math.sin(ang)
        ss += a * a + b * b
    pay = N * ((acc + ss) / T - KVAR)
    tot += pay; tot2 += pay * pay
mean = tot / paths; se = math.sqrt((tot2 / paths - mean * mean) / paths)
p("3 mark, 20000 simulated daily paths", D * mean, 2)
p("  its standard error", D * se, 2)
assert abs(rem - IMP ** 2) < 1e-7, "strip must price the rest at 20% squared"
assert abs(D * mean - m1) < 4 * D * se, "simulation must land within 4 standard errors"
T1, T2, V1, V2 = 0.5, 1.0, 0.18, 0.20
w1, w2 = V1 ** 2 * T1, V2 ** 2 * T2
fv = (w2 - w1) / (T2 - T1)
p("total variance w1 to half a year", w1); p("total variance w2 to one year", w2)
p("  six-month swap strike, 18% squared", V1 ** 2)
p("1 forward variance, formula", fv); p("  forward vol, percent", 100 * math.sqrt(fv), 2)
fs = (T2 * strip_var(V2, T2) - T1 * strip_var(V1, T1)) / (T2 - T1)
p("2 forward variance, two strips", fs)
Z, NZ = 7.0, 160                      # road 3: two-step bell-curve integral, then bisection on the call
hz = 2 * Z / NZ
grid = [(-Z + i * hz, hz / 3 * (1 if i in (0, NZ) else 4 if i % 2 else 2) * math.exp(-0.5 * (-Z + i * hz) ** 2) / math.sqrt(2 * math.pi)) for i in range(NZ + 1)]
def call2(sf):                        # one-year call: 18% for six months, then sf for six
    a, b = V1 * math.sqrt(T1), sf * math.sqrt(T2 - T1)
    m = math.log(S) + (r - q) * T2 - 0.5 * (a * a + b * b)
    acc = 0.0
    for z, w in grid:
        for y, v in grid:
            acc += w * v * max(math.exp(m + a * z + b * y) - 100.0, 0.0)
    return math.exp(-r * T2) * acc
target = bs(S, 100.0, V2, T2, True)
lo, hi = 0.01, 0.60
for _ in range(40):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if call2(mid) < target else (lo, mid)
sf = 0.5 * (lo + hi)
p("  one-year call at 20%, target", target)
p("3 forward vol matching that call, percent", 100 * sf, 2)
p("3 forward variance from it", sf * sf)
assert abs(fs - fv) < 1e-6, "two strips must give the formula's forward variance"
assert abs(sf - math.sqrt(fv)) < 2e-4, "the two-step integral must give the forward vol"
lo, hi = 0.0, 0.6                     # break-even: the vol for the rest at which the mark is zero
for _ in range(60):
    mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if mark(DONE, mid * mid) < 0 else (lo, mid)
p("break-even vol for the rest, percent", 100 * lo, 2)
assert abs(lo - math.sqrt(fv)) < 1e-9, "break-even must equal the forward vol"
p("no forward: w1 = 24% squared x 0.5", 0.24 ** 2 * 0.5); p("no forward: w2 = 16% squared x 1", 0.16 ** 2 * 1)
p("no forward: 24% to 0.5y, 16% to 1y, fwd var", (0.16 ** 2 * 1 - 0.24 ** 2 * 0.5) / 0.5)
vega = D * NVAR * tau / T * 2 * 100 * IMP
vb = (mark(DONE, strip_var(IMP + 1e-4, tau)) - mark(DONE, strip_var(IMP - 1e-4, tau))) / 2e-2
p("vega per vol point, formula", vega, 2)
p("vega per vol point, strip bumped", vb, 2)
p("vega per vol point at inception", math.exp(-r * T) * NVAR * 2 * 100 * IMP, 2)
p("per variance point of realised so far", D * NVAR * t / T, 2)
assert abs(vb - vega) < 0.05, "vega by bumping the strip"
f0, h = S * math.exp((r - q) * tau), 0.5
V = lambda s: N * (tau / T) * (2 / tau) * strip_pv(s, f0, IMP, tau, 3.0, 600)
C = lambda s: bs(s, 100.0, IMP, tau, True)
g2 = lambda f, s: s * s * (f(s + h) - 2 * f(s) + f(s - h)) / (h * h)
p("dollar gamma S^2 x Gamma, formula 2ND/T", 2 * N * D / T, 0)
k = 2 * N * D / T / g2(C, 100.0)      # calls needed to match the strip's dollar gamma at S = 100
for s in (80.0, 100.0, 120.0):
    gs = g2(V, s)
    print(f"  S = {s:5.1f}   strip {gs:12.0f}   {k:6.0f} calls struck at 100 {k * g2(C, s):12.0f}")
    assert abs(gs / (2 * N * D / T) - 1) < 1e-3, "strip dollar gamma must not depend on S"
p("break-even daily move, percent", 100 * IMP / math.sqrt(DAYS), 4)
for mv in (0.0, 1.0, 2.0, 3.0):
    p(f"  day with a {mv:.0f}% move adds to the payoff", N / T * ((mv / 100) ** 2 - IMP ** 2 / DAYS), 2)
for lab, v in (("wrong: average the vols, 19% squared", D * N * (0.19 ** 2 - KVAR)),
               ("wrong: drop the realised half", D * N * (IMP ** 2 - KVAR)),
               ("wrong: 18% as the whole year's", D * N * (DONE ** 2 - KVAR)),
               ("wrong: no discount", N * (t / T * DONE ** 2 + tau / T * IMP ** 2 - KVAR)),
               ("wrong: forward vol from vols, percent", (100 * V2 * T2 - 100 * V1 * T1) / (T2 - T1))):
    p(lab, v, 2)
print("story: month, realised so far %, implied for rest %, mark $")
for mo, rv, iv in ((3, 16.0, 20.0), (6, 18.0, 20.0), (9, 19.0, 26.0), (12, 20.5, 20.0)):
    ta = (12 - mo) / 12; mk = mark(rv / 100, (iv / 100) ** 2, ta)   # squared-return sums: done plus quoted rest
    assert abs(mk - math.exp(-r * ta) * N * (((rv / 100) ** 2 * mo / 12 + (iv / 100) ** 2 * ta) / T - KVAR)) < 1e-6, "sums"
    print(f"  month {mo:2d}   {rv:5.1f}   {iv:5.1f}   {mk:12.2f}")
print("chart, vol for the rest %      14       16       18       20       22       24       26")
print("chart, payoff if realised $k" + "".join(f"{N * (acc + tau / T * (x / 100) ** 2 - KVAR) / 1000:9.2f}" for x in range(14, 27, 2)))
print("chart, mark if implied $k   " + "".join(f"{mark(DONE, (x / 100) ** 2) / 1000:9.2f}" for x in range(14, 27, 2)))
print("ALL CHECKS PASS")
