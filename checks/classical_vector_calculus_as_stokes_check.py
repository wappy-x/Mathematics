# Green, divergence and curl theorems as one statement -- the check behind the card.  Standard
# library only.  One routine integrates any k-form over a parametrised cube, and one routine takes
# its exterior derivative d by central differences.  Stokes says: integral of dw over M equals
# integral of w over the boundary of M.  The valley's four cases change only the degree of w and
# the shape M.  Road A: w over the boundary.  Road B: dw over the inside.  Road C: the classical
# formula (gradient, curl, divergence) worked out by hand, integrated directly.  Road D: exact values.
import math
from functools import reduce
from itertools import combinations, product

def gauss(n):                                    # Gauss-Legendre nodes and weights on [0, 1]
    out = []
    for i in range(n):
        x = math.cos(math.pi * (i + 0.75) / (n + 0.5))
        for _ in range(60):                      # Newton's method on the Legendre polynomial
            p0, p1 = 1.0, x
            for k in range(2, n + 1):
                p0, p1 = p1, ((2 * k - 1) * x * p1 - (k - 1) * p0) / k
            dp = n * (x * p1 - p0) / (x * x - 1)
            x = x - p1 / dp
        out.append(((1 - x) / 2, 1 / ((1 - x * x) * dp * dp)))
    return out

NODES, H = gauss(10), 1e-5                       # 10 nodes: exact for polynomials up to degree 19

def quad(fn, k):                                 # integral of fn over the unit cube [0, 1]^k
    total = 0.0
    for pt in product(NODES, repeat=k):
        total += math.prod(w for _, w in pt) * fn([x for x, _ in pt])
    return total

def bump(p, i, s):
    q = list(p); q[i] += s; return q

def det(m):                                      # determinant, expanding along the first row
    if not m: return 1.0
    total = 0.0
    for j in range(len(m)):
        total += (-1) ** j * m[0][j] * det([r[:j] + r[j + 1:] for r in m[1:]])
    return total

def d(n, k, f):                                  # exterior derivative: a k-form to a (k+1)-form
    lo, hi = list(combinations(range(n), k)), list(combinations(range(n), k + 1))
    def df(p):
        out = []
        for J in hi:                             # coefficient of dx^J: sum of (-1)^m d_j w_(J without j)
            s = 0.0
            for m, j in enumerate(J):
                r = lo.index(J[:m] + J[m + 1:])
                s += (-1) ** m * (f(bump(p, j, H))[r] - f(bump(p, j, -H))[r]) / (2 * H)
            out.append(s)
        return out
    return df

def integrate(n, k, f, c):                       # pull w back along the cube map c, then add up
    idx = list(combinations(range(n), k))
    def pulled(u):
        p = c(u)
        vs = [[(a - b) / (2 * H) for a, b in zip(c(bump(u, i, H)), c(bump(u, i, -H)))] for i in range(k)]
        total = 0.0
        for fi, I in zip(f(p), idx):             # a k-form eats k arrows: coefficient times a minor
            total += fi * det([[v[i] for i in I] for v in vs])
        return total
    return quad(pulled, k)

def faces(n, k, f, c):                           # faces of a (k+1)-cube, signed (-1)^(i+1+a), i from 0
    out = []
    for i in range(k + 1):
        for a in (0, 1):
            face = lambda t, i=i, a=a: c(t[:i] + [float(a)] + t[i:])
            out.append((-1) ** (i + 1 + a) * integrate(n, k, f, face))
    return out

def boundary(n, k, f, c): return reduce(lambda a, b: a + b, faces(n, k, f, c), 0.0)   # left to right

def h(x, y): return 0.04 * (x - 3) * (x - 3) + 0.05 * y          # ground height, km
def wind(p): x, y, z = p; return [-0.1 * y * y + 0.5 * z, 12 + 0.2 * x * y + 2 * z, 0.05 * x]
def rain(p): x, y, z = p; return [0.0, 0.1 * y * (2 - z), -0.75 * (2 - z)]   # mm/h of water
height = lambda p: [h(p[0], p[1])]                                # 0-form on the map
glider = lambda p: wind([p[0], p[1], 1.0])[:2]                    # 1-form P dx + Q dy at 1 km up
flux = lambda p: (lambda g: [g[2], -g[1], g[0]])(rain(p))         # G1 dy^dz + G2 dz^dx + G3 dx^dy
path = lambda u: [3 - 3 * u[0], 4 * u[0]]                         # valley floor to the north-west corner
floor = lambda u: [6 * u[0], 4 * u[1]]                            # the 6 km by 4 km map
ground = lambda u: [6 * u[0], 4 * u[1], h(6 * u[0], 4 * u[1])]    # the terrain itself
air = lambda u: (lambda x, y: [x, y, h(x, y) + u[2] * (2 - h(x, y))])(6 * u[0], 4 * u[1])

