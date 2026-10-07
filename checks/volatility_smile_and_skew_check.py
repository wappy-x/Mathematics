# Volatility smile and skew -- the check behind the card.  Standard library only.
# A crash-mixture market prices the house strip 80..120; each price is run back through
# Black-Scholes to one volatility per strike.  Every number quoted on the card is printed.
from math import log, sqrt, exp, cos, pi

def N(x):                        # normal CDF from its own series: erf(y) = 2/sqrt(pi) e^-y^2 sum 2^n y^(2n+1)/(2n+1)!!
    if x > 9.0: return 1.0
    if x < -9.0: return 0.0
    y = abs(x) / sqrt(2.0); term = y; s = y; n = 0
    while term > 1e-17 * s:
        n += 1; term *= 2.0 * y * y / (2 * n + 1); s += term
    e = 2.0 / sqrt(pi) * exp(-y * y) * s
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

S, r, q, T = 100.0, 0.05, 0.02, 1.0
F, D = S * exp((r - q) * T), exp(-r * T)            # forward and discount factor
def legs(p, c, sc, sn):                             # crash leg (weight, forward, vol) and calm leg; average forward = F
    return [(p, c * F, sc), (1.0 - p, (F - p * c * F) / (1.0 - p), sn)]
MIX = legs(0.12, 0.70, 0.40, 0.15)                   # 12% chance of a crash to 70% of the forward

def b76(f, K, s, call=True):                        # one lognormal centred on forward f, discounted
    v = s * sqrt(T); d1 = (log(f / K) + 0.5 * v * v) / v; d2 = d1 - v
    return D * (f * N(d1) - K * N(d2)) if call else D * (K * N(-d2) - f * N(-d1))
def mix(K, call=True, m=MIX): return sum(w * b76(f, K, s, call) for w, f, s in m)
def bs(K, s, call=True, qq=q): return b76(S * exp((r - qq) * T), K, s, call)   # Black-Scholes on spot

def iv_bisect(C, K, lo=1e-6, hi=5.0, qq=q):        # road A to the vol: bisection on the call
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if bs(K, mid, True, qq) > C: hi = mid
        else: lo = mid
        if hi - lo < 1e-15: break
    return 0.5 * (lo + hi)
def iv_newton(P, K):                                # road B: Newton on the put, slope = vega
    s = 0.25
    for _ in range(50):
        d1 = (log(F / K) + 0.5 * s * s * T) / (s * sqrt(T))
        step = (bs(K, s, False) - P) / (D * F * phi(d1) * sqrt(T))
        s -= step
        if abs(step) < 1e-15: break
    return s

def density(x, m=MIX):                              # mixture density of log S_T
    return sum(w * phi((x - log(f) + 0.5 * s * s * T) / (s * sqrt(T))) / (s * sqrt(T)) for w, f, s in m)
def simpson(g, a, b, n=4000):                      # Simpson's rule, written out
    h = (b - a) / n
    return h / 3.0 * (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n)))
def call_integral(K):                               # road 2 to the price: payoff x density, no Black formula
    return D * simpson(lambda x: (exp(x) - K) * density(x), log(K), log(F) + 3.0)

state = [20260919]
def uniform():                                      # splitmix64, top 53 bits -> (0,1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
STRIP = [80.0 + 5.0 * i for i in range(9)]
def monte_carlo(paths=200000):                      # road 3: pick a leg, draw a price, average the payoffs
    tot = [0.0] * 9
    for _ in range(paths):
        w, f, s = MIX[0] if uniform() < MIX[0][0] else MIX[1]
        z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
        st = f * exp(-0.5 * s * s * T + s * sqrt(T) * z)
        for j, K in enumerate(STRIP): tot[j] += max(st - K, 0.0)
    return [D * t / paths for t in tot]

mc = monte_carlo()
print(f"forward F = S e^(r-q)T, e^-rT      {F:.6f} {D:.4f}")
for lab, (w, f, s) in zip(("crash", "calm "), MIX):
    print(f"{lab} leg: weight, forward/F, forward, vol  {w:.2f} {f / F:.4f} {f:.4f} {s:.2f}")
print(f"weights x forwards                 {sum(w * f for w, f, s in MIX):.6f}")
mean = call_integral(1e-9) / D
assert abs(mean - F) < 1e-6, "the density integrates to the market's forward"
print(f"mean of S_T by integral            {mean:.6f}")
print("   K       k   call:formula integral  MC    iv call  iv put  crash share of put")
ivs = []
for j, K in enumerate(STRIP):
    C, Ci, P = mix(K), call_integral(K), mix(K, False)
    a, b = iv_bisect(C, K), iv_newton(P, K)
    ivs.append(a)
    assert abs(Ci - C) < 1e-7, "integral road must land on the weighted formula"
    assert abs(mc[j] - C) < 0.1, "Monte Carlo within ten cents"
    assert abs(a - b) < 1e-9, "bisection on the call and Newton on the put find one vol"
    share = MIX[0][0] * b76(MIX[0][1], K, MIX[0][2], False) / P
    print(f"{K:5.0f} {log(K / F):+7.4f} {C:10.4f} {Ci:9.4f} {mc[j]:7.2f} {100 * a:8.2f} {100 * b:7.2f} {100 * share:9.1f}%")
