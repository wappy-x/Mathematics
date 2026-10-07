# Strike from delta -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is the erf Taylor series
# written out, the quantile is Newton's method on it, the price is Simpson's rule.
from math import log, sqrt, exp, pi, factorial

def N(x):                                     # bell-curve area left of x (series good for |x| <= 5)
    assert abs(x) <= 5.0, "series used outside its accurate range"
    y = x / sqrt(2.0)
    s = sum((-1) ** n * y ** (2 * n + 1) / (factorial(n) * (2 * n + 1)) for n in range(90))
    return 0.5 + s / sqrt(pi)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def N_inv(p):                                 # Newton on N; None when p is outside (0, 1)
    if not 0.0 < p < 1.0: return None
    x = 0.0
    for _ in range(60): x -= (N(x) - p) / phi(x)
    return x

S, r, q, sigma, T = 100.0, 0.05, 0.02, 0.20, 1.0
vt = sigma * sqrt(T)                          # one wiggle unit
mu = (r - q + 0.5 * sigma * sigma) * T        # the drift term inside d1

def d1(K): return (log(S / K) + mu) / vt
def delta(K, kind):                           # the forward map: strike in, delta out
    return exp(-q * T) * N(d1(K)) if kind == "call" else -exp(-q * T) * N(-d1(K))

def strike_closed(target, kind):              # Road 1: invert N, then undo d1
    z = N_inv(target * exp(q * T) if kind == "call" else -target * exp(q * T))
    if z is None: return None
    D1 = z if kind == "call" else -z
    return S * exp(-D1 * vt + mu)

def strike_bisect(target, kind):              # Road 2: search strikes; delta falls as K rises
    lo, hi = 50.0, 200.0
    assert delta(lo, kind) > target > delta(hi, kind), "bracket must straddle the target"
    for _ in range(100):
        mid = sqrt(lo * hi)
        if delta(mid, kind) > target: lo = mid
        else: hi = mid
    return sqrt(lo * hi)

def price(s, K, kind, n=4000):                # Road 3: premium by Simpson over the bell curve
    m = (r - q - 0.5 * sigma * sigma) * T
    zs = (log(K / s) - m) / vt                # where the option starts to pay
    a, b = (zs, zs + 12.0) if kind == "call" else (zs - 12.0, zs)
    sign = 1.0 if kind == "call" else -1.0
    f = lambda z: sign * (s * exp(m + vt * z) - K) * phi(z)
    h = (b - a) / n
    tot = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return exp(-r * T) * tot * h / 3.0

def bump_delta(K, kind, h=0.01):
    return (price(S + h, K, kind) - price(S - h, K, kind)) / (2 * h)

Kc1, Kc2 = strike_closed(0.25, "call"), strike_bisect(0.25, "call")
Kp1, Kp2 = strike_closed(-0.25, "put"), strike_bisect(-0.25, "put")
dc_bump, dp_bump = bump_delta(Kc1, "call"), bump_delta(Kp1, "put")
house = price(S, 100.0, "call")
# ---- what breaks ----
no_q = S * exp(-N_inv(0.25) * vt + mu)                            # solved N(d1) = 0.25
use_d2 = S * exp(-N_inv(0.25 * exp(q * T)) * vt + mu - vt * vt)   # solved e^-qT N(d2) = 0.25
as_75c = strike_closed(0.75, "call")                              # 25-delta put read as 75-delta call
K_dn = S * exp(mu)                                                # d1 = 0: call delta = -put delta
rows = [
    ("ceiling e^-qT", exp(-q * T)), ("target N(d1) = 0.25 e^qT", 0.25 * exp(q * T)),
    ("d1 at the 25-delta call", N_inv(0.25 * exp(q * T))), ("drift in d1, (r-q+sigma^2/2)T", mu),
    ("ln(K/S), 25-delta call", log(strike_closed(0.25, "call") / S)),
    ("ln(K/S), 25-delta put", log(strike_closed(-0.25, "put") / S)),
    ("1 call strike, closed form", Kc1), ("2 call strike, bisection", Kc2),
    ("3 call delta by bumping S", dc_bump),
    ("1 put strike, closed form", Kp1), ("2 put strike, bisection", Kp2),
    ("3 put delta by bumping S", dp_bump),
    ("house call at K = 100 by Simpson", house), ("call delta at K = 100", delta(100.0, "call")),
    ("delta 0.99 needs N(d1) =", 0.99 * exp(q * T)),
    ("delta-neutral strike S e^mu", K_dn),
    ("  call delta there", delta(K_dn, "call")), ("  put delta there", delta(K_dn, "put")),
    ("10-delta call strike", strike_closed(0.10, "call")),
    ("10-delta put strike", strike_closed(-0.10, "put")),
    ("call delta at the 25-delta put strike", delta(Kp1, "call")),
    ("wrong: forgot e^qT", no_q), ("wrong: d2 for d1", use_d2),
    ("wrong: 25-delta put as 75-delta call", as_75c),
]
for name, v in rows: print(f"{name:<38} {v:>14.6f}")
print(f"{'  strike for delta 0.99':<38} {'none' if strike_closed(0.99, 'call') is None else 'found':>14}")
# ---- try changing ----
print()
for label, sg, tt, qq in (("try: sigma 0.30", 0.30, 1.0, q), ("try: T 0.25", sigma, 0.25, q), ("try: q 0", sigma, 1.0, 0.0)):
    v2, m2 = sg * sqrt(tt), (r - qq + 0.5 * sg * sg) * tt
    kc = S * exp(-N_inv(0.25 * exp(qq * tt)) * v2 + m2)
    kp = S * exp(N_inv(0.25 * exp(qq * tt)) * v2 + m2)
    print(f"{label:<18} 25d call {kc:9.4f}   25d put {kp:9.4f}   ceiling {exp(-qq * tt):.4f}")
# ---- chart points: delta against strike ----
print()
ks = [70.0 + 10.0 * i for i in range(9)]
print(f"{'chart, strike':<20}" + "".join(f"{k:7.0f}" for k in ks))
print(f"{'chart, call delta':<20}" + "".join(f"{delta(k, 'call'):7.2f}" for k in ks))
print(f"{'chart, minus put':<20}" + "".join(f"{-delta(k, 'put'):7.2f}" for k in ks))
print(f"{'chart, target':<20}" + "".join(f"{0.25:7.2f}" for k in ks))

assert abs(Kc1 - Kc2) < 1e-6, "call: closed form vs bisection"
assert abs(Kp1 - Kp2) < 1e-6, "put: closed form vs bisection"
assert abs(dc_bump - 0.25) < 1e-5, "bumped call delta at the call strike"
assert abs(dp_bump + 0.25) < 1e-5, "bumped put delta at the put strike"
assert abs(house - 9.227005508154) < 1e-8, "Simpson premium vs the house call"
assert strike_closed(0.99, "call") is None, "0.99 is above the ceiling: no strike"
assert abs(round(Kc1, 2) - 119.93) < 1e-9, "house 25-delta call strike"
print("ALL CHECKS PASS")
