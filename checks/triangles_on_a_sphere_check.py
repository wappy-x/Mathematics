# Triangles on a sphere -- the check behind the card.  Standard library only.
# London, New York and the North Pole on a round Earth of radius 6371 km, then
# a second case, the octant.  Distance, corner angles and area: two roads each.
from math import sin, cos, acos, asin, atan2, sqrt, radians, degrees, pi
R = 6371.0
def dot(u, v): return sum(x * y for x, y in zip(u, v))
def cross(u, v): return [u[1]*v[2] - u[2]*v[1], u[2]*v[0] - u[0]*v[2], u[0]*v[1] - u[1]*v[0]]
def less(u, v, k=1.0): return [x - k * y for x, y in zip(u, v)]
def length(u): return sqrt(dot(u, u))
def unit(u): return [x / length(u) for x in u]
def point(lat, lon):                    # latitude, longitude in degrees -> unit arrow
    la, lo = radians(lat), radians(lon)
    return [cos(la) * cos(lo), cos(la) * sin(lo), sin(la)]
def corner(p, q, r):                    # road two to an angle: directions leaving p
    t, s = less(q, p, dot(p, q)), less(r, p, dot(p, r))
    return atan2(length(cross(t, s)), dot(t, s))
def flat_area(p, q, r, k):              # road two to the area: 4^k flat triangles
    if k == 0: return length(cross(less(q, p), less(r, p))) / 2
    m, n, o = unit(less(p, q, -1)), unit(less(q, r, -1)), unit(less(r, p, -1))
    return (flat_area(p, m, o, k-1) + flat_area(m, q, n, k-1)
            + flat_area(o, n, r, k-1) + flat_area(m, n, o, k-1))

def solve(lat1, lon1, lat2, lon2):      # A = first place, B = second, C = North Pole
    a, b, C = radians(90 - lat2), radians(90 - lat1), radians(abs(lon1 - lon2))
    c = acos(cos(a) * cos(b) + sin(a) * sin(b) * cos(C))       # road one: cosine law
    PA, PB, PC = point(lat1, lon1), point(lat2, lon2), [0.0, 0.0, 1.0]
    chord = length(less(PA, PB))                               # road two: straight chord
    A = acos((cos(a) - cos(b) * cos(c)) / (sin(b) * sin(c)))
    B = acos((cos(b) - cos(a) * cos(c)) / (sin(a) * sin(c)))
    tangents = [corner(PA, PB, PC), corner(PB, PC, PA), corner(PC, PA, PB)]
    girard = R * R * (A + B + C - pi)
    return a, b, C, c, 2 * asin(chord / 2), chord, [A, B, C], tangents, girard, R * R * flat_area(PA, PB, PC, 9), (PA, PB, PC)

d = lambda x: f"{degrees(x):.2f}"
a, b, C, c, c2, chord, ang, tan, girard, flat, pts = solve(51.5074, -0.1278, 40.7128, -74.0060)
ratios = [sin(ang[0]) / sin(a), sin(ang[1]) / sin(b), sin(C) / sin(c)]
print(f"sides to the pole: a (New York) {degrees(a):.4f} deg = {R * a:.2f} km, b (London) {degrees(b):.4f} deg = {R * b:.2f} km")
print(f"angle C at the pole {degrees(C):.4f} deg; route c by the cosine law {degrees(c):.6f} deg = {c:.6f} rad")
print(f"route c by the straight chord: {degrees(c2):.6f} deg (chord {R * chord:.2f} km)")
print(f"surface distance R x c = {R * c:.2f} km; 1 deg of central angle = {R * pi / 180:.2f} km")
print("corner angles A (London), B (New York), C, by the cosine law:", ", ".join(map(d, ang)))
print("the same corners, by tangent directions:", ", ".join(map(d, tan)))
print(f"sine law ratios: {ratios[0]:.6f}, {ratios[1]:.6f}, {ratios[2]:.6f}")
print(f"angle sum {d(sum(ang))} deg; excess {d(sum(ang) - pi)} deg = {sum(ang) - pi:.6f} rad")
print(f"area by Girard, R^2 x excess: {girard:.0f} km^2; by 262144 flat triangles: {flat:.0f} km^2")
print(f"share of Earth's surface ({4 * pi * R * R:.0f} km^2): {girard / (4 * pi * R * R):.2%}")
oa, ob, oC, oc, oc2, _, oang, otan, ogirard, oflat, _ = solve(0, 90, 0, 0)
print(f"octant: corners {', '.join(map(d, oang))}, sum {d(sum(oang))}; area {ogirard:.0f} km^2, flat triangles {oflat:.0f}, one eighth of 4 pi R^2 {pi * R * R / 2:.0f}")
flat_c = sqrt((R*a)**2 + (R*b)**2 - 2 * (R*a) * (R*b) * cos(C))
print(f"mistakes: flat law of cosines {flat_c:.2f} km; flat 180 deg at New York {d(pi - ang[0] - C)}; "
      f"excess left in degrees {R * R * degrees(sum(ang) - pi):.0f} km^2")
V = unit([x + y + z for x, y, z in zip(*pts)])
up = unit(less([0, 0, 1], V, V[2])); right = cross(up, V)
fig = [f"{180 + 150 * dot(p, right):.1f},{128 - 150 * dot(p, up):.1f}" for p in pts]
print(f"figure, 150 units = 6371 km: London {fig[0]}, New York {fig[1]}, pole {fig[2]}")
assert abs(c - c2) < 1e-12 and abs(oc - oc2) < 1e-12           # cosine law = chord road
assert max(abs(x - y) for x, y in zip(ang + oang, tan + otan)) < 1e-9   # two roads to corners
assert max(ratios) - min(ratios) < 1e-12                       # the sine law holds
assert abs(flat / girard - 1) < 1e-5 and abs(oflat / (pi * R * R / 2) - 1) < 1e-5
print("ALL CHECKS PASS")
