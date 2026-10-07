# Midpoint and Heun -- the check behind the card.  Standard library only.
# The skydiver: v' = 9.8 - 0.2 v, v(0) = 0, exact v = 49 (1 - e^(-0.2 t)).
# Road one: step the rule and compare with the exact curve.  Road two: for this
# straight-line rule a two-stage step multiplies the gap to 49 m/s by
# q = 1 - x + x^2/2 with x = 0.2 h, so v_n = 49 (1 - q^n), no stepping at all.
import math

def f(t, v): return 9.8 - 0.2 * v                  # the rate rule, m/s per s
def drag(t, v): return 9.8 - 9.8 * (v / 49) ** 2   # second case: drag grows as v^2
def euler(f, t, v, h): return v + h * f(t, v)
def midpoint(f, t, v, h): return v + h * f(t + h / 2, v + h / 2 * f(t, v))
def heun(f, t, v, h): return v + h / 2 * (f(t, v) + f(t + h, v + h * f(t, v)))
def heun_no_half(f, t, v, h): return v + h * (f(t, v) + f(t + h, v + h * f(t, v)))
def slope_at_end(f, t, v, h): return v + h * f(t + h, v + h * f(t, v))

def run(step, rule, h, t_end=10.0):
    v, path = 0.0, [0.0]
    for n in range(round(t_end / h)):
        v = step(rule, n * h, v, h)
        path.append(v)
    return path

exact = lambda t: 49 * (1 - math.exp(-0.2 * t))
exact_drag = lambda t: 49 * (1 - math.exp(-0.4 * t)) / (1 + math.exp(-0.4 * t))
k1 = f(0, 0); k2 = f(2, 2 * k1); km = f(1, k1)
print(f"first step, h = 2: k1 = {k1:.2f}; Heun predicts {2 * k1:.2f}, slope there {k2:.2f}, "
      f"average {(k1 + k2) / 2:.2f}; midpoint half-step {k1:.2f}, slope there {km:.2f}")
print(f"first step lands at {heun(f, 0, 0, 2):.2f} (Heun) and {midpoint(f, 0, 0, 2):.2f} "
      f"(midpoint); exact {exact(2):.4f}; Euler {euler(f, 0, 0, 2):.2f}")
for name, path in (("exact", [exact(t) for t in range(0, 11, 2)]),
                   ("euler h = 2", run(euler, f, 2)), ("heun h = 2", run(heun, f, 2))):
    print(f"chart, {name}: " + ", ".join(f"{v:.2f}" for v in path))
x = 0.2 * 2; q = 1 - x + x * x / 2
print(f"shortcut, h = 2: q = {q:.4f} against e^(-0.4) = {math.exp(-x):.4f}; "
      f"49 (1 - q^5) = {49 * (1 - q ** 5):.4f}; q passes 1 at h = {2 / 0.2:.0f}")
hs, err = (2, 1, 0.5, 0.25), {}
for h in hs:
    err[h] = [abs(run(s, f, h)[-1] - exact(10)) for s in (euler, midpoint, heun)]
    print(f"h = {h}: v(10) Euler {run(euler, f, h)[-1]:.4f} error {err[h][0]:.4f}; "
          f"Heun {run(heun, f, h)[-1]:.4f} error {err[h][2]:.4f}; midpoint error {err[h][1]:.4f}")
print(f"error ratio when h halves, 0.5 to 0.25: Euler {err[0.5][0] / err[0.25][0]:.2f}, "
      f"Heun {err[0.5][2] / err[0.25][2]:.2f}")
dm, dh = run(midpoint, drag, 2)[-1], run(heun, drag, 2)[-1]
print(f"drag v^2, h = 2: midpoint {dm:.4f}, Heun {dh:.4f}, exact {exact_drag(10):.4f}")
de = {h: [abs(run(s, drag, h)[-1] - exact_drag(10)) for s in (midpoint, heun)] for h in (0.5, 0.25)}
print(f"drag v^2, error at h = 0.5 and 0.25: midpoint {de[0.5][0]:.5f} {de[0.25][0]:.5f} ratio "
      f"{de[0.5][0] / de[0.25][0]:.2f}; Heun {de[0.5][1]:.5f} {de[0.25][1]:.5f} ratio {de[0.5][1] / de[0.25][1]:.2f}")
for name, s in (("slope at start only (Euler)", euler), ("sum not averaged", heun_no_half),
                ("end slope alone", slope_at_end)):
    print(f"mistake, {name}: v(10) = {run(s, f, 2)[-1]:.2f}, error {abs(run(s, f, 2)[-1] - exact(10)):.2f}")
X = lambda t: 45 + 100 * t; Y = lambda v: 200 - 9 * v
print("figure, exact curve (x, y): " + ", ".join(f"({X(t):.1f}, {Y(exact(t)):.1f})" for t in (0, 0.5, 1, 1.5, 2))
      + f"; end x {X(2):.1f}: Euler y {Y(2 * k1):.1f}, Heun y {Y(heun(f, 0, 0, 2)):.1f}; half-step ({X(1):.1f}, {Y(k1):.1f})")
h = 0.1; x = 0.2 * h
assert all(abs(v - 49 * (1 - q ** n)) < 1e-9 for n, v in enumerate(run(heun, f, 2)))  # two roads agree
assert abs(exact(h) - heun(f, 0, 0, h) - 49 * x ** 3 / 6) < 49 * x ** 4 / 24          # local error ~ h^3
assert 3.8 < err[0.5][2] / err[0.25][2] < 4.2 and 1.8 < err[0.5][0] / err[0.25][0] < 2.2
assert dm != dh and 3.6 < de[0.5][0] / de[0.25][0] < 4.4 and 3.6 < de[0.5][1] / de[0.25][1] < 4.4
print("ALL CHECKS PASS")
