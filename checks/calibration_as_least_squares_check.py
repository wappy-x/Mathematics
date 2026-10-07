# Calibration as least squares -- the check behind the card.  Standard library
# only.  Nothing is imported that already knows the answer: the bell-curve area
# is built from math.erf, the Levenberg-Marquardt loop is written out here, and
# a second road reaches the same fit by shrinking a grid, using no derivatives.
from math import log, sqrt, exp, erf, pi
S, R, T = 100.0, 0.05, 1.0                        # Acme spot, bank rate, one year
KS = (80.0, 90.0, 100.0, 110.0, 120.0)            # the five quoted strikes
SMILE = (0.22, 0.21, 0.20, 0.19, 0.185)           # vol the market charges per strike
START, BOX, FAR = (0.30, 0.05), ((0.05, 0.60), (-0.05, 0.12)), (0.70, 0.10)
def N(x):    return 0.5 * (1.0 + erf(x / sqrt(2.0)))       # bell-curve area left of x
def dens(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x
def call(K, sig, q):                              # Black-Scholes call at one strike
    v = sig * sqrt(T)
    d1 = (log(S / K) + (R - q + 0.5 * sig * sig) * T) / v
    return S * exp(-q * T) * N(d1) - K * exp(-R * T) * N(d1 - v)
def slopes(K, sig, q):                            # dC/dsigma (vega) and dC/dq
    v = sig * sqrt(T)
    d1 = (log(S / K) + (R - q + 0.5 * sig * sig) * T) / v
    return S * exp(-q * T) * dens(d1) * sqrt(T), -S * T * exp(-q * T) * N(d1)
def loss(ks, x, y, s):                            # half the sum of scaled squared misses
    return 0.5 * sum(((call(K, x[0], x[1]) - yi) / si) ** 2 for K, yi, si in zip(ks, y, s))
def normal(ks, x, y, s):                          # J'J (three entries) and the gradient J'e
    miss = [(call(K, x[0], x[1]) - yi) / si for K, yi, si in zip(ks, y, s)]
    J = [tuple(g / si for g in slopes(K, x[0], x[1])) for K, si in zip(ks, s)]
    a = [sum(j[0] * j[0] for j in J), sum(j[0] * j[1] for j in J), sum(j[1] * j[1] for j in J)]
    return a, [sum(j[0] * z for j, z in zip(J, miss)), sum(j[1] * z for j, z in zip(J, miss))]
def step(a, g, lam, scaled=True):                 # solve (J'J + damping) d = -J'e by hand
    b0, b2 = a[0] + lam * (a[0] if scaled else 1.0), a[2] + lam * (a[2] if scaled else 1.0)
    det = b0 * b2 - a[1] * a[1]
    if det <= 0.0:
        return None, det
    return [(-b2 * g[0] + a[1] * g[1]) / det, (a[1] * g[0] - b0 * g[1]) / det], det
def fit(ks, y, s, start, lam=1e-3):               # road one: Levenberg-Marquardt
    x, f, taken = list(start), loss(ks, start, y, s), 0
    for _ in range(200):
        a, g = normal(ks, x, y, s)
        for _ in range(60):
            d, _ = step(a, g, lam)
            if d is not None and x[0] + d[0] > 0.0:
                trial = [x[0] + d[0], x[1] + d[1]]
                ft = loss(ks, trial, y, s)
                if ft < f:
                    gain, x, f, taken = f - ft, trial, ft, taken + 1
                    lam = max(lam / 3.0, 1e-14)   # step taken: trust the slope more
                    if gain <= 1e-8 * (1.0 + f):
                        return x, f, taken, "loss settled"
                    break
            lam *= 3.0                            # step refused: trust the slope less
        else:
            return x, f, taken, "no better step"
    return x, f, taken, "step cap"
def shrink(ks, y, s, box, rounds=30, n=6):        # road two: shrink a grid, no derivatives
    (lo, hi), (lo2, hi2) = box
    best = [0.5 * (lo + hi), 0.5 * (lo2 + hi2)]
    for _ in range(rounds):
        cand = [[lo + (hi - lo) * i / n, lo2 + (hi2 - lo2) * j / n]
                for i in range(n + 1) for j in range(n + 1)]
        best = min(cand, key=lambda p: loss(ks, p, y, s))
        w, w2 = (hi - lo) / n, (hi2 - lo2) / n
        lo, hi = max(best[0] - w, 1e-4), best[0] + w
        lo2, hi2 = best[1] - w2, best[1] + w2
    return best, loss(ks, best, y, s)
def q_repricing(sig, target):                     # bisection: the price falls as q rises
    lo, hi = -0.40, 0.40
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if call(100.0, sig, mid) > target else (lo, mid)
    return 0.5 * (lo + hi)
def wide(name, values, fmt="{:>10.6f}"):
    print(f"{name:<30}" + "".join(fmt.format(v) for v in values))
def report(name, x, f, extra=""):
    print(f"{name:<30}sigma {x[0]:.6f}   q {x[1]:.6f}   loss {f:.8f}{extra}")
qa = [call(K, 0.20, 0.02) for K in KS]                 # set A: one volatility made these
qb = [call(K, v, 0.02) for K, v in zip(KS, SMILE)]     # set B: the market's own smile
vega, ones = [slopes(K, 0.20, 0.02)[0] for K in KS], [1.0] * 5   # scales: $ per 1.00 vol
print(f"five one-year Acme calls: spot {S:.2f}, bank rate {R * 100:.2f}%, strikes 80 to 120; "
      f"every fit starts at sigma {START[0]:.2f}, q {START[1]:.2f}")
wide("strike", KS, "{:>10.0f}")
wide("set A quote, one vol", qa)
wide("set B quote, market smile", qb)
wide("set B vol, strike by strike", SMILE)
wide("vega scale, $ per 1.00 vol", vega)
found = {}
for label, y, s in (("A, dollar scales", qa, ones), ("B, dollar scales", qb, ones),
                    ("B, vega scales", qb, vega)):
    x, f, n, stop = fit(KS, y, s, START)                    # road one
    g, fg = shrink(KS, y, s, BOX)                           # road two
    report("fit " + label, x, f, f"   steps {n}   stop: {stop}")
    report("fit " + label + ", grid", g, fg)
    found[label] = (x, g)
xa, xb, xv = (found[k][0] for k in ("A, dollar scales", "B, dollar scales", "B, vega scales"))
gb, gv = found["B, dollar scales"][1], found["B, vega scales"][1]
miss_b = [call(K, xb[0], xb[1]) - yi for K, yi in zip(KS, qb)]
miss_v = [call(K, xv[0], xv[1]) - yi for K, yi in zip(KS, qb)]
wide("dollar fit misses, dollars", miss_b)
wide("dollar fit misses, vol pts", [100.0 * m / w for m, w in zip(miss_b, vega)])
wide("vega fit misses, vol pts", [100.0 * m / w for m, w in zip(miss_v, vega)])
g0 = normal(KS, START, qb, ones)[1]
bump = [(loss(KS, [START[0] + 1e-5 * (k == 0), START[1] + 1e-5 * (k == 1)], qb, ones)     # the same
         - loss(KS, [START[0] - 1e-5 * (k == 0), START[1] - 1e-5 * (k == 1)], qb, ones)) / 2e-5 for k in (0, 1)]
print(f"gradient at the start, from the Jacobian {g0[0]:+.4f} {g0[1]:+.4f}, "
      f"by bumping the loss {bump[0]:+.4f} {bump[1]:+.4f}")
ab = normal(KS, xb, qb, ones)[0]
a1 = normal((100.0,), (0.20, 0.02), [qa[2]], [1.0])[0]     # one quote: J has a single row
dq = -S * T * exp(-0.02 * T)                               # a zero-strike ticket has no vega
tick = [0.0, 0.0, 5.0 * dq * dq]                           # so J'J for five of them is this
print(f"det(J'J): five strikes {ab[0] * ab[2] - ab[1] * ab[1]:.3f}, one strike "
      f"{a1[0] * a1[2] - a1[1] * a1[1]:.6f}, five zero-strike tickets {tick[0] * tick[2]:.6f}")
(lev, dlev), dmar = step(tick, [0.0, 1.0], 0.01, scaled=False), step(tick, [0.0, 1.0], 0.01, True)[1]
print(f"tickets, damped step: Levenberg moves sigma by {lev[0]:.6f}, determinant "
      f"{dlev:.6f}; Marquardt's determinant is {dmar:.6f}, so it has no step to take")
valley = [(sg, q_repricing(sg, qa[2])) for sg in (0.18, 0.19, 0.20, 0.21, 0.22)]
wide("valley, sigma", [v[0] for v in valley])
wide("valley, q repricing quote 3", [v[1] for v in valley])
x1, f1, n1, _ = fit((100.0,), [qa[2]], [1.0], (0.16, 0.00))
x2, f2, n2, _ = fit((100.0,), [qa[2]], [1.0], (0.26, 0.05))
report("one quote from sigma 0.16", x1, f1, f"   steps {n1}")
report("one quote from sigma 0.26", x2, f2, f"   steps {n2}")
pin, fpin = shrink(KS, qb, ones, ((0.05, 0.60), (0.0, 0.0)))
report("mistake, q pinned at zero", pin, fpin)
gn = step(*normal(KS, FAR, qb, ones), 0.0)[0]
xf, ff, nf, _ = fit(KS, qb, ones, FAR)
print(f"from sigma {FAR[0]:.2f}, q {FAR[1]:.2f}: one undamped step gives sigma "
      f"{FAR[0] + gn[0]:.6f}, a volatility below zero; damped, sigma {xf[0]:.6f} "
      f"and loss {ff:.8f} in {nf} steps")
for label, vals in (("chart, market vol percent", [100.0 * v for v in SMILE]),
                    ("chart, fitted flat vol", [100.0 * xv[0]] * 5), ("chart, vega scale dollars", vega),
                    ("chart, valley sigma percent", [100.0 * v[0] for v in valley]),
                    ("chart, valley q percent", [100.0 * v[1] for v in valley]), ("chart, dividend used", [2.0] * 5)):
    wide(label, vals, "{:>10.2f}")
assert abs(qa[2] - 9.227005508154) < 1e-9          # quote 3 is the house call price
assert abs(xa[0] - 0.20) < 1e-9 and abs(xa[1] - 0.02) < 1e-9   # set A recovers its makers
assert abs(xb[0] - gb[0]) < 1e-7 and abs(xb[1] - gb[1]) < 1e-7  # two roads, one fit
assert abs(xv[0] - gv[0]) < 1e-7 and abs(xv[1] - gv[1]) < 1e-7
assert max(abs(g0[k] - bump[k]) for k in (0, 1)) < 1e-4         # Jacobian vs bumped loss
assert all(abs(call(100.0, sg, qv) - qa[2]) < 1e-10 for sg, qv in valley)
assert loss(KS, xv, qb, vega) < loss(KS, xb, qb, vega)          # weights move the answer
assert abs(xf[0] - xb[0]) < 1e-7 and FAR[0] + gn[0] < 0.0       # damping saves a bad start
print("ALL CHECKS PASS")
