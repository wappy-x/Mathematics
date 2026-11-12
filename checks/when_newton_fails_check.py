# Newton's bad days: the check behind the card.  Standard library only.
# A triple root (x^3) slows Newton to a crawl; arctan makes it overshoot, cycle and
# run away.  Diagnose, cure, damp, and test the conditions that guarantee convergence.
from math import atan, log, log10, sqrt, ceil
def sci(v, d=2):                              # 1.23e-10, the form Rust prints
    m, e = f"{v:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def newton(f, df, x, steps, m=1):             # m = 1 plain; m > 1 the modified step
    xs = [x]
    for _ in range(steps):
        if f(xs[-1]) == 0: break
        xs.append(xs[-1] - m * f(xs[-1]) / df(xs[-1]))
    return xs
cube, dcube = (lambda x: x * x * x), (lambda x: 3 * x * x)
xs = newton(cube, dcube, 1.0, 60)
k9 = next(k for k, x in enumerate(xs) if abs(x) < 1e-9)
print("1. Newton on f(x) = x^3 from 1 (root 0, slope 0 there)")
for k in (0, 1, 2, 3, 10, k9 - 1, k9):
    q = f"{xs[k] / xs[k - 1]:.6f}" if k else "-"
    print(f"   k = {k:2}  x_k = error = {sci(xs[k])}  ratio e_k/e_(k-1) = {q}")
cf = [1.0]                                    # road two: (2/3)^k by repeated multiplication
for _ in range(k9): cf.append(cf[-1] * (2 / 3))
gap = max(abs(xs[k] / cf[k] - 1) for k in range(k9 + 1))
print(f"   closed form x_k = (2/3)^k: largest relative gap {sci(gap)}")
print(f"   steps to error < 1e-9: run {k9}, formula ceil(9/log10(1.5)) = {ceil(9 / log10(1.5))}, "
      f"{log10(1.5):.3f} digits a step")
assert k9 == ceil(9 / log10(1.5)) and gap < 1e-14
assert all(0 < xs[k + 1] < xs[k] for k in range(k9))            # monotone, as the theorem says
q = xs[k9] / xs[k9 - 1]
print(f"   multiplicity read off the ratio: m = 1/(1 - q) = {1 / (1 - q):.4f}")
assert abs(1 / (1 - q) - 3) < 1e-9
print(f"   last step {sci(xs[k9 - 1] - xs[k9])}, true error after it {sci(xs[k9])}: error = 2 x step")
mx = newton(cube, dcube, 1.0, 5, m=3)
print(f"2. modified Newton, 3 f/f', on x^3 from 1: x_1 = {sci(mx[1])}, done in {len(mx) - 1} step")
assert mx == [1.0, 0.0]
m2 = newton(cube, dcube, 1.0, 60, m=2)                          # too small an m: still linear
k2 = next(k for k, x in enumerate(m2) if abs(x) < 1e-9)
print(f"   with m = 2 instead: ratio {m2[1] / m2[0]:.6f}, {k2} steps to error < 1e-9")
assert k2 == ceil(9 / log10(3))
g, dg = (lambda x: x ** 3 + x ** 4), (lambda x: 3 * x * x + 4 * x ** 3)
gp, gm = newton(g, dg, 1.0, 80), newton(g, dg, 1.0, 6, m=3)
kp = next(k for k, x in enumerate(gp) if abs(x) < 1e-9)
print(f"   on x^3 + x^4 from 1: plain Newton {kp} steps, last ratio {gp[kp] / gp[kp - 1]:.4f}")
print("   modified:  k  error e_k   e_k/e_(k-1)^2   law 1/(3 + 4 e_(k-1))")
for k in range(1, 5):
    law = 1 / (3 + 4 * gm[k - 1])
    print(f"              {k}  {sci(gm[k]):>9}   {gm[k] / gm[k - 1] ** 2:.6f}        {law:.6f}")
    assert abs(gm[k] / gm[k - 1] ** 2 - law) < 1e-9
assert abs(gm[4] / gm[3] ** 2 - 1 / 3) < 1e-5 and gm[4] < 1e-10 < gm[3]
p, dp = (lambda x: ((x - 3) * x + 3) * x - 1), (lambda x: (3 * x - 6) * x + 3)
pe = newton(p, dp, 2.0, 200)
u = 2.0 ** -53
print(f"3. (x-1)^3 multiplied out, from 2: stops after {len(pe) - 1} steps with p(x) = {sci(p(pe[-1]))}")
print(f"   true error {sci(abs(pe[-1] - 1))}; u = {sci(u)}, estimate cbrt(u) = {sci(u ** (1 / 3))}")
assert p(pe[-1]) == 0 and 1e-6 < abs(pe[-1] - 1) < 2 * u ** (1 / 3)
N = lambda x: x - (1 + x * x) * atan(x)                         # Newton's step on arctan
c = lambda x: (1 + x * x) * atan(x) - 2 * x                     # zero where N(x) = -x
lo, hi = 1.0, 2.0
while lo < (lo + hi) / 2 < hi:
    lo, hi = ((lo + hi) / 2, hi) if c((lo + hi) / 2) < 0 else (lo, (lo + hi) / 2)
a, b = 1.0, 2.0                                                 # road two: secant on c
for _ in range(40):
    if c(b) == c(a): break
    a, b = b, b - c(b) * (b - a) / (c(b) - c(a))
