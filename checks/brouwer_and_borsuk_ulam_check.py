# Brouwer and Borsuk-Ulam -- the check behind the card.  Standard library only.
# A stir of a coffee cup of radius 4 cm.  Roads: winding numbers and a hunt by cells, against Newton's
# method and a one-variable bisection; a cut that halves two slices, by bisection against a grid count.
from math import atan2, cos, sin, sqrt, pi, dist, hypot
R, A = 4.0, 0.3  # cup radius in cm; how far the slosh pushes the middle, as a share of R

def stir(x, y):  # twist each ring by 1.5 - 0.3 s^2 radians (s = r/R), then slosh east
    s2 = (x * x + y * y) / (R * R); t = 1.5 - 0.3 * s2
    u, v = (x * cos(t) - y * sin(t)) / R, (x * sin(t) + y * cos(t)) / R
    d = (1 + A * u) * (1 + A * u) + A * v * A * v  # the slosh (u + A) / (1 + A u), u + iv complex
    nu, nv = (u + A) * (1 + A * u) + v * A * v, v * (1 + A * u) - (u + A) * A * v
    return R * nu / d, R * nv / d

def disp(x, y):  # where a point goes minus where it was; outside the cup, use the rim point
    r = sqrt(x * x + y * y)
    if r > R: x, y = x * R / r, y * R / r
    fx, fy = stir(x, y); return fx - x, fy - y

def winding(g, pts):  # net turns of g along a closed path: the lift of card 04, step by step
    tot, (px, py) = 0.0, g(*pts[-1])
    for p in pts:
        qx, qy = g(*p); tot += atan2(px * qy - py * qx, px * qx + py * qy); px, py = qx, qy
    return round(tot / (2 * pi))

def circle(r, n=720): return [(r * cos(2 * pi * k / n), r * sin(2 * pi * k / n)) for k in range(n)]
def square(x0, y0, h, n=32):
    sides = [(x0 + h * k / n, y0) for k in range(n)] + [(x0 + h, y0 + h * k / n) for k in range(n)]
    return sides + [(x0 + h - h * k / n, y0 + h) for k in range(n)] + [(x0, y0 + h - h * k / n) for k in range(n)]

def hunt(g, x0, y0, h, levels=40):  # keep a quarter whose rim still winds; it shrinks onto a zero
    for _ in range(levels):
        h /= 2
        x0, y0 = next((a, b) for a in (x0, x0 + h) for b in (y0, y0 + h) if winding(g, square(a, b, h)) != 0)
    return x0 + h / 2, y0 + h / 2

def newton(g, x, y, steps=30, e=1e-6):
    for _ in range(steps):
        gx, gy = g(x, y); ax, ay = g(x + e, y); bx, by = g(x, y + e)
        a, b, c, d = (ax - gx) / e, (bx - gx) / e, (ay - gy) / e, (by - gy) / e; det = a * d - b * c
        x, y = x - (d * gx - b * gy) / det, y - (a * gy - c * gx) / det
    return x, y

def bisect(g, lo, hi):  # halve the bracket 60 times, keeping a sign change of g inside
    for _ in range(60): mid = (lo + hi) / 2; lo, hi = (mid, hi) if g(lo) * g(mid) > 0 else (lo, mid)
    return lo

w_rim = winding(disp, circle(R)); print(f"stir: winding of the displacement round the rim r = 4 cm: {w_rim}")
assert w_rim == 1
dirs = [disp(R * cos(k * pi / 4), R * sin(k * pi / 4)) for k in range(0, 8, 2)]
print("stir: rim points at 0, 90, 180, 270 deg move by", "; ".join(f"({a:.4f}, {b:.4f}), heading {atan2(b, a) * 180 / pi:.1f} deg" for a, b in dirs))
hd = [atan2(b, a) * 180 / pi for a, b in dirs + dirs[:1]]  # the headings round the rim, back to 0 deg
un = [hd[0] + sum((y - x + 180) % 360 - 180 for x, y in zip(hd[:k], hd[1:k + 1])) for k in range(5)]  # each step the short way
print("stir: headings unwrapped:", " -> ".join(f"{u:.1f}" for u in un), f"deg; total turn {un[4] - un[0]:.1f} deg")
print("stir: winding round circles r = 3, 2, 1, 0.9, 0.5 cm:", [winding(disp, circle(r)) for r in (3, 2, 1, 0.9, 0.5)])
cells = sum(winding(disp, square(-4 + i, -4 + j, 1)) != 0 for i in range(8) for j in range(8))
print(f"stir: 1 cm cells whose rim winds: {cells} of 64 (checked on 64 cells; proves nothing about pairs)")
px, py = hunt(disp, -4.0, -4.0, 8.0); nx, ny = newton(disp, 0.0, 0.0)
print(f"fixed point by cell hunt: ({px:.9f}, {py:.9f}) cm; by Newton from the centre: ({nx:.9f}, {ny:.9f}) cm")
fx, fy = stir(px, py); moved = sqrt((fx - px) ** 2 + (fy - py) ** 2)
print(f"it lands at ({fx:.9f}, {fy:.9f}); moved under 1e-9 cm: {moved < 1e-9}; {sqrt(px*px+py*py):.4f} cm from the centre")
assert abs(px - nx) < 1e-8 and abs(py - ny) < 1e-8 and moved < 1e-9 and abs(un[4] - un[0] - 360 * w_rim) < 1e-9
x, y, near = 0.0, 0.0, []
for n in range(1, 201):
    x, y = stir(x, y); near.append(sqrt((x - px) ** 2 + (y - py) ** 2))
    if n in (1, 2, 3, 10, 100, 200): print(f"press {n:3}: at ({x:.4f}, {y:.4f}), {near[-1]:.4f} cm from the fixed point")
