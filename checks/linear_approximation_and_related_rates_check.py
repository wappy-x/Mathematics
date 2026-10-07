# Linear approximation and related rates -- the check behind the card.
# A spherical balloon of radius 10 cm is pumped at 500 cm^3 of air a second.
# Road one is the formula dr/dt = (dV/dt) / (4 pi r^2) and its tangent line.
# Road two never uses it: it finds the radius itself, as a cube root by
# halving, and measures the rate by shrinking difference quotients.
from math import pi

def cube_root(y):                        # 200 halvings of the bracket [0, y + 1]
    lo, hi = 0.0, y + 1.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if mid * mid * mid < y:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2

def radius(v):                           # V = (4/3) pi r^3, solved for r
    return cube_root(3 * v / (4 * pi))

PUMP, R0, R1 = 500.0, 10.0, 20.0
V0, V1 = 4 / 3 * pi * R0 ** 3, 4 / 3 * pi * R1 ** 3
rate, rate1 = PUMP / (4 * pi * R0 * R0), PUMP / (4 * pi * R1 * R1)
slope = 1 / (4 * pi * R0 * R0)           # dr/dV at 10 cm, in cm per cm^3
M = 1 / (8 * pi * pi * R0 ** 5)          # largest size of r'' while r >= 10
print(f"balloon: r = {R0:.0f} cm, V = {V0:.3f} cm^3, pump {PUMP:.0f} cm^3/s")
print(f"formula at 10 cm: 4 pi r^2 = {4 * pi * R0 * R0:.3f} cm^2, dr/dt = {rate:.9f} cm/s; at 20 cm: {rate1:.9f} cm/s")
for dt in (0.1, 0.01, 0.001):
    q = (radius(V0 + PUMP * dt) - R0) / dt
    print(f"quotient at 10 cm, dt = {dt}: {q:.9f} cm/s, off by {q - rate:+.9f}")
q1 = (radius(V1 + PUMP * 0.001) - R1) / 0.001
print(f"quotient at 20 cm, dt = 0.001: {q1:.9f} cm/s, off by {q1 - rate1:+.9f}")
print(f"slope dr/dV at 10 cm: {slope:.9f} cm per cm^3; M = {M * 1e8:.4f} x 10^-8, M/2 = {M / 2 * 1e8:.4f} x 10^-8")
errs = []
for h in (500.0, 250.0, 125.0):
    line, true = R0 + slope * h, radius(V0 + h)
    errs.append(true - line)
    print(f"h = {h:.0f}: tangent {line:.6f}, true {true:.6f}, error {true - line:+.6f}, "
          f"error/h x 10^5 = {(true - line) / h * 1e5:+.3f}, error/h^2 x 10^8 = {(true - line) / h / h * 1e8:+.3f}")
bound = M * 500.0 ** 2 / 2
print(f"bound M h^2 / 2 at h = 500: {bound:.6f} cm; error ratios {errs[0] / errs[1]:.3f}, {errs[1] / errs[2]:.3f}")
ts = [0, 4, 8, 12, 16, 20]
print("chart, t (s): " + ", ".join(f"{t}" for t in ts))
print("chart, true radius (cm): " + ", ".join(f"{radius(V0 + PUMP * t):.2f}" for t in ts))
print("chart, tangent line (cm): " + ", ".join(f"{R0 + rate * t:.2f}" for t in ts))
print(f"mistake, multiply by 4 pi r^2 instead of dividing: {PUMP * 4 * pi * R0 * R0:.2f}")
print(f"mistake, fix r = 10 before differentiating: dV/dt = {(V0 - V0) / 0.001:.1f}, so dr/dt = 0")
assert abs((radius(V0 + PUMP * 1e-4) - R0) / 1e-4 - rate) < 1e-5   # road two meets road one
assert abs(q1 - rate1) < 1e-5                                      # the second case too
assert -bound <= errs[0] < 0                                       # below the tangent, within the bound
assert 3.8 < errs[1] / errs[2] < 4.2                               # halve the step, quarter the error
