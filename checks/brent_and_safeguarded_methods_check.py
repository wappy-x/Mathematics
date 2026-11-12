# Brent's method -- the check behind the card.  Standard library only.
# A kiln's steel shell (6 m2, emissivity 0.85) sheds heat to 20 C air by
# radiation and convection (h = 8 W/m2K).  A gas meter says the loss is
# 12,000 W (illustrative).  Which shell temperature t, in C, explains it?
# Roads: bisection to the last bit; Brent; Dekker; a factorised residual.
from math import log, log10
SIG, AREA, EMIS, HC, LOSS, TA = 5.670374419e-8, 6.0, 0.85, 8.0, 12000.0, 293.15

def kiln(t):                              # heat loss at t minus the meter, in W
    T = t + 273.15
    return AREA * (EMIS * SIG * (T * T * T * T - TA * TA * TA * TA) + HC * (T - TA)) - LOSS

def kiln_factored(t):                     # the same loss, written another way
    T = t + 273.15
    return AREA * (T - TA) * (EMIS * SIG * (T * T + TA * TA) * (T + TA) + HC) - LOSS

def x9(x): return x * x * x * x * x * x * x * x * x

def iqi(a, b, c, fa, fb, fc):             # x as a quadratic in f, read at f = 0
    return (a * fb * fc / ((fa - fb) * (fa - fc)) + b * fa * fc / ((fb - fa) * (fb - fc))
            + c * fa * fb / ((fc - fa) * (fc - fb)))

def solve(f, lo, hi, delta, mode):        # mode: bisect, dekker, brent or notest
    fl, fh = f(lo), f(hi)
    if (fl < 0) == (fh < 0): return None, 2, []
    b, fb, c, fc = hi, fh, lo, fl         # b best end, c the other end
    if abs(fc) < abs(fb): b, fb, c, fc = c, fc, b, fb
    a, fa, n, log_ = c, fc, 2, []
    s1 = s2 = abs(c - b)                  # the last two step lengths
    while abs(c - b) / 2 > delta and fb != 0:
        m = (b + c) / 2
        if mode in ("brent", "notest") and a != c and fa != fb and fa != fc and fb != fc:
            p, kind = iqi(a, b, c, fa, fb, fc), "IQI"
        elif fa != fb: p, kind = b - fb * (b - a) / (fb - fa), "secant"
        else: p, kind = m, "no chord"         # b did not move, so a = b: halve
        st = abs(p - b)
        if mode == "dekker": ok = (p - b) * (c - b) > 0 and st < abs(m - b)
        else: ok = (p - b) * (c - b) > 0 and st < 0.75 * abs(c - b) and (mode == "notest"
                                                                       or max(st, delta) < s2 / 2)
        if mode == "bisect" or not (ok or kind == "no chord"): new, kind = m, "halve"
        elif st < delta: new, kind = b + (delta if c > b else -delta), "nudge"
        else: new = p
        s2, s1 = s1, abs(new - b)
        fn = f(new); n += 1
        a, fa = b, fb
        if (fn < 0) == (fc < 0): c, fc = b, fb
        b, fb = new, fn
        if abs(fc) < abs(fb): b, fb, c, fc = c, fc, b, fb
        log_.append((kind, new, fn, abs(c - b)))
    return b, n, log_

def promise(w, delta):                    # halvings until w / 2^k <= 2 delta
    k = 0
    while w / 2 ** k > 2 * delta: k += 1
    return k

lo, hi = 20.0, 520.0                      # reference: halve until the ends touch
while (lo + hi) / 2 not in (lo, hi):
    if kiln((lo + hi) / 2) < 0: lo = (lo + hi) / 2
    else: hi = (lo + hi) / 2
r = lo if abs(kiln(lo)) <= abs(kiln(hi)) else hi
T = r + 273.15
d1 = AREA * (4 * EMIS * SIG * T * T * T + HC)
d2, d3 = AREA * 12 * EMIS * SIG * T * T, AREA * 24 * EMIS * SIG * T
C = (3 * d2 * d2 - d1 * d3) / (6 * d1 * d1)
D = 1e-6
k = promise(500.0, D)
print(f"reference root t* (C)          {r:.12f}")
print(f"slope f'(t*) (W per C)         {d1:.6f}")
print(f"f(20) and f(520) (W)           {kiln(20.0):.3f} {kiln(520.0):.3f}")
print(f"delta {D:.0e} C; promise k = {k}; bound (k+1)(k+2) = {(k + 1) * (k + 2)}")
res = {}
for mode in ("bisect", "dekker", "brent"):
    x, n, lg = solve(kiln, 20.0, 520.0, D, mode)
    res[mode] = (x, n, lg)
    print(f"{mode:<7} evaluations {n:>3}  t = {x:.9f}  true error {x - r:.3e}")
print("Brent on the kiln: step, kind, t, f(t) in W, bracket width")
for i, (kind, x, fx, w) in enumerate(res["brent"][2]):
    print(f"  {i + 1}  {kind:<6} {x:16.9f} {fx:13.6f} {w:.3e}")
