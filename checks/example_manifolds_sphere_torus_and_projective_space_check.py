# Sphere, torus and projective plane -- the check behind the card.  Standard library only.
# Changes of chart: closed form against chart-of-inverse-chart; determinants: closed form
# against central differences; clockwise: count the mirror choices that keep it; Euler
# characteristic: glued meshes counted against curvature summed over the surface.
from math import sin, cos, atan2, acos, sqrt, radians, degrees, pi
from itertools import product
R, A, B = 6371.0, 3.0, 1.5             # globe radius, km; doughnut: centre-circle and tube radius, cm
def sph(lat, lon):                     # latitude N, longitude E in degrees -> point in space, km
    p, t = radians(90 - lat), radians(lon)
    return (R * sin(p) * cos(t), R * sin(p) * sin(t), R * cos(p))
CITY = {"London": (51.5074, -0.1278), "Tokyo": (35.6762, 139.6503),
        "Delhi": (28.6139, 77.2090), "Sydney": (-33.8688, 151.2093)}
PTS = [sph(*v) for v in CITY.values()]
LON = PTS[0]
def det2(f, u):                        # Jacobian determinant of a map of the plane, central differences
    c = []
    for i in range(2):
        h = 1e-6 * max(1.0, abs(u[i]))
        up, dn = [x + h * (k == i) for k, x in enumerate(u)], [x - h * (k == i) for k, x in enumerate(u)]
        c.append([(a - b) / (2 * h) for a, b in zip(f(up), f(dn))])
    return c[0][0] * c[1][1] - c[0][1] * c[1][0]
def orientations(charts, samples):     # mirror choices (one sign per chart) keeping every det > 0
    dets = [(i, j, det2(lambda u, i=i, j=j: charts[j][0](charts[i][1](u)), charts[i][0](p)))
            for p in samples for i in range(len(charts)) for j in range(len(charts)) if i != j]
    return sum(all(s[i] * s[j] * d > 0 for i, j, d in dets)
               for s in product((1, -1), repeat=len(charts)))
f2 = lambda u: f"({u[0]:.2f}, {u[1]:.2f})"
# The globe: stereographic charts from the North Pole and from the South Pole
def sN(p): return (R * p[0] / (R - p[2]), R * p[1] / (R - p[2]))
def sS(p): return (R * p[0] / (R + p[2]), R * p[1] / (R + p[2]))
def back(u, sgn):
    s = u[0] ** 2 + u[1] ** 2
    return (2 * R * R * u[0] / (s + R * R), 2 * R * R * u[1] / (s + R * R), sgn * R * (s - R * R) / (s + R * R))
SPH = [(sN, lambda u: back(u, 1)), (sS, lambda u: back(u, -1))]
uN, uS = sN(LON), sS(LON)
n2 = uN[0] ** 2 + uN[1] ** 2
T = (R * R * uN[0] / n2, R * R * uN[1] / n2)
dS, dF = -(R * R / n2) ** 2, det2(lambda u: sS(back(u, 1)), uN)
print(f"globe: R = {R:.0f} km; London at latitude 51.5074 N, longitude 0.1278 W")
print(f"London in space: ({LON[0]:.2f}, {LON[1]:.2f}, {LON[2]:.2f}) km")
print(f"chart from North Pole: {f2(uN)} km; from South Pole: {f2(sS(LON))} km")
print(f"|u_N| = {sqrt(n2):.2f} km, |u_S| = {sqrt(uS[0]**2 + uS[1]**2):.2f} km; product {sqrt(n2) * sqrt(uS[0]**2 + uS[1]**2):.1f} = R^2 = {R*R:.1f} km^2")
print(f"change of chart R^2 u/|u|^2 applied to u_N: {f2(T)} km")
print(f"det of change, closed form -R^4/|u|^4: {dS:.6f}; differences: {dF:.6f}; length factor {R*R/n2:.6f}")
pole = sph(90 - degrees(1 / R), 0.0)
print(f"a point 1 km from the North Pole, chart from North Pole: {sN(pole)[0]:.0f} km out")
# The doughnut: angle charts on four windows; theta round the hole, psi round the tube
def tor(u): w = A + B * cos(u[1]); return (w * cos(u[0]), w * sin(u[0]), B * sin(u[1]))
def win(lt, ls):
    def f(p):
        t, s = atan2(p[1], p[0]), atan2(p[2], sqrt(p[0] ** 2 + p[1] ** 2) - A)
        return ((t - lt) % (2 * pi) + lt, (s - ls) % (2 * pi) + ls)
    return f
