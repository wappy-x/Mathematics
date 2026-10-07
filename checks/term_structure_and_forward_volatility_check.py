# Term structure and forward volatility -- the check behind the card.  Standard library only,
# and nothing imported knows an option price: the bell-curve area comes from math.erf, the
# integral is Simpson's rule, the root finder is bisection and the random numbers come from a
# SplitMix64 generator, all written out below.
from math import log, sqrt, exp, erf, pi, cos
S, K, R, Q = 100.0, 100.0, 0.05, 0.02         # Acme spot, strike, riskless rate, dividend yield
T1, T2 = 0.5, 1.0                              # near and far expiry, in years

def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))      # bell-curve area left of x
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)    # bell-curve height at x
def call(s, k, t, sig):                        # Black-Scholes call at one flat volatility
    if sig <= 0.0: return max(s * exp(-Q * t) - k * exp(-R * t), 0.0)
    d1 = (log(s / k) + (R - Q + 0.5 * sig * sig) * t) / (sig * sqrt(t))
    return s * exp(-Q * t) * N(d1) - k * exp(-R * t) * N(d1 - sig * sqrt(t))
def simpson(f, a, b, n):
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def bisect(f, lo, hi, steps=60):               # needs f(lo) < 0 < f(hi); halves the bracket
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0.0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def fwd_vol(s1, t1, s2, t2):                   # road 1: the formula; None when there is no answer
    w1, w2 = s1 * s1 * t1, s2 * s2 * t2
    return sqrt((w2 - w1) / (t2 - t1)) if w2 >= w1 else None
def two_stage(k, s1, sf):                      # road 2: price the far call in two stages
    # At T1 the far call is a (T2 - T1)-year call at the forward vol sf.  Average that over
    # where Acme lands at T1 under s1, then discount.  No variances are added anywhere.
    def f(z):
        s_mid = S * exp((R - Q - 0.5 * s1 * s1) * T1 + s1 * sqrt(T1) * z)
        return call(s_mid, k, T2 - T1, sf) * phi(z)
    return exp(-R * T1) * simpson(f, -10.0, 10.0, 800)
def implied(price, k, t): return bisect(lambda v: call(S, k, t, v) - price, 1e-9, 2.0)

MASK, state = (1 << 64) - 1, 20260919
def u01():                                     # SplitMix64, mapped into (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(u01())) * cos(2.0 * pi * u01())   # Box-Muller

def row(label, v): print(f"{label:<46} {v:>12.6f}")
s1, s2 = 0.18, 0.20
w1, w2 = s1 * s1 * T1, s2 * s2 * T2
sf = fwd_vol(s1, T1, s2, T2)
c_far = call(S, K, T2, s2)
sf_road2 = bisect(lambda v: two_stage(K, s1, v) - c_far, 0.0, 1.0)
print("house sheet: 18% at half a year, 20% at one year")
row("total variance w1 = 0.18^2 x 0.5", w1); row("total variance w2 = 0.20^2 x 1", w2)
row("variance added in between, w2 - w1", w2 - w1)
row("per year in between, (w2 - w1)/(T2 - T1)", (w2 - w1) / (T2 - T1))
row("1 forward vol, formula", sf); row("2 forward vol, two-stage price + bisection", sf_road2)
row("  one-year call at 20%", c_far); row("  half-year call at 18%", call(S, K, T1, s1))
iv = {k: implied(two_stage(k, s1, sf), k, T2) for k in (90.0, 100.0, 110.0)}
for k in iv: row(f"3 implied vol of the two-stage price, K {k:.0f}", iv[k])
paths, weeks = 10000, 26
dt = T1 / weeks
a_s, b_s = [], []
for _ in range(paths):
    a_s.append(sum(s1 * sqrt(dt) * gauss() for _ in range(weeks)))
    b_s.append(sum(sf * sqrt(dt) * gauss() for _ in range(weeks)))
