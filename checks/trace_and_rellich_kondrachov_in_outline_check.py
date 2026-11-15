# Trace and Rellich-Kondrachov in outline: a 1 m square plate, temperatures in deg C above room.
# Every computation is a truncation (N cells, n x n pixels, N modes) shown at several sizes.
import math

def thomas(lo, di, up, rhs):
    # tridiagonal solve, written out: lo/up are the off-diagonals, di the diagonal
    n = len(di); c = [0.0] * n; d = [0.0] * n
    c[0] = up[0] / di[0]; d[0] = rhs[0] / di[0]
    for i in range(1, n):
        m = di[i] - lo[i] * c[i - 1]
        c[i] = up[i] / m if i < n - 1 else 0.0
        d[i] = (rhs[i] - lo[i] * d[i - 1]) / m
    x = [0.0] * n; x[-1] = d[-1]
    for i in range(n - 2, -1, -1):
        x[i] = d[i] - c[i] * x[i + 1]
    return x

def min_energy(N, stiff):
    # smallest ||u||^2 (stiff=1: H1 norm, stiff=0: L2 norm) over piecewise-linear u on N cells with u(0) = 1
    h = 1.0 / N
    a0 = stiff / h + h / 3; off = -stiff / h + h / 6
    di = [2 * a0] * (N - 1) + [a0]; lo = [off] * N; up = [off] * N
    rhs = [-off] + [0.0] * (N - 1)
    v = thomas(lo, di, up, rhs)
    return a0 + off * v[0]

coth1 = math.cosh(1) / math.sinh(1)
print("== Trace on the interval (0, 1): sharpest C with u(0)^2 <= C ||u||^2 ==")
print(f"closed form coth(1) = {coth1:.10f}  (minimiser cosh(1 - x)/cosh(1), energy tanh(1) = {math.tanh(1):.10f})")
errs = []
for N in (4, 16, 64, 256):
    r1 = 1 / min_energy(N, 1.0); r0 = 1 / min_energy(N, 0.0)
    errs.append(coth1 - r1)
    print(f"N={N:4d} cells: H1 ratio {r1:.10f}  gap {coth1 - r1:.3e}   L2-only ratio {r0:10.3f}  = {r0 / N:.6f} N")
    assert 0 < coth1 - r1 < 0.01 and abs(r0 / N - 2 * math.sqrt(3)) < 1e-3   # 2 sqrt(3): decay rate sqrt(3) - 2 per node
for a, b in zip(errs, errs[1:]):
    assert 14 < a / b < 18   # gap falls 16x per 4x cells: error ~ h^2
print(f"gap shrink per 4x cells: {errs[0] / errs[1]:.2f} {errs[1] / errs[2]:.2f} {errs[2] / errs[3]:.2f}")
print(f"L2-only ratio / N -> 2 sqrt(3) = {2 * math.sqrt(3):.6f}: no bound survives N -> infinity")
Ns = (4, 16, 64, 256)
print("chart,log10 N," + ",".join(f"{math.log10(N):.2f}" for N in Ns))
print("chart,log10 H1 ratio," + ",".join(f"{math.log10(1 / min_energy(N, 1.0)):.3f}" for N in Ns))
print("chart,log10 L2 ratio," + ",".join(f"{math.log10(1 / min_energy(N, 0.0)):.3f}" for N in Ns))

print("== The plate: w(x, y) = 60 exp(-pi x) sin(pi y), left edge x = 0 ==")
E = 1 - math.exp(-2 * math.pi)
L2 = 1800 * E / (2 * math.pi); GR = 1800 * math.pi * E; H1 = L2 + GR
print(f"||w||^2 = {L2:.4f}  ||grad w||^2 = {GR:.4f}  ||w||_H1^2 = {H1:.4f}")
print(f"edge integral of w^2 = 1800 (exact), rms edge excess = {math.sqrt(1800):.4f} C, peak 60 C")
WX = math.pi ** 2 * L2   # w_x = -pi w, half of the gradient's energy
print(f"||w_x||^2 = {WX:.4f}  bounds on 1800: crude 2(||w||^2 + ||w_x||^2) = {2 * (L2 + WX):.4f}")
print(f"  sharp coth(1)(||w||^2 + ||w_x||^2) = {coth1 * (L2 + WX):.4f}  coth(1)||w||_H1^2 = {coth1 * H1:.4f}")
assert abs(2 * WX - GR) < 1e-9 * GR
assert 1800 <= coth1 * (L2 + WX) <= 2 * (L2 + WX)
def edge_from_inside(n):
    # midpoint pixels only, never the edge: integral of w^2 - 2(1 - x) w w_x, w_x by differences
    h = 1.0 / n; tot = 0.0
    for j in range(n):
        y = (j + 0.5) * h
        col = [60 * math.exp(-math.pi * (i + 0.5) * h) * math.sin(math.pi * y) for i in range(n)]
        for i in range(n):
            if i == 0: wx = (-3 * col[0] + 4 * col[1] - col[2]) / (2 * h)
            elif i == n - 1: wx = (3 * col[i] - 4 * col[i - 1] + col[i - 2]) / (2 * h)
            else: wx = (col[i + 1] - col[i - 1]) / (2 * h)
            x = (i + 0.5) * h
            tot += (col[i] ** 2 - 2 * (1 - x) * col[i] * wx) * h * h
    return tot
