# Conjugate gradient, the card's check. Standard library only: every product, step and elimination is written out.
from math import sqrt, log10, cos, pi
def dot(u, v):                                  # a plain loop, so Python and Rust add in the same order
    s = 0.0
    for a, b in zip(u, v): s += a * b
    return s
def cg(Av, b, x, tol, bmul=1.0, keep=0):
    # Solve A x = b, i.e. minimise f(x) = 1/2 x.Ax - b.x, knowing A only as the rule Av(v).
    r = [bi - qi for bi, qi in zip(b, Av(x))]   # residual b - Ax = minus the gradient
    p, rr, steps, dirs = r[:], dot(r, r), [], []
    r0, hist = sqrt(rr), [1.0]
    while sqrt(rr) / r0 > tol and len(steps) < 20000:
        Ap = Av(p); pAp = dot(p, Ap)
        if len(dirs) < keep: dirs.append((p, Ap))   # kept only to test conjugacy
        a = rr / pAp                            # exact step to the lowest point along p
        x = [xi + a * pi_ for xi, pi_ in zip(x, p)]
        r = [ri - a * qi for ri, qi in zip(r, Ap)]; rn = dot(r, r)
        beta = bmul * rn / rr                   # bmul = 0: gradient descent with exact steps
        steps.append((p[0], p[1], pAp, a, x[0], x[1], r[0], r[1], beta))
        p, rr = [ri + beta * pi_ for ri, pi_ in zip(r, p)], rn
        hist.append(sqrt(rr) / r0)
    return x, steps, hist, dirs
def f2(A, b, x):                                # f = 1/2 x.Ax - b.x for a 2 by 2 example
    return 0.5 * dot(x, [dot(A[0], x), dot(A[1], x)]) - dot(b, x)

# ---- by hand: two readings, 18 and 15 C, weight w = 1, start from a flat 15 C ----
A2, y2 = [[2.0, -1.0], [-1.0, 2.0]], [18.0, 15.0]
mv2 = lambda v: [dot(A2[0], v), dot(A2[1], v)]
x2, st2, _, _ = cg(mv2, y2, [15.0, 15.0], 1e-12); sd2 = cg(mv2, y2, [15.0, 15.0], 1e-12, bmul=0.0)[1]
fstar = f2(A2, y2, [17.0, 16.0])                # the answer from A's inverse, (1/3)[[2, 1], [1, 2]] y
print(f"hand: start (15, 15), residual (3, 0), gap f - f* {f2(A2, y2, [15.0, 15.0]) - fstar:.4f},"
      f" conjugacy d1.Ad0 {dot(st2[1][:2], mv2(st2[0][:2])):.4f}")
for k, s in enumerate(st2):
    print(f"hand cg k={k}: r.r {s[3] * s[2]:.4f} p ({s[0]:.4f}, {s[1]:.4f}) Ap ({mv2(s[:2])[0]:.4f}, {mv2(s[:2])[1]:.4f})"
          f" pAp {s[2]:.4f} alpha {s[3]:.4f} -> x ({s[4]:.4f}, {s[5]:.4f})"
          f" r ({s[6]:.4f}, {s[7]:.4f}) beta {s[8]:.4f}\n            gap {f2(A2, y2, [s[4], s[5]]) - fstar:.4f}")
print("hand gd:", " ".join(f"({s[4]:.4f}, {s[5]:.4f})" for s in sd2[:5]),
      "gaps", " ".join(f"{f2(A2, y2, [s[4], s[5]]) - fstar:.4f}" for s in sd2[:5]), f"steps to 1e-12: {len(sd2)}")
print("figure, centre (17, 16), long axis along (1, 1); semi-axes sqrt(2c), sqrt(2c/3) at gap c:",
      ", ".join(f"c={c:g} {sqrt(2 * c):.4f} {sqrt(2 * c / 3):.4f}" for c in (3.0, 0.75, 0.1875)))
assert len(st2) == 2 and abs(x2[0] - 17.0) < 1e-12 and abs(x2[1] - 16.0) < 1e-12   # exact in n = 2 steps
assert abs(dot(st2[1][:2], mv2(st2[0][:2]))) < 1e-12                                # the two moves are conjugate
assert len(sd2) > 20                                                                # gradient descent never lands

