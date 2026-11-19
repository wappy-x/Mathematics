# Riemannian Hessian -- the check behind the card.  Standard library only.
# A rank-1 music recommender: 4 listeners rate 3 songs (matrix M).  The taste
# direction x is a unit vector, a point on the sphere S^2.  Its error is
# f(x) = |M|^2 - x^T C x with C = M^T M.  A trust region minimises f using the
# Riemannian Hessian, steps in the tangent plane and returns by a retraction.
from math import sqrt, cos, sin, atan2, pi, hypot
M = [[5, 4, 1], [4, 5, 2], [1, 2, 5], [2, 1, 4]]
C = [[sum(r[i] * r[j] for r in M) for j in range(3)] for i in range(3)]
TOT = sum(v * v for r in M for v in r)
def dot(a, b): return sum(p * q for p, q in zip(a, b))
def Cv(v): return [dot(r, v) for r in C]
def comb(a, x, b, y): return [a * p + b * q for p, q in zip(x, y)]
def z(v): return 0.0 if abs(v) < 5e-5 else v      # print -0.0000 as 0.0000
def unit(v): return [c / sqrt(dot(v, v)) for c in v]
def f(x): return TOT - dot(x, Cv(x))            # the formula, used on all of R^3
def proj(x, u): return comb(1, u, -dot(x, u), x)  # P_x u = u - (x.u) x
def egrad(x): return [-2 * c for c in Cv(x)]      # ordinary gradient in R^3
def rgrad(x): return proj(x, egrad(x))
def rhess(x, v, curv=True):                       # P_x(-2 C v) - (x . egrad) v
    return comb(1, proj(x, [-2 * c for c in Cv(v)]), -dot(x, egrad(x)) if curv else 0.0, v)
def basis(x):                                     # two orthonormal tangent vectors
    out = []
    for e in ([1.0, 0, 0], [0, 1.0, 0], [0, 0, 1.0]):
        w = proj(x, e)
        for b in out: w = comb(1, w, -dot(w, b), b)
        if len(out) < 2 and sqrt(dot(w, w)) > 0.3: out.append(unit(w))
    return out
def model(x, curv=True):
    E = basis(x)
    g = [dot(e, rgrad(x)) for e in E]
    H = [[dot(E[i], rhess(x, E[j], curv)) for j in range(2)] for i in range(2)]
    return E, g, H
def eig2(H):
    m, d = (H[0][0] + H[1][1]) / 2, hypot((H[0][0] - H[1][1]) / 2, H[0][1])
    return m - d, m + d
def solve2(H, g, lam):                            # (H + lam I) s = -g
    a, b, c = H[0][0] + lam, H[0][1], H[1][1] + lam
    return [-(c * g[0] - b * g[1]) / (a * c - b * b), -(a * g[1] - b * g[0]) / (a * c - b * b)]
def subproblem(H, g, D):                          # exact lowest point of the model in the disc
    lo = eig2(H)[0]
    if lo > 0 and hypot(*solve2(H, g, 0)) <= D: return solve2(H, g, 0)
    a, b = max(0.0, -lo) + 1e-12, max(0.0, -lo) + 1e6
    for _ in range(200):
        m = (a + b) / 2
        if hypot(*solve2(H, g, m)) > D: a = m
        else: b = m
    return solve2(H, g, b)
def tangent_step(E, g, H, D):
    s = subproblem(H, g, D)
    return comb(s[0], E[0], s[1], E[1])
def promise(g, H, s): return -(dot(g, s) + 0.5 * dot(s, [dot(H[0], s), dot(H[1], s)]))
def retract(x, v): return unit(comb(1, x, 1, v))
def geodesic(x, v, t):                            # great circle through x along v
    n = sqrt(dot(v, v))
    return comb(cos(t * n), x, sin(t * n) / n, v)
