# Charm -- the check behind the card.  Python standard library only.
# Every number on the card is printed here.  The bell-curve area N is a power
# series written out below (no erf); the integrals are Simpson's rule, a loop.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def N(x):                                                  # bell-curve area left of x
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term = total = x; k = 1
    while abs(term) > 1e-18 * abs(total):                  # x + x^3/3 + x^5/15 + ...
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

def dd(S, K, r, q, s, T):
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T)); return d1, d1 - s * sqrt(T)
def call(S, K, r, q, s, T):
    d1, d2 = dd(S, K, r, q, s, T); return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def delta(S, K, r, q, s, T): return exp(-q * T) * N(dd(S, K, r, q, s, T)[0])
def put_delta(S, K, r, q, s, T): return -exp(-q * T) * N(-dd(S, K, r, q, s, T)[0])
def theta(S, K, r, q, s, T):                               # the theta card's formula, per year
    d1, d2 = dd(S, K, r, q, s, T)
    return (-S * exp(-q * T) * phi(d1) * s / (2 * sqrt(T)) - r * K * exp(-r * T) * N(d2)
            + q * S * exp(-q * T) * N(d1))
def charm(S, K, r, q, s, T):                               # Road 1: the formula, per year
    d1, d2 = dd(S, K, r, q, s, T)
    slide = (2 * (r - q) * T - d2 * s * sqrt(T)) / (2 * T * s * sqrt(T))
    return q * exp(-q * T) * N(d1) - exp(-q * T) * phi(d1) * slide
def put_charm(S, K, r, q, s, T): return charm(S, K, r, q, s, T) - q * exp(-q * T)

def delta_integral(S, K, r, q, s, T):
    # Road 5: delta as an average: e^-rT E[(S_T / S) when S_T > K], by Simpson.  No N, no d1.
    lo = (log(K / S) - (r - q - 0.5 * s * s) * T) / (s * sqrt(T))   # where S_T crosses K
    f = lambda z: exp((r - q - 0.5 * s * s) * T + s * sqrt(T) * z) * phi(z)
    return exp(-r * T) * simpson(f, lo, 12.0, 4000)

S, K, r, q, s, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1, d2 = dd(S, K, r, q, s, T)
D, ch, chp = delta(S, K, r, q, s, T), charm(S, K, r, q, s, T), put_charm(S, K, r, q, s, T)
h, e = 1e-4, 0.01
c_delta = -(delta(S, K, r, q, s, T + h) - delta(S, K, r, q, s, T - h)) / (2 * h)
c_price = -(call(S + e, K, r, q, s, T + h) - call(S - e, K, r, q, s, T + h)
            - call(S + e, K, r, q, s, T - h) + call(S - e, K, r, q, s, T - h)) / (4 * e * h)
c_theta = (theta(S + e, K, r, q, s, T) - theta(S - e, K, r, q, s, T)) / (2 * e)
c_int = -(delta_integral(S, K, r, q, s, T + h) - delta_integral(S, K, r, q, s, T - h)) / (2 * h)
p_bump = -(put_delta(S, K, r, q, s, T + h) - put_delta(S, K, r, q, s, T - h)) / (2 * h)
m = 1 / 12                                                 # one month, in years
drift = delta(S, K, r, q, s, T - m) - D
drift_int = simpson(lambda t: charm(S, K, r, q, s, T - t), 0.0, m, 200)   # charm added up over the month
book, day = 10000, 1 / 365                                 # 10,000 calls hedged; one day

