# Adaptive quadrature and awkward integrals -- the check behind the card.
# Standard library only: math gives atan, cos, exp, sqrt and pi. Every rule, weight
# and integral is computed here. Load in MW, time in hours, energy in MWh.
import math
from functools import reduce

XK = [0.991455371120812639, 0.949107912342758525, 0.864864423359769073, 0.741531185599394440,
      0.586087235467691130, 0.405845151377397167, 0.207784955007898468, 0.0]  # Kronrod nodes, x >= 0
WK = [0.022935322010529225, 0.063092092629978553, 0.104790010322250184, 0.140653259715525919,
      0.169004726639267903, 0.190350578064785410, 0.204432940075298892, 0.209482141084727828]
WG = [0.129484966168869693, 0.279705391489276668, 0.381830050505118945, 0.417959183673469388]  # Gauss: XK[1], XK[3], XK[5], XK[7]

def ef(x, d=3):                           # e-notation with the same text as Rust's {:.de}
    m, p = f"{x:.{d}e}".split("e")
    return f"{m}e{int(p)}"

def total(xs): return reduce(lambda s, x: s + x, xs, 0.0)  # plain left-to-right sum, as in Rust

def pw(x, n):                             # x to the n by repeated multiplication
    r = 1.0
    for _ in range(n):
        r *= x
    return r

def legendre(n, x):                       # P_n(x) and its slope, by the three-term recurrence
    p0, p1 = 0.0, 1.0
    for k in range(1, n + 1):
        p0, p1 = p1, ((2 * k - 1) * x * p1 - (k - 1) * p0) / k
    return p1, n * (x * p1 - p0) / (x * x - 1)