def var(xs): m = sum(xs) / len(xs); return sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
v_a, v_b = var(a_s), var(b_s)
v_ab = var([a + b for a, b in zip(a_s, b_s)])
print("4 simulated log moves, 10000 paths x 52 weeks")
for lab, v in (("first half", v_a), ("second half", v_b), ("whole year", v_ab), ("twice the covariance", v_ab - v_a - v_b)):
    print(f"  {'variance, ' + lab if lab[0] != 't' else lab:<44} {v:>12.4f}")
F1, F2, cover = S * exp((R - Q) * T1), S * exp((R - Q) * T2), exp(-Q * (T2 - T1))
k_match = K * F2 / F1
row("forward F(T1)", F1); row("forward F(T2)", F2)
row("matched far strike, K x F(T2)/F(T1)", k_match); row("cover weight e^-q(T2-T1)", cover)
row("calendar cushion, far call - cover x near", call(S, k_match, T2, s2) - cover * call(S, K, T1, s1))
row("wrong: vols averaged in a straight line", (s2 * T2 - s1 * T1) / (T2 - T1))
row("wrong: divided by T2, not T2 - T1", sqrt((w2 - w1) / T2))
row("wrong: squared vols subtracted, no T weights", sqrt((s2 * s2 - s1 * s1) / (T2 - T1)))
b1, b2 = 0.21, 0.14
bw1, bw2 = b1 * b1 * T1, b2 * b2 * T2
print("broken sheet: 21% at half a year, 14% at one year")
row("total variance w1 = 0.21^2 x 0.5", bw1); row("total variance w2 = 0.14^2 x 1", bw2)
row("per year in between, (w2 - w1)/(T2 - T1)", (bw2 - bw1) / (T2 - T1))
print(f"  {'1 forward vol, formula':<44} {'none' if fwd_vol(b1, T1, b2, T2) is None else 'found':>12}")
floor = two_stage(K, b1, 0.0)
row("2 cheapest two-stage far call, forward vol 0", floor); row("  quoted one-year call at 14%", call(S, K, T2, b2))
near_b, far_b = call(S, K, T1, b1), call(S, k_match, T2, b2)
row("  half-year call at 21%, K 100", near_b); row("  one-year call at 14%, matched strike", far_b)
row("  cash collected, cover x near - far", cover * near_b - far_b)
print("chart: months to expiry, implied vol %, instantaneous vol %")
months = list(range(1, 13))
imp = [100 * sqrt((min(m / 12, T1) * s1 * s1 + max(m / 12 - T1, 0.0) * sf * sf) / (m / 12)) for m in months]
print(" ".join(f"{m:>6d}" for m in months)); print(" ".join(f"{v:>6.2f}" for v in imp))
print(" ".join(f"{100 * (s1 if m <= 6 else sf):>6.2f}" for m in months))
for lab, t2v in (("try: 18% flat", 0.18), ("try: 25% at one year", 0.25), ("try: 12.7279% at one year", 0.127279220614)):
    row(lab + ", forward vol", fwd_vol(s1, T1, t2v, T2))
row("falling vols: 25% then 20%, w1", 0.25 * 0.25 * T1); row("  forward vol", fwd_vol(0.25, T1, 0.20, T2))
assert abs(sf_road2 - sf) < 1e-8, "two-stage bisection must land on the formula"
assert max(abs(v - s2) for v in iv.values()) < 1e-7, "a deterministic vol path leaves no smile"
assert abs(v_ab - w2) < 0.002, "simulated whole-year variance vs 0.20^2 x 1"
assert abs(v_b - (w2 - w1)) < 0.0015, "simulated second-half variance vs w2 - w1"
assert floor > call(S, K, T2, b2), "broken sheet: quoted far call under the cheapest reachable"
assert cover * near_b - far_b > 0.0, "broken sheet: the calendar collects cash"
assert all(call(x, k_match, T2 - T1, b2) >= cover * max(x - K, 0.0) - 1e-9 for x in range(50, 301, 5)), "at T1 the long far call covers the short near calls"
print("ALL CHECKS PASS")
