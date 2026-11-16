# Restriction and Kakeya in outline: the check behind the card. Standard library only.
# A 343 Hz tone in air has wavelength 1 m, so its spectrum lies on the circle of
# radius 1 cycle per metre. Every circle integral and every area is computed here.
import math

def ext(x1, x2, lo, hi, m):
    # Eg(x) = integral over the arc lo..hi of exp(2 pi i x.w) d(arc), g = 1, midpoint rule
    h = (hi - lo) / m
    re = im = 0.0
    for k in range(m):
        p = lo + (k + 0.5) * h
        a = 2 * math.pi * (x1 * math.cos(p) + x2 * math.sin(p))
        re += math.cos(a)
        im += math.sin(a)
    return re * h, im * h

def circle(r):  # whole circle, g = 1: real by symmetry
    return ext(r, 0.0, 0.0, 2 * math.pi, int(8 * r) + 64)[0]

def j0_series(z):  # J0(z) = sum (-1)^k (z/2)^(2k) / (k!)^2
    term, s, k = 1.0, 1.0, 1
    while abs(term) > 1e-18:
        term *= -(z * z / 4) / (k * k)
        s += term
        k += 1
    return s

def asym(r):  # large r: 2 pi J0(2 pi r) is about (2 / sqrt r)(cos u + sin u / (16 pi r)), u = 2 pi r - pi/4
    u = 2 * math.pi * r - math.pi / 4
    return 2 * (math.cos(u) + math.sin(u) / (16 * math.pi * r)) / math.sqrt(r)

print("circle field Eg(r), g = 1 on the whole circle")
for r in (0.0, 0.25, 0.5, 1.0, 2.0):
    q, s = circle(r), 2 * math.pi * j0_series(2 * math.pi * r)
    assert abs(q - s) < 1e-9
    print(f"r={r:g} m: quadrature {q:.6f}, Bessel series {s:.6f}")
for r in (10.3, 50.3):
    q = circle(r)
    assert abs(q - asym(r)) < 1e-4
    print(f"r={r:g} m: quadrature {q:.6f}, large-r formula {asym(r):.6f}, envelope 2/sqrt(r) {2 / math.sqrt(r):.6f}")
rs = [0.25 * i for i in range(1, 21)]
print("chart r:", ", ".join(f"{r:g}" for r in rs))
print("chart Eg:", ", ".join(f"{circle(r):.3f}" for r in rs))
print("chart envelope 2/sqrt(r):", ", ".join(f"{2 / math.sqrt(r):.3f}" for r in rs))

