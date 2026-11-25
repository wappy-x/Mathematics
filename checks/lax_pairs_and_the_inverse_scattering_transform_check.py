# Lax pairs and inverse scattering: KdV u_t - 6 u u_x + u_xxx = 0 from u(x, 0) = -6 sech^2 x (scaled).
# Roads: the Lax identity on exact integer polynomials; bound states by a Sturm count at t = 0 and on a
# KdV solve; the Gel'fand-Levitan-Marchenko (GLM) equation as a determinant and as a Simpson-rule
# linear system; the textbook two-soliton formula; conserved integrals against kappa. Units: scaled.
import math
def pmul(p, q): return [sum(p[i] * q[k - i] for i in range(len(p)) if 0 <= k - i < len(q)) for k in range(len(p) + len(q) - 1)]
def pder(p): return [i * p[i] for i in range(1, len(p))] or [0]
def sc(c, p): return [c * a for a in p]
def padd(*ps): return [sum(p[i] for p in ps if i < len(p)) for i in range(max(map(len, ps)))]
def opL(u, f): return padd(sc(-1, pder(pder(f))), pmul(u, f))
def opB(u, f, a): return padd(sc(-4, pder(pder(pder(f)))), sc(a, pmul(u, pder(f))), sc(3, pmul(pder(u), f)))
def lax_left(u, f, a):  # [B, L] f - (6 u u_x - u_xxx) f, an exact integer polynomial
    k = padd(sc(6, pmul(u, pder(u))), sc(-1, pder(pder(pder(u)))))
    return padd(opB(u, opL(u, f), a), sc(-1, opL(u, opB(u, f, a))), sc(-1, pmul(k, f)))
U, F = [1, 2, -3, 0, 1], [2, -1, 4, 1]
good, bad = lax_left(U, F, 6), lax_left(U, F, 3)
print(f"Lax identity, B = -4 d3 + 6u d + 3u_x: {sum(c != 0 for c in good)} nonzero coefficients left")
print(f"  with 3u d in B instead: leftover at x = 1 is {sum(bad)}, not 0")
assert all(c == 0 for c in good) and sum(bad) != 0
def tau(x, t, s=1):  # det(I + A) built from the scattering data c1^2 = 6 e^{8t}, c2^2 = 12 e^{64t}
    e = [(1, 0), (3 * math.exp(8 * s * t), -2), (3 * math.exp(64 * s * t), -4), (math.exp(72 * s * t), -6)]
    return [sum(a * p ** m * math.exp(p * x) for a, p in e) for m in (0, 1, 2)]
def u_ist(x, t, s=1):
    T, T1, T2 = tau(x, t, s); return -2 * (T2 * T - T1 * T1) / (T * T)
def u_book(x, t):
    return -12 * (3 + 4 * math.cosh(2*x - 8*t) + math.cosh(4*x - 64*t)) / (3 * math.cosh(x - 28*t) + math.cosh(3*x - 36*t)) ** 2
def gold(f, a, b):  # golden-section search for a minimum
    g = (math.sqrt(5) - 1) / 2
    for _ in range(90):
        c, d = b - g * (b - a), a + g * (b - a); a, b = (a, d) if f(c) < f(d) else (c, b)
    return (a + b) / 2
def below(u, h, E):  # Sturm count: eigenvalues of the grid operator -D2 + u below E
    n, d = 0, 1.0
    for j, uj in enumerate(u):
        d = 2 / h**2 + uj - E - ((1 / h**4) / d if j else 0.0); n += d < 0
    return n
def eig(u, h, k):  # k-th lowest eigenvalue by bisection on the count
    lo, hi = -10.0, 0.0
    for _ in range(60):
        m = (lo + hi) / 2
        if below(u, h, m) >= k: hi = m
        else: lo = m
    return (lo + hi) / 2
