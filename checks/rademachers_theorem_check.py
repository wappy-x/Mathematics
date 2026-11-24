# Rademacher's theorem -- the check behind the card.  Standard library only.
# d(p) = | |p| - 1 | is the distance from p to the unit circle (a round fence of
# radius 1 m); f1(p) = |x| + |y|.  Both are Lipschitz.  The script checks the
# Lipschitz bounds, the gradient two ways, the size of the bad set, the
# test-function identity of Step 2, and the uniform error of Step 3.
import math
hyp = lambda x, y: math.sqrt(x * x + y * y)  # length of (x, y)

def d(x, y): return abs(hyp(x, y) - 1.0)
def f1(x, y): return abs(x) + abs(y)
def grad_d(x, y):                          # the formula, valid off the circle and origin
    r = hyp(x, y); s = 1.0 if r > 1.0 else -1.0
    return (s * x / r, s * y / r)
def central(f, x, y, h=1e-6):              # road two: difference quotients only
    return ((f(x + h, y) - f(x - h, y)) / (2 * h), (f(x, y + h) - f(x, y - h)) / (2 * h))
def fmt(p): return f"({p[0]:.6f}, {p[1]:.6f})"

state = 12345                              # a hand-written random number generator
def rnd():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return (state >> 11) / 2**53 * 4.0 - 2.0

best_d = best_f = 0.0
for _ in range(200000):                    # Lipschitz ratios over random pairs in [-2, 2]^2
    px, py, qx, qy = rnd(), rnd(), rnd(), rnd()
    dist = hyp(px - qx, py - qy)
    best_d = max(best_d, abs(d(px, py) - d(qx, qy)) / dist)
    best_f = max(best_f, abs(f1(px, py) - f1(qx, qy)) / dist)
print("d = distance to the unit circle; f1 = |x| + |y|")
print(f"largest ratio |f(p) - f(q)| / |p - q| over 200000 pairs: d {best_d:.6f} (L = 1), f1 {best_f:.6f} (L = {math.sqrt(2):.6f})")
assert 0.99 < best_d <= 1.0 + 1e-12 and 1.40 < best_f <= math.sqrt(2) + 1e-12

for name, (x, y) in [("A", (1.5, 2.0)), ("B", (0.3, 0.4))]:
    g, c = grad_d(x, y), central(d, x, y)
    print(f"mower {name} = ({x}, {y}): |p| {hyp(x, y):.6f}, d {d(x, y):.6f}, grad by formula {fmt(g)}, "
          f"by difference quotients {fmt(c)}, length {hyp(*g):.6f}")
    assert abs(g[0] - c[0]) < 1e-6 and abs(g[1] - c[1]) < 1e-6
for h in (0.1, 0.01):                      # the tangent-plane error at A, divided by the step
    plane = 1.5 + 0.6 * h
    print(f"step ({h}, 0) from A: d {d(1.5 + h, 2.0):.6f}, plane {plane:.6f}, error/step {abs(d(1.5 + h, 2.0) - plane) / h:.6f}")
print(f"fence point P = (1, 0), steps +0.1 and -0.1 along x: d {d(1.1, 0):.6f} and {d(0.9, 0):.6f}; "
      f"every plane misses one by at least {(d(1.1, 0) + d(0.9, 0)) / 2:.6f}, error/step {(d(1.1, 0) + d(0.9, 0)) / 0.2:.6f}")
print(f"centre O = (0, 0), step 0.1 in any direction: d {d(0.1, 0):.6f}, slope {(d(0.06, 0.08) - d(0, 0)) / 0.1:.6f} every way")
t0 = math.sqrt(1 - 0.25)                   # the line y = 0.5 meets the circle at x = +-t0
g = lambda t: d(t, 0.5)
print(f"line y = 0.5 meets the bad set at x = {-t0:.6f} and {t0:.6f}; slopes at x = {t0:.6f}: "
      f"left {(g(t0) - g(t0 - 1e-7)) / 1e-7:.6f}, right {(g(t0 + 1e-7) - g(t0)) / 1e-7:.6f}")
lf, rf = (f1(0, 0.5) - f1(-1e-3, 0.5)) / 1e-3, (f1(1e-3, 0.5) - f1(0, 0.5)) / 1e-3
cf = central(f1, 0.5, -0.3)                # off the axes the formula is (sign x, sign y) = (1, -1)
print(f"f1 on the line y = 0.5 at the axis x = 0: slope left {lf:.6f}, right {rf:.6f}; "
      f"at (0.5, -0.3), off the axes: grad (1, -1) by formula, {fmt(cf)} by difference quotients")
assert abs(lf + 1) < 1e-9 and abs(rf - 1) < 1e-9 and abs(cf[0] - 1) < 1e-6 and abs(cf[1] + 1) < 1e-6

M = 1000                                   # grid fraction of [-2, 2]^2 within h of the bad set
for h in (0.2, 0.1, 0.05):
    hits = 0
    for i in range(M):
        for j in range(M):
            x, y = -2 + 4 * (i + 0.5) / M, -2 + 4 * (j + 0.5) / M
            r = hyp(x, y)
            hits += abs(r - 1) < h or r < h
    exact = (4 * math.pi * h + math.pi * h * h) / 16
    print(f"share of the 4 m x 4 m yard within {h} m of circle or centre: grid {hits / M**2:.6f}, formula {exact:.6f}")
    assert abs(hits / M**2 - exact) < 1e-3

