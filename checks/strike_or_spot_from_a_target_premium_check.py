# Strike or spot from a target premium -- the check behind the card.
# Standard library only.  Nothing imported knows the answer: the bell-curve
# area is a series written out here, the second price is Simpson's rule over
# the payoff, and both root finders (Newton, bisection) are loops written here.
from math import log, sqrt, exp, pi

S, K0, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
QUOTE = 9.227005508154                       # the house call, S = K = 100

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                    # 0.5 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    term, total, k = x, x, 0
    while abs(term) > 1e-17 * abs(total) + 1e-300:
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + phi(x) * total

def d12(s, k, sg, t, qq=q):
    d1 = (log(s / k) + (r - qq + 0.5 * sg * sg) * t) / (sg * sqrt(t))
    return d1, d1 - sg * sqrt(t)
def call(s, k, sg=sigma, t=T, qq=q):         # road 1: the closed form
    d1, d2 = d12(s, k, sg, t, qq)
    return s * exp(-qq * t) * N(d1) - k * exp(-r * t) * N(d2)
def put(s, k, sg=sigma, t=T):
    d1, d2 = d12(s, k, sg, t)
    return k * exp(-r * t) * N(-d2) - s * exp(-q * t) * N(-d1)

def by_integral(s, k, kind):                 # road 2: average the payoff over the bell curve
    m, v = (r - q - 0.5 * sigma * sigma) * T, sigma * sqrt(T)
    z0 = (log(k / s) - m) / v                # the draw at which the stock ends exactly at k
    a, b = (z0, 12.0) if kind == "call" else (-12.0, z0)
    n, h, tot = 2000, (b - a) / 2000, 0.0
    for i in range(n + 1):
        z = a + i * h
        pay = s * exp(m + v * z) - k if kind == "call" else k - s * exp(m + v * z)
        tot += (1 if i in (0, n) else 4 if i % 2 else 2) * max(pay, 0.0) * phi(z)
    return exp(-r * T) * tot * h / 3.0

def bisect(f, target, lo, hi, up):           # f increasing if up, else decreasing
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if (f(mid) < target) == up: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def bracket(f, target, up):                  # double and halve until the target is straddled
    lo = hi = 100.0
    while (f(hi) < target) == up: hi *= 2.0
    while (f(lo) < target) != up: lo /= 2.0
    return lo, hi

def newton(f, slope, target, x, steps=6):
    path = [x]
    for _ in range(steps):
        x = x - (f(x) - target) / slope(x)
        path.append(x)
    return path

target = 5.0
ceiling = S * exp(-q * T)                    # a call can never cost more than this
slope_k = lambda k: -exp(-r * T) * N(d12(S, k, sigma, T)[1])
slope_s = lambda s: exp(-q * T) * N(d12(s, K0, sigma, T)[0])
lo, hi = bracket(lambda k: call(S, k), target, False)
path = newton(lambda k: call(S, k), slope_k, target, 100.0)
Kc_newton = path[-1]
Kc_integral = bisect(lambda k: by_integral(S, k, "call"), target, lo, hi, False)
lo_p, hi_p = bracket(lambda k: put(S, k), target, True)
Kp_bisect = bisect(lambda k: put(S, k), target, lo_p, hi_p, True)
Kp_integral = bisect(lambda k: by_integral(S, k, "put"), target, lo_p, hi_p, True)
lo_s, hi_s = bracket(lambda s: call(s, K0), QUOTE, True)
S_newton = newton(lambda s: call(s, K0), slope_s, QUOTE, 120.0)[-1]
S_integral = bisect(lambda s: by_integral(s, K0, "call"), QUOTE, lo_s, hi_s, True)
S_for_5 = bisect(lambda s: call(s, K0), target, lo_s / 4, hi_s, True)
h = 1e-4
slope_fd = (call(S, Kc_newton + h) - call(S, Kc_newton - h)) / (2 * h)
d1, d2 = d12(S, Kc_newton, sigma, T)

