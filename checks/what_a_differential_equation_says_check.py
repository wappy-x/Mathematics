# A differential equation -- the check behind the card.  Standard library only.
# The coffee obeys T' = -0.1 (T - 20), T(0) = 80.  Road one: the family
# 20 + C e^(-0.1 t), tested by substitution.  Road two: Euler's rule.
import math

def rate(T):                                   # the rule, in degrees C per minute
    return -0.1 * (T - 20)

def family(C):                                 # one member of the proposed family
    return lambda t: 20 + C * math.exp(-0.1 * t)

def residual(curve, t, d=1e-4, rule=rate):     # the curve's own slope minus the rule
    return (curve(t + d) - curve(t - d)) / (2 * d) - rule(curve(t))

def euler(h, t_end):                           # step along the slope, nothing else
    T = 80.0
    for _ in range(round(t_end / h)):
        T += h * rate(T)
    return T

def euler_hit(h, target):                      # first time the steps reach target
    T, t = 80.0, 0.0
    while T + h * rate(T) > target:
        T, t = T + h * rate(T), t + h
    return t + h * (T - target) / (T - (T + h * rate(T)))

ts, Cs, hs = [0, 5, 10, 15, 20, 25, 30], [60, 30, 0, -10], (0.1, 0.01, 0.001)
C = 80 - 20                                    # T(0) = 20 + C forces C
exact10, exact_hit = family(C)(10), 10 * math.log(2)
worst = max(abs(residual(family(c), t)) for c in Cs for t in ts)
errs = [abs(euler(h, 10) - exact10) for h in hs]
hit = euler_hit(0.001, 50)
C_back = (euler(0.001, 10) - 20) * math.exp(1)
print(f"C = {C} from T(0) = 80; rate {rate(80):.1f} at 80 C and {rate(50):.1f} at 50 C; "
      f"T(10) = {exact10:.4f}; 50 C at t = {exact_hit:.4f}")
for c in Cs:
    print(f"chart, C = {c}: " + ", ".join(f"{family(c)(t):.2f}" for t in ts))
print(f"substitution, largest residual over 4 values of C, t = 0..30: {worst:.6f}")
for h, e in zip(hs, errs):
    print(f"euler, step {h} min: T(10) = {euler(h, 10):.4f}, error {e:.4f}")
print(f"euler, error ratio 0.01 vs 0.001: {errs[1] / errs[2]:.2f}")
print(f"euler, reaches 50 C at t = {hit:.3f}; C read back from T(10): {C_back:.2f}")
wrong1 = lambda t: 80 * math.exp(-0.1 * t)
wrong2 = lambda t: 20 + 60 * math.exp(0.1 * t)
line = lambda t: 80 - 6 * t
print(f"mistake, 80e^(-0.1t): residual {residual(wrong1, 0):.3f} at t = 0 and "
      f"{residual(wrong1, 10):.3f} at t = 10; 50 C at t = {10 * math.log(1.6):.2f}")
print(f"mistake, 20 + 60e^(+0.1t): residual {residual(wrong2, 0):.3f}; T(6.93) = {wrong2(exact_hit):.2f}")
print(f"mistake, tangent line 80 - 6t: 50 C at t = {30 / 6:.2f}; residual there {residual(line, 5):.3f}")
root = lambda h: -math.sqrt(max(h, 0.0))       # the leaking bucket, h' = -sqrt(h)
b1 = lambda t: (1 - t / 2) ** 2 if t < 2 else 0.0
b2 = lambda t: (2 - t / 2) ** 2 if t < 4 else 0.0
bw = max(abs(residual(b, t, rule=root)) for b in (b1, b2) for t in (0.5, 1.5, 2.5, 3.5, 4.5))
print(f"bucket, at t = 4 both read {b1(4):.2f} and {b2(4):.2f}; at t = 1 they read "
      f"{b1(1):.2f} and {b2(1):.2f}; largest residual {bw:.6f}")
assert worst < 1e-6 and abs(residual(wrong1, 10) + 2) < 1e-6   # family passes; mistake misses by 2
assert abs(euler(0.001, 10) - exact10) < 2e-3                  # the roads agree
assert 9 < errs[1] / errs[2] < 11                              # error shrinks with the step
assert abs(hit - exact_hit) < 0.01 and abs(C_back - 60) < 0.01  # same time, same C
print("ALL CHECKS PASS")
