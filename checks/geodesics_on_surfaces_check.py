# Geodesics on surfaces -- the check behind the card.  Standard library only.
# Dome: part of a sphere, radius R = 60 m, rising 12 m above a rim of radius 36 m.
# Walk: from A (rim, due east of the axis) to B (rim, due north), a quarter turn apart.
# Chart: phi = angle down from the crown, theta = turn about the axis from A toward B.
from math import sin, cos, tan, atan, acos, asin, sqrt, pi, degrees, radians
R, PHI0 = 60.0, acos(0.8)                     # rim at phi0: radius 36 m, 48 m above the centre

def X(phi, th):                               # chart to space; heights from the sphere's centre
    return (R * sin(phi) * cos(th), R * sin(phi) * sin(th), R * cos(phi))
def add(a, b, k=1.0): return tuple(x + k * y for x, y in zip(a, b))
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def norm(a): return sqrt(dot(a, a))
def lift(x, y): return (x, y, sqrt(R * R - x * x - y * y))   # plan chart to space

def geo(th):                                   # road 1: closed form, great circle through A and B
    return atan(0.75 / (cos(th) + sin(th)))    # phi on the geodesic at turn th
def closed_len(): return R * acos(dot(X(PHI0, 0), X(PHI0, pi / 2)) / R ** 2)

def euler(psi, h, cross_term=True):            # road 2: geodesic equations, Euler steps of h metres
    p, t = PHI0, 0.0                           # psi = start angle from straight uphill
    dp, dt = -cos(psi) / R, sin(psi) / (R * sin(PHI0))
    s = 0.0                                    # length walked, each step measured along the sphere
    while t < pi / 2:
        ddp = sin(p) * cos(p) * dt * dt
        ddt = -2 * cos(p) / sin(p) * dp * dt if cross_term else 0.0
        p0, t0 = p, t
        p, t, dp, dt = p + h * dp, t + h * dt, dp + h * ddp, dt + h * ddt
        step = 2 * R * asin(norm(add(X(p, t), X(p0, t0), -1)) / (2 * R)); s += step
    f = (pi / 2 - t0) / (t - t0)               # interpolate to theta = 90 degrees
    return s - step + f * step, p0 + f * (p - p0)

def gc_land(psi):                              # closed form for a wrong start: the great circle leaving A at psi
    sg = atan(tan(PHI0) / cos(psi))            # angle at the centre walked to reach theta = 90 degrees
    return acos(cos(PHI0) * cos(sg) + cos(psi) * sin(PHI0) * sin(sg))

def shoot(h):                                  # find the start angle that lands on the rim at B
    lo, hi = radians(30), radians(80)
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if euler(mid, h)[1] < PHI0 else (lo, mid)
    return mid, euler(mid, h)[0]

