# The interpolation error theorem -- the check behind the card.  Standard library only.
# Sine on [0, pi] from four nodes.  Road 1: the Lagrange form on a fine grid gives
# the true error.  Road 2: the closed form p(x) = a x (pi - x) and bisection on
# e'(x) = 0 find the worst point without a grid.  Road 3: divided differences
# give e(x) = f[x0..x3, x] * omega(x) with no Lagrange basis.  The theorem itself
# is tested at every grid point: 24 e(x) / omega(x) must be a value of sin.
import math
PI = math.pi
N = 3600                                      # grid: 3600 slices of [0, pi]

def lagrange(xs, ys, x):
    total = 0.0
    for j, xj in enumerate(xs):
        l = 1.0
        for k, xk in enumerate(xs):
            if k != j:
                l *= (x - xk) / (xj - xk)
        total += ys[j] * l
    return total
def omega(xs, x):                             # product of distances to the nodes
    w = 1.0
    for xk in xs:
        w *= x - xk
    return w
def divided(xs, ys):                          # top divided difference f[x0..xm]
    c = list(ys)
    for k in range(1, len(xs)):
        for i in range(len(xs) - 1, k - 1, -1):
            c[i] = (c[i] - c[i - 1]) / (xs[i] - xs[i - k])
    return c[-1]
def study(xs, f, lo, hi):                     # worst true error and worst |omega| on a grid
    ys = [f(x) for x in xs]
    best = (0.0, lo, 0.0, lo)
    for i in range(N + 1):
        x = lo + (hi - lo) * i / N
        e, w = abs(f(x) - lagrange(xs, ys, x)), abs(omega(xs, x))
        best = (max(best[0], e), x if e > best[0] else best[1],
                max(best[2], w), x if w > best[2] else best[3])
    return best

deg = math.degrees
eq = [k * PI / 3 for k in range(4)]
ys = [math.sin(x) for x in eq]
print("nodes, degrees", " ".join(f"{deg(x):.0f}" for x in eq))
print("values, sin   ", " ".join(f"{y:.6f}" for y in ys))
a = 9 * math.sqrt(3) / (4 * PI ** 2)          # p(x) = a x (pi - x) passes through all four
gap = max(abs(lagrange(eq, ys, PI * i / N) - a * (PI * i / N) * (PI - PI * i / N)) for i in range(N + 1))
assert gap < 1e-14, gap
print(f"closed form a = {a:.6f}; matches Lagrange at all {N + 1} grid points")

x = PI / 2                                    # the worked point, 90 degrees
p = lagrange(eq, ys, x); e = math.sin(x) - p; w = omega(eq, x)
s = 24 * e / w                                # the value sin(xi) must take
print(f"at 90: p {p:.6f}  true error {e:.6f}  omega {w:.6f}  omega/24 {w / 24:.6f}")
print(f"at 90: sin(xi) = 24 e/omega = {s:.6f}, xi = {deg(math.asin(s)):.2f} or {180 - deg(math.asin(s)):.2f} degrees")
assert abs(e - (1 - 9 * math.sqrt(3) / 16)) < 1e-14          # exact value by hand
dd = divided(eq + [x], ys + [math.sin(x)])
print(f"at 90: f[x0..x3,x] = {dd:.6f}, times omega = {dd * w:.6f}")
assert abs(dd * w - e) < 1e-12                              # road 3 against road 1

emax, xe, wmax, xw = study(eq, math.sin, 0.0, PI)
lo, hi = 0.2, 0.6                             # road 2: e'(x) = cos x - a (pi - 2x) = 0
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if math.cos(mid) - a * (PI - 2 * mid) < 0 else (lo, mid)
eb = abs(math.sin(lo) - a * lo * (PI - lo))
print(f"worst true error {emax:.6f} (grid); {eb:.6f} at {deg(lo):.2f} and {180 - deg(lo):.2f} deg (bisection)")
assert abs(eb - emax) < 1e-7
sw = (3 - math.sqrt(5)) / 2                   # |s(s-1)(s-2)(s-3)| peaks at 1, at s = (3 - sqrt5)/2
print(f"max|omega| {wmax:.6f} (grid); (pi/3)^4 = {(PI / 3) ** 4:.6f} at {deg(sw * PI / 3):.2f} and {180 - deg(sw * PI / 3):.2f} deg")
assert abs(wmax - (PI / 3) ** 4) < 1e-6
bound = wmax / 24
print(f"bound max|omega|/4! = {bound:.6f}; true {emax:.6f}; bound/true {bound / emax:.3f}")
assert emax <= bound

lo_s, hi_s = 1.0, 0.0                         # the theorem, point by point
for i in range(N + 1):
    t = PI * i / N
    if min(abs(t - xk) for xk in eq) > 1e-9:
        r = 24 * (math.sin(t) - lagrange(eq, ys, t)) / omega(eq, t)
        lo_s, hi_s = min(lo_s, r), max(hi_s, r)
print(f"24 e/omega over the grid: min {lo_s:.6f} max {hi_s:.6f} (sin on [0, pi] spans 0 to 1)")
assert 0 <= lo_s and hi_s <= 1 and abs(hi_s - 24 * (1 - 9 * math.sqrt(3) / 16) / (PI ** 4 / 144)) < 1e-9   # top: 90 by hand

