# Schur's triangle -- the check behind the card.  Only math is imported (cos, sin, sqrt).
# A has the eigenvalue 2 twice and one eigenvector line, yet perpendicular axes make it
# upper triangular.  Road one builds the axes from the eigenvector; road two scans turned
# axes and never solves for an eigenvalue.  A^10 is found twice; R needs complex axes.
from math import cos, sin, pi, sqrt
A, R = [[1, 1], [-1, 3]], [[0, -1], [1, 0]]
def mul(X, Y): return [[sum(X[i][k] * Y[k][j] for k in (0, 1)) for j in (0, 1)] for i in (0, 1)]
def star(X): return [[complex(X[j][i]).conjugate() for j in (0, 1)] for i in (0, 1)]
def cl(x): return 0.0 if abs(x) < 5e-7 else x                  # never print "-0.000000"
def f(x, d=6): return f"{cl(complex(x).real):.{d}f}"
def show(X, d=6): return "[" + ", ".join("[" + ", ".join(f(v, d) for v in r) + "]" for r in X) + "]"
def cs(z): return f"{f(z, 0)}{'-' if cl(z.imag) < 0 else '+'}{abs(cl(z.imag)):.0f}i"

def schur(M):                     # road one: eigenvalue, eigenvector, perpendicular partner
    tr, det = M[0][0] + M[1][1], M[0][0] * M[1][1] - M[0][1] * M[1][0]
    disc = tr * tr - 4 * det
    lam = (tr + (sqrt(disc) if disc >= 0 else 1j * sqrt(-disc))) / 2
    v = (M[0][1], lam - M[0][0])                 # kills the shifted top row (a - lam, b)
    n = sqrt(abs(v[0]) ** 2 + abs(v[1]) ** 2)
    q1 = (v[0] / n, v[1] / n)
    Q = [[q1[0], complex(q1[1]).conjugate()], [q1[1], -complex(q1[0]).conjugate()]]
    return tr, det, disc, lam, v, Q, mul(mul(star(Q), M), Q)

def turned(M, c, s, flip): Q = [[c, s if flip else -s], [s, -c if flip else c]]; return mul(mul(star(Q), M), Q)
def low(M, flip): return [abs(turned(M, cos(k * pi / 18000), sin(k * pi / 18000), flip)[1][0]) for k in range(18000)]
def sq(X): return sum(abs(v) ** 2 for r in X for v in r)
tr, det, disc, lam, v, Q, T = schur(A)
scan = low(A, False); k = scan.index(min(scan)); T2 = turned(A, cos(k * pi / 18000), sin(k * pi / 18000), False)
P = A
for _ in range(9): P = mul(P, A)                                 # A^10, ten factors of A
L, b = T[0][0], T[0][1]
P2 = mul(mul(Q, [[L ** 10, 10 * L ** 9 * b], [0, L ** 10]]), star(Q))  # T^10 by formula
corner = sqrt(sq(A) - abs(T[0][0]) ** 2 - abs(T[1][1]) ** 2)
rt, _, rdisc, rl, _, RQ, RT = schur(R)
real_best = min(min(low(R, False)), min(low(R, True)))
B1 = mul(mul(star([[1, 1], [1, 0]]), A), [[1, 1], [1, 0]]); B2 = mul(mul(star([[1, 1], [1, -1]]), A), [[1, 1], [1, -1]])
print(f"A = {show(A, 0)}  trace {f(tr)}  determinant {f(det)}  discriminant {f(disc)}")
print(f"eigenvalue {f(lam)} twice; A - 2I = {show([[A[0][0] - lam, A[0][1]], [A[1][0], A[1][1] - lam]], 0)}; eigenvector ({f(v[0], 0)}, {f(v[1], 0)})")
print(f"q1 = ({f(Q[0][0])}, {f(Q[1][0])})  q2 = ({f(Q[0][1])}, {f(Q[1][1])})  Q*Q = {show(mul(star(Q), Q))}")
AQ = mul(A, Q); print(f"A q1 = ({f(AQ[0][0])}, {f(AQ[1][0])})  A q2 = ({f(AQ[0][1])}, {f(AQ[1][1])})")
print(f"road one, T = Q*AQ = {show(T)}")
print(f"diagonal sum {f(T[0][0] + T[1][1])} = trace, product {f(T[0][0] * T[1][1])} = determinant")
print(f"road two, turned axes: lower-left smallest {f(scan[k])} at {k / 100:.2f} degrees, T = {show(T2)}")
print(f"squared entries: A {f(sq(A))}, T {f(sq(T))}, so the corner has size {f(corner)}")
print(f"A^10 by ten multiplications = {show(P, 0)}")
print(f"A^10 as Q T^10 Q*            = {show(P2, 0)}")
print(f"quarter turn R = {show(R, 0)}: discriminant {f(rdisc)}, eigenvalues {cs(rl)} and {cs(rt - rl)}")
print(f"real axes, turned or flipped: lower-left never below {f(real_best)}")
print(f"complex axes: sqrt2 q1 = ({cs(RQ[0][0] * sqrt(2))}, {cs(RQ[1][0] * sqrt(2))}), sqrt2 q2 = "
      f"({cs(RQ[0][1] * sqrt(2))}, {cs(RQ[1][1] * sqrt(2))}), T = [[{cs(RT[0][0])}, {cs(RT[0][1])}], [{cs(RT[1][0])}, {cs(RT[1][1])}]]")
print(f"mistake 1, axes (1, 1) and (1, 0), transpose as inverse: {show(B1, 0)}, diagonal sum {f(B1[0][0] + B1[1][1], 0)}")
print(f"mistake 2, axes not shrunk to length 1: {show(B2, 0)}, diagonal {f(B2[0][0], 0)} and {f(B2[1][1], 0)}")
print(f"mistake 3, A's own diagonal as eigenvalues: product {f(A[0][0] * A[1][1], 0)}, not {f(det, 0)}")
assert abs(T[1][0]) < 1e-12 and abs(T[0][0] - 2) < 1e-12 and abs(T[1][1] - 2) < 1e-12   # triangle, 2 and 2
assert abs(T2[1][0]) < 1e-7 and abs(T2[0][0] - lam) < 1e-6 and abs(abs(T2[0][1]) - abs(T[0][1])) < 1e-6
assert max(abs(P[i][j] - P2[i][j]) for i in (0, 1) for j in (0, 1)) < 1e-9   # two roads to A^10
assert abs(T[0][0] + T[1][1] - (A[0][0] + A[1][1])) < 1e-12 and abs(T[0][0] * T[1][1] - det) < 1e-12
assert abs(RT[1][0]) < 1e-12 and abs(RT[0][0] - 1j) < 1e-12 and real_best > 0.999   # R needs complex Q
print("ALL CHECKS PASS")
