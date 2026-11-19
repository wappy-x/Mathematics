# Regular surfaces -- the check behind the card.  Stadium roof, metres:
# z = h(x, y) = 40 + x^2 (120 - x)/40000 - y^2/250 over x in [-40, 120], y in [-50, 50].
# Road one: the graph patch r(x, y) = (x, y, h), tangent arrows from exact slopes.
# Road two: a polar patch about the crown (80, 0), arrows by central differences.
# Road three: a survey, the plane through four roof points, no derivatives at all.
from math import sqrt, cos, sin, atan2, degrees, pi

def h(x, y): return 40 + x * x * (120 - x) / 40000 - y * y / 250
def hx(x, y): return (240 * x - 3 * x * x) / 40000          # slope east
def hy(x, y): return -2 * y / 250                           # slope north
def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def dot(a, b): return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
def norm(a): return sqrt(dot(a, a))
def unit(a): return tuple(c / norm(a) for c in a)
def sub(a, b): return tuple(p - q for p, q in zip(a, b))
def angle(a, b): return degrees(atan2(norm(cross(a, b)), dot(a, b)))   # degrees between arrows
def vec(a, d=6): return "(" + ", ".join(f"{c:.{d}f}" for c in a) + ")"

def graph(x, y):                          # road one: r_x = (1, 0, h_x), r_y = (0, 1, h_y)
    rx, ry = (1.0, 0.0, hx(x, y)), (0.0, 1.0, hy(x, y))
    return rx, ry, cross(rx, ry)

def polar(rho, th):                       # the roof by distance rho and angle th from the crown
    x, y = 80 + rho * cos(th), rho * sin(th)
    return (x, y, h(x, y))

def polar_arrows(rho, th, d=1e-5):        # road two: tangent arrows by central differences
    rr = tuple(c / (2 * d) for c in sub(polar(rho + d, th), polar(rho - d, th)))
    rt = tuple(c / (2 * d) for c in sub(polar(rho, th + d), polar(rho, th - d)))
    return rr, rt, cross(rr, rt)

def survey(x, y, s):                      # road three: chords between roof points s metres out
    a = sub((x + s, y, h(x + s, y)), (x - s, y, h(x - s, y)))
    b = sub((x, y + s, h(x, y + s)), (x, y - s, h(x, y - s)))
    return unit(cross(a, b))

for name, (x, y) in (("P, over the saddle", (20.0, 25.0)), ("Q, on the dome", (100.0, -15.0))):
    rx, ry, N = graph(x, y)
    n, c = unit(N), dot(N, (x, y, h(x, y)))
    print(f"{name}: ({x:.0f}, {y:.0f}), height {h(x, y):.4f} m")
    print(f"  r_x = {vec(rx, 2)}, r_y = {vec(ry, 2)}, N = {vec(N, 2)}, |N| = {norm(N):.6f}")
    print(f"  n = {vec(n)}, tilt {angle(N, (0, 0, 1)):.4f} degrees, steepest slope {sqrt(N[0] ** 2 + N[1] ** 2):.6f}")
    print(f"  tangent plane: N . (x, y, z) = N . p = {c:.4f}")

P = (20.0, 25.0, h(20.0, 25.0))
rx, ry, N = graph(20.0, 25.0)
n = unit(N)
rho, th = sqrt(60.0 ** 2 + 25.0 ** 2), atan2(25.0, -60.0)
rr, rt, M = polar_arrows(rho, th)
print(f"polar chart at P: rho = {rho:.4f} m, theta = {th:.6f} rad = {degrees(th):.6f} degrees")
print(f"  r_rho = {vec(rr)}, r_theta = {vec(rt)}")
print(f"  N' = {vec(M)}, |N'|/|N| = {norm(M) / norm(N):.6f}, Jacobian rho = {rho:.6f}")
print(f"  n' = {vec(unit(M))}, largest r_rho.n, r_theta.n: {max(abs(dot(rr, n)), abs(dot(rt, n))):.6f}")
for s in (4.0, 1.0):
    m = survey(20.0, 25.0, s)
    print(f"survey {s:.0f} m out: n = {vec(m)}, angle to n {angle(m, n) * 3600:.4f} arcseconds")
