# Symplectic steps -- the check behind the card.  Road one steps each method in its own loop;
# road two is a closed form: rotation formula, (1 + h^2)^n for Euler, the exact circle.
from math import pi, sin, cos, asin, sqrt, hypot

def leap(q, v, h):                     # half kick, drift, half kick, for q'' = -q
    v -= h / 2 * q; q += h * v
    return q, v - h / 2 * q
def euler(q, v, h): return q + h * v, v - h * q
def energy(q, v): return (q * q + v * v) / 2

def orbit_error(step, m):              # distance from the true state after one orbit
    q, v = 1.0, 0.0
    for _ in range(m): q, v = step(q, v, 2 * pi / m)
    return hypot(q - 1.0, v)
def planet(per_year, method, years=1000):      # sun's pull GM = 4 pi^2 AU^3 per yr^2
    h, gm, x, y, vx, vy, hi, r1, track = 1 / per_year, 4 * pi * pi, 1.0, 0.0, 0.0, 2 * pi, 0.0, 0, []
    for n in range(1, per_year * years + 1):
        r3 = hypot(x, y) ** 3
        if method == "euler":
            x, y, vx, vy = x + h * vx, y + h * vy, vx - h * gm * x / r3, vy - h * gm * y / r3
        else:
            vx -= h / 2 * gm * x / r3; vy -= h / 2 * gm * y / r3; x += h * vx; y += h * vy
            r3 = hypot(x, y) ** 3; vx -= h / 2 * gm * x / r3; vy -= h / 2 * gm * y / r3
        hi = max(hi, abs(hypot(x, y) - 1))
        if n <= per_year and n % 5 == 0: track.append(f"{180 + 60 * x:.0f},{120 - 60 * y:.0f}")
        if n == per_year: r1 = hypot(x, y)
    return hi, r1, track, (vx * vx + vy * vy) / 2 - gm / hypot(x, y)

h = 2 * pi / 100; a, b, theta = 1 - h * h / 2, 1 - h * h / 4, 2 * asin(h / 2)
print(f"h = 2 pi/100 = {h:.7f}; a = {a:.9f}; b = {b:.9f}")
print(f"area factor per step: leapfrog a^2 + h^2 b = {a * a + h * h * b:.12f}; Euler 1 + h^2 = {1 + h * h:.9f}")
q, v, eq, ev, lo, hi, gap = 1.0, 0.0, 1.0, 0.0, 0.5, 0.5, 0.0
for n in range(1, 100001):
    q, v = leap(q, v, h); lo, hi = min(lo, energy(q, v)), max(hi, energy(q, v))
    gap = max(gap, abs(q - cos(n * theta)), abs(v + sqrt(b) * sin(n * theta)))
    eq, ev = euler(eq, ev, h)
    if n == 100: print(f"one orbit: Euler energy {energy(eq, ev):.6f}, formula 0.5(1 + h^2)^100 = {0.5 * (1 + h * h) ** 100:.6f}")
print(f"1000 orbits: leapfrog energy min {lo:.6f}, max {hi:.6f}; band [b/2, 1/2] = [{b / 2:.6f}, 0.5], width {25 * h * h:.3f}%")
print(f"1000 orbits: Euler energy {energy(eq, ev):.4e}, formula {0.5 * (1 + h * h) ** 100000:.4e}")
print(f"leapfrog loop vs rotation formula, largest gap in 100000 steps: {gap:.1e}")
print(f"angle per step {theta:.9f} vs h {h:.9f}; lead after 1000 orbits {100000 * (theta - h):.4f} rad")
print(f"position after 1000 orbits: leapfrog q = {q:.4f}, exact 1; cos(lead) = {cos(100000 * (theta - h)):.4f}")
errs = {m: (orbit_error(leap, m), orbit_error(euler, m)) for m in (50, 100, 200)}
for m, (el, ee) in errs.items(): print(f"one orbit in {m} steps: leapfrog error {el:.3e}, Euler error {ee:.3e}")
hi1, _, _, en1 = planet(100, "leap")
hi2, _, _, _ = planet(200, "leap")
ehi, er1, etrack, een = planet(100, "euler")
print(f"planet, leapfrog, 100/yr, 1000 yr: largest radius error {hi1:.5f} AU ({100 * hi1:.3f}%); energy {en1:.4f}, exact {-2 * pi * pi:.4f}")
print(f"planet, leapfrog, 200/yr, 1000 yr: largest radius error {hi2:.5f} AU; ratio {hi1 / hi2:.2f}")
print(f"planet, Euler, 100/yr: radius after 1 yr {er1:.4f} AU ({100 * (er1 - 1):.0f}% out), largest error in 1000 yr {ehi:.2f} AU; energy {een:.4f}")
q, v = 1.0, -0.75
for _ in range(6): q, v = leap(q, v, 2.5)
a5 = 1 - 2.5 ** 2 / 2
print(f"h = 2.5: a = {a5}, growth root {a5 - sqrt(a5 * a5 - 1)}; from (1, -0.75), 6 steps: q = {q:.0f}, v = {v:.0f}")
print("figure, Euler first year every 5 steps (px): " + " ".join(["240,120"] + etrack))
assert gap < 1e-9                                                       # loop = rotation formula
assert abs(energy(eq, ev) / (0.5 * (1 + h * h) ** 100000) - 1) < 1e-8   # Euler's growth law
assert 3.8 < errs[100][0] / errs[200][0] < 4.2 and 1.8 < errs[100][1] / errs[200][1] < 2.4  # orders 2, 1
assert 3.95 < hi1 / hi2 < 4.05 and hi1 < 0.0025 and er1 > 1.5  # band ~ h^2; Euler > 50% out
print("ALL CHECKS PASS")
