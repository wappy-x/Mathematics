# Small angles -- the check behind the card.  Nothing is imported.  A pendulum
# 1 m long swings 5 deg out from straight down.  Road one: sin 5 deg from exact
# values, the half-angle and triple-angle rules, then 5 deg added again and again.
# Road two: walk the arc round a circle of radius 1 in short chords.
PI, L = 3.141592653589793, 1000.0                # L: the pendulum's length in mm

def walk(x, step=1e-5):                          # road two: walk arc x from the lowest point
    c, s, done, area = 1.0, 0.0, 0.0, 0.0        # c: depth below the pivot, s: sideways
    while x - done > 1e-15:
        h = min(step, x - done)
        u, v = c - s * h, s + c * h              # a short step along the tangent line
        k = (u * u + v * v) ** -0.5              # pulled back onto the circle
        done += ((u * k - c) ** 2 + (v * k - s) ** 2) ** 0.5   # the arc, as chords
        area += (c * v - s * u) * k / 2          # the sector, as thin triangles from the pivot
        c, s = u * k, v * k
    return c, s, area
def halve(f, lo, hi):                            # halving search: f(lo) holds, f(hi) fails
    for _ in range(60):
        lo, hi = ((lo + hi) / 2, hi) if f((lo + hi) / 2) else (lo, (lo + hi) / 2)
    return lo

c30 = 3 ** 0.5 / 2
s15 = ((1 - c30) / 2) ** 0.5                     # half of 30 deg
s5 = halve(lambda s: 3 * s - 4 * s ** 3 < s15, 0.0, 0.5)   # a third of 15 deg
one, c, s, c5 = [], 1.0, 0.0, (1 - s5 * s5) ** 0.5
for k in range(1, 21):                           # road one at 5, 10, ... 100 deg
    c, s = c * c5 - s * s5, s * c5 + c * s5      # add 5 deg: the addition rule
    one.append((5 * k * PI / 180, c, s))
two = [walk(r[0]) for r in one[:9]]              # road two at 5, 10, ... 45 deg
(x, _, _), (wc, ws, wa), (x4, c4, s4) = one[0], two[0], one[7]
t = ws / wc
print(f"pendulum 1 m = {L:.0f} mm, swing 5 deg = 5 x pi / 180 = {x:.6f} rad; to four places sin {x:.4f} = {ws:.4f}")
print(f"sin 5 deg, road one (30 deg halved, then a third): {s5:.6f}; road two (arc walked): {ws:.6f}")
print(f"the sandwich at 5 deg: sin x {ws:.6f} < x {x:.6f} < tan x {t:.6f}")
print(f"areas: triangle OAB {ws / 2:.6f} < sector in thin slices {wa:.6f} (x / 2 = {x / 2:.6f}) < triangle OAT {t / 2:.6f}")
print(f"the chain: 1 - x^2/2 = {1 - x * x / 2:.6f} < cos x {wc:.6f} < sin x / x {ws / x:.6f} < 1 < tan x / x {t / x:.6f} < 1 / cos x {1 / wc:.6f}")
print(f"shortfalls: 1 - sin x / x = {1 - ws / x:.6f} (bound x^2/2 = {x * x / 2:.6f}); tan x / x - 1 = {t / x - 1:.6f} (bound {1 / wc - 1:.6f})")
print(f"cos x - (1 - x^2/2) = {wc - 1 + x * x / 2:.7f} (bound x^4/8 = {x ** 4 / 8:.7f}); x in place of sin x is {x / ws - 1:.3%} too high")
print(f"1 m pendulum, mm: sideways {L * ws:.2f}, along the arc {L * x:.2f}, to the tangent point {L * t:.2f}; "
      f"rise {L * (1 - wc):.3f}, by x^2/2 {L * x * x / 2:.3f}")
print(f"second case, 40 deg = {x4:.6f} rad: sin {s4:.6f} < x < tan {s4 / c4:.6f}; x in place of sin x is {x4 / s4 - 1:.2%} too high")
edge = halve(lambda y: walk(y, 1e-4)[1] / y > 0.99, 0.1, 0.5)
print(f"within 1% of x: the bound x^2/2 promises it to {0.02 ** 0.5 * 180 / PI:.2f} deg; walked, it holds to {edge * 180 / PI:.2f} deg")
sa, ca = 0.5, c30                                # Archimedes: 30 deg halved four times
for _ in range(4):
    sa, ca = ((1 - ca) / 2) ** 0.5, ((1 + ca) / 2) ** 0.5
print(f"Archimedes, 96 sides: {96 * sa:.6f} < pi < {96 * sa / ca:.6f}; his fractions {3 + 10 / 71:.6f} and {3 + 1 / 7:.6f}")
print("chart, angle in deg: " + " ".join(f"{5 * k}" for k in range(1, 10)))
for name, f in (("tan x / x", lambda w, y: w[1] / w[0] / y), ("sin x / x", lambda w, y: w[1] / y), ("cos x", lambda w, y: w[0])):
    print(f"chart, {name}: " + " ".join(f"{f(w, r[0]):.2f}" for w, r in zip(two, one)))
print(f"mistakes: 5 for x is {5 / x:.2f} times x; rise by x^2 {L * x * x:.3f} mm; at 100 deg tan x {one[19][2] / one[19][1]:.6f}, x {one[19][0]:.6f}")
print(f"figure, 40 deg, radius 1 = 200: O (110, 16), A (110, 216), B ({110 + 200 * s4:.2f}, {16 + 200 * c4:.2f}), T ({110 + 200 * s4 / c4:.2f}, 216), "
      f"arc end ({110 + 30 * s4:.2f}, {16 + 30 * c4:.2f}), OB tick ({110 + 100 * s4 + 6 * c4:.2f}, {16 + 100 * c4 - 6 * s4:.2f}) "
      f"to ({110 + 100 * s4 - 6 * c4:.2f}, {16 + 100 * c4 + 6 * s4:.2f})")
assert max(abs(r[2] - w[1]) for r, w in zip(one, two)) < 1e-10          # two roads, each sine
assert abs(wa - x / 2) < 1e-10 and ws / 2 < wa < t / 2                   # slices give x/2, nested
for (y, _, _), (cy, sy, _) in zip(one, two):     # the whole chain at every chart angle
    assert 1 - y * y / 2 < cy < sy / y < 1 < sy / cy / y and cy < 1 - y * y / 2 + y ** 4 / 8
assert 96 * sa < PI < 96 * sa / ca                                       # the sandwich brackets pi
print("ALL CHECKS PASS")
