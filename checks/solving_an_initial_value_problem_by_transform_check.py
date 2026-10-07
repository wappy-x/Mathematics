# The round trip -- the check behind the card.  Only math is imported.  Test mass y'' + 2y' + 5y = f(t)
# from rest, y in m, t in s; case 1 is the steady push f = 10, case 2 is f = 10 cos t.  Road one:
# transform, partial fractions, table.  Road two: undetermined coefficients.  Road three: RK4.
from math import exp, cos, sin, pi

def mul(p, q):                                 # polynomials, lowest power first
    r = [0.0] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q): r[i + j] += a * b
    return r

def solve(M, v):                               # Gaussian elimination, row swaps
    A, n = [row[:] + [x] for row, x in zip(M, v)], len(v)
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(A[r][c])); A[c], A[p] = A[p], A[c]
        for r in range(n):
            if r != c: A[r] = [a - A[r][c] / A[c][c] * b for a, b in zip(A[r], A[c])]
    return [A[i][n] / A[i][i] for i in range(n)]

def transform_road(num, P):                    # Y = num / (P (s^2 + 2s + 5)), P = s or s^2 + 1
    k, Q = len(P) - 1, [5.0, 2.0, 1.0]
    cols = [mul([0.0] * j + [1.0], Q) for j in range(k)] + [mul([0.0] * j + [1.0], P) for j in range(2)]
    x = solve([[(c + [0.0] * 4)[i] for c in cols] for i in range(k + 2)], (num + [0.0] * 4)[:k + 2])
    D, C = x[k], x[k + 1]                      # (Cs + D)/((s+1)^2 + 4) -> e^(-t)(C cos 2t + (D - C)/2 sin 2t)
    return x, ([x[0], 0.0, 0.0] if k == 1 else [0.0, x[1], x[0]]) + [C, (D - C) / 2]

def trial_road(F0, Fc):                        # constant K, then A cos t + B sin t
    A, B = solve([[4.0, 2.0], [-2.0, 4.0]], [Fc, 0.0]); c1 = -(F0 / 5.0 + A)   # y(0) = 0
    return [F0 / 5.0, A, B, c1, (c1 - B) / 2]  # y'(0) = B - c1 + 2 c2 = 0

def y(c, t): return c[0] + c[1] * cos(t) + c[2] * sin(t) + exp(-t) * (c[3] * cos(2 * t) + c[4] * sin(2 * t))

def rk4(F0, Fc, h, T):                         # y'' = f - 2y' - 5y, stepped from rest
    g = lambda t, y, v: (v, F0 + Fc * cos(t) - 2 * v - 5 * y)
    u, path = (0.0, 0.0), [(0.0, 0.0)]
    for n in range(round(T / h)):
        t = n * h; k1 = g(t, *u); k2 = g(t + h / 2, u[0] + h / 2 * k1[0], u[1] + h / 2 * k1[1])
        k3 = g(t + h / 2, u[0] + h / 2 * k2[0], u[1] + h / 2 * k2[1]); k4 = g(t + h, u[0] + h * k3[0], u[1] + h * k3[1])
        u = tuple(u[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in (0, 1)); path.append((t + h, u[0]))
    return path

fmt = lambda v: ", ".join(f"{x + 0.0:.6f}" for x in v)
for case, F0, Fc, num, P, part in ((1, 10.0, 0.0, [10.0], [0.0, 1.0], "{0:.6f}/s"), (2, 0.0, 10.0, [0.0, 10.0], [1.0, 0.0, 1.0], "({1:.6f} s {0:+.6f})/(s^2 + 1)")):
    x, c = transform_road(num, P); u = trial_road(F0, Fc)
    print(f"case {case}: Y = {part.format(*x)} + ({x[-1]:.6f} s {x[-2]:+.6f})/(s^2 + 2s + 5)")
    print(f"  transform road  [const, cos t, sin t, e^-t cos 2t, e^-t sin 2t] = {fmt(c)}")
    print(f"  trial road      [const, cos t, sin t, e^-t cos 2t, e^-t sin 2t] = {fmt(u)}")
    assert max(abs(a - b) for a, b in zip(c, u)) < 1e-12              # two roads, one answer
    e = [max(abs(yy - y(c, t)) for t, yy in rk4(F0, Fc, h, 10.0)) for h in (0.1, 0.05)]
    print(f"  RK4 to t = 10: max error {e[0]:.1e} at h = 0.1, {e[1]:.1e} at h = 0.05, ratio {e[0] / e[1]:.1f}; y(1) = {y(c, 1.0):.2f}")
    assert e[1] < 1e-5 and 12 < e[0] / e[1] < 20                     # stepped motion = formula
x, c = transform_road([10.0], [0.0, 1.0]); tp, yp = max(rk4(10.0, 0.0, 0.001, 3.0), key=lambda q: q[1])
print(f"peak by RK4 scan: y = {yp:.6f} m at t = {tp:.3f} s; formula 2 + 2e^(-pi/2) = {2 + 2 * exp(-pi / 2):.6f}, overshoot {100 * exp(-pi / 2):.1f}%")
assert abs(yp - (2 + 2 * exp(-pi / 2))) < 1e-6 and abs(tp - pi / 2) < 1e-3
print("figure, t " + " ".join(f"{0.5 * k:4.1f}" for k in range(13)))
print("figure, y " + " ".join(f"{y(c, 0.5 * k):4.2f}" for k in range(13)))
print(f"mistake 1, push taken as 10 not 10/s: y = 5e^(-t) sin 2t, y(0.5) = {5 * exp(-0.5) * sin(1.0):.3f} m, settles at 0")
print(f"mistake 2, no 1/2 on the sine: starting velocity {-c[3] + 2 * (x[1] - x[2]):.1f} m/s, not 0")
print(f"mistake 3, (s - 1)^2 + 4 for (s + 1)^2 + 4: y(5) = {y(c[:3] + [0, 0], 5.0) + exp(5.0) * (c[3] * cos(10.0) + (x[1] + x[2]) / 2 * sin(10.0)):.1f} m")
print("ALL CHECKS PASS")
