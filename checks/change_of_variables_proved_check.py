# Change of variables, proved -- the check behind the card.  Standard library only.
# Linear case: L = shear after stretch.  Then the polar moment of a disc, radius 2 cm, by
# polar coordinates, by a blind x-y grid, by cutting into pieces, and by two one-coordinate moves.
import math
PI = math.pi
mul = lambda A, B: [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
det = lambda M: M[0][0] * M[1][1] - M[0][1] * M[1][0]
def shoelace(pts):                              # area of a polygon from its corners, in order
    return sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1])) / 2
def simpson(f, a, b, n=200):                    # Simpson's rule on n (even) strips
    h, s = (b - a) / n, f(a) + f(b)
    return (s + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))) * h / 3
def grid(f, inside, lo, hi, n):                 # midpoint cells on a square box, kept if inside
    h = (hi - lo) / n
    pts = ((lo + (i + 0.5) * h, lo + (j + 0.5) * h) for i in range(n) for j in range(n))
    return sum(f(x, y) for x, y in pts if inside(x, y)) * h * h
f = lambda x, y: x * x + y * y                  # squared distance from the axis, cm^2
S, H = [[2, 0], [0, 3]], [[1, 1 / 3], [0, 1]]   # stretch x by 2 and y by 3; shear x + y/3
L = mul(H, S)
sq = [(0, 0), (1, 0), (1, 1), (0, 1)]
Lx = lambda u, v: (L[0][0] * u + L[0][1] * v, L[1][0] * u + L[1][1] * v)
par = [Lx(u, v) for u, v in sq]
PL, swp = mul([[0, 1], [1, 0]], L), [(b, a) for a, b in par]   # a swap after L: not triangular, so det's sign is tested
def ins(x, y):                                  # pull the point back by L inverse, test the square
    u, v = (L[1][1] * x - L[0][1] * y) / det(L), (L[0][0] * y - L[1][0] * x) / det(L)
    return 0 <= u <= 1 and 0 <= v <= 1
print(f"L = shear x stretch: rows ({L[0][0]:g}, {L[0][1]:g}), ({L[1][0]:g}, {L[1][1]:g}); det stretch {det(S):g}, det shear {det(H):g}, det L {det(L):.6f}")
print("image of the unit square: corners", " ".join(f"({a:g}, {b:g})" for a, b in par) + ";", f"area by shoelace {shoelace(par):.6f}; after a swap {shoelace(swp):.6f}, det {det(PL):g}")
print(f"mistake, side lengths multiplied: {math.hypot(L[0][0], L[1][0]) * math.hypot(L[0][1], L[1][1]):.6f}")
lin_grid = grid(f, ins, -0.001, 3.001, 600)     # box padded 0.001 cm, so no cell centre sits on an edge
lin_sq = abs(det(L)) * simpson(lambda u: simpson(lambda v: f(*Lx(u, v)), 0, 1), 0, 1)
print(f"polar moment of the plate about its corner: x-y grid {lin_grid:.6f}; square x 6 {lin_sq:.6f}; by hand 6 x 17/3 = 34")
polar = simpson(lambda t: simpson(lambda r: r ** 3, 0, 2), 0, 2 * PI)
print(f"disc radius 2: polar with factor r {polar:.6f}; by hand 2 pi x 4 = {8 * PI:.6f}")
for n in (200, 800):
    g = grid(f, lambda x, y: x * x + y * y <= 4, -2, 2, n)
    print(f"x-y grid {n} a side, blind to r: {g:.6f}, error {g - 8 * PI:+.6f}")
def pieces(nr, nt, m=8):                        # sum f(T(centre)) x shoelace area of T(cell)
    s, dr, dt = 0.0, 2 / nr, 2 * PI / nt
    for i in range(nr):
        for j in range(nt):
            r0, t0 = i * dr, j * dt
            edge = [(r0 + dr * k / m, t0) for k in range(m)] + [(r0 + dr, t0 + dt * k / m) for k in range(m)]
            edge += [(r0 + dr - dr * k / m, t0 + dt) for k in range(m)] + [(r0, t0 + dt - dt * k / m) for k in range(m)]
            s += (r0 + dr / 2) ** 2 * shoelace([(r * math.cos(t), r * math.sin(t)) for r, t in edge])
    return s
cut = [pieces(n, 4 * n) for n in (10, 40)]
print(f"cut into pieces, no Jacobian used: 10 x 40 cells {cut[0]:.6f}; 40 x 160 cells {cut[1]:.6f}")
d = 1e-6
r, t = 1.5, 0.6                                 # one address; factor polar into two moves
x = r * math.cos(t)
m1 = (math.cos(t) * (r + d) - math.cos(t) * (r - d)) / (2 * d)             # (r, t) -> (x, t)
m2 = (x * math.tan(t + d) - x * math.tan(t - d)) / (2 * d)                 # (x, t) -> (x, x tan t)
print(f"at r {r}, theta {t}: move 1 det {m1:.6f}, move 2 det {m2:.6f}, product {m1 * m2:.6f} = r")
print(f"mistakes: factor r dropped {simpson(lambda t: simpson(lambda r: r * r, 0, 2), 0, 2 * PI):.6f}; theta run twice round {2 * polar:.6f}; factor 1/r {4 * PI:.6f}")
assert abs(shoelace(par) - det(S) * det(H)) < 1e-12 and abs(det(L) - 6) < 1e-12 and abs(shoelace(swp) - det(PL)) < 1e-12
assert abs(lin_grid - 34) < 0.05 and abs(lin_sq - 34) < 1e-9    # plate: blind grid meets the square
assert abs(polar - 8 * PI) < 1e-9 and abs(g - 8 * PI) < 0.01    # disc: polar meets the blind grid
assert abs(cut[1] - 8 * PI) < 0.01 and abs(m1 * m2 - r) < 1e-6  # pieces close in; moves multiply to r
print("ALL CHECKS PASS")
