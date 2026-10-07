# Second derivatives -- the check behind the card.  Nothing is imported.
# A car pulls away from one set of lights and brakes to a stop at the next:
# s(t) = 1.5 t^2 - 0.1 t^3 metres at t seconds, 0 to 10 s.  The acceleration
# at 7 s is reached by two roads: differences of raw odometer readings, and
# the power-rule formula 3 - 0.6 t.  Whole-second readings give a third.
T = 7.0
def s(t): return 1.5 * t * t - 0.1 * t * t * t      # odometer, metres
def v(t): return 3 * t - 0.3 * t * t                 # power rule once, m/s
def acc(t): return 3 - 0.6 * t                       # power rule twice, m/s^2
def d2(f, t, h): return (f(t + h) - 2 * f(t) + f(t - h)) / (h * h)  # central
def r(x): return round(x, 9) + 0.0                   # prints -0.00 as 0.00
def row(xs): return ", ".join(f"{r(x):.2f}" for x in xs)

print(f"at {T:.0f} s: position {s(T):.2f} m, velocity {v(T):.2f} m/s, acceleration {acc(T):.2f} m/s^2")
for h in [1, 0.1, 0.01, 0.001]:
    fwd = (s(T + 2 * h) - 2 * s(T + h) + s(T)) / (h * h)   # difference of differences
    print(f"window {h}: forward second difference {fwd:.6f}, off by {abs(fwd - acc(T)):.6f}; central {d2(s, T, h):.6f}")
    assert abs(fwd - (acc(T) - 0.6 * h)) < 1e-5      # raw road == formula road
pos = [s(t) for t in range(11)]
d_1 = [pos[k + 1] - pos[k] for k in range(10)]
d_2 = [d_1[k + 1] - d_1[k] for k in range(9)]
d_3 = [d_2[k + 1] - d_2[k] for k in range(8)]
print(f"chart position, 0 to 10 s: {row(pos)}")
print(f"chart velocity: {row(v(t) for t in range(11))}")
print(f"chart acceleration: {row(acc(t) for t in range(11))}")
print(f"metres in each second: {row(d_1)}")
print(f"change from second to second, at 1 to 9 s: {row(d_2)}")
print(f"third differences: {row(d_3[:4])} ...; fourth differences: {row(d_3[k + 1] - d_3[k] for k in range(3))} ...")
assert all(abs(d_2[k] - acc(k + 1)) < 1e-9 for k in range(9))  # whole seconds == formula
lo, hi = 1.0, 9.0                                    # halve to where the bend switches
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if d2(s, mid, 0.01) > 0 else (lo, mid)
print(f"inflection by halving: t = {lo:.6f} s at {s(lo):.3f} m, speed {v(lo):.2f} m/s; formula 3 / 0.6 = {3 / 0.6:.6f} s")
assert abs(lo - 3 / 0.6) < 1e-6
tan8 = s(T) + v(T) * 1
print(f"tangent at 7 s predicts {tan8:.2f} m at 8 s; car is at {s(8):.2f} m; gap {s(8) - tan8:.2f} = 1 x (-0.6 - 0.1)")
print(f"s = t^4 near 0, central second difference: {d2(lambda t: t ** 4, -0.1, 0.001):.4f}, {d2(lambda t: t ** 4, 0, 0.001):.6f}, {d2(lambda t: t ** 4, 0.1, 0.001):.4f}")
def circle(t, h):                                    # 1 / radius of circle through 3 points
    (x1, y1), (x2, y2), (x3, y3) = [(u, s(u)) for u in (t - h, t, t + h)]
    a2, b2, c2 = (x2 - x1) ** 2 + (y2 - y1) ** 2, (x3 - x2) ** 2 + (y3 - y2) ** 2, (x3 - x1) ** 2 + (y3 - y1) ** 2
    area2 = abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1))
    return 2 * area2 / (a2 * b2 * c2) ** 0.5
for t in [7.0, 10.0]:
    kap = abs(acc(t)) / (1 + v(t) ** 2) ** 1.5
    print(f"curvature at {t:.0f} s: formula {kap:.6f} per m; circle through 3 points, h 0.1: {circle(t, 0.1):.6f}, h 0.001: {circle(t, 0.001):.6f}")
    assert abs(circle(t, 0.001) - kap) < 1e-5 * (1 + kap)
print(f"second case, 2 s: central difference {d2(s, 2, 0.5):.6f}, formula {acc(2):.2f} m/s^2; mistake: velocity squared {v(T) ** 2:.2f}")
print("ALL CHECKS PASS")