def grid(h): return [-20 + i * h for i in range(round(40 / h))]
def wells(A, h): return [eig([-A / math.cosh(x)**2 for x in grid(h)], h, k) for k in (1, 2)]
def kdv(h, nl=1.0):  # periodic method of lines on [-20, 20), RK4, dt = 0.83 h^3, to t = 0.5
    xs = grid(h); N = len(xs); u = [-6 / math.cosh(x)**2 for x in xs]
    n = 2 * round(0.3 / h**3); dt = 0.5 / n
    def f(v): return [nl * 6 * v[j] * (v[(j+1) % N] - v[j-1]) / (2*h)
                      - (v[(j+2) % N] - 2*v[(j+1) % N] + 2*v[j-1] - v[j-2]) / (2*h**3) for j in range(N)]
    for _ in range(n):
        k1 = f(u); k2 = f([a + dt/2*b for a, b in zip(u, k1)]); k3 = f([a + dt/2*b for a, b in zip(u, k2)])
        k4 = f([a + dt*b for a, b in zip(u, k3)])
        u = [a + dt/6*(b + 2*c + 2*d + e) for a, b, c, d, e in zip(u, k1, k2, k3, k4)]
    return xs, u
E = {h: wells(6, h) for h in (0.1, 0.05)}
print("bound states of L = -d2/dx2 + u at t = 0, grid on [-20, 20]:")
for h in (0.1, 0.05):
    print(f"  h = {h:.2f}: {below([-6 / math.cosh(x)**2 for x in grid(h)], h, 0.0)} below zero, E = {E[h][0]:.6f}, {E[h][1]:.6f}")
kap = [math.sqrt(-(4 * E[0.05][k] - E[0.1][k]) / 3) for k in (0, 1)]
print(f"  extrapolated: kappa = {kap[0]:.5f}, {kap[1]:.5f}; depths 2 kappa^2 = {2*kap[0]**2:.4f}, {2*kap[1]**2:.4f}; speeds 4 kappa^2 = {4*kap[0]**2:.4f}, {4*kap[1]**2:.4f}")
assert abs(kap[0] - 2) < 1e-4 and abs(kap[1] - 1) < 1e-4
xq = [-20 + i * 0.01 for i in range(4001)]; c2 = []
for k, psi in ((2, lambda x: 1 / math.cosh(x)**2), (1, lambda x: math.sinh(x) / math.cosh(x)**2)):
    r = max(abs(-(psi(x+1e-3) - 2*psi(x) + psi(x-1e-3)) / 1e-6 - 6 / math.cosh(x)**2 * psi(x) + k*k*psi(x)) for x in (-1.3, 0.4, 2.2))
    c2.append(psi(10.0)**2 * math.exp(2 * k * 10.0) / (sum(psi(x)**2 for x in xq) * 0.01)); assert r < 1e-4
print(f"norming constants c^2 at t = 0: {c2[0]:.6f} (kappa = 2), {c2[1]:.6f} (kappa = 1)")
assert abs(c2[0] - 12) < 1e-6 and abs(c2[1] - 6) < 1e-6
def refl(A, k, X=12.0, n=2400):  # |R(k)| for u = -A sech^2 x, RK4 from x = X back to -X
    hh = 2 * X / n; x = X
    def g(x, y): V = -A / math.cosh(x)**2 - k * k; return [y[1], V * y[0], y[3], V * y[2]]
    y = [math.cos(k*X), -k*math.sin(k*X), math.sin(k*X), k*math.cos(k*X)]
    for _ in range(n):
        k1 = g(x, y); k2 = g(x - hh/2, [a - hh/2*b for a, b in zip(y, k1)])
        k3 = g(x - hh/2, [a - hh/2*b for a, b in zip(y, k2)]); k4 = g(x - hh, [a - hh*b for a, b in zip(y, k3)])
        y = [a - hh/6*(b + 2*c + 2*d + e) for a, b, c, d, e in zip(y, k1, k2, k3, k4)]; x -= hh
    P, P1, Q, Q1 = y
    return math.hypot(P - Q1/k, Q + P1/k) / math.hypot(P + Q1/k, Q - P1/k)
def refl_formula(A, k):
    l = (-1 + math.sqrt(1 + 4 * A)) / 2; s = math.sin(math.pi * l)**2
    return math.sqrt(s / (math.sinh(math.pi * k)**2 + s))