# integral over the disc of radius R of |Eg|^p, Simpson in r with step 1/128 m
n_per, R_max = 128, 64
h = 1 / n_per
vals = [circle(i * h) if i else 2 * math.pi for i in range(R_max * n_per + 1)]
lp = {}
for p in (3, 4, 5, 6):
    s = 0.0
    for i, v in enumerate(vals):
        f = abs(v) ** p * 2 * math.pi * i * h
        if i and i % (8 * n_per) == 0:
            lp[(p, i // n_per)] = (s + f) * h / 3
        s += f * (1 if i == 0 else (4 if i % 2 else 2))
Rs = (8, 16, 32, 64)
for p in (3, 4, 5, 6):
    print(f"p={p}: " + ", ".join(f"R={R} {lp[(p, R)]:.1f}" for R in Rs))
grow = [lp[(4, 2 * R)] - lp[(4, R)] for R in (8, 16, 32)]
print("p=4 gain per doubling of R:", ", ".join(f"{g:.2f}" for g in grow),
      f"| 12 pi ln 2 = {12 * math.pi * math.log(2):.2f}")
assert grow[0] > grow[1] > grow[2] > 12 * math.pi * math.log(2) > grow[2] - 0.1
tails = [lp[(6, R)] + 40 * math.pi / R for R in (32, 64)]
assert abs(tails[0] - tails[1]) < 0.05
print(f"p=6 plus tail 40 pi/R: R=32 {tails[0]:.1f}, R=64 {tails[1]:.1f}")
ratio = (lp[(3, 64)] / lp[(3, 32)]) ** 2
assert abs(ratio - 2) < 0.05
print(f"p=3 growth: (I(64)/I(32))^2 = {ratio:.3f}, like sqrt(R)")

# a cap of half-width delta = 0.1 rad around the direction (1, 0): a beam
d = 0.1
along = [(x, math.hypot(*ext(x, 0, -d, d, 2000))) for x in (0, 25, 50, 100, 200, 400)]
for x, v in along:
    assert abs(v - math.hypot(*ext(x, 0, -d, d, 4000))) < 1e-6
print("beam along the axis:", ", ".join(f"{x} m {v:.4f}" for x, v in along))
across = []
for y in (0, 2.5, 5, 7.5, 10):
    v = math.hypot(*ext(0, y, -d, d, 2000))
    u = 2 * math.pi * d * y
    small = 2 * d * (abs(math.sin(u) / u) if u else 1.0)
    assert abs(v - small) < 1e-3
    across.append(f"{y:g} m {v:.4f} (small-angle {small:.4f})")
print("beam across the axis:", ", ".join(across))
def flat(x1, x2, m=2000):  # flat segment w = (1, s), |s| <= delta: no curvature
    re = im = 0.0
    for k in range(m):
        a = 2 * math.pi * (x1 + x2 * (-d + (k + 0.5) * 2 * d / m))
        re, im = re + math.cos(a), im + math.sin(a)
    return math.hypot(re, im) * 2 * d / m
fl = [flat(200, 0), flat(400, 0)]
assert abs(flat(400, 2.5) - 2 * d * math.sin(5 * math.pi * d) / (5 * math.pi * d)) < 1e-6 and along[4][1] < 0.1  # off axis: 2 delta sinc(2 delta x2)
print(f"flat segment along the axis: 200 m {fl[0]:.4f}, 400 m {fl[1]:.4f}")
print(f"try delta=0.05: across 10 m {math.hypot(*ext(0, 10, -0.05, 0.05, 2000)):.4f},"
      f" along 400 m {math.hypot(*ext(400, 0, -0.05, 0.05, 2000)):.4f}")
for p in (5, 6):
    print(f"Knapp ratio (2 delta)^(1/2) delta^(-3/{p}) at L2 data:",
          ", ".join(f"delta={e} {(2 * e) ** 0.5 * e ** (-3 / p):.3f}" for e in (0.1, 0.01, 0.001)))

# needle bound in the plane: N tubes 1 by 1/N, directions k pi / N
def overlap_total(N):  # sum over all pairs of |Tj n Tk| at most N delta + sum delta^2 / sin(angle)
    dl = 1 / N
    return N * dl + N * dl * dl * sum(1 / math.sin(math.pi * m / N) for m in range(1, N))
for N in (10, 100, 1000, 10000):
    S = overlap_total(N)
    print(f"N={N}: S_N {S:.4f}, union at least 1/S_N = {1 / S:.4f}, 1 + (2/pi) ln N = {1 + 2 / math.pi * math.log(N):.4f}")
inv = [1 / math.sin(math.pi * m / 10) for m in range(1, 10)]
print("S_10 terms 1/sin(m pi/10), m=1..5:", ", ".join(f"{v:.4f}" for v in inv[:5]), f"| sum m=1..9 {sum(inv):.4f}")
N, G = 10, 440
cell = 1.1 / G
dirs = [(math.cos(math.pi * k / N), math.sin(math.pi * k / N)) for k in range(N)]
cover = squares = 0
for i in range(G):
    x = -0.55 + (i + 0.5) * cell
    for j in range(G):
        y = -0.55 + (j + 0.5) * cell
        m = sum(1 for c, s in dirs if abs(x * c + y * s) <= 0.5 and abs(y * c - x * s) <= 0.05)
        cover += m > 0
        squares += m * m
cover, squares = cover * cell * cell, squares * cell * cell
assert abs(squares - overlap_total(10)) < 0.01 and cover >= 1 / overlap_total(10)
print(f"bush of 10 tubes on a grid: union {cover:.3f}, sum of overlaps {squares:.3f}")

# Kakeya needle problem: areas in which a unit needle turns round
def shoelace(P):
    return abs(sum(P[i][0] * P[i - 1][1] - P[i - 1][0] * P[i][1] for i in range(len(P)))) / 2
side = 2 / math.sqrt(3)
tri = shoelace([(0, 0), (side, 0), (side / 2, 1)])
K, a = 4000, 0.25
delt = shoelace([(2 * a * math.cos(t) + a * math.cos(2 * t), 2 * a * math.sin(t) - a * math.sin(2 * t))
                 for t in (2 * math.pi * k / K for k in range(K))])
G = 997  # grid count of the triangle, an independent road to its area
grid = sum(1 for i in range(G) for j in range(G) if (j + 0.5) / G <= math.sqrt(3) * min((i + 0.5) * side / G, side - (i + 0.5) * side / G)) * side / G ** 2
assert abs(tri - grid) < 1e-5 and abs(delt - math.pi / 8) < 1e-6
print(f"needle areas: disc {math.pi / 4:.6f}, triangle {tri:.6f} (1/sqrt3 {1 / math.sqrt(3):.6f}),"
      f" deltoid {delt:.6f} (pi/8 {math.pi / 8:.6f})")
for dim, p in ((2, 4), (2, 6), (3, 3), (3, 3.5), (3, 4)):
    print(f"restriction at p={p} in dimension {dim}: Kakeya dimension at least {2 * p / (p - 2) - dim:.3f}")
print("ALL CHECKS PASS")
