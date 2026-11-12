# Tridiagonal systems and the Thomas algorithm -- the check behind the card.
# Standard library only.  A 1 m rod in 200 segments, ends held at 20 C and 60 C,
# heated inside: -k T'' = q.  Road one: the Thomas sweep.  Road two: the exact
# parabola T(s) = 20 + 40 s + 200 s (1 - s).  Road three: dense elimination.
from math import sqrt, log10

def thomas(a, b, c, d, fl):              # a below, b on, c above the diagonal
    n = len(b)
    p, l, y = [b[0]], [0.0], [d[0]]
    for i in range(1, n):                # sweep down: one multiplier per row
        l.append(a[i] / p[i - 1])
        p.append(b[i] - l[i] * c[i - 1])
        y.append(d[i] - l[i] * y[i - 1])
        fl[0] += 5
    x = [0.0] * n
    x[n - 1] = y[n - 1] / p[n - 1]
    fl[0] += 1
    for i in range(n - 2, -1, -1):       # sweep back: last unknown first
        x[i] = (y[i] - c[i] * x[i + 1]) / p[i]
        fl[0] += 3
    return p, l, y, x

def dense(a, b, c, d, fl):               # full elimination, partial pivoting
    n = len(b)
    M = [[0.0] * n + [d[i]] for i in range(n)]
    for i in range(n):
        M[i][i] = b[i]
        if i > 0: M[i][i - 1] = a[i]
        if i < n - 1: M[i][i + 1] = c[i]
    for k in range(n):
        r = max(range(k, n), key=lambda i: abs(M[i][k]))
        M[k], M[r] = M[r], M[k]
        for i in range(k + 1, n):
            m = M[i][k] / M[k][k]
            for j in range(k + 1, n + 1):
                M[i][j] -= m * M[k][j]
            fl[0] += 1 + 2 * (n - k)
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        s = M[i][n]
        for j in range(i + 1, n):
            s -= M[i][j] * x[j]
        x[i] = s / M[i][i]
        fl[0] += 2 * (n - 1 - i) + 1
    return x

def E(n): return (4 * n**3 + 9 * n**2 - 7 * n) // 6   # dense flops, exact
def F(n): return 8 * n - 7                           # Thomas flops, exact
def resid(a, b, c, d, x):                # d - A x, row by row
    n = len(b)
    return [d[i] - (a[i] * x[i - 1] if i > 0 else 0.0) - b[i] * x[i]
            - (c[i] * x[i + 1] if i < n - 1 else 0.0) for i in range(n)]

n, h, k, q = 199, 0.005, 50.0, 20000.0   # illustrative steel-like k and heating q
a, b, c = [-1.0] * n, [2.0] * n, [-1.0] * n
d = [h * h * q / k] * n
d[0] += 20.0; d[-1] += 60.0              # the held ends move to the right side
f1, f2 = [0], [0]
p, l, y, x = thomas(a, b, c, d, f1)
xd = dense(a, b, c, d, f2)
ex = [20 + 40 * (i * h) + 200 * (i * h) * (1 - i * h) for i in range(1, n + 1)]
print(f"rod: n = {n} unknowns, h = {h:.3f} m, right side h^2 q/k = {d[1]:.4f}, ends 20 and 60 C")
for i in (0, 1, 2):
    print(f"row {i + 1}: multiplier {l[i]:.6f}, pivot {p[i]:.6f}, swept right side {y[i]:.6f}")
print(f"row {n}: multiplier {l[-1]:.6f}, pivot {p[-1]:.6f}, swept right side {y[-1]:.6f}")
print(f"back: T{n}, T{n - 1}, T{n - 2} =", " ".join(f"{v:.6f}" for v in x[-1:-4:-1]))
j = max(range(n), key=lambda i: x[i])
print(f"hottest node: s = {(j + 1) * h:.3f} m, T = {x[j]:.6f} C; middle T = {x[n // 2]:.6f} C")
print("chart, T at s = 0, 0.1, ..., 1.0 m:", " ".join(f"{v:.2f}" for v in [20.0] + x[round(0.1 / h) - 1::round(0.1 / h)] + [60.0]))
print(f"flops: Thomas counted {f1[0]}, 8n - 7 = {F(n)}; dense counted {f2[0]}, E(n) = {E(n)}")
print(f"dense / Thomas = {f2[0] / f1[0]:.1f}; storage 4n = {4 * n} numbers against n^2 = {n * n}")
print("chart, log10 flops at n = 10, 30, 100, 300, 1000:")
print("  Thomas", " ".join(f"{log10(F(m)):.2f}" for m in (10, 30, 100, 300, 1000)))
print("  dense ", " ".join(f"{log10(E(m)):.2f}" for m in (10, 30, 100, 300, 1000)))
same = all(u == v for u, v in zip(x, xd))
print(f"Thomas and dense elimination agree bit for bit: {same}")
err = max(abs(u - v) for u, v in zip(x, ex))
z = thomas(a, b, c, [1.0] * n, [0])[3]   # A z = ones gives the row sums of A^-1
zc = [(i + 1) * (n - i) / 2 for i in range(n)]
kap = 4.0 * max(z)
eta = max(map(abs, resid(a, b, c, d, x))) / (4.0 * max(map(abs, x)) + max(map(abs, d)))
rel, bnd = err / max(map(abs, ex)), 2 * kap * eta
print(f"true error against the parabola {err:.2e} C, relative {rel:.2e}")
print(f"kappa_inf = 4 x {max(z):.1f} = {kap:.1f}; backward error eta = {eta:.2e}")
print(f"bound 2 kappa eta = {bnd:.2e}; true / bound = {rel / bnd:.3f}")
print(f"smallest pivot {min(p):.6f}, bound |b| - |a| = 1; pivots stay above 1: {min(p) > 1}")
# the same pattern: one implicit heat step (r = 4.8) and a natural cubic spline
alpha, dt = 1.2e-5, 10.0
r = alpha * dt / h**2
bi = [1 + 2 * r] * n
dh = x[:]; dh[0] += r * 20.0; dh[-1] += r * 60.0     # heating switched off
ph, _, _, xh = thomas([-r] * n, bi, [-r] * n, dh, [0])
rh = max(map(abs, resid([-r] * n, bi, [-r] * n, dh, xh)))
print(f"implicit step: r = {r:.1f}, smallest pivot {min(ph):.6f}, bound 1 + r = {1 + r:.1f}, "
      f"limit {(bi[0] + sqrt(bi[0]**2 - 4 * r * r)) / 2:.6f}")
