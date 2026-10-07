# Implied volatility by Newton and bisection -- the check behind the card.
# Standard library only.  The normal CDF is a series written out below and the
# root finders are plain loops: nothing imported already knows the answer.
from math import exp, log, sqrt, pi

S, R, Q = 100.0, 0.05, 0.02                       # Acme spot, cash rate, dividend yield
WEEK = 1.0 / 52.0

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def N(x):                                         # 0.5 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x < -10.0: return 0.0
    if x > 10.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + total * phi(x)

def d1(K, T, s): return (log(S / K) + (R - Q + 0.5 * s * s) * T) / (s * sqrt(T))
def call(K, T, s):
    a = d1(K, T, s); return S * exp(-Q * T) * N(a) - K * exp(-R * T) * N(a - s * sqrt(T))
def put(K, T, s):
    a = d1(K, T, s); return K * exp(-R * T) * N(s * sqrt(T) - a) - S * exp(-Q * T) * N(-a)
def vega(K, T, s): return S * exp(-Q * T) * phi(d1(K, T, s)) * sqrt(T)     # dollars per 1.00 of vol
def s_peak(K, T): return sqrt(2.0 * abs(log(S * exp((R - Q) * T) / K)) / T)  # where vega peaks

def newton(price, K, T, p, x, trace=None):        # road 1: the slope, unguarded
    for trip in range(1, 100):
        f, v = price(K, T, x) - p, vega(K, T, x)
        if trace is not None: trace.append((trip, x, f, v))
        if abs(f) < 1e-12: return x, trip
        if v == 0.0: return float("inf"), trip
        x = x - f / v
        if not (0.0 < x < 1e3): return x, trip    # left the world of volatilities
    return x, 100

def bisect(price, K, T, p, lo=0.01, hi=5.0):      # road 2: no slope, only signs
    halvings = 0
    while hi - lo > 1e-12:
        m = 0.5 * (lo + hi); halvings += 1
        if price(K, T, m) > p: hi = m
        else: lo = m
    return 0.5 * (lo + hi), halvings

def guarded(price, K, T, p, x, lo=0.01, hi=5.0):  # Newton inside a bracket, bisection as the net
    falls = 0
    for trips in range(1, 200):
        f = price(K, T, x) - p
        if abs(f) < 1e-12 or hi - lo < 1e-14: break
        if f > 0: hi = x
        else: lo = x
        v = vega(K, T, x)
        nxt = x - f / v if v > 0.0 else lo
        if not (lo < nxt < hi): nxt = 0.5 * (lo + hi); falls += 1
        x = nxt
    return x, trips, falls

def strike_for_delta(T, target):                  # the strike whose call delta is target, at 0.20
    lo, hi = 50.0, 200.0
    while hi - lo > 1e-12:
        m = 0.5 * (lo + hi)
        if exp(-Q * T) * N(d1(m, T, 0.20)) > target: lo = m
        else: hi = m
    return 0.5 * (lo + hi)

def row(label, v): print(f"{label:<46}{v:>22d}" if isinstance(v, int) else f"{label:<46}{v:>22.12f}")

# ---- the house quote, read backwards ----
C, P = call(100.0, 1.0, 0.20), put(100.0, 1.0, 0.20)
row("house call at 0.20", C)
row("house put at 0.20", P)
row("call floor, S e^-qT - K e^-rT", S * exp(-Q) - 100.0 * exp(-R))
row("call ceiling, S e^-qT", S * exp(-Q))
v0, h = vega(100.0, 1.0, 0.20), 1e-5
v_bump = (call(100.0, 1.0, 0.20 + h) - call(100.0, 1.0, 0.20 - h)) / (2 * h)
row("vega at 0.20, per 1.00 of vol", v0)
row("vega by bumping the price", v_bump)
row("sigma_c, where vega peaks", s_peak(100.0, 1.0))
trace = []
x_n, trips_n = newton(call, 100.0, 1.0, C, 0.50, trace)
for trip, x, f, v in trace:
    print(f"newton from 0.50, trip {trip}: sigma {x:.12f}  residual {f:+.12f}  vega {v:.6f}")