rows = [("d1", d1), ("d2", d2), ("e^-qT", exp(-q * T)), ("N(d1)", N(d1)), ("phi(d1)", phi(d1)),
        ("slide  d(d1)/dT", (2 * (r - q) * T - d2 * s * sqrt(T)) / (2 * T * s * sqrt(T))), ("call delta", D),
        ("dividend piece  q e^-qT N(d1)", q * D), ("bell piece  e^-qT phi(d1) slide", q * D - ch),
        ("1 charm, formula", ch), ("2 delta bumped in time", c_delta), ("3 price bumped in S and T", c_price),
        ("4 theta bumped in S", c_theta), ("5 integral delta, bumped", c_int),
        ("put delta", put_delta(S, K, r, q, s, T)), ("put charm, formula", chp),
        ("  put delta bumped in time", p_bump), ("  q e^-qT", q * exp(-q * T)),
        ("month: charm x 1/12", ch * m), ("  delta drift, repriced", drift), ("  charm added up", drift_int),
        ("  delta after a month", D + drift),
        ("night: charm per day", ch * day), ("  hedge change, charm", book * ch * day),
        ("  hedge change, repriced", book * (delta(S, K, r, q, s, T - day) - D)),
        ("  shares held tonight", book * D), ("  weekend, 3 days, charm", 3 * book * ch * day)]
for S1, lab in ((100.0, "2 days left, S 100"), (101.0, "2 days left, S 101")):
    pr = book * charm(S1, K, r, q, s, 2 * day) * day
    ex = book * (delta(S1, K, r, q, s, day) - delta(S1, K, r, q, s, 2 * day))
    rows += [(lab + ": delta", delta(S1, K, r, q, s, 2 * day)), ("  night, charm", pr), ("  night, repriced", ex),
             ("  charm misses by", ex - pr)]
gam = exp(-q * T) * phi(d1) / (S * s * sqrt(T))             # the gamma card's formula
rows += [("gamma", gam), ("  delta change, 1-sd day move", gam * S * s * sqrt(day))]
rows += [("wrong: no dividend piece", ch - q * D), ("wrong: time-left sign", -ch),
         ("wrong: per-year used per day", book * ch), ("wrong: put charm = call charm", ch),
         ("try: q = 0, call charm", charm(S, K, r, 0.0, s, T)), ("try: q = 0, put charm", put_charm(S, K, r, 0.0, s, T)),
         ("try: sigma = 0.40", charm(S, K, r, q, 0.40, T)), ("try: S 105, 1 month", charm(105.0, K, r, q, s, m))]
for name, x in rows:
    print(f"{name:<32} {x:>13.6f}")

left = (("1 yr", 1.0), ("6 mo", 0.5), ("3 mo", 0.25), ("1 mo", m), ("1 wk", 7 / 365), ("1 day", day), ("1 hr", day / 24))
print("\nshares per 100 calls   " + " ".join(f"{a:>6}" for a, _ in left))
for S1 in (95.0, 100.0, 105.0):
    print(f"chart, delta at {S1:3.0f}    " + " ".join(f"{100 * delta(S1, K, r, q, s, t):6.2f}" for _, t in left))
print(f"chart, Acme price      " + " ".join(f"{80 + 5 * i:>6d}" for i in range(9)))
for lab, t in (("charm x100, 1 yr", 1.0), ("charm x100, 3 mo", 0.25), ("charm x100, 1 mo", m)):
    print(f"{lab:<22} " + " ".join(f"{100 * charm(80 + 5 * i, K, r, q, s, t):6.2f}" for i in range(9)))

assert abs(D - 0.586851) < 5e-7,               "the delta card's house number"
assert abs(ch - -0.035639) < 5e-7,             "the shelf's house charm"
assert abs(c_delta - ch) < 1e-8,               "delta bumped in time"
assert abs(c_price - ch) < 1e-6,               "price bumped in S and T: no delta formula used"
assert abs(c_theta - ch) < 1e-8,               "theta bumped in S: mixed partials agree"
assert abs(c_int - ch) < 1e-7,                 "integral delta: no N, no d1"
assert abs(p_bump - chp) < 1e-8,               "put charm vs put delta bumped"
assert abs(drift_int - drift) < 1e-10,         "charm added up over a month = repriced drift"
assert abs(delta(S, K, r, q, s, 1e-8) - 0.5) < 1e-4, "at-the-money delta ends near one half"
print("ALL CHECKS PASS")