print(f"presses 101 to 200: closest {min(near[100:]):.4f} cm -- pressing does not find the point")
assert min(near[100:]) > 0.1
# the proof's retraction, built from a ring stir with no fixed point: rotate a ring 2 <= r <= 4 by 30 degrees
rot = lambda x, y: (x * cos(pi / 6) - y * sin(pi / 6), x * sin(pi / 6) + y * cos(pi / 6))
def retract(x, y, f):  # follow the ray from f(x) through x out to the rim
    fx, fy = f(x, y); ux, uy = x - fx, y - fy; L = sqrt(ux * ux + uy * uy); ux, uy = ux / L, uy / L
    b = x * ux + y * uy; t = -b + sqrt(b * b + R * R - x * x - y * y); return x + t * ux, y + t * uy
ring_min = min(sqrt((rot(x, y)[0] - x) ** 2 + (rot(x, y)[1] - y) ** 2) for x, y in circle(2) + circle(3) + circle(4))
print(f"ring stir: smallest move {ring_min:.6f} cm = 2 x 2 x sin 15 deg = {4 * sin(pi / 12):.6f}; no fixed point")
rim_err = max(abs(a - x) + abs(b - y) for x, y in circle(R) for a, b in [retract(x, y, rot)])
print(f"ring stir: retraction fixes the rim to 1e-9 cm: {rim_err < 1e-9}; (3, 0) goes to "
      f"({retract(3, 0, rot)[0]:.6f}, {retract(3, 0, rot)[1]:.6f}) on the rim")
least = lambda f, pts: min(dist(p, f(*p)) for p in pts)  # what breaks: the smallest move of a map over sample points
cup, neg, z = circle(1e-9) + circle(R), lambda *p: tuple(-c for c in p), 0.0  # cup points, from almost the centre
ball = lambda r: [(r * sin(a) * cos(b), r * sin(a) * sin(b), r * cos(a)) for a in (0.5, 1.5, 2.5) for b in range(6)]
for _ in range(10): z = (z + 4) / 2  # the open cup, pressed 10 times from the centre
pour = least(lambda x, y: (-R * x / hypot(x, y), -R * y / hypot(x, y)), cup)
print(f"breaks: open cup, z -> (z + 4)/2: after 10 presses {R - z:.6f} cm from the wall, never there")
print(f"breaks: pour into another cup, z -> rim point opposite: every point moves at least {pour:.0f} cm")
print(f"breaks: spill, z -> z + 1 cm: every point moves {least(lambda x, y: (x + 1, y), cup):.0f} cm; the map leaves the cup")
print(f"breaks: sphere, p -> -p on a sphere of radius 4 cm: every point moves {least(neg, ball(R)):.0f} cm")
print(f"breaks: Borsuk-Ulam with 3 readings, g(p) = p on the unit sphere: g(p) and g(-p) always {least(neg, ball(1)):.0f} apart")
assert rim_err < 1e-9 and abs(ring_min - 4 * sin(pi / 12)) < 1e-12 and abs(R - z - R / 2 ** 10) < 1e-12
T = lambda p: 70 + 4 * cos(p) + 1.5 * cos(2 * p) + sin(3 * p)  # Borsuk-Ulam, n = 1: rim temperature, deg C, modelled
g1 = lambda p: T(p) - T(p + pi)  # = 8 cos p + 2 sin 3p
lo = bisect(g1, 0.0, pi)
flips = sum(g1(pi * k / 3600) * g1(pi * (k + 1) / 3600) < 0 for k in range(3600))
print(f"rim: g(0) = {g1(0):.1f}, g(180 deg) = {g1(pi):.1f}; equal readings at {lo * 180 / pi:.6f} deg and opposite, "
      f"{T(lo):.6f} and {T(lo + pi):.6f} deg C; sign changes on half the rim: {flips}")
