# Law of cosines -- the check behind the card.  Only cos, sin, sqrt and pi are
# imported.  A surveyor at C sights marker B 300 m away and pylon A 450 m away,
# 52 degrees apart.  Distance, area and angles are each reached by two roads.
from math import cos, sin, sqrt, pi
a, b, C = 300.0, 450.0, 52.0                  # the two sightings (m), the angle between

def rad(deg): return deg * pi / 180           # degrees to radians, for cos and sin
def law(a, b, deg):                           # road one: the law of cosines
    return sqrt(a * a + b * b - 2 * a * b * cos(rad(deg)))

def grid(a, b, deg, turn=20.0):               # road two: two directions on a grid,
    ax, ay = b * cos(rad(turn)), b * sin(rad(turn))               # pylon at 20 degrees,
    bx, by = a * cos(rad(turn + deg)), a * sin(rad(turn + deg))   # marker deg further
    return sqrt((ax - bx) ** 2 + (ay - by) ** 2)                  # round; Pythagoras

def angle_back(q):                            # the angle from 0 to 180 whose cosine is q,
    lo, hi = 0.0, 180.0                       # found by halving: cos falls steadily there
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if cos(rad(mid)) > q else (lo, mid)
    return (lo + hi) / 2
def cos_facing(x, y, z):                      # SSS: cosine of the angle facing side x
    return (y * y + z * z - x * x) / (2 * y * z)

def figure(name, deg, scale, x0):             # corners of the drawn figure, y pointing down
    bx, by = x0 + scale * a * cos(rad(deg)), 200 - scale * a * sin(rad(deg))
    print(f"figure, {name}, 1 m = {scale:.1f} units: C ({x0:.2f}, 200.00), "
          f"A ({x0 + scale * b:.2f}, 200.00), B ({bx:.2f}, {by:.2f}), foot ({bx:.2f}, 200.00)")

c, cg = law(a, b, C), grid(a, b, C)
h, near = a * sin(rad(C)), a * cos(rad(C))
K = 0.5 * b * h                               # half base times height
s = (a + b + cg) / 2                          # Heron, from the grid's three sides only
heron = sqrt(s * (s - a) * (s - b) * (s - cg))
qA, qB, qC = cos_facing(a, b, cg), cos_facing(b, a, cg), cos_facing(cg, a, b)
A_, B_, C_ = angle_back(qA), angle_back(qB), angle_back(qC)
print(f"sightings a = {a:.2f} m, b = {b:.2f} m, angle C = {C:.2f} degrees; "
      f"cos C = {cos(rad(C)):.8f}, sin C = {sin(rad(C)):.8f}")
print(f"a^2 + b^2 = {a * a + b * b:.2f}; correction 2ab cos C = {2 * a * b * cos(rad(C)):.2f}; c^2 = {c * c:.2f}")
print(f"SAS, c by the law: {c:.2f} m; by directions 20 and {20 + C:.0f} degrees on a grid: {cg:.2f} m")
print(f"height h = a sin C = {h:.2f} m; near piece a cos C = {near:.2f} m; far piece b - a cos C = {b - near:.2f} m")
print(f"area (1/2) b h = {K:.2f} m^2 = {K / 10000:.2f} hectares of 10000 m^2; Heron from three sides: {heron:.2f} m^2")
print(f"SSS, cos A = {qA:.4f}, cos B = {qB:.4f}, cos C = {qC:.4f}")
print(f"angles back by halving: A = {A_:.2f}, B = {B_:.2f}, C = {C_:.2f} degrees; sum {A_ + B_ + C_:.2f}")
for deg in (90.0, 128.0):
    print(f"at {deg:.0f} degrees: law {law(a, b, deg):.2f} m, grid {grid(a, b, deg):.2f} m, near piece "
          f"{a * cos(rad(deg)):.2f} m, far piece {b - a * cos(rad(deg)):.2f} m, area {0.5 * a * b * sin(rad(deg)):.2f} m^2")
print(f"no triangle: sides 300, 450, 800 m need cos C = {cos_facing(800.0, a, b):.4f}, below -1")
print(f"mistake, no correction: {sqrt(a * a + b * b):.2f} m; correction without the 2: "
      f"{sqrt(a * a + b * b - a * b * cos(rad(C))):.2f} m")
print(f"mistake, 52 read as radians: {sqrt(a * a + b * b - 2 * a * b * cos(C)):.2f} m; "
      f"area with cos for sin: {0.5 * a * b * cos(rad(C)):.2f} m^2")
figure("acute", C, 0.6, 40.0)
figure("obtuse", 128.0, 0.5, 112.0)
for deg in (C, 90.0, 128.0):
    assert abs(law(a, b, deg) - grid(a, b, deg)) < 1e-9     # two roads, one distance
assert abs(K - heron) < 1e-6                                 # two roads, one area
assert abs(C_ - C) < 1e-9                                    # SSS hands back the SAS angle
assert abs(A_ + B_ + C_ - 180.0) < 1e-9                      # three separate angles close up
print("ALL CHECKS PASS")
