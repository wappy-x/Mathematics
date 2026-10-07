# Angles at a circle -- the check behind the card.  math supplies sqrt, acos,
# cos, sin and pi, nothing more.  A stage 12 m wide runs from A = (-6, 0) to
# B = (6, 0); the audience sits at positive y.  Road one: the circle rules.
# Road two: camera spots on a grid, every angle measured by the dot product.
import math

A, B, HALF = (-6.0, 0.0), (6.0, 0.0), 6.0

def dot(u, w): return u[0] * w[0] + u[1] * w[1]
def length(u): return math.sqrt(dot(u, u))

def seen(v):                                  # angle at v between A and B, in degrees
    u, w = (A[0] - v[0], A[1] - v[1]), (B[0] - v[0], B[1] - v[1])
    c = dot(u, w) / (length(u) * length(w))
    return math.acos(max(-1.0, min(1.0, c))) * 180 / math.pi

om = math.sqrt(HALF * HALF / 3)               # road one: half an equilateral triangle,
r60, O = 2 * om, (0.0, om)                    # so r = 2 OM and r^2 = OM^2 + 6^2
back, front_b = om + r60, om + math.sqrt(r60 * r60 - HALF * HALF)
arc_len = r60 * 120 * math.pi / 180           # the arc away from the camera: 120 deg of turn
a, b = 4.0, 16.0                              # the aisle: 4 m left of A, 16 m from B
P = -HALF - a                                 # where the aisle meets the stage line
r_aisle = (a + b) / 2                         # the centre sits over M, level with T (OT square)
t_rule = math.sqrt(r_aisle * r_aisle - HALF * HALF)   # how far back: Pythagoras on O, M, B
O2 = (0.0, t_rule)
thales = [seen((0.0, 6.0)), seen((3.6, 4.8))]              # road two: measure
arc = [seen((r60 * math.cos(d * math.pi / 180), om + r60 * math.sin(d * math.pi / 180)))
       for d in range(0, 181, 30)]
hits = [length((x / 20, y / 20 - om)) for x in range(-200, 201) for y in range(1, 241)
        if abs(seen((x / 20, y / 20)) - 60) < 0.05]
best, at = max(((seen((P, k / 1000)), k / 1000) for k in range(1, 40001)), key=lambda p: p[0])
wrong = math.sqrt(12 * 12 - HALF * HALF)     # mistake 1: centre angle 60, so O, A, B equilateral
print(f"stage A (-6, 0) to B (6, 0): {B[0] - A[0]:.0f} m wide, midpoint M (0, 0)")
print(f"90 deg lens, Thales: radius {HALF:.3f} m round M; at (0, 6) and (3.6, 4.8): "
      f"{thales[0]:.3f}, {thales[1]:.3f} deg")
print(f"60 deg lens: centre angle 120 deg; O {om:.3f} m back from M, radius {r60:.3f} m")
print(f"straight back from M {back:.3f} m; straight back from B {front_b:.3f} m")
print(f"measured at {len(arc)} spots round the arc: {min(arc):.3f} to {max(arc):.3f} deg; at O {seen(O):.3f} deg")
print(f"in radians: arc {arc_len:.3f} m / diameter {2 * r60:.3f} m = {arc_len / (2 * r60):.4f} rad"
      f" = {arc_len / (2 * r60) * 180 / math.pi:.3f} deg")
print(f"grid spots 5 cm apart seeing 60 +/- 0.05 deg: {len(hits)}, all {min(hits):.3f} to {max(hits):.3f} m from O")
print(f"aisle, a = {a:.0f} m, b = {b:.0f} m: circle radius {r_aisle:.3f} m, centre (0, {t_rule:.0f})")
print(f"rule: t = sqrt({r_aisle:.0f}^2 - 6^2) = {t_rule:.3f} = sqrt({a:.0f} x {b:.0f}) = {math.sqrt(a * b):.3f} m; "
      f"angle {seen(O2):.3f} / 2 = {seen(O2) / 2:.3f} deg")
print(f"scan of the aisle in 1 mm steps: widest {best:.3f} deg at {at:.3f} m")
print(f"at 4 m and 16 m back: {seen((P, 4.0)):.3f} and {seen((P, 16.0)):.3f} deg")
print(f"mistake 1, centre angle made 60: radius 12 m, straight back {wrong + 12:.3f} m sees {seen((0.0, wrong + 12)):.3f} deg")
print(f"mistake 2, 90 deg lens 12 m back, width taken as radius: {seen((0.0, 12.0)):.3f} deg")
print(f"mistake 3, same circle, behind the stage: {seen((0.0, om - r60)):.3f} deg")
print(f"mistake 4, aisle at the average ({a:.0f} + {b:.0f}) / 2 = {r_aisle:.0f} m: {seen((P, r_aisle)):.3f} deg")
print(f"figure 1, 1 m = 17 units: A (78, 30), B (282, 30), O (180, {30 + 17 * om:.1f}), radius {17 * r60:.1f}; "
      f"cameras (180, {30 + 17 * back:.1f}), (282, {30 + 17 * front_b:.1f}), (180, {30 + 17 * HALF:.0f})")
print(f"figure 2, 1 m = 10 units: P (80, 40), A ({80 + 10 * a:.0f}, 40), B ({80 + 10 * b:.0f}, 40), centre "
      f"({80 + 10 * r_aisle:.0f}, {40 + 10 * t_rule:.0f}), radius {10 * r_aisle:.0f}, T (80, {40 + 10 * t_rule:.0f})")
assert max(abs(x - 60) for x in arc + [seen((HALF, front_b))]) < 1e-9 and max(abs(x - 90) for x in thales) < 1e-9  # rim rule
assert abs(seen(O) - 2 * 60) < 1e-9 and abs(seen((0.0, back)) - arc_len / (2 * r60) * 180 / math.pi) < 1e-9  # centre; far arc / diameter
assert hits and max(abs(d - r60) for d in hits) < 0.05   # the grid finds no 60 deg spot off the arc
assert abs(at - math.sqrt(a * b)) < 0.002 and abs(best - seen(O2) / 2) < 1e-6  # widest at the touch
print("ALL CHECKS PASS")
