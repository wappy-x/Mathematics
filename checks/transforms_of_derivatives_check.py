# Transforming a derivative -- the check behind the card.  Only math.exp is
# imported.  The car body: y'' + 2y' + 5y = 0, released from 1 cm at rest.
# Road one steps the motion with Runge-Kutta 4 and adds up e^(-st) times the
# height, velocity and acceleration as it goes, never using the rule.  Road two
# is the rule: multiply by s, subtract the starting values, solve for Y.
from math import exp
Y0, V0, T_END = 1.0, 0.0, 30.0

def acc(y, v):                                 # the rate law, per unit mass
    return -2.0 * v - 5.0 * y

def road_one(s, h):                            # returns totals every 0.5 s of cutoff
    def f(t, u):
        w = exp(-s * t)
        return [u[1], acc(u[0], u[1]), w * u[0], w * u[1], w * acc(u[0], u[1])]
    u, marks, every = [Y0, V0, 0.0, 0.0, 0.0], [], round(0.5 / h)
    for n in range(round(T_END / h)):
        if n % every == 0: marks.append(list(u))
        t = n * h
        k1 = f(t, u)
        k2 = f(t + h / 2, [a + h / 2 * b for a, b in zip(u, k1)])
        k3 = f(t + h / 2, [a + h / 2 * b for a, b in zip(u, k2)])
        k4 = f(t + h, [a + h * b for a, b in zip(u, k3)])
        u = [a + h / 6 * (p + 2 * q + 2 * r + w) for a, p, q, r, w in zip(u, k1, k2, k3, k4)]
    return u[2:], marks

def road_two(s, y0=Y0, v0=V0):                 # (s^2 + 2s + 5) Y = s y(0) + y'(0) + 2 y(0)
    return (s * y0 + v0 + 2 * y0) / (s * s + 2 * s + 5)

errs = []
for s in (2.0, 0.0):
    Y = road_two(s)
    print(f"s = {s:g}: rule and algebra give Y = {Y:.6f}, sY - y(0) = {s*Y - Y0:.6f}, "
          f"s^2 Y - s y(0) - y'(0) = {s*s*Y - s*Y0 - V0:.6f}")
    for h in (0.05, 0.025):
        (I0, I1, I2), marks = road_one(s, h)
        errs.append(abs(I0 - Y))
        print(f"  RK4 h = {h}: L[y] = {I0:.6f}, L[y'] = {I1:.6f}, L[y''] = {I2:.6f}, error in Y {errs[-1]:.1e}")
    assert abs(I0 - Y) < 1e-6                                  # stepped motion = algebra
    assert abs(I1 - (s * I0 - Y0)) < 1e-6 and abs(I2 - (s * s * I0 - s * Y0 - V0)) < 1e-6
    print(f"  transformed equation L[y''] + 2 L[y'] + 5 L[y] = {I2 + 2 * I1 + 5 * I0:.1e}")
print(f"error ratio at s = 2, h halved: {errs[0] / errs[1]:.1f}, near 2^4 = 16 for order 4")
assert 12 < errs[0] / errs[1] < 20                             # RK4's order, seen in the run
_, marks = road_one(2.0, 0.025)
m = marks[1]                                                   # the totals at cutoff R = 0.5 s
print(f"cutoff R = 0.5: J = {m[3]:.6f}, sI - y(0) = {2 * m[2] - Y0:.6f}, "
      f"end term e^(-sR) y(R) = {exp(-1.0) * m[0]:.6f}")
print("figure, R      " + " ".join(f"{0.5 * k:5.2f}" for k in range(7)))
print("figure, J_R    " + " ".join(f"{mk[3]:5.2f}" for mk in marks[:7]))
print("figure, sI_R-1 " + " ".join(f"{2 * mk[2] - Y0:5.2f}" for mk in marks[:7]))
print(f"mistake 1, drop y(0): sY = {2 * road_two(2.0):.6f}, and (s^2+2s+5)Y = 0 forces Y = 0")
print(f"mistake 2, drop the s on y(0): Y = {(Y0 + V0 + 2 * Y0) / 13.0:.6f} instead of {road_two(2.0):.6f}")
F = sum(0.001 * exp(-2.0 * (1.0 + (k + 0.5) * 0.001)) for k in range(29000))
print(f"mistake 3, step at t = 1: L[f'] = 0 but sF - f(0) = {2.0 * F:.6f}")
assert abs(2.0 * F - exp(-2.0)) < 1e-6                         # midpoint sum vs e^(-2)
print("ALL CHECKS PASS")
