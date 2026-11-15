# Linear or not -- the check behind the card.  Standard library only.
# Plate: u_t = KAPPA (u_xx + u_yy) on a 1 m square, edges held at the frame's
# 20 C, u = temperature above the frame.  Burgers: u_t + u u_x = 0, u in m/s.
# Roads: closed forms; an explicit grid; residuals by centred differences;
# characteristics by bisection; a probe test that grades an equation.
from math import sin, pi, exp, gcd

KAPPA, HOUR, X0, Y0 = 1.2e-5, 3600.0, 0.25, 0.5  # m^2/s (illustrative), s, m, m

def mode(amp, m, n, x, y, t):                     # one cooling profile
    return amp * sin(m * pi * x) * sin(n * pi * y) * exp(-(m * m + n * n) * pi * pi * KAPPA * t)
def uA(x, y, t): return mode(30.0, 1, 1, x, y, t)  # warm middle, 30 C up
def uB(x, y, t): return mode(10.0, 2, 1, x, y, t)  # left half up, right half down
def uS(x, y, t): return uA(x, y, t) + uB(x, y, t)  # the sum

def heat_res(f, x, y, t, h, k):                   # u_t - KAPPA * Laplacian
    ut = (f(x, y, t + k) - f(x, y, t - k)) / (2 * k)
    lap = (f(x + h, y, t) + f(x - h, y, t) + f(x, y + h, t) + f(x, y - h, t) - 4 * f(x, y, t)) / h ** 2
    return ut - KAPPA * lap

def grid(n, dt):                                  # explicit scheme from the summed start
    h = 1.0 / n
    u = [[uS(i * h, j * h, 0.0) if 0 < i < n and 0 < j < n else 0.0 for j in range(n + 1)] for i in range(n + 1)]
    r = KAPPA * dt / h ** 2
    assert r <= 0.25                              # stability limit of the scheme
    for _ in range(round(HOUR / dt)):
        v = [row[:] for row in u]
        for i in range(1, n):
            for j in range(1, n):
                v[i][j] = u[i][j] + r * (u[i+1][j] + u[i-1][j] + u[i][j+1] + u[i][j-1] - 4 * u[i][j])
        u = v
    return u[round(X0 * n)][round(Y0 * n)]

a0, b0, a1, b1 = uA(X0, Y0, 0), uB(X0, Y0, 0), uA(X0, Y0, HOUR), uB(X0, Y0, HOUR)
s1 = a1 + b1
print(f"plate start at (0.25 m, 0.5 m): A {a0:.2f} C, B {b0:.2f} C, sum {a0 + b0:.2f} C")
print(f"plate after 1 h: A {a1:.2f} C, B {b1:.2f} C, sum {s1:.2f} C")
eA, eB = 2 * pi * pi * KAPPA * HOUR, 5 * pi * pi * KAPPA * HOUR
print(f"time constants: A {HOUR / eA:.0f} s ({HOUR / eA / 60:.1f} min), B {HOUR / eB:.0f} s ({HOUR / eB / 60:.1f} min)")
print(f"by hand: sin(pi/4) {sin(pi / 4):.4f}; exponents {eA:.4f} and {eB:.4f}; factors {exp(-eA):.4f} and {exp(-eB):.4f}")
ut = (uS(X0, Y0, HOUR + 10) - uS(X0, Y0, HOUR - 10)) / 20
print(f"rate of change of the sum after 1 h: {ut:.3e} C/s")
rs = [heat_res(uS, X0, Y0, HOUR, h, 10.0) for h in (0.02, 0.01)]
print(f"residual of the sum, h = 0.02 m and 0.01 m: {rs[0]:.1e} and {rs[1]:.1e} C/s, ratio {rs[0] / rs[1]:.1f}")
assert abs(rs[0]) < 1e-3 * abs(ut) and 3.5 < rs[0] / rs[1] < 4.5   # step error only: falls as h^2
g1, g2 = grid(20, 40.0), grid(40, 10.0)
print(f"grid from the summed start: h = 0.05 m {g1:.3f} C, h = 0.025 m {g2:.3f} C, exact {s1:.3f} C")
print(f"grid errors {g1 - s1:.4f} C and {g2 - s1:.4f} C, ratio {(g1 - s1) / (g2 - s1):.1f}")
assert abs(g1 - s1) < 0.05 and abs(g2 - s1) < 0.015
frame = (20 + a1) + (20 + b1)
print(f"mistake, add whole temperatures: {frame:.2f} C, right: {20 + s1:.2f} C")
def z(v): return 0.0 if abs(v) < 0.005 else v    # print a rounding speck at an edge as 0
for i in range(11):
    x = i / 10
    print(f"chart, x = {x:.1f} m, A {z(uA(x, Y0, HOUR)):.2f}, B {z(uB(x, Y0, HOUR)):.2f}, sum {z(uS(x, Y0, HOUR)):.2f}")

