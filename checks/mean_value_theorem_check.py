# Mean value theorem -- the check behind the card.  Standard library only.
# A train runs 100 km in 1 hour, rest to rest: s(t) = 100(3t^2 - 2t^3) km at
# t hours.  When is its speed exactly the average, 100 km/h?  Three roads: the
# quadratic formula; bisection on the script's own difference-quotient speed;
# and Rolle's road, which finds where the lead over a steady 100 km/h is
# lowest and highest on a grid, then refines, and never looks at a speed.
import math
def s(t): return 100 * (3 * t * t - 2 * t ** 3)
def lead(t): return s(t) - 100 * t                        # km ahead of steady pace
def speed(f, t, h=1e-5): return (f(t + h) - f(t - h)) / (2 * h)
def bisect(fn, lo, hi):
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if (fn(lo) < 0) == (fn(mid) < 0) else (lo, mid)
    return (lo + hi) / 2
def extreme(fn, sign):                                    # sign 1 lowest, -1 highest
    k = min(range(1001), key=lambda i: sign * fn(i / 1000))
    lo, hi = (k - 1) / 1000, (k + 1) / 1000
    for _ in range(100):
        a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, b) if sign * fn(a) < sign * fn(b) else (a, hi)
    return (lo + hi) / 2
avg = (s(1) - s(0)) / (1 - 0)
exact = [(3 - math.sqrt(3)) / 6, (3 + math.sqrt(3)) / 6]  # 600t - 600t^2 = 100
bis = [bisect(lambda t: speed(s, t) - avg, a, b) for a, b in ((0, 0.5), (0.5, 1))]
rol = [extreme(lead, 1), extreme(lead, -1)]
print(f"trip: {s(1) - s(0):.0f} km in 1 h; average speed {avg:.0f} km/h")
print("speed at minutes 0, 6, ..., 60:", [round(600 * k / 10 * (1 - k / 10)) for k in range(11)])
print(f"road 1, quadratic formula, sqrt 3 = {math.sqrt(3):.6f}: c1 = {exact[0]:.6f} h ({60 * exact[0]:.2f} min), c2 = {exact[1]:.6f} h ({60 * exact[1]:.2f} min)")
print(f"road 2, bisection on difference-quotient speed: c1 = {bis[0]:.6f}, c2 = {bis[1]:.6f}")
print(f"road 3, Rolle: lead lowest at {rol[0]:.6f} h, {lead(rol[0]):.2f} km; highest at {rol[1]:.6f} h, {lead(rol[1]):.2f} km")
print(f"positions at c1 and c2: {s(exact[0]):.2f} km and {s(exact[1]):.2f} km")
for h in (0.1, 0.01, 0.001):
    r, l = (lead(rol[0] + h) - lead(rol[0])) / h, (lead(rol[0] - h) - lead(rol[0])) / -h
    print(f"lead's slope over a step of {h} h after c1: {r:+.4f}, before c1: {l:+.4f}")
print("difference-quotient speed at c1, steps 0.1, 0.01, 0.001:",
      ", ".join(f"{speed(s, exact[0], h):.4f}" for h in (0.1, 0.01, 0.001)))
X, Y = lambda t: 40 + 280 * t, lambda km: 210 - 1.8 * km
print("figure, curve M 40,210 C", " ".join(f"{X(t):.1f},{Y(k):.1f}" for t, k in ((1/3, 0), (2/3, 100), (1, 100))))
for i, c in enumerate(exact, 1):
    ends = [(X(c + d), Y(s(c) + 100 * d)) for d in (-0.1, 0.1)]
    print(f"figure, tangent {i} at ({X(c):.1f},{Y(s(c)):.1f}) from ({ends[0][0]:.1f},{ends[0][1]:.1f}) to ({ends[1][0]:.1f},{ends[1][1]:.1f})")
corner = lambda t: 200 * t if t <= 0.5 else 100.0
jump = lambda t: 100.0 if t >= 1 else 0.0
gap = lambda t: 0.0 if t < 0.5 else 100.0                 # undefined at exactly 0.5
print(f"breaks 1, corner: average {corner(1) - corner(0):.0f}; speed {speed(corner, 0.25):.0f} before 30 min, {speed(corner, 0.75):.0f} after")
print(f"breaks 2, jump at the end: average {jump(1) - jump(0):.0f}; speed {speed(jump, 0.5):.0f} at every inside time")
print(f"breaks 3, gap at 30 min: rate {speed(gap, 0.25):.0f} and {speed(gap, 0.75):.0f}, values {gap(0.25):.0f} and {gap(0.75):.0f}")
assert all(abs(e - b) < 1e-6 for e, b in zip(exact, bis))          # formula vs bisection
assert all(abs(e - r) < 1e-6 for e, r in zip(exact, rol))          # formula vs Rolle's road
assert abs(speed(s, exact[0], 0.001) - 600 * exact[0] * (1 - exact[0])) < 1e-3
cavg = corner(1) - corner(0)                               # the corner trip's own average
assert abs(speed(corner, 0.25) - cavg) > 99 and abs(speed(corner, 0.75) - cavg) > 99
print("ALL CHECKS PASS")
