# Pullback and change of variables -- the check behind the card.  Standard library only.
# A rain map on the east-north grid is pulled back to a radar's (range, azimuth) grid.
# Roads: the pullback built by wedging pulled-back 1-forms (finite differences), the
# closed form -r, the signed (shoelace) area of a mapped cell, a two-stage pullback
# through a raster grid, and a plain cell count on the map that uses no pullback at all.
from math import sin, cos, sqrt, pi, radians

def rain(x, y):                 # rain depth, mm, at x km east and y km north of the radar
    return 20.0 + 10.0 * sqrt(x * x + y * y)

def radar(r, a):                # radar address -> map place; azimuth a clockwise from north
    return (r * sin(a), r * cos(a))

def raster_to_map(c, k):        # raster column c (east), row k counted south from y = 3 km
    return (0.25 * c, 3.0 - 0.25 * k)

def radar_to_raster(r, a):      # the two re-griddings in a row: radar address -> raster cell
    x, y = radar(r, a)
    return (4.0 * x, 4.0 * (3.0 - y))

def wedge(p, q):                # (p1 du + p2 dv) ^ (q1 du + q2 dv) = (p1 q2 - p2 q1) du ^ dv
    return p[0] * q[1] - p[1] * q[0]

def pull(F, u, v):              # F*(dx ^ dy) at (u, v): pull dx and dy back, then wedge them
    return wedge(pull_1form(F, u, v, 0), pull_1form(F, u, v, 1))

def pull_1form(F, u, v, i, h=1e-5):     # F*dx (i = 0) or F*dy (i = 1): its du and dv parts
    return ((F(u + h, v)[i] - F(u - h, v)[i]) / (2 * h), (F(u, v + h)[i] - F(u, v - h)[i]) / (2 * h))

def shoelace(pts):              # signed area of a polygon: positive anticlockwise
    return 0.5 * sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
                     for i in range(len(pts)))

def simpson2(g, a0, a1, b0, b1, n=60):    # double Simpson's rule, n even
    ha, hb = (a1 - a0) / n, (b1 - b0) / n
    w = lambda i: 1 if i in (0, n) else (4 if i % 2 else 2)
    return sum(w(i) * w(j) * g(a0 + i * ha, b0 + j * hb)
               for i in range(n + 1) for j in range(n + 1)) * ha * hb / 9.0

def cell_count(h):              # road with no pullback: add rain x cell area over map cells in the valley
    tot, m = 0.0, int(round(3.0 / h))
    for i in range(m):
        for j in range(m):
            x, y = (i + 0.5) * h, (j + 0.5) * h
            if x * x + y * y <= 9.0 and 2.0 * x >= sqrt(x * x + y * y):
                tot += rain(x, y) * h * h
    return tot

r0, a0 = 2.25, radians(65.0)             # centre of the marked radar cell
f0 = rain(*radar(r0, a0))
det_fd, det_cf = pull(radar, r0, a0), -r0
dr, da = 1e-4, 1e-4
tiny = [radar(r0, a0), radar(r0 + dr, a0), radar(r0 + dr, a0 + da), radar(r0, a0 + da)]
det_sh = shoelace(tiny) / (dr * da)
px, py = [pull_1form(radar, r0, a0, i) for i in (0, 1)]
coef = f0 * det_fd                        # radar-grid coefficient of the pulled-back rain form
k0 = radar_to_raster(r0, a0)
det_G = pull(raster_to_map, *k0)                                      # raster cell -> map place
coef_raster = rain(*raster_to_map(*k0)) * det_G                       # rain form in raster cells
coef_two = coef_raster * pull(radar_to_raster, r0, a0)                # then back to radar cells
cell = [radar(2.0, radians(60)), radar(2.5, radians(60)), radar(2.5, radians(70)), radar(2.0, radians(70))]
cell_rain = radians(10) * (10 * (2.5**2 - 2.0**2) + 10 / 3 * (2.5**3 - 2.0**3))