cx, cy, R, vx, vy, K = 1.2, 0.0, 0.5, 1.0, 0.0, 800   # Step 2: bump at C, direction v
def phi(x, y):
    s = ((x - cx) ** 2 + (y - cy) ** 2) / R**2
    return math.exp(-1 / (1 - s)) if s < 1 else 0.0
def dphi_v(x, y):                          # v . grad phi, from the chain rule
    s = ((x - cx) ** 2 + (y - cy) ** 2) / R**2
    if s >= 1: return 0.0
    return phi(x, y) * (-1 / (1 - s) ** 2) * 2 * (vx * (x - cx) + vy * (y - cy)) / R**2
lhs = rhs = 0.0; quot = [0.0, 0.0, 0.0]; ts = (0.1, 0.01, 0.001); w = (2 * R / K) ** 2
for i in range(K):
    for j in range(K):
        x, y = cx - R + 2 * R * (i + 0.5) / K, cy - R + 2 * R * (j + 0.5) / K
        p = phi(x, y)
        if p == 0.0: continue
        gx, gy = grad_d(x, y)
        lhs += (vx * gx + vy * gy) * p * w
        rhs -= d(x, y) * dphi_v(x, y) * w
        for k, t in enumerate(ts):
            quot[k] += (d(x + t * vx, y + t * vy) - d(x, y)) / t * p * w
print(f"Step 2, bump of radius 0.5 at C = (1.2, 0), v = (1, 0): integral of (v . grad d) phi {lhs:.5f}; "
      f"minus integral of d (v . grad phi) {rhs:.5f}")
print("  integral of the difference quotient times phi: " + ", ".join(f"t = {t}: {q:.5f}" for t, q in zip(ts, quot)))
assert abs(lhs - rhs) < 1e-5 and abs(quot[2] - lhs) < 1e-3 and abs(quot[0] - lhs) > 1e-4

dirs = [(math.cos(2 * math.pi * k / 3600), math.sin(2 * math.pi * k / 3600)) for k in range(3600)]
def worst(px, py, gx, gy, t):              # largest |error/step| over 3600 unit directions
    return max(abs((d(px + t * u, py + t * v) - d(px, py)) / t - (gx * u + gy * v)) for u, v in dirs)
wa = [worst(1.5, 2.0, 0.6, 0.8, t) for t in ts]
wp = [worst(1.0, 0.0, 0.0, 0.0, t) for t in ts]
print("Step 3, worst error/step over 3600 directions, t = 0.1, 0.01, 0.001:")
print("  at A with grad (0.6, 0.8): " + ", ".join(f"{q:.6f}" for q in wa))
print("  at P with the flat plane:  " + ", ".join(f"{q:.6f}" for q in wp))
assert wa[0] > wa[1] > wa[2] and wa[2] < 1e-3 and min(wp) > 1 - 1e-9

gxy = lambda x, y: 0.0 if x == y == 0 else x * x * y / (x * x + y * y)
u = 1 / math.sqrt(2)                       # slope of gxy at O along v, from both sides: v1^2 v2
fwd, bwd = gxy(1e-3 * u, 1e-3 * u) / 1e-3, gxy(-1e-3 * u, -1e-3 * u) / -1e-3
print(f"mistake 1, g = x^2 y/(x^2 + y^2) at O: partials {gxy(1e-3, 0) / 1e-3:.6f} and {gxy(0, 1e-3) / 1e-3:.6f}, "
      f"slope along ({u:.6f}, {u:.6f}) is {fwd:.6f} forward and {bwd:.6f} backward, the plane predicts 0")
print(f"mistake 2, f1 with L taken as 1: ratio along the diagonal {(f1(1e-3, 1e-3) - f1(0, 0)) / hyp(1e-3, 1e-3):.6f}")
print(f"mistake 3, a derivative expected at P: slope outward {(d(1.001, 0) - d(1, 0)) / 0.001:.6f}, "
      f"slope inward {(d(0.999, 0) - d(1, 0)) / 0.001:.6f}; a plane needs them to cancel")
def takagi(x): return sum(abs(2**k * x - round(2**k * x)) / 2**k for k in range(60))
slopes = []
for n in range(1, 7):                      # cells of width 2^-n holding 1/3
    a = math.floor(2**n / 3) / 2**n
    slopes.append(round((takagi(a + 2**-n) - takagi(a)) * 2**n))
print(f"mistake 4, Lipschitz dropped, Takagi T(x) on the plane: slopes across the cells holding x = 1/3: {slopes}")
assert abs(fwd - u ** 3) < 1e-12 and abs(bwd - u ** 3) < 1e-12 and slopes == [1, 0, 1, 0, 1, 0]

S, O = 60, (180, 165)                      # figure: 60 px per metre, centre at pixel (180, 165)
px = lambda x, y: f"({O[0] + S * x:.2f}, {O[1] - S * y:.2f})"
print(f"figure, circle r {S}px at {px(0, 0)}; A {px(1.5, 2.0)} to {px(1.74, 2.32)}; "
      f"B {px(0.3, 0.4)} to {px(0.06, 0.08)}; line y = 0.5 bad points {px(-t0, 0.5)} {px(t0, 0.5)}")
print("ALL CHECKS PASS")
