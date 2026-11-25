# Peter-Weyl -- the check behind the card.  Standard library only: math.  Haar averages are
# sums on finite groups and Gauss-Legendre quadrature, written out, on SO(3) and the sphere.
# Roads: exact counts and hand fractions; Haar averages; each degree's Legendre kernel; Parseval.
import math

def mul(a, b):                        # matrix product
    return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))]
            for i in range(len(a))]

tp = lambda a: [list(r) for r in zip(*a)]                       # transpose

def gram_gap(funcs, w):               # largest |<e_j, e_k> - (1 if j = k else 0)|
    return max(abs(sum(wi * fj[i] * fk[i] for i, wi in enumerate(w)) - (j == k))
               for j, fj in enumerate(funcs) for k, fk in enumerate(funcs))

def legendre(n, t):                   # P_n(t), by Bonnet's rule
    p0, p1 = 1.0, t
    for k in range(1, n):
        p0, p1 = p1, ((2 * k + 1) * t * p1 - k * p0) / (k + 1)
    return p1 if n else 1.0

def gauss(n):                         # Gauss-Legendre nodes and weights on [-1, 1]
    out = []
    for i in range(n):
        t = math.cos(math.pi * (i + 0.75) / (n + 0.5))
        for _ in range(50):           # Newton's method on P_n
            d = n * (t * legendre(n, t) - legendre(n - 1, t)) / (t * t - 1)
            t -= legendre(n, t) / d
        out.append((t, 2 / ((1 - t * t) * d * d)))
    return out

def rank(rows):                       # Gaussian elimination, partial pivoting
    rows, r = [list(x) for x in rows], 0
    for c in range(len(rows[0]) if rows else 0):
        p = max(range(r, len(rows)), key=lambda i: abs(rows[i][c]), default=None)
        if p is None or abs(rows[p][c]) < 1e-9:
            continue
        rows[r], rows[p] = rows[p], rows[r]
        for i in range(r + 1, len(rows)):
            f = rows[i][c] / rows[r][c]
            rows[i] = [x - f * y for x, y in zip(rows[i], rows[r])]
        r += 1
    return r

clean = lambda v: 0.0 if abs(v) < 5e-7 else v                   # print -0.000000 as 0.000000
yn = lambda c: "yes" if c else "no"
# ---- 1. the triangle's six symmetries S3, in the basis of two corners 120 degrees apart ----
A, B = [[0, -1], [1, -1]], [[0, 1], [1, 0]]          # turn by 120 degrees; swap the corners
G = [[[1, 0], [0, 1]]]
for g in G:                                          # grows while read: closure under A, B
    for s in (A, B):
        if mul(g, s) not in G:
            G.append(mul(g, s))
n = len(G)
M = [[sum(mul(tp(g), g)[i][j] for g in G) / n for j in range(2)] for i in range(2)]
inv_gap = max(abs(mul(mul(tp(g), M), g)[i][j] - M[i][j]) for g in G for i in range(2) for j in range(2))
raw11 = sum(g[0][0] ** 2 for g in G) / n
l11 = math.sqrt(M[0][0]); l21 = M[1][0] / l11; l22 = math.sqrt(M[1][1] - l21 * l21)
U = [mul(mul([[l11, l21], [0, l22]], g), [[1 / l11, -l21 / (l11 * l22)], [0, 1 / l22]]) for g in G]
sign = [g[0][0] * g[1][1] - g[0][1] * g[1][0] for g in G]
ents = [[u[i][j] for u in U] for i in range(2) for j in range(2)]
basis = [[1.0] * n, [float(s) for s in sign]] + [[math.sqrt(2) * v for v in e] for e in ents]
gap6 = gram_gap(basis, [1 / n] * n)
f = [1.0 if g == B else 0.0 for g in G]              # the single move B: swap two corners
c = [sum(fi * ei for fi, ei in zip(f, e)) / n for e in basis]
rebuilt = [sum(ck * e[k] for ck, e in zip(c, basis)) for k in range(n)]
plain = [[1.0] * n, [float(s) for s in sign]] + ents  # the entries without the factor sqrt(2)
at_b = sum(sum(fi * ei for fi, ei in zip(f, e)) / n * e[G.index(B)] for e in plain)
print(f"S3: closure of the turn and the swap gives {n} matrices; 1^2 + 1^2 + 2^2 = {1 + 1 + 4}")
print(f"Haar average of g^T g: [[{M[0][0]:.6f}, {M[0][1]:.6f}], [{M[1][0]:.6f}, {M[1][1]:.6f}]]")
print(f"every move keeps that inner product: {yn(inv_gap < 1e-12)}")
print(f"before averaging, mean of (entry 1,1)^2 = {raw11:.6f}, not 1/2 = 0.500000")
print(f"after: 1, sign, sqrt(2) x 4 entries are orthonormal on S3: {yn(gap6 < 1e-12)}")
print(f"single swap rebuilt from 6 coefficients, worst error below 1e-12: "
      f"{yn(max(abs(a - b) for a, b in zip(rebuilt, f)) < 1e-12)}")
print(f"Parseval: sum of squared coefficients {sum(x * x for x in c):.6f} = mean of f^2 {sum(x * x for x in f) / n:.6f}")
print(f"mistake, no sqrt(d) weight: rebuilt value at the swap {at_b:.6f}, not 1")
# ---- 2. the 12-hour clock Z/12: twelve characters, each a 1-by-1 matrix ----
gap12 = max(abs(sum(math.cos(2 * math.pi * (j - k) * m / 12) for m in range(12)) / 12 - (j == k))
            + abs(sum(math.sin(2 * math.pi * (j - k) * m / 12) for m in range(12)) / 12)
            for j in range(12) for k in range(12))
