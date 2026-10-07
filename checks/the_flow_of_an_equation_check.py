# The flow of an equation -- the check behind the card.  Standard library only.
# The colony obeys y' = y^2 (y in hundreds of animals, t in years).  Road one:
# the flow formula x / (1 - t x).  Road two: the travel time from a to b, the
# integral of 1/u^2, by Simpson's rule.  Road three: Euler steps along the slope.
import math

def phi(t, x):                                 # the flow: where x is after time t
    return x / (1 - t * x)

def travel(a, b, n=1000):                      # years to grow from a to b
    h = (b - a) / n
    w = lambda k: 1 if k in (0, n) else (4 if k % 2 else 2)
    return h / 3 * sum(w(k) / (a + k * h) ** 2 for k in range(n + 1))

def euler(x, t, h):                            # small steps along the slope x^2
    for _ in range(round(t / h)):
        x += h * x * x
    return x

def level(t, h0):                              # bucket h' = -0.2 sqrt(h), in cm
    return max(math.sqrt(h0) - 0.1 * t, 0.0) ** 2

a, c = phi(0.25, 1.0), phi(0.5, 1.0)
b = phi(0.25, a)
print(f"flow: phi_0.25(1) = {a:.4f}; phi_0.25({a:.4f}) = {b:.4f}; phi_0.5(1) = {c:.4f}; "
      f"phi_-0.5(2) = {phi(-0.5, 2.0):.4f}")
t1, t2, t12 = travel(1.0, a), travel(a, 2.0), travel(1.0, 2.0)
print(f"travel time, 1 to 1.3333: {t1:.6f}; 1.3333 to 2: {t2:.6f}; 1 to 2: {t12:.6f}")
hs = (0.001, 0.0001, 0.00001)
errs = [abs(euler(1.0, 0.5, h) - c) for h in hs]
for h, e in zip(hs, errs):
    print(f"euler, step {h:.5f}: y(0.5) = {euler(1.0, 0.5, h):.5f}, error {e:.5f}")
print(f"euler, error ratio 0.00010 vs 0.00001: {errs[1] / errs[2]:.2f}")
grid = [(s, t, x) for s in (-0.3, 0.1, 0.2, 0.4) for t in (-0.2, 0.1, 0.3)
        for x in (0.5, 1.0, 1.2) if t * x < 1 and s * phi(t, x) < 1]
worst = max(abs(phi(s, phi(t, x)) - phi(s + t, x)) for s, t, x in grid)
shift = max(abs(phi(k / 20, 4 / 3) - phi(k / 20 + 0.25, 1.0)) for k in range(15))
print(f"composition, {len(grid)} triples (s, t, x): largest gap {worst:.2e}")
print(f"time shift, start 4/3 against start 1 moved on 0.25, t = 0..0.7: largest gap {shift:.2e}")
ts = (0, 0.125, 0.25, 0.375, 0.5)
for x in (0.5, 1.0, 4 / 3):
    print(f"chart, start {x:.2f}: " + ", ".join(f"{phi(t, x):.2f}" for t in ts))
order = all(phi(t, 0.5) < phi(t, 1.0) < phi(t, 4 / 3) for t in ts)
print(f"order kept at every chart time: {'yes' if order else 'no'}; life span from 1: {1 / 1.0:.2f}, from 2: {1 / 2.0:.2f}")
m = lambda t, x: x * math.exp(t * t)           # y' = 2ty, map read from clock 0
print(f"mistake, y' = 2ty: map from 0 used twice {m(0.25, m(0.25, 1.0)):.4f}, "
      f"one move of 0.5 {m(0.5, 1.0):.4f}")
print(f"mistake, growth factor reused: {a:.4f} x {a:.4f} = {a * a:.4f}, not {c:.4f}")
print(f"mistake, formula past the life span: phi_1.5(1) = {phi(1.5, 1.0):.2f}")
print(f"bucket: 25 cm empties at t = {math.sqrt(25) / 0.1:.0f}; at t = 60 starts of 25 cm and 1 cm "
      f"read {level(60, 25):.2f} and {level(60, 1):.2f}; 10 s before empty: 0.00 or {level(-10, 0):.2f}")
assert abs(t1 - 0.25) < 1e-9 and abs(t12 - 0.5) < 1e-9     # the integral recovers the times
assert abs(euler(1.0, 0.5, 1e-5) - 2) < 1e-3 and 8 < errs[1] / errs[2] < 12
assert worst < 1e-12 and shift < 1e-12                     # twice short equals once long
assert abs(m(0.25, m(0.25, 1.0)) - m(0.5, 1.0)) > 0.1      # a clock-reading rule breaks it
print("ALL CHECKS PASS")
