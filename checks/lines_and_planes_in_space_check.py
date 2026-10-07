# Lines and planes in space -- the check behind the card.  Nothing is imported.
# A drone at p = (2, 3, 5) flies along d = (2, 1, -2).  Below it a 10 m by 6 m
# solar panel has corner A = (0, 0, 0) and edges u = (10, 0, 0), v = (0, 4.8, 3.6).
# Each answer is reached twice: by the formula, and by a search that never uses it.
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def at(p, t, d): return (p[0] + t * d[0], p[1] + t * d[1], p[2] + t * d[2])
def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def length(a): return dot(a, a) ** 0.5
def f3(a): return "(" + ", ".join(f"{x:.3f}" for x in a) + ")"

p, d, q = (2, 3, 5), (2, 1, -2), (5, 1.5, 5)          # drone, flight direction, mast tip
A, u, v = (0, 0, 0), (10, 0, 0), (0, 4.8, 3.6)          # panel corner and its two edges
n = cross(u, v)                                         # the panel's normal
c = dot(n, A)
def gap(X): return dot(n, X) - c                        # zero on the plane; sign gives the side
t = (c - dot(n, p)) / dot(n, d)                         # road 1: substitute the line
lo, hi = 0.0, 5.0                                       # road 2: halve a bracket on the sign
for _ in range(80):
    mid = (lo + hi) / 2
    if gap(at(p, mid, d)) > 0: lo = mid
    else: hi = mid
hit = at(p, t, d)
def panel_coords(X): return dot(sub(X, A), u) / length(u), dot(sub(X, A), v) / length(v)
D = abs(gap(p)) / length(n)                             # road 1: the distance formula
foot = at(p, -gap(p) / dot(n, n), n)
grid = min((length(sub(p, at(at(A, i / 200, u), j / 120, v))), i / 20, j / 20)
           for i in range(201) for j in range(121))     # road 2: every 5 cm of the panel
m = (0, -3, 4)                                          # the normal divided by 12
Dm = abs(dot(m, p) - dot(m, A)) / length(m)
E = length(cross(sub(q, p), d)) / length(d)             # road 1: area over base
scan = min((length(sub(q, at(p, k / 1000, d))), k / 1000) for k in range(-2000, 3001))
d2 = (1, 4, 3)                                          # a flight that runs level with the panel
drop = p[2] - p[1] * (-n[1] / n[2])                     # straight down to the panel, at y = 3
def svg(X): return f"({60 + 40 * X[1]:.1f},{220 - 40 * X[2]:.1f})"
print(f"normal n = u x v = {f3(n)}, |n| = {length(n):.3f}, c = n.A = {c:.3f}")
print(f"road 1, substitute the line: t = {c - dot(n, p):.3f} / {dot(n, d):.3f} = {t:.6f}")
print(f"road 2, halve the bracket 80 times: t = {lo:.6f}")
print(f"hit = {f3(hit)}, %.3f m along the 10 m edge, %.3f m up the 6 m edge" % panel_coords(hit))
print(f"flight to the hit: t x |d| = {t:.3f} x {length(d):.3f} = {t * length(d):.3f} m")
print(f"road 1, distance formula: D = |{gap(p):.3f}| / {length(n):.3f} = {D:.3f} m")
print(f"road 2, closest of 24321 panel grid points: {grid[0]:.3f} m at {grid[1]:.3f} m along, {grid[2]:.3f} m up")
print(f"foot = {f3(foot)}; normal (0, -3, 4): D = {abs(dot(m, p)):.3f} / {length(m):.3f} = {Dm:.3f} m")
print(f"mast tip q = (5, 1.5, 5): road 1, |(q - p) x d| / |d| = {length(cross(sub(q, p), d)):.3f} / {length(d):.3f} = {E:.3f} m")
print(f"road 2, scanning t from -2 to 3 in steps of 0.001: {scan[0]:.3f} m at t = {scan[1]:.3f}")
print(f"level flight d = (1, 4, 3): n.d = {dot(n, d2):.3f}, gap stays {abs(gap(at(p, 7, d2))) / length(n):.3f} m, no hit")
print(f"mistake 1, raw gap as distance: {abs(gap(p)):.3f} instead of {D:.3f} m")
print(f"mistake 2, t read as metres: {t:.3f} instead of {t * length(d):.3f} m")
print(f"mistake 3, straight-down drop as distance: {drop:.3f} instead of {D:.3f} m")
print(f"figure, 1 m = 40 units: panel {svg(A)}-{svg(at(A, 1, v))}, drone {svg(p)}, hit {svg(hit)}, foot {svg(foot)}")
assert abs(lo - t) < 1e-9                                # two roads to the meeting point
assert abs(grid[0] - D) < 1e-9 and abs(dot(m, foot)) < 1e-12 and max(abs(g - f) for g, f in zip(grid[1:], panel_coords(foot))) < 1e-9
assert abs(scan[0] - E) < 1e-6 and abs(Dm - D) < 1e-12   # line distance; normal's scale is irrelevant
assert abs(dot(m, hit)) < 1e-12 and 0 <= panel_coords(hit)[0] <= 10 and 0 <= panel_coords(hit)[1] <= 6
print("ALL CHECKS PASS")
