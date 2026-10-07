# Optimisation on the 330 ml can -- the check behind the card.  Standard library
# only.  Radius r in cm; the volume pins the height, h = 330 / (pi r^2), so the
# metal is A(r) = 2 pi r^2 + 660 / r square cm.  Road 1 solves A'(r) = 0 by
# algebra; road 2 hunts the lowest A by golden-section search, never using A'.
import math
PI, V = math.pi, 330.0
def A(r): return 2 * PI * r * r + 2 * V / r            # lids plus wall
def dA(r): return 4 * PI * r - 2 * V / (r * r)          # A'(r), by the power rule
def dq(f, r, s=1e-5): return (f(r + s) - f(r - s)) / (2 * s)   # own difference quotient
def golden(f, lo, hi):                                  # shrink [lo, hi] round the lowest f
    g = (math.sqrt(5) - 1) / 2
    for _ in range(80):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(a) < f(b): hi = b
        else: lo = a
    return (lo + hi) / 2
r1 = math.exp(math.log(V / (2 * PI)) / 3)               # road 1: r^3 = 330 / (2 pi)
h1 = V / (PI * r1 * r1)
r2 = golden(A, 0.5, 20.0)                               # road 2: no derivative used
d2 = (A(r1 + 1e-3) - 2 * A(r1) + A(r1 - 1e-3)) / 1e-6  # A'' by a second difference
lo, hi = 2.5, 3.3                                       # a filling line takes 5.0 to 6.6 cm
scan = [lo + i * (hi - lo) / 800 for i in range(801)]
best = min(scan, key=A)
print("closed can, 330 ml: A(r) = 2*pi*r^2 + 660/r sq cm, r in cm")
print(f"road 1, solve A'(r) = 0: r^3 = {r1 ** 3:.2f}, r = {r1:.4f} cm, h = {h1:.4f} cm, h/(2r) = {h1 / (2 * r1):.4f}, A = {A(r1):.4f}")
print(f"road 2, golden-section search on A alone: r = {r2:.4f} cm, A = {A(r2):.4f}")
print(f"A' by formula at r = 3, 4.5: {dA(3):.2f}, {dA(4.5):.2f}; by difference quotient: {dq(A, 3):.2f}, {dq(A, 4.5):.2f}")
print(f"A'' at r = {r1:.4f}: formula 4*pi + 1320/r^3 = {4 * PI + 1320 / r1 ** 3:.2f}; second difference {d2:.2f}; 12*pi = {12 * PI:.2f}")
rs = [2, 2.5, 3, 3.5, 4, 4.5, 5, 6]
print("chart, r:", " ".join(f"{r}" for r in rs))
print("chart, A:", " ".join(f"{A(r):.2f}" for r in rs))
print(f"slot {2 * lo:.1f} to {2 * hi:.1f} cm across: A' at the ends {dA(lo):.2f}, {dA(hi):.2f}; stationary r = {r1:.4f} lies outside")
print(f"slot by scanning 801 radii: best r = {best:.4f}, A = {A(best):.2f}, h = {V / (PI * best * best):.2f} cm; extra metal {100 * (A(best) / A(r1) - 1):.2f}%")
print(f"figure, 20 units per cm, base y = 210: square can x 20 to {20 + 40 * r1:.1f}, top y {210 - 20 * h1:.1f}; slim can x 200 to {200 + 40 * hi:.1f}, top y {210 - 20 * V / (PI * hi * hi):.1f}")
print(f"figure, square can {2 * r1:.2f} x {h1:.2f} cm; slim can {2 * hi:.2f} x {V / (PI * hi * hi):.2f} cm")
g = lambda x: -1 / x
print(f"mistake 1, domain with a gap: f(x) = -1/x has f'(-1) = {dq(g, -1):.2f}, f'(1) = {dq(g, 1):.2f}, yet f(-1) = {g(-1):.2f} > f(1) = {g(1):.2f}")
c = lambda x: x ** 3
print(f"mistake 2, flat is not a turn: x^3 at 0 has slope {dq(c, 0):.2f}, f(-0.1) = {c(-0.1):.3f}, f(0.1) = {c(0.1):.3f}")
print(f"mistake 3, most metal on (0, infinity): A(0.1) = {A(0.1):.2f}, A(0.01) = {A(0.01):.2f}, no maximum")
assert abs(r2 - r1) < 1e-6                              # two roads, one radius
assert abs(V / (PI * r2 * r2) - 2 * r1) < 1e-5          # height equals diameter
assert abs(d2 - 12 * PI) < 1e-3 and all(abs(dA(r) - dq(A, r)) < 1e-6 for r in (3, 4.5)) and dA(3) < 0 < dA(4.5)  # slope formula right; it flips upward
assert abs(best - hi) < 1e-9 and A(best) > A(r2)        # the endpoint wins the slot
print("ALL CHECKS PASS")
