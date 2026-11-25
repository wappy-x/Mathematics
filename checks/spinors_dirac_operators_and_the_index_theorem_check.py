# Spinors and the Dirac operator -- the check behind the card.  Standard library only.
# 2x2 matrices are lists of Python complex numbers.  Ranks are exact, in Fractions.  The
# eigenvalues of the 22 x 22 form come from a Jacobi sweep written out here.
import math
from fractions import Fraction

def mul(a, b): return [[sum(a[i][k] * b[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
def lin(*terms): return [[sum(c * m[i][j] for c, m in terms) for j in range(2)] for i in range(2)]
def size(a): return max(abs(a[i][j]) for i in range(2) for j in range(2))
def eig2(a):                                     # roots of the characteristic polynomial
    tr, det = a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]
    r = complex(tr * tr - 4 * det) ** 0.5
    return sorted([((tr - r) / 2).real, ((tr + r) / 2).real])
I, S1, S2, S3 = [[1, 0], [0, 1]], [[0, 1], [1, 0]], [[0, -1j], [1j, 0]], [[1, 0], [0, -1]]
S12 = mul(S1, S2)

rules = [size(lin((1, mul(S1, S1)), (-1, I))), size(lin((1, mul(S2, S2)), (-1, I))), size(lin((1, S12), (1, mul(S2, S1))))]
print("Clifford rules: s1 s1 = 1, s2 s2 = 1, s1 s2 + s2 s1 = 0:", "yes" if max(rules) < 1e-12 else "no")
assert max(rules) < 1e-12 and size(lin((1, S12), (-1j, S3))) < 1e-12 and size(lin((1, mul(mul(S3, S2), mul(S1, S3))), (-1, mul(S2, S1)))) < 1e-12  # s1 s2 = i s3; (e3e2)(e1e3) = e2e1
def spin(t): return lin((math.cos(t / 2), I), (-math.sin(t / 2), S12))   # its inverse is spin(-t)
t = math.pi / 2                                        # a quarter turn in the s1 s2 plane
turned = mul(mul(spin(t), S1), spin(-t))
err = size(lin((1, turned), (-math.cos(t), S1), (-math.sin(t), S2)))
print("g(90 deg) s1 g^-1 = cos(90) s1 + sin(90) s2, to 1e-12:", "yes" if err < 1e-12 else "no")
minus = mul(mul(lin((-1, spin(t))), S1), lin((-1, spin(-t))))
print("g and -g turn s1 the same way:", "yes" if size(lin((1, minus), (-1, turned))) < 1e-12 else "no")
assert err < 1e-12 and size(lin((1, minus), (-1, turned))) < 1e-12
for deg in (360, 720):
    print(f"g after a {deg} degree turn: {spin(math.radians(deg))[0][0].real:.6f} times the identity")
assert abs(spin(2 * math.pi)[0][0] + 1) < 1e-12 and abs(spin(4 * math.pi)[0][0] - 1) < 1e-12

D = {(1, 0): lin((-1j, S1)), (0, 1): lin((-1j, S2))}   # D = -i(s1 d/dx + s2 d/dy)
DD = {(2, 0): mul(D[1, 0], D[1, 0]), (0, 2): mul(D[0, 1], D[0, 1]), (1, 1): lin((1, mul(D[1, 0], D[0, 1])), (1, mul(D[0, 1], D[1, 0])))}
print(f"D squared: d2/dx2 coefficient {DD[2, 0][0][0].real:.0f} | d2/dy2 {DD[0, 2][0][0].real:.0f} | d2/dxdy {size(DD[1, 1]):.0f}")
assert size(lin((1, DD[(2, 0)]), (1, I))) < 1e-12 and size(DD[(1, 1)]) < 1e-12

def mode(m, n): return lin((m, S1), (n, S2))           # D acting on e^{i(mx+ny)} times a spinor
spec = {}
for m in range(-3, 4):
    for n in range(-3, 4):
        for lam in eig2(mode(m, n)):                   # road 2 against road 1, sqrt(m^2 + n^2)
            assert abs(abs(lam) - math.hypot(m, n)) < 1e-9 and size(lin((1, mul(S3, mode(m, n))), (1, mul(mode(m, n), S3)))) < 1e-12
            if abs(lam) < 2.3: spec[round(lam, 6) + 0.0] = spec.get(round(lam, 6) + 0.0, 0) + 1
print("torus eigenvalues with multiplicity:", ", ".join(f"{k:.6f} x{v}" for k, v in sorted(spec.items())))
print(f"chirality s3 anticommutes with D on mode (1, 2): {size(lin((1, mul(S3, mode(1, 2))), (1, mul(mode(1, 2), S3)))):.0f}")
kp, km = [sum(s * v > 0 for v in eig2(S3)) for s in (1, -1)]   # s3 splits the kernel, mode (0, 0), by handedness
print(f"kernel: {spec[0.0]} constant spinors, (1, 0) in S+ and (0, 1) in S-; index of D+ = {kp} - {km} = {kp - km}")
assert spec[0.0] == kp + km and kp == km               # flat torus: curvature integral 0
print(f"try: mode (3, 4) eigenvalues {eig2(mode(3, 4))[0]:.6f} and {eig2(mode(3, 4))[1]:.6f}")

def grid_eig(m, n, N):                                 # D by central differences on a periodic N x N grid
    h = 2 * math.pi / N                                # the wave e^{i(mx+ny)} repeats on the grid, and each
    w = lambda u, v: complex(math.cos(m * u + n * v), math.sin(m * u + n * v))   # stencil returns it times a number,
    dx, dy = (w(h, 0) - w(-h, 0)) / (2 * h), (w(0, h) - w(0, -h)) / (2 * h)       # read off at the origin, where w = 1
    return eig2(lin((-1j * dx, S1), (-1j * dy, S2)))[1]                          # so D acts on it as this 2x2 matrix
errs = [math.sqrt(5) - grid_eig(1, 2, N) for N in (16, 32, 64)]
for N, e in zip((16, 32, 64), errs): print(f"grid {N} x {N}: mode (1, 2) eigenvalue {math.sqrt(5) - e:.6f}, error {e:.6f}")
assert 3.5 < errs[0] / errs[1] < 4.5                   # error falls like h^2

def rank(rows):                                        # exact Gaussian elimination
    rows, r = [[Fraction(v) for v in row] for row in rows], 0
    for c in range(len(rows[0])):
        p = next((i for i in range(r, len(rows)) if rows[i][c] != 0), None)
        if p is None: continue
        rows[r], rows[p] = rows[p], rows[r]
        for i in range(len(rows)):
            if i != r and rows[i][c] != 0:
                f = rows[i][c] / rows[r][c]
                rows[i] = [a - f * b for a, b in zip(rows[i], rows[r])]
        r += 1
    return r
def surface(faces):
    edges = sorted({tuple(sorted((f[a], f[b]))) for f in faces for a, b in ((0, 1), (0, 2), (1, 2))})
    verts = sorted({v for e in edges for v in e})
    d0 = [[(v == e[1]) - (v == e[0]) for v in verts] for e in edges]                     # edges x verts
    d1 = [[(e == (f[1], f[2])) - (e == (f[0], f[2])) + (e == (f[0], f[1])) for e in edges] for f in faces]
    assert all(sum(d1[f][e] * d0[e][v] for e in range(len(edges))) == 0 for f in range(len(faces)) for v in range(len(verts)))
    r0, r1 = rank(d0), rank(d1)                        # (above: the boundary of a boundary is zero)
    betti = (len(verts) - r0, len(edges) - r0 - r1, len(faces) - r1)
    A = [d0[i] + [d1[j][i] for j in range(len(faces))] for i in range(len(edges))]      # d + delta
    At = [list(col) for col in zip(*A)]
    ker_even, ker_odd = len(At) - rank(A), len(A) - rank(At)
    return len(verts), len(edges), len(faces), betti, ker_even, ker_odd
sphere = surface([sorted(f) for f in ((0, 1, 2), (0, 1, 3), (0, 2, 3), (1, 2, 3))])
at = lambda i, j: 3 * (i % 3) + j % 3                  # the 3 x 3 grid torus, two triangles per square
torus = surface([sorted(f) for i in range(3) for j in range(3) for f in ((at(i, j), at(i, j + 1), at(i + 1, j + 1)), (at(i, j), at(i + 1, j), at(i + 1, j + 1)))])
for name, (V, E, F, b, ke, ko) in (("sphere", sphere), ("torus", torus)):
    print(f"{name}: V - E + F = {V} - {E} + {F} = {V - E + F}; b = {b}; b0 - b1 + b2 = {b[0] - b[1] + b[2]}")
    print(f"{name}: d + delta kernel on even forms {ke}, on odd forms {ko}, index {ke - ko}")
    assert ke - ko == V - E + F == b[0] - b[1] + b[2] and (ke, ko) == (b[0] + b[2], b[1])
def gauss_bonnet(a, c, n):                             # total curvature of a spheroid / 2 pi
    tot = 0.0
    for k in range(n):
        p = (k + 0.5) * math.pi / n
        K = 1 / (a ** 4 * c * c * (math.sin(p) ** 2 / a ** 2 + math.cos(p) ** 2 / c ** 2) ** 2)
        tot += K * a * math.sin(p) * math.sqrt(c * c * math.sin(p) ** 2 + a * a * math.cos(p) ** 2) * math.pi / n
    return tot
for a, c, n in ((2, 1, 20), (2, 1, 40), (1, 0.1, 40)): print(f"spheroid a = {a}, c = {c}, {n} steps: total curvature / 2 pi = {gauss_bonnet(a, c, n):.6f}")
gb20, gb40 = gauss_bonnet(2, 1, 20) - 2, gauss_bonnet(2, 1, 40) - 2
assert abs(gb40) < 5e-4 and 3.5 < gb20 / gb40 < 4.5     # converges to 2 like h^2

def jacobi(A):                                         # eigenvalues of a symmetric matrix
    A, n = [row[:] for row in A], len(A)
    for _ in range(60):
        for p in range(n):
            for q in range(p + 1, n):
                if abs(A[p][q]) < 1e-15: continue
                th = 0.5 * math.atan2(2 * A[p][q], A[q][q] - A[p][p])
                c, s = math.cos(th), math.sin(th)
                for k in range(n): A[k][p], A[k][q] = c * A[k][p] - s * A[k][q], s * A[k][p] + c * A[k][q]
                for k in range(n): A[p][k], A[q][k] = c * A[p][k] - s * A[q][k], s * A[p][k] + c * A[q][k]
    return [A[i][i] for i in range(n)]
E8 = [[2 if i == j else -1 if {i, j} in ({0, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 6}, {6, 7}, {1, 3}) else 0
       for j in range(8)] for i in range(8)]
blocks = [[[-v for v in row] for row in E8]] * 2 + [[[0, 1], [1, 0]]] * 3
Q, o = [[0] * 22 for _ in range(22)], 0
for b in blocks:
    for i, j in ((i, j) for i in range(len(b)) for j in range(len(b))): Q[o + i][o + j] = b[i][j]
    o += len(b)
ev = jacobi(Q)
pos, neg = sum(v > 1e-9 for v in ev), sum(v < -1e-9 for v in ev)
chi, p1 = 2 + 22, 0 - 2 * (2 + 22)                     # c2 = chi, c1 = 0, p1 = c1^2 - 2 c2
print(f"K3 intersection form: {pos} positive, {neg} negative eigenvalues; signature {pos - neg}")
print(f"K3 from curvature: chi = {chi}, p1 = {p1}, signature = p1/3 = {p1 // 3}, A-hat = -p1/24 = {-p1 // 24}")
assert 3 * (pos - neg) == p1                           # the signature theorem: the two roads agree
c1, c2 = 3, 3                                          # CP2: c = 1 + 3h + 3h^2, signature 1
print(f"CP2: signature 1, p1 = {c1 * c1 - 2 * c2}, p1/3 = {(c1 * c1 - 2 * c2) / 3:.6f}, A-hat = -p1/24 = {-(c1 * c1 - 2 * c2) / 24:.6f} (not whole: CP2 is not spin)")
print(f"unit sphere: S = 2, Lichnerowicz S/4 = {2 / 4:.6f}, Friedrich nS/(4(n-1)) = {2 * 2 / 4:.6f}")
mono = [f"z^{k}" for k in range(3 + 1)]               # polynomials of degree <= 3 on the sphere
print(f"Riemann-Roch on the sphere, degree 3: sections {', '.join(mono)} count {len(mono)}; d - g + 1 = {3 - 0 + 1}")
hv = 6.62607015e-34 * 1.0e6 / 1.602176634e-19         # h v_F in eV m
for L in (100e-9, 200e-9): print(f"graphene flake {L * 1e9:.0f} nm: levels {1000 * hv / L:.4f} and {1000 * hv / L * math.sqrt(2):.4f} meV")
same, no_i = lin((1, S1), (1, S1)), lin((1j, S1), (1j, S2))     # mode (1, 1) with each mistake
print(f"mistake: commuting s1, s1 on mode (1, 1): D squared gives {eig2(mul(same, same))[1]:.0f}, not 2")
print(f"mistake: no -i, (s1 dx + s2 dy) squared on mode (1, 1) gives {eig2(mul(no_i, no_i))[1]:.0f}, not 2")
V, E, F = surface([[0, 1, 2]])[:3]
print(f"mistake: one flat triangle, a disc: V - E + F = {V} - {E} + {F} = {V - E + F}, total curvature / 2 pi = 0")
print(f"mistake: no 1/4 in Lichnerowicz: bound {2:.6f} above the true smallest eigenvalue squared {1:.6f}")
print("ALL CHECKS PASS")
