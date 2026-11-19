# Isoperimetric and four-vertex theorems -- the check behind the card.
# Standard library only. Areas from closed forms, shoelace sums and exact Fourier coefficients;
# vertices counted from the curvature formula and from circles through three neighbouring points.
import math, cmath

PI = math.pi
L = 400.0                                   # metres of fencing wire
M = 4000                                    # points round each smooth curve
def f(x, d=6): return f"{x:.{d}f}"

def shoelace(V):                            # area of a polygon, corners anticlockwise
    return 0.5 * sum((V[j].conjugate() * V[(j + 1) % len(V)]).imag for j in range(len(V)))

def regular(k, side):                       # regular k-sided polygon
    R = side / (2 * math.sin(PI / k))
    return [R * cmath.exp(2j * PI * j / k) for j in range(k)]

def coeffs(V, N):                           # exact c_n, 0 < |n| <= N, polygon walked at constant speed
    sides = [V[(j + 1) % len(V)] - V[j] for j in range(len(V))]
    P = sum(abs(e) for e in sides); ts = [0.0]
    for e in sides: ts.append(ts[-1] + 2 * PI * abs(e) / P)
    c = {}
    for n in [m for m in range(-N, N + 1) if m != 0]:
        d = sum(e / abs(e) * P / (2 * PI) * (cmath.exp(-1j * n * ts[j]) - cmath.exp(-1j * n * ts[j + 1]))
                for j, e in enumerate(sides)) / (2j * PI * n)
        c[n] = d / (1j * n)                 # z' has coefficient i n c_n
    return c
def area_sum(c, N): return PI * sum(n * abs(v) ** 2 for n, v in c.items() if abs(n) <= N)
def lost_sum(c, N): return PI * sum((n * n - n) * abs(v) ** 2 for n, v in c.items() if abs(n) <= N)

def simpson(g, a, b, steps):
    h = (b - a) / steps
    return h / 3 * sum((1 if i in (0, steps) else 4 if i % 2 else 2) * g(a + i * h) for i in range(steps + 1))
def ell_len(a, b, t, steps=200):            # arc length of the ellipse from angle 0 to t
    return simpson(lambda u: math.hypot(a * math.sin(u), b * math.cos(u)), 0.0, t, steps)
def ellipse_for(ratio):                     # semi-axes (a, b), a = ratio * b, perimeter exactly L
    lo, hi = 1.0, L
    for _ in range(100):
        b = (lo + hi) / 2
        lo, hi = (lo, b) if ell_len(ratio * b, b, 2 * PI, 2000) > L else (b, hi)
    return ratio * b, b
def ell_kappa(a, b, t): return a * b / (a * a * math.sin(t) ** 2 + b * b * math.cos(t) ** 2) ** 1.5
def ell_pts(a, b): return [complex(a * math.cos(2 * PI * i / M), b * math.sin(2 * PI * i / M)) for i in range(M)]
def pol_r(p, q, w, t): return p + q * math.cos(t) + w * math.sin(2 * t)   # polar curve, r in metres
def pol_pts(p, q, w): return [pol_r(p, q, w, 2 * PI * i / M) * cmath.exp(2j * PI * i / M) for i in range(M)]
def pol_kappa(p, q, w):
    out = []
    for t in [2 * PI * i / M for i in range(M)]:
        r, r1, r2 = pol_r(p, q, w, t), -q * math.sin(t) + 2 * w * math.cos(2 * t), -q * math.cos(t) - 4 * w * math.sin(2 * t)
        out.append((r * r + 2 * r1 * r1 - r * r2) / (r * r + r1 * r1) ** 1.5)
    return out
def kappa3(z0, z1, z2):                     # signed curvature of the circle through three points
    u, v = z1 - z0, z2 - z1
    return 2 * (u.conjugate() * v).imag / (abs(u) * abs(v) * abs(z2 - z0))
