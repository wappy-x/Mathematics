# Interior point for linear programs -- the check behind the card.  Standard library only.
# Roads to the answer: the primal-dual interior point method; every corner of the
# workshop's region listed in exact fractions; the prices y = (3, 0, 7) checked as a
# dual bound that meets the best corner.  Then the worst cases: the simplex method on
# Klee-Minty cubes against the interior point count on the same cubes.
import math
from fractions import Fraction as F
from itertools import combinations

def solve(M, r):                  # Gaussian elimination with row swaps
    n = len(r); M = [M[i][:] + [r[i]] for i in range(n)]
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(M[i][k]))   # first of the largest
        M[k], M[p] = M[p], M[k]
        for i in range(k + 1, n):
            f = M[i][k] / M[k][k]
            for j in range(k, n + 1): M[i][j] -= f * M[k][j]
    x = [0.0] * n
    for k in range(n - 1, -1, -1):
        x[k] = (M[k][n] - dot(M[k][k + 1:n], x[k + 1:])) / M[k][k]
    return x

def dot(u, v):
    t = 0.0
    for a, b in zip(u, v): t += a * b
    return t
def f4(v): return f"{v:.4f}"

def newton(A, c, x, y, sigma):    # one primal-dual Newton direction, x and y feasible
    m, n = len(A), len(c)
    s = [dot([A[i][j] for i in range(m)], y) - c[j] for j in range(n)]
    mu = dot(x, s) / n
    r = [sigma * mu - x[j] * s[j] for j in range(n)]
    d = [x[j] / s[j] for j in range(n)]
    M = [[dot([A[i][j] * d[j] for j in range(n)], A[l]) for l in range(m)] for i in range(m)]
    dy = solve(M, [dot(A[i], [r[j] / s[j] for j in range(n)]) for i in range(m)])
    ds = [dot([A[i][j] for i in range(m)], dy) for j in range(n)]
    dx = [(r[j] - x[j] * ds[j]) / s[j] for j in range(n)]
    return s, mu, M, dx, dy, ds

def ipm(A, c, x, y, sigma=0.1, eta=0.9, cap=200, hist=None):
    for k in range(cap + 1):
        s, mu, M, dx, dy, ds = newton(A, c, x, y, sigma)
        gap = dot(x, s)
        amax = min([-x[j] / dx[j] for j in range(len(x)) if dx[j] < 0] + [-s[j] / ds[j] for j in range(len(x)) if ds[j] < 0] + [1e9])
        a = 1.0 if eta is None else min(1.0, eta * amax)
        if hist is not None: hist.append((k, x, y, gap, a))
        if gap <= 1e-8 * (1 + abs(dot(c, x))) or k == cap: return k, x, y, s
        x = [x[j] + a * dx[j] for j in range(len(x))]; y = [y[i] + a * dy[i] for i in range(len(y))]

A = [[4.0, 2.0, 1.0, 0.0, 0.0], [3.0, 1.0, 0.0, 1.0, 0.0], [1.0, 2.0, 0.0, 0.0, 1.0]]
b, c = [160.0, 120.0, 64.0], [19.0, 20.0, 0.0, 0.0, 0.0]
X0, Y0 = [10.0, 10.0, 100.0, 80.0, 34.0], [5.0, 5.0, 5.0]
print("maximise 19 x1 + 20 x2 pounds: timber 4,2 <= 160 m; labour 3,1 <= 120 h; finish 1,2 <= 64 l")
s, mu, M, dx, dy, ds = newton(A, c, X0, Y0, 0.1)
print("start x = (" + ", ".join(f4(v) for v in X0) + "), y = (5, 5, 5), s = (" + ", ".join(f4(v) for v in s) + ")")
print(f"gap x.s = {f4(dot(X0, s))}, mu = {f4(mu)}, target sigma*mu = {f4(0.1 * mu)}")
print("M = A D A^T rows: " + "; ".join(", ".join(f4(v) for v in row) for row in M))
print("dy = (" + ", ".join(map(f4, dy)) + "), ds = (" + ", ".join(map(f4, ds)) + "), dx = (" + ", ".join(map(f4, dx)) + ")")
amax = min(-s[j] / ds[j] for j in range(5) if ds[j] < 0)
print(f"largest safe step {f4(amax)} (chairs' surplus s2 hits 0); take 0.9 of it: alpha = {f4(0.9 * amax)}")
print(f"new gap predicted 1330 * (1 - alpha * 0.9) = {f4(1330 * (1 - 0.9 * amax * 0.9))}")
H = []
k, x, y, s = ipm(A, c, X0, Y0, hist=H)
print(" k   tables    chairs    profit     bound       gap   step")
for (j, xj, yj, g, a) in H:
    print(f"{j:2d} {xj[0]:8.4f} {xj[1]:9.4f} {dot(c, xj):9.4f} {dot(b, yj):9.4f} {g:9.6f} {a:6.4f}")