assert flips % 2 == 1 and abs(T(lo) - T(lo + pi)) < 1e-9
Tp = lambda x, y, z: 15 - 25 * z * z + 6 * x + 4 * y * z * z  # Borsuk-Ulam, n = 2: modelled deg C on a unit Earth
Pp = lambda x, y, z: 1013 + 9 * y - 5 * x * z + 7 * z * z * z  # and modelled hPa
def g2(x, y):  # north half of the sphere seen from above; outside the disc, use the equator
    r = sqrt(x * x + y * y)
    if r > 1: x, y = x / r, y / r
    z = sqrt(max(0.0, 1 - x * x - y * y))
    return Tp(x, y, z) - Tp(-x, -y, -z), Pp(x, y, z) - Pp(-x, -y, -z)
w_eq = winding(g2, circle(1)); print(f"earth: winding of the antipodal difference round the equator: {w_eq} (odd)")
ex, ey = hunt(g2, -1.0, -1.0, 2.0); ez = sqrt(1 - ex * ex - ey * ey)
def sumsq(z): x, y = 14 * z * z * z * z * z / 27, -7 * z * z * z / 9; return x * x + y * y + z * z
lo = bisect(lambda z: sumsq(z) - 1, 0.0, 1.0)  # by hand: zero needs y = -7z^3/9, x = 14z^5/27; solve sumsq(z) = 1
print(f"earth: point by cell hunt ({ex:.9f}, {ey:.9f}, {ez:.9f}); z by bisection {lo:.9f}")
print(f"earth: there {Tp(ex, ey, ez):.6f} deg C, {Pp(ex, ey, ez):.6f} hPa; opposite {Tp(-ex, -ey, -ez):.6f} deg C, {Pp(-ex, -ey, -ez):.6f} hPa")
assert w_eq % 2 == 1 and abs(ez - lo) < 1e-8 and abs(ex - 14 * lo * lo * lo * lo * lo / 27) < 1e-8
# the sandwich in the plane: one straight cut halves a square of toast and a triangle of cheese (cm)
toast, cheese = [(0, 0), (10, 0), (10, 10), (0, 10)], [(13, 2), (21, 4), (15, 11)]
def area(P): return sum(P[i][0] * P[i - 1][1] - P[i - 1][0] * P[i][1] for i in range(len(P))) / -2
def left(P, nx, ny, c):  # area of P where nx x + ny y <= c: clip the polygon, then shoelace
    out = []
    for i in range(len(P)):
        (ax, ay), (bx, by) = P[i - 1], P[i]; sa, sb = nx * ax + ny * ay - c, nx * bx + ny * by - c
        if sa * sb < 0: out.append((ax + sa / (sa - sb) * (bx - ax), ay + sa / (sa - sb) * (by - ay)))
        if sb <= 0: out.append((bx, by))
    return area(out) if len(out) > 2 else 0.0
def halve(P, nx, ny, lo=-40.0, hi=40.0):
    for _ in range(80):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if left(P, nx, ny, mid) < area(P) / 2 else (lo, mid)
    return lo
def h(th): return left(cheese, cos(th), sin(th), halve(toast, cos(th), sin(th))) - area(cheese) / 2
lo = bisect(h, 0.0, pi)
nx, ny = cos(lo), sin(lo); c = halve(toast, nx, ny)
print(f"sandwich: areas toast {area(toast):.1f}, cheese {area(cheese):.1f} cm2; h(0) = {h(0):.6f}, h(180 deg) = {h(pi):.6f}")
print(f"sandwich: cut {nx:.9f} x + {ny:.9f} y = {c:.9f}; halves {left(toast, nx, ny, c):.6f} and {left(cheese, nx, ny, c):.6f} cm2")
def share(P, step=0.02):  # independent road: count grid points inside P and on the cut's left
    xs, ys = [p[0] for p in P], [p[1] for p in P]; n = k = 0
    for i in range(int(min(xs) / step), int(max(xs) / step) + 1):
        for j in range(int(min(ys) / step), int(max(ys) / step) + 1):
            x, y = (i + 0.5) * step, (j + 0.5) * step
            if all((b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0]) >= 0 for a, b in zip(P, P[1:] + P[:1])):
                n += 1; k += nx * x + ny * y <= c
    return k / n
st, sc = share(toast), share(cheese)
print(f"sandwich: grid count, 0.02 cm spacing: toast {st:.4f}, cheese {sc:.4f} on one side; cut misses the toast's centre by under 1e-9: {abs(5 * nx + 5 * ny - c) < 1e-9}")
assert abs(st - 0.5) < 0.002 and abs(sc - 0.5) < 0.002 and abs(5 * nx + 5 * ny - c) < 1e-9
print("ALL CHECKS PASS")
