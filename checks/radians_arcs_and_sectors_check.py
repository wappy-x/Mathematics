# Radians, arcs and sectors -- the check behind the card.  Standard library only.
# A 30 cm pizza, radius 15 cm, and a 60 degree slice.  Road one: radians and the
# formulas.  Road two: coordinates, no pi -- the crust as thousands of short chords.
import math
r, deg = 15.0, 60.0
theta = deg * math.pi / 180                      # road one: degrees to radians
arc, area = r * theta, r * r * theta / 2

def dist(p, q): return math.sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2)

def crust(rad, rounds):                 # crust points from 0 to 120 degrees, no angles used
    h = math.sqrt(rad * rad - (rad / 2) ** 2)    # triangles with three equal sides fix 60 and 120
    pts = [(rad, 0.0), (rad / 2, h), (-rad / 2, h)]
    for _ in range(rounds):             # halve every piece: push each chord's midpoint out to the crust
        new = [pts[0]]
        for p, q in zip(pts, pts[1:]):
            x, y = p[0] + q[0], p[1] + q[1]
            new += [(x * rad / math.sqrt(x * x + y * y), y * rad / math.sqrt(x * x + y * y)), q]
        pts = new
    return pts

def walk(pts, target=1e9):              # along the chords: pieces passed, length, area, where it stops
    done = tri = 0.0
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        c, mid = dist(p, q), ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
        f = min(1.0, (target - done) / c)            # stop partway along a chord at the target
        done, tri = done + f * c, tri + f * c * dist((0, 0), mid) / 2   # thin triangle: base x height / 2
        if f < 1: return i + f, done, tri, (p[0] + f * (q[0] - p[0]), p[1] + f * (q[1] - p[1]))
    return len(pts) - 1, done, tri, pts[-1]

fine = crust(r, 12)                     # 4096 pieces for every 60 degrees
print(f"pizza {2 * r:.0f} cm across, radius {r:.4f} cm; slice {deg:.0f} degrees")
print(f"road 1, convert: {deg:.0f} degrees = {theta:.6f} rad; 1 rad = {180 / math.pi:.6f} degrees")
print("landmarks in rad: " + ", ".join(f"{a} = {a * math.pi / 180:.6f}" for a in (30, 45, 90, 180, 360)))
print(f"road 1, formulas: crust {arc:.4f} cm, area {area:.4f} cm^2")
print(f"whole pizza: crust {2 * math.pi * r:.4f} cm, area {math.pi * r * r:.4f} cm^2; "
      f"one sixth: {2 * math.pi * r / 6:.4f} cm, {math.pi * r * r / 6:.4f} cm^2")
for step in (4096, 1024, 256, 1):
    _, L, T, _ = walk(fine[:4097:step])
    print(f"road 2, {4096 // step:>4} chord(s): length {L:.4f} cm, triangle area {T:.4f} cm^2")
(n1, _, _, P), (n2, _, A2, _) = walk(fine, r), walk(fine, 20.0)
print(f"road 2, length over radius {L / r:.6f} rad; walk {r:.0f} cm (one radius): {60 * n1 / 4096:.6f} degrees")
print(f"second case, 20 cm of crust: road 1 {20 / r:.6f} rad = {20 / r * 180 / math.pi:.6f} degrees, "
      f"area {r * 20 / 2:.4f} cm^2")
print(f"second case, road 2 walk: {60 * n2 / 4096:.6f} degrees, area {A2:.4f} cm^2")
_, L40, _, _ = walk(crust(20.0, 12)[:4097])
print(f"same slice of a 40 cm pizza, radius 20 cm: crust {L40:.4f} cm, crust over radius {L40 / 20:.6f}")
print(f"mistake, 60 used as radians: crust {r * 60:.4f} cm, area {r * r * 60 / 2:.4f} cm^2")
print(f"mistake, half left off: {r * r * theta:.4f} cm^2; diameter as radius: crust "
      f"{2 * r * theta:.4f} cm, area {2 * r * 2 * r * theta / 2:.4f} cm^2")
bx, by = 50 + 12 * fine[4096][0], 212 - 12 * fine[4096][1]
print(f"figure, 1 cm = 12 units: O (50.0,212.0), A ({50 + 12 * r:.1f},212.0), B ({bx:.1f},{by:.1f}), "
      f"angle mark to ({50 + (bx - 50) / 6:.1f},{212 - (212 - by) / 6:.1f}), "
      f"1 rad at ({50 + 12 * P[0]:.1f},{212 - 12 * P[1]:.1f})")
assert abs(L - arc) < 1e-6                       # chords against r x theta
assert abs(T - area) < 1e-5                      # thin triangles against r^2 x theta / 2
assert abs(60 * n1 / 4096 - 180 / math.pi) < 1e-6   # one radius of crust is 180/pi degrees
assert abs(A2 - r * 20 / 2) < 1e-5               # second case: area is radius x crust / 2
print("ALL CHECKS PASS")