def v1(x, t): return x / (1 + t)                  # cloud that left x = 0 one second ago
def v2(x, t): return x / (0.5 + t)                # cloud that left half a second ago
def vS(x, t): return v1(x, t) + v2(x, t)
def burg_res(f, x, t, h):
    return (f(x, t + h) - f(x, t - h)) / (2 * h) + f(x, t) * (f(x + h, t) - f(x - h, t)) / (2 * h)
def charac(u0, x, t):                             # solve x = x0 + u0(x0) t by bisection
    lo, hi = -100.0, 100.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if mid + u0(mid) * t < x: lo = mid
        else: hi = mid
    return u0((lo + hi) / 2)
print(f"Burgers flows at (1 m, 1 s): v1 {v1(1.0, 1.0):.4f} m/s, v2 {v2(1.0, 1.0):.4f} m/s")
xi, ti = 1, 1                                     # the point (1 m, 1 s), in whole units
cn, cd = 4 * xi, (1 + ti) * (1 + 2 * ti)          # (v1 v2)_x = 2x/((1+t)(0.5+t)) = 4x/((1+t)(1+2t))
for h in (1e-2, 1e-3):
    print(f"Burgers residual of v1 + v2 at (1 m, 1 s), h = {h}: {burg_res(vS, 1.0, 1.0, h):.4f} m/s^2")
    assert abs(burg_res(v1, 1.0, 1.0, h)) < 1e-4 and abs(burg_res(v2, 1.0, 1.0, h)) < 1e-4
    assert abs(burg_res(vS, 1.0, 1.0, h) - cn / cd) < 1e-3     # the sum's residual is the cross term
gg = gcd(cn, cd)
print(f"cross term (v1 v2)_x at (1 m, 1 s): {cn // gg}/{cd // gg} m/s^2")
true = charac(lambda x: 3 * x, 1.0, 1.0)
print(f"flow from the summed start at (1 m, 1 s): {true:.4f} m/s; v1 + v2 gives {vS(1.0, 1.0):.4f} m/s")
assert abs(true - 3 / (1 + 3 * 1.0)) < 1e-9
dbl = charac(lambda x: 2 * x, 1.0, 1.0)
print(f"flow from the doubled start: {dbl:.4f} m/s; 2 v1 gives {2 * v1(1.0, 1.0):.4f} m/s")
assert abs(dbl - 2 / (1 + 2 * 1.0)) < 1e-9
print(f"Burgers residual of 2 v1 at (1 m, 1 s): {burg_res(lambda x, t: 2 * v1(x, t), 1.0, 1.0, 1e-3):.4f} m/s^2")

# Grade by probing F(u, u_x, u_y, u_xx, u_xy, u_yy) at fixed jets; y is time in an evolution
# equation; constants are 1 (a grade depends on where u sits).  Order 1: top = (u_x, u_y).
EQS = [("heat u_t = u_xx", 2, lambda j: j[2] - j[3], "linear"),
       ("heat with a torch, source 5", 2, lambda j: j[2] - j[3] - 5, "linear"),
       ("heat with radiation u^4", 2, lambda j: j[2] - j[3] + j[0] ** 4, "semilinear"),
       ("viscous Burgers", 2, lambda j: j[2] + j[0] * j[1] - j[3], "semilinear"),
       ("conductivity 1 - u", 2, lambda j: j[2] - (1 - j[0]) * j[3] + j[1] ** 2, "quasilinear"),
       ("Burgers u_t + u u_x", 1, lambda j: j[2] + j[0] * j[1], "quasilinear"),
       ("eikonal u_x^2 + u_y^2 = 1", 1, lambda j: j[1] ** 2 + j[2] ** 2 - 1, "fully nonlinear"),
       ("Monge-Ampere u_xx u_yy - u_xy^2 = 1", 2, lambda j: j[3] * j[5] - j[4] ** 2 - 1, "fully nonlinear")]
P = [[1, 2, -1, 3, 1, -2], [-2, 1, 3, -1, 2, 1], [2, -3, 1, 1, -1, 2]]
def add(p, q): return [a + b for a, b in zip(p, q)]
def lin(G, ps):                                   # G additive and 3G(p) = G(3p)?
    return all(abs(G(add(p, q)) - G(p) - G(q)) < 1e-9 and abs(G([3 * a for a in p]) - 3 * G(p)) < 1e-9
               for p in ps for q in ps)
def grade(k, F):
    top = [1, 2] if k == 1 else [3, 4, 5]
    def split(L, T): return [T[i] if i in top else (L[i] if i < top[0] else 0) for i in range(6)]
    def D(L): return lambda T: F(split(L, T)) - F(split(L, [0] * 6))
    if lin(lambda j: F(j) - F([0] * 6), P): return "linear"
    if not all(lin(D(L), P) for L in P): return "fully nonlinear"
    same = all(abs(D(L)(T) - D(P[0])(T)) < 1e-9 for L in P for T in P)
    return "semilinear" if same else "quasilinear"
for name, k, F, want in EQS:
    g = grade(k, F)
    print(f"grade: {name}: {g}")
    assert g == want
print("ALL CHECKS PASS")
