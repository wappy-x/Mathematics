# Schauder estimates -- the check behind the card.  Standard library only.
# Scaled units: lengths in m, heights in m, tension T = 200 N/m, load q = T*f in Pa.
# Equation -Lap u = f on the disc r < 1/2.  Phi = -(1/2pi) ln|x| is the point-source potential.
from math import log, sqrt, cos, sin, pi
T, R = 200.0, 0.5

# ---- A. a continuous source that is not Hoelder: u1 = (x^2 - y^2) sqrt(ln(1/r)) ----
def u1(x, y): return (x * x - y * y) * sqrt(log(1.0 / sqrt(x * x + y * y)))
def f1(x, y):                       # -Lap u1, worked out by hand on the card
    r2 = x * x + y * y; l = log(1.0 / sqrt(r2))
    return (x * x - y * y) / r2 * (2.0 / sqrt(l) + 0.25 / l ** 1.5)
def bend1(r):                       # u1_xx on the y-axis, by hand
    l = log(1.0 / r); return 2.0 * sqrt(l) + 0.5 / sqrt(l)
print("A. continuous source f1 = -Lap[(x^2 - y^2) sqrt(ln 1/r)], read on the y-axis at distance r")
print("     r (m)   f1 (1/m)   load (Pa)    |f1|/r^0.5  u_xx (1/m)  2 sqrt(ln 1/r)")
for k in (1, 2, 4, 8, 16):
    r = 10.0 ** -k
    print(f"     1e-{k:02d} {f1(0, r):10.4f} {T * f1(0, r):10.2f} {abs(f1(0, r)) / sqrt(r):12.1f} {bend1(r):12.4f} {2 * sqrt(log(1 / r)):14.4f}")
fd = []
for r in (1e-1, 1e-2):
    h = r / 100
    uxx = (u1(h, r) - 2 * u1(0, r) + u1(-h, r)) / h ** 2
    lap = (u1(h, r) + u1(-h, r) + u1(0, r + h) + u1(0, r - h) - 4 * u1(0, r)) / h ** 2
    fd.append((r, uxx, -lap))
    print(f"  centred differences, h = r/100, r = 1e-0{len(fd)}: bend {uxx:.4f}, -Lap u1 {-lap:.4f}")
print(f"  by hand at r = 1e-02: ell {log(100.0):.4f}, sqrt(ell) {sqrt(log(100.0)):.4f}, r^0.5 {sqrt(0.01):.4f}")

# ---- B. a Hoelder source: f2 = r^(1/2); its Newtonian potential on the disc is -(4/25) r^(5/2) + const ----
def f2(x, y): return (x * x + y * y) ** 0.25
def d2w(x, y):                      # (w_xx, w_xy, w_yy) of w = -(4/25) r^(5/2), by hand
    r = sqrt(x * x + y * y)
    if r == 0.0: return (0.0, 0.0, 0.0)
    c, s = x / r, y / r
    return (-sqrt(r) * (0.6 * c * c + 0.4 * s * s), -0.2 * sqrt(r) * c * s, -sqrt(r) * (0.6 * s * s + 0.4 * c * c))
def korn_xx(x, y, n=400):           # road 2: the proof's formula, D11 Phi against f(y) - f(x), polar about x
    fx, tot = f2(x, y), 0.0
    for i in range(n):
        ph = (i + 0.5) * 2 * pi / n; ex, ey = cos(ph), sin(ph)
        b = x * ex + y * ey; L = -b + sqrt(b * b + R * R - x * x - y * y)   # ray length to the rim
        s = sum((f2(x + (j + 0.5) * L / n * ex, y + (j + 0.5) * L / n * ey) - fx) / ((j + 0.5) * L / n) for j in range(n))
        tot += -cos(2 * ph) / (2 * pi) * (s * L / n + fx * log(L))
    return -(tot * 2 * pi / n + fx / 2)
def simpson(g, a, b, n=2000):
    h = (b - a) / n
    return (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))) * h / 3
