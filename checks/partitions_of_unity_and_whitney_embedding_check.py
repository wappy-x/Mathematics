# Partition of unity and Whitney embedding -- the check behind the card.  Standard library only.
# The Earth is a sphere of radius R = 6371 km (a model), covered by six orthographic sheets.
# Each sheet drops one coordinate of space and keeps the other two; it covers the open half
# where the dropped coordinate has its sign.  A bump on each sheet glues them into one map F.
from math import exp, sqrt, sin, cos, asin, radians, degrees

R, C, W = 6371.0, 0.5, 0.1      # km; a bump is on where t > C, with t = dropped coordinate / R
SHEETS = [("North", 2, 1), ("South", 2, -1), ("Greenwich", 0, 1),
          ("Date line", 0, -1), ("East", 1, 1), ("West", 1, -1)]   # (name, dropped axis, sign)

def f(s): return exp(-1.0 / (s * s)) if s > 0 else 0.0        # e^(-1/s^2), cut to 0 for s <= 0
def df(s): return 2.0 / s ** 3 * f(s) if s > 0 else 0.0       # its slope
def tent(s): return max(s, 0.0)                               # a bump with a corner, for "what breaks"
def cut(s): return 1.0 if s > 0 else 0.0                       # a hard cut, no fading at all
def t_of(P, k): return SHEETS[k][2] * P[SHEETS[k][1]] / R
def bump(P, k, c=C, prof=f): return prof((t_of(P, k) - c) / W)
def chart(P, k): return [P[j] for j in range(3) if j != SHEETS[k][1]]
def point(lat, lon):
    a, b = radians(lat), radians(lon)
    return [R * cos(a) * cos(b), R * cos(a) * sin(b), R * sin(a)]
def dist(A, B): return sqrt(sum((a - b) ** 2 for a, b in zip(A, B)))

def embed(P, with_bumps=True):          # F(p) = (psi_1 x_1, ..., psi_6 x_6, R psi_1, ..., R psi_6), km
    psi = [bump(P, k) for k in range(6)]
    out = [psi[k] * u for k in range(6) for u in chart(P, k)]
    return out + [R * p for p in psi] if with_bumps else out

def unembed(F):                         # road 1 to "one-to-one": read p back off F(p)
    k = max(range(6), key=lambda i: F[12 + i])
    x = [R * F[2 * k] / F[12 + k], R * F[2 * k + 1] / F[12 + k]]
    a, sg = SHEETS[k][1], SHEETS[k][2]
    P = x[:a] + [sg * sqrt(R * R - x[0] ** 2 - x[1] ** 2)] + x[a:]
    return P

def dF(P, v):                           # derivative of F along a tangent vector v, by the product rule
    rows, dpsi = [], []
    for k in range(6):
        a, sg = SHEETS[k][1], SHEETS[k][2]
        s = (t_of(P, k) - C) / W
        dp = df(s) / W * sg * v[a] / R
        rows += [dp * u + bump(P, k) * w for u, w in zip(chart(P, k), chart(v, k))]
        dpsi.append(R * dp)
    return rows + dpsi

def tangents(P):                        # two unit vectors at right angles, tangent to the globe
    a = [0.0, 0.0, 1.0] if abs(P[2]) < 0.9 * R else [1.0, 0.0, 0.0]
    e = [a[1] * P[2] - a[2] * P[1], a[2] * P[0] - a[0] * P[2], a[0] * P[1] - a[1] * P[0]]
    n = sqrt(sum(u * u for u in e)); e = [u / n for u in e]
    g = [(P[1] * e[2] - P[2] * e[1]) / R, (P[2] * e[0] - P[0] * e[2]) / R, (P[0] * e[1] - P[1] * e[0]) / R]
    return e, g

def min_stretch(P):                     # smallest stretch of dF on unit ground vectors (2x2 Gram matrix)
    e, g = tangents(P)
    A, B = dF(P, e), dF(P, g)
    p, q, r = sum(x * x for x in A), sum(x * y for x, y in zip(A, B)), sum(y * y for y in B)
    return sqrt((p + r) / 2 - sqrt(((p - r) / 2) ** 2 + q * q))

grid = [point(lat, lon) for lat in range(-80, 81, 10) for lon in range(0, 360, 10)]
grid += [point(90, 0), point(-90, 0)]

# ---- the partition of unity at London ----
L = point(51.5074, -0.1278)
psiL = [bump(L, k) for k in range(6)]
rhoL = [p / sum(psiL) for p in psiL]
print("London in space (km):", ", ".join(f"{u:.1f}" for u in L))
for k in range(6):
    print(f"{SHEETS[k][0]:<10} t = {t_of(L, k):8.5f}  s = {(t_of(L, k) - C) / W:8.4f}  bump {psiL[k]:.6f}  weight {rhoL[k]:.6f}")