def taut(n, sweeps):                           # road 3: a string of n pieces pulled tight on the dome
    pts = [lift(36 * (1 - k / n), 36 * k / n) for k in range(n + 1)]
    for _ in range(sweeps):
        for i in range(1, n):
            m = add(pts[i - 1], pts[i + 1])
            pts[i] = tuple(R * x / norm(m) for x in m)
    return sum(norm(add(b, a, -1)) for a, b in zip(pts, pts[1:])), pts[n // 2][2] - 48

def chord_len(curve, n=40000):
    pts = [curve(k / n) for k in range(n + 1)]
    return sum(norm(add(b, a, -1)) for a, b in zip(pts, pts[1:]))

def curv(curve, t, d=1e-4):                    # kappa_g and kappa_n of a space curve at t
    a, b, c = curve(t - d), curve(t), curve(t + d)
    v, acc = add(c, a, -1), add(add(c, b, -2), a)
    v, acc = tuple(x / (2 * d) for x in v), tuple(x / (d * d) for x in acc)
    n = tuple(x / R for x in b)                # outward unit normal of the sphere
    return dot(n, cross(v, acc)) / norm(v) ** 3, dot(n, acc) / dot(v, v)

rim = lambda t: X(PHI0, t * pi / 2)
plan = lambda t: lift(36 * (1 - t), 36 * t)
gpath = lambda t: X(geo(t * pi / 2), t * pi / 2)
L = closed_len()
c = R * sin(geo(pi / 4))                       # Clairaut constant: r sin(psi), r at the top
psi_c = asin(c / 36)
(ps1, L1), (ps2, L2) = shoot(0.5), shoot(0.05)
T16, T64 = taut(16, 400), taut(64, 6000)
kg_rim, kn_rim = curv(rim, 0.5)
kg_geo, kn_geo = curv(gpath, 0.3)
kg_pl, kn_pl = curv(plan, 0.5)
def ring(dist):                                # inhabitant's road: tape two rings dist m up and down
    C = lambda ph: 2 * pi * R * sin(ph)
    return (C(PHI0 + dist / R) - C(PHI0 - dist / R)) / (2 * dist) / C(PHI0)
nS = 200                                       # Gauss-Bonnet preview: area between rim and geodesic
area = R * R * sum((1 if k in (0, nS) else 4 if k % 2 else 2) * (cos(geo(k * pi / 2 / nS)) - 0.8)
                   for k in range(nS + 1)) * (pi / 2 / nS) / 3
alpha = pi / 2 - psi_c                         # corner angle between rim and geodesic at A and B
v0 = add(plan(1e-6), plan(-1e-6), -1)         # the plan line's start angle on the dome,
up = add(X(PHI0 - 1e-6, 0), X(PHI0 + 1e-6, 0), -1)  # measured from straight uphill
wrong_psi = acos(dot(v0, up) / (norm(v0) * norm(up)))
miss = lambda ph: R * (PHI0 - ph)              # metres uphill of B

rows = [
    ("rim radius, crown above rim, m", f"{R * sin(PHI0):.6f} {R - R * cos(PHI0):.6f}"),
    ("rim angle phi0 from the crown, deg, rad", f"{degrees(PHI0):.6f} {PHI0:.6f}"),
    ("hand: cos AOB, angle AOB rad, cot phi0", f"{dot(X(PHI0, 0), X(PHI0, pi / 2)) / R ** 2:.6f} {L / R:.6f} {cos(PHI0) / sin(PHI0):.6f}"),
    ("hand: tan, sin of phi at top; sin psi", f"{tan(geo(pi / 4)):.6f} {sin(geo(pi / 4)):.6f} {c / 36:.6f}"),
    ("1 geodesic length, closed form, m", f"{L:.6f}"),
    ("2 Euler h = 0.5 m: start angle deg, length", f"{degrees(ps1):.6f} {L1:.6f}"),
    ("  Euler h = 0.05 m: start angle deg, length", f"{degrees(ps2):.6f} {L2:.6f}"),
    ("  start angle errors, deg; ratio", f"{degrees(ps1 - psi_c):.6f} {degrees(ps2 - psi_c):.6f} {(ps1 - psi_c) / (ps2 - psi_c):.2f}"),
    ("3 taut string 16 pieces: length, top", f"{T16[0]:.6f} {T16[1]:.6f}"),
    ("  taut string 64 pieces: length, top", f"{T64[0]:.6f} {T64[1]:.6f}"),
    ("  closed-form curve taped in 40000 pieces", f"{chord_len(gpath):.6f}"),
    ("Clairaut constant c, m", f"{c:.6f}"),
    ("start angle from Clairaut, deg; tan", f"{degrees(psi_c):.6f} {tan(psi_c):.6f}"),
    ("geodesic top above rim, m", f"{R * cos(geo(pi / 4)) - 48:.6f}"),
    ("rim walk, m", f"{chord_len(rim):.6f}"),
    ("plan-straight walk, m; top above rim", f"{chord_len(plan):.6f} {plan(0.5)[2] - 48:.6f}"),
    ("plan line on the plan, m; nearest axis", f"{36 * sqrt(2):.6f} {18 * sqrt(2):.6f}"),
    ("geodesic saves vs rim, vs plan line, m", f"{chord_len(rim) - L:.6f} {chord_len(plan) - L:.6f}"),
    ("kappa_g, kappa_n on rim, 1/m", f"{kg_rim:.6f} {kn_rim:.6f}"),
    ("  1/45, -1/60, 1/36", f"{1 / 45:.6f} {-1 / 60:.6f} {1 / 36:.6f}"),
    ("  sqrt(kg^2 + kn^2) on rim", f"{sqrt(kg_rim ** 2 + kn_rim ** 2):.6f}"),
    ("  rings 1 m and 0.1 m apart, 1/m", f"{ring(1.0):.6f} {ring(0.1):.6f}"),
    ("|kappa_g|, kappa_n on geodesic, 1/m", f"{abs(kg_geo):.6f} {kn_geo:.6f}"),
    ("kappa_g, kappa_n mid plan line, 1/m", f"{kg_pl:.6f} {kn_pl:.6f}"),
    ("plan line start angle, deg", f"{degrees(wrong_psi):.4f}"),
    ("wrong: plan line start, uphill of B, m", f"{miss(gc_land(wrong_psi)):.6f}"),
    ("wrong: drop cross term, h = 0.005, 0.0005 m", f"{miss(euler(psi_c, 0.005, False)[1]):.6f} {miss(euler(psi_c, 0.0005, False)[1]):.6f}"),
    ("breaks: long way round, m", f"{2 * pi * R - L:.6f}"),
    ("rim turning, integral kappa_g ds, deg", f"{degrees(kg_rim * 18 * pi):.6f}"),
    ("corner angle at A and B; turn there, deg", f"{degrees(alpha):.6f} {180 - degrees(alpha):.6f}"),
    ("K times area, deg", f"{degrees(area / R ** 2):.6f}"),
    ("area rim to geodesic, Simpson, m^2", f"{area:.6f}"),
    ("  R^2 (2 alpha - turning), m^2", f"{R * R * (2 * alpha - kg_rim * 18 * pi):.6f}"),
    ("try: B 120 deg round: geodesic, rim, m", f"{R * acos(0.36 * cos(2 * pi / 3) + 0.64):.6f} {24 * pi:.6f}"),
    ("try: B opposite A: geodesic, rim, m", f"{2 * R * PHI0:.6f} {36 * pi:.6f}"),
    ("try: R = 100 m dome, rim kappa_g, 1/m", f"{sqrt(100 ** 2 - 36 ** 2) / (100 * 36):.6f}"),
]
for name, v in rows:
    print(f"{name:<44} {v}")
fig = [(40 + 5 * R * sin(geo(t)) * cos(t), 220 - 5 * R * sin(geo(t)) * sin(t))
       for t in (k * pi / 24 for k in range(13))]
print("figure, geodesic", " ".join(f"{x:.1f},{y:.1f}" for x, y in fig))

assert 9 < (ps1 - psi_c) / (ps2 - psi_c) < 11 and 0 < L2 - L < 1e-5, "Euler closes in: first order in h, length just over L"
assert abs(ps2 - psi_c) < radians(0.2) and abs(gc_land(psi_c) - PHI0) < 1e-12, "shooting and the great circle find Clairaut's angle"
assert 0 < L - T64[0] < (L - T16[0]) / 10, "the taut string tightens onto the geodesic"
assert abs(kg_rim - 1 / 45) < 1e-6 and abs(ring(0.1) - 1 / 45) < 1e-5, "rim turns at 1/45 per metre"
assert abs(kg_rim ** 2 + kn_rim ** 2 - 1 / 36 ** 2) < 1e-8 and abs(kn_geo + 1 / R) < 1e-6, "kappa^2 = kg^2 + kn^2"
assert abs(kg_geo) < 1e-6 < abs(kg_pl), "the geodesic does not steer; the plan line does"
assert L < chord_len(plan) < chord_len(rim), "the geodesic is the shortest of the three"
assert abs(area - R * R * (2 * alpha - kg_rim * 18 * pi)) < 1e-3, "Gauss-Bonnet preview"
print("ALL CHECKS PASS")
