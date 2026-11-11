# Trust regions -- the check behind the card.  Standard library only.
# Rosenbrock's banana valley, f(x, y) = (1 - x)^2 + 100 (y - x^2)^2, is
# minimised from (-1.2, 1) by a trust region: a quadratic model, the dogleg
# step inside a radius, the ratio test, and the radius resized by the ratio.
from math import hypot, sqrt, log10, cos, sin, pi

def f(x, y): return (1 - x) ** 2 + 100 * (y - x * x) ** 2
def grad(x, y): return (-2 * (1 - x) - 400 * x * (y - x * x), 200 * (y - x * x))
def hess(x, y): return (2 - 400 * (y - x * x) + 800 * x * x, -400 * x, 200.0)  # [[a, b], [b, c]]

def promise(g, B, d):                  # m(0) - m(d): the fall the model promises
    a, b, c = B
    return -(g[0] * d[0] + g[1] * d[1] + 0.5 * (a * d[0] ** 2 + 2 * b * d[0] * d[1] + c * d[1] ** 2))

def solve(B, g, lam=0.0):              # (B + lam I) d = -g, two equations by elimination
    a, b, c = B[0] + lam, B[1], B[2] + lam
    det = a * c - b * b
    return (-(c * g[0] - b * g[1]) / det, -(a * g[1] - b * g[0]) / det)

def cauchy(g, B, R):                   # best point straight downhill, inside radius R
    a, b, c = B
    gn, gBg = hypot(*g), a * g[0] ** 2 + 2 * b * g[0] * g[1] + c * g[1] ** 2
    t = R / gn if gBg <= 0 else min(gn * gn / gBg, R / gn)
    return (-t * g[0], -t * g[1])

def dogleg(g, B, R):
    a, b, c = B
    if a <= 0 or a * c - b * b <= 0: return cauchy(g, B, R)   # no bowl: no Newton point
    dN = solve(B, g)
    if hypot(*dN) <= R: return dN                             # Newton point fits
    dU = cauchy(g, B, float("inf"))                           # downhill to the turn
    if hypot(*dU) >= R: return cauchy(g, B, R)
    e = (dN[0] - dU[0], dN[1] - dU[1])                        # leg two: turn to Newton
    A, Bq, C = e[0] ** 2 + e[1] ** 2, 2 * (dU[0] * e[0] + dU[1] * e[1]), dU[0] ** 2 + dU[1] ** 2 - R * R
    t = (-Bq + sqrt(Bq * Bq - 4 * A * C)) / (2 * A)           # where leg two leaves the circle
    return (dU[0] + t * e[0], dU[1] + t * e[1])

def try_step(x, y, R):
    g, B = grad(x, y), hess(x, y)
    d = dogleg(g, B, R)
    pred, act = promise(g, B, d), f(x, y) - f(x + d[0], y + d[1])
    return d, pred, act, act / pred

def run(x, y, R, eta=0.1, shrink=0.25, grow=2.0, cap=10.0, kmax=200):
    trace = []
    for k in range(kmax):
        if hypot(*grad(x, y)) < 1e-8: break                   # stopping test
        d, pred, act, rho = try_step(x, y, R)
        ok = rho > eta
        trace.append((k, x, y, f(x, y), R, hypot(*d), pred, act, rho, ok))
        if ok: x, y = x + d[0], y + d[1]
        if rho < 0.25: R = shrink * R
        elif rho > 0.75 and abs(hypot(*d) - R) < 1e-12: R = min(grow * R, cap)
    return x, y, trace

# ---- road 1: derivatives against central differences ----
x1, y1 = -1.2 + solve(hess(-1.2, 1.0), grad(-1.2, 1.0))[0], 1.0 + solve(hess(-1.2, 1.0), grad(-1.2, 1.0))[1]
h, g1, B1 = 1e-5, grad(x1, y1), hess(x1, y1)
fd = ((f(x1 + h, y1) - f(x1 - h, y1)) / (2 * h), (f(x1, y1 + h) - f(x1, y1 - h)) / (2 * h))
fdB = ((grad(x1 + h, y1)[0] - grad(x1 - h, y1)[0]) / (2 * h), (grad(x1, y1 + h)[0] - grad(x1, y1 - h)[0]) / (2 * h))
assert max(abs(fd[0] - g1[0]), abs(fd[1] - g1[1])) < 1e-6 and abs(fdB[0] - B1[0]) < 1e-4 and abs(fdB[1] - B1[1]) < 1e-4
print(f"start (-1.2, 1): f = {f(-1.2, 1.0):.4f}; step 0 is the Newton point, to ({x1:.6f}, {y1:.6f}), f = {f(x1, y1):.6f}")
print(f"at x1: gradient ({g1[0]:.6f}, {g1[1]:.6f}), Hessian a, b, c = {B1[0]:.4f}, {B1[1]:.4f}, {B1[2]:.4f}")

# ---- the overpromise at x1, and the subproblem solved three ways ----
dN, dU = solve(B1, g1), cauchy(g1, B1, float("inf"))
print(f"Newton point ({dN[0]:.6f}, {dN[1]:.6f}), length {hypot(*dN):.6f}; downhill turn at length {hypot(*dU):.6f}")
print("radius    step x    step y   promised  delivered       rho")
for R in (hypot(*dN), 1.0, 0.5, 0.25, 0.125):
    d, pred, act, rho = try_step(x1, y1, R)
    print(f"{R:6.4f} {d[0]:9.6f} {d[1]:9.6f} {pred:10.6f} {act:10.6f} {rho:9.4f}")