prev = None
for n in (20, 80, 320):
    v = edge_from_inside(n); err = abs(v - 1800)
    print(f"{n:3d} x {n:<3d} interior pixels: edge integral {v:.4f}  error {err:.4f}")
    if prev: assert 15 < prev / err < 30; print(f"  error shrink {prev / err:.2f}x")   # 16x = second order
    prev = err
assert prev < 0.02

print("== What breaks: a hot layer of width eps on the left edge, 100 C at the edge ==")
for eps in (0.1, 0.01, 0.001):
    l2 = 1e4 * eps / 3; gx = 1e4 / eps
    # midpoint rule over the layer, independent of the closed forms
    m = 1000; s = sum((100 * (1 - (k + 0.5) / m)) ** 2 for k in range(m)) * eps / m
    assert abs(s - l2) < 1e-3 * l2
    print(f"eps={eps:<6}: ||u||^2 = {l2:.4f}  edge = 10000  ratio {1e4 / l2:.0f}  ||u_x||^2 = {gx:.0f}  H1 bound {coth1 * (l2 + gx):.0f}")
    assert coth1 * (l2 + gx) >= 1e4
tent = lambda x: max(0.0, 1 - abs(x))   # 1 m tent on an endless strip, slid 2 m
K = 40000; dx = 4 / K; xs = [-1 + (k + 0.5) * dx for k in range(K)]
dist2 = sum((tent(x) - tent(x - 2)) ** 2 for x in xs) * dx
h1t = sum(tent(x) ** 2 + (1 if abs(x) < 1 else 0) for x in xs) * dx
print(f"tent: ||tent||_H1^2 = {h1t:.6f} (8/3)  L2 distance between slides 2 m apart = {math.sqrt(dist2):.6f}")
assert abs(dist2 - 4 / 3) < 1e-6 and abs(h1t - 8 / 3) < 1e-6

print("== Rellich: ripples sqrt(2) sin(n pi x) on (0, 1) ==")
def l2dist2(n, m, K=4000):
    return sum((math.sqrt(2) * (math.sin(n * math.pi * (k + 0.5) / K) - math.sin(m * math.pi * (k + 0.5) / K))) ** 2 for k in range(K)) / K
for n in (1, 10, 100):
    d2 = l2dist2(n, 2 * n)
    print(f"n={n:3d}: ||s_n||_H1^2 = {1 + (n * math.pi) ** 2:.4f}  L2 distance to s_2n = {math.sqrt(d2):.6f}")
    assert abs(d2 - 2) < 1e-6
print("== Rellich: keep N cosine modes; worst L2 error over the H1 unit ball ==")
f0 = 60.0; e = math.exp(-math.pi)
def coef(k):   # cosine coefficient of f(x) = 60 exp(-pi x), basis 1, sqrt(2) cos(k pi x)
    if k == 0: return f0 * (1 - e) / math.pi
    return math.sqrt(2) * f0 * (1 - (-1) ** k * e) / (math.pi * (1 + k * k))
def coef_quad(k, K=20000):
    b = (lambda x: 1.0) if k == 0 else (lambda x: math.sqrt(2) * math.cos(k * math.pi * x))
    return sum(f0 * math.exp(-math.pi * (i + 0.5) / K) * b((i + 0.5) / K) for i in range(K)) / K
for k in (0, 1, 2, 7):
    assert abs(coef(k) - coef_quad(k)) < 1e-4
fH1 = (1 + math.pi ** 2) * 3600 * E / (2 * math.pi)
energy = sum((1 + (k * math.pi) ** 2) * coef(k) ** 2 for k in range(200000))
print(f"midline f = 60 exp(-pi x): ||f||_H1^2 = {fH1:.4f}, sum (1 + k^2 pi^2) c_k^2 = {energy:.4f}")
assert abs(energy - fH1) < 0.1
for N in (1, 10, 100):
    worst = 1 / math.sqrt(1 + (N * math.pi) ** 2)
    tail = math.sqrt(sum(coef(k) ** 2 for k in range(N, 200000)))
    print(f"N={N:3d}: worst {worst:.6f}  f's tail {tail:.6f} <= {worst * math.sqrt(fH1):.6f}  L2 ball worst 1")
    assert tail <= worst * math.sqrt(fH1)
print("ALL CHECKS PASS")
