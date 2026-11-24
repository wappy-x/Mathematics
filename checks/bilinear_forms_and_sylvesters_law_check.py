# Bilinear forms and Sylvester's law -- the check behind the card.  Standard library only.  The pass: q = x^2 + 4xy + y^2,
# B = [[1, 2], [2, 1]]: sign counts three ways on B and every P^T B P; area two ways; ranks by elimination and by Step 5's pairs.
from fractions import Fraction
from math import sqrt, cos, sin, pi
B, P, OM, NUM = [[1, 2], [2, 1]], [[1, -2], [0, 1]], [[0, 1], [-1, 0]], range(-2, 3)
def mul(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def tr(X): return [list(r) for r in zip(*X)]
def form(M, v, w): return sum(v[i] * M[i][j] * w[j] for i in range(len(v)) for j in range(len(w)))
def det2(M): return M[0][0] * M[1][1] - M[0][1] * M[1][0]
def counts(vals): return (sum(v > 0 for v in vals), sum(v < 0 for v in vals), sum(v == 0 for v in vals))
def squares(M): return [Fraction(M[0][0]), Fraction(det2(M), M[0][0])]   # road one: a(x + b/a y)^2 + (det/a) y^2
def eigs(M): return [t / 2 + s * sqrt(t * t / 4 - det2(M)) for t in [M[0][0] + M[1][1]] for s in (1, -1)]  # road two
def sweep(M): return counts([form(M, [cos(a), sin(a)], [cos(a), sin(a)]) for a in (pi * (k + 0.5) / 360 for k in range(720))])[:2]  # road three
def rank(M):                                                             # elimination in exact fractions
    M, r = [[Fraction(x) for x in row] for row in M], 0
    for c in range(len(M[0])):
        i = next((i for i in range(r, len(M)) if M[i][c] != 0), None)
        if i is None: continue
        M[r], M[i] = M[i], M[r]
        for j in range(r + 1, len(M)): M[j] = [a - M[j][c] / M[r][c] * b for a, b in zip(M[j], M[r])]
        r += 1
    return r
def pairs(S):       # Step 5: split off u, w with c = w(u, w) not 0; each other v becomes c v - w(v, w) u + w(v, u) w
    om, V, k = (lambda v, w: form(S, v, w)), [[int(i == j) for j in range(len(S))] for i in range(len(S))], 0
    while uw := next(((u, w) for u in V for w in V if om(u, w)), None):
        V, k = [[om(*uw) * a - om(v, uw[1]) * b + om(v, uw[0]) * d for a, b, d in zip(v, *uw)] for v in V if v is not uw[0] and v is not uw[1]], k + 1
    return k, V                                                          # pairs found, and the vectors where the form is zero
def rnd(s=[2026]): s[0] = (s[0] * 1103515245 + 12345) % 2**31; return s[0] % 7 - 3   # a written-out random -3 to 3
q = lambda x, y: form(B, [x, y], [x, y])
D, Q, s3 = mul(mul(tr(P), B), P), [[1 / sqrt(2), 1 / sqrt(2)], [1 / sqrt(2), -1 / sqrt(2)]], 1 / sqrt(3)
T, sw = mul(mul(tr(Q), B), Q), sweep(B)
print(f"matrix B rows (1, 2) and (2, 1); q(1, 0) = {q(1, 0)}, q(1, 1) = {q(1, 1)}, q(1, -1) = {q(1, -1)}")
print(f"pairing B(e1, e2) = {form(B, [1, 0], [0, 1])}; from heights, (q(1, 1) - q(1, 0) - q(0, 1)) / 2 = {(q(1, 1) - q(1, 0) - q(0, 1)) // 2}")
print(f"completed square: P = {P}, P^T B P = {D}; at (1, -1), s = -1, t = -1, s^2 - 3t^2 = {form(D, [-1, -1], [-1, -1])}")
print(f"second arrow shortened by 1/sqrt(3) = {s3:.6f}: diagonal {D[0][0]:.6f} and {D[1][1] * s3 * s3:.6f}")
print(f"eigenvalues from trace 2 and determinant {det2(B)}: {eigs(B)[0]:.6f} and {eigs(B)[1]:.6f}")
print(f"turned grid (1, 1)/sqrt(2), (1, -1)/sqrt(2): diagonal {T[0][0]:.6f} and {T[1][1]:.6f}, corner {abs(T[0][1]):.6f}")
print(f"sign counts (plus, minus, zero): squares {counts(squares(B))}, eigenvalues {counts(eigs(B))}; directions up {sw[0]}, down {sw[1]} of 720")
regrid = [(R, mul(mul(tr(R), B), R)) for R in ([[a, b], [c, d]] for a in NUM for b in NUM for c in NUM for d in NUM if a * d - b * c)]
ok = all(counts(squares(C)) == counts(eigs(C)) == (1, 1, 0) and min(sweep(C)) > 0 for _, C in regrid)
dets, tops = all(det2(C) == det2(R) ** 2 * det2(B) for R, C in regrid), {round(eigs(C)[0], 6) for _, C in regrid}
print(f"{len(regrid)} grids: (1, 1, 0) by all three roads every time: {'yes' if ok else 'no'}; det = det(P)^2 x (-3): {'yes' if dets else 'no'}; different top eigenvalues {len(tops)}")
u, v, S3 = [3, 1], [1, 2], [[0, 1, 2], [-1, 0, 3], [-2, -3, 0]]
base, height = sqrt(u[0] ** 2 + u[1] ** 2), sqrt(sum((v[i] - (u[0] * v[0] + u[1] * v[1]) / (u[0] ** 2 + u[1] ** 2) * u[i]) ** 2 for i in range(2)))  # v minus its shadow on u
print(f"signed area of legs (3, 1), (1, 2): ad - bc = {form(OM, u, v)}; legs swapped {form(OM, v, u)}; a leg with itself {form(OM, u, u)}",
      f"base x height by dot products: {base:.6f} x {height:.6f} = {base * height:.6f}", sep="\n")
skews = [[[0] * m for _ in range(m)] for m in [2, 3, 4, 5, 6] * 50]
for S, i, j in [(S, i, j) for S in skews for i in range(len(S)) for j in range(i + 1, len(S))]: S[i][j] = rnd(); S[j][i] = -S[i][j]
seen = [(len(S), rank(S), 2 * pairs(S)[0]) for S in skews]               # rank by elimination, and twice the pairs
print(f"250 random skew matrices, (size, rank) seen: {sorted({(m, r) for m, r, _ in seen})}; rank = 2 x pairs every time: {'yes' if all(r == p for _, r, p in seen) else 'no'}")
print(f"Step 5 on {S3}: {pairs(S3)[0]} pair, zero on {pairs(S3)[1][0]}, rank {rank(S3)}; not alternating [[0, 1], [0, 0]]: rank {rank([[0, 1], [0, 0]])}")
X, F = mul(mul([[1, 2], [0, 1]], B), P), mul(mul([[1, 1], [1, 1]], B), [[1, 1], [1, 1]])
print(f"mistake 1, similarity P^-1 B P = {X}, symmetric: {'yes' if X == tr(X) else 'no'}", f"mistake 2, flattening grid P = [[1, 1], [1, 1]]: P^T B P = {F}, counts {counts(eigs(F))}", sep="\n")
print(f"mistake 3, eigenvalues read off P^T B P: {D[0][0]} and {D[1][1]}, not 3 and -1")
assert counts(squares(B)) == counts(eigs(B)) == (1, 1, 0) and sw == (480, 240)
assert ok and dets and len(tops) > 20                                  # the signs never move; the sizes do
assert D == [[1, 0], [0, -3]] and abs(T[0][0] - 3) < 1e-12 and abs(T[1][1] + 1) < 1e-12
assert abs(base * height - form(OM, u, v)) < 1e-12                      # area: two roads
assert all(r == p for _, r, p in seen) and pairs(S3) == (1, [[3, -2, 1]]) and rank(S3) == 2   # ranks: two roads
print("ALL CHECKS PASS")