TOR = [(win(lt, ls), tor) for lt in (-pi, 0.0) for ls in (-pi, 0.0)]
spr = tor((radians(200), radians(300)))
print(f"doughnut: a = {A:.1f} cm, b = {B:.1f} cm; sprinkle at theta 200 deg, psi 300 deg")
print("sprinkle in windows (-pi,pi)^2 and (0,2pi)^2, deg: " +
      "; ".join("({:.1f}, {:.1f})".format(*map(degrees, TOR[k][0](spr))) for k in (0, 3)))
dT = det2(lambda u: TOR[3][0](tor(u)), TOR[0][0](spr))
print(f"det of change, closed form 1; differences: {dT:.6f}")
TS = [tor((radians(a), radians(b))) for a, b in ((200, 300), (30, 60), (120, 210), (290, 100))]
# The one-sided sheet: lines through the Earth's centre, gnomonic charts tangent at three points
mz = (lambda p: (R * p[0] / p[2], R * p[1] / p[2]), lambda u: (u[0], u[1], R))
mx = (lambda p: (R * p[1] / p[0], R * p[2] / p[0]), lambda u: (R, u[0], u[1]))
my = (lambda p: (R * p[0] / p[1], R * p[2] / p[1]), lambda u: (u[0], R, u[1]))
RP = [mz, mx, my]
anti = tuple(-c for c in LON)
print(f"gnomonic sheet at the North Pole: London {f2(mz[0](LON))}, its antipode {f2(mz[0](anti))} km")
for name, p in zip(CITY, PTS):
    U, V = mz[0](p)
    print(f"{name}: sheet at pole {f2((U, V))}, at 0E {f2(mx[0](p))}; formula (RV/U, R^2/U) {f2((R * V / U, R * R / U))};"
          f" det R^3/U^3 {(R / U) ** 3:.4f}, differences {det2(lambda u: mx[0](mz[1](u)), (U, V)):.4f}")
# Clockwise: count mirror choices that make every change of chart keep it
nS, nT, nP = orientations(SPH, PTS), orientations(TOR, TS), orientations(RP, PTS)
print(f"mirror choices keeping clockwise: globe {nS} of 4, doughnut {nT} of 16, one-sided sheet {nP} of 8")
# Euler characteristic, counted on glued meshes
E3 = [tuple(s * (i == k) for k in range(3)) for i in range(3) for s in (1, -1)]
oV = set(E3)
oE = {frozenset((v, w)) for v in E3 for w in E3 if sum(a * b for a, b in zip(v, w)) == 0}
oF = {frozenset(((x, 0, 0), (0, y, 0), (0, 0, z))) for x, y, z in product((1, -1), repeat=3)}
neg = lambda v: tuple(-c for c in v)
glue = lambda S, f: {frozenset((x, f(x))) for x in S}
negset = lambda s: frozenset(neg(v) for v in s)
chi = lambda V, E, F: len(V) - len(E) + len(F)
def grid(n, glued):
    w = (lambda i: i % n) if glued else (lambda i: i)
    sq = [[(w(i + a), w(j + b)) for a, b in ((0, 0), (1, 0), (1, 1), (0, 1))] for i in range(n) for j in range(n)]
    V = {c for s in sq for c in s}
    E = {frozenset((s[k], s[(k + 1) % 4])) for s in sq for k in range(4)}
    return V, E, {frozenset(s) for s in sq}
cS, cP = chi(oV, oE, oF), chi(glue(oV, neg), glue(oE, negset), glue(oF, negset))
cT, cQ = chi(*grid(4, True)), chi(*grid(4, False))
print(f"Euler count V - E + F: octahedron {len(oV)} - {len(oE)} + {len(oF)} = {cS}; "
      f"glued opposite: {len(glue(oV, neg))} - {len(glue(oE, negset))} + {len(glue(oF, negset))} = {cP}")
print(f"Euler count: 4 x 4 grid glued {cT}; same grid unglued {cQ}")
# Euler characteristic again, from curvature: K from E, F, G, L, M, N by differences, then sum K dA
def Kint(r, s0, s1, t0, t1, n, h=1e-4):
    tot, ds, dt = 0.0, (s1 - s0) / n, (t1 - t0) / n
    for i, j in product(range(n), repeat=2):
        s, t = s0 + (i + 0.5) * ds, t0 + (j + 0.5) * dt
        q = lambda a, b: r((s + a * h, t + b * h))
        c, rs, rt = q(0, 0), [(x - y) / (2 * h) for x, y in zip(q(1, 0), q(-1, 0))], [(x - y) / (2 * h) for x, y in zip(q(0, 1), q(0, -1))]
        rss = [(x - 2 * y + z) / h / h for x, y, z in zip(q(1, 0), c, q(-1, 0))]
        rtt = [(x - 2 * y + z) / h / h for x, y, z in zip(q(0, 1), c, q(0, -1))]
        rst = [(w - x - y + z) / (4 * h * h) for w, x, y, z in zip(q(1, 1), q(1, -1), q(-1, 1), q(-1, -1))]
        nv = (rs[1] * rt[2] - rs[2] * rt[1], rs[2] * rt[0] - rs[0] * rt[2], rs[0] * rt[1] - rs[1] * rt[0])
        dA = sqrt(sum(x * x for x in nv))
        d = lambda u, v: sum(x * y for x, y in zip(u, v))
        L, M, N = (d(x, nv) / dA for x in (rss, rst, rtt))
        tot += (L * N - M * M) / (d(rs, rs) * d(rt, rt) - d(rs, rt) ** 2) * dA * ds * dt
    return tot, (L * N - M * M) / dA ** 2