def gauss_slope(r): return -simpson(lambda t: t * t ** 0.5, 0.0, r) / r   # road 3: Gauss's law, w'(r)
print("B. Hoelder source f2 = r^0.5 on the disc r < 0.5, Newtonian potential w")
roads = []
for (x, y) in ((0.2, 0.0), (0.12, 0.16)):
    r, e = sqrt(x * x + y * y), 1e-4
    w2 = (gauss_slope(r + e) - gauss_slope(r - e)) / (2 * e)
    g3 = w2 * x * x / r ** 2 + gauss_slope(r) / r * y * y / r ** 2
    roads.append((d2w(x, y)[0], korn_xx(x, y), g3))
    print(f"  bend w_xx at ({x:.2f}, {y:.2f}): by hand {roads[-1][0]:.6f}, proof's formula {roads[-1][1]:.6f}, Gauss's law {g3:.6f}")
    print(f"     load there {T * f2(x, y):.2f} Pa; -Lap w = w_xx + w_yy by hand {-d2w(x, y)[0] - d2w(x, y)[2]:.6f}, f2 {f2(x, y):.6f}")
def semi(vals, pts, a):             # largest Hoelder quotient over all pairs of sample points
    return max(abs(vals[i] - vals[j]) / sqrt((pts[i][0] - pts[j][0]) ** 2 + (pts[i][1] - pts[j][1]) ** 2) ** a
               for i in range(len(pts)) for j in range(i))
print("  disc radius rho: sup|f2|  [f2]_0.5  sup|D2w|  [D2w]_0.5   (129 sample points)")
disc = []
for rho in (0.5, 0.05, 0.005, 0.0005):
    pts = [(0.0, 0.0)] + [(rho * k / 8 * cos(m * pi / 8), rho * k / 8 * sin(m * pi / 8)) for k in range(1, 9) for m in range(16)]
    D = [d2w(*p) for p in pts]
    sup2 = max(abs(v) for d in D for v in d)
    h5 = max(semi([d[c] for d in D], pts, 0.5) for c in range(3))
    disc.append((rho, semi([f2(*p) for p in pts], pts, 0.5), sup2, h5))
    print(f"  {rho:16.4f} {max(f2(*p) for p in pts):8.4f} {disc[-1][1]:9.4f} {sup2:9.4f} {h5:10.4f}")
q6 = [max(abs(p - q) for p, q in zip(d2w(e, 0.0), d2w(0.0, 0.0))) / e ** 0.6 for e in (0.1, 1e-3, 1e-6, 1e-12)]
print("  exponent 0.6: D2w quotient from the centre to 10 cm, 1 mm, 1 um, 1e-12 m: " + ", ".join(f"{q:.4f}" for q in q6))

# ---- C. method of continuity: -a_t u'' = 1 on (0, 1), u(0) = u(1) = 0, a_t = 1 + t (a - 1) ----
N = 1000; hx = 1.0 / N; X = [i * hx for i in range(N + 1)]
a = [1.0 + 2.0 * sqrt(abs(2 * x - 1)) for x in X]      # Hoelder 1/2, between 1 and 3
def solve(at, g):                   # tridiagonal (Thomas) solve of -at u'' = g by centred differences
    n = N - 1; cp, dp = [0.0] * n, [0.0] * n
    for k in range(n):
        lo = hi = -at[k + 1] / hx ** 2; di = 2 * at[k + 1] / hx ** 2
        m = di - (lo * cp[k - 1] if k else 0.0)
        cp[k] = hi / m; dp[k] = (g[k + 1] - (lo * dp[k - 1] if k else 0.0)) / m
    u = [0.0] * (N + 1)
    for k in range(n - 1, -1, -1): u[k + 1] = dp[k] - (cp[k] * u[k + 2] if k < n - 1 else 0.0)
    return u
def d2(u): return [0.0] + [(u[i + 1] - 2 * u[i] + u[i - 1]) / hx ** 2 for i in range(1, N)] + [0.0]
def step(u, s, t, iters):           # u <- L_s^(-1)[f - (t - s)(L_1 - L_0) u], the contraction of the proof
    at, ch = [1 + s * (ai - 1) for ai in a], []
    for _ in range(iters):
        un = solve(at, [1.0 + (t - s) * (ai - 1) * v for ai, v in zip(a, d2(u))])
        ch.append(max(abs(p - q) for p, q in zip(un, u))); u = un
        if ch[-1] < 1e-13: break
    return u, ch