cheb = [PI / 2 * (1 - math.cos((2 * k + 1) * PI / 8)) for k in range(4)]
bunch = [PI / 4 + k * PI / 6 for k in range(4)]
print("placement   nodes(deg)            max|omega|  bound     true      ratio")
for name, xs in [("equal", eq), ("chebyshev", cheb), ("bunched", bunch)]:
    em, _, wm, _ = study(xs, math.sin, 0.0, PI)
    print(f"{name:10s}  {' '.join(f'{deg(t):5.1f}' for t in xs)}  {wm:.6f}  {wm / 24:.6f}  {em:.6f}  {wm / 24 / em:.3f}")
    assert em <= wm / 24
    if name == "chebyshev":
        assert abs(wm - 2 * (PI / 4) ** 4) < 1e-6           # the smallest possible max|omega|

print("window(deg)  true      bound     ratio  order")
errs = []
for k in range(14):                           # four equal nodes across a window centred on 90, down to rounding
    wd = PI / 2 ** k
    xs = [PI / 2 - wd / 2 + j * wd / 3 for j in range(4)]
    em, _, wm, _ = study(xs, math.sin, PI / 2 - wd / 2, PI / 2 + wd / 2)
    order = "" if not errs else f"{math.log2(errs[-1] / em):.2f}"
    print(f"{deg(wd):9.2f}  {em:.3e}  {wm / 24:.3e}  {wm / 24 / em:.3f}  {order}")
    assert em <= wm / 24 + 1e-15              # rounding, a few units of 1.1e-16, lies outside the theorem
    errs.append(em)
assert 3.95 < math.log2(errs[7] / errs[8]) < 4.05 and abs(errs[6] / ((PI / 192) ** 4 / 24) - 1) < 0.01 and errs[-1] > (PI / 24576) ** 4 / 24
hmax = (24 * 1e-3) ** 0.25; m = math.ceil(PI / (3 * hmax)); h = PI / (3 * m)   # a table for 0.001: h^4 / 24 <= 0.001
ep = max(study([(3 * i + j) * h for j in range(4)], math.sin, 3 * i * h, 3 * i * h + 3 * h)[0] for i in range(m))
print(f"target 0.001: spacing at most {deg(hmax):.1f} deg; {m} cubic pieces, {3 * m + 1} values {deg(h):.0f} deg apart; bound {h ** 4 / 24:.3e}, true {ep:.3e}")
assert ep <= h ** 4 / 24 < 1e-3 < (PI / (3 * m - 3)) ** 4 / 24       # and one piece fewer would miss the target

ac = lambda t: abs(math.cos(t))               # what breaks: a kink at 90, no 4th derivative there
ek, xk, _, _ = study(eq, ac, 0.0, PI)
print(f"break, |cos x|: true {ek:.6f} at {deg(xk):.2f} deg against the claimed bound {bound:.6f}")
assert ek > 8 * bound
print(f"break, 3! for 4!: {wmax / 6:.6f};  (b-a)^4 for omega: {PI ** 4 / 24:.6f}")
xo = 4 * PI / 3                               # 240 degrees, outside the nodes
eo = abs(math.sin(xo) - lagrange(eq, ys, xo))
print(f"break, at 240 deg: true {eo:.6f}; in-span bound {bound:.6f}; right bound {abs(omega(eq, xo)) / 24:.6f}")
assert bound < eo <= abs(omega(eq, xo)) / 24
x10 = PI / 18                                 # 10 degrees: derivative read at x, not at xi
e10 = abs(math.sin(x10) - lagrange(eq, ys, x10))
print(f"break, sin(x) for sin(xi) at 10 deg: predicts {math.sin(x10) * abs(omega(eq, x10)) / 24:.6f}; true {e10:.6f}")

leb = max(sum(abs(lagrange(eq, [1.0 if i == j else 0.0 for i in range(4)], PI * t / N)) for j in range(4))
          for t in range(N + 1))
print(f"Lebesgue constant, equal nodes: {leb:.4f}")
assert abs(leb - 1.6311) < 1e-4                              # tabulated value for 4 equal nodes

five = [k * PI / 4 for k in range(5)]         # try changing: five nodes, 5th derivative is cos
e5, _, w5, _ = study(five, math.sin, 0.0, PI)
print(f"try, five equal nodes: true {e5:.6f}; bound max|omega|/5! {w5 / 120:.6f}")
assert e5 <= w5 / 120
xs13 = [PI * k / 12 for k in range(13)]
fix = lambda v: 0.0 if abs(v) < 5e-5 else v
print("chart, x (deg)    ", " ".join(f"{deg(t):.0f}" for t in xs13))
print("chart, error      ", " ".join(f"{fix(math.sin(t) - lagrange(eq, ys, t)):.4f}" for t in xs13))
print("chart, omega/24   ", " ".join(f"{fix(omega(eq, t) / 24):.4f}" for t in xs13))
print("chart, |omega| eq ", " ".join(f"{abs(omega(eq, t)):.4f}" for t in xs13))
print("chart, |omega| ch ", " ".join(f"{abs(omega(cheb, t)):.4f}" for t in xs13))
print("ALL CHECKS PASS")
