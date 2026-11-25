# Leray-Schauder and a priori bounds -- the check behind the card.  Standard library only.
# Slab, scaled: -((1 + u^2) u')' = t on (0, 1), u(0) = u(1) = 0.  Theta* = 100 K, L = 0.1 m.
import math

def kirchhoff_root(rhs):  # bisection for u + u^3/3 = rhs, rhs >= 0
    lo, hi = 0.0, 1.0 + rhs
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if mid + mid * mid * mid / 3.0 < rhs: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def frozen_map(w, s):  # T(w) = v with -((1 + w^2) v')' = s, v(0) = v(1) = 0, trapezoid rule
    n = len(w) - 1; h = 1.0 / n
    g = [1.0 / (1.0 + wi * wi) for wi in w]
    i0 = i1 = 0.0
    for j in range(n):
        i0 += 0.5 * h * (g[j] + g[j + 1])
        i1 += 0.5 * h * (j * h * g[j] + (j + 1) * h * g[j + 1])
    c = i1 / i0
    v = [0.0] * (n + 1)
    for j in range(n):
        v[j + 1] = v[j] + 0.5 * h * s * ((c - j * h) * g[j] + (c - (j + 1) * h) * g[j + 1])
    return v

def fixed_point(n, s):  # repeat T until it stops moving; a computing road, not the proof
    u = [0.0] * (n + 1); k = 0
    while True:
        k += 1; v = frozen_map(u, s)
        d = max(abs(a - b) for a, b in zip(u, v)); u = v
        if d < 1e-15 or k > 500: return u, k

def det(a):  # Gaussian elimination with partial pivoting
    a = [row[:] for row in a]; n = len(a); d = 1.0
    for i in range(n):
        p = max(range(i, n), key=lambda r: abs(a[r][i]))
        if p != i: a[i], a[p] = a[p], a[i]; d = -d
        d *= a[i][i]
        for r in range(i + 1, n):
            f = a[r][i] / a[i][i]
            for col in range(i, n): a[r][col] -= f * a[i][col]
    return d