row("newton from sigma_c, trips", newton(call, 100.0, 1.0, C, s_peak(100.0, 1.0))[1])
x_b, halv_b = bisect(call, 100.0, 1.0, C)
row("bisection on 0.01 to 5.00, answer", x_b)
row("bisection on 0.01 to 5.00, halvings", halv_b)
x_p = newton(put, 100.0, 1.0, P, 0.50)[0]
row("put 6.330080627550 by Newton from 0.50", x_p)

# ---- the same solver on one-week options ----
cases = [("1y atm", 100.0, 1.0), ("1w atm", 100.0, WEEK),
         ("1w 20d", strike_for_delta(WEEK, 0.20), WEEK), ("1w 5d", strike_for_delta(WEEK, 0.05), WEEK)]
print("case    strike      sigma_c   newton from 0.05 ends at  trips  from sigma_c  guarded, falls  bisection")
results = []
for name, K, T in cases:
    p = call(K, T, 0.20)
    x_lo, t_lo = newton(call, K, T, p, 0.05)
    x_c, t_c = newton(call, K, T, p, s_peak(K, T))
    x_g, t_g, f_g = guarded(call, K, T, p, 0.05)
    x_bi = bisect(call, K, T, p)[0]
    results.append((x_lo, x_c, x_g, x_bi))
    print(f"{name:<7}{K:>11.6f}{s_peak(K, T):>9.4f}{x_lo:>27.6f}{t_lo:>7d}{t_c:>14d}{t_g:>9d}{f_g:>7d}{x_bi:>11.6f}")

for name, K, T in cases[2:]:                      # where the low start goes
    tr = []; newton(call, K, T, call(K, T, 0.20), 0.05, tr)
    for trip, x, f, v in tr: print(f"{name} from 0.05, trip {trip}: sigma {x:.6f}  residual {f:+.6f}  vega {v:.12f}")

# ---- a 0.05 bid-ask width, read as a volatility width ----
print("case    mid price   vega per vol point   width / vega, points   ask vol - bid vol, points")
widths = []
for name, K, T in cases:
    p = call(K, T, 0.20)
    lin = 0.05 / vega(K, T, 0.20) * 100.0
    exact = (bisect(call, K, T, p + 0.025)[0] - bisect(call, K, T, p - 0.025)[0]) * 100.0
    widths.append((lin, exact))
    print(f"{name:<7}{p:>10.6f}{vega(K, T, 0.20) / 100.0:>21.6f}{lin:>23.4f}{exact:>28.4f}")

# ---- what breaks, and the chart ----
row("bisection on a 2.80 quote, below the floor", bisect(call, 100.0, 1.0, 2.80)[0])
row("0.05 / vega per 1.00, misread as points", 0.05 / v0)
strikes = [90.0 + 2.5 * i for i in range(9)]
print("chart, strike              " + " ".join(f"{k:6.1f}" for k in strikes))
for label, T in (("chart, cents per point, 1y ", 1.0), ("chart, cents per point, 1w ", WEEK)):
    print(label + " " + " ".join(f"{vega(k, T, 0.20):6.2f}" for k in strikes))

slide = []
newton(call, cases[3][1], WEEK, call(cases[3][1], WEEK, 0.20), s_peak(cases[3][1], WEEK), slide)
assert abs(C - 9.227005508154) < 1e-9                                     # the pilot's call
assert abs(P - 6.330080627550) < 1e-9                                     # the pilot's put
assert abs(v_bump - v0) < 1e-6                                            # slope two ways
assert abs(x_n - 0.20) < 1e-12                                            # Newton recovers 0.20
assert abs(x_b - 0.20) < 1e-11                                            # bisection recovers 0.20
assert abs(x_p - 0.20) < 1e-12                                            # the put gives the same vol
assert all(abs(x - 0.20) < 1e-10 for r in results for x in r[1:])        # every safe road lands
assert not any(0.0 < results[i][0] < 1e3 for i in (2, 3))                 # low start dies on 20d and 5d
assert all(vega(k, T, s_peak(k, T)) > max(vega(k, T, s_peak(k, T) * f) for f in (0.99, 1.01)) for _, k, T in cases)  # vega peaks at sigma_c
assert all(a[1] >= b[1] - 1e-15 for a, b in zip(slide, slide[1:]))       # from sigma_c: never overshoots
assert abs(widths[0][0] - widths[0][1]) < 0.001                           # linear width holds at the money
assert widths[3][1] > 3.0                                                 # several points on the 5d
print("ALL CHECKS PASS")
