# Complex roots and damped oscillation -- the check behind the card.  Standard
# library only; math gives sin, cos, exp, log, sqrt, pi and nothing more.  The
# car: y'' + 2y' + 5y = 0, height y in cm, time t in s, y(0) = 1, y'(0) = 0.
# Road one: the formula built from the complex roots.  Road two: Euler's rule,
# small steps along the rates, which never calls sin, cos or exp.
from math import sin, cos, exp, log, sqrt, pi
P, Q, Y0, V0 = 2.0, 5.0, 1.0, 0.0
def cmul(z, w):                               # complex numbers as (real, imaginary) pairs
    return (z[0] * w[0] - z[1] * w[1], z[0] * w[1] + z[1] * w[0])
A, B = -P / 2, sqrt(Q - P * P / 4)            # the roots a +/- ib, by the quadratic formula
C, D = Y0, (V0 - A * Y0) / B                  # fitted to the start
R = sqrt(C * C + D * D)                       # the envelope's starting height
def formula(t):
    return exp(A * t) * (C * cos(B * t) + D * sin(B * t))
def step(p, h, t_end):                        # Euler's rule: y += h y', y' += h y''
    y, v, ys = Y0, V0, [Y0]
    for _ in range(round(t_end / h)):
        y, v = y + h * v, v + h * (-p * v - Q * y)
        ys.append(y)
    return ys
def bisect(f, lo, hi):                        # f changes sign between lo and hi
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2
sq = cmul((A, B), (A, B)); left = (sq[0] + P * A + Q, sq[1] + P * B)
z = (1.0, 2.0 / 2 ** 30)                      # 1 + 2i/2^30, squared 30 times
for _ in range(30): z = cmul(z, z)
h = 0.00025; ys = step(P, h, 4.0)
k = next(i for i in range(len(ys) - 1) if ys[i] > 0 >= ys[i + 1])
cross_step = h * (k + ys[k] / (ys[k] - ys[k + 1]))
cross = bisect(formula, 0.5, 1.5); dip = formula(pi / B)
errs = [max(abs(y - formula(i * s)) for i, y in enumerate(step(P, s, 4.0))) for s in (0.001, 0.0005, 0.00025)]
print(f"equation y'' + 2y' + 5y = 0, y(0) = 1 cm, y'(0) = 0 cm/s; discriminant p^2 - 4q = {P * P - 4 * Q:.0f}")
print(f"roots a +/- ib = {A:.0f} +/- {B:.0f}i; r^2 + 2r + 5 at r = -1 + 2i gives {left[0]:.6f} + {left[1]:.6f}i")
print(f"Euler's formula by a limit: (1 + 2i/2^30)^(2^30) = {z[0]:.6f} + {z[1]:.6f}i; cos 2 + i sin 2 = {cos(2):.6f} + {sin(2):.6f}i")
print(f"C = {C:.6f}, D = {D:.6f}; envelope R = {R:.6f} cm")
print(f"envelope halves every {log(2) / -A:.6f} s; period {2 * pi / B:.6f} s; one period multiplies height by {exp(A * 2 * pi / B):.6f}")
print(f"first zero crossing: formula {cross:.6f} s, stepped {cross_step:.3f} s")
print(f"deepest dip: formula {dip:.6f} cm at {pi / B:.6f} s, stepped {min(ys):.3f} cm")
print(f"Euler's rule, worst error 0 to 4 s at steps 0.001, 0.0005, 0.00025 s: {errs[0]:.6f}, {errs[1]:.6f}, {errs[2]:.6f} cm")
print("chart y:", ", ".join(f"{formula(i / 4):.2f}" for i in range(17)))
print("chart envelope:", ", ".join(f"{R * exp(A * i / 4):.2f}" for i in range(17)))
pts = [(100 + 200 * exp(A * t) * cos(B * t), 170 - 200 * exp(A * t) * sin(B * t)) for t in [i / 8 for i in range(25)]]
print("figure, spiral e^((-1+2i)t), t = 0 to 3 s by 0.125, svg px:", " ".join(f"{x:.0f},{y:.0f}" for x, y in pts))
count = {}
for p in (2.0, 2 * sqrt(Q), 6.0):
    disc = p * p - 4 * Q; ys10 = step(p, 0.001, 10.0)
    count[p] = sum(1 for u, w in zip(ys10, ys10[1:]) if u > 0 >= w or u < 0 <= w)
    kind = "underdamped" if disc < -1e-9 else "critical" if disc < 1e-9 else "overdamped"
    print(f"p = {p:.3f} per s: discriminant {disc:.3f}, {kind}, zero crossings in 10 s (stepped): {count[p]}")
print(f"mistake D = y'(0) = 0: formula starts at y'(0) = {A * C:.6f} cm/s, not 0")
print(f"mistake sqrt(q) as ring rate: period {2 * pi / sqrt(Q):.6f} s, not {2 * pi / B:.6f}; b read as cycles per s: period {1 / B:.6f} s")
assert abs(z[0] - cos(2)) < 1e-7 and abs(z[1] - sin(2)) < 1e-7     # rotation, by a limit
assert abs(cross - cross_step) < 1e-3 and abs(dip - min(ys)) < 1e-3  # two roads, one motion
assert errs[2] < 1e-3 and 1.8 < errs[0] / errs[1] < 2.2               # error halves with the step
assert [count[p] > 0 for p in count] == [True, False, False]          # the sign of p^2 - 4q decides
print("ALL CHECKS PASS")
