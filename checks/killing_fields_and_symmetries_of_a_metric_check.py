# Killing fields -- the check behind the card.  Standard library only.
# The globe is a sphere of radius 6371 km in the chart (phi, theta): phi is the
# angle down from the North Pole, theta the longitude east, both in radians.
# Each field is tested by the chart formula for L_X g, by moving real points
# in space, and by counting every solution of the Killing equation.
from math import sin, cos, acos, asin, atan2, sqrt, radians, degrees, pi
R = 6371.0
LON = (radians(90 - 51.5074), radians(-0.1278))         # London (phi, theta)
NYC = (radians(90 - 40.7128), radians(-74.0060))        # New York (phi, theta)
A_WGS, B_WGS = 6378.137, 6378.137 * (1 - 1 / 298.257223563)   # the real Earth, km

def embed(p):                                           # chart point -> space, km
    f, t = p
    return (R * sin(f) * cos(t), R * sin(f) * sin(t), R * cos(f))
def turn(k, s, v):                                      # Rodrigues: turn v by s rad about unit k
    c = (k[1]*v[2] - k[2]*v[1], k[2]*v[0] - k[0]*v[2], k[0]*v[1] - k[1]*v[0])
    d = sum(a * b for a, b in zip(k, v))
    return tuple(v[i]*cos(s) + c[i]*sin(s) + k[i]*d*(1 - cos(s)) for i in range(3))
def dist(u, v):                                         # great-circle distance between space points, km
    return R * acos(max(-1.0, min(1.0, sum(a * b for a, b in zip(u, v)) / R**2)))

# name, field X = (X^phi, X^theta) in rad per unit time, its flow in space
FIELDS = [
    ("spin about the polar axis z", lambda p: (0.0, 1.0), lambda p, s: turn((0, 0, 1), s, embed(p))),
    ("spin about the axis x", lambda p: (-sin(p[1]), -cos(p[0]) / sin(p[0]) * cos(p[1])),
     lambda p, s: turn((1, 0, 0), s, embed(p))),
    ("spin about the axis y", lambda p: (cos(p[1]), -cos(p[0]) / sin(p[0]) * sin(p[1])),
     lambda p, s: turn((0, 1, 0), s, embed(p))),
    ("slide south", lambda p: (1.0, 0.0), lambda p, s: embed((p[0] + s, p[1]))),
    ("twist, rate sin(phi)", lambda p: (0.0, sin(p[0])), lambda p, s: embed((p[0], p[1] + s * sin(p[0])))),
]

def lie_formula(X, p):      # (L_X g)_ij / R^2 from the chart formula, g11 = 1, g22 = sin^2 phi
    h, (f, t) = 1e-5, p
    P, Q = X(p)
    Pf = (X((f + h, t))[0] - X((f - h, t))[0]) / (2 * h)
    Pt = (X((f, t + h))[0] - X((f, t - h))[0]) / (2 * h)
    Qf = (X((f + h, t))[1] - X((f - h, t))[1]) / (2 * h)
    Qt = (X((f, t + h))[1] - X((f, t - h))[1]) / (2 * h)
    return (2 * Pf, P * 2 * sin(f) * cos(f) + 2 * sin(f)**2 * Qt, Pt + sin(f)**2 * Qf), P * 2 * sin(f) * cos(f)

def lie_flow(flow, p):      # the definition: rate of change of squared tiny lengths under the flow
    h, t = 1e-4, 1e-4
    def q(u):
        a = (p[0] - h * u[0] / 2, p[1] - h * u[1] / 2)
        b = (p[0] + h * u[0] / 2, p[1] + h * u[1] / 2)
        d = lambda s: sum((x - y)**2 for x, y in zip(flow(a, s), flow(b, s)))
        return (d(t) - d(-t)) / (2 * t * h * h * R * R)
    q11, q22 = q((1, 0)), q((0, 1))
    return (q11, q22, (q((1, 1)) - q11 - q22) / 2)