print(f"bumps add to {sum(psiL):.6f}; weights add to {sum(rhoL):.12f}")
print("F(London), km:", ", ".join(f"{u + 0.0:.1f}" for u in embed(L)))
north = [-sin(radians(51.5074)) * cos(radians(-0.1278)), -sin(radians(51.5074)) * sin(radians(-0.1278)),
         cos(radians(51.5074))]
spd = [sqrt(sum(u * u for u in chart(north, k))) for k in range(6)]
print(f"walking north: North sheet speed {spd[0]:.4f}, Greenwich {spd[2]:.4f}, "
      f"glued ruler {sqrt(sum(rhoL[k] * spd[k] ** 2 for k in range(6))):.4f}")

# ---- every point is under some bump: grid search against the corner formula ----
tot = [sum(bump(P, k) for k in range(6)) for P in grid]
corner = 3 * f((1 / sqrt(3) - C) / W)
print(f"sum of bumps: grid minimum {min(tot):.6f}, at the corner {degrees(asin(1 / sqrt(3))):.2f} N 45.00 E, "
      f"t = {1 / sqrt(3):.5f}, total {corner:.6f}")
assert min(tot) >= corner - 1e-12 and corner > 0.5

# ---- road 1: F is one-to-one, because p can be read back off F(p) ----
back = max(dist(unembed(embed(P)), P) for P in grid)
print(f"grid points {len(grid)}; worst miss reading p back from F(p): {back:.2e} km")
assert back < 1e-6

# ---- road 2: F is one-to-one, by brute force over every pair of grid points ----
FG = [embed(P) for P in grid]
ratio = min(dist(FG[i], FG[j]) / dist(grid[i], grid[j])
            for i in range(len(grid)) for j in range(i))
print(f"pairs {len(grid) * (len(grid) - 1) // 2}; smallest (gap in F) / (gap in space): {ratio:.4f}")
assert ratio > 0.1

# ---- F is an immersion: product rule against difference quotients, then the whole grid ----
e, g = tangents(L)
h = 1.0
Ph = [cos(h / R) * p + R * sin(h / R) * u for p, u in zip(L, e)]
Pm = [cos(h / R) * p - R * sin(h / R) * u for p, u in zip(L, e)]
num = [(a - b) / (2 * h) for a, b in zip(embed(Ph), embed(Pm))]
miss = max(abs(a - b) for a, b in zip(num, dF(L, e)))
print(f"London: product rule vs difference quotient, worst entry miss {miss:.2e}")
assert miss < 1e-6
st = [min_stretch(P) for P in grid]
print(f"smallest stretch of dF: at London {min_stretch(L):.4f}, over the grid {min(st):.4f}")
assert min(st) > 0.1

# ---- what breaks ----
Np, Sp = [0.0, 0.0, R], [0.0, 0.0, -R]
print(f"poles apart in F: with bump entries {dist(embed(Np), embed(Sp)):.6f}, "
      f"without {dist(embed(Np, False), embed(Sp, False)):.6f}")
assert dist(embed(Np, False), embed(Sp, False)) == 0.0
print(f"bumps start at t > 0.6: sum at the corner {3 * f((1 / sqrt(3) - 0.6) / W):.6f}")
for prof, name in ((f, "e^(-1/s^2)"), (tent, "tent"), (cut, "hard cut")):
    at = lambda lat: bump(point(lat, 0), 0, C, prof)
    step = 1.0 / R * 180 / 3.141592653589793                 # 1 km of ground, in degrees
    print(f"{name:<10} North bump slope at 30 N, per 1000 km: below {1000 * (at(30) - at(30 - step)):.4f}, "
          f"above {1000 * (at(30 + step) - at(30)):.4f}")

# ---- the chart along the Greenwich meridian, and the figure ----
lats = range(-90, 91, 10)
print("latitude  ", ", ".join(str(lat) for lat in lats))
for k, name in ((1, "South"), (2, "Greenwich"), (0, "North")):
    w = [bump(point(lat, 0), k) / sum(bump(point(lat, 0), j) for j in range(6)) for lat in lats]
    print(f"{name:<10}", ", ".join(f"{u:.2f}" for u in w))
px = lambda P, r=160: (220 + P[0] / R * r, 220 - P[2] / R * r)   # globe circle r = 160 px; arcs drawn outside it
print("figure, London px ({:.1f}, {:.1f}); North arc (r 176) right end ({:.1f}, {:.1f}); Greenwich arc (r 192) top end "
      "({:.1f}, {:.1f}); 30 N and 60 N rays (r 205) end ({:.1f}, {:.1f}), ({:.1f}, {:.1f})".format(
    *px(L), *px(point(30, 0), 176), *px(point(60, 0), 192), *px(point(30, 0), 205), *px(point(60, 0), 205)))
print("ALL CHECKS PASS")
