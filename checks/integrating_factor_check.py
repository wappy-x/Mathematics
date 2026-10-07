# The integrating factor -- the check behind the card.  Standard library only.
# A room at 10 C drifts toward an outdoor temperature that swings round 20 C:
# T' = -0.5 (T - (20 + 5 sin t)), T(0) = 10, t in hours.  Road one: the answer
# found with the weight e^(0.5t).  Road two: the weighted-input formula, its
# integral added up by Simpson's rule.  Road three: Euler steps on the law.
import math

K, T0 = 0.5, 10.0
def outdoor(t): return 20 + 5 * math.sin(t)
def law(t, T): return -K * (T - outdoor(t))                # the room's rate, C per hour
def forced(t): return 20 + math.sin(t) - 2 * math.cos(t)   # the part that stays
def closed(t): return forced(t) - 8 * math.exp(-K * t)     # plus the transient

def simpson(f, a, b, n=2000):             # area under f from a to b, n even
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * (b - a) / n) for i in range(1, n))
    return s * (b - a) / (3 * n)

def via_weight(t, p, q, y0):              # y = (y0 + integral of mu q) / mu, mu = e^(pt)
    return (y0 + simpson(lambda s: math.exp(p * s) * q(s), 0, t)) / math.exp(p * t)

def euler(t_end, h, t=0.0, T=T0):         # plain small steps along the slope
    for _ in range(round((t_end - t) / h)):
        T, t = T + h * law(t, T), t + h
    return T

errs = [abs(euler(10, h) - closed(10)) for h in (0.1, 0.05, 0.025)]
T30, h = euler(30, 0.001), 0.001          # late in the day: the transient is gone
late = []
for i in range(round(2 * math.pi / h)):   # one full outdoor swing, stepped
    late.append((T30, 30 + i * h))
    T30 = T30 + h * law(30 + i * h, T30)
top, t_top = max(late)
swing = (top - min(late)[0]) / 2
lag = t_top - (math.pi / 2 + 10 * math.pi)  # outdoor peaks at t = pi/2 + 2 pi n
lo, hi = 0.0, 20.0                        # house coffee: T' = -0.1 (T - 20), by bisection
for _ in range(50):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if via_weight(mid, 0.1, lambda s: 2.0, 80.0) > 50 else (lo, mid)
fd = (closed(3.001) - closed(2.999)) / 0.002
print("t (h)       ", list(range(13)))
print("outdoor (C) ", ", ".join(f"{outdoor(t):.2f}" for t in range(13)))
print("room T (C)  ", ", ".join(f"{closed(t):.2f}" for t in range(13)))
print("forced (C)  ", ", ".join(f"{forced(t):.2f}" for t in range(13)))
print(f"T(10): weight answer {closed(10):.4f}; Simpson on the weighted input {via_weight(10, K, lambda s: K * outdoor(s), T0):.4f}")
print("Euler error at t = 10, h = 0.1, 0.05, 0.025:", " ".join(f"{e:.5f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"rate at t = 3: finite difference {fd:.4f}; law {law(3, closed(3)):.4f}")
print(f"swing: formula 5 x {K / math.sqrt(K * K + 1):.4f} = {5 * K / math.sqrt(K * K + 1):.4f}; Euler, one late cycle {swing:.4f}")
print(f"lag: formula atan(1/k) = {math.atan(1 / K):.4f} h of a {2 * math.pi:.2f} h swing; Euler peak after outdoor peak {lag:.3f} h")
print(f"transient -8e^(-0.5t): at t = 10 {-8 * math.exp(-5):.4f}; under 0.1 C after {2 * math.log(80):.2f} h")
print(f"coffee reaches 50 C: weight formula + bisection {lo:.4f} min; 10 ln 2 = {10 * math.log(2):.4f} min")
print(f"mistake, weight e^(-0.5t) carried through: T(10) = {via_weight(10, -K, lambda s: K * outdoor(s), T0):.1f}")
print(f"mistake, constant dropped: T(0) = {forced(0):.2f}, not 10")
print(f"mistake, input not weighted: T(10) = {math.exp(-5) * (T0 + simpson(lambda s: K * outdoor(s), 0, 10)):.2f}")
print(f"mistake, room copies outdoor: swing 5.00, lag 0; truth {math.sqrt(5):.2f} and {math.atan(2):.2f} h")
assert abs(via_weight(10, K, lambda s: K * outdoor(s), T0) - closed(10)) < 1e-9   # road two
assert 1.8 < errs[0] / errs[1] < 2.2 and 1.8 < errs[1] / errs[2] < 2.2            # order one
assert abs(swing - math.sqrt(5)) < 0.005 and abs(lag - math.atan(2)) < 0.005     # road three
assert abs(fd - law(3, closed(3))) < 1e-6 and abs(lo - 10 * math.log(2)) < 1e-6
print("ALL CHECKS PASS")