for A in (6, 5):
    r = [refl(A, k) for k in (0.5, 1.0)]
    print(f"u = -{A} sech^2 x: |R| at k = 0.5, 1 by RK4 {r[0]:.6f}, {r[1]:.6f}; formula {refl_formula(A, 0.5):.6f}, {refl_formula(A, 1.0):.6f}")
    assert abs(r[1] - refl_formula(A, 1.0)) < 1e-6
def glm(x, t, n):  # K(x, x) from K(x,y) + F(x+y) + int_x^inf K(x,z) F(z+y) dz = 0, Simpson on [x, x+20]
    Fn = lambda s: 6 * math.exp(8*t - s) + 12 * math.exp(64*t - 2*s)
    hh = 20 / n; ys = [x + i * hh for i in range(n + 1)]
    w = [hh / 3 * (1 if i in (0, n) else 4 if i % 2 else 2) for i in range(n + 1)]
    M = [[(i == j) + w[j] * Fn(ys[j] + ys[i]) for j in range(n + 1)] + [-Fn(x + ys[i])] for i in range(n + 1)]
    for c in range(n + 1):
        p = max(range(c, n + 1), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n + 1):
            f = M[r][c] / M[c][c]; Mr, Mc = M[r], M[c]
            for j in range(c, n + 2): Mr[j] -= f * Mc[j]
    s = [0.0] * (n + 1)
    for r in range(n, -1, -1): s[r] = (M[r][n + 1] - sum(M[r][j] * s[j] for j in range(r + 1, n + 1))) / M[r][r]
    return s[0]
def u_glm(x, t, n): return -(glm(x + 1e-3, t, n) - glm(x - 1e-3, t, n)) / 1e-3
xd = gold(lambda x: u_ist(x, 0.5), 6, 11); xs_ = gold(lambda x: u_ist(x, 0.5), -1, 4)
g = [u_glm(0.0, 0.0, n) for n in (200, 400)] + [u_glm(xd, 0.5, 400)]
print(f"GLM as a linear system: u(0, 0) = {g[0]:.6f} (n = 200), {g[1]:.6f} (n = 400), order {math.log2((g[0] + 6) / (g[1] + 6)):.2f}; u({xd:.4f}, 0.5) = {g[2]:.6f}")
print(f"  GLM determinant: u(0, 0) = {u_ist(0, 0):.6f}, u({xd:.4f}, 0.5) = {u_ist(xd, 0.5):.6f}")
assert abs(g[1] + 6) < 1e-3 and abs(g[2] - u_ist(xd, 0.5)) < 1e-3
dev = max(abs(u_ist(x / 10, t) - u_book(x / 10, t)) for x in range(-100, 201) for t in (0.0, 0.25, 0.5))
assert dev < 1e-12; print("  determinant against the textbook two-soliton formula: max gap under 1e-12")
print("scattering data in time:  t   ln c1^2   ln c2^2   deep dip   shallow dip")
for t in (0.0, 0.25, 0.5):
    a = gold(lambda x: u_ist(x, t), 16 * t - 2, 16 * t + 2); b = gold(lambda x: u_ist(x, t), -1, 4)
    print(f"  {t:.2f}  {math.log(6) + 8*t:.4f}  {math.log(12) + 64*t:.4f}  x = {round(a, 4) + 0.0:.4f}, u = {u_ist(a, t):.4f}  x = {round(b, 4) + 0.0:.4f}, u = {u_ist(b, t):.4f}")
runs = {h: kdv(h) for h in (0.1, 0.05)}
err = {h: max(abs(a - u_ist(x, 0.5)) for x, a in zip(runs[h][0], runs[h][1])) for h in runs}
rich = max(abs((4 * a - b) / 3 - u_ist(x, 0.5)) for x, a, b in zip(runs[0.05][0][::2], runs[0.05][1][::2], runs[0.1][1]))
print(f"KdV solve to t = 0.5, max error: h = 0.1 {err[0.1]:.4f}, h = 0.05 {err[0.05]:.4f}, order {math.log2(err[0.1] / err[0.05]):.2f}; extrapolated {rich:.4f}")
assert err[0.05] < 0.3 and rich < 0.05
for h in (0.1, 0.05):
    e = [eig(runs[h][1], h, k) for k in (1, 2)]
    print(f"  bound states on the solve, h = {h:.2f}, t = 0.5: E = {e[0]:.6f}, {e[1]:.6f}; drift from t = 0: {e[0] - E[h][0]:.6f}, {e[1] - E[h][1]:.6f}")
    assert abs(e[0] - E[h][0]) < 0.05 * h / 0.1 and abs(e[1] - E[h][1]) < 0.05 * h / 0.1