radii = [0.1 * i for i in range(1, 11)]
falls = [try_step(x1, y1, R)[1:3] for R in radii]
print("chart, radius 0.1 to 1.0 by 0.1, promised: " + ", ".join(f"{p:.4f}" for p, a in falls))
print("chart, radius 0.1 to 1.0 by 0.1, delivered: " + ", ".join(f"{a:.4f}" for p, a in falls))
for R in (1.0, 0.25):
    lo, hi = 0.0, 1e6                                         # road 2: exact step, bisection on the damping
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if hypot(*solve(B1, g1, mid)) > R else (lo, mid)
    exact = promise(g1, B1, solve(B1, g1, hi))
    scan = max(promise(g1, B1, (R * cos(2 * pi * i / 100000), R * sin(2 * pi * i / 100000))) for i in range(100000))
    dog, cau = promise(g1, B1, dogleg(g1, B1, R)), promise(g1, B1, cauchy(g1, B1, R))
    print(f"radius {R:.2f}: promised fall, Cauchy {cau:.6f} <= dogleg {dog:.6f} <= exact {exact:.6f} (circle scan {scan:.6f}), dogleg/exact {dog / exact:.4f}")
    assert abs(exact - scan) < 1e-6 and cau <= dog <= exact + 1e-12 and dog >= 0.9 * exact
d, pred, act, rho = try_step(x1, y1, 1.0)                    # road 3: the exact leftover terms
u, v = d[0], d[1]                                            # f is quartic, so the model misses by
left = 100 * u ** 4 - 200 * u * u * (v - 2 * x1 * u)          # exactly this much
print(f"radius 1: v - 2xu = {v - 2 * x1 * u:.6f}, leftover quartic terms {left:.6f}; promised - leftover = {pred - left:.6f}, delivered {act:.6f}")
rhos = [try_step(x1, y1, r)[3] for r in (0.1, 0.01, 0.001)]
print("rho at radius 0.1, 0.01, 0.001: " + ", ".join(f"{q:.6f}" for q in rhos))
assert abs(pred - left - act) < 1e-9 and rho < 0 and abs(rhos[2] - 1) < abs(rhos[1] - 1) < abs(rhos[0] - 1) < 0.05

# ---- the full run ----
x, y, tr = run(-1.2, 1.0, 1.0)
print(" k         x         y          f  radius    step  promised delivered     rho  verdict")
for k, xa, ya, fa, R, n, pred, act, rho, ok in tr:
    print(f"{k:2d} {xa:9.6f} {ya:9.6f} {fa:10.6f} {R:7.4f} {n:7.4f} {pred:9.6f} {act:9.6f} {rho:7.3f}  {'accept' if ok else 'reject'}")
acc = [t for t in tr if t[9]]
logs = [log10(max(t[3], 1e-300)) for t in acc] + [log10(max(f(x, y), 1e-300))]
print("chart log10 f at each accepted point: " + ", ".join(f"{v:.2f}" for v in logs))
gx, gy = grad(x, y)
a, b, c = hess(x, y)
print(f"stopped after {len(tr)} iterations ({len(tr) - len(acc)} rejected) at ({x:.9f}, {y:.9f}), "
      f"log10 f = {logs[-1]:.2f}, |gradient| below 1e-8: {hypot(gx, gy) < 1e-8}")
print(f"certificate: Hessian there a = {a:.4f}, det = {a * c - b * b:.4f} > 0; f is a sum of squares, f(1, 1) = {f(1.0, 1.0):.1f}")
assert hypot(x - 1, y - 1) < 1e-8 and a > 0 and a * c - b * b > 0 and f(1.0, 1.0) == 0.0
assert all(acc[i + 1][3] < acc[i][3] for i in range(len(acc) - 1)) and f(x, y) < acc[-1][3]

# ---- what breaks ----
xn, yn, newton_f = -1.2, 1.0, []
for _ in range(20):
    if hypot(*grad(xn, yn)) < 1e-8: break
    d = solve(hess(xn, yn), grad(xn, yn))
    xn, yn = xn + d[0], yn + d[1]
    newton_f.append(f(xn, yn))
print(f"pure Newton: f after steps 1, 2, 3 = {newton_f[0]:.6f}, {newton_f[1]:.6f}, {newton_f[2]:.6f}; done in {len(newton_f)} steps")
_, _, t2 = run(-1.2, 1.0, 1.0, shrink=1.0, kmax=50)
print(f"never shrink: {sum(1 for t in t2 if not t[9])} of {len(t2)} tries rejected, stuck at f = {t2[-1][3]:.6f}")
_, _, t3 = run(-1.2, 1.0, 1.0, eta=-1e300)
print(f"no ratio test: f goes {t3[1][3]:.6f} -> {t3[2][3]:.6f} at k = 1; done in {len(t3)} iterations")
x4, y4, t4 = run(-1.2, 1.0, 0.1, shrink=1.0, grow=1.0)
print(f"radius fixed at 0.1: {len(t4)} iterations, against {len(tr)}")
assert newton_f[1] > 1000 and len(t2) == 50 and t2[-1][3] == f(x1, y1) and t3[2][3] > t3[1][3] and len(t4) > 2 * len(tr)
r1 = try_step(x1, y1, 1.0)[0]
print(f"figure, x1 = ({x1:.4f}, {y1:.4f}), circles 1 and 0.25, rejected ({x1 + r1[0]:.4f}, {y1 + r1[1]:.4f}), "
      f"accepted ({acc[2][1]:.4f}, {acc[2][2]:.4f}), level f = {f(x1, y1):.4f}")
print("ALL CHECKS PASS")
