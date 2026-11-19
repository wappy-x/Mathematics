# Riemannian gradient descent -- the check behind the card.  Python standard library only.
# Exam scores in maths, physics and English; A is their covariance in points^2.  The weights w
# (unit length, a point on the sphere S^2) define one combined score.  f(w) is the mean squared
# distance, in points^2, of the students' score points from the line through the mean along w.
from math import sqrt, sin, cos, atan2, pi
A = [[225.0, 144.0, 45.0], [144.0, 144.0, 30.0], [45.0, 30.0, 100.0]]
TR = A[0][0] + A[1][1] + A[2][2]
def mv(v): return [A[i][0] * v[0] + A[i][1] * v[1] + A[i][2] * v[2] for i in range(3)]
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def norm(v): return sqrt(dot(v, v))
def add(a, b, t): return [a[i] + t * b[i] for i in range(3)]
def unit(v): n = norm(v); return [x / n for x in v]
def f(w): return TR - dot(w, mv(w))
def egrad(w): return [-2.0 * x for x in mv(w)]               # ordinary gradient of f in 3D
def proj(w, v): return add(v, w, -dot(w, v))                 # drop the part along w
def rgrad(w): return proj(w, egrad(w))                       # Riemannian gradient
def retract(w, v): return unit(add(w, v, 1.0))               # step in the plane, then rescale
def expmap(w, v):                                            # step along the great circle
    t = norm(v)
    return w if t == 0.0 else [cos(t) * w[i] + sin(t) * v[i] / t for i in range(3)]
def deg(x): return x * 180.0 / pi
def fmt(v): return "(" + ", ".join(f"{x:.6f}" for x in v) + ")"

def jacobi(M):                                               # road 2: eigen-solver by rotations
    a = [row[:] for row in M]; V = [[1.0 if i == j else 0.0 for j in range(3)] for i in range(3)]
    for _ in range(20):
        for p, q in ((0, 1), (0, 2), (1, 2)):
            if abs(a[p][q]) < 1e-14: continue
            th = (a[q][q] - a[p][p]) / (2.0 * a[p][q])
            t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(th * th + 1.0)); c = 1.0 / sqrt(t * t + 1.0); s = t * c
            for k in range(3): a[k][p], a[k][q] = c * a[k][p] - s * a[k][q], s * a[k][p] + c * a[k][q]
            for k in range(3): a[p][k], a[q][k] = c * a[p][k] - s * a[q][k], s * a[p][k] + c * a[q][k]
            for k in range(3): V[k][p], V[k][q] = c * V[k][p] - s * V[k][q], s * V[k][p] + c * V[k][q]
    order = sorted(range(3), key=lambda i: -a[i][i])
    vecs = [[V[k][i] for k in range(3)] for i in order]
    return [a[i][i] for i in order], [v if v[0] + v[1] + v[2] > 0 else [-x for x in v] for v in vecs]
lam, E = jacobi(A); e = E[0]
def err(w): return deg(atan2(norm(proj(e, w)), abs(dot(w, e))))   # angle from the answer, degrees

def descend(w, alpha, beta, n, step=retract, transport=True):
    d = [0.0, 0.0, 0.0]; path = [w]
    for _ in range(n):
        if transport: d = proj(w, d)                         # carry the old direction to T_w S^2
        d = add([-x for x in rgrad(w)], d, beta)              # downhill, plus beta times the old way
        w = step(w, [alpha * x for x in d]); path.append(w)
    return path

ALPHA, BETA, N = 0.001, 0.1, 30
w0 = unit([1.0, 1.0, 1.0])
print(f"total spread trace(A) = {TR:.0f} points^2; equal weights w0 = {fmt(w0)}")
sd = [sqrt(A[i][i]) for i in range(3)]
print(f"standard deviations {sd[0]:.0f} {sd[1]:.0f} {sd[2]:.0f} points; correlations {A[0][1] / (sd[0] * sd[1]):.2f} "
      f"{A[0][2] / (sd[0] * sd[2]):.2f} {A[1][2] / (sd[1] * sd[2]):.2f}; row sums of A {fmt(mv([1.0, 1.0, 1.0]))}, sqrt 3 = {sqrt(3.0):.6f}")
print(f"equal weights: index variance {dot(w0, mv(w0)):.3f}, f(w0) = {f(w0):.3f} points^2")
g = egrad(w0); r = rgrad(w0)
print(f"step 1: A w0 = {fmt(mv(w0))}")
print(f"step 1: ordinary gradient {fmt(g)}, part along w0 {dot(g, w0):.3f}")
print(f"step 1: Riemannian gradient {fmt(r)}, length {norm(r):.3f}, w0 . grad = {dot(w0, r):.1e}")
v = [-ALPHA * x for x in r]; u = add(w0, v, 1.0); w1 = retract(w0, v)
print(f"step 1: w0 - alpha grad = {fmt(u)}, length {norm(u):.6f}; retracted w1 = {fmt(w1)}")
gap1 = norm(add(expmap(w0, v), w1, -1.0))
print(f"step 1: f(w1) = {f(w1):.3f}; step length |v| = {norm(v):.6f}; exp map lands {gap1:.2e} from w1, |v|^3/3 = {norm(v) ** 3 / 3:.2e}")
assert abs(dot(w0, r)) < 1e-12 and f(w1) < f(w0) and 0.5 < gap1 / (norm(v) ** 3 / 3) < 1.5
print(f"road 2, eigen-solver: eigenvalues {lam[0]:.6f} {lam[1]:.6f} {lam[2]:.6f}; top eigenvector {fmt(e)}")
gd, hb = descend(w0, ALPHA, 0.0, N), descend(w0, ALPHA, BETA, N)
gx, hx = descend(w0, ALPHA, 0.0, N, expmap), descend(w0, ALPHA, BETA, N, expmap)
print("  k | plain: f, error deg | momentum: f, error deg | exp-map steps, momentum: error deg")
for k in (0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30):
    print(f"{k:3d} | {f(gd[k]):.6f} {err(gd[k]):.2e} | {f(hb[k]):.6f} {err(hb[k]):.2e} | {err(hx[k]):.2e}")
