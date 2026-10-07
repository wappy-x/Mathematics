# Cross product and oriented area -- the check behind the card.  Only square root,
# arctangent and degrees are imported.  A 10 m by 6 m solar panel: bottom edge u, sloping edge v,
# in metres east, north, up.  Road 1 is the component formula.  Road 2 never forms a
# cross product: base times height for the area, the panel's tilt for the normal.
from math import sqrt, atan2, degrees

def cross(u, v):
    return (u[1]*v[2] - u[2]*v[1], u[2]*v[0] - u[0]*v[2], u[0]*v[1] - u[1]*v[0])

def dot(u, v):
    return u[0]*v[0] + u[1]*v[1] + u[2]*v[2]

def f(x):                                   # two decimals, and never "-0.00"
    return f"{(x if abs(x) > 5e-10 else 0.0):.2f}"

def vec(a):
    return "(" + ", ".join(f(x) for x in a) + ")"

def det3(a, b, c):                          # rows a, b, c; cofactors along the top row
    return (a[0]*(b[1]*c[2] - b[2]*c[1]) - a[1]*(b[0]*c[2] - b[2]*c[0])
            + a[2]*(b[0]*c[1] - b[1]*c[0]))

cases = [("case 1, bottom edge due east", (10.0, 0.0, 0.0), (0.0, 4.8, 3.6)),
         ("case 2, the same panel turned", (8.0, 6.0, 0.0), (-2.88, 3.84, 3.6))]
for label, u, v in cases:
    w = cross(u, v)                         # road 1
    area = sqrt(dot(w, w))
    n = tuple(x / area for x in w)
    k = dot(u, v) / dot(u, u)               # road 2: drop v's part along u, keep the height
    h = tuple(v[i] - k * u[i] for i in range(3))
    base, height = sqrt(dot(u, u)), sqrt(dot(h, h))
    run, rise = sqrt(h[0]**2 + h[1]**2), h[2]   # u is level, so h climbs straight up the slope
    tilt_n = (-h[0] / run * rise / height, -h[1] / run * rise / height, run / height)
    d = det3(u, v, w)
    print(f"{label}: u = {vec(u)}, v = {vec(v)}")
    print(f"  road 1, components: w = u x v = {vec(w)}, length {f(area)} m^2")
    print(f"  road 2, base times height: {f(base)} m x {f(height)} m = {f(base * height)} m^2")
    print(f"  unit normal by components {vec(n)}; by the tilt {vec(tilt_n)}")
    print(f"  w.u = {f(dot(w, u))}, w.v = {f(dot(w, v))}; det of rows u, v, w = {f(d)}")
    assert abs(area - base * height) < 1e-9                        # area, two roads
    assert all(abs(n[i] - tilt_n[i]) < 1e-12 for i in range(3))    # normal, two roads
    assert abs(dot(w, u)) < 1e-9 and abs(dot(w, v)) < 1e-9          # perpendicular to both
    assert d > 0 and abs(d - (w[0]**2 + w[1]**2 + w[2]**2)) < 1e-9  # right-handed
u, v = cases[0][1], cases[0][2]
w, bad = cross(u, v), (u[1]*v[2] - u[2]*v[1], u[0]*v[2] - u[2]*v[0], u[0]*v[1] - u[1]*v[0])
A = sqrt(dot(w, w))
print(f"tilt from level {degrees(atan2(v[2], v[1])):.2f} degrees; sin of the edge angle = {f(A / sqrt(dot(u, u) * dot(v, v)))}")
print(f"shadows: ground {f(w[2])}, east-west wall {f(w[1])}, north-south wall {f(w[0])}; squares add to {f(dot(w, w))}")
print(f"order swapped: v x u = {vec(cross(v, u))}, length {f(A)} m^2, facing down")
print(f"mistake, middle sign unflipped: {vec(bad)}; dot with v = {f(dot(bad, v))}, not 0")
print(f"mistake, dot product read as area: u.v = {f(dot(u, v))}, not {f(A)}")
print(f"mistake, triangle half-panel left unhalved: {f(A)} instead of {f(A / 2)} m^2")
print(f"figure, 1 m = 40 units: foot (100, 200), top ({100 + 40 * v[1]:.0f}, {200 - 40 * v[2]:.0f}), "
      f"normal ({100 + 20 * v[1]:.0f}, {200 - 20 * v[2]:.0f}) to ({100 + 20 * v[1] + 80 * w[1] / A:.0f}, {200 - 20 * v[2] - 80 * w[2] / A:.0f})")
print("ALL CHECKS PASS")
