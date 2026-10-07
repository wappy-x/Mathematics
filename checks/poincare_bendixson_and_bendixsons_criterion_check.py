# Poincare-Bendixson and Bendixson's criterion -- the check behind the card.  Only
# math primitives imported.  Oscillator r' = r(1 - r^2), angle' = 1, in x, y (volts, ms);
# shock absorber p' = v, v' = -5p - 2v (cm, s).  Two roads each time, see the card.
from math import sin, cos, exp, sqrt, pi
def ring(p): x, y = p; s = x * x + y * y; return (x - y - x * s, x + y - y * s)
def shock(p): x, v = p; return (v, -5 * x - 2 * v)
def add(p, k, c): return (p[0] + c * k[0], p[1] + c * k[1])
def rk4(F, p, h, n):                                     # Runge-Kutta 4, written out
    for _ in range(n):
        k1 = F(p); k2 = F(add(p, k1, h / 2)); k3 = F(add(p, k2, h / 2)); k4 = F(add(p, k3, h))
        p = (p[0] + h * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]) / 6, p[1] + h * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]) / 6)
    return p
def closed(r0, t): return 1 / sqrt(1 + (1 / r0 ** 2 - 1) * exp(-2 * t))
def div(F, p, e=1e-5):                                   # f_x + g_y by central differences
    return (F((p[0] + e, p[1]))[0] - F((p[0] - e, p[1]))[0] + F((p[0], p[1] + e))[1] - F((p[0], p[1] - e))[1]) / (2 * e)
def flux(F, a, b, n=4000):                               # line integral of f dy - g dx round an ellipse
    S = [2 * pi * (i + 0.5) / n for i in range(n)]
    return sum((F((a * cos(s), b * sin(s)))[0] * b * cos(s) + F((a * cos(s), b * sin(s)))[1] * a * sin(s)) * 2 * pi / n for s in S)
def disk(F, R, n=1000, m=32):                            # double integral of the divergence over a disk
    return sum(div(F, (r * cos(s), r * sin(s))) * r * (R / n) * (2 * pi / m)
               for r in [(i + 0.5) * R / n for i in range(n)] for s in [2 * pi * (j + 0.5) / m for j in range(m)])
def rad(r, a): x, y = r * cos(a), r * sin(a); f, g = ring((x, y)); return (x * f + y * g) / r, (x * g - y * f) / r ** 2
def area(P): return abs((P[1][0] - P[0][0]) * (P[2][1] - P[0][1]) - (P[2][0] - P[0][0]) * (P[1][1] - P[0][1])) / 2
def f6(xs): return " ".join(f"{x:.6f}" for x in xs)
print("oscillator r' = r(1 - r^2), angle' = 1; shock absorber p'' + 2p' + 5p = 0")
rims = [[rad(R, 2 * pi * j / 360) for j in range(360)] for R in (0.5, 2.0)]
print("rims r = 0.5, 2: radial rate", " ".join(f"{min(q[0] for q in w):.6f}..{max(q[0] for q in w):.6f}" for w in rims)
      + f"; angular rate min {min(q[1] for w in rims for q in w):.6f}")
ts, rk = (2, 4, 8), {}
for r0 in (0.5, 2.0):
    rk[r0] = [sqrt(sum(c * c for c in rk4(ring, (r0, 0.0), 0.01, 100 * t))) for t in ts]
    print(f"from r = {r0}, r at t = 2, 4, 8 ms: closed {f6(closed(r0, t) for t in ts)}")
    print(f"from r = {r0}, r at t = 2, 4, 8 ms: RK4    {f6(rk[r0])}")
err = [abs(sqrt(sum(c * c for c in rk4(ring, (0.5, 0.0), h, round(2 / h)))) - closed(0.5, 2)) for h in (0.2, 0.1)]
print(f"RK4 error at t = 2 ms, h = 0.2, 0.1, in millionths: {err[0] * 1e6:.3f} {err[1] * 1e6:.3f}; ratio {err[0] / err[1]:.2f}")
back = rk4(ring, (1.0, 0.0), 2 * pi / 6283, 6283)
print(f"start on the cycle at (1, 0): after {2 * pi:.6f} ms the gap is {sqrt((back[0] - 1) ** 2 + back[1] ** 2):.6f}")
print("oscillator divergence at r = 0, 0.5, 1, 2:", f6(div(ring, (r, 0.0)) for r in (0, 0.5, 1, 2)))
g1, g2 = (flux(ring, 0.5, 0.5), disk(ring, 0.5)), (flux(ring, 1, 1), disk(ring, 1))
print(f"Green, circle r = 0.5: line {g1[0]:.5f} area {g1[1]:.5f}; cycle r = 1: line {g2[0]:.5f} area {g2[1]:.5f}")
dv = [div(shock, p) for p in ((0, 0), (3, -4), (-10, 7))]
T0 = ((1.0, 0.0), (1.01, 0.0), (1.0, 0.01)); ratio = area([rk4(shock, p, 0.001, 1000) for p in T0]) / area(T0)
print(f"shock divergence at (0,0), (3,-4), (-10,7): {f6(dv)}; patch area after 1 s x {ratio:.6f}, e^(-2) = {exp(-2):.6f}")
ell = (flux(shock, sqrt(5), 5), -2 * pi * sqrt(5) * 5)
print(f"ellipse 5p^2 + v^2 = 25: line integral {ell[0]:.6f}; -2 x area {ell[1]:.6f}")
E = [5 * p[0] ** 2 + p[1] ** 2 for p in (rk4(shock, (sqrt(5), 0.0), 0.001, 1000 * t) for t in (0, 2, 4))]
print(f"mistake 1, rest inside: energy 5p^2 + v^2 at t = 0, 2, 4 s: {f6(E)}")
gap = min(abs(k * sqrt(2) - round(k * sqrt(2))) * 2 * pi for k in range(1, 1001))
print(f"mistake 2, doughnut angles' = 1, sqrt 2: closest return in 1000 laps {gap:.6f} rad, not 0")
X = lambda p: f"{180 + 50 * p[0]:.1f},{120 - 50 * p[1]:.1f}"
for r0 in (0.5, 2.0):
    print(f"figure, from r = {r0}, t = 0 to 4 ms every 0.25:", " ".join(X(rk4(ring, (r0, 0.0), 0.01, 25 * k)) for k in range(17)))
assert max(abs(rk[r0][i] - closed(r0, t)) for r0 in rk for i, t in enumerate(ts)) < 1e-8 and min(q[0] for q in rims[0]) > 0 > max(q[0] for q in rims[1])
assert 14 < err[0] / err[1] < 18                         # error falls 16-fold as h halves: order 4
assert abs(ratio - exp(dv[1] * 1)) < 1e-6                # Liouville: area shrinks at the divergence
assert abs(g1[0] - g1[1]) < 1e-5 and abs(ell[0] - ell[1]) < 1e-6   # Green's two sides agree
print("ALL CHECKS PASS")