xc = lo
print(f"4. Newton on arctan: cycle point x_c, bisection {xc:.11f}, secant {b:.11f}")
assert abs(xc - b) < 1e-12 and abs(N(xc) + xc) < 1e-12
print(f"   N(x_c) = {N(xc):.11f}; slope of the step map there N'(x_c) = -2 x_c atan(x_c) = {-2 * xc * atan(xc):.4f}")
fx = lambda v: f"{v:.3f}" if abs(v) < 1000 else sci(v)
for lab, x0 in (("1.39", 1.39), ("1.5", 1.5), ("10", 10.0)):
    s = [x0]
    while len(s) < 7 and abs(s[-1]) < 1e30 and abs(s[-1]) > 1e-12: s.append(N(s[-1]))
    print(f"   from {lab:<4}: " + ", ".join(fx(v) for v in s))
assert all(N(x) * x < 0 for x in (0.1, 0.5, 1.0, 2.0, -3.0))    # every step overshoots
s, k = [xc], 0
while abs(abs(s[-1]) - xc) < 1e-3: s.append(N(s[-1]))
print(f"   from x_c in floats: the 2-cycle holds to 1e-3 for {len(s) - 1} steps, then x = {s[-1]:.4f}")
amp = (2 * xc * atan(xc)) ** 2                                  # growth of a slip per round trip
est = 2 * log(1e-3 / 1e-16) / log(amp)
print(f"   a slip grows x{amp:.4f} per round trip; from 1e-16 to 1e-3 takes about {est:.1f} steps")
assert abs(est - (len(s) - 1)) < 3
def damped(x, c1=1e-4):                                         # backtracking on |f|
    path = []
    while abs(atan(x)) > 1e-15 and len(path) < 50:
        d, lam = -(1 + x * x) * atan(x), 1.0
        while abs(atan(x + lam * d)) > (1 - c1 * lam) * abs(atan(x)): lam /= 2
        x += lam * d
        path.append((lam, x))
    return path
dp10 = damped(10.0)
print(f"5. damped Newton from 10: {len(dp10)} steps, end x = {sci(dp10[-1][1])}")
print("   step lengths: " + " ".join(f"{l:g}" for l, _ in dp10))
L = 3 * sqrt(3) / 8                                             # largest |f''| for arctan
Ls = max(2 * x / (1 + x * x) ** 2 for x in (i / 10000 for i in range(30001)))
print(f"   largest |f''| = 2|x|/(1+x^2)^2: scan {Ls:.6f}, formula 3 sqrt(3)/8 = {L:.6f}")
assert abs(Ls - L) < 1e-6
lam_bound = (1 - 1e-4) * (1 / 101) ** 2 / (L * atan(10.0))
print(f"   theorem's floor on the step length {sci(lam_bound)}; smallest taken {min(l for l, _ in dp10):g}, "
      f"{min(l for l, _ in dp10) / lam_bound:.0f} times the floor")
assert abs(dp10[-1][1]) < 1e-15 and min(l for l, _ in dp10) >= lam_bound
assert [l for l, _ in dp10[-3:]] == [1.0, 1.0, 1.0]
for c1 in (1e-4, 0.5):                                          # the miss must fall at every step
    path = [10.0] + [x for _, x in damped(10.0, c1)]
    assert all(abs(atan(b)) < abs(atan(a)) for a, b in zip(path, path[1:]))
h = lambda x: L * atan(x) * (1 + x * x) ** 2                   # Kantorovich h at a start x
lo, hi = 0.0, 1.0
for _ in range(100): lo, hi = ((lo + hi) / 2, hi) if h((lo + hi) / 2) <= 0.5 else (lo, (lo + hi) / 2)
tstar = 1 / ((1 + lo * lo) * L)
print(f"6. Kantorovich on arctan: h <= 1/2 for |x0| <= {lo:.4f}; true basin |x0| < {xc:.4f}, "
      f"ratio {xc / lo:.3f}")
dat = lambda x: 1 / (1 + x * x)                                 # road two: beta and eta from the slope
beta, eta = 1 / dat(lo), abs(atan(lo) / dat(lo))
print(f"   at that edge beta L eta = {beta * L * eta:.6f}; the root is promised within t* = {tstar:.4f} of x0; "
      f"true distance {lo:.4f}")
assert abs(beta * L * eta - 0.5) < 1e-9
assert abs(h(lo) - 0.5) < 1e-9 and tstar > lo and newton(atan, lambda x: 1 / (1 + x * x), lo, 8)[-1] < 1e-15
print("chart, log10 error: plain x^3 " + " ".join(f"{log10(xs[k]):.2f}" for k in range(6))
      + "; modified x^3+x^4 " + " ".join(f"{log10(gm[k]):.2f}" for k in range(6)))
X, Y = (lambda x: 180 + 70 * x), (lambda y: 120 - 70 * y)
print(f"figure, cycle points ({X(xc):.1f}, {Y(atan(xc)):.1f}) and ({X(-xc):.1f}, {Y(-atan(xc)):.1f}), "
      f"tangents land at ({X(-xc):.1f}, {Y(0):.1f}) and ({X(xc):.1f}, {Y(0):.1f}), curve ends "
      f"({X(-2.4):.1f}, {Y(atan(-2.4)):.1f}) ({X(2.4):.1f}, {Y(atan(2.4)):.1f})")
print("ALL CHECKS PASS")
