import math
def f(p): return (1 - p[0])**2 + 100 * (p[1] - p[0]**2)**2
def grad(p):
    u, v = p
    return (-2 * (1 - u) - 400 * u * (v - u * u), 200 * (v - u * u))
def hess(p):
    u, v = p
    return (2 - 400 * v + 1200 * u * u, -400 * u + 0.0, 200.0)
def solve(a, b, c, r):  # [[a, b], [b, c]] d = r, by elimination
    m = b / a
    d2 = (r[1] - m * r[0]) / (c - m * b)
    return ((r[0] - b * d2) / a, d2)
def lam_min(a, b, c): return (a + c) / 2 - math.sqrt(((a - c) / 2)**2 + b * b)
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def norm(u): return math.sqrt(dot(u, u))
def step(p, d, t): return (p[0] + t * d[0], p[1] + t * d[1])
def err(p): return norm((p[0] - 1, p[1] - 1))
def newton(p, delta=1e-3, tol=1e-8, search=True, modify=True, cap=1000):
    rows = []
    for k in range(cap):
        g = grad(p)
        a, b, c = hess(p)
        tau = max(0.0, delta - lam_min(a, b, c)) if modify else 0.0
        if norm(g) < tol:
            return rows + [(k, p, f(p), norm(g), tau, 0.0)]
        d = solve(a + tau, b, c + tau, (-g[0], -g[1]))
        t = 1.0
        while search and f(step(p, d, t)) > f(p) + 1e-4 * t * dot(g, d): t /= 2
        rows.append((k, p, f(p), norm(g), tau, t))
        p = step(p, d, t)
    return rows
def wolfe(p, d, g):  # weak Wolfe by bisection, c1 = 0.0001, c2 = 0.9
    lo, hi, t = 0.0, math.inf, 1.0
    for _ in range(60):
        if f(step(p, d, t)) > f(p) + 1e-4 * t * dot(g, d): hi = t
        elif dot(grad(step(p, d, t)), d) < 0.9 * dot(g, d): lo = t
        else: break
        t = (lo + hi) / 2 if hi < math.inf else 2 * t
    return t
def bfgs_update(B, s, y):
    Bs = (B[0] * s[0] + B[1] * s[1], B[1] * s[0] + B[2] * s[1])
    sBs, sy = dot(s, Bs), dot(s, y)
    return (B[0] - Bs[0] * Bs[0] / sBs + y[0] * y[0] / sy,
            B[1] - Bs[0] * Bs[1] / sBs + y[0] * y[1] / sy,
            B[2] - Bs[1] * Bs[1] / sBs + y[1] * y[1] / sy)
def bfgs(p, tol=1e-8, learn=True, cap=50000):
    B, errs, worst = (1.0, 0.0, 1.0), [], 0.0
    for k in range(cap):
        g = grad(p)
        errs.append(err(p))
        if norm(g) < tol: break
        d = solve(B[0], B[1], B[2], (-g[0], -g[1]))
        q = step(p, d, wolfe(p, d, g))
        s, y = (q[0] - p[0], q[1] - p[1]), (grad(q)[0] - g[0], grad(q)[1] - g[1])
        if learn:
            B = bfgs_update(B, s, y)
            worst = max(worst, norm((B[0] * s[0] + B[1] * s[1] - y[0], B[1] * s[0] + B[2] * s[1] - y[1])) / norm(y))
        p = q
    return k, p, B, errs, worst