rows = [
    ("e^-rT", exp(-r * T)), ("e^-qT", exp(-q * T)), ("ceiling S e^-qT", ceiling),
    ("put spot ceiling K e^-rT", K0 * exp(-r * T)),
    ("bracket low", lo), ("bracket high", hi), ("newton step 0", path[0]), ("  call there", call(S, path[0])),
    ("  gap to 5.00 there", call(S, path[0]) - target), ("  N(d2) there", N(d12(S, path[0], sigma, T)[1])),
    ("  slope there", slope_k(path[0])),
    ("newton step 1", path[1]), ("newton step 2", path[2]), ("newton step 3", path[3]),
    ("1 strike, Newton on formula", Kc_newton), ("2 strike, bisection on integral", Kc_integral),
    ("  ln(S/K) at that strike", log(S / Kc_newton)), ("  d1 at that strike", d1), ("  d2 at that strike", d2), ("  N(d1)", N(d1)), ("  N(d2)", N(d2)),
    ("  share half", S * exp(-q * T) * N(d1)), ("  cash half", Kc_newton * exp(-r * T) * N(d2)),
    ("  call repriced by integral", by_integral(S, Kc_newton, "call")),
    ("  slope by bump", slope_fd), ("  -e^-rT N(d2)", slope_k(Kc_newton)),
    ("put strike, bisection on formula", Kp_bisect), ("put strike, bisection on integral", Kp_integral),
    ("spot for 9.227, Newton from 120", S_newton), ("spot for 9.227, bisection on integral", S_integral),
    ("spot for 5.00 call, K = 100", S_for_5),
    ("wrong: sigma = 0, K = (S e^-qT - 5) e^rT", (ceiling - target) * exp(r * T)),
    ("wrong: stop after one Newton step", path[1]),
    ("wrong: forgot the 2% dividend", bisect(lambda k: call(S, k, qq=0.0), target, lo, 2 * hi, False)),
    ("wrong: put solved for the call quote", Kp_bisect),
    ("wrong: 99.00 target, solver ends at", bisect(lambda k: call(S, k), 99.0, 1e-9, 1000.0, False)),
    ("try: sigma = 0.40", bisect(lambda k: call(S, k, 0.40), target, lo, 2 * hi, False)),
    ("try: T = 0.25", bisect(lambda k: call(S, k, sigma, 0.25), target, 1.0, hi, False)),
    ("try: target 1.00", bisect(lambda k: call(S, k), 1.0, lo, 4 * hi, False)),
    ("try: expiry today, K = S - 5", S - target),
]
for sg in (0.10, 0.30):                      # one quote, many (spot, vol) pairs
    s_pair = bisect(lambda s: call(s, K0, sg), QUOTE, 50.0, 200.0, True)
    rows.append((f"same 9.227 quote: vol {sg:.2f} needs spot", s_pair))
for name, v in rows:
    print(f"{name:<42} {v:>12.6f}")
print("chart, strike        " + " ".join(f"{k:7.0f}" for k in range(80, 141, 10)))
print("chart, call premium  " + " ".join(f"{call(S, k):7.2f}" for k in range(80, 141, 10)))
print("chart, put premium   " + " ".join(f"{put(S, k):7.2f}" for k in range(80, 141, 10)))
print("chart, spot          " + " ".join(f"{s:7.0f}" for s in range(80, 121, 10)))
print("chart, call at K=100 " + " ".join(f"{call(s, K0):7.2f}" for s in range(80, 121, 10)))

assert abs(call(S, K0) - QUOTE) < 1e-9,               "formula must reproduce the house call"
assert abs(Kc_newton - Kc_integral) < 1e-6,           "two roads to the strike"
assert abs(Kp_bisect - Kp_integral) < 1e-6,           "two roads to the put strike"
assert abs(S_newton - 100.0) < 1e-8 and abs(S_integral - 100.0) < 1e-6, "9.227 must return S = 100"
assert abs(slope_fd - slope_k(Kc_newton)) < 1e-6,    "strike slope: bump vs -e^-rT N(d2)"
assert all(a < b <= Kc_newton + 1e-12 for a, b in zip(path, path[1:4])), "Newton climbs, never overshoots"
assert all(call(S, k) > call(S, k + 10) and put(S, k) < put(S, k + 10) for k in range(40, 300, 10)), "call falls, put rises in strike"
assert all(call(s, K0) < call(s + 10, K0) for s in range(40, 300, 10)), "call rises in spot"
print("ALL CHECKS PASS")