def tr_run(x, D, curv=True, eta=0.1, cap=3.0, kmax=30, quiet=False):
    tries, refused = 0, 0
    for k in range(kmax):
        E, g, H = model(x, curv)
        if hypot(*g) < 1e-8: break
        s = subproblem(H, g, D)
        v = comb(s[0], E[0], s[1], E[1])
        pred, act = promise(g, H, s), f(x) - f(retract(x, v))
        rho = act / pred
        ok = rho > eta or pred < 1e-6                         # a fall below 1e-6 is rounding noise
        tries, refused = tries + 1, refused + (not ok)
        if not quiet and pred > 1e-6:                         # below that, rounding decides rho
            print(f"{k:2d} {f(x):10.6f} {D:5.3f} {hypot(*s):8.6f} {pred:11.6f} {act:10.6f} {rho:7.4f} {1 / (1 + dot(s, s)):7.4f} {'keep' if ok else 'refuse'}")
            assert abs(rho - 1 / (1 + dot(s, s))) < 1e-9          # the closed form of Step 3
        elif not quiet: print(f"{k:2d} {f(x):10.6f} {D:5.3f} {hypot(*s):8.6f}  promised fall below 1e-6: {'keep' if ok else 'refuse'}")
        if ok: x = retract(x, v)
        if rho < 0.25: D /= 4
        elif rho > 0.75 and abs(hypot(*s) - D) < 1e-9: D = min(2 * D, cap)
    return x, tries, refused, hypot(*model(x)[1])
def jacobi(A):                                    # eigenvalues and vectors of symmetric 3x3
    a, V = [r[:] for r in A], [[float(i == j) for j in range(3)] for i in range(3)]
    for _ in range(30):
        for p, q in ((0, 1), (0, 2), (1, 2)):
            if abs(a[p][q]) < 1e-14: continue
            t = 0.5 * atan2(2 * a[p][q], a[q][q] - a[p][p]); c, s = cos(t), sin(t)
            for k in range(3): a[k][p], a[k][q] = c * a[k][p] - s * a[k][q], s * a[k][p] + c * a[k][q]
            for k in range(3): a[p][k], a[q][k] = c * a[p][k] - s * a[q][k], s * a[p][k] + c * a[q][k]
            for k in range(3): V[k][p], V[k][q] = c * V[k][p] - s * V[k][q], s * V[k][p] + c * V[k][q]
    pairs = sorted(((a[i][i], [V[k][i] for k in range(3)]) for i in range(3)), reverse=True)
    return [p[0] for p in pairs], [unit(p[1]) if p[1][0] + p[1][1] + p[1][2] > 0 else [-c for c in p[1]] for p in pairs]
# ---- the data and the start: all weight on song 3 ----
print(f"C = M^T M rows: {C[0]}, {C[1]}, {C[2]}; |M|^2 = {TOT}")
x0 = [0.0, 0.0, 1.0]
E, g, H = model(x0)
Hflat = model(x0, curv=False)[2]
print(f"start x0 = (0, 0, 1): f = {f(x0):.6f}, ordinary gradient ({egrad(x0)[0]:.1f}, {egrad(x0)[1]:.1f}, {egrad(x0)[2]:.1f}), radial part x.grad = {dot(x0, egrad(x0)):.1f}")
print(f"grad f = ({g[0]:.1f}, {g[1]:.1f}); projected part {Hflat[0][0]:.1f}, {Hflat[0][1]:.1f}, {Hflat[1][1]:.1f}; curvature term +{-dot(x0, egrad(x0)):.1f}")
print(f"Hess f at x0 = [[{H[0][0]:.1f}, {H[0][1]:.1f}], [{H[1][0]:.1f}, {H[1][1]:.1f}]], eigenvalues {eig2(H)[0]:.4f}, {eig2(H)[1]:.4f}; flat part alone {eig2(Hflat)[0]:.4f}, {eig2(Hflat)[1]:.4f}")
# ---- road 1: second derivative along great circles and along the retraction ----
h = 1e-4
for v in ([1.0, 0, 0], [0, 1.0, 0], [1.0, 1.0, 0], [1.0, -2.0, 0]):
    geo = (f(geodesic(x0, v, h)) - 2 * f(x0) + f(geodesic(x0, v, -h))) / h ** 2
    ret = (f(retract(x0, [h * c for c in v])) - 2 * f(x0) + f(retract(x0, [-h * c for c in v]))) / h ** 2
    form = dot(v, rhess(x0, v))
    assert abs(geo - form) < 1e-4 and abs(ret - form) < 1e-4
    print(f"v = ({v[0]:.0f}, {v[1]:.0f}, 0): <v, Hess v> = {z(form):9.4f}; great circle {z(geo):9.4f}; retraction {z(ret):9.4f}")