# Road 1: modified Newton with Armijo backtracking, from (0, 1)
start = (0.0, 1.0)
a, b, c = hess(start)
print(f"start (0, 1): f = {f(start):.0f}, gradient ({grad(start)[0]:.0f}, {grad(start)[1]:.0f})")
print(f"Hessian at start [[{a:.0f}, {b:.0f}], [{b:.0f}, {c:.0f}]], lowest curvature {lam_min(a, b, c):.0f}")
tau0 = 1e-3 - lam_min(a, b, c)
d0 = solve(a + tau0, b, c + tau0, (-grad(start)[0], -grad(start)[1]))
print(f"shifted by tau = {tau0:.3f}: [[{a + tau0:.3f}, {b:.0f}], [{b:.0f}, {c + tau0:.3f}]], step d = ({d0[0]:.0f}, {d0[1]:.3f})")
rows = newton(start)
print(" k         u          v          f     |grad|       tau     alpha")
for k, p, fv, gn, tau, t in rows:
    frac = "-" if t == 0 else "1" if t == 1 else f"1/{round(1 / t)}"
    print(f"{k:2d} {p[0]:10.6f} {p[1]:10.6f} {fv:10.3e} {gn:9.2e} {tau:9.3f} {frac:>9}")
ne = [err(r[1]) for r in rows]
print("Newton e(k+1)/e(k)^2, k = 4..7:" + "".join(f" {ne[k + 1] / ne[k]**2:.2f}" for k in range(4, 8)))
# Road 2: the certificate at (1, 1): f is a sum of two squares, so f >= 0 = f(1, 1)
a, b, c = hess((1.0, 1.0))
print(f"Hessian at (1, 1) [[{a:.0f}, {b:.0f}], [{b:.0f}, {c:.0f}]], det {a * c - b * b:.0f}, lowest curvature {lam_min(a, b, c):.4f}")
# Road 3: BFGS with weak Wolfe steps, from the same start, B_0 = identity
nb, pb, B, be, worst = bfgs(start)
print(f"BFGS steps {nb}, final ({pb[0]:.10f}, {pb[1]:.10f}), worst secant miss {worst:.1e}")
print("BFGS e(k+1)/e(k), last five:" + "".join(f" {be[k + 1] / be[k]:.4f}" for k in range(nb - 5, nb)))
print(f"BFGS remembered B [[{B[0]:.1f}, {B[1]:.1f}], [{B[1]:.1f}, {B[2]:.1f}]] vs true [[802, -400], [-400, 200]]")
# Road 4: derivatives against central differences
h, worst_g, worst_h = 1e-5, 0.0, 0.0
for p in (start, (0.7, 0.5), (1.2, 1.3)):
    for i in range(2):
        up, dn = list(p), list(p); up[i] += h; dn[i] -= h
        worst_g = max(worst_g, abs((f(up) - f(dn)) / (2 * h) - grad(p)[i]))
        col = [(grad(up)[j] - grad(dn)[j]) / (2 * h) for j in range(2)]
        worst_h = max(worst_h, abs(col[0] - hess(p)[i]), abs(col[1] - hess(p)[i + 1]))
print(f"central difference miss: gradient {worst_g:.1e}, Hessian {worst_h:.1e}")
# Road 5: on a quadratic with exact line search, BFGS learns A in two steps
A, rhs, x, Bq = (3.0, 1.0, 2.0), (1.0, 1.0), (0.0, 0.0), (1.0, 0.0, 1.0)
for _ in range(2):
    g = (A[0] * x[0] + A[1] * x[1] - rhs[0], A[1] * x[0] + A[2] * x[1] - rhs[1])
    d = solve(Bq[0], Bq[1], Bq[2], (-g[0], -g[1]))
    t = -dot(g, d) / dot(d, (A[0] * d[0] + A[1] * d[1], A[1] * d[0] + A[2] * d[1]))
    s = (t * d[0], t * d[1])
    Bq, x = bfgs_update(Bq, s, (A[0] * s[0] + A[1] * s[1], A[1] * s[0] + A[2] * s[1])), step(x, s, 1.0)
