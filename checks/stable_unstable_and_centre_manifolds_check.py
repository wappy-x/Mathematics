# Invariant manifolds -- the check behind the card.  Standard library only.
# Saddle: x' = x, y' = -y + x^2.  Centre: x' = xy, y' = -y - x^2, and its twin
# y' = -y + x^2.  Road one: power series that the flow must leave unchanged.
# Road two: Runge-Kutta 4, written out here, run on the full system.
from fractions import Fraction as F
from math import pi, log, sqrt, sin
def rk4(f, s, t, h=0.001):
    n = max(1, round(abs(t) / h)); k = t / n          # n equal steps, landing exactly on t
    for _ in range(n):
        a = f(s); b = f((s[0] + k/2*a[0], s[1] + k/2*a[1]))
        c = f((s[0] + k/2*b[0], s[1] + k/2*b[1])); d = f((s[0] + k*c[0], s[1] + k*c[1]))
        s = (s[0] + k/6*(a[0] + 2*b[0] + 2*c[0] + d[0]), s[1] + k/6*(a[1] + 2*b[1] + 2*c[1] + d[1]))
    return s
def centre(sign, n=4):                # y = h(x) = sum a[k] x^k, with h'(x) x h(x) = -h(x) + sign x^2
    a = [F(0)] * (2*n + 1)
    for k in range(2, 2*n + 1, 2):
        a[k] = sign * int(k == 2) - sum(i * a[i] * a[k - i] for i in range(2, k - 1))
    return a
saddle, sad = (lambda s: (s[0], -s[1] + s[0]**2)), [F(int(k == 2), k + 1) for k in range(9)]   # Step 1: (k + 1) a_k = [k = 2]
hs, dhs = (lambda x: sum(c * x**k for k, c in enumerate(sad))), (lambda x: sum(k * c * x**(k - 1) for k, c in enumerate(sad) if k))
print("saddle x' = x, y' = -y + x^2: J = [[1, 0], [0, -1]], eigenvalues 1 and -1")
print("unstable manifold y = a2 x^2 + ... + a8 x^8: " + ", ".join(str(sad[k]) for k in range(2, 9)))
assert all(dhs(x) * saddle((x, hs(x)))[0] == saddle((x, hs(x)))[1] for x in map(F, range(-4, 5)))   # h' f = g at 9 points: degree 8, so everywhere
for y0 in (0.0, 1.0):
    x1, y1 = rk4(saddle, (0.01, y0), log(100))
    assert abs(y1 - (1/3 + (y0 - 0.01**2/3) / 100)) < 1e-9    # exact: gap y - x^2/3 falls like e^-t
    print(f"start (0.01, {y0:g}), t = ln 100 = {log(100):.6f}: x = {x1:.6f}, y = {y1:.6f}, curve x^2/3 = {x1**2/3:.6f}")
print(f"stable manifold x = 0: start (0, 1), y at t = 5: {rk4(saddle, (0.0, 1.0), 5)[1]:.6f} = e^-5")
a, b = centre(-1), centre(+1)
print("centre x' = xy, y' = -y - x^2: J = [[0, 0], [0, -1]], eigenvalues 0 and -1")
print("centre manifold y = h(x), coefficients of x^2, x^4, x^6, x^8: " + ", ".join(str(a[k]) for k in (2, 4, 6, 8)))
assert [a[k] for k in (2, 4, 6, 8)] == [-1, -2, -12, -112]
h = lambda x: sum(float(a[k]) * x**k for k in (2, 4, 6))
full = lambda s: (s[0] * s[1], -s[1] - s[0]**2)
gaps = [(t, rk4(full, (0.3, 0.2), t)) for t in (0, 2, 4, 8)]
print("start (0.3, 0.2): gap y - h(x) at t = 0, 2, 4, 8: " + ", ".join(f"{s[1] - h(s[0]):.6f}" for t, s in gaps)
      + f"; x at t = 8: {gaps[-1][1][0]:.6f}")
assert abs(gaps[-1][1][1] - h(gaps[-1][1][0])) < 0.01 * abs(0.2 - h(0.3))
xf = rk4(full, (0.3, h(0.3)), 100, 0.01)[0]
xr, x3 = rk4(lambda s: (s[0] * h(s[0]), 0.0), (0.3, 0.0), 100, 0.01)[0], 0.3 / sqrt(1 + 2*0.09*100)
assert abs(xf - xr) < 0.1 * abs(xf - x3)        # the x^5 term earns its place
print(f"from x = 0.3 on the curve, x at t = 100: full system {xf:.6f}, reduced x' = x h(x) {xr:.6f}, x' = -x^3 alone {x3:.6f}")
xg = rk4(lambda s: (s[0] * s[1], -s[1] + s[0]**2), (0.3, sum(float(b[k]) * 0.3**k for k in (2, 4, 6))), 6)[0]
assert b[2] == 1 and b[4] == -2 and xg > 0.6
print(f"twin y' = -y + x^2, same J: coefficients {b[2]}, {b[4]}, so x' = +x^3 - 2x^5; from 0.3, x at t = 6: {xg:.6f}")
print(f"mistake 1, tangent line y = 0 as the way out of the saddle: y = 0 at x = 1, truly {float(sad[2]):.6f}")
print(f"mistake 2, centre curve taken as y = 0: x' = 0, x stays 0.3; truly {xf:.6f} at t = 100")
swing, ls, tops = lambda s: (s[1], -sin(s[0]) - 0.5 * s[1]), 0.5 * (-0.5 - sqrt(4.25)), []
for e in (1e-5, 1e-7):                  # start on the swing's stable line at the top, run back
    s = p = (pi - e, -ls * e)
    while s[0] > 0:
        p, s = s, rk4(swing, s, -0.001)
    tops.append(p[1] + (s[1] - p[1]) * p[0] / (p[0] - s[0]))
assert abs(tops[0] - tops[1]) < 1e-6 and tops[0] > 2
print(f"swing, upright rest: stable manifold meets theta = 0 at speed {tops[0]:.4f} rad per unit (2 without damping)")
P = lambda x, y, X, Y, k: f"{X + k*x:.1f},{Y - k*y:.1f}"
print("figure, saddle curve: " + " ".join(P(x/2, x*x/12, 160, 200, 100) for x in range(-3, 4)))
print("figure, centre curve: " + " ".join(P(x/10, h(x/10), 480, 110, 250) for x in range(-4, 5, 2))
      + "; path at t = 0, 2, 4, 8: " + " ".join(P(*s, 480, 110, 250) for t, s in gaps))
print("ALL CHECKS PASS")