def kg(f, a, b):                          # Kronrod 15-point K and Gauss 7-point G on [a, b]
    c, h = (a + b) / 2, (b - a) / 2
    fc = f(c)
    k, g = WK[7] * fc, WG[3] * fc
    for i in range(7):
        s = f(c - h * XK[i]) + f(c + h * XK[i])
        k += WK[i] * s
        if i % 2 == 1:
            g += WG[i // 2] * s
    return k * h, g * h

def est(p): return abs(p[2] - p[3])       # a panel's error estimate |K - G|

def adaptive(f, a, b, tol, start=1):      # split the worst panel until the estimates sum to <= tol
    cuts = [a + (b - a) * j / start for j in range(start + 1)]
    ps = [(lo, hi) + kg(f, lo, hi) for lo, hi in zip(cuts, cuts[1:])]
    while total(est(p) for p in ps) > tol and len(ps) < 500:
        w = max(range(len(ps)), key=lambda j: est(ps[j]))
        lo, hi, _, _ = ps.pop(w)
        mid = (lo + hi) / 2
        ps += [(lo, mid) + kg(f, lo, mid), (mid, hi) + kg(f, mid, hi)]
    return total(p[2] for p in ps), total(est(p) for p in ps), 15 * (2 * len(ps) - start), ps

def uniform(f, a, b, n): return total(kg(f, a + (b - a) * j / n, a + (b - a) * (j + 1) / n)[0] for j in range(n))

# ---- 1. the rule's table, checked three ways ----
gn, gw = [], []
for i in range(4):                        # Newton on P_7 from a cosine guess
    x = math.cos(math.pi * (i + 0.75) / 7.5)
    for _ in range(8): p, dp = legendre(7, x); x -= p / dp
    gn.append(x)
    gw.append(2 / ((1 - x * x) * legendre(7, x)[1] * legendre(7, x)[1]))
dn = max(abs(gn[i] - XK[2 * i + 1]) for i in range(4))
dw = max(abs(gw[i] - WG[i]) for i in range(4))
print(f"Gauss nodes: Newton on P_7 vs table, max gap {ef(dn)}; weights 2/((1-x^2)P_7'(x)^2), max gap {ef(dw)}")
A = [[legendre(2 * m, x)[0] * (2 if i < 7 else 1) for i, x in enumerate(XK)] + [2.0 if m == 0 else 0.0] for m in range(8)]
for c in range(8):                        # Kronrod weights from 8 moment equations, Gaussian elimination
    r = max(range(c, 8), key=lambda r: abs(A[r][c])); A[c], A[r] = A[r], A[c]
    for r in range(c + 1, 8):
        q = A[r][c] / A[c][c]
        A[r] = [u - q * v for u, v in zip(A[r], A[c])]
wk = [0.0] * 8
for c in range(7, -1, -1):
    wk[c] = (A[c][8] - total(A[c][j] * wk[j] for j in range(c + 1, 8))) / A[c][c]
dk = max(abs(wk[i] - WK[i]) for i in range(8))
print(f"Kronrod weights from the moment equations vs table, max gap {ef(dk)}")
ex = {n: kg(lambda x: pw(x, n), -1, 1) for n in (12, 14, 22, 23, 24)}
print(f"exactness on [-1, 1]: G7 errors x^12 {ef(ex[12][1] - 2 / 13)}, x^14 {ef(ex[14][1] - 2 / 15)}; "
      f"K15 errors x^22 {ef(ex[22][0] - 2 / 23)}, x^23 {ef(ex[23][0])}, x^24 {ef(ex[24][0] - 2 / 25)}")
assert dn < 1e-15 and dw < 1e-15 and dk < 1e-14
assert abs(ex[22][0] - 2 / 23) < 1e-15 and abs(ex[23][0]) < 1e-15 and abs(ex[24][0] - 2 / 25) > 1e-9 and abs(ex[14][1] - 2 / 15) > 1e-6

# ---- 2. the peaked load: 2 MW all day plus a surge to 10 MW at 18:00, half-width 0.25 h ----
def surge(w): return lambda t: 2 + 8 / (1 + ((t - 18) / w) * ((t - 18) / w))
def surge_exact(w): return 48 + 8 * w * (math.atan(6 / w) + math.atan(18 / w))
load, E = surge(0.25), surge_exact(0.25)
print(f"load: exact energy 48 + 2(atan 24 + atan 72) = {E:.10f} MWh")
K0, G0 = kg(load, 0, 24)
print(f"first panel, 0 to 24 h: K15 {K0:.10f}, G7 {G0:.10f}, estimate {ef(abs(K0 - G0))}, true error {ef(abs(K0 - E))}")
v, e, n, ps = adaptive(load, 0, 24, 1e-3)
gsum = total(p[3] for p in ps)
print(f"adaptive, tol 1e-3: {v:.10f} MWh, estimate {ef(e)}, true error {ef(abs(v - E))}, "
      f"estimate / true {abs(e / (v - E)):.0f}, {n} evaluations, {len(ps)} panels")
for p in sorted(ps):
    print(f"  panel {p[0]:5.2f} to {p[1]:5.2f} h: {15 / (p[1] - p[0]):5.2f} points per hour")
print(f"same panels, G7 values summed: {gsum:.10f} MWh, true error {ef(abs(gsum - E))}")
assert abs(v - E) <= e <= 1e-3 and abs(gsum - E) > 1e-6
for tol in (1e-6, 1e-9, 1e-12):
    v2, e2, n2, p2 = adaptive(load, 0, 24, tol)
    print(f"adaptive, tol {ef(tol, 0)}: {n2} evaluations, {len(p2)} panels, estimate {ef(e2)}, true error {ef(abs(v2 - E))}")
ue = [abs(uniform(load, 0, 24, m) - E) for m in (4, 8, 16, 32)]
for j, m in enumerate((4, 8, 16, 32)):
    order = f", observed order {math.log2(ue[j - 1] / ue[j]):.1f}" if j else ""
    print(f"uniform, {m} panels, {15 * m} evaluations: true error {ef(ue[j])}{order}")
hh = 24 / 144
trap = hh * (total(load(j * hh) for j in range(145)) - (load(0) + load(24)) / 2)
print(f"ten-minute readings, trapezoid on 145 values: {trap:.10f} MWh, true error {ef(trap - E)}")
assert ue[1] > 1e-4 and 1e-9 > abs(v - E) and trap - E > 9e-4

# ---- 3. out to infinity: Planck's integral of x^3/(e^x - 1) from 0 to infinity is pi^4/15 ----
def planck(x): return 0.0 if x > 700 else x * x * x / (math.exp(x) - 1)
def mapped(t): return planck(t / (1 - t)) / ((1 - t) * (1 - t))  # x = t/(1 - t) takes [0, 1) to [0, infinity)
P = pw(math.pi, 4) / 15
v, e, n, ps = adaptive(mapped, 0, 1, 1e-10)
print(f"Planck: pi^4/15 = {P:.11f}; mapped to [0, 1): {v:.11f}, estimate {ef(e)}, true error {ef(abs(v - P))}, {n} evaluations")
assert abs(v - P) < 1e-10
sig = 2 * math.pi * pw(1.380649e-23, 4) * v / (pw(6.62607015e-34, 3) * pw(299792458.0, 2))
print(f"Stefan-Boltzmann constant from it: {ef(sig, 9)} W/(m^2 K^4); the sun at 5772 K: {sig * pw(5772.0, 4) / 1e6:.1f} MW per m^2")
for L in (10, 20, 40):
    vl, el, nl, pl = adaptive(planck, 0, L, 1e-10)
    print(f"cut off at x = {L}: {vl:.11f}, missing {ef(P - vl)}, {nl} evaluations")

# ---- 4. a spike at an end: the integral of 1/sqrt(x) from 0 to 1 is 2 ----
inv_sqrt = lambda x: 1 / math.sqrt(x)
se = [uniform(inv_sqrt, 0, 1, m) - 2 for m in (1, 4, 16, 64)]
print(f"1/sqrt(x), uniform 1, 4, 16, 64 panels: errors {', '.join(ef(s) for s in se)}")
v, e, n, ps = adaptive(inv_sqrt, 0, 1, 1e-8)
sub = kg(lambda u: 2 * u / math.sqrt(u * u), 0, 1)[0]
print(f"adaptive, tol 1e-8: error {ef(v - 2)}, {n} evaluations; substitute x = u^2: one panel, error {ef(sub - 2)}")
assert all(abs(se[j] / se[j + 1] - 2) < 1e-6 for j in range(3)) and abs(sub - 2) < 1e-15

# ---- 5. the trap: a surge 36 seconds wide (half-width 0.005 h) that one panel never sees ----
spike, S = surge(0.005), surge_exact(0.005)
v1, e1, n1, _ = adaptive(spike, 0, 24, 1e-3)
v24, e24, n24, _ = adaptive(spike, 0, 24, 1e-3, start=24)
print(f"spike: exact {S:.6f} MWh; from 1 panel {v1:.6f}, estimate {ef(e1)}, true error {ef(v1 - S)}, {n1} evaluations")
print(f"spike: from 24 hourly panels {v24:.6f}, estimate {ef(e24)}, true error {ef(v24 - S)}, {n24} evaluations")
assert S - v1 > 0.1 and 1e-3 > abs(v24 - S)
print("ALL CHECKS PASS")
