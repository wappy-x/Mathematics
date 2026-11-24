# Change of variables for Lebesgue measure -- the check behind the card.  Standard library only.
# A = [[3, 1], [0, 2]] multiplies every area by |det A| = 6: checked by the determinant, the
# corners of the image, a stretch-then-shear factorisation and exact grid counts on three sets.
# Polar coordinates: the Gaussian over the plane and over R^n, ball volumes by three roads.
from fractions import Fraction as Fr
from math import cos, exp, pi, sin, sqrt

A = ((3, 1), (0, 2))
det = A[0][0] * A[1][1] - A[0][1] * A[1][0]
corners = [(0, 0), (1, 0), (1, 1), (0, 1)]
img = [(A[0][0] * x + A[0][1] * y, A[1][0] * x + A[1][1] * y) for x, y in corners]
shoelace = sum(img[k][0] * img[(k + 1) % 4][1] - img[(k + 1) % 4][0] * img[k][1] for k in range(4)) / 2
print(f"det A = 3 x 2 - 1 x 0 = {det}; image of the unit square has corners {img}, shoelace area {shoelace:g}")
S, H = ((3, 0), (0, 2)), ((1, Fr(1, 2)), (0, 1))                 # stretch by 3 and 2, then shear: first += second / 2
HS = [[sum(H[i][k] * S[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
factors = (S[0][0], S[1][1], H[0][0] * H[1][1] - H[0][1] * H[1][0])  # the two stretches, and the shear's determinant
print(f"factorisation: shear [[1, 0.5], [0, 1]] after stretch [[3, 0], [0, 2]] = [[{'], ['.join(', '.join(str(v) for v in row) for row in HS)}]]; factors {' x '.join(str(f) for f in factors)} = {factors[0] * factors[1] * factors[2]}")

# Grid counts.  Points at odd multiples of 1/800 m (a 1/400 m grid, midpoints).  A point y lies in
# A(E) exactly when A^{-1} y = ((2 y1 - y2)/6, y2/2) lies in E; every test is in whole numbers.
def in_E(name, U, V, s):                    # u = U/(2s), v = V/(2s); s = 2400 below, or 400 for E itself
    if name == "square":
        return 0 <= U < 2 * s and 0 <= V < 2 * s
    if name == "disc":                      # centre (0.5, 0.5) m, radius 0.5 m
        return (U - s) ** 2 + (V - s) ** 2 < s * s
    return 0 <= V < U < 2 * s               # triangle: below the diagonal y < x
names, exact = ("square", "disc", "triangle"), (1.0, pi / 4, 0.5)
before = {n: sum(in_E(n, 2 * a + 1, 2 * b + 1, 400) for a in range(400) for b in range(400)) for n in names}
after = dict.fromkeys(names, 0)
for i in range(1600):
    Y1 = 2 * i + 1
    for j in range(800):
        Y2 = 2 * j + 1
        U, V = 2 * Y1 - Y2, 3 * Y2          # A^{-1} y in units of 1/4800 m
        for n in names:
            after[n] += in_E(n, U, V, 2400)
print("set E | exact m(E) | grid m(E) | grid m(AE) | 6 m(E) | grid m(AE) / exact m(E)")
ratios = []
for n, e in zip(names, exact):
    mb, ma = before[n] / 400 ** 2, after[n] / 400 ** 2
    ratios.append(ma / e)
    print(f"{n} | {e:.6f} | {mb:.6f} | {ma:.6f} | {6 * e:.6f} | {ma / e:.4f}")
dens = Fr(1, abs(det))                      # the dart lands uniformly; a camera records A x, spread at density 1/|det A|
p_ell, p_grid = abs(det) * pi / 4 * dens, after["disc"] / 400 ** 2 * dens
print(f"camera records (3x + y, 2y): density {dens} per m^2 on the parallelogram; P(recorded point in ellipse) = "
      f"{abs(det) * pi / 4:.6f} x {dens} = {p_ell:.6f} (grid {p_grid:.6f}); P(dart in disc) = {pi / 4:.6f}")
print(f"break, density 1 instead of {dens}: total probability over the parallelogram = {after['square'] / 400 ** 2:.0f}, not 1")

def midpoint(f, a, b, steps):
    h = (b - a) / steps
    return h * sum(f(a + (k + 0.5) * h) for k in range(steps))

# A smooth map: polar coordinates on the plane, |det DT(r, t)| = r.  The Gaussian bump on the unit disc;
# the Cartesian road slices at x = sin p, so the slice half-width is cos p.
polar = 2 * pi * midpoint(lambda r: exp(-r * r) * r, 0.0, 1.0, 10000)
cart = midpoint(lambda p: exp(-sin(p) ** 2) * cos(p) * 2 * midpoint(lambda y: exp(-y * y), 0.0, cos(p), 1000), -pi / 2, pi / 2, 1000)
print(f"unit disc, e^(-|x|^2): polar {polar:.6f}; Cartesian slices {cart:.6f}; pi(1 - 1/e) = {pi * (1 - exp(-1)):.6f}")
no_r = 2 * pi * midpoint(lambda r: exp(-r * r), 0.0, 1.0, 10000)
print(f"break, polar without the factor r: {no_r:.6f}; angle run twice round: {2 * polar:.6f}")
print(f"break, signed det of [[1, 3], [2, 0]] (A's columns swapped): {1 * 0 - 3 * 2}; area is |-6| = 6")
print(f"break, factor on the wrong side: ellipse area as disc area / 6 = {pi / 4 / 6:.6f}, not {6 * pi / 4:.6f}")

# Polar coordinates in R^n.  Road 1: the Gaussian integral and its product over n coordinates (Tonelli).
root_pi = midpoint(lambda x: exp(-x * x), -10.0, 10.0, 20000)
print(f"integral of e^(-x^2) over the line = {root_pi:.9f}; sqrt(pi) = {sqrt(pi):.9f}")
def gamma_half(m):                          # Gamma(m/2) from Gamma(1) = 1, Gamma(1/2) = root_pi, Gamma(s+1) = s Gamma(s)
    g, s = (1.0, 1.0) if m % 2 == 0 else (root_pi, 0.5)
    while s < m / 2 - 1e-9:
        g, s = g * s, s + 1
    return g
radial = {n: midpoint(lambda r: exp(-r * r) * r ** (n - 1), 0.0, 12.0, 120000) for n in (2, 3, 10)}
print("n | Gaussian over R^n | radial integral | Gamma(n/2)/2 | sphere area | ball volume | pi^(n/2)/Gamma(n/2+1)")
by_polar = {}
for n in (2, 3, 10):
    gauss = root_pi ** n
    sphere = gauss / radial[n]              # polar: integral = sphere area x radial integral
    by_polar[n] = sphere / n
    print(f"{n} | {gauss:.6f} | {radial[n]:.6f} | {gamma_half(n) / 2:.6f} | {sphere:.6f} | {sphere / n:.6f} | "
          f"{root_pi ** n / gamma_half(n + 2):.6f}")
print(f"Gamma(5/2) = {gamma_half(5):.6f}; Gamma(6) = {gamma_half(12):.0f}")
# Road 2: slicing (Fubini), no Gamma and no polar: V_n = V_(n-1) x integral of (1 - t^2)^((n-1)/2) over [-1, 1].
slab, V = [], 2.0
for n in range(1, 13):
    if n > 1:
        V *= midpoint(lambda t: (1 - t * t) ** ((n - 1) / 2), -1.0, 1.0, 200000)
    slab.append(V)
print("chart, n = 1 to 12, ball volume by slicing: " + ", ".join(f"{v:.4f}" for v in slab))
print("chart, n = 1 to 12, sphere area n V_n: " + ", ".join(f"{(k + 1) * v:.4f}" for k, v in enumerate(slab)))
print(f"share of the cube [-1, 1]^n filled by the ball: n = 3 {slab[2] / 8:.4f}, n = 10 {slab[9] / 2 ** 10:.5f}")
print(f"break, R^3 without r^(n-1): sphere area x half-line integral = {4 * pi * root_pi / 2:.6f}, "
      f"not {root_pi ** 3:.6f}; sphere area 4 pi = {4 * pi:.6f} taken as the volume")

state, N, hits = 2026, 200000, 0            # Road 3: SplitMix64 darts in the cube [-1, 1]^3
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
for _ in range(N):
    x, y, z = 2 * uniform() - 1, 2 * uniform() - 1, 2 * uniform() - 1
    hits += x * x + y * y + z * z < 1
mc = 8 * hits / N
se = 8 * sqrt(slab[2] / 8 * (1 - slab[2] / 8) / N)
print(f"simulation, {N} points in [-1, 1]^3: {hits} inside, volume {mc:.4f}, standard error {se:.4f}")
print(f"figure, 60 px per m; square (30, 190) to (90, 130); parallelogram " +
      ", ".join(f"({130 + 60 * x}, {190 - 60 * y})" for x, y in img) + f"; ellipse centre ({130 + 60 * 2}, {190 - 60 * 1})")

assert det == 6 and abs(shoelace) == det                           # determinant against the corners
assert HS == [[3, 1], [0, 2]]                                       # the factorisation really gives A
assert factors[0] * factors[1] * factors[2] == det                  # the step factors multiply to det A
assert all(abs(r - 6) < 0.01 for r in ratios)                       # grid counts against |det A|
assert abs(after["disc"] / 400 ** 2 - 6 * pi / 4) < 0.005
assert after["square"] * dens == 400 ** 2                           # the recorded point's density totals 1
assert abs(p_grid - pi / 4) < 0.001                                 # P(ellipse) on the camera's grid = P(dart in disc)
assert abs(polar - cart) < 1e-5 and abs(polar - pi * (1 - exp(-1))) < 1e-6   # polar against Cartesian slices
assert abs(root_pi - sqrt(pi)) < 1e-12
assert all(abs(radial[n] - gamma_half(n) / 2) < 1e-9 for n in (2, 3, 10))
assert all(abs(by_polar[n] - slab[n - 1]) < 1e-6 for n in (2, 3, 10))   # polar road against slicing road
assert abs(slab[2] - 4 * pi / 3) < 1e-6 and abs(slab[9] - pi ** 5 / 120) < 1e-6
assert abs(mc - slab[2]) < 4 * se                                   # simulation against slicing
print("ALL CHECKS PASS")
