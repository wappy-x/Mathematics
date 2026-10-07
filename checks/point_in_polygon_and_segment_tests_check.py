# Inside or outside -- the check behind the card.  Standard library only.  A paddock
# of six corners, reflex at E; a drone at (70, 80), its pilot at (126, 60).  Each verdict
# is reached twice: ray crossings against winding angle, straddle test against solving.
import math
P = {"A": (0, 0), "B": (150, 0), "C": (170, 60), "D": (140, 100), "E": (70, 50), "F": (0, 100)}
fence = list(P.values())
edges = [(fence[i], fence[(i + 1) % 6]) for i in range(6)]
drone, pilot, B, C, D, E = (70, 80), (126, 60), P["B"], P["C"], P["D"], P["E"]
def orient(a, b, c):                   # twice the signed area of triangle a, b, c
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
def crossings(p, half_open=True):      # road one: x of each fence the ray going right meets
    hits = []
    for a, b in edges:
        closed = a[1] != b[1] and min(a[1], b[1]) <= p[1] <= max(a[1], b[1])
        if ((a[1] > p[1]) != (b[1] > p[1]) if half_open else closed) and orient(a, b, p) * (b[1] - a[1]) > 0:
            hits.append(a[0] + (p[1] - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
    return sorted(hits)
def winding(p):                        # road two: total turn of the sight line, in degrees
    total = 0.0
    for a, b in edges:
        d = math.atan2(b[1] - p[1], b[0] - p[0]) - math.atan2(a[1] - p[1], a[0] - p[0])
        total += (d + math.pi) % (2 * math.pi) - math.pi
    return abs(math.degrees(total))
def straddle(p, q, r, s):              # road one: each segment's ends on opposite sides of the other
    return orient(p, q, r) * orient(p, q, s) < 0 and orient(r, s, p) * orient(r, s, q) < 0
def solve(p, q, r, s):                 # road two: p + t(q - p) = r + u(s - r), by Cramer's rule
    dx, dy, ex, ey, fx, fy = q[0] - p[0], q[1] - p[1], s[0] - r[0], s[1] - r[1], r[0] - p[0], r[1] - p[1]
    det = ex * dy - dx * ey
    return (ex * fy - ey * fx) / det, (dx * fy - dy * fx) / det

side = lambda k: "inside" if k else "outside"
svg = lambda x, y: (round(27 + 1.8 * x, 1), round(210 - 1.8 * y, 1))
dist = lambda a, b: math.sqrt((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2)
print(f"reflex corner E: orient(D, E, F) = {orient(D, E, P['F'])}; area by shoelace {sum(orient((0, 0), a, b) for a, b in edges) / 2} m2")
for name, p in (("drone", drone), ("pilot", pilot)):
    h = crossings(p)
    print(f"{name} {p}: ray meets fences at x = {h}, count {len(h)} -> {side(len(h) % 2)}; winding {winding(p):.2f} deg")
print(f"orient(D, E, pilot) = {orient(D, E, pilot)}, orient(D, E, drone) = {orient(D, E, drone)}\n"
      f"orient(pilot, drone, D) = {orient(pilot, drone, D)}, orient(pilot, drone, E) = {orient(pilot, drone, E)}")
t, u = solve(pilot, drone, D, E)
X = (pilot[0] + t * (drone[0] - pilot[0]), pilot[1] + t * (drone[1] - pilot[1]))
print(f"flight line meets fence D-E at t = {t}, u = {u}, point ({X[0]:g}, {X[1]:g})")
by_straddle = [straddle(pilot, drone, a, b) for a, b in edges]
by_solving = [0 < v < 1 and 0 < w < 1 for v, w in [solve(pilot, drone, a, b) for a, b in edges]]
print(f"fences crossed by the flight line: straddle test {sum(by_straddle)}, solving {sum(by_solving)}")
grid = [(4 + 10 * i, 3 + 10 * j) for i in range(18) for j in range(10)]
ray_in, wind_in = [len(crossings(g)) % 2 == 1 for g in grid], [round(winding(g)) == 360 for g in grid]
print(f"grid of {len(grid)} points 10 m apart: inside by ray {sum(ray_in)}, by winding {sum(wind_in)}; x 100 m2 = {100 * sum(ray_in)} m2")
print(f"mistake 1, bounding box 0..170 by 0..100 says the drone is {side(0 <= drone[0] <= 170 and 0 <= drone[1] <= 100)}")
bad, (t2, u2) = crossings(pilot, half_open=False), solve(pilot, drone, B, C)
print(f"mistake 2, corner C counted on both its fences: pilot count {len(bad)} -> {side(len(bad) % 2)}")
print(f"mistake 3, fence B-C ends only: orient(pilot, drone, B) = {orient(pilot, drone, B)}, C = {orient(pilot, drone, C)} -> 'crosses'\n"
      f"  but orient(B, C, pilot) = {orient(B, C, pilot)}, orient(B, C, drone) = {orient(B, C, drone)}; t = {t2:.4f}, u = {u2:.4f}")
print(f"figure, corners {[svg(*c) for c in fence]}")
print(f"figure, drone {svg(*drone)}, pilot {svg(*pilot)}, meet {svg(*X)}, ray hits {[svg(x, drone[1]) for x in crossings(drone)]}, {svg(*C)}")
assert ray_in == wind_in and [len(crossings(p)) % 2 for p in (drone, pilot)] == [0, 1]
assert by_straddle == by_solving and by_straddle.index(True) == 3        # fence D-E, both roads
assert abs(dist(pilot, X) + dist(X, drone) - dist(pilot, drone)) < 1e-9 and abs(dist(D, X) - u * dist(D, E)) + abs(dist(X, E) - (1 - u) * dist(D, E)) < 1e-9
assert len(bad) % 2 != len(crossings(pilot)) % 2 and not 0 < t2 < 1
print("ALL CHECKS PASS")
