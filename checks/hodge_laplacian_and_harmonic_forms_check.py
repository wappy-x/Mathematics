# Hodge Laplacian and harmonic forms -- the check behind the card.  Standard library only.
# A flat torus 40,000 km by 20,000 km.  Roads to its hole count b = (1, 2, 1):
#   road 1: zero modes of the Hodge Laplacian's Fourier spectrum
#   road 2: exact kernel of a grid Hodge Laplacian (rank mod a prime, plus kernel vectors)
#   road 3: the Euler count V - E + F against b0 - b1 + b2
# A cube stands in for the globe: b = (1, 0, 1).  Then the example's split, by sampling.
from math import sin, cos, pi

L1, L2 = 40000.0, 20000.0                      # the torus's two circles, km
P = 1_000_000_007                              # a prime: ranks mod P bound the true ranks
def f6(x): return "%.6f" % (0.0 if abs(x) < 5e-7 else x)

def rank_mod_p(A):                             # row reduction with arithmetic mod P
    A = [[x % P for x in row] for row in A]; r = 0
    for c in range(len(A[0])):
        piv = next((i for i in range(r, len(A)) if A[i][c]), None)
        if piv is None: continue
        A[r], A[piv] = A[piv], A[r]
        inv = pow(A[r][c], P - 2, P); A[r] = [x * inv % P for x in A[r]]
        for i in range(r + 1, len(A)):
            if A[i][c]:
                f = A[i][c]; A[i] = [(x - f * y) % P for x, y in zip(A[i], A[r])]
        r += 1
    return r

def mul(A, B): return [[sum(a * b for a, b in zip(row, col)) for col in zip(*B)] for row in A]
def tr(A): return [list(r) for r in zip(*A)]

def build(nv, edges, faces):                   # d0: functions -> 1-forms, d1: 1-forms -> 2-forms
    look = {}
    for k, (a, b) in enumerate(edges): look[(a, b)] = (k, 1); look[(b, a)] = (k, -1)
    d0 = [[0] * nv for _ in edges]
    for k, (a, b) in enumerate(edges): d0[k][a] -= 1; d0[k][b] += 1
    d1 = [[0] * len(edges) for _ in faces]
    for f, cyc in enumerate(faces):
        for a, b in zip(cyc, cyc[1:] + cyc[:1]):
            k, s = look[(a, b)]; d1[f][k] += s
    return d0, d1

def grid(n1, n2):                              # n1 x n2 square cells, opposite edges glued
    v = lambda i, j: i % n1 + n1 * (j % n2)
    E = [(v(i, j), v(i + 1, j)) for j in range(n2) for i in range(n1)] + \
        [(v(i, j), v(i, j + 1)) for j in range(n2) for i in range(n1)]
    F = [[v(i, j), v(i + 1, j), v(i + 1, j + 1), v(i, j + 1)] for j in range(n2) for i in range(n1)]
    return n1 * n2, E, F

def cube():                                    # the globe, flattened onto a cube's six faces
    E = [(a, a | 1 << t) for t in range(3) for a in range(8) if not a >> t & 1]
    F = []
    for t in range(3):
        u, w = [1 << s for s in range(3) if s != t]
        for side in (0, 1):
            b = side << t; F.append([b, b ^ u, b ^ u ^ w, b ^ w])
    return 8, E, F

def hodge_counts(nv, E, F):                    # nullities of the three Hodge Laplacians
    d0, d1 = build(nv, E, F)
    assert all(x == 0 for row in mul(d1, d0) for x in row)       # d after d is zero
    up, down = mul(d0, tr(d0)), mul(tr(d1), d1)                   # d delta and delta d
    L1 = [[a + b for a, b in zip(r, s)] for r, s in zip(up, down)]
    L0, L2 = mul(tr(d0), d0), mul(d1, tr(d1))
    null = [len(M) - rank_mod_p(M) for M in (L0, L1, L2)]
    return null, (len(up) - rank_mod_p(up), len(down) - rank_mod_p(down)), L1

def apply(M, v): return [sum(a * b for a, b in zip(row, v)) for row in M]

print("torus %.0f km by %.0f km, area %.0f km^2" % (L1, L2, L1 * L2))
# road 1: Fourier.  e^{2 pi i (m x/L1 + n y/L2)} times a basis form has eigenvalue lam(m, n)
lam = lambda m, n: (2 * pi * m / L1) ** 2 + (2 * pi * n / L2) ** 2
zero_modes = sum(1 for m in range(-4, 5) for n in range(-4, 5) if lam(m, n) == 0.0)
fourier = [zero_modes * comps for comps in (1, 2, 1)]           # 1, 2, 1 basis forms per degree
print("road 1 Fourier zero modes in degrees 0 1 2:", *fourier)
print("lowest nonzero eigenvalues x 1e8 per km^2: %s (east-west), %s (north-south)"
      % (f6(lam(1, 0) * 1e8), f6(lam(0, 1) * 1e8)))