def discrete(Z): return [kappa3(Z[i - 1], Z[i], Z[(i + 1) % M]) for i in range(M)]
def extremes(K): return sum(1 for i in range(len(K)) if (K[i] - K[i - 1]) * (K[(i + 1) % len(K)] - K[i]) < 0)

# 1. The circle and five other paddocks, all fenced with 400 m
r = L / (2 * PI); A_circle = L * L / (4 * PI)
print("paddock, wire length L (m)", f(L), " circle radius (m)", f(r), " circle area (m^2)", f(A_circle))
a, b = ellipse_for(2.0)
shapes = [("equilateral triangle", regular(3, L / 3)), ("2:1 rectangle", [0j, L / 3, L / 3 + L / 6 * 1j, L / 6 * 1j]),
          ("square", [0j, L / 4, L / 4 + L / 4 * 1j, L / 4 * 1j]), ("2:1 ellipse", ell_pts(a, b)), ("regular hexagon", regular(6, L / 6))]
for name, V in shapes:
    A = shoelace(V) if name != "2:1 ellipse" else PI * a * b
    if name != "2:1 ellipse":
        assert abs(area_sum(coeffs(V, 1000), 1000) - A) < 1e-6 * A, name      # Fourier area = shoelace area
    else:
        assert abs(shoelace(V) - A) < 1e-6 * A                                # 4000-gon against pi a b
    assert A < A_circle
    bar = "#" * round(A / 400)
    print(f"bars, {name:<20} {bar:<32} {f(A, 1):>9} m^2  ratio 4piA/L^2 = {f(4 * PI * A / L ** 2, 4)}")
print(f"bars, {'circle':<20} {'#' * round(A_circle / 400):<32} {f(A_circle, 1):>9} m^2  ratio 4piA/L^2 = {f(1.0, 4)}")

# 2. The square, circle by circle
sq = coeffs(shapes[2][1], 10000)
closed = lambda n: L / (2 * PI) * 2 * math.sqrt(2) / (PI * n * n)            # |c_n| for n = 1 mod 4
for n in (1, -3, 5, -7):
    assert abs(abs(sq[n]) - closed(n)) < 1e-9
    print(f"square, n = {n:>2}  |c_n| (m) {f(abs(sq[n]))}  term pi (n^2 - n)|c_n|^2 (m^2) {f(PI * (n * n - n) * abs(sq[n]) ** 2, 2)}")
assert max(abs(v) for n, v in sq.items() if n % 4 != 1) < 1e-9          # only n = 1, -3, 5, -7, ...
exact = L * L / (4 * PI) - L * L / 16                         # from the sums pi^2/8 and pi^3/32
assert abs(lost_sum(sq, 10000) + PI * closed(1) ** 2 / 20000 - exact) < 1e-3   # sum plus its 1/N tail
print("square, L/(2 pi) (m)", f(L / (2 * PI)), " area from Fourier, N = 1000 (m^2)", f(area_sum(sq, 1000)))
for N in (10, 100, 1000, 10000):
    print(f"square, lost area to the circle, sum to |n| = {N:>5} (m^2) {f(lost_sum(sq, N), 4)}  short by {f(exact - lost_sum(sq, N), 4)}")
print("square, lost area exact, L^2/(4 pi) - L^2/16 (m^2)", f(exact, 4))
assert 9 < (exact - lost_sum(sq, 100)) / (exact - lost_sum(sq, 1000)) < 11          # tail falls like 1/N

# 3. Four vertices on the 2:1 oval paddock
K = [ell_kappa(a, b, 2 * PI * i / M) for i in range(M)]
Kd = discrete(ell_pts(a, b))
assert extremes(K) == 4 and extremes(Kd) == 4
assert max(abs(K[i] - Kd[i]) for i in range(M)) < 1e-6 and abs(Kd[0] - a / b ** 2) < 1e-6
print("oval, semi-axes a, b (m)", f(a, 4), f(b, 4), " perimeter, Simpson 20 and 2000 steps (m)",
      f(ell_len(a, b, 2 * PI, 20), 4), f(ell_len(a, b, 2 * PI, 2000), 4))
