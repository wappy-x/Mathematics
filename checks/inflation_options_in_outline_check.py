# A 0% floor and a 5% cap on year-on-year inflation, five yearly fixings, shifted Black.
# Roads: the formula; the payoff averaged over the bell curve; a coin-flip tree; parity.
from math import erf, exp, log, sqrt, pi

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

M = 1_000_000.0                 # notional, dollars
F, A, SIG = 0.025, 0.03, 0.20   # forward YoY rate, shift, shifted volatility
NOM = 1.01 * 1.025 - 1.0        # nominal yearly rate from 1% real and 2.5% breakeven
YEARS = (1, 2, 3, 4, 5)
def D(t): return (1.0 + NOM) ** (-t)

def black(g, l, w, put):        # Black-76 on the slid pair, undiscounted
    if l <= 0.0: return 0.0 if put else g - l
    if w <= 0.0: return max(l - g, 0.0) if put else max(g - l, 0.0)
    d1 = (log(g / l) + 0.5 * w * w) / w
    d2 = d1 - w
    return l * N(-d2) - g * N(-d1) if put else g * N(d1) - l * N(d2)

def let_(k, t, put, f=F, a=A, sig=SIG, tv=None, disc=D):
    tv = t if tv is None else tv
    return M * disc(t) * black(f + a, k + a, sig * sqrt(tv), put)

def book(k, put, **kw): return sum(let_(k, t, put, **kw) for t in YEARS)

def simpson(fn, lo, hi, n=2000):
    h = (hi - lo) / n
    s = fn(lo) + fn(hi) + sum((4 if i % 2 else 2) * fn(lo + i * h) for i in range(1, n))
    return s * h / 3.0

def let_integral(k, t, put):    # average the payoff over the bell curve; kink found by bisection
    w = SIG * sqrt(t)
    y = lambda z: (F + A) * exp(-0.5 * w * w + w * z) - A          # the YoY fixing at draw z
    pay = lambda z: (max(k - y(z), 0.0) if put else max(y(z) - k, 0.0)) * phi(z)
    lo, hi = -12.0, 12.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if y(mid) < k else (lo, mid)
    return M * D(t) * (simpson(pay, -12.0, lo) + simpson(pay, lo, 12.0))

def let_tree(k, t, put, n=2000):   # drift-free coin-flip tree on the slid rate
    u = exp(SIG * sqrt(t / n)); p = (1.0 - 1.0 / u) / (u - 1.0 / u)
    lw, tot = n * log(1.0 - p), 0.0
    for j in range(n + 1):
        y = (F + A) * u ** (2 * j - n) - A
        tot += exp(lw) * (max(k - y, 0.0) if put else max(y - k, 0.0))
        lw += log((n - j) / (j + 1)) + log(p / (1.0 - p)) if j < n else 0.0
    return M * D(t) * tot

fl = [let_(0.0, t, True) for t in YEARS]
fl_int = [let_integral(0.0, t, True) for t in YEARS]
fl_tree = [let_tree(0.0, t, True) for t in YEARS]
cap5 = book(0.05, False)
cap5_int = sum(let_integral(0.05, t, False) for t in YEARS)
cap0_int = sum(let_integral(0.0, t, False) for t in YEARS)
swap = sum(M * D(t) * (F - 0.0) for t in YEARS)

g, l, w5 = F + A, A, SIG * sqrt(5.0)
d1 = (log(g / l) + 0.5 * w5 * w5) / w5; d2 = d1 - w5
bp, vp = 1e-4, 0.01
delta_an = sum(-M * D(t) * N(-(log(g / l) + 0.5 * SIG * SIG * t) / (SIG * sqrt(t))) * bp for t in YEARS)
delta_bump = (book(0.0, True, f=F + bp / 10) - book(0.0, True, f=F - bp / 10)) * 5.0
vega_an = sum(M * D(t) * g * sqrt(t) * phi((log(g / l) + 0.5 * SIG * SIG * t) / (SIG * sqrt(t))) * vp for t in YEARS)
vega_bump = (book(0.0, True, sig=SIG + vp / 10) - book(0.0, True, sig=SIG - vp / 10)) * 5.0

# convexity: YoY forward = (1 + b) exp(-rho vI vP) - 1, with vI vP = sI sR T(i-1); second road by 2D Simpson
SI, SR, RHO = 0.01, 0.01, 0.5
def fwd_adj(t, rho=RHO): return (1.0 + F) * exp(-rho * SI * SR * (t - 1)) - 1.0
def joint_mean(vi, vp, rho, n=240):   # E[exp(vi z1 - vi^2/2) exp(vp z2 - vp^2/2)], corr(z1, z2) = rho
    c = sqrt(1.0 - rho * rho)
    inner = lambda z1: simpson(lambda e: exp(vp * (rho * z1 + c * e) - 0.5 * vp * vp) * phi(e), -9.0, 9.0, n)
    return simpson(lambda z1: exp(vi * z1 - 0.5 * vi * vi) * phi(z1) * inner(z1), -9.0, 9.0, n)