print(f"  middle after one 10 s step: {x[n // 2]:.6f} -> {xh[n // 2]:.6f} C; residual {rh:.1e}")
ps = thomas([1.0] * n, [4.0] * n, [1.0] * n, [0.0] * n, [0])[0]
print(f"spline system: pivots 4, {ps[1]:.6f}, {ps[2]:.6f} ... smallest {min(ps):.6f}; "
      f"bound 3, limit 2 + sqrt 3 = {2 + sqrt(3):.6f}")
# what breaks
x0 = thomas(a, b, c, [h * h * q / k] * n, [0])[3]
yb = d[:]                                # forgot to sweep the right side
xb = [0.0] * n; xb[-1] = yb[-1] / p[-1]
for i in range(n - 2, -1, -1): xb[i] = (yb[i] - c[i] * xb[i + 1]) / p[i]
print(f"mistake, ends left off the right side: hottest {max(x0):.6f} C at s = {(x0.index(max(x0)) + 1) * h:.3f} m")
print(f"mistake, right side not swept: T at s = 0.6 m reads {xb[round(0.6 / h) - 1]:.6f} C")
print(f"mistake, dense count for a band: {E(n)} flops, {E(n) / F(n):.0f} times the sweep")
eps = 1e-12                              # not dominant: a tiny pivot appears
A3 = ([0.0, 1.0, 1.0], [1.0, 1.0 + eps, 1.0], [1.0, 1.0, 0.0])
d3 = [0.3 + 0.6, 0.3 + (1.0 + eps) * 0.6 + 0.9, 0.6 + 0.9]   # true x = 0.3, 0.6, 0.9
p3, _, _, x3 = thomas(*A3, d3, [0])
x3d = dense(*A3, d3, [0])
inv = [dense(*A3, [float(i == j) for i in range(3)], [0]) for j in range(3)]
k3 = 3.0 * max(sum(abs(col[i]) for col in inv) for i in range(3))
e3 = max(abs(u - v) for u, v in zip(x3, (0.3, 0.6, 0.9)))
e3d = max(abs(u - v) for u, v in zip(x3d, (0.3, 0.6, 0.9)))
print(f"break: eps = {eps:.0e}, pivots {p3[0]:.1f}, {p3[1]:.3e}, {p3[2]:.0f}; kappa_inf = {k3:.3f}")
print("  sweep gives", " ".join(f"{v:.6f}" for v in x3), f"error {e3:.8f}; pivoted elimination error {e3d:.2e}")
va = [0.0] + [-(1.0 + i % 3) for i in range(1, 12)]   # a dominant chain with varying entries
vb, vc = [5.0 + i % 5 for i in range(12)], [0.25 + 0.5 * (i % 4) for i in range(11)] + [0.0]
vd = [float(i + 1) for i in range(12)]
vx, vxd = thomas(va, vb, vc, vd, [0])[3], dense(va, vb, vc, vd, [0])
rows = [abs(a[i]) * (i > 0) + abs(b[i]) + abs(c[i]) * (i < n - 1) for i in range(n)]   # row sums of A

assert f1[0] == F(n) and f2[0] == E(n)                # counted flops = the formulas
assert same                                           # the sweep is elimination on a band
assert max(abs(u - v) for u, v in zip(z, zc)) < 1e-12 * max(zc)  # row sums of A^-1 = i(n+1-i)/2
assert rel <= bnd and err < 1e-10                     # forward error inside kappa x eta
assert all(abs(p[i] - (i + 2) / (i + 1)) < 1e-12 for i in range(n))   # p_i = (i+1)/i
assert min(ph) >= 1 + r and min(ps) >= 3 and rh < 1e-10                # dominance bound
assert e3 > 1e-6 > e3d                                # no dominance: the sweep loses digits
assert max(abs(u - v) for u, v in zip(vx, vxd)) < 1e-12 * max(map(abs, vxd))   # general recurrence = dense
assert abs(kap - max(rows) * max(zc)) < 1e-9 * kap    # kappa = ||A||_inf x closed-form ||A^-1||_inf
print("ALL CHECKS PASS")