print("chart log10 gap: " + ", ".join(f"{math.log10(h[3]):.2f}" for h in H))
print(f"stop after {k} iterations: plan ({f4(x[0])}, {f4(x[1])}), prices y = ({', '.join(f4(v) for v in y)})")
P, Q, R = [[4, 2], [3, 1], [1, 2], [-1, 0], [0, -1]], [160, 120, 64, 0, 0], {}
for p, q in combinations(range(5), 2):          # cross every pair of walls, exactly
    det = F(P[p][0] * P[q][1] - P[p][1] * P[q][0])
    if det:
        pt = ((Q[p] * P[q][1] - P[p][1] * Q[q]) / det, (P[p][0] * Q[q] - Q[p] * P[q][0]) / det)
        if all(w[0] * pt[0] + w[1] * pt[1] <= l for w, l in zip(P, Q)): R[pt] = 19 * pt[0] + 20 * pt[1]
print("corners: " + "; ".join(f"({p[0]}, {p[1]}) {v}" for p, v in sorted(R.items())))
yc = [3, 0, 7]
cover = [sum(P[i][j] * yc[i] for i in range(3)) for j in range(2)]
print(f"certificate y = (3, 0, 7): covers tables {cover[0]} >= 19, chairs {cover[1]} >= 20; bound {sum(Q[i] * yc[i] for i in range(3))}")
H2 = []; ipm(A, c, X0, Y0, eta=None, cap=2, hist=H2)
for j in (1, 2):
    xj = H2[j][1]; print(f"break, full steps, after {j}: plan ({f4(xj[0])}, {f4(xj[1])}), timber left {f4(xj[2])}, profit {f4(dot(c, xj))}")
Hc = []; ipm(A, c, X0, Y0, sigma=1.0, cap=20, hist=Hc)
print(f"break, sigma = 1 (centre only): gap after 20 iterations {f4(Hc[-1][3])}")
kt, xt, yt, st = ipm(A, [19.0, 38.0, 0.0, 0.0, 0.0], X0, [5.0, 10.0, 10.0])
print(f"break, chairs at 38 pounds (tied best edge): stops after {kt} at ({f4(xt[0])}, {f4(xt[1])}), profit {f4(19 * xt[0] + 38 * xt[1])}")
xs, ys, nc = X0, Y0, 0                           # short-step method: centre, then sigma = 1 - 0.4/sqrt(n)
def prox(x, y):
    s = newton(A, c, x, y, 1.0)[0]; mu = dot(x, s) / 5
    return math.sqrt(sum((x[j] * s[j] / mu - 1) ** 2 for j in range(5)))
while prox(xs, ys) > 0.4:
    _, xs, ys, _ = ipm(A, c, xs, ys, sigma=1.0, cap=1); nc += 1