A0, A1 = radians(30), radians(90)        # the valley: bearings 030 to 090, out to 3 km
g = lambda r, a: rain(*radar(r, a)) * pull(radar, r, a)
I_pull = simpson2(g, 0.0, 3.0, A0, A1)   # integral of the pullback in the order (r, a)
I_closed = -(A1 - A0) * (10 * 9 + 10 / 3 * 27)
total = -I_pull                          # the radar grid is left-handed: flip once
c1, c2 = cell_count(0.05), cell_count(0.025)

no_d = (A1 - A0) * (20 * 3 + 5 * 9)                       # f only, differentials dropped
comm = 180.0 * (sin(2 * A1) - sin(2 * A0)) / 2            # dr^da treated like da^dr: r cos 2a
degs = (90 - 30) * 180.0                                  # azimuth in degrees
twice = -simpson2(g, 0.0, 3.0, 0.0, 4 * pi)               # two sweeps of the whole disc
disc = 2 * pi * 180.0

rows = [("rain at cell centre, mm", f0), ("pulled-back dx: dr part", px[0]), ("pulled-back dx: da part", px[1]),
        ("pulled-back dy: dr part", py[0]), ("pulled-back dy: da part", py[1]), ("det by wedging pulled-back dx, dy", det_fd),
        ("det closed form, -r", det_cf), ("det from shoelace of a tiny cell", det_sh),
        ("rain form coefficient on radar grid", coef), ("  via raster cells, two stages", coef_two),
        ("  raster-grid coefficient", coef_raster), ("  det radar -> raster", pull(radar_to_raster, r0, a0)),
        ("  det raster -> map", det_G), ("  bars: |det| x |det|", abs(det_G) * abs(pull(radar_to_raster, r0, a0))),
        ("marked cell: shoelace of corners", shoelace(cell)), ("marked cell: exact area, km2", radians(10) * 1.125),
        ("marked cell: rain, mm km2", cell_rain),
        ("range part: integral of (20 + 10r) r dr", 10 * 9 + 10 / 3 * 27), ("integral of pullback, Simpson", I_pull), ("integral of pullback, closed form", I_closed),
        ("valley total, mm km2", total), ("valley total, cubic metres", total * 1000),
        ("cell count on map, 0.05 km", c1), ("cell count on map, 0.025 km", c2),
        ("wrong: differentials dropped", no_d), ("wrong: wedge treated as commuting", comm),
        ("wrong: sign not flipped", I_pull), ("wrong: azimuth in degrees", degs),
        ("fails: azimuth swept twice", twice), ("  true rain on the 3 km disc", disc),
        ("try: azimuth anticlockwise from east, det", pull(lambda r, t: (r * cos(t), r * sin(t)), r0, radians(25))),
        ("try: raster rows counted north, det", pull(lambda c, k: (0.25 * c, 0.25 * k), 1.0, 1.0)),
        ("try: valley area, km2", (A1 - A0) * 4.5), ("try: uniform 40 mm, mm km2", 40 * (A1 - A0) * 4.5)]
for name, v in rows:
    print(f"{name:<42}{v:>16.6f}")
print("figure," + ",".join(f"{p[0]:.4f} {p[1]:.4f}" for p in cell))

assert abs(det_fd - det_cf) < 1e-6                 # wedging pulled-back 1-forms gives -r
assert abs(det_sh - det_cf) < 1e-3                 # so does the signed area of a mapped cell
assert abs(coef_two - coef) < 1e-6                 # two-stage pullback agrees with one stage
assert abs(I_pull - I_closed) < 1e-6               # Simpson on the pullback against the closed form
assert abs(c2 - total) < 0.005 * c2                # a cell count with no pullback at all
assert shoelace(cell) < 0                          # the radar grid runs clockwise on the map
assert pull(radar_to_raster, r0, a0) > 0           # two reversals in a row preserve orientation
assert abs(abs(det_G) * abs(pull(radar_to_raster, r0, a0)) - abs(det_fd)) < 1e-6   # bars compose too, minus the sign
assert abs(twice - 2 * disc) < 1e-6                # two sweeps count every place twice
assert abs(no_d - total) > 50                      # the dropped differentials are a real error
print("ALL CHECKS PASS")
