# Volumes by discs, washers and shells -- the check behind the card.  Only
# math is imported, for sqrt and pi; every sum and root is written out here.
# The wine glass: its inside wall stands y = r^2/2 cm above the bowl's bottom
# at r cm from the stem's axis; the bowl is 10 cm deep, rim radius sqrt(20).
import math
PI, H, T = math.pi, 10.0, 0.3          # depth, and how far the outer wall sits below
C, TOP = math.sqrt(2 * H), math.sqrt(2 * (H + T))   # rim radius; where the outer wall meets the rim's level

def discs(n):                          # cylinders inside and outside each slice
    h = H / n                          # radius^2 is 2y: smallest at a slice's bottom
    return (sum(PI * 2 * (i * h) * h for i in range(n)),
            sum(PI * 2 * ((i + 1) * h) * h for i in range(n)))

def shells(n):                         # exact tubes, length taken at each edge
    w, lo, hi = C / n, 0.0, 0.0
    for i in range(n):
        u, v = i * w, (i + 1) * w
        lo += PI * (v * v - u * u) * (H - v * v / 2)
        hi += PI * (v * v - u * u) * (H - u * u / 2)
    return lo, hi

def midpoint(f, a, b, n):              # thin slices sampled at their middles
    return sum(f(a + (i + 0.5) * (b - a) / n) for i in range(n)) * (b - a) / n

disc_exact = PI * H * H                                    # antiderivative pi y^2 at 10
shell_exact = 2 * PI * (H / 2 * C**2 - C**4 / 8)           # 2 pi (5 p^2 - p^4/8) at sqrt(20)
print(f"bowl: wall y = r^2/2 cm, depth {H:.0f} cm, rim radius {C:.6f} cm")
print(f"discs: pi x {H:.0f}^2 = {disc_exact / PI:.0f} pi = {disc_exact:.6f}; shells: 2 pi ({H / 2 * C**2:.0f} - {C**4 / 8:.0f}) = {shell_exact:.6f}")
print(f"the can round the bowl: pi x {C * C:.0f} x 10 = {PI * C * C * H:.6f} cm^3, half of it {PI * C * C * H / 2:.6f}")
for n in (10, 100, 1000):
    (a, b), (c, d) = discs(n), shells(n)
    print(f"n = {n:>4}: discs [{a:.6f}, {b:.6f}] gap {b - a:.6f}; shells [{c:.6f}, {d:.6f}] gap {d - c:.6f}")
print("fill height cm: 0 1 2 3 4 5 6 7 8 9 10")
print("volume cm^3:", " ".join(f"{PI * h * h:.2f}" for h in range(11)))
lo, hi = 0.0, H                                            # bisection: fill height for 150 ml
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if midpoint(lambda y: 2 * PI * y, 0, mid, 8) < 150 else (lo, mid)
print(f"150 ml fills to {lo:.6f} cm by bisection; sqrt(150/pi) = {math.sqrt(150 / PI):.6f} cm")
wall_exact = PI * (2 * T * H + T * T)                      # washers: constant 2 pi T, plus the cap
washer = midpoint(lambda y: PI * (2 * (y + T) - 2 * max(y, 0)), -T, H, 103000)
shell_wall = midpoint(lambda p: 2 * PI * p * (min(p * p / 2, H) - (p * p / 2 - T)), 0, TOP, 200000)
print(f"glass in the bowl: washers exact {wall_exact / PI:.2f} pi = {wall_exact:.6f}, washer sum {washer:.6f}, shell sum {shell_wall:.6f} cm^3")
print(f"each washer 2 pi T = {2 * PI * T:.6f} cm^2; shells need two pieces: rim at r = {C:.6f}, outer wall ends at r = {TOP:.6f} cm")
bad_ring = midpoint(lambda y: PI * (math.sqrt(2 * (y + T)) - math.sqrt(2 * max(y, 0)))**2, -T, H, 103000)
wrong_axis = midpoint(lambda r: PI * (r * r / 2)**2, 0, C, 100000)
double = midpoint(lambda p: 2 * PI * abs(p) * (H - p * p / 2), -C, C, 100000)
print(f"mistake, (R - r)^2 for the glass: {bad_ring:.6f} cm^3")
print(f"mistake, wall height as the radius: {wrong_axis:.6f} cm^3")
print(f"mistake, shells from -sqrt(20) to sqrt(20): {double:.6f} cm^3")
print(f"mistake, half the depth: {PI * 25:.6f} cm^3, a fraction {PI * 25 / disc_exact:.2f} of the bowl")
k, m = 16 * C, 16 * math.sqrt(12.5); print(f"figure, bottom y 200, rim y {200 - 16 * H:.2f}, control y {200 + 16 * H:.2f}, stem to y 224; rim x {90 - k:.2f} {90 + k:.2f} "
      f"{270 - k:.2f} {270 + k:.2f}; disc x {90 - m:.2f} to {90 + m:.2f}, y {200 - 16 * 6.5:.2f} to {200 - 16 * 6:.2f}; "
      f"shells x 230-238, 302-310, y 40 to {200 - 16 * 2.25**2 / 2:.2f}")
assert abs(midpoint(lambda p: 2 * PI * p * (H - p * p / 2), 0, C, 1000) - shell_exact) < 1e-3   # shell sum vs antiderivative
a, b = discs(1000); c, d = shells(1000)
assert a <= disc_exact <= b and c <= disc_exact <= d and b - a < 0.9 and d - c < 0.9
assert abs(washer - wall_exact) < 1e-6 and abs(shell_wall - wall_exact) < 1e-6
assert abs(lo - math.sqrt(150 / PI)) < 1e-9                # bisection against the formula
print("ALL CHECKS PASS")