sig = 1 - 0.4 / math.sqrt(5); g0 = dot(xs, newton(A, c, xs, ys, 1.0)[0]); Hs = []
ks, xs, ys, _ = ipm(A, c, xs, ys, sigma=sig, eta=None, cap=500, hist=Hs)
worst = max(prox(h[1], h[2]) for h in Hs)
pred = math.ceil(math.log(g0 / (1e-8 * 929)) / -math.log(sig))
bound = math.sqrt(5) / 0.4 * math.log(g0 / (1e-8 * 929))
print(f"short step: {nc} centring steps, gap {f4(g0)}; sigma {f4(sig)}; {ks} iterations (predicted {pred}, bound {f4(bound)}); worst proximity {f4(worst)}")

def km_simplex(n):                               # Dantzig's rule, integer tableau: every pivot is 1
    T = [[2 * 10 ** (i - j) if j < i else int(j == i or j == n + i) for j in range(2 * n)] + [100 ** i] for i in range(n)]
    z, piv = [-(10 ** (n - 1 - j)) for j in range(n)] + [0] * (n + 1), 0
    while min(z[:-1]) < 0:
        j = z.index(min(z[:-1]))
        r = min((i for i in range(n) if T[i][j] > 0), key=lambda i: F(T[i][-1], T[i][j]))
        assert T[r][j] == 1
        for i in range(n):
            if i != r: T[i] = [u - T[i][j] * v for u, v in zip(T[i], T[r])]
        z = [u - z[j] * v for u, v in zip(z, T[r])]; piv += 1
    return piv, z[-1]

def km_ipm(n):                                   # the same cube with each x_j measured in units of 100^j
    p = [1.0]
    for _ in range(n): p.append(p[-1] / 10.0)
    A = [[2.0 * p[i - j] if j < i else float(j == i or j == n + i) for j in range(2 * n)] for i in range(n)]
    x = [0.1] * n + [1.0 - dot(A[i][:n], [0.1] * n) for i in range(n)]
    return ipm(A, [p[n - 1 - j] for j in range(n)] + [0.0] * n, x, [2.0] * n)

print(" d  pivots          2^d - 1  iterations  x_d")
rows = []
for n in (2, 4, 6, 8, 10, 20, 40):
    piv, val = km_simplex(n) if n <= 10 else (None, None)
    k_n, xk, _, _ = km_ipm(n)
    rows.append((n, piv, val, k_n, xk[n - 1]))
    print(f"{n:2d} {'-' if piv is None else piv:>7} {2 ** n - 1:>16} {k_n:>11}  {xk[n - 1]:.6f}")
print("figure, px = 50 + 5*x1, py = 225 - 5*x2: path k = 0..7 " + " ".join(f"({50 + 5 * h[1][0]:.1f},{225 - 5 * h[1][1]:.1f})" for h in H[:8]))

best = max(R.values())
assert best == 928 and max(R, key=R.get) == (32, 16)                      # enumeration
assert cover[0] >= 19 and cover[1] >= 20 and sum(Q[i] * yc[i] for i in range(3)) == best  # dual bound meets it
assert abs(x[0] - 32) < 1e-6 and abs(x[1] - 16) < 1e-6 and k == 13       # interior point meets both
assert max(abs(y[i] - yc[i]) for i in range(3)) < 1e-6
assert abs(H[1][3] - 1330 * (1 - 0.9 * amax * 0.9)) < 1e-9               # gap falls by 1 - alpha(1 - sigma)
assert H2[2][1][2] < 0 and dot(c, H2[2][1]) > best                        # full steps leave the region
assert abs(Hc[-1][3] - 1330) < 1e-6 and ks == pred and worst <= 0.4
assert abs(19 * xt[0] + 38 * xt[1] - 1216) < 1e-5 and 1 < xt[0] < 31     # tie: inside the edge, no corner
assert all(r[1] is None or (r[1] == 2 ** r[0] - 1 and r[2] == 100 ** (r[0] - 1)) for r in rows)
assert all(abs(r[4] - 1) < 1e-6 and r[3] <= 20 for r in rows)
print("ALL CHECKS PASS")
