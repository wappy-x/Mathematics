# The Wronskian and reduction of order -- the check behind the card.  Standard
# library only.  y'' - 2y' + y = 0, t in s, y in cm: a spring whose damper is
# wired backwards.  Known solution y1 = e^t.  Road one: reduction of order and
# Abel's identity in closed form.  Road two: Euler steps on the equation itself
# and slopes by finite differences.  Second case: y'' + y = 0 from y1 = sin t.
import math

def y1(t): return math.exp(t)
def y2(t): return t * math.exp(t)                    # reduction of order: v = t
def slope(f, t, h=1e-5): return (f(t + h) - f(t - h)) / (2 * h)
def wr(f, g, t): return f(t) * slope(g, t) - slope(f, t) * g(t) + 0.0   # value-slope determinant
def abel(t, p=-2.0): return 1.0 * math.exp(-p * t)   # W(0) = 1, times exp(-integral of p)

def euler(y, v, t_end, h):                           # y'' = 2y' - y, small steps along the slope
    for _ in range(round(t_end / h)):
        y, v = y + h * v, v + h * (2 * v - y)
    return y, v

print("y'' - 2y' + y = 0, y1 = e^t; y = v e^t gives v'' = 0, so v = t and y2 = t e^t")
errs = []
for h in (0.01, 0.005, 0.0025):
    a, da = euler(1.0, 1.0, 1.0, h); b, db = euler(0.0, 1.0, 1.0, h)
    errs.append(abs(b - y2(1))); w_euler = a * db - da * b
    print(f"Euler h = {h:.4f}: y2(1) = {b:.6f}, error {errs[-1]:.6f}; W(1) = {w_euler:.6f}")
print(f"closed form: y2(1) = {y2(1):.6f}; W(1) from slopes = {wr(y1, y2, 1):.6f}; Abel e^2 = {abel(1):.6f}")
ts = [-2 + 0.5 * k for k in range(7)]
print("chart, t:", " ".join(f"{t:.1f}" for t in ts))
for name, f in (("e^t", y1), ("t e^t", y2), ("W", lambda t: wr(y1, y2, t))):
    print(f"chart, {name}:", " ".join(f"{f(t):.2f}" for t in ts))
d0 = wr(y1, y2, 0)                                   # Cramer's rule for y(0) = 2, y'(0) = -1
c1 = (2 * slope(y2, 0) + 1 * y2(0)) / d0; c2 = (-1 * y1(0) - 2 * slope(y1, 0)) / d0
def y(t): return c1 * y1(t) + c2 * y2(t)
lo, hi = 0.0, 1.0
for _ in range(60):                                  # bisection for the moment y = 0
    lo, hi = (lo, (lo + hi) / 2) if y((lo + hi) / 2) < 0 else ((lo + hi) / 2, hi)
print(f"start 2 cm at -1 cm/s: c1 = {c1:.6f}, c2 = {c2:.6f}; y(0.5) = {y(0.5):.6f} cm; rest at t = {lo:.6f} s")
def mid(f, a, b, n=400): return (b - a) / n * sum(f(a + (j + 0.5) * (b - a) / n) for j in range(n))
sine = [(t, math.sin(t) * mid(lambda s: 1 / math.sin(s) ** 2, math.pi / 2, t)) for t in (math.pi / 3, 2 * math.pi / 3)]
print("second case y'' + y = 0, y1 = sin t: " + "; ".join(f"y2 = {v:.6f} vs -cos t = {-math.cos(t):.6f}" for t, v in sine))
r = math.sqrt(5)
wh = wr(lambda t: math.exp(-r * t), lambda t: t * math.exp(-r * t), 1)
print(f"house absorber, b = {2 * r:.6f}: y = (1 + {r:.6f} t) e^(-{r:.6f} t); W(1) = {wh:.6f}, Abel {abel(1, 2 * r):.6f}")
print(f"mistake, + sign in Abel: W(1) = {abel(1, 2.0):.6f}, not {abel(1):.6f}")
print(f"mistake, p = -4 read off 2y'' - 4y' + 2y = 0 undivided: W(1) = {abel(1, -4.0):.6f}")
print("mistake, e^t and 2e^t: W at -1, 0, 1 =", " ".join(f"{wr(y1, lambda t: 2 * y1(t), t):.6f}" for t in (-1, 0, 1)))
def f(t): return t * t
def g(t): return t * abs(t)
wq = [wr(f, g, t) for t in (-1.0, 0.0, 1.0)]
det = f(1) * g(-1) - g(1) * f(-1)                    # a f + b g = 0 at t = 1 and t = -1
print("breaks, t^2 and t|t|: W at -1, 0, 1 =", " ".join(f"{w:.6f}" for w in wq) + f"; values at 1 and -1 give determinant {det:.0f}")
pts = [(y1(0), slope(y1, 0)), (y2(0), slope(y2, 0)), (2 * y1(0), 2 * slope(y1, 0))]
print("figure, origin (60, 200), 80 per unit:", "; ".join(f"({a:.0f}, {b:.0f}) -> ({60 + 80 * a:.0f}, {200 - 80 * b:.0f})" for a, b in pts) + f"; area {d0:.6f}")
assert errs[1] < 0.6 * errs[0] and errs[2] < 0.6 * errs[1] and abs(w_euler - abel(1)) < 0.05   # Euler meets Abel
assert abs(wr(y1, y2, 1) - abel(1)) < 1e-6 and abs(wr(y1, y2, -1.5) - abel(-1.5)) < 1e-6    # slopes meet Abel
assert all(abs(v + math.cos(t)) < 1e-5 for t, v in sine) and abs(wh - abel(1, 2 * r)) < 1e-6
assert abs(lo - 2 / 3) < 1e-9 and all(w == 0 for w in wq) and det != 0
print("ALL CHECKS PASS")