xb = res["brent"][0]
print(f"factorised residual at Brent's t  {kiln_factored(xb):.3e} W; bound f' x 2 delta {d1 * 2 * D:.3e}")
print(f"error bound 2 delta over Brent's true error  {2 * D / abs(xb - r):.1f}")
ch = [log10(res[m][2][j][3]) for m in ("bisect", "brent") for j in range(7)]
print("chart, log10 bracket width, evals 3-9, bisect", " ".join(f"{v:.2f}" for v in ch[:7]))
print("chart, log10 bracket width, evals 3-9, brent ", " ".join(f"{v:.2f}" for v in ch[7:]))
xs = [20.0, 520.0, 270.0]                 # pure IQI, no bracket, for the order
for i in range(6): xs.append(iqi(*xs[-3:], *[kiln(v) for v in xs[-3:]]))
e = [v - r for v in xs]
print(f"pure IQI from 20, 520, 270; predicted C = (3f''^2 - f'f''')/(6f'^2) = {C:.4e}")
for i in range(3, 9):
    ratio = e[i] / (e[i - 1] * e[i - 2] * e[i - 3])
    order = log(abs(e[i] / e[i - 1])) / log(abs(e[i - 1] / e[i - 2]))
    print(f"  x{i}  error {e[i]:10.3e}  e/(e e e) {ratio:10.3e}  order {order:.4f}")
pl, ph = 1.0, 2.0                          # p^3 = p^2 + p + 1 by halving
for _ in range(60):
    pm = (pl + ph) / 2
    if pm * pm * pm - pm * pm - pm - 1 < 0: pl = pm
    else: ph = pm
dg = [1.0, 2.0, 3.0]                      # digits obey D' = D + D_ + D__
for _ in range(40): dg.append(dg[-1] + dg[-2] + dg[-3])
print(f"order of IQI: root of p^3=p^2+p+1 {pl:.6f}; digit law ratio {dg[-1] / dg[-2]:.6f}")
k9 = promise(2.3, D)
print(f"x^9 on [-1, 1.3]: promise k = {k9}; bound (k+1)(k+2) = {(k9 + 1) * (k9 + 2)}")
cnt = {}
for mode in ("bisect", "dekker", "brent", "notest"):
    x, n, lg = solve(x9, -1.0, 1.3, D, mode)
    cnt[mode] = n
    h, nc = sum(s[0] == "halve" for s in lg), sum(s[0] == "no chord" for s in lg)
    print(f"  {mode:<7} evaluations {n:>3}  answer {x:.3e}  halvings {h + nc}, {nc} of them with no chord")
dk = solve(x9, -1.0, 1.3, D, "dekker")[2]
print("  Dekker bracket width after 25, 50, 100, 140 steps",
      " ".join(f"{dk[j - 1][3]:.3f}" for j in (25, 50, 100, 140)))
sx = [-1.0, 1.3]                          # plain secant, no bracket
while abs(sx[-1]) > D: sx.append(sx[-1] - x9(sx[-1]) * (sx[-1] - sx[-2]) / (x9(sx[-1]) - x9(sx[-2])))
print(f"  plain secant: {len(sx)} evaluations to reach |x| <= 1e-06")
bad = solve(kiln, 150.0, 520.0, D, "brent")
print(f"break: bracket [150, 520], f(150) = {kiln(150.0):.3f} W: answer {bad[0]}")
for loss in (6000.0, 24000.0):
    LOSS = loss
    x, n, _ = solve(kiln, 20.0, 520.0, D, "brent")
    print(f"try: loss {loss:.0f} W -> t = {x:.6f} C in {n} evaluations")
LOSS = 12000.0
for dd in (1e-3, 1e-9):
    print(f"try: delta {dd:.0e} -> bisection {solve(kiln, 20.0, 520.0, dd, 'bisect')[1]},"
          f" Brent {solve(kiln, 20.0, 520.0, dd, 'brent')[1]}")
assert abs(res["bisect"][0] - r) <= D and abs(res["brent"][0] - r) <= 2 * D
assert abs(res["dekker"][0] - r) <= 2 * D, "Dekker must land inside 2 delta"
assert res["bisect"][1] == k + 2, "bisection keeps its promise"
assert abs(kiln_factored(xb)) <= 1.01 * d1 * 2 * D, "residual road agrees"
assert res["brent"][1] <= (k + 1) * (k + 2) and cnt["brent"] <= (k9 + 1) * (k9 + 2)
assert min(cnt["dekker"], cnt["notest"]) > 4 * cnt["brent"], "the halving test must cure the slow case"
assert abs(e[7] / (e[6] * e[5] * e[4]) / C - 1) < 0.02, "IQI error law"
assert abs(pl - dg[-1] / dg[-2]) < 1e-9, "two roads to the order 1.839"
assert bad[0] is None, "no sign change must be refused"
print("ALL CHECKS PASS")