flat = [iv_bisect(bs(K, 0.20), K) for K in (80.0, 100.0, 120.0)]
assert max(abs(v - 0.20) for v in flat) < 1e-10, "a flat 20% market must invert to 20% everywhere"
assert all(ivs[i] > ivs[i + 1] for i in range(8)), "the crash market must skew down across the strip"
print(f"flat 20% market inverted at 80/100/120   {100 * flat[0]:.2f} {100 * flat[1]:.2f} {100 * flat[2]:.2f}")
skew = (ivs[6] - ivs[2]) / log(110.0 / 90.0)
iv_k = lambda k: iv_bisect(mix(F * exp(k)), F * exp(k))
print(f"skew, 90 to 110, vol per unit k      {skew:.4f}")
print(f"skew at the money, k = -0.01 to 0.01 {(iv_k(0.01) - iv_k(-0.01)) / 0.02:.4f}")
print(f"iv at the forward, k = 0             {100 * iv_k(0.0):.2f}")
# the worked example: the 80 put, leg by leg, then the vol that reproduces it
pc, pn = b76(MIX[0][1], 80.0, 0.40, False), b76(MIX[1][1], 80.0, 0.15, False)
print(f"80 put: crash leg, calm leg          {pc:.4f} {pn:.4f}")
print(f"80 put: mixture, flat 20%            {MIX[0][0] * pc + MIX[1][0] * pn:.4f} {bs(80.0, 0.20, False):.4f}")
lo, hi, P80 = 0.0, 0.5, mix(80.0, False)
for i in range(6):
    mid = 0.5 * (lo + hi); v = bs(80.0, mid, False)
    print(f"  bisection try {mid:.6f} put {v:.4f} {'too dear' if v > P80 else 'too cheap'}")
    lo, hi = (lo, mid) if v > P80 else (mid, hi)
# why: tails and moments of the market's density against one lognormal at 20%
tail = lambda K, m: sum(w * N(-(log(f / K) - 0.5 * s * s * T) / (s * sqrt(T))) for w, f, s in m)
LN = [(1.0, F, 0.20)]
assert abs(simpson(density, -20.0, log(60.0)) - tail(60.0, MIX)) < 1e-9, "tail formula = area under the density"
print(f"P(S_T < 60): mixture, lognormal 20%  {tail(60.0, MIX):.4f} {tail(60.0, LN):.4f}")
print(f"P(S_T > 130): mixture, lognormal 20% {1 - tail(130.0, MIX):.4f} {1 - tail(130.0, LN):.4f}")
mom = lambda n: sum(w * f ** n * exp(0.5 * n * (n - 1) * s * s * T) for w, f, s in MIX)
sstar = sqrt(log(mom(2) / F ** 2) / T)
for n in (2, 3): assert abs(simpson(lambda x: exp(n * x) * density(x), -20.0, log(F) + 4.0) / mom(n) - 1) < 1e-9, "moment formula = integral"
assert mom(3) < F ** 3 * exp(3 * sstar ** 2 * T) - 1000, "no lognormal matching the second moment matches the third"
print(f"vol matching E[S_T^2]; E[S_T^3] mixture vs that lognormal  {sstar:.4f} {mom(3):.1f} {F ** 3 * exp(3 * sstar ** 2 * T):.1f}")
# what breaks
bad_q = [iv_bisect(mix(K), K, qq=0.0) for K in (80.0, 100.0, 120.0)]
print(f"wrong: forward with q forgotten     {S * exp(r * T):.4f}")
print(f"wrong: inverter forgets q, 80/100/120    {100 * bad_q[0]:.2f} {100 * bad_q[1]:.2f} {100 * bad_q[2]:.2f}")
BAD = [(0.12, 0.70 * F, 0.40), (0.88, F, 0.15)]
print(f"wrong: calm leg left at F: call iv, put iv at 100  {100 * iv_bisect(mix(100.0, True, BAD), 100.0):.2f} {100 * iv_newton(mix(100.0, False, BAD), 100.0):.2f}")
print(f"wrong: bracket 0.01 to 0.25 at 80        {100 * iv_bisect(mix(80.0), 80.0, 0.01, 0.25):.2f}")
# try changing
for lab, m in (("no crash leg", legs(0.0, 0.70, 0.40, 0.15)), ("crash to 50%", legs(0.12, 0.50, 0.40, 0.15))):
    print(f"try: {lab}, iv 80/100/120      " + " ".join(f"{100 * iv_bisect(mix(K, True, m), K):.2f}" for K in (80.0, 100.0, 120.0)))
EQ = legs(0.12, 1.0, 0.40, 0.15)
ev = [iv_bisect(mix(F * exp(k), True, EQ), F * exp(k)) for k in (-0.2, 0.2)]
assert abs(ev[0] - ev[1]) < 1e-9, "equal centres give an even smile in k"
print(f"try: equal centres, iv at k = -0.2, +0.2  {100 * ev[0]:.4f} {100 * ev[1]:.4f}")
# chart points: the market's density and one lognormal at 20%, percent per $1 of S_T
grid = [40.0 + 10.0 * i for i in range(13)]
print("chart, S_T          " + " ".join(f"{x:5.0f}" for x in grid))
print("chart, mixture      " + " ".join(f"{100 * density(log(x)) / x:5.2f}" for x in grid))
print("chart, lognormal 20 " + " ".join(f"{100 * density(log(x), LN) / x:5.2f}" for x in grid))
print("ALL CHECKS PASS")