glb = lambda u: (R * sin(u[0]) * cos(u[1]), R * sin(u[0]) * sin(u[1]), R * cos(u[0]))
gS, gS50, gP = Kint(glb, 0, pi, 0, 2 * pi, 100)[0], Kint(glb, 0, pi, 0, 2 * pi, 50)[0], Kint(glb, 0, pi / 2, 0, 2 * pi, 100)[0]
gT, gO, gI = (Kint(tor, -pi, pi, a, b, 100)[0] for a, b in ((-pi, pi), (-pi / 2, pi / 2), (pi / 2, 3 * pi / 2)))
kO, kI = Kint(tor, -1e-3, 1e-3, -1e-3, 1e-3, 1)[1], Kint(tor, -1e-3, 1e-3, pi - 1e-3, pi + 1e-3, 1)[1]
print(f"doughnut K: outer equator {kO:.6f} (closed form {1/(B*(A+B)):.6f}), inner {kI:.6f} ({-1/(B*(A-B)):.6f}) per cm^2")
z6 = lambda x: round(x, 6) + 0.0          # prints -0.000000 as 0.000000
print(f"integral of K dA / 2pi: globe {gS / (2*pi):.6f}, doughnut {z6(gT / (2*pi)):.6f}, one-sided sheet {gP / (2*pi):.6f}")
print(f"doughnut: outer half {gO:.6f}, inner half {gI:.6f}, 4pi = {4*pi:.6f}; globe error 50 steps {abs(gS50 - 4*pi):.6f}, 100 steps {abs(gS - 4*pi):.6f}")
# What breaks: a flat sheet asked to keep the octant triangle exact
tri = [sph(90, 0), sph(0, 0), sph(0, 90)]
def ang(a, b, c):                      # angle at a between great-circle arcs to b and c
    tb, tc = ([y - sum(p * q for p, q in zip(a, x)) / R / R * z for y, z in zip(x, a)] for x in (b, c))
    return acos(sum(p * q for p, q in zip(tb, tc)) / sqrt(sum(p * p for p in tb) * sum(q * q for q in tc)))
tot = sum(ang(tri[k], tri[(k + 1) % 3], tri[(k + 2) % 3]) for k in range(3))
print(f"octant triangle: angles add to {degrees(tot):.4f} deg (a flat sheet gives 180); "
      f"excess x R^2 = {(tot - pi) * R * R:.0f} km^2, one eighth of 4 pi R^2 = {pi * R * R / 2:.0f} km^2")
print(f"figure, 100 units = R; N (120, 30), S (120, 230), London ({120 + 100 * sin(radians(38.4926)):.2f}, {130 - 100 * cos(radians(38.4926)):.2f}),"
      f" u_N ({120 + 100 * uN[0] / R:.2f}, 130), u_S ({120 + 100 * uS[0] / R:.2f}, 130)")
assert all(abs(x - y) < 1e-6 for x, y in zip(T, uS))          # change of chart: formula = chart of inverse
assert abs(dF - dS) < 1e-6 and abs(dT - 1) < 1e-6              # determinants: closed form = differences
assert all(abs(x - y - 2 * pi) < 1e-12 for x, y in zip(TOR[3][0](spr), TOR[0][0](spr)))   # torus: a shift by 2 pi
assert all(abs(mx[0](p)[0] - R * mz[0](p)[1] / mz[0](p)[0]) + abs(mx[0](p)[1] - R * R / mz[0](p)[0]) < 1e-6 for p in PTS)
assert (nS, nT, nP) == (2, 2, 0)                                # clockwise: kept, kept, impossible
assert (cS, cT, cP) == (round(gS / (2 * pi)), round(gT / (2 * pi)), round(gP / (2 * pi))) == (2, 0, 1)
assert abs(kO - 1 / (B * (A + B))) < 1e-5 and abs(kI + 1 / (B * (A - B))) < 1e-5
assert abs((tot - pi) * R * R - pi * R * R / 2) < 1e-3 * R * R
print("ALL CHECKS PASS")