sN = solve2(H, g, 0)
print(f"pure Newton step: length {hypot(*sN):.6f}, f goes 92 -> {f(retract(x0, comb(sN[0], E[0], sN[1], E[1]))):.6f}")
s1 = subproblem(H, g, 1.0)
v1 = comb(s1[0], E[0], s1[1], E[1])
print(f"radius-1 step v = ({v1[0]:.6f}, {v1[1]:.6f}, {v1[2]:.6f}); x0 + v off the sphere: f = {f(comb(1, x0, 1, v1)):.6f}, |x0 + v| = {sqrt(dot(comb(1, x0, 1, v1), comb(1, x0, 1, v1))):.6f}")
print("chart, radius 0.25 to 2.00, promised: " + ", ".join(f"{promise(g, H, subproblem(H, g, 0.25 * i)):.2f}" for i in range(1, 9)))
print("chart, radius 0.25 to 2.00, delivered: " + ", ".join(f"{f(x0) - f(retract(x0, tangent_step(E, g, H, 0.25 * i))):.2f}" for i in range(1, 9)))
# ---- the run, radius 1, eta 0.1 ----
print(" k          f     D     step    promised  delivered     rho 1/(1+s^2)")
xs, tries, refused, gend = tr_run(x0, 1.0)
lam, vec = jacobi(C)
print(f"end x* = ({xs[0]:.6f}, {xs[1]:.6f}, {xs[2]:.6f}), f = {f(xs):.6f}, after {tries} tries, slope below 1e-8: {gend < 1e-8}")
print(f"eigen-solver: lambda = {lam[0]:.6f}, {lam[1]:.6f}, {lam[2]:.6f}; top vector ({vec[0][0]:.6f}, {vec[0][1]:.6f}, {vec[0][2]:.6f}); |M|^2 - lambda1 = {TOT - lam[0]:.6f}")
assert abs(f(xs) - (TOT - lam[0])) < 1e-9 and max(abs(p - q) for p, q in zip(xs, vec[0])) < 1e-8
print(f"rms error per rating {sqrt(f(xs) / 12):.4f} stars; share of |M|^2 captured {lam[0] / TOT:.4f}; listener 1 predicted " + ", ".join(f"{dot(M[0], xs) * c:.2f}" for c in xs))
Hs, Hsf = model(xs)[2], model(xs, curv=False)[2]
print(f"Hess f at x*: eigenvalues {eig2(Hs)[0]:.4f}, {eig2(Hs)[1]:.4f}; 2(l1-l2), 2(l1-l3) = {2 * (lam[0] - lam[1]):.4f}, {2 * (lam[0] - lam[2]):.4f}")
assert abs(eig2(Hs)[0] - 2 * (lam[0] - lam[1])) < 1e-6 and abs(eig2(Hs)[1] - 2 * (lam[0] - lam[2])) < 1e-6
print(f"flat part alone at x*: {eig2(Hsf)[0]:.4f}, {eig2(Hsf)[1]:.4f}; curvature term +{2 * lam[0]:.4f}")
# ---- what breaks ----
_, t2, r2, g2 = tr_run(x0, 1.0, curv=False, kmax=10, quiet=True)
print(f"no curvature term: after {t2} tries, {r2} refused, slope still {g2:.4f}")
Hv = model(vec[1])[2]
print(f"saddle (song mix 5, 4, -11): slope below 1e-8: {hypot(*model(vec[1])[1]) < 1e-8}, Hess eigenvalues {eig2(Hv)[0]:.4f}, {eig2(Hv)[1]:.4f}")
assert abs(eig2(Hv)[0] - 2 * (lam[1] - lam[0])) < 1e-6 and eig2(Hv)[1] > 0 and abs(abs(dot(vec[1], [5, 4, -11])) - sqrt(162)) < 1e-9
print("convexity along the great circle x* -> saddle, lowest Hess eigenvalue:")
for deg in (0, 15, 30, 45, 60):
    t = deg * pi / 180
    print(f"  {deg:2d} deg: {z(eig2(model(comb(cos(t), vec[0], sin(t), vec[1]))[2])[0]):9.4f}   2(l1-l2)cos(2t) = {z(2 * (lam[0] - lam[1]) * cos(2 * t)):9.4f}")
(xe, te, _, _), ts, s2 = tr_run([1.0, 0, 0], 1.0, quiet=True), tr_run(vec[1], 1.0, quiet=True)[1], subproblem(H, g, 2.0)
print(f"try: radius 2 first ratio {(f(x0) - f(retract(x0, tangent_step(E, g, H, 2.0)))) / promise(g, H, s2):.4f}; start (1, 0, 0): f = {f([1.0, 0, 0]):.6f} -> {f(xe):.6f} after {te} tries; start at the saddle: {ts} tries")
print("ALL CHECKS PASS")