def ints(u, h):
    N = len(u); return [sum(u) * h, sum(a * a for a in u) * h, sum(u[j]**3 + ((u[(j+1) % N] - u[j-1]) / (2*h))**2 / 2 for j in range(N)) * h]
I0, I5 = ints([-6 / math.cosh(x)**2 for x in grid(0.05)], 0.05), ints(runs[0.05][1], 0.05)
K = [-4 * sum(kap), 16 / 3 * sum(k**3 for k in kap), -32 / 5 * sum(k**5 for k in kap)]
for name, a, b, c in zip(("int u", "int u^2", "int u^3 + u_x^2/2"), I0, I5, K):
    print(f"conserved {name}: grid t = 0 {a:.4f}, solve t = 0.5 {b:.4f}, from kappa {c:.3f}"); assert abs(b - c) < 0.01 * abs(c)
lin = min(kdv(0.1, 0.0)[1]); w5 = wells(5, 0.05); w5b = wells(5, 0.1)
k5 = [math.sqrt(-(4 * w5[k] - w5b[k]) / 3) for k in (0, 1)]; l5 = (-1 + math.sqrt(21)) / 2
print(f"what breaks: two separate solitons added, at x = 0, t = 0: {-8 / math.cosh(0)**2 - 2:.4f}, not -6")
print(f"  c_n run backwards: deep dip at x = {gold(lambda x: u_ist(x, 0.5, -1), -11, -6):.4f}; no 6 u u_x term: deepest u {lin:.4f} at t = 0.5")
print(f"  start -5 sech^2 x: kappa = {k5[0]:.5f}, {k5[1]:.5f} (exact {l5:.5f}, {l5 - 1:.5f}); depths {2*k5[0]**2:.4f}, {2*k5[1]**2:.4f}")
assert abs(k5[0] - l5) < 1e-4 and abs(k5[1] - l5 + 1) < 1e-4
h0, Lu = 1.0, 10.0; c0 = math.sqrt(9.81 * h0); T, H = 6 * Lu**3 / (c0 * h0**2), 2000 * h0**3 / (3 * Lu**2)  # make KdV's coefficients 1, -6
print(f"canal {h0:.0f} m deep, length unit {Lu:.0f} m: c0 = {c0:.4f} m/s, time unit T = 6 (10 m)^3 / (c0 h0^2) = {T:.2f} s, height unit H = 2 h0^3 / (3 (10 m)^2) = {H:.4f} mm")
print(f"  start {6 * H:.2f} mm; solitons {8 * H:.2f} mm, {2 * H:.2f} mm, extra speeds {16 * Lu / T:.4f}, {4 * Lu / T:.4f} m/s (c0 a / 2h0 for height a: {c0 * 8 * H / 2000 / h0:.4f}); t = 0.5 is {T / 2:.1f} s")
assert abs(16 * Lu / T - c0 * 8 * H / 2000 / h0) < 1e-12 and abs(4 * Lu / T - c0 * 2 * H / 2000 / h0) < 1e-12   # Dispersion's solitary-wave speed
print(f"  at t = 0.5 the marker has moved {c0 * T / 2:.1f} m; humps {10 * xd:.2f} m and {10 * xs_:.2f} m ahead of it, gap {10 * (xd - xs_):.2f} m")
print("chart: water height in mm at 2.5 m steps from -20 m to 100 m, t = 0, 0.25, 0.5:")
for t in (0.0, 0.25, 0.5): print("  " + ", ".join(f"{-u_ist(-2 + i / 4, t) * H:.1f}" for i in range(49)))
print("ALL CHECKS PASS")
