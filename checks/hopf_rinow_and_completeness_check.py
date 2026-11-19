# Hopf-Rinow and where shortest routes end -- the check behind the card.
# Nothing is imported except math.  The Earth is a sphere of radius 6371 km.
# Points are unit vectors; a flight along heading h is a great circle.
# Roads: closed-form great circles against an RK4-stepped geodesic, the
# proof's "shoot through the nearest point" search against the bearing
# formula, and closed-form distances against distances measured point to point.
import math
R = 6371.0
D = math.pi / 180

def pos(phi, th):                      # phi down from the North Pole, th east
    return (math.sin(phi * D) * math.cos(th * D), math.sin(phi * D) * math.sin(th * D), math.cos(phi * D))
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def dist(a, b):                        # surface distance in km, accurate near antipodes
    c = cross(a, b)
    return R * math.atan2(math.sqrt(dot(c, c)), dot(a, b))
def start(phi, th, h):                 # position and unit direction for heading h deg
    north = (-math.cos(phi * D) * math.cos(th * D), -math.cos(phi * D) * math.sin(th * D), math.sin(phi * D))
    east = (-math.sin(th * D), math.cos(th * D), 0.0)
    return pos(phi, th), [math.cos(h * D) * north[i] + math.sin(h * D) * east[i] for i in range(3)]
def fly(phi, th, h, t):                # road one, closed form: a great circle, t km along
    p, u = start(phi, th, h)
    return tuple(math.cos(t / R) * p[i] + math.sin(t / R) * u[i] for i in range(3))
def rk4(phi, th, h, t, n):             # road two: step x'' = -|x'|^2 x / |x|^2 in km
    p, v = start(phi, th, h)
    x = [R * c for c in p]
    def acc(x, v): k = -sum(c * c for c in v) / sum(c * c for c in x); return [k * c for c in x]
    dt = t / n
    for _ in range(n):
        a1 = acc(x, v)
        x2 = [x[i] + dt / 2 * v[i] for i in range(3)]; v2 = [v[i] + dt / 2 * a1[i] for i in range(3)]; a2 = acc(x2, v2)
        x3 = [x[i] + dt / 2 * v2[i] for i in range(3)]; v3 = [v[i] + dt / 2 * a2[i] for i in range(3)]; a3 = acc(x3, v3)
        x4 = [x[i] + dt * v3[i] for i in range(3)]; v4 = [v[i] + dt * a3[i] for i in range(3)]; a4 = acc(x4, v4)
        x = [x[i] + dt / 6 * (v[i] + 2 * v2[i] + 2 * v3[i] + v4[i]) for i in range(3)]
        v = [v[i] + dt / 6 * (a1[i] + 2 * a2[i] + 2 * a3[i] + a4[i]) for i in range(3)]
    return x

LON = (90 - 51.5074, -0.1278)          # London
SYD = (90 + 33.8688, 151.2093)         # Sydney
ANT = (180 - LON[0], LON[1] + 180)     # London's antipode
HALF = math.pi * R
print(f"globe: R = {R:.0f} km, half a great circle pi R = {HALF:.2f} km, full circle {2 * HALF:.2f} km")
print(f"London's antipode: latitude {90 - ANT[0]:.4f}, longitude {ANT[1]:.4f}")
heads = [0, 45, 90, 135, 180, 225, 270, 315]
print("eight headings from London, each flown pi R km: miss from the antipode (km)")
ties = [dist(fly(*LON, h, HALF), pos(*ANT)) for h in heads]
print("  closed form: " + " ".join(f"{m:.6f}" for m in ties))
err = {}
for n in (100, 200):
    err[n] = [dist([c / R for c in rk4(*LON, h, HALF, n)], pos(*ANT)) * 1000 for h in heads]
    print(f"  RK4, {n} steps of {HALF / n:.2f} km, miss in metres: " + " ".join(f"{e:.4f}" for e in err[n]))
print(f"  error ratio, 100 steps over 200 steps: {err[100][0] / err[200][0]:.2f} (RK4 predicts 16)")

dpq = dist(pos(*LON), pos(*SYD))       # Hopf-Rinow: shoot through the nearest point
DEL = 500.0
f = lambda h: dist(fly(*LON, h, DEL), pos(*SYD))
h0 = min(range(360), key=f)
lo, hi = h0 - 1.0, h0 + 1.0
for _ in range(80):                    # golden-section search on the heading
    m1, m2 = hi - 0.618033988749895 * (hi - lo), lo + 0.618033988749895 * (hi - lo)
    lo, hi = (lo, m2) if f(m1) < f(m2) else (m1, hi)
hb = (lo + hi) / 2
p1, p2, dl = (90 - LON[0]) * D, (90 - SYD[0]) * D, (SYD[1] - LON[1]) * D   # latitudes, longitude gap
bear = math.atan2(math.sin(dl) * math.cos(p2), math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)) / D
print(f"London to Sydney: distance {dpq:.2f} km")
print(f"  nearest point to Sydney on the {DEL:.0f} km circle: heading {hb:.6f}, bearing formula {bear % 360:.6f}")
print(f"  {DEL:.0f} + distance from that point = {DEL + f(hb):.2f} km")
print(f"  fly that heading {dpq:.2f} km: lands {dist(fly(*LON, hb, dpq), pos(*SYD)):.6f} km from Sydney")
g = [dist(fly(*LON, h, DEL), pos(*ANT)) for h in range(360)]
print(f"  same search aimed at the antipode: every heading gives {min(g):.2f} km, spread {max(g) - min(g):.6f} km")