print(f"quadratic: x_2 = ({x[0]:.6f}, {x[1]:.6f}), B_2 = [[{Bq[0]:.6f}, {Bq[1]:.6f}], [{Bq[1]:.6f}, {Bq[2]:.6f}]]")
# What breaks
p = (0.7, 0.5); g = grad(p); a, b, c = hess(p)
dp = solve(a, b, c, (-g[0], -g[1]))
dm = solve(a + 1e-3 - lam_min(a, b, c), b, c + 1e-3 - lam_min(a, b, c), (-g[0], -g[1]))
print(f"break: pure Newton at (0.7, 0.5), lowest curvature {lam_min(a, b, c):.4f}, slope along step {dot(g, dp):+.2f}, f {f(p):.2f} -> {f(step(p, dp, 1)):.2f}")
print(f"  modified step there: slope along step {dot(g, dm):+.2f}")
n10 = len(newton(start, delta=10.0)) - 1
print(f"break: floor delta = 10 instead of 0.001, Newton steps {n10}")
wild = newton(start, search=False, cap=2)
print(f"break: shift but no line search, first step lands at u = {wild[1][1][0]:.0f}, f = {wild[1][2]:.3e}")
ngd = bfgs(start, learn=False)[0]
print(f"break: B never updated (gradient descent with Wolfe), steps {ngd}")
pa = (-1.2, 1.0)                                 # BFGS fed an Armijo-only step: descent to step 30, as on Line search
for _ in range(31):
    ga, t = grad(pa), 1.0
    while f(step(pa, ga, -t)) > f(pa) - 1e-4 * t * dot(ga, ga): t /= 2
    qa, pa = pa, step(pa, ga, -t)
sa, ya = (pa[0] - qa[0], pa[1] - qa[1]), (grad(pa)[0] - ga[0], grad(pa)[1] - ga[1])
Ba, gn = bfgs_update((1.0, 0.0, 1.0), sa, ya), grad(pa)
print(f"break: BFGS fed an Armijo-only step at step 30 from (-1.2, 1): s.y {dot(sa, ya):.2f}, next slope {dot(gn, solve(Ba[0], Ba[1], Ba[2], (-gn[0], -gn[1]))):+.2f}")
# Try changing
print(f"try: start (-1.2, 1): Newton {len(newton((-1.2, 1.0))) - 1}, BFGS {bfgs((-1.2, 1.0))[0]}")
raw = newton(start, search=False, modify=False)
print(f"try: pure Newton from (0, 1), no shift, no search: steps {len(raw) - 1}, highest f after the start {max(r[2] for r in raw[1:]):.2f}")
print(f"try: tolerance 1e-12: Newton {len(newton(start, tol=1e-12)) - 1}, BFGS {bfgs(start, tol=1e-12)[0]}")
print("figure, Newton path" + "".join(f" ({r[1][0]:.3f}, {r[1][1]:.3f})" for r in rows[:5]))
print("figure, pure Newton path" + "".join(f" ({r[1][0]:.3f}, {r[1][1]:.3f})" for r in raw[:4]))

assert len(rows) - 1 == 8 and err(rows[-1][1]) < 1e-9, "Newton reaches (1, 1) in eight steps"
assert err(pb) < 1e-8 and nb == 27, "BFGS reaches the same floor"
assert a * c - b * b < 0 and dot(g, dp) > 0 and f(step(p, dp, 1)) > f(p), "pure Newton climbs at an indefinite point"
assert dot(g, dm) < 0, "the modified step points downhill"
assert worst < 1e-10, "every BFGS matrix satisfies the secant equation B s = y"
assert max(abs(B[0] - 802) / 802, abs(B[1] + 400) / 400, abs(B[2] - 200) / 200) < 0.01, "BFGS memory near the true Hessian"
assert worst_g < 1e-4 and worst_h < 1e-3, "analytic derivatives match central differences"
assert abs(x[0] - 0.2) < 1e-12 and abs(x[1] - 0.4) < 1e-12, "quadratic minimiser by Cramer: (2 - 1, 3 - 1) / 5"
assert max(abs(Bq[0] - 3), abs(Bq[1] - 1), abs(Bq[2] - 2)) < 1e-12, "BFGS recovers A after two exact steps"
assert ne[7] / ne[6]**2 < 20 and be[nb] / be[nb - 1] < 0.01, "quadratic for Newton, superlinear for BFGS"
print("ALL CHECKS PASS")
