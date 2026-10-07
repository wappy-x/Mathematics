# Euler's method -- the check behind the card.  Standard library only.
# The skydiver obeys v' = 9.8 - 0.2 v, v(0) = 0, time in s, speed in m/s.
# Road one: Euler's loop.  Road two: the exact solution 49 (1 - e^(-0.2 t)).
# Road three: the loop's own closed form, 49 (1 - (1 - 0.2 h)^n).
import math

def f(t, v):                                   # the rate law, m/s per s
    return 9.8 - 0.2 * v

def euler(h, t_end, rule=f):                   # step along the current slope
    t, v, path = 0.0, 0.0, [0.0]
    for _ in range(round(t_end / h)):
        v, t = v + h * rule(t, v), t + h
        path.append(v)
    return path

def exact(t):                                  # found by separating variables
    return 49 * (1 - math.exp(-0.2 * t))

def fmt(xs, d=2):
    return ", ".join(f"{x:.{d}f}" for x in xs)

hs, T = (2, 1, 0.5, 0.25), 10
errs = [euler(h, T)[-1] - exact(T) for h in hs]
print(f"euler, h = 2, t = 0, 2, ..., 10: {fmt(euler(2, T))}")
print(f"euler, h = 2, drag 0.2v at each step: {fmt((0.2 * v for v in euler(2, T)[:-1]), 3)}")
print(f"euler, h = 1, t = 0, 2, ..., 10: {fmt(euler(1, T)[::2])}")
print(f"exact, t = 0, 2, ..., 10: {fmt(exact(t) for t in range(0, 11, 2))}")
for h, e in zip(hs, errs):
    print(f"step {h}: euler v(10) = {euler(h, T)[-1]:.4f}, exact {exact(T):.4f}, "
          f"error {e:.4f}, error/h {e / h:.4f}")
ratios = [errs[i] / errs[i + 1] for i in range(3)]
print(f"error ratio each time the step halves: {fmt(ratios)}")
closed = [49 * (1 - (1 - 0.2 * h) ** round(T / h)) for h in hs]
print(f"closed form 49(1 - (1 - 0.2h)^n) at t = 10: {fmt(closed, 4)}")
local = [euler(h, h)[-1] - exact(h) for h in hs[:3]]
print(f"one step from rest, error at h = 2, 1, 0.5: {fmt(local, 4)}")
pred, fine = 9.8 * math.exp(-2), euler(0.001, T)[-1] - exact(T)
print(f"predicted error per second of step, 9.8 e^(-2): {pred:.4f}; "
      f"step 0.001 gives error {fine:.6f}")
L, M = 0.2, 1.96                               # rule's slope in v; largest |v''|
bound = M / (2 * L) * (math.exp(L * T) - 1)
print(f"guaranteed bound (M / 2L)(e^(LT) - 1) h with L = 0.2, M = 1.96: {bound:.2f} h")
X, Y = (lambda t: 50 + 140 * t), (lambda v: 200 - 8 * v)
curve = " ".join(f"{X(k / 4):.1f},{Y(exact(k / 4)):.1f}" for k in range(9))
print(f"figure, curve (px): {curve}")
print(f"figure, tangent end {X(2):.1f},{Y(19.6):.1f}; curve end {X(2):.1f},{Y(exact(2)):.1f}")
no_h = 0.0
for _ in range(5):                             # five steps, the h left out
    no_h = no_h + f(0, no_h)
print(f"mistake, h left out (five steps of v + f): 'v(10)' = {no_h:.2f}")
print(f"mistake, slope never updated: 9.8 x 10 = {9.8 * T:.2f}")
print(f"mistake, h = 15 past the limit 2 / 0.2 = {2 / 0.2:.0f}: v(60) = {euler(15, 60)[-1]:.2f}, "
      f"exact {exact(60):.2f}")
assert max(abs(euler(h, T)[-1] - c) for h, c in zip(hs, closed)) < 1e-9  # loop = closed form
assert all(1.9 < r < 2.2 for r in ratios)                  # first order: error halves
assert abs(fine / 0.001 - pred) / pred < 0.01              # error/h -> 9.8 e^(-2)
assert all(0 < e <= bound * h for h, e in zip(hs, errs))   # within the proved bound
print("ALL CHECKS PASS")