print(f"Z/12: 12 characters orthonormal: {yn(gap12 < 1e-12)}; 12 x 1^2 = {12 * 1}")
# ---- 3. rotations SO(3): Haar measure in Euler angles is sin(beta), over 8 pi^2 ----
rz = lambda a: [[math.cos(a), -math.sin(a), 0], [math.sin(a), math.cos(a), 0], [0, 0, 1]]
ry = lambda b: [[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]]
Rs, w = [], []
for t, wt in gauss(6):                               # t = cos(beta), so sin(beta) d(beta) = dt
    for i in range(8):
        for j in range(8):
            Rs.append(mul(mul(rz(2 * math.pi * i / 8), ry(math.acos(t))), rz(2 * math.pi * j / 8)))
            w.append(wt / 2 / 64)
so3 = [[1.0] * len(Rs)] + [[math.sqrt(3) * R[i][j] for R in Rs] for i in range(3) for j in range(3)]
gap10 = gram_gap(so3, w)
uniform = sum(3 * math.cos(math.pi * (k + 0.5) / 12) ** 2 for k in range(12)) / 12
haar33 = sum(wi * 3 * R[2][2] ** 2 for wi, R in zip(w, Rs))
print(f"SO(3): Haar mass {sum(w):.6f}; 1 and sqrt(3) x 9 rotation entries orthonormal: {yn(gap10 < 1e-12)}")
print(f"mistake, Euler angles averaged evenly: mean of 3 R33^2 = {uniform:.6f}, Haar gives {haar33:.6f}")
# ---- 4. degree-l spherical harmonics: harmonic polynomials, counted two ways ----
monos = lambda d: [(a, b, d - a - b) for a in range(d + 1) for b in range(d + 1 - a)]
gl8 = gauss(8)
for l in range(5):
    tgt = monos(l - 2) if l >= 2 else []
    lap = [[sum(e[q] * (e[q] - 1) for q in range(3)
                if tuple(e[r] - 2 * (r == q) for r in range(3)) == m) for m in tgt] for e in monos(l)]
    harm = len(monos(l)) - (rank(lap) if tgt else 0)
    hs = (2 * l + 1) ** 2 * sum(wt * legendre(l, t) ** 2 for t, wt in gl8) / 2
    print(f"degree {l}: {len(monos(l))} monomials, harmonic {harm}, Legendre kernel {hs:.6f}, SO(3) block {(2 * l + 1) ** 2}")
    assert harm == 2 * l + 1 and abs(hs - harm) < 1e-9
print(f"up to degree 3: sphere {sum(2 * l + 1 for l in range(4))} numbers, SO(3) {sum((2 * l + 1) ** 2 for l in range(4))}")
# ---- 5. a globe's temperature, 30 - 40 z^2 degC (illustrative), and the same pattern tilted 30 degrees ----
pts, pw = [], []
for t, wt in gauss(6):
    for k in range(12):
        ph = 2 * math.pi * k / 12
        pts.append((math.sqrt(1 - t * t) * math.cos(ph), math.sqrt(1 - t * t) * math.sin(ph), t))
        pw.append(wt / 2 / 12)
temp = lambda p: 30 - 40 * p[2] ** 2
tilt = lambda p: 30 - 40 * (p[2] * math.cos(math.pi / 6) - p[0] * math.sin(math.pi / 6)) ** 2
for name, T in (("upright", temp), ("tilted 30 deg", tilt)):
    v = [T(p) for p in pts]
    E = [(2 * l + 1) * sum(pw[a] * pw[b] * legendre(l, sum(x * y for x, y in zip(pts[a], pts[b]))) * v[a] * v[b]
                           for a in range(len(pts)) for b in range(len(pts))) for l in range(4)]
    ms = sum(wi * x * x for wi, x in zip(pw, v))
    print(f"{name}: north pole {clean(T((0, 0, 1))):.6f} degC; energy by degree 0-3: "
          + ", ".join(f"{clean(e):.6f}" for e in E) + f"; total {sum(E):.6f}; mean square {ms:.6f}")
    assert abs(E[0] - 2500 / 9) < 1e-9 and abs(E[2] - 1280 / 9) < 1e-9     # hand fractions
    assert abs(E[1]) < 1e-9 and abs(E[3]) < 1e-9 and abs(sum(E) - ms) < 1e-9 and abs(ms - 420) < 1e-9
print(f"hand fractions: 50/3 = {50 / 3:.6f}; (50/3)^2 = 2500/9 = {2500 / 9:.6f}; 1280/9 = {1280 / 9:.6f}; sum 420")
# ---- 6. no compact group, no average: the shear [[1, 1], [0, 1]] on the whole numbers ----
v, lens = [0, 1], []
for k in range(1, 101):
    v = [v[0] + v[1], v[1]]
    lens += [math.sqrt(v[0] ** 2 + v[1] ** 2)] if k in (1, 10, 100) else []
print("mistake, shear on the integers: length of S^n (0, 1) at n = 1, 10, 100: " + ", ".join(f"{x:.6f}" for x in lens))
assert n == 1 + 1 + 2 * 2 and inv_gap < 1e-12 and abs(raw11 - 0.5) > 0.1  # count; average works; raw fails
assert gap6 < 1e-12 and gap12 < 1e-12 and gap10 < 1e-12                    # Schur orthogonality, three groups
assert abs(sum(x * x for x in c) - 1 / 6) < 1e-12 and abs(at_b - 1) > 0.1
assert abs(uniform - 1.5) < 1e-12 and abs(haar33 - 1) < 1e-12 and lens[2] > 100
print("ALL CHECKS PASS")