print("C. method of continuity, -a_t u'' = 1, a = 1 + 2 sqrt|2x - 1|, 1000 grid steps")
u = solve([1.0] * (N + 1), [1.0] * (N + 1)); ts = [0.0, 0.25, 0.5, 0.75, 1.0]
for s, t in zip(ts, ts[1:]):
    qb = (t - s) * max((ai - 1) / (1 + s * (ai - 1)) for ai in a)
    u, ch = step(u, s, t, 100)
    print(f"  step {s:.2f} -> {t:.2f}: bound on the factor {qb:.4f}, change ratio near the end {ch[-2] / ch[-3]:.2f}, {len(ch)} iterations, u(1/2) = {u[N // 2]:.6f} m")
_, big = step(solve([1.0] * (N + 1), [1.0] * (N + 1)), 0.0, 1.0, 20)
print(f"  one step 0 -> 1: bound on the factor {max(ai - 1 for ai in a):.4f}, change after 1, 10, 20 iterations {big[0]:.4f}, {big[9]:.4f}, {big[19]:.4f} m")
ud = solve(a, [1.0] * (N + 1))
exact = simpson(lambda s: (1 - s * s) * s / (2 * (1 + 2 * s)), 0.0, 1.0)  # u(1/2) = int_0^1/2 t/a dt, t = (1 - s^2)/2
print(f"  u(1/2): continuity {u[N // 2]:.8f}, direct solve {ud[N // 2]:.8f}, integral {exact:.8f} m")
sub = list(range(0, N + 1, 5))
for t in (0.25, 0.5, 1.0):
    v = [-1.0 / (1 + t * (a[i] - 1)) for i in sub]
    meas = semi(v, [(X[i], 0.0) for i in sub], 0.5)
    near = (1 - 1 / (1 + t * 2 * sqrt(2e-12))) / sqrt(1e-12)   # x = 1/2 against 1/2 + 1e-12, where |2x - 1| = 2e-12
    print(f"  t = {t:.2f}: [u'']_0.5 quotient on a 5 mm sample {meas:.4f}, pair 1e-12 m apart at x = 1/2 {near:.4f}; bound [a_t]_0.5 * sup|f| / theta^2 = {t * 2 * sqrt(2):.4f}")
    assert meas < near < t * 2 * sqrt(2) < near + 1e-4, "the bound is reached as the pair closes in on x = 1/2"
print("  coefficient a = 1 + 1/ln(1/|2x - 1|), only continuous: [u'']_0.5 quotient at distance d from x = 1/2")
for k in (2, 4, 8):
    d = 10.0 ** -k
    print(f"     d = 1e-{k:02d}: {(1 - 1 / (1 + 1 / log(1 / (2 * d)))) / sqrt(d):.4f}")
print("chart, k in r = 10^-k: 1, 2, 4, 8, 16")
print("chart, bend under f1 (1/m): " + ", ".join(f"{bend1(10.0 ** -k):.2f}" for k in (1, 2, 4, 8, 16)))
print("chart, size of f1 (1/m): " + ", ".join(f"{abs(f1(0, 10.0 ** -k)):.2f}" for k in (1, 2, 4, 8, 16)))

for r, uxx, lap in fd:              # roads agree: hand formulas against centred differences
    assert abs(uxx - bend1(r)) < 1e-3 * bend1(r) and abs(lap - f1(0, r)) < 1e-3 * abs(f1(0, r))
assert bend1(1e-16) > 2.5 * bend1(1e-2) and abs(f1(0, 1e-16)) < abs(f1(0, 1e-2)), "source shrinks, bend grows"
for hand, korn, gauss in roads:
    assert abs(korn - hand) < 1e-5 and abs(gauss - hand) < 1e-6, "three roads to the bend"
assert all(abs(d[3] - 0.6) < 1e-9 for d in disc), "[D2w]_0.5 = 0.6 [f2]_0.5 on every disc"
assert abs(q6[3] / q6[1] - 1e9 ** 0.1) < 1e-9, "[D2w]_0.6 quotient grows like eta^-0.1 without bound: alpha not gained"
assert abs(u[N // 2] - ud[N // 2]) < 1e-11 and abs(ud[N // 2] - exact) < 1e-4, "continuity = direct = integral"
assert big[19] > 1e3 * big[0], "one giant step must diverge"
print("ALL CHECKS PASS")
