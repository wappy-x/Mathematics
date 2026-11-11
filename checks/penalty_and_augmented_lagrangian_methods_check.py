# Penalties and augmented Lagrangians -- the check behind the card.  Standard library only.
# Three pumps feed one town.  Choose flows x = (x1, x2, x3) in L/s to MINIMISE the power drawn,
# f(x) = 0.02 x1^2 + 0.03 x2^2 + 0.05 x3^2 (kW), subject to two rules:
#   demand   h(x) = 150 - x1 - x2 - x3 = 0       (shortfall in L/s)
#   pressure g(x) = 0.5 x1 - 25 <= 0             (head over the low district's 25 m cap, in m)
# Road 1: the KKT equations, solved by elimination.  Road 2: a scan of every plan on a 0.5 L/s grid.
# Road 3: penalty and augmented-Lagrangian loops (sub-problems by elimination), rate checked against the proof.
import math
A, K, CAP, DEM, KWH = [0.02, 0.03, 0.05], 0.5, 25.0, 150.0, 0.20
f = lambda x: sum(a * v * v for a, v in zip(A, x))
h = lambda x: DEM - sum(x)
g = lambda x, cap=CAP: K * x[0] - cap
dist = lambda x, y: math.sqrt(sum((p - q) ** 2 for p, q in zip(x, y)))
f4 = lambda v: ", ".join(f"{u:.4f}" for u in v)
sci = lambda v, d: f"{v:.{d}e}"           # 1.23e-04 style, the same in both languages