v19 = SI * sqrt(19.0) * SR * sqrt(19.0)
jm20 = joint_mean(SI * sqrt(19.0), SR * sqrt(19.0), RHO)
fl_adj = sum(let_(0.0, t, True, f=fwd_adj(t)) for t in YEARS)

print(f"inputs: forward {100 * F:.2f} pct, shift {100 * A:.2f} pct, vol {100 * SIG:.2f} pct, notional {M:.0f}")
print(f"toy: index vol {100 * SI:.2f} pct, real-rate vol {100 * SR:.2f} pct, rho {RHO:.2f}")
rows = [
    ("nominal rate from Fisher, pct", 100 * NOM), ("D(5), dollars per dollar", D(5)),
    ("year 5: G, pct", 100 * g), ("year 5: L, pct", 100 * l), ("year 5: w", w5),
    ("year 5: d1", d1), ("year 5: d2", d2), ("year 5: N(-d2)", N(-d2)), ("year 5: N(-d1)", N(-d1)),
    ("napkin normal vol, G sigma, pct", 100 * g * SIG),
    *[(f"1 floorlet year {t}, formula, $", v) for t, v in zip(YEARS, fl)],
    ("1 floor 0%, formula, $", sum(fl)), ("2 floor 0%, payoff average, $", sum(fl_int)),
    ("3 floor 0%, tree 2000 steps, $", sum(fl_tree)),
    ("  cap 5%, formula, $", cap5), ("  cap 5%, payoff average, $", cap5_int),
    ("  collar: 0% floor minus 5% cap, $", sum(fl) - cap5),
    ("4 cap 0% minus floor 0%, $", cap0_int - sum(fl)), ("  swap: sum D(t) (F - 0), $", swap),
    ("delta per 1 bp of F, formula, $", delta_an), ("delta per 1 bp of F, bump, $", delta_bump),
    ("vega per vol point, formula, $", vega_an), ("vega per vol point, bump, $", vega_bump),
    ("plain Black, no shift, floor 0%, $", book(0.0, True, a=0.0)),
    ("convexity: year 5 forward, pct", 100 * fwd_adj(5)),
    ("convexity: year 5 shift, bp", 1e4 * (fwd_adj(5) - F)),
    ("convexity: year 20 shift, bp", 1e4 * (fwd_adj(20) - F)),
    ("  factor exp(rho vI vP), year 20", exp(RHO * v19)),
    ("  the same by 2D Simpson", jm20),
    ("  floor 0% on adjusted forwards, $", fl_adj),
    ("wrong: vol run to start of year, $", sum(let_(0.0, t, True, tv=t - 1) for t in YEARS)),
    ("wrong: strike slid, rate not, $", sum(M * D(t) * black(F, A, SIG * sqrt(t), True) for t in YEARS)),
    ("wrong: 20% vol used at a 1% shift, $", book(0.0, True, a=0.01)),
    ("wrong: discounted at the 1% real rate, $", book(0.0, True, disc=lambda t: 1.01 ** (-t))),
    ("try: sigma = 30%, $", book(0.0, True, sig=0.30)),
    ("try: forward 1%, $", book(0.0, True, f=0.01)),
    ("try: strike -1%, $", book(-0.01, True)),
]
for name, v in rows:
    print(f"{name:<42} {v:>14.6f}")
print("bars, floorlets by year, $       " + " ".join(f"{v:>9.2f}" for v in fl))
xs = [-3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7]
print("chart, YoY inflation pct          " + " ".join(f"{x:>6d}" for x in xs))
print("chart, floorlet pays $            " + " ".join(f"{M * max(-x / 100, 0.0):>6.0f}" for x in xs))
print("chart, 5% caplet pays $           " + " ".join(f"{M * max(x / 100 - 0.05, 0.0):>6.0f}" for x in xs))
ks = [-0.02, -0.01, 0.0, 0.01, 0.02, 0.03]
print("chart, floor strike pct    " + " ".join(f"{100 * k:>9.0f}" for k in ks))
print("chart, shifted, $          " + " ".join(f"{book(k, True):>9.2f}" for k in ks))
print("chart, plain Black, $      " + " ".join(f"{book(k, True, a=0.0):>9.2f}" for k in ks))

assert abs(sum(fl_int) - sum(fl)) < 1e-6, "payoff average must land on the formula"
assert abs(sum(fl_tree) - sum(fl)) < 1.0, "tree within a dollar"
assert abs(cap5_int - cap5) < 1e-6, "cap by integral vs formula"
assert abs((cap0_int - sum(fl)) - swap) < 1e-6, "cap minus floor at one strike is the swap"
assert abs(delta_an - delta_bump) < 1e-4, "delta by bump"
assert abs(vega_an - vega_bump) < 0.005, "vega by bump"
assert abs(jm20 - exp(RHO * v19)) < 1e-10, "convexity factor"
assert abs((1.0 + F) / jm20 - 1.0 - fwd_adj(20)) < 1e-10, "year-20 forward by 2D Simpson"
print("ALL CHECKS PASS")