print(f"gap, roof minus tangent plane, mm (gap/step^2 in mm per m^2; h_xx/2 = {1000 * (240 - 120) / 80000:.4f}, h_yy/2 = {-1000 / 250:.4f}):")
gaps = [(s, h(20 + s, 25) - (P[2] + 0.09 * s), h(20, 25 + s) - (P[2] - 0.2 * s)) for s in (4.0, 2.0, 1.0, 0.5)]
for s, ge, gn in gaps:
    print(f"  step {s:.1f} m: east {1000 * ge:.4f} ({1000 * ge / s / s:.4f}), north {1000 * gn:.4f} ({1000 * gn / s / s:.4f})")
print(f"chart roof y=25: " + ", ".join(f"{h(x, 25):.1f}" for x in range(-40, 121, 20)))
print(f"chart plane y=25: " + ", ".join(f"{P[2] + 0.09 * (x - 20):.1f}" for x in range(-40, 121, 20)))
D = tuple(p + 2 * c for p, c in zip(P, n))
print(f"drone 2 m off along n: {vec(D, 4)}; along N instead: {2 * norm(N):.4f} m off")
print(f"mistake, r_y x r_x: n = {vec(unit(cross(ry, rx)))}, points into the stands")
bad = (0.09, -0.2, 1.0)
print(f"mistake, slopes without the minus signs: {vec(bad, 2)}, {angle(bad, N):.4f} degrees off")
cz = polar_arrows(0.0, 0.3)[2]
a1, a2 = polar_arrows(0.001, 0.0)[2], polar_arrows(0.001, pi)[2]
print(f"crown (80, 0), {h(80.0, 0.0):.4f} m up: polar |N'| at rho = 0: {norm(cz):.6f}; graph chart tilt {angle(graph(80.0, 0.0)[2], (0, 0, 1)):.4f} degrees")
print(f"crown, polar normals 1 mm east and west differ by {angle(a1, a2) * 3600:.2f} arcseconds")
def cone(u, v): return cross((cos(v), sin(v), -1.0), (-u * sin(v), u * cos(v), 0.0))
k1, k2 = cone(0.001, 0.0), cone(0.001, pi)
print(f"spire, 45-degree cone: |N| at tip {norm(cone(0.0, 0.0)):.6f}; normals 1 mm either side differ by {angle(k1, k2):.4f} degrees")
def eight(u): return cross((2 * cos(2 * u), cos(u), 0.0), (0.0, 0.0, 1.0))
e1, e2 = eight(pi), eight(1e-9)
print(f"figure-eight sheet at the crossing: N = {vec(e1, 2)} and {vec(e2, 2)}, {angle(e1, e2):.4f} degrees apart")
g = [ge / (s * s) for s, ge, gn in gaps[2:]]                     # the printed rows at 1 m and 0.5 m
assert max(abs(p - q) for p, q in zip(unit(M), n)) < 1e-8        # two charts, one unit normal
assert abs(norm(M) / norm(N) - rho) < 1e-6                         # normals differ by the Jacobian
assert max(abs(dot(rr, n)), abs(dot(rt, n))) < 1e-6                # polar arrows lie in the graph plane
assert angle(survey(20.0, 25.0, 1.0), n) < angle(survey(20.0, 25.0, 4.0), n) / 10   # survey closes in
assert abs(g[1] - (240 - 120) / 80000) < abs(g[0] - (240 - 120) / 80000) < 3e-5   # gap/step^2 -> h_xx/2
assert angle(a1, a2) < 0.01 and angle(k1, k2) > 89                 # crown regular, spire tip not
assert angle(e1, e2) > 50                                          # crossing: two planes at one point
assert max(abs(gn / (s * s) + 1 / 250) for s, ge, gn in gaps) < 1e-9   # north gap/step^2 = h_yy/2 exactly
assert norm(cz) < 1e-9 and norm(cone(0.0, 0.0)) < 1e-12           # N = 0 at the polar centre and the spire tip
print("ALL CHECKS PASS")
