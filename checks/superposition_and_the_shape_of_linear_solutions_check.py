# Superposition -- the check behind the card.  Standard library only.
# A weight on a spring: y'' + y = f(t), y in cm above rest, t in s.  Road one:
# closed forms, tested by substitution.  Road two: Euler's rule, rate law only.
import math

cos, sin, pi = math.cos, math.sin, math.pi

def L(y, t, d=1e-3):                   # y'' + y, with y'' by a centred difference
    return (y(t + d) - 2 * y(t) + y(t - d)) / d ** 2 + y(t)

def D(y, t, d=1e-6):                   # slope by a centred difference
    return (y(t + d) - y(t - d)) / (2 * d)

def det(g1, g2):                       # starting values of two solutions, as a determinant
    return g1(0) * D(g2, 0) - g2(0) * D(g1, 0)

def euler(f, y0, v0, t_end, n):        # y' = v, v' = f(t) - y, in n small steps
    h, y, v = t_end / n, y0, v0
    for k in range(n):
        y, v = y + h * v, v + h * (f(k * h) - y)
    return y

combo = lambda t: 3 * cos(t) - 2 * sin(t)          # free swing from 3 cm, -2 cm/s
hook = lambda t: t / 2                             # one forced solution: follow the hook
forced = lambda t: t / 2 + 3 * cos(t) - 2.5 * sin(t)
ts, grid = [0.5, 1, 2, 3], [k / 2 for k in range(17)]
worst = max(abs(L(g, t)) for g in (cos, sin, combo) for t in ts)
c1, c2 = 3, -2 - 0.5                               # y(0) = c1, y'(0) = 1/2 + c2
energy = [(-3 * sin(t) - 2 * cos(t)) ** 2 + combo(t) ** 2 for t in (0, 1, 2)]
print(f"residual y'' + y, largest over cos t, sin t, 3 cos t - 2 sin t: {worst:.6f}")
print(f"y'^2 + y^2 for 3 cos t - 2 sin t at t = 0, 1, 2: " + ", ".join(f"{e:.3f}" for e in energy)
      + f"; amplitude {math.sqrt(energy[0]):.2f} cm")
print("forcing of t/2 at t = 1, 2, 3: " + ", ".join(f"{L(hook, t):.3f}" for t in (1, 2, 3)))
print(f"forced solution: c1 = {c1:.1f}, c2 = {c2:.1f}; start {forced(0):.3f} cm, {D(forced, 0):.3f} cm/s; "
      f"forcing at t = 2 is {L(forced, 2):.3f}")
for name, g in (("t/2", hook), ("3 cos t - 2 sin t", combo), ("t/2 + 3 cos t - 2.5 sin t", forced)):
    print(f"chart, {name}: " + ", ".join(f"{g(t):.2f}" for t in grid))
f_half, f_one, errs = (lambda t: t / 2), (lambda t: t), []
for n in (1000, 10000, 100000):
    y = euler(f_half, 3, -2, 2, n)
    errs.append(abs(y - forced(2)))
    print(f"euler, {n} steps to t = 2: y = {y:.4f}, closed form {forced(2):.4f}, error {errs[-1]:.5f}")
print(f"euler, error ratio 10000 vs 100000 steps: {errs[1] / errs[2]:.2f}")
free = euler(lambda t: 0, 3, -2, 2, 100000)
print(f"at t = 2: cos t = {cos(2):.4f}, sin t = {sin(2):.4f}; euler free swing {free:.4f}, "
      f"closed form {combo(2):.4f}; period 2 pi = {2 * pi:.4f}")
double = euler(f_one, 6, -4, 2, 100000)
print(f"doubled: hook at 1 cm/s from 6 cm, -4 cm/s: euler {double:.4f}, 2 x closed form {2 * forced(2):.4f}")
both = lambda t: hook(t) + forced(t)
print(f"mistake, adding two forced solutions: forcing at t = 2 is {L(both, 2):.3f}, not {hook(2):.3f}")
pend = lambda y, t: L(y, t) - y(t) + sin(y(t))      # the pendulum's y'' + sin y
print(f"mistake, pendulum y'' + sin y = 0: y = pi leaves {pend(lambda t: pi, 1):.3f}, "
      f"y = pi/2 leaves {pend(lambda t: pi / 2, 1):.3f}")
print(f"mistake, start determinant: cos t, sin t -> {det(cos, sin):.3f}; "
      f"cos t, 2 cos t -> {det(cos, lambda t: 2 * cos(t)):.3f}")
assert worst < 1e-5 and abs(L(both, 2) - 2.0) < 1e-5        # combinations pass; a sum of forced ones does not
assert abs(euler(f_half, 3, -2, 2, 100000) - forced(2)) < 1e-3  # the two roads agree
assert 9 < errs[1] / errs[2] < 11                            # error shrinks with the step
assert abs(double - 2 * forced(2)) < 2e-3                   # double the forcing, double the answer
print("ALL CHECKS PASS")