# road 2: grid Hodge Laplacian on 8 x 4 cells of 5000 km
nv, E, F = grid(8, 4)
null, drop, L1g = hodge_counts(nv, E, F)
N = 32; dx, dy = [1] * N + [0] * N, [0] * N + [1] * N           # the two constant 1-forms
assert apply(L1g, dx) == [0] * 64 and apply(L1g, dy) == [0] * 64  # kernel has dimension >= 2
assert null == fourier                                             # so mod-P nullity 2 is exact
print("road 2 grid 8 x 4 of %.0f km: V E F = %d %d %d, harmonic counts" % (L1 / 8, nv, len(E), len(F)), *null)
print("dropping delta d leaves %d; dropping d delta leaves %d" % drop)
assert drop == (len(E) - (nv - 1), len(E) - (len(F) - 1))       # closed or coclosed cochains
chi = nv - len(E) + len(F); assert chi == null[0] - null[1] + null[2]
print("road 3 Euler count V - E + F = %d = b0 - b1 + b2" % chi)
cv, cE, cF = cube(); cnull, _, _ = hodge_counts(cv, cE, cF)
assert cnull == [1, 0, 1]; assert cv - len(cE) + len(cF) == cnull[0] - cnull[1] + cnull[2]
print("cube (globe): V E F = %d %d %d, harmonic counts" % (cv, len(cE), len(cF)), *cnull)
tnull, tdrop, _ = hodge_counts(*grid(12, 6))
assert tnull == null
print("try grid 12 x 6: harmonic counts", *tnull, "| dropping delta d leaves", tdrop[0])

def eig_check(n1, n2):                         # grid Laplacian on the cochain of cos(kx) dx
    nv, E, F = grid(n1, n2); _, _, L = hodge_counts(nv, E, F)
    h, k = L1 / n1, 2 * pi / L1
    c = [(sin(k * (i + 1) * h) - sin(k * i * h)) / k for j in range(n2) for i in range(n1)] + [0.0] * (n1 * n2)
    ratios = [a / b for a, b in zip(apply(L, c), c) if abs(b) > 1e-6]
    assert max(ratios) - min(ratios) < 1e-9                        # an eigenvector of the grid
    assert abs(ratios[0] - 4 * sin(k * h / 2) ** 2) < 1e-12         # discrete Fourier formula
    return ratios[0] / h ** 2
e8, e16, ex = eig_check(8, 4), eig_check(16, 8), lam(1, 0)
assert (ex - e8) / (ex - e16) > 3.9
print("grid eigenvalue x 1e8: 8x4 %s, 16x8 %s, smooth %s; error ratio %.2f"
      % (f6(e8 * 1e8), f6(e16 * 1e8), f6(ex * 1e8), (ex - e8) / (ex - e16)))

# the example: wind form (1 + sin(2 pi x / L1)) dx, sampled at 64 points round the long loop
k, M = 2 * pi / L1, 64
xs = [L1 * i / M for i in range(M)]
u = [1 + sin(k * x) for x in xs]
a = sum(u) / M                                 # harmonic part: the average coefficient
s1 = 2 * sum(ui * sin(k * x) for ui, x in zip(u, xs)) / M
amp = s1 / k                                   # exact part = d(-amp cos(kx))
pot = lambda x: -amp * cos(k * x)
x0 = 5000.0; slope = (pot(x0 + 0.5) - pot(x0 - 0.5)) / 1.0
assert abs(a - 1) < 1e-12 and abs(amp - L1 / (2 * pi)) < 1e-8 and abs(slope - sin(k * x0)) < 1e-6
print("harmonic part %s dx + %s dy; sine share %s; potential amplitude L1/2pi %s km"
      % (f6(a), f6(0.0), f6(s1), f6(amp)))
print("at x = 5000 km: wind %s = harmonic %s + exact %s (slope of potential)"
      % (f6(1 + sin(k * x0)), f6(a), f6(slope)))
loop = sum(u) * L1 / M                         # the short loop's integral is 0: no dy part
print("long loop integral %s km m/s, average tailwind %s m/s" % (f6(loop), f6(loop / L1)))
ms = [sum(v * v for v in u) / M, a * a, sum((s1 * sin(k * x)) ** 2 for x in xs) / M, sum(a * s1 * sin(k * x) for x in xs) / M]
assert abs(ms[0] - 1.5) < 1e-12 and abs(ms[2] - 0.5) < 1e-12 and abs(ms[3]) < 1e-12 and abs(ms[0] - ms[1] - ms[2]) < 1e-12
print("mean squares: form %s = harmonic %s + exact %s; cross term %s" % tuple(f6(m) for m in ms))
print("wrong: harmonic part read at x = 10000 km gives %s" % f6(1 + sin(k * 10000.0)))
# a crosswind cos(2 pi y / L2) dx is coexact: delta of b dx^dy, b = (L2/2pi) sin(2 pi y/L2)
q = 2 * pi / L2; b = lambda y: sin(q * y) / q
y0 = 2500.0; dbdy = (b(y0 + 0.5) - b(y0 - 0.5)) / 1.0
assert abs(dbdy - cos(q * y0)) < 1e-6
print("coexact: L2/2pi %s km; delta(beta) at y = 2500 km %s; curl x 1000 km %s"
      % (f6(1 / q), f6(dbdy), f6(q * sin(q * 5000.0) * 1000)))
print("plane: dx = d(x) is harmonic and exact; torus: dx round the long loop %s km, not exact"
      % f6(sum(dx[:8]) * L1 / 8))
u3 = [1 + 3 * sin(k * x) for x in xs]
print("try 1 + 3 sin: harmonic %s, potential amplitude %s km, mean square %s" % (f6(sum(u3) / M),
      f6(2 * sum(v * sin(k * x) for v, x in zip(u3, xs)) / M / k), f6(sum(v * v for v in u3) / M)))
cx = [5000 * i for i in range(9)]
for name, g in (("wind", lambda x: 1 + sin(k * x)), ("exact", lambda x: sin(k * x))):
    print("chart " + name + ":", *["%.2f" % (0.0 if abs(g(x)) < 5e-3 else g(x)) for x in cx])
print("ALL CHECKS PASS")
