# Koch snowflake and fractal dimension -- the check behind the card.  Only
# math is imported, for sqrt, hypot and log.  A 27 cm equilateral triangle;
# each stage swaps every side's middle third for two sides of an outward bump.
# Perimeter, area and dimension are each reached by two separate roads.
import math
S3, SIDE = math.sqrt(3), 27.0
R, A0 = SIDE / S3, S3 / 4 * SIDE * SIDE      # centre-to-corner distance, first area

def koch(poly):                              # one stage: every side becomes four
    out = []
    for i, (px, py) in enumerate(poly):
        qx, qy = poly[(i + 1) % len(poly)]
        dx, dy = (qx - px) / 3, (qy - py) / 3
        ax, ay = px + dx, py + dy            # apex: the middle third turned 60 degrees out
        out += [(px, py), (ax, ay), (ax + dx / 2 + dy * S3 / 2, ay - dx * S3 / 2 + dy / 2), (ax + dx, ay + dy)]
    return out

def shoelace(p):                             # road one to the area
    return sum(p[i - 1][0] * p[i][1] - p[i][0] * p[i - 1][1] for i in range(len(p))) / 2

def walk(p):                                 # road one to the perimeter
    return sum(math.hypot(p[i][0] - p[i - 1][0], p[i][1] - p[i - 1][1]) for i in range(len(p)))

stages = [[(0.0, R), (-SIDE / 2, -R / 2), (SIDE / 2, -R / 2)]]
for n in range(6):
    stages.append(koch(stages[-1]))
print(f"side 27 cm; first area {A0:.4f} cm^2; the snowflake's area {1.6 * A0:.4f}; hexagon {2 * A0:.4f}")
print("stage, sides, perimeter walked / 81 x (4/3)^n, area by shoelace / by formula (cm, cm^2)")
for n, p in enumerate(stages[:6]):
    per, area, formula = walk(p), shoelace(p), A0 * (1.6 - 0.6 * (4 / 9) ** n)
    print(f"{n}, {len(p)}, {per:.4f} / {81 * (4 / 3) ** n:.4f}, {area:.4f} / {formula:.4f}")
    assert abs(per - 81 * (4 / 3) ** n) < 1e-9 * per and abs(area - formula) < 1e-9 * area  # two roads each
normals = ((1.0, 0.0), (0.5, S3 / 2), (-0.5, S3 / 2))     # the hexagon's sides face these ways, and back
reach = max(abs(x * c + y * s) for x, y in stages[6] for c, s in normals)
print(f"stage 6: {len(stages[6])} sides; farthest reach toward a hexagon side {reach:.4f} cm, apothem {R * S3 / 2:.4f}")
assert reach <= R * S3 / 2 + 1e-9                             # never leaves the hexagon
for km in (1, 40075):                                         # 1 km, then the equator
    goal, n, per = km * 1e5, 0, 81.0
    while per <= goal:
        n, per = n + 1, per * 4 / 3
    by_log = math.ceil(math.log(goal / 81) / math.log(4 / 3))
    print(f"perimeter first passes {km} km at stage {n} by stepping, {by_log} by logs")
    assert n == by_log
dims = [(nm, math.log(N) / math.log(s)) for nm, N, s in (("line", 3, 3), ("square", 9, 3), ("Koch", 4, 3), ("Sierpinski", 3, 2))]
print("log N / log s: " + ", ".join(f"{nm} {d:.4f}" for nm, d in dims))
counts = [len({(math.floor(x / (SIDE / 3 ** k)), math.floor(y / (SIDE / 3 ** k))) for x, y in stages[6]}) for k in (2, 3, 4)]
slope = math.log(counts[2] / counts[0]) / math.log(9)
print(f"boxes of 3, 1, 1/3 cm touching stage 6: {counts}; slope log(count) per log(1/size) {slope:.4f}")
assert abs(slope - dims[2][1]) < 0.05                        # box count agrees with log 4 / log 3
print(f"figure, 1 cm = 7 units, centre (180, 120): corners (180, {120 - 7 * R:.2f}), ({180 - 7 * SIDE / 2:.2f}, "
      f"{120 + 3.5 * R:.2f}), ({180 + 7 * SIDE / 2:.2f}, {120 + 3.5 * R:.2f}); lowest tip y {120 + 7 * R:.2f}; cap {SIDE * S3 / 6:.4f} cm = {12 * SIDE * S3 / 6:.2f} units")
print(f"Sierpinski stage 6: {3 ** 6} triangles, {(3 / 4) ** 6:.4f} of the area left")
print(f"mistakes: log 3 / log 4 = {math.log(3) / math.log(4):.4f}; log 4 / log(4/3) = {math.log(4) / math.log(4 / 3):.4f};"
      f" stage 10 area with 4/3 for 4/9 = {A0 * (4 / 3) ** 10:.2f}, true {A0 * (1.6 - 0.6 * (4 / 9) ** 10):.2f}")
print("ALL CHECKS PASS")