classic = [                                      # road C: hand-derived gradient, curl, divergence
    quad(lambda u: (lambda x, y: 0.08 * (x - 3) * -3 + 0.05 * 4)(*path(u)), 1),
    quad(lambda u: 0.4 * (4 * u[1]) * 24, 2),
    quad(lambda u: (lambda x, y: -2 * -(0.08 * (x - 3)) + 0.45 * -0.05 + 0.4 * y)(*floor(u)) * 24, 2),
    quad(lambda u: (lambda x, y, z: (0.75 + 0.1 * (2 - z)) * 24 * (2 - h(x, y)))(*air(u)), 3)]
cases = [("k=0 path, climb in km", 2, 0, height, path, 0.56),
         ("k=1 plane, Green, km^2/h", 2, 1, glider, floor, 19.2),
         ("k=1 space, curl, km^2/h", 3, 1, wind, ground, 18.66),
         ("k=2 space, divergence", 3, 2, flux, air, 35.859904)]
def f6(v): return f"{v:.6f}".replace("-0.000000", "0.000000")   # no minus sign on a zero
def z6(v): return f"{f6(v):>12}"
def row(vs): return ", ".join(f6(v) for v in vs)
print(f"{'case':<28}{'boundary':>12}{'inside':>12}{'classical':>12}{'exact':>12}")
for (name, n, k, f, c, exact), cl in zip(cases, classic):
    edge, inside = boundary(n, k, f, c), integrate(n, k + 1, d(n, k, f), c)
    print(f"{name:<28}{z6(edge)}{z6(inside)}{z6(cl)}{z6(exact)}")
    assert abs(edge - exact) < 1e-6 and abs(inside - exact) < 1e-6 and abs(cl - exact) < 1e-6

p0 = [1.0, 2.0, 0.5]                             # d reads as gradient, curl and divergence here
g, cw, dv = d(2, 0, height)(p0[:2]), d(3, 1, wind)(p0), d(3, 2, flux)(p0)
print("at (1, 2, 0.5): d(height) =", row(g))
print("  d(wind) on dy^dz, dz^dx, dx^dy =", row((cw[2], -cw[1], cw[0])))
print(f"  d(rain) on dx^dy^dz = {dv[0]:.6f}")
assert abs(g[0] + 0.16) < 1e-8 and abs(g[1] - 0.05) < 1e-8 and abs(dv[0] - 0.9) < 1e-8
assert abs(cw[2] + 2) < 1e-8 and abs(cw[1] + 0.45) < 1e-8 and abs(cw[0] - 0.8) < 1e-8
assert abs(det([[1.0, 2.0], [3.0, 4.0]]) + 2) < 1e-12   # cofactor signs, on a matrix with both off-diagonal entries nonzero
print(f"map area {f6(integrate(2, 2, lambda p: [1.0], floor))} km^2; integral of y dy {f6(quad(lambda u: 16 * u[0], 1))}; curl north part x rise {f6(-cw[1] * g[1])}")

curl_slip = lambda p: (lambda v: [v[0], -v[1], v[2]])(d(3, 1, wind)(p))
tilt = quad(lambda u: (lambda x, y: -2 * -(0.08 * (x - 3)) + 0.45 * -0.05)(*floor(u)) * 24, 2)
sides, rim, box = faces(2, 1, glider, floor), faces(3, 1, wind, ground), faces(3, 2, flux, air)
no_ground = boundary(3, 2, flux, air) - box[4]
clockwise, flat, slip = -boundary(3, 1, wind, ground), boundary(2, 1, glider, floor), integrate(3, 2, curl_slip, ground)
vortex = lambda p: (lambda dx, dy: [-dy / (dx * dx + dy * dy), dx / (dx * dx + dy * dy)])(p[0] - 3, p[1] - 2)
spin10 = boundary(2, 1, vortex, floor)          # not a polynomial: 10 nodes are not exact here
NODES = gauss(20)
spin_edge, spin_inside = boundary(2, 1, vortex, floor), integrate(2, 2, d(2, 1, vortex), floor)
print("sides west, east, south, north:")
print("  glider at 1 km =", row(sides))
print("  rim on the ground =", row(rim))
print("  rain, then ground and ceiling =", row(box))
print(f"curl flux through the ground from the tilt terms: {tilt:.6f}")
print("what breaks:")
print(f"  rim walked clockwise:             {z6(clockwise)}")
print(f"  terrain treated as the flat map:  {z6(flat)}")
print(f"  dz^dx read as dx^dz:              {z6(slip)}")
print(f"  ground left out of the skin:      {z6(no_ground)}")
print(f"  whirlwind, boundary, 10 nodes:    {z6(spin10)}")
print(f"  whirlwind, boundary, 20 nodes:    {z6(spin_edge)}")
print(f"  whirlwind, inside, 20 nodes:      {z6(spin_inside)}")
assert abs(box[4] - 32.4592) < 1e-6 and abs(tilt + 0.54) < 1e-6 and abs(no_ground - 3.400704) < 1e-6
assert abs(spin_edge - 2 * math.pi) < 1e-8 and abs(spin_inside) < 1e-6 and abs(spin10 - 2 * math.pi) > 1e-6
assert abs(slip - 19.74) < 1e-6 and abs(flat - 19.2) < 1e-6 and abs(clockwise + 18.66) < 1e-6
print("ALL CHECKS PASS")