print("chart, plain:", " ".join(f"{f(w):.2f}" for w in gd[:11]))
print("chart, momentum:", " ".join(f"{f(w):.2f}" for w in hb[:11]))
first = lambda p: next(k for k, w in enumerate(p) if err(w) < 1e-6)
print(f"steps to within 1e-6 deg: plain {first(gd)}, momentum {first(hb)}, plain exp-map {first(gx)}, momentum exp-map {first(hx)}")
wb = hb[N]; mult = dot(wb, mv(wb)); res = norm(add(mv(wb), wb, -mult))
print(f"answer w* = {fmt(wb)}, f = {f(wb):.6f}, share of spread kept {100 * mult / TR:.2f}%")
print(f"Lagrange: A w* = lambda w* with lambda = {mult:.6f}, residual {res:.1e}")
assert err(gd[N]) < 1e-7 and err(hb[N]) < 1e-7 and err(hx[N]) < 1e-7 and abs(mult - lam[0]) < 1e-9 and res < 1e-8
assert max(abs(norm(w) - 1.0) for w in gx + hx) < 1e-12              # exp-map steps stay on the sphere
best = min(((f(unit([sin(i * pi / 900) * cos(j * pi / 900), sin(i * pi / 900) * sin(j * pi / 900), cos(i * pi / 900)])), i, j)
            for i in range(451) for j in range(1800)))
wg = unit([sin(best[1] * pi / 900) * cos(best[2] * pi / 900), sin(best[1] * pi / 900) * sin(best[2] * pi / 900), cos(best[1] * pi / 900)])
print(f"road 3, grid of 811,800 points, 0.2 deg apart in both angles: best f = {best[0]:.6f}, {err(wg):.4f} deg from w*")
assert abs(best[0] - f(wb)) < 1e-2 and err(wg) < 0.2
hess = [2 * (lam[0] - lam[1]), 2 * (lam[0] - lam[2])]; pred = 1 - ALPHA * hess[0]
print(f"Riemannian Hessian at w*: {hess[0]:.3f} {hess[1]:.3f}; step limit 2/L = {2 / hess[1]:.6f}")
ratio = err(gd[12]) / err(gd[11])
print(f"rate: predicted error factor per step {pred:.6f}, measured {ratio:.6f}")
assert abs(ratio - pred) < 1e-3
# what breaks
p = [w0]
for _ in range(N): p.append(add(p[-1], egrad(p[-1]), -ALPHA))
print(f"mistake, no projection, no retraction: after {N} steps |w| = {norm(p[-1]):.4e}, f = {f(p[-1]):.4e}")
q = [w0]
for _ in range(N): x = q[-1]; g = egrad(x); q.append(add(x, add(g, x, -dot(x, g) / dot(x, x)), -ALPHA))
print(f"mistake, project but never retract: |w| = {norm(q[-1]):.6f}, f = {f(q[-1]):.3f}, true f there {f(unit(q[-1])):.3f}")
assert norm(p[-1]) > 1e6 and f(q[-1]) < f(wb) - 1 and norm(q[-1]) > 1.01
big = descend(w0, 0.004, 0.0, 200)
print(f"mistake, step 0.004 above the limit: steps 199 and 200 bounce between {fmt(big[199])} and {fmt(big[200])},"
      f" f = {f(big[199]):.3f} and {f(big[200]):.3f}, {err(big[199]):.2f} and {err(big[200]):.2f} deg from w*")
assert err(big[200]) > 10 and err(big[199]) > 10
d1 = [-x for x in r]; tilt = deg(atan2(abs(dot(hb[1], d1)), norm(proj(hb[1], d1))))
nt = descend(w0, ALPHA, BETA, N, expmap, False); drift = max(abs(norm(w) - 1) for w in nt)
print(f"mistake, no transport: old direction sits {tilt:.2f} deg out of the new tangent plane; with exp-map steps"
      f" |w| strays by up to {drift:.2e}, {first(nt)} steps to within 1e-6 deg")
assert tilt > 5 and drift > 1e-6
e2 = E[1]; s2 = descend(e2, ALPHA, BETA, 20)
print(f"hypothesis fails, start on a critical point (2nd eigenvector): f stays {f(s2[0]):.3f} -> {f(s2[20]):.3f}")
assert abs(f(s2[20]) - (TR - lam[1])) < 1e-6
# try changing
t1, t2, t3 = first(descend(w0, ALPHA, 0.3, 80)), first(descend(w0, 0.0005, 0.0, 120)), first(descend([0.0, 0.0, 1.0], ALPHA, BETA, 80))
print(f"try: momentum 0.3 needs {t1} steps; plain step 0.0005 needs {t2}; English-only start (0, 0, 1) needs {t3}")
print("ALL CHECKS PASS")
