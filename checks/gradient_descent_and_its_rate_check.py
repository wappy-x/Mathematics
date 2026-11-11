# Gradient descent on the Rosenbrock banana, with the proofs' bounds checked.
# Standard library only: the gradient, the curvatures and the walk are written out.
import math

def f(x): return (1 - x[0])**2 + 100 * (x[1] - x[0]**2)**2
def grad(x): return [-2 * (1 - x[0]) - 400 * x[0] * (x[1] - x[0]**2), 200 * (x[1] - x[0]**2)]
def curv(x):   # the two curvatures (eigenvalues of the Hessian), largest first
    a, b, c = 1200 * x[0]**2 - 400 * x[1] + 2, -400 * x[0], 200.0
    m, r = (a + c) / 2, math.sqrt(((a - c) / 2)**2 + b * b)
    return m + r, m - r
def walk(x, alpha, steps, sign=1.0):   # x_{k+1} = x_k - alpha * grad f(x_k)
    path = [x]
    for _ in range(steps):
        g = grad(x)
        x = [x[0] - sign * alpha * g[0], x[1] - sign * alpha * g[1]]
        path.append(x)
    return path
def dist(x): return math.sqrt((x[0] - 1)**2 + (x[1] - 1)**2)
def reversals(p): return sum(1 for k in range(1, len(p) - 1) if (p[k][0] - p[k-1][0]) * (p[k+1][0] - p[k][0]) + (p[k][1] - p[k-1][1]) * (p[k+1][1] - p[k][1]) < 0)
def show(label, *v): print(f"{label:<44}" + " ".join(v))
F4 = lambda v: f"{v:.4f}".replace("-0.0000", "0.0000")

# ---- the valley and its certificate ----
x0, alpha, xs = [-1.2, 1.0], 0.001, [1.0, 1.0]
g0, h = grad(x0), 1e-6
cd = [(f([x0[0] + h, x0[1]]) - f([x0[0] - h, x0[1]])) / (2 * h), (f([x0[0], x0[1] + h]) - f([x0[0], x0[1] - h])) / (2 * h)]
show("start: height, gradient, distance", F4(f(x0)), F4(g0[0]), F4(g0[1]), F4(dist(x0)))
show("gradient by central differences", F4(cd[0]), F4(cd[1]))
L0, mu0 = curv(xs)
H = [[802.0, -400.0], [-400.0, 200.0]]   # Hessian at the bottom
scan = [H[0][0] * math.cos(t)**2 + 2 * H[0][1] * math.cos(t) * math.sin(t) + H[1][1] * math.sin(t)**2 for t in [i * math.pi / 3600 for i in range(3600)]]
show("bottom (1, 1): height, gradient", F4(f(xs)), F4(grad(xs)[0]), F4(grad(xs)[1]))
show("bottom curvatures: formula", F4(L0), F4(mu0))
show("bottom curvatures: 3600 directions scanned", F4(max(scan)), F4(min(scan)))
show("bottom: 1/L, 2/L, L/mu", f"{1 / L0:.7f}", f"{2 / L0:.7f}", f"{L0 / mu0:.1f}")

# ---- 200 steps at alpha = 0.001 ----
p = walk(x0, alpha, 200)
L = max(curv([p[k][0] + j / 10 * (p[k+1][0] - p[k][0]), p[k][1] + j / 10 * (p[k+1][1] - p[k][1])])[0] for k in range(200) for j in range(11))
gn = [grad(q)[0]**2 + grad(q)[1]**2 for q in p]
promise = [alpha * (1 - L * alpha / 2) * gn[k] for k in range(200)]
held = sum(1 for k in range(200) if f(p[k]) - f(p[k+1]) >= promise[k] > 0)
show("steepest curvature on the path L, 2/L", F4(L), f"{2 / L:.7f}")
show("step 1: point, height", F4(p[1][0]), F4(p[1][1]), F4(f(p[1])))
show("|grad|^2 at start, 1 - L alpha/2", F4(gn[0]), F4(1 - L * alpha / 2))
show("step 1: promised drop, actual drop", F4(promise[0]), F4(f(p[0]) - f(p[1])))
show("descent promise kept, of 200 steps", str(held))
show("height at steps 0 1 2 10 50 100 150 200", *[F4(f(p[k])) for k in (0, 1, 2, 10, 50, 100, 150, 200)])
show("step 200: point, distance to the bottom", F4(p[200][0]), F4(p[200][1]), F4(dist(p[200])))
bound = (f(x0) - 0.0) / (200 * alpha * (1 - L * alpha / 2))
show("smallest |grad|^2 in 200 steps, bound", F4(min(gn[:200])), F4(bound))
show("step reversals in 200 steps, step 0.001", str(reversals(p)))
show("step reversals, steps 0.0013 and 0.0017", str(reversals(walk(x0, 0.0013, 200))), str(reversals(walk(x0, 0.0017, 200))))

