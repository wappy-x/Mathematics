# Change of variables -- the check behind the card.  Standard library only.  Rain on a
# fan: radius 3 km, opening 60 degrees, 20 + 10 r mm deep at r km from the outlet.  Road 1:
# polar, with the factor r.  Road 2: an x-y grid that never mentions r.  Then the Jacobians.
import math
PI, R = math.pi, 3.0
TH, DEG = PI / 3, PI / 180                    # the fan's opening, and one degree, in radians
def simpson(f, a, b, n=100):                  # Simpson's rule on n (even) strips
    h, s = (b - a) / n, f(a) + f(b)
    for k in range(1, n):
        s += (4 if k % 2 else 2) * f(a + k * h)
    return s * h / 3
def grid(n):                                  # road 2: n x n midpoint cells on the square 0..3 km
    h, s = R / n, 0.0
    for i in range(n):
        for j in range(n):
            x, y = (i + 0.5) * h, (j + 0.5) * h
            if x * x + y * y <= R * R and y <= math.sqrt(3) * x:
                s += depth(math.sqrt(x * x + y * y))
    return s * h * h
def jac(T, p, h=1e-6):                        # matrix of rates, one central difference per input
    cols = [[(u - v) / (2 * h) for u, v in zip(T(*(p[:k] + [p[k] + h] + p[k+1:])), T(*(p[:k] + [p[k] - h] + p[k+1:])))] for k in range(len(p))]
    return [[cols[j][i] for j in range(len(p))] for i in range(len(p))]
def patch(r1, r2, t1, t2, m=400):             # a fan patch's area, as a polygon hugging both arcs
    pts = [pol(r2, t1 + (t2 - t1) * k / m) for k in range(m + 1)] + [pol(r1, t2 - (t2 - t1) * k / m) for k in range(m + 1)]
    s = 0.0
    for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]):
        s += x1 * y2 - x2 * y1
    return s / 2
depth = lambda r: 20 + 10 * r                 # mm of rain at r km from the outlet
pol = lambda r, t: (r * math.cos(t), r * math.sin(t))
sph = lambda p, f, t: (p * math.sin(f) * math.cos(t), p * math.sin(f) * math.sin(t), p * math.cos(f))
det2 = lambda m: m[0][0] * m[1][1] - m[0][1] * m[1][0]
det3 = lambda m: sum(m[0][j] * (m[1][(j + 1) % 3] * m[2][(j + 2) % 3] - m[1][(j + 2) % 3] * m[2][(j + 1) % 3]) for j in range(3))
exact = 60 * PI                               # by hand: (pi/3) x (90 + 90)
polar = simpson(lambda t: simpson(lambda r: depth(r) * r, 0, R), 0, TH)
print(f"road 1, polar with factor r: {polar:.6f} mm km2; by hand (pi/3) x (90 + 90) = {exact:.6f}")
for n in (100, 400, 1600):
    g = grid(n)
    print(f"road 2, x-y grid {n:4}: {g:.6f} mm km2, error {g - exact:+.6f}")
area = TH * simpson(lambda r: r, 0, R)
print(f"area {area:.6f} km2; mean depth {polar / area:.6f} mm; water {polar * 1000:.0f} m3")
dp, ds = det2(jac(pol, [2.25, 25 * DEG])), det3(jac(sph, [2.0, 60 * DEG, 0.7]))
print(f"Jacobian by difference quotients: polar at r 2.25 {dp:.6f}; spherical at rho 2, phi 60 deg {ds:.6f} (rho^2 sin phi {4 * math.sin(60 * DEG):.6f})")
areas = [patch(r1, r1 + 0.5, 20 * DEG, 30 * DEG) for r1 in (0.5, 2.0)]
for r1, a in zip((0.5, 2.0), areas):
    print(f"patch r {r1:.1f}..{r1 + 0.5:.1f} km, 20..30 deg: polygon {a:.6f} km2; r dr dtheta {(r1 + 0.25) * 0.5 * 10 * DEG:.6f}")
drop = 2 * PI * simpson(lambda p: p * p, 0, 2) * simpson(math.sin, 0, PI)
print(f"raindrop radius 2 mm: {drop:.6f} mm3; 4/3 pi 2^3 = {32 * PI / 3:.6f}; sin phi dropped {2 * PI * PI * 8 / 3:.6f}")
per_m = 2 * PI * simpson(lambda r: r, 0, 100)
print(f"round tank radius 100 m: {per_m:.3f} m3 per metre (theta run twice round: {2 * per_m:.3f}); the storm fills it to {polar * 1000 / per_m:.6f} m")
print(f"mistakes: r dropped {TH * simpson(depth, 0, R):.6f}; rim-outlet average x area {35 * area:.6f}; degrees {60 * simpson(lambda r: depth(r) * r, 0, R):.6f}")
px = lambda r, t: f"({40 + 60 * r * math.cos(t):.2f}, {215 - 60 * r * math.sin(t):.2f})"
print(f"figure, 60 px per km, outlet (40, 215), rim ends {px(3, 0)} {px(3, TH)}")
for r1 in (0.5, 2.0):
    print(f"figure, patch r {r1:.1f}..{r1 + 0.5:.1f}:", " ".join(px(r, t * DEG) for r, t in ((r1, 20), (r1 + 0.5, 20), (r1 + 0.5, 30), (r1, 30))))
assert abs(polar - exact) < 1e-9                                  # polar Simpson meets the hand answer
assert abs(g - exact) < 0.05                                      # the grid, blind to r, closes on it
assert abs(dp - 2.25) < 1e-6 and abs(ds - 4 * math.sin(60 * DEG)) < 1e-6
assert abs(areas[1] - 2.25 * 0.5 * 10 * DEG) < 1e-6 and abs(drop - 32 * PI / 3) < 1e-6
print("ALL CHECKS PASS")