def gauss(M, r):                          # solve M z = r by elimination with row swaps
    n = len(r)
    M = [list(row) + [v] for row, v in zip(M, r)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(M[i][c]))
        M[c], M[p] = M[p], M[c]
        for i in range(n):
            if i != c:
                m = M[i][c] / M[c][c]
                M[i] = [u - m * v for u, v in zip(M[i], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def hess(rho, act):                       # Hessian of the sub-problem: diag(2a) + rho J^T J
    return [[(2 * A[i] if i == j else 0) + rho + (rho * K * K if act and i == j == 0 else 0)
             for j in range(3)] for i in range(3)]

def sub(rho, lam, nu, cap=CAP, clamp=True):   # minimise the augmented Lagrangian exactly
    for act in (True, False):             # cap term switched on, then off; keep the consistent one
        b = [nu + rho * DEM - (K * (lam - rho * cap) if act and i == 0 else 0) for i in range(3)]
        x = gauss(hess(rho, act), b)
        if not clamp or act == (lam + rho * g(x, cap) >= 0):
            return x

def grad(x, rho, lam, nu):                # gradient of the augmented Lagrangian
    w = max(0.0, lam + rho * g(x))
    return [2 * A[i] * x[i] - nu - rho * h(x) + (K * w if i == 0 else 0) for i in range(3)]

def extremes(H):                          # largest and smallest eigenvalue, by power iteration
    v, w = [1.0, 0.3, 0.2], [1.0, 0.3, 0.2]
    for _ in range(300):
        u = [sum(H[i][j] * v[j] for j in range(3)) for i in range(3)]
        big = math.sqrt(sum(t * t for t in u)); v = [t / big for t in u]
        u = gauss(H, w)
        small = math.sqrt(sum(t * t for t in u)); w = [t / small for t in u]
    return big, 1 / small

def gd_steps(rho, lam, nu, x0, tol):      # gradient descent with step 1/L, counted to tol
    target, (L, _) = sub(rho, lam, nu), extremes(hess(rho, True))
    x, n = list(x0), 0
    while dist(x, target) > tol and n < 10 ** 6:
        x = [p - q / L for p, q in zip(x, grad(x, rho, lam, nu))]; n += 1
    return n, x

def aug_lag(rho, rounds, cap=CAP, clamp=True, sign=1):
    lam = nu = 0.0; path = []
    for _ in range(rounds):
        x = sub(rho, lam, nu, cap, clamp)
        nu += sign * rho * h(x)
        lam = max(0.0, lam + rho * g(x, cap)) if clamp else lam + rho * g(x, cap)
        path.append((x, lam, nu))
    return path

# ---- road 1: KKT with the cap binding.  Unknowns x1, x2, x3, nu, lam ----
M = [[2 * A[0], 0, 0, -1, K], [0, 2 * A[1], 0, -1, 0], [0, 0, 2 * A[2], -1, 0], [1, 1, 1, 0, 0], [K, 0, 0, 0, 0]]
*xs, nu_s, lam_s = gauss(M, [0, 0, 0, DEM, CAP])
free = [DEM / A[i] / sum(1 / a for a in A) for i in range(3)]   # demand only: x_i in proportion to 1/a_i
print(f"no cap: flows {f4(free)} L/s, power {f(free):.4f} kW, head {K * free[0]:.4f} m, {g(free):.4f} m over")
print(f"KKT: flows {f4(xs)} L/s, pump powers {f4([a * v * v for a, v in zip(A, xs)])} kW")
print(f"KKT: power {f(xs):.4f} kW, {KWH * f(xs):.4f} pounds an hour; the cap costs {f(xs) - f(free):.4f} kW")
print(f"KKT: nu {nu_s:.4f} kW per L/s ({KWH * nu_s:.4f} pounds an hour), lam {lam_s:.4f} kW per m ({KWH * lam_s:.4f})")
stat = max(abs(t) for t in grad(xs, 0.0, lam_s, nu_s))
print(f"KKT residuals: stationarity {sci(stat, 1)}, shortfall {sci(abs(h(xs)), 1)}, lam*g {sci(abs(lam_s * g(xs)), 1)}")
assert stat < 1e-12 and abs(h(xs)) < 1e-12 and lam_s > 0 and abs(g(xs)) < 1e-12

# ---- road 2: scan every plan on a 0.5 L/s grid that meets demand and the cap ----
best = min((f([p / 2, q / 2, DEM - p / 2 - q / 2]), p / 2, q / 2) for p in range(101) for q in range(301 - p))
print(f"grid scan: best flows {f4([best[1], best[2], DEM - best[1] - best[2]])} L/s, power {best[0]:.4f} kW")
assert dist([best[1], best[2], DEM - best[1] - best[2]], xs) < 1e-9

# ---- road 3a: quadratic penalty, rho = 1, 10, ..., 10^6 (no prices kept) ----
S = [[sum(1 / (2 * a) for a in A), -K / (2 * A[0])], [-K / (2 * A[0]), K * K / (2 * A[0])]]   # J (grad^2 f)^-1 J^T
print("penalty  rho    flows (L/s)                 power   short   over    rho*h   rho*g   error    kappa")
pen = []
for e in range(7):
    rho = 10.0 ** e; x = sub(rho, 0, 0); big, small = extremes(hess(rho, True)); pen.append(dist(x, xs))
    print(f"penalty 1e{e}  {f4(x):26s}  {f(x):8.4f} {h(x):7.5f} {g(x):7.5f} {rho * h(x):7.4f} "
          f"{rho * g(x):7.4f} {sci(pen[-1], 2)} {big / small:9.0f}")
    gap = gauss([[1 + rho * S[0][0], rho * S[0][1]], [rho * S[1][0], 1 + rho * S[1][1]]], [nu_s, lam_s])
    assert abs(nu_s - rho * h(x) - gap[0]) < 1e-8 * rho and abs(lam_s - rho * g(x) - gap[1]) < 1e-8 * rho
assert pen[3] * 1000 > 1 and pen[6] < 2e-5 and abs(pen[5] / pen[6] - 10) < 0.05
for e in range(4):
    n, _ = gd_steps(10.0 ** e, 0, 0, [50.0, 50.0, 50.0], 1e-3)
    print(f"gradient descent on the penalty at rho 1e{e}: {n} steps to 0.001 L/s")

# ---- road 3b: augmented Lagrangian, prices updated, rho held at 1 and at 10 ----
tr, det = S[0][0] + S[1][1], S[0][0] * S[1][1] - S[0][1] ** 2
sig = (tr - math.sqrt(tr * tr - 4 * det)) / 2
print(f"S = J (grad^2 f)^-1 J^T = [[{f4(S[0])}], [{f4(S[1])}]], smallest eigenvalue sigma {sig:.4f}")
print(f"predicted ratio 1/(1+rho sigma): rho 1 -> {1 / (1 + sig):.4f}, rho 10 -> {1 / (1 + 10 * sig):.4f}")
for rho in (1.0, 10.0):
    path, prev, errs = aug_lag(rho, 10), None, []
    for k, (x, lam, nu) in enumerate(path):
        errs.append(dist(x, xs)); ratio = f"{errs[-1] / prev:.4f}" if prev else "  -   "
        if rho == 1.0:
            print(f"AL rho 1, k={k}: flows {f4(x)}  error {sci(errs[-1], 2)}  ratio {ratio}  lam {lam:.4f}  nu {nu:.4f}")
        prev = errs[-1]
    big, small = extremes(hess(rho, True))
    print(f"AL rho {rho:g}: kappa {big / small:.1f}, chart log10 error k=0..6: " + " ".join(f"{math.log10(t):.2f}" for t in errs[:7]))
    assert abs(errs[4] / errs[3] - 1 / (1 + rho * sig)) < 1e-3
print("chart penalty log10 error k=0..6: " + " ".join(f"{math.log10(t):.2f}" for t in pen))
n, x = gd_steps(1.0, 3.5, 3.75, [50.0, 50.0, 50.0], 1e-3)
print(f"gradient descent on the AL at rho 1 with the true prices: {n} steps, lands {dist(x, xs):.4f} L/s from x*")

# ---- what breaks ----
x = sub(1.0, 0, 0)
print(f"stop at rho 1: head {K * x[0]:.4f} m, {g(x):.4f} m over; {h(x):.4f} L/s short; power {f(x):.4f} kW")
x, lam, nu = aug_lag(1.0, 60, cap=40.0, clamp=False)[-1]
y, lam2, _ = aug_lag(1.0, 60, cap=40.0)[-1]
print(f"cap 40 m, no clamp: lam {lam:.4f}, head {K * x[0]:.4f} m, power {f(x):.4f} kW; "
      f"with clamp: lam {lam2:.4f}, head {K * y[0]:.4f} m, power {f(y):.4f} kW")
assert lam < 0 and abs(K * x[0] - 40) < 1e-6 and abs(f(y) - f(free)) < 1e-9 and lam2 == 0
x = aug_lag(1.0, 10, sign=-1)[-1][0]; assert dist(x, xs) > 100; print(f"price update with the wrong sign, 10 rounds: error {dist(x, xs):.4f} L/s")
L1 = extremes(hess(1.0, True))[0]; x = [50.0, 50.0, 50.0]
for _ in range(50):
    x = [p - q / L1 for p, q in zip(x, grad(x, 10.0, 0, 0))]
assert dist(x, xs) > 1e6
print(f"rho 10 with the rho-1 step 1/L = {1 / L1:.4f}: error after 50 steps {sci(dist(x, xs), 3)} L/s")
for c in (4.0, 3.0):
    ex = lambda y: f(y) + c * (abs(h(y)) + max(0.0, g(y)))
    low = min(ex([xs[0] + i / 10, xs[1] + j / 10, xs[2] + l / 10])
              for i in range(-10, 11) for j in range(-10, 11) for l in range(-10, 11))
    print(f"exact penalty, rate {c:g}: value at x* {ex(xs):.4f} kW, lowest within 1 L/s {low:.4f} kW")
    assert (low > ex(xs) - 1e-9) if c > max(nu_s, lam_s) else (low < ex(xs) - 1)
print("ALL CHECKS PASS")