def count_killing(a, b, steps=(8, 6)):   # nullity of the Killing equation over 50 trial fields
    FB = [lambda f: (1.0, 0.0), lambda f: (sin(f), cos(f)), lambda f: (cos(f), -sin(f)),
          lambda f: (cos(f) / sin(f), -1 / sin(f)**2), lambda f: (1 / sin(f), -cos(f) / sin(f)**2)]
    TB = [lambda t, k=k: (cos(k * t), -k * sin(k * t)) for k in (0, 1, 2)] + \
         [lambda t, k=k: (sin(k * t), k * cos(k * t)) for k in (1, 2)]
    rows = []
    for i in range(steps[0]):
        for j in range(steps[1]):
            f, t = 0.3 + 2.5 * i / (steps[0] - 1), 2 * pi * j / steps[1]
            g11, g22 = a*a*cos(f)**2 + b*b*sin(f)**2, a*a*sin(f)**2
            d11, d22 = 2 * (b*b - a*a) * sin(f) * cos(f), 2 * a*a * sin(f) * cos(f)
            r11, r22, r12 = [], [], []
            for comp in (0, 1):
                for F in FB:
                    for T in TB:
                        (u, uf), (v, vt) = F(f), T(t)
                        U, Uf, Ut = u * v, uf * v, u * vt
                        r11.append(U * d11 + 2 * g11 * Uf if comp == 0 else 0.0)
                        r22.append(U * d22 if comp == 0 else 2 * g22 * Ut)
                        r12.append(g11 * Ut if comp == 0 else g22 * Uf)
            rows += [r11, r22, r12]
    rank, n = 0, len(rows[0])
    scale = max(abs(x) for r in rows for x in r)
    for c in range(n):                                  # Gaussian elimination, partial pivoting
        piv = max(range(rank, len(rows)), key=lambda r: abs(rows[r][c]))
        if abs(rows[piv][c]) < 1e-9 * scale:
            continue
        rows[rank], rows[piv] = rows[piv], rows[rank]
        for r in range(rank + 1, len(rows)):
            m = rows[r][c] / rows[rank][c]
            rows[r] = [x - m * y for x, y in zip(rows[r], rows[rank])]
        rank += 1
    return n - rank

fmt = lambda v: "(" + ", ".join(f"{(x if abs(x) > 5e-7 else 0.0):+.6f}" for x in v) + ")"
print("L_X g at New York divided by R^2, components (11, 22, 12):")
worst, results = 0.0, {}
for name, X, flow in FIELDS:
    a, naive = lie_formula(X, NYC)
    b = lie_flow(flow, NYC)
    worst = max(worst, max(abs(x - y) for x, y in zip(a, b)))
    d = dist(flow(LON, 0.5), flow(NYC, 0.5))
    results[name] = (a, naive, d)
    print(f"  {name:<28} formula {fmt(a)}  moving points {fmt(b)}")
print(f"largest gap between the two roads: {worst:.9f}")
d0 = dist(embed(LON), embed(NYC))
print(f"London-New York before any flow: {d0:.2f} km; after 0.5 unit of each flow:")
for name, (a, naive, d) in results.items():
    print(f"  {name:<28} |{'#' * round(d / 250):<32}{d:.2f} km   Killing: {'yes' if max(map(abs, a)) < 1e-6 else 'no'}")
print(f"6 sidereal hours of Earth spin (pi/2 rad): {dist(FIELDS[0][2](LON, pi/2), FIELDS[0][2](NYC, pi/2)):.2f} km")

Px, Qx = FIELDS[1][1](NYC)
print(f"spin about x at New York: X = ({Px:+.6f}, {Qx:+.6f}); naive term X^phi d_phi g_22 = "
      f"{results['spin about the axis x'][1]:+.6f}, stretch term {2 * sin(NYC[0]) * cos(NYC[0]) * sin(NYC[1]):+.6f}")
