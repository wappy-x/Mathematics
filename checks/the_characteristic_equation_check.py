# The characteristic equation -- the check behind the card.  Standard library
# only.  The shock absorber y'' + b y' + 5y = 0, y(0) = 1 cm, y'(0) = 0, is
# answered by two roads: the closed form built from the quadratic's roots, and
# Euler's small steps along the slope, which never call exp.  The roots are
# found twice: by the quadratic formula, and by bisection, which never calls sqrt.
import math
C = 5.0

def roots(b):                            # quadratic formula for r^2 + b r + C = 0
    d = math.sqrt(b * b - 4 * C)
    return (-b + d) / 2, (-b - d) / 2

def bisect(f, lo, hi):                   # f changes sign between lo and hi
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

R1, R2 = roots(6.0)
C1 = (0 - R2 * 1) / (R1 - R2)            # from C1 + C2 = 1 and r1 C1 + r2 C2 = 0
over = lambda t: C1 * math.exp(R1 * t) + (1 - C1) * math.exp(R2 * t)
R = -math.sqrt(C)                        # b = 2 sqrt 5: the root repeats
crit = lambda t: (1 + (0 - R * 1) * t) * math.exp(R * t)
one = lambda t: math.exp(R * t)          # the repeated root used once, no t e^(rt)
def euler(b, t_end, h):                  # position += h velocity; velocity += h acceleration
    y, v = 1.0, 0.0
    for _ in range(round(t_end / h)):
        y, v = y + h * v, v + h * (-b * v - C * y)
    return y
def leftover(f, t, a, b, c, k=1e-3):     # a y'' + b y' + c y by finite differences
    return a * (f(t + k) - 2 * f(t) + f(t - k)) / k**2 + b * (f(t + k) - f(t - k)) / (2 * k) + c * f(t)

rb = (bisect(lambda r: r * r + 6 * r + C, -3, 0), bisect(lambda r: r * r + 6 * r + C, -6, -3))
bc, hs, ts = 2 * math.sqrt(C), (0.01, 0.005, 0.0025), [0.5 * i for i in range(7)]
e_over = [abs(euler(6, 1, h) - over(1)) for h in hs]
e_crit = abs(euler(bc, 1, 0.0025) - crit(1))
res = [leftover(over, 1, 1, 6, C), leftover(crit, 1, 1, bc, C)]
ce = [leftover(math.exp, t, t * t, t, -1) / math.exp(t) for t in (1, 2)] + [leftover(lambda s: s, 2, 4, 2, -1)]
fmt = lambda xs, d=2: " ".join(f"{x:.{d}f}" for x in xs)
print("y'' + b y' + 5y = 0, y(0) = 1 cm, y'(0) = 0 cm/s")
print(f"b = 6: discriminant {36 - 4 * C:.0f}; roots by formula {fmt((R1, R2), 6)}; by bisection {fmt(rb, 6)}")
print(f"b = 6: C1 = {C1:.4f}, C2 = {1 - C1:.4f}; y(1) = {over(1):.6f} cm")
print(f"b = 6, Euler y(1) at h = 0.01 0.005 0.0025: {fmt([euler(6, 1, h) for h in hs], 6)}")
print(f"errors: {fmt(e_over, 6)}; ratios on halving h: {e_over[0] / e_over[1]:.3f} {e_over[1] / e_over[2]:.3f}")
print(f"b = 2 sqrt 5 = {bc:.6f}: discriminant {bc * bc - 4 * C:.6f}; repeated root {R:.6f}; C1 = 1, C2 = {-R:.6f}")
print(f"critical: y(1) = {crit(1):.6f} cm; Euler h = 0.0025: {euler(bc, 1, 0.0025):.6f}; error {e_crit:.6f}")
print(f"law's leftover at t = 1 by finite differences, in millionths: b = 6 {abs(res[0]) * 1e6:.2f}; critical {abs(res[1]) * 1e6:.2f}")
print(f"figure, t (s):           {fmt(ts)}")
print(f"figure, b = 6 y (cm):    {fmt([over(t) for t in ts])}")
print(f"figure, critical y (cm): {fmt([crit(t) for t in ts])}")
print(f"within 0.05 cm of level: b = 6 after {bisect(lambda t: over(t) - 0.05, 0, 10):.2f} s; critical after {bisect(lambda t: crit(t) - 0.05, 0, 10):.2f} s")
print(f"mistake, one exponential at the repeated root: y'(0) = {R:.3f}, not 0; y(1) = {one(1):.4f}, not {crit(1):.4f}")
print(f"mistake, roots' signs flipped to +1 and +5: y(1) = {C1 * math.exp(-R1) + (1 - C1) * math.exp(-R2):.2f} cm")
print(f"hypothesis dropped, t^2 y'' + t y' - y = 0: e^t leaves {fmt(ce[:2])} times e^t at t = 1, 2; y = t leaves {abs(ce[2]):.2f}")
print(f"house b = 2: discriminant {4 - 4 * C:.0f}, roots -1 +/- 2i, complex")
assert max(abs(rb[0] - R1), abs(rb[1] - R2)) < 1e-12                  # formula against bisection
assert abs(euler(6, 1, 0.0025) - over(1)) < 1e-3 and 1.9 < e_over[0] / e_over[1] < 2.1  # steps meet roots
assert e_crit < 1e-3 and abs(euler(bc, 1, 0.0025) - one(1)) > 0.2      # t e^(rt) is the missing piece
assert max(abs(x) for x in res) < 1e-4                                # the answers obey the law
print("ALL CHECKS PASS")