print("oval, kappa max a/b^2 (1/m)", f(a / b ** 2), " radius", f(b * b / a, 3), " three-point circle", f(Kd[0]))
print("oval, kappa min b/a^2 (1/m)", f(b / a ** 2), " radius", f(a * a / b, 3), " three-point circle", f(Kd[M // 4]))
print("oval, vertices from the formula", extremes(K), " from three-point circles", extremes(Kd))
s_pts, k_pts = [], []
for j in range(17):
    lo, hi = 0.0, 2 * PI
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if ell_len(a, b, mid) < 25 * j else (lo, mid)
    s_pts.append(str(25 * j)); k_pts.append(f(1000 * ell_kappa(a, b, (lo + hi) / 2), 2))
print("chart, arc length s (m)  ", " ".join(s_pts))
print("chart, kappa (1/km)      ", " ".join(k_pts))

# 4. A lopsided egg, and the proof's identity: x and y weighted by d kappa total zero
Z, Kl = pol_pts(60, 20, 4), pol_kappa(60, 20, 4)
assert min(Kl) > 0 and extremes(Kl) == 4 and extremes(discrete(Z)) == 4
print("egg, r = 60 + 20 cos t + 4 sin 2t: vertices", extremes(Kl), " three-point", extremes(discrete(Z)),
      " kappa min, max (1/m)", f(min(Kl)), f(max(Kl)))
for part, name in ((lambda z: z.real, "x"), (lambda z: z.imag, "y")):
    tot = sum(part((Z[i] + Z[(i + 1) % M]) / 2) * (Kl[(i + 1) % M] - Kl[i]) for i in range(M))
    size = sum(abs(part(Z[i]) * (Kl[(i + 1) % M] - Kl[i])) for i in range(M))
    assert abs(tot) < 1e-6 * size
    print(f"identity, egg: sum {name} d(kappa) = {f(tot, 9)}  against sum |{name} d(kappa)| = {f(size, 6)}")

# 5. What breaks, and the experiments
semi = [L / PI * cmath.exp(1j * PI * i / M) for i in range(M + 1)]
assert abs(shoelace(semi) - L * L / (2 * PI)) < 1e-7 * L * L
print("breaks, fence ends on a straight river bank: semicircle (m^2)", f(L * L / (2 * PI), 2), " 4000-gon", f(shoelace(semi), 2))
wrong = PI * math.sqrt(2 * (a * a + b * b))
assert wrong > L
print("breaks, oval's angle parameter, not constant speed: 'length' (m)", f(wrong, 2), " lost area", f(wrong ** 2 / (4 * PI) - PI * a * b, 2),
      " true", f(A_circle - PI * a * b, 2))
print("breaks, square's sum cut at n = 1, -3, 5, -7 (m^2)", f(lost_sum(sq, 7), 2), " true", f(exact, 2))
loop = pol_kappa(30, 60, 0)
assert min(loop) > 0 and extremes(loop) == 2 and extremes(discrete(pol_pts(30, 60, 0))) == 2   # bends left throughout
print("breaks, loop r = 30 + 60 cos t crosses itself: vertices", extremes(loop))
a3, b3 = ellipse_for(3.0)
assert extremes([ell_kappa(a3, b3, 2 * PI * i / M) for i in range(M)]) == 4
print("try, 3:1 oval: a, b (m)", f(a3, 4), f(b3, 4), " area (m^2)", f(PI * a3 * b3, 2), " vertices 4")
print("try, 800 m of wire: square's lost area (m^2)", f(800 ** 2 / (4 * PI) - 200 ** 2, 2), " a 100 m circle (m^2)", f(100 ** 2 / (4 * PI), 2))
six = pol_kappa(60, 30, 12)
assert extremes(six) == 6 and extremes(discrete(pol_pts(60, 30, 12))) == 6
print("try, egg r = 60 + 30 cos t + 12 sin 2t: vertices", extremes(six))
print("ALL CHECKS PASS")