X1, X2 = FIELDS[1][1], FIELDS[2][1]                       # bracket [X, Y]^k = X^i d_i Y^k - Y^i d_i X^k
def grad(Y, p, k, h=1e-5):
    return ((Y((p[0] + h, p[1]))[k] - Y((p[0] - h, p[1]))[k]) / (2 * h),
            (Y((p[0], p[1] + h))[k] - Y((p[0], p[1] - h))[k]) / (2 * h))
br = [sum(X1(NYC)[i] * grad(X2, NYC, k)[i] - X2(NYC)[i] * grad(X1, NYC, k)[i] for i in (0, 1)) for k in (0, 1)]
print(f"bracket [spin x, spin y] at New York, in the chart: {fmt(br)} = minus the spin about z")
n_sphere, n_egg = count_killing(1.0, 1.0), count_killing(A_WGS / R, B_WGS / R)
print(f"Killing fields among 50 trial fields: round globe {n_sphere}, flattened Earth {n_egg}; most possible in 2D: {2 * 3 // 2}")
pole = turn((1, 0, 0), pi / 2, (0.0, 0.0, B_WGS))
print(f"flattened Earth, North Pole turned 90 deg about x: {sqrt(sum(x * x for x in pole)):.3f} km from the centre,"
      f" equator at {A_WGS:.3f} km, off the surface by {A_WGS - B_WGS:.3f} km")
OMEGA = 2 * pi / 86164.0905                              # Earth's spin, rad/s: one turn per sidereal day
print(f"Earth's spin field: one turn per {86164.0905:.4f} s, {OMEGA * 1e5:.6f} x 10^-5 rad/s; ground speed London {R * sin(LON[0]) * OMEGA * 1000:.1f} m/s,"
      f" New York {R * sin(NYC[0]) * OMEGA * 1000:.1f} m/s, pole 0.0 m/s")
A, B = embed(LON), embed(NYC)                             # Clairaut: the polar spin's conserved number
c = acos(sum(x * y for x, y in zip(A, B)) / R**2)
clair = []
for s in (0.0, 0.5, 1.0):
    r = [(sin((1 - s) * c) * a + sin(s * c) * b) / sin(c) for a, b in zip(A, B)]
    T = [-cos((1 - s) * c) * a + cos(s * c) * b for a, b in zip(A, B)]
    T = [x / sqrt(sum(y * y for y in T)) for x in T]
    f, t = acos(r[2] / R), atan2(r[1], r[0])
    east, north = (-sin(t), cos(t), 0.0), (-cos(f) * cos(t), -cos(f) * sin(t), sin(f))
    head = atan2(sum(x * y for x, y in zip(T, east)), sum(x * y for x, y in zip(T, north))) % (2 * pi)
    clair.append(R * sin(f) * sin(head))
    print(f"great circle at {s:.1f} of the way: latitude {90 - degrees(f):.2f} deg, heading {degrees(head):.2f} deg,"
          f" g(spin z, T) = R sin(phi) sin(heading) = {clair[-1]:.2f} km")
print(f"highest latitude on the route, where the heading is due west: {90 - degrees(asin(-clair[0] / R)):.2f} deg")
assert worst < 1e-6                                                  # formula against moving points
assert all(abs(results[n][2] - d0) < 1e-6 for n, _, _ in FIELDS[:3])   # spins keep the distance
assert abs(results["slide south"][2] - d0) > 100 and abs(results["twist, rate sin(phi)"][2] - d0) > 100
assert n_sphere == 3 and n_egg == 1                                  # two counts of the symmetries
assert abs(br[0]) < 1e-6 and abs(br[1] + 1) < 1e-6                   # [X_x, X_y] = -X_z
assert max(clair) - min(clair) < 1e-6                                # conserved along the geodesic
print("ALL CHECKS PASS")
