# Sine, cosine and tangent -- the check behind the card.  Nothing is imported.
# A 30 m crane boom at 40 degrees: how far out and how high is its tip?
# Road one measures the angle as a fraction of a turn: walk up a circle of
# radius 1 in tiny straight steps until the distance walked is 40/45 of the
# walk to the 45-degree point.  Road two halves angles: a chord's midpoint,
# pushed out to radius 1, halves its angle; 60 halvings from 0 and 90 close in.
BOOM, ANGLE, OUT = 30.0, 40.0, 20.0     # boom (m), boom angle (deg), second case reach (m)
TOP, STEPS = 0.5 ** 0.5, 400000         # the 45-degree point sits at height 1/sqrt(2)

def walk(target=None):                  # road one: climb from (1, 0) by equal rises
    s, x, y = 0.0, 1.0, 0.0
    for i in range(1, STEPS + 1):
        y2 = TOP * i / STEPS
        x2 = (1 - y2 * y2) ** 0.5       # Pythagoras keeps every point on the circle
        step = ((x - x2) ** 2 + (y2 - y) ** 2) ** 0.5
        if target is not None and s + step >= target:
            f = (target - s) / step     # stop part-way through the last step
            return x + f * (x2 - x), y + f * (y2 - y)
        s, x, y = s + step, x2, y2
    return s                            # no target: the whole walk to 45 degrees

EIGHTH = walk()                         # the arc to 45 degrees, an eighth of a turn
def point(deg): return walk(deg / 45 * EIGHTH)   # (cos, sin) of deg, for deg up to 45
(cA, sA), (c30, s30) = point(ANGLE), point(30.0)
lo, hi, p, q = 0.0, 90.0, (1.0, 0.0), (0.0, 1.0)   # road two: the points at 0 and 90 deg
for _ in range(60):                     # halve 60 times, keeping the half that holds 40
    mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2   # chord midpoint, on the halving line
    r, mid = (mx * mx + my * my) ** 0.5, (lo + hi) / 2
    if mid < ANGLE: p, lo = (mx / r, my / r), mid  # pushed out to radius 1
    else: q, hi = (mx / r, my / r), mid
(cB, sB) = p
reach, height = BOOM * cA, BOOM * sA
boom2, tip2 = OUT / cB, OUT * sB / cB   # second case: tip 20 m out, boom extended
rad = 180 / (4 * EIGHTH)                # one radian, the angle whose arc equals the radius
left = 40 * rad - 6 * 360               # 40 rad is six full turns and this much more
wrong = point(left - 90)[0]             # a quarter turn lifts a point's reach to its height
print(f"angles: A = {ANGLE:.0f}, C = 90, so B = 180 - 90 - {ANGLE:.0f} = {90 - ANGLE:.0f} deg")
print(f"walk to 45 deg: {EIGHTH:.6f}; one radian = {rad:.4f} deg")
print(f"road 1, arc 40/360 of a turn: sin 40 = {sA:.6f}, cos 40 = {cA:.6f}, tan 40 = {sA / cA:.6f}")
print(f"road 2, 60 halvings from 0 and 90 deg: sin 40 = {sB:.6f}, cos 40 = {cB:.6f}, tan 40 = {sB / cB:.6f}")
print(f"reach b = {BOOM:.0f} cos 40 = {reach:.6f} m; height a = {BOOM:.0f} sin 40 = {height:.6f} m")
for d, co, si in ((30, c30, s30), (40, cA, sA), (45, TOP, TOP), (50, sA, cA), (60, s30, c30)):  # 50, 60 by the complement rule
    print(f"table {d} deg: sin {si:.4f}  cos {co:.4f}  tan {si / co:.4f}")
print(f"from the table: 30 x 0.6428 = {30 * 0.6428:.4f} m against {height:.4f} m; "
      f"rounding moves it at most 30 x 0.00005 = {30 * 0.00005:.4f} m")
print(f"second case, tip {OUT:.0f} m out: boom 20 / cos 40 = {boom2:.6f} m, height 20 tan 40 = {tip2:.6f} m")
print(f"second case by scaling the first: height {height * OUT / reach:.6f} m, boom {BOOM * OUT / reach:.6f} m")
print(f"mistake, sine for the reach: {BOOM * sA:.2f} m, not {reach:.2f} m")
print(f"mistake, tangent times the boom: {BOOM * sA / cA:.2f} m, not {height:.2f} m")
print(f"mistake, radian mode: 40 rad = {40 * rad:.2f} deg = 6 turns + {left:.2f} deg, "
      f"sin = {wrong:.4f}, height {BOOM * wrong:.2f} m")
print(f"mistake, 20 x cos 40 for the boom: {OUT * cA:.2f} m, not {boom2:.2f} m")
print(f"figure, 1 m = 8 units: pivot (40,200), tip ({40 + 8 * reach:.2f},{200 - 8 * height:.2f}), "
      f"foot ({40 + 8 * reach:.2f},200), arc end ({40 + 30 * cA:.2f},{200 - 30 * sA:.2f})")
assert abs(sA - sB) < 1e-9                  # two roads to sin 40
assert abs(cA - cB) < 1e-9                  # two roads to cos 40
assert abs(s30 - 0.5) < 1e-9                # road one against half an equilateral triangle
assert max(abs(BOOM * OUT / reach - boom2), abs(height * OUT / reach - tip2)) < 1e-9  # scaling vs ratios
print("ALL CHECKS PASS")