# ---- the card's example: 1000 thermometer readings, smoothing weight w = 25 ----
n, w, MASK = 1000, 25.0, (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, z ^ (z >> 31)
seed, y = 2026, []
for i in range(n):                              # true warming 15 -> 25 C, plus up to 1 C of noise
    seed, z = splitmix(seed)
    y.append(15.0 + 0.01 * i + 2.0 * ((z >> 11) / 2.0**53 - 0.5))
def Av(v):                                      # (I + w L) v, without storing a 1000 by 1000 matrix
    return [v[i] + (w * (v[i] - v[i - 1]) if i > 0 else 0.0) + (w * (v[i] - v[i + 1]) if i < n - 1 else 0.0)
            for i in range(n)]
def fsm(x):                                     # misfit to the readings + w times the jumps
    e, j = [a - b for a, b in zip(x, y)], [x[i + 1] - x[i] for i in range(n - 1)]
    return 0.5 * dot(e, e) + 0.5 * w * dot(j, j)
start = [15.0] * n
x, st, hist, dirs = cg(Av, y, start, 1e-8, keep=n)
xg, sts, hists, _ = cg(Av, y, start, 1e-8, bmul=0.0)
# road 2: elimination on the three-diagonal system (forward sweep, then back substitution)
c, d, xe = [0.0] * n, [0.0] * n, [0.0] * n
for i in range(n):
    diag = 1.0 + w * ((i > 0) + (i < n - 1)) + (w * c[i - 1] if i > 0 else 0.0)
    c[i] = -w / diag
    d[i] = (y[i] + (w * d[i - 1] if i > 0 else 0.0)) / diag
for i in range(n - 1, -1, -1):
    xe[i] = d[i] - (c[i] * xe[i + 1] if i < n - 1 else 0.0)
res = [bi - qi for bi, qi in zip(y, Av(x))]
gap_ce = max(abs(a - b) for a, b in zip(x, xe))
acos = [max(abs(dot(dirs[i][0], dirs[j][1])) / sqrt(dot(dirs[i][0], dirs[i][1]) * dot(dirs[j][0], dirs[j][1]))
            for j in range(i)) for i in range(1, len(dirs))]   # worst A-cosine of each direction with the earlier ones
kappa = 1.0 + w * (2.0 + 2.0 * cos(pi / n))    # largest eigenvalue L over smallest, mu = 1
rate_cg, rate_gd = (sqrt(kappa) - 1) / (sqrt(kappa) + 1), (kappa - 1) / (kappa + 1)
ea = lambda u: sqrt(dot([a - b for a, b in zip(u, xe)], Av([a - b for a, b in zip(u, xe)])))   # error in the bowl's units
mcg, mgd = (ea(x) / ea(start)) ** (1 / len(st)), (ea(xg) / ea(start)) ** (1 / len(sts))
def rms(u):                                     # root-mean-square distance from the true warming
    e = [u[i] - (15.0 + 0.01 * i) for i in range(n)]
    return sqrt(dot(e, e) / n)
print(f"smoother: steps cg {len(st)}  gradient descent {len(sts)}  numbers held {4 * n} vs matrix {n * n}")
print(f"smoother: f start {fsm(start):.4f}  f cg {fsm(x):.6f}  f elimination {fsm(xe):.6f}")
print(f"smoother: minute 0 {y[0]:.3f} -> {x[0]:.3f}  minute 500 {y[500]:.3f} -> {x[500]:.3f}  minute 999 {y[999]:.3f} -> {x[999]:.3f}")
print(f"smoother: rms error against the true warming, readings {rms(y):.3f}  smoothed {rms(x):.3f}")
print(f"smoother: log10 |residual| {log10(sqrt(dot(res, res))):.2f}  log10 max |cg - elimination| {log10(gap_ce):.2f}")
print(f"smoother: log10 worst A-cosine, first 20 directions {log10(max(acos[:19])):.2f}, all {len(dirs)} {log10(max(acos)):.2f}")
print(f"smoother: kappa {kappa:.2f}  bound per step cg {rate_cg:.4f} gd {rate_gd:.4f}  measured cg {mcg:.4f} gd {mgd:.4f}")
print("chart, k  ", " ".join(f"{k:>6d}" for k in range(0, 80, 10)))
for lab, hh in (("cg ", hist), ("gd ", hists)): print("chart, " + lab, " ".join(f"{log10(hh[k]):6.2f}" for k in range(0, 80, 10)))
assert gap_ce < 1e-6 and gap_ce <= sqrt(dot(res, res)) and abs(fsm(x) - fsm(xe)) < 1e-9 * fsm(xe)   # roads 1, 2, 3 agree
assert len(st) < n // 10 and len(sts) > 5 * len(st)              # far fewer than n steps, and beats descent
assert ea(x) <= 2 * rate_cg ** len(st) * ea(start) and ea(xg) <= rate_gd ** len(sts) * ea(start) and rms(x) < rms(y) / 3  # A-norm bounds; smoothing helps

# ---- break: an indefinite matrix, a saddle instead of a bowl ----
Ai, bi = [[1.0, 2.0], [2.0, 1.0]], [3.0, 0.0]
xi, sti, _, _ = cg(lambda v: [dot(Ai[0], v), dot(Ai[1], v)], bi, [0.0, 0.0], 1e-12)
print(f"break: indefinite, pAp {sti[0][2]:.1f} then {sti[1][2]:.1f}, ends at ({xi[0]:.4f}, {xi[1]:.4f}) with f {f2(Ai, bi, xi):.4f};"
      f" f(0, 0) 0.0000, f(10, -10) {f2(Ai, bi, [10.0, -10.0]):.1f}")
assert sti[1][2] < 0 and f2(Ai, bi, xi) > 0.0                    # it stops on a saddle, above the start

# ---- the nonlinear version: the Rosenbrock banana valley, start (-1.2, 1), stop when |grad| < 1e-6 ----
def fr(x, y): return 100.0 * (y - x * x) * (y - x * x) + (1.0 - x) * (1.0 - x)
def gr(x, y): return -400.0 * x * (y - x * x) - 2.0 * (1.0 - x), 200.0 * (y - x * x)
def search(x, y, dx, dy, c2):                   # bisection until the strong Wolfe tests pass
    f0, (gx, gy) = fr(x, y), gr(x, y)
    s0, lo, hi, a = gx * dx + gy * dy, 0.0, -1.0, 1.0
    for _ in range(60):
        gx, gy = gr(x + a * dx, y + a * dy); s = gx * dx + gy * dy
        if fr(x + a * dx, y + a * dy) > f0 + 1e-4 * a * s0: hi = a
        elif s < c2 * s0: lo = a
        elif s > -c2 * s0: hi = a
        else: break
        a = (lo + hi) / 2.0 if hi > 0.0 else 2.0 * a
    return a
def ncg(kind, c2=0.1):
    x, y = -1.2, 1.0; gx, gy = gr(x, y)
    dx, dy, k, restarts, path = -gx, -gy, 0, 0, []
    while sqrt(gx * gx + gy * gy) >= 1e-6 and k < 100000:
        if gx * dx + gy * dy >= 0.0:            # not downhill: restart along minus the gradient
            dx, dy, restarts = -gx, -gy, restarts + 1
        a = search(x, y, dx, dy, c2)
        x, y = x + a * dx, y + a * dy; hx, hy = gr(x, y)
        b = (hx * hx + hy * hy) / (gx * gx + gy * gy) if kind == "FR" else 0.0       # Fletcher-Reeves
        if kind == "PR+": b = max(0.0, (hx * (hx - gx) + hy * (hy - gy)) / (gx * gx + gy * gy))  # Polak-Ribiere
        dx, dy, gx, gy, k = -hx + b * dx, -hy + b * dy, hx, hy, k + 1
        path.append((x, y))
    return k, x, y, restarts, path
runs = {kind: ncg(kind) for kind in ("PR+", "FR", "GD")}
for kind, (k, xr, yr, rs, _) in runs.items():
    print(f"banana {kind:<3}: {k:>5d} iterations, ends ({xr:.6f}, {yr:.6f}), restarts {rs}")
print("banana PR+ path:", " ".join(f"k={j + 1} ({runs['PR+'][4][j][0]:.3f}, {runs['PR+'][4][j][1]:.3f})" for j in (0, 4, 9, 14, 19)))
ka, _, _, rsa, _ = ncg("PR+", c2=1e9)
print(f"break: PR+ with backtracking only, no curvature test: {ka} iterations, {rsa} restarts")
for kind, (k, xr, yr, rs, _) in runs.items():                    # certificate: f >= 0 everywhere, f(1, 1) = 0
    assert abs(xr - 1.0) < 1e-5 and abs(yr - 1.0) < 1e-5 and fr(xr, yr) < 1e-10
assert runs["GD"][0] > 100 * runs["PR+"][0] and runs["GD"][0] > 10 * runs["FR"][0] and ka > 10 * runs["PR+"][0] and runs["PR+"][0] == 34
print("ALL CHECKS PASS")
