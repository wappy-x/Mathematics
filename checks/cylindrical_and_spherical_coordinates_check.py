# Cylindrical and spherical coordinates -- the check behind the card.  Standard
# library only.  Latitude and longitude become (x, y, z) by two roads, and
# (x, y, z) goes back to the angles by two more.  Earth is a ball, R = 6371 km.
from math import sin, cos, acos, atan, atan2, sqrt, radians as rad, degrees as deg
R, CITIES = 6371.0, [("Tokyo", 35.68, 139.69), ("Rio", -22.91, -43.17)]

def spherical(rho, theta, phi):         # road 1: radius, longitude, angle down from the pole
    s = rho * sin(rad(phi))
    return (s * cos(rad(theta)), s * sin(rad(theta)), rho * cos(rad(phi)))

def via_cylinder(lat, lon):             # road 2: meridian triangle, then polar in the equator
    r, z = R * cos(rad(lat)), R * sin(rad(lat))
    return (r * cos(rad(lon)), r * sin(rad(lon)), z), r, z

def back_atan2(x, y, z):                # inverse road 1: the quadrant-aware angle
    r = sqrt(x * x + y * y)
    return sqrt(r * r + z * z), deg(atan2(y, x)), deg(atan2(r, z))

def back_dot(x, y, z):                  # inverse road 2: dot products with Greenwich and the pole
    rho, r = sqrt(x * x + y * y + z * z), sqrt(x * x + y * y)
    return rho, deg(acos(x / r)) * (1 if y >= 0 else -1), deg(acos(z / rho))

pts, g = {}, lambda t: "(" + ", ".join(f"{v:.1f}" for v in t) + ")"
print(f"radius {R:.0f} km; angles in degrees; colatitude = 90 - latitude")
for name, lat, lon in CITIES:
    p1 = spherical(R, lon, 90 - lat)
    p2, r, z = via_cylinder(lat, lon)
    a, b = back_atan2(*p1), back_dot(*p1)
    pts[name] = p1
    print(f"{name}: latitude {lat:.2f}, longitude {lon:.2f}, colatitude {90 - lat:.2f}")
    print(f"  cylindrical (r, theta, z) = ({r:.1f}, {lon:.2f}, {z:.1f})")
    print(f"  (x, y, z): road 1 spherical {g(p1)}; road 2 via cylinder {g(p2)}")
    print(f"  back: atan2 road (rho, theta, phi) = ({a[0]:.1f}, {a[1]:.2f}, {a[2]:.2f}); dot road ({b[0]:.1f}, {b[1]:.2f}, {b[2]:.2f})")
    assert max(abs(u - v) for u, v in zip(p1, p2)) < 1e-9          # two forward roads
    assert max(abs(u - v) for u, v in zip(a + b, (R, lon, 90 - lat) * 2)) < 1e-9  # two inverse roads
T, S = pts["Tokyo"], pts["Rio"]
chord = sqrt(sum((u - v) ** 2 for u, v in zip(T, S)))              # distance formula in 3D
gamma = acos(sum(u * v for u, v in zip(T, S)) / (R * R))             # angle at Earth's centre
print(f"Tokyo to Rio straight through the Earth: {chord:.1f} km; angle at the centre {deg(gamma):.2f}")
assert abs(chord - 2 * R * sin(gamma / 2)) < 1e-6                    # chord of a circle, second road
a_, e2, la, lo = 6378.137, 0.00669437999014, rad(35.68), rad(139.69)
N = a_ / sqrt(1 - e2 * sin(la) ** 2)                                 # the flattened Earth (WGS 84)
E = (N * cos(la) * cos(lo), N * cos(la) * sin(lo), N * (1 - e2) * sin(la))
print(f"Tokyo on the flattened Earth {g(E)}; gap from the ball {sqrt(sum((u - v) ** 2 for u, v in zip(E, T))):.1f} km")
w1 = spherical(R, 139.69, 35.68)
print(f"mistake 1, latitude in the colatitude slot: {g(w1)}, latitude {90 - back_atan2(*w1)[2]:.2f}")
w2 = back_atan2(*spherical(R, 90 - 35.68, 139.69))
print(f"mistake 2, the two angles swapped: lands at latitude {90 - w2[2]:.2f}, longitude {w2[1]:.2f}")
x, y, _ = T
print(f"mistake 3, plain arctan(y / x) for Tokyo's longitude: {deg(atan(y / x)):.2f}")
assert abs(deg(atan(y / x)) + 180 - 139.69) < 1e-9                  # arctan is off by half a turn
k, cx, cy = 0.015, 180, 120                                          # figure scale: 1 km = 0.015 units
rr, zz = R * cos(rad(35.68)), R * sin(rad(35.68))
print(f"figure, side view: circle radius {k * R:.2f}, Tokyo at ({cx + k * rr:.2f}, {cy - k * zz:.2f})")
print("ALL CHECKS PASS")