print("fly east from London: km flown, distance home (measured), R arccos(cos(t/R))")
chart = []
for t in [2500 * k for k in range(17)] + [HALF]:
    meas = dist(pos(*LON), fly(*LON, 90, t))
    chart.append(meas)
    print(f"  {t:9.2f} {meas:9.2f} {R * math.acos(math.cos(t / R)):9.2f}")
print("chart, distance home: " + ", ".join(f"{c:.0f}" for c in chart[:17]))

MIR = (LON[0], LON[1] + 180)           # London's mirror across the North Pole
dm = dist(pos(*LON), pos(*MIR))
print(f"London to its mirror over the pole: {dm:.2f} km, by the pole; 2 x {LON[0]:.4f} deg x R = {2 * LON[0] * D * R:.2f}")
print("globe with the pole removed: detour through a point delta from the pole")
det = []
for dd in (1.0, 0.1, 0.01):
    w = pos(dd, LON[1] + 90)
    det.append((2 * dist(pos(*LON), w), 2 * R * math.acos(math.cos(LON[0] * D) * math.cos(dd * D))))
    print(f"  delta {dd:4.2f} deg = {dd * D * R:6.2f} km: route {det[-1][0]:.4f} km, Pythagoras {det[-1][1]:.4f} km, extra {det[-1][0] - dm:.4f} km")
print(f"  flying due north, the route leaves the punctured globe after {LON[0] * D * R:.2f} km")

A = 1.0                                # two headings 1 degree apart: Jacobi field size
print("headings 90 and 91 from London: gap (km), Jacobi alpha R sin(t/R), flat alpha t, hyperbolic alpha R sinh(t/R)")
gaps = []
for t in (5000.0, HALF / 2, 15000.0, HALF):
    gap = dist(fly(*LON, 90, t), fly(*LON, 90 + A, t))
    gaps.append(gap)
    print(f"  t {t:8.2f}: {gap:7.2f} {A * D * R * math.sin(t / R):7.2f} {A * D * t:7.2f} {A * D * R * math.sinh(t / R):8.2f}")
C = 2 * HALF                           # flat cylinder with the equator's length, built in 3D
RC = C / (2 * math.pi)                 # its radius, km
def cpt(e, n): return (RC * math.cos(e / RC), RC * math.sin(e / RC), n)   # unrolled (east, north) -> 3D point
def cdist(a, b):                       # on the surface: shorter arc round the axis, then Pythagoras with the height
    arc = RC * math.atan2(a[0] * b[1] - a[1] * b[0], a[0] * b[0] + a[1] * b[1])
    return math.sqrt(arc * arc + (a[2] - b[2]) * (a[2] - b[2]))
print(f"flat cylinder in 3D, circumference {C:.2f} km, radius {RC:.2f} km: distance home, the two ways round, gap to heading 91")
cyl = []
for t in (10000.0, HALF, 30000.0):
    p = cpt(t, 0.0)
    east = RC * (math.atan2(p[1], p[0]) % (2 * math.pi))   # the way round going east, read from the 3D point
    home, gap = cdist(cpt(0.0, 0.0), p), cdist(p, cpt(t * math.sin((90 + A) * D), t * math.cos((90 + A) * D)))
    cyl.append((t, home, east, C - east, gap))
    print(f"  flown {t:8.2f}: home {home:8.2f}, min(t, C - t) {min(t, C - t):8.2f}; east {east:8.2f}, west {C - east:8.2f}, "
          f"tied: {'yes' if abs(east - (C - east)) < 1e-6 else 'no'}; gap {gap:6.2f}, alpha t {A * D * t:6.2f}")
print(f"what breaks: fly 22000.00 km east, distance home {dist(pos(*LON), fly(*LON, 90, 22000.0)):.2f} km")
print("figure, centre (210, 200), radius 160 px; London (210, 40), antipode (210, 360); route half-widths px: "
      + " ".join(f"{abs(160 * math.cos((h + 20) * D)):.1f}" for h in heads[:4]))   # orthographic view

assert max(ties) < 1e-6                                       # every heading ties at the antipode
assert all(e < 50 for e in err[100]) and 14 < err[100][0] / err[200][0] < 18   # RK4 is fourth order
assert abs(DEL + f(hb) - dpq) < 1e-6 and abs(hb - bear % 360) < 1e-5          # shooting = bearing formula
assert dist(fly(*LON, hb, dpq), pos(*SYD)) < 1e-3                             # the shot lands on Sydney
assert max(g) - min(g) < 1e-6                                                  # no best heading at the antipode
assert all(abs(c - min(t, 2 * HALF - t)) < 1e-6 for c, t in zip(chart, [2500 * k for k in range(17)] + [HALF]))
assert all(a > dm and abs(a - b) < 1e-6 for a, b in det) and det[0][0] > det[1][0] > det[2][0]
assert abs(gaps[1] - A * D * R) < 1e-6 and gaps[3] < 1e-6                     # neighbours refocus at pi R
assert all(abs(h - min(t, C - t)) < 1e-6 for t, h, e, w, g in cyl)                  # measured on the surface = min(t, C - t)
assert [abs(e - w) < 1e-6 for t, h, e, w, g in cyl] == [False, True, False]          # the two ways round tie only at pi R
assert all(abs(g - A * D * t) < 1e-4 * A * D * t for t, h, e, w, g in cyl)           # flat: neighbours spread as alpha t
print("ALL CHECKS PASS")
