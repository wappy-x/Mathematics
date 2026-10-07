# Separable equations -- the check behind the card.  Standard library only.
# A snowball melts at a rate proportional to its surface: V' = -k V^(2/3),
# V(0) = 1000 cm^3, k = 0.3 cm/min.  Road one: the separated answer.  Road
# two: Euler steps on the law.  Road three: the law turned round, minutes per
# cm^3 of snow added up by Simpson's rule.
import math

K, V0 = 0.3, 1000.0

def rate(v):                              # the law; no snow, no melting
    return -K * v ** (2 / 3) if v > 0 else 0.0

def separated(t):                         # 3 V^(1/3) = 30 - k t, cubed; then V = 0
    return max(10 - 0.1 * t, 0.0) ** 3

def euler(t_end, h):                      # plain small steps along the slope
    v = V0
    for _ in range(round(t_end / h)):
        v = v + h * rate(v)
    return v

def euler_melt(h):                        # step until the snow runs out
    v, n = V0, 0
    while v > 0:
        v, n = v + h * rate(v), n + 1
    return n * h

def simpson(f, a, b, n=2000):             # area under f from a to b, n even
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * (b - a) / n) for i in range(1, n))
    return s * (b - a) / (3 * n)

minutes_per_cm3 = lambda v: -1 / rate(v)
t_half = 10 * (10 - 500 ** (1 / 3))       # separated: V = 500 when 10 - 0.1t = 500^(1/3)
t_half_simpson = simpson(minutes_per_cm3, 500, V0)
t_melt = 3 * V0 ** (1 / 3) / K            # separated: 3 V^(1/3) = 30 - k t reaches 0
errs = [abs(euler(50, h) - separated(50)) for h in (1, 0.5, 0.25)]
slope = (separated(37.001) - separated(36.999)) / 0.002  # the answer's own rate at t = 37
coffee = simpson(lambda T: 1 / (0.1 * (T - 20)), 50, 80)  # house example, same law turned round
print("t (min)    ", [t for t in range(0, 130, 10)])
print("V (cm^3)   ", [round(separated(t)) for t in range(0, 130, 10)])
print("formula    ", [round((10 - 0.1 * t) ** 3) for t in range(0, 130, 10)])
print(f"V(50) separated {separated(50):.4f}; Euler h = 0.01 gives {euler(50, 0.01):.4f}")
print("Euler error at t = 50, h = 1, 0.5, 0.25:", " ".join(f"{e:.4f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"melted at: separated {t_melt:.2f} min; Euler h = 0.01 steps out at {euler_melt(0.01):.2f} min")
print(f"half gone (500 cm^3): separated {t_half:.4f} min; Simpson {t_half_simpson:.4f} min")
print(f"rate at t = 37: finite difference {slope:.4f}; law -k V^(2/3) {rate(separated(37)):.4f}; at t = 0 {rate(V0):.1f}")
print(f"lost constant solution: k V^(2/3) at V = 0 is {K * 0.0 ** (2 / 3):.1f}, so V = 0 for all time obeys the law")
print(f"a puddle at t = 120 fits both histories: V(50) = {separated(50):.0f} or V(50) = 0")
print(f"radius {(3 * V0 / (4 * math.pi)) ** (1 / 3):.4f} cm, shrinking {K / (36 * math.pi) ** (1 / 3):.4f} cm/min")
print(f"coffee reaches 50 C: Simpson {coffee:.4f} min; separated 10 ln 2 = {10 * math.log(2):.4f} min")
print(f"mistake, formula past 100 min: V(120) = {(10 - 0.1 * 120) ** 3:.0f} cm^3")
print(f"mistake, dropped the 3: V^(1/3) = 10 - 0.3t, gone at {10 / 0.3:.2f} min")
print(f"mistake, constant added after cubing: V = 1000 - (0.1t)^3, V(50) = {1000 - 5 ** 3:.0f}")
assert abs(euler(50, 0.01) - separated(50)) < 0.1              # road two meets road one
assert abs(t_half_simpson - t_half) < 1e-6 and abs(coffee - 10 * math.log(2)) < 1e-6
assert 1.8 < errs[0] / errs[1] < 2.2 and 1.8 < errs[1] / errs[2] < 2.2  # order one
assert abs(slope - rate(separated(37))) < 1e-4                 # the answer obeys the law
print("ALL CHECKS PASS")