# ---- the long run, and the rate near the bottom ----
q, k, hit, logs = x0, 0, None, []
while k <= 18000:
    if k % 2000 == 0: logs.append(math.log10(f(q)))
    if hit is None and dist(q) < 1e-3: hit = k
    if k == 17000: fa = f(q)
    if k == 17001: fb = f(q)
    q, k = walk(q, alpha, 1)[1], k + 1
pred = (1 - alpha * mu0)**2
show("steps until within 0.001 of the bottom", str(hit))
show("log10 height every 2000 steps", *[f"{v:.2f}" for v in logs])
show("height ratio per step at 17000: measured", f"{fb / fa:.6f}")
show("predicted (1 - alpha mu)^2, proved bound", f"{pred:.6f}", f"{1 - 2 * mu0 * alpha * (1 - L0 * alpha / 2):.6f}")
show("steps for a tenfold drop", f"{math.log(10) / -math.log(pred):.0f}")

# ---- the stretched bowl: the banana's bottom, magnified ----
v = [(L0 - 200) / 400 * -1, 1.0]   # across direction (curvature L0), unnormalised
n = math.sqrt(v[0]**2 + v[1]**2); v = [v[0] / n, v[1] / n]; w = [-v[1], v[0]]   # w: along the floor
e0 = [-0.2, 0.0]   # start at (0.8, 1.0)
c0 = [e0[0] * v[0] + e0[1] * v[1], e0[0] * w[0] + e0[1] * w[1]]
show("bowl start: across, along", F4(c0[0]), F4(c0[1]))
for a in (0.001, 0.0015, 0.0019, 0.0021):
    e = e0
    for _ in range(50): e = [e[0] - a * (H[0][0] * e[0] + H[0][1] * e[1]), e[1] - a * (H[1][0] * e[0] + H[1][1] * e[1])]
    across = e[0] * v[0] + e[1] * v[1]
    assert abs(across - (1 - a * L0)**50 * c0[0]) < 1e-9 * max(1.0, abs(across))   # iteration = closed form
    show(f"step {a}: across, along, across at 50", F4(1 - a * L0), f"{1 - a * mu0:.6f}", F4(across))
show("step 0.0019: across error, steps 0 to 6", *[f"{(1 - 0.0019 * L0)**k * c0[0]:.4f}" for k in range(7)])

# ---- what breaks ----
show("step 0.002: height after step 1", F4(f(walk(x0, 0.002, 1)[1])))
show("far start (-2, 2): f, f after 1, L there", F4(f([-2.0, 2.0])), F4(f(walk([-2.0, 2.0], alpha, 1)[1])), F4(curv([-2.0, 2.0])[0]))
show("uphill sign: height after 3 steps", F4(f(walk(x0, alpha, 3, -1.0)[3])))
stop = next(k for k in range(1, 200) if f(p[k-1]) - f(p[k]) < 0.01)
show("stop when the drop < 0.01: step, distance", str(stop), F4(dist(p[stop])))
print("figure," + ",".join(f"{c:.4f}" for c in p[0] + p[1] + p[2] + p[200] + xs) + ",contours,25,4,1")

assert all(abs(g0[i] - cd[i]) < 1e-4 for i in range(2))                      # gradient formula vs differences
assert abs(max(scan) - L0) < 1e-3 and abs(min(scan) - mu0) < 1e-3              # curvature formula vs scan
assert held == 200 and min(gn[:200]) <= bound                                  # descent lemma and its sum
assert abs(fb / fa - pred) < 1e-5 and fb / fa <= 1 - 2 * mu0 * alpha * (1 - L0 * alpha / 2)   # the rate
assert hit is not None and dist(p[200]) > 1                                    # reaches the bottom; still far at 200
print("ALL CHECKS PASS")