print("scale: q L^2/(k0 theta*) = 10000 * 0.1^2 / (1 * 100) =", f"{10000 * (0.1 * 0.1) / 100:.6f}")
peak = kirchhoff_root(0.125)
p3 = math.sqrt(1.0 + 9.0 / 256.0)
cardano = math.copysign(abs(3 / 16 + p3) ** (1 / 3), 3 / 16 + p3) + math.copysign(abs(3 / 16 - p3) ** (1 / 3), 3 / 16 - p3)
print(f"peak u(1/2), Kirchhoff root by bisection: {peak:.9f}  = {100 * peak:.4f} K")
print(f"peak u(1/2), Cardano's formula:           {cardano:.9f}")
assert abs(peak - cardano) < 1e-12
assert 0 <= peak <= 0.125
gap, kslope = 0.125 * 0.125 * 0.125 / 3, 1 + 0.125 * 0.125
print(f"hand Newton step from 1/8: K(1/8) - 1/8 = {gap:.6f}, slope K'(1/8) = {kslope:.6f}, new guess {0.125 - gap / kslope:.6f}")
assert abs(0.125 - gap / kslope - peak) < 1e-6
print(f"constant conductivity peak 1/8: {0.125:.6f} = {12.5:.4f} K; nonlinearity lowers it {100 * (0.125 - peak):.4f} K")
errs = []
for n in (50, 100, 200, 400):
    u, k = fixed_point(n, 1.0)
    errs.append(abs(u[n // 2] - peak))
    print(f"fixed point of discrete T, N = {n:3d}: peak {u[n // 2]:.9f}, error {errs[-1]:.3e}, {k} rounds")
order = math.log(errs[1] / errs[2]) / math.log(2.0)
print(f"observed order of the trapezoid fixed point: {order:.3f}")
assert 1.9 < order < 2.1
assert errs[2] < 1e-5
x = 0.3
for h in (0.01, 0.005):
    um, u0, up = (kirchhoff_root(y * (1 - y) / 2) for y in (x - h, x, x + h))
    d1 = (up - um) / (2 * h); d2 = (up - 2 * u0 + um) / (h * h)
    res = -(1 + u0 * u0) * d2 - 2 * u0 * d1 * d1 - 1.0
    print(f"residual of the equation at x = 0.3, h = {h}: {res:.3e}")
    assert abs(res) < 2e-5
u, _ = fixed_point(200, 1.0)
w0 = (-3 * u[0] + 4 * u[1] - u[2]) * 100
print(f"wall slope u'(0) from the N = 200 grid: {w0:.6f} scaled = {w0 * 100 / 0.1:.1f} K/m; wall flux {w0 * 1000:.1f} W/m^2, against q L/2 = {10000 * 0.1 / 2:.1f} W/m^2")
assert abs(w0 - 0.5) < 1e-4
ts = [0.0, 0.2, 0.4, 0.6, 0.8, 0.9, 0.95]
slab = [kirchhoff_root(t / 8) for t in ts]
for t, pk in zip(ts[1:5:2], slab[1:5:2]):
    u, _ = fixed_point(200, t)
    print(f"t-family t = {t}: peak {pk:.6f} (grid {u[100]:.6f}) <= bound t/8 = {t / 8:.6f}")
    assert abs(u[100] - pk) < 1e-5
    assert pk <= t / 8
wild = [100 * math.sin(50 * math.pi * j / 400000) for j in range(400001)]  # 400,000 cells follow all 25 waves
v = frozen_map(wild, 1.0)
slope = max(abs(v[j + 1] - v[j]) * 400000 for j in range(400000))
print(f"T(wild input, size 100, 400000 cells): min {min(v):.6f}, max {max(v):.6f} <= 1/8, steepest slope over a cell {slope:.6f} <= 1")
assert min(v) > -1e-12
assert max(v) <= 0.125 and abs(max(v) - 0.125 / math.sqrt(1 + 100 ** 2)) < 1e-6  # weight 1/(1+w^2) averages 1/sqrt(10001)
assert slope <= 1.0
dets = []
for n in (20, 40, 80):
    u, _ = fixed_point(n, 1.0); eps = 1e-6; jac = []
    for j in range(n + 1):
        a = u[:]; b = u[:]; a[j] += eps; b[j] -= eps
        ta, tb = frozen_map(a, 1.0), frozen_map(b, 1.0)
        jac.append([(ta[i] - tb[i]) / (2 * eps) for i in range(n + 1)])
    m = [[(1.0 if i == j else 0.0) - jac[j][i] for j in range(n + 1)] for i in range(n + 1)]
    dv = det(m)
    print(f"det(I - DT) at the solution, N = {n}: {dv:.6f}, index {'+1' if dv > 0 else '-1'}")
    assert dv > 0
    dets.append(dv)
assert abs(dets[2] - dets[1]) < 1e-4
lo, hi = 0.5, 3.0
for _ in range(200):
    mid = 0.5 * (lo + hi)
    if mid - math.tanh(2 * mid) < 0: lo = mid
    else: hi = mid
root = 0.5 * (lo + hi)
idx = [1 if 1 - 2 / (math.cosh(2 * m) * math.cosh(2 * m)) > 0 else -1 for m in (-root, 0.0, root)]
deg_b = (int(math.copysign(1, 3 - math.tanh(6))) - int(math.copysign(1, -3 + math.tanh(6)))) // 2
print(f"magnet m = tanh(2m): roots {-root:.6f}, 0, {root:.6f}; indices {idx}; sum {sum(idx)}; degree on (-3, 3) from end signs {deg_b}")
assert sum(idx) == deg_b == 1
assert abs(root - math.tanh(2 * root)) < 1e-12
res_peaks = []; PI3 = math.pi * math.pi * math.pi
for t in ts:
    k = math.pi * math.sqrt(t) / 2
    closed = (1 / math.cos(k) - 1) / (math.pi * math.pi) if t > 0 else 0.0
    series = 0.0
    for i in range(4000):
        nn = 2 * i + 1
        series += (1 - 2 * (i % 2)) * 4 * t / (nn * PI3 * (nn * nn - t))
    nn = 8001; omit = 4 * t / (nn * PI3 * (nn * nn - t))
    res_peaks.append(closed)
    assert abs(closed - series) <= omit + 1e-12
print("self-heating family -u'' = t(pi^2 u + 1): peaks", " ".join(f"{p:.4f}" for p in res_peaks), f"(series agrees; first omitted term <= {omit:.1e})")
for t in (0.99, 0.999):
    print(f"  t = {t}: peak {(1 / math.cos(math.pi * math.sqrt(t) / 2) - 1) / (math.pi * math.pi):.4f}")
print(f"  t = 1: no solution, since int_0^1 1 * sin(pi x) dx = 2/pi = {2 / math.pi:.6f}, not 0")
print("chart t:", " ".join(f"{t}" for t in ts))
print("chart slab peaks:", " ".join(f"{p:.4f}" for p in slab))
print("chart self-heating peaks:", " ".join(f"{p:.4f}" for p in res_peaks))
big = kirchhoff_root(1.0)
print(f"source 8 (q = 80 kW/m^3): peak {big:.6f} = {100 * big:.2f} K; constant conductivity {1.0:.6f} = {100.0:.2f} K")
assert abs(big + big * big * big / 3 - 1) < 1e-12
print("ALL CHECKS PASS")
