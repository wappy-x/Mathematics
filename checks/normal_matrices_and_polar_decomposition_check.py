# Normal matrices and the polar form -- the check behind the card.  Standard library only.
# R = [[0, -1], [1, 0]] is normal; A = [[0, -2], [1, 0]] is not, and splits as A = U P.
import math
def M(rows): return [[complex(x) for x in r] for r in rows]
def mm(a, b): return [[a[i][0] * b[0][j] + a[i][1] * b[1][j] for j in range(2)] for i in range(2)]
def st(a): return [[a[j][i].conjugate() for j in range(2)] for i in range(2)]      # conjugate transpose a*
def lin(s, a, t, b): return [[s * a[i][j] + t * b[i][j] for j in range(2)] for i in range(2)]  # s a + t b
def gap(a, b): return max(abs(a[i][j] - b[i][j]) for i in range(2) for j in range(2))
def dot(x, y): return x[0].conjugate() * y[0] + x[1].conjugate() * y[1]             # x* y
def det(a): return a[0][0] * a[1][1] - a[0][1] * a[1][0]
def inv(a): return [[a[1][1] / det(a), -a[0][1] / det(a)], [-a[1][0] / det(a), a[0][0] / det(a)]]
def yn(c): return "yes" if c else "no"
def r(x): return f"{x if abs(x) >= 5e-7 else 0.0:.6f}"
def c(z): return f"{r(z.real)} {'-' if z.imag < -5e-7 else '+'} {r(abs(z.imag))}i"
def mat(a): return "[[" + "], [".join(", ".join(r(x.real) for x in row) for row in a) + "]]"
def eig(a):                     # roots of t^2 - trace t + det = 0, complex square root by hand
    tr = a[0][0] + a[1][1]; z = tr * tr - 4 * det(a); m = abs(z); im = math.sqrt(max(m - z.real, 0.0) / 2)
    s = complex(math.sqrt((m + z.real) / 2), -im if z.imag < 0 else im); return [(tr + s) / 2, (tr - s) / 2]
def evec(a, lam):               # unit eigenvector from one row of (a - lam I), first entry real and positive
    v = [a[0][1], lam - a[0][0]] if abs(a[0][1]) + abs(lam - a[0][0]) > 1e-12 else [a[1][1] - lam, -a[1][0]]
    n = math.hypot(abs(v[0]), abs(v[1])) * (v[0] / abs(v[0]) if abs(v[0]) > 1e-12 else 1); return [v[0] / n, v[1] / n]
def schur(a):                   # T = Q* a Q, where Q's first column is a unit eigenvector
    v = evec(a, eig(a)[0]); Q = [[v[0], -v[1].conjugate()], [v[1], v[0].conjugate()]]; return mm(mm(st(Q), a), Q)
def psqrt(m):                   # square root of a 2 by 2 nonzero positive semidefinite m, by Cayley-Hamilton
    d = math.sqrt(abs(det(m))); t = math.sqrt(abs(m[0][0] + m[1][1]) + 2 * d); return lin(1 / t, m, d / t, I2)
def normal(a): return gap(mm(a, st(a)), mm(st(a), a)) < 1e-12
I2, R, A = M([[1, 0], [0, 1]]), M([[0, -1], [1, 0]]), M([[0, -2], [1, 0]])
H, N = [[2 + 0j, 1j], [-1j, 2 + 0j]], lin(1, I2, 2, R)                          # N = I + 2R
for name, a in (("R", R), ("H", H), ("N", N), ("A", A)):
    print(f"{name}: normal {yn(normal(a))}, Hermitian {yn(gap(st(a), a) < 1e-12)}, unitary {yn(gap(mm(st(a), a), I2) < 1e-12)}, "
          f"skew-Hermitian {yn(gap(st(a), lin(-1, a, 0, a)) < 1e-12)}; eigenvalues {c(eig(a)[0])} and {c(eig(a)[1])}")
lr = eig(R); q1, q2 = evec(R, lr[0]), evec(R, lr[1]); Q = [[q1[0], q2[0]], [q1[1], q2[1]]]; QDQ = mm(mm(Q, [[lr[0], 0], [0, lr[1]]]), st(Q))
print(f"R: q1 = ({c(q1[0])}, {c(q1[1])}), q2 = ({c(q2[0])}, {c(q2[1])}); q1* q2 = {c(dot(q1, q2))}; Q diag(i, -i) Q* = R: {yn(gap(QDQ, R) < 1e-12)}")
print(f"A A* = {mat(mm(A, st(A)))}; A* A = {mat(mm(st(A), A))}")
la = eig(A); va = [evec(A, l) for l in la]; cosang = abs(dot(va[0], va[1]))
print(f"A: eigenvectors (1, {c(va[0][1] / va[0][0])}) and (1, {c(va[1][1] / va[1][0])}); |v1* v2| = {r(cosang)}, angle {r(math.degrees(math.acos(cosang)))} degrees")
TR, TA = schur(R), schur(A); frob = sum(abs(x) ** 2 for row in A for x in row); lam2 = abs(la[0]) ** 2 + abs(la[1]) ** 2
print(f"Schur T = Q* M Q: |t12| for R = {r(abs(TR[0][1]))}, for A = {r(abs(TA[0][1]))}; A's road two: {r(frob)} - {r(lam2)} = {r(frob - lam2)}")
G = mm(st(A), A); s2 = [z.real for z in eig(G)]; sv = [math.sqrt(x) for x in s2]; v1, v2 = evec(G, s2[0]), evec(G, s2[1])
V, S = [[v1[0], v2[0]], [v1[1], v2[1]]], [[sv[0], 0], [0, sv[1]]]; W = mm(mm(A, V), inv(S))   # u_i = A v_i / sigma_i
Us, Ps = mm(W, st(V)), mm(mm(V, S), st(V))
print(f"SVD of A: singular values {r(sv[0])} and {r(sv[1])}; V = {mat(V)}, W = {mat(W)}"); print(f"road one, from the SVD: U = W V* = {mat(Us)}, P = V S V* = {mat(Ps)}")
Un, trail = A, [A[0][1].real]
for k in range(6): Un = lin(0.5, Un, 0.5, st(inv(Un))); trail.append(Un[0][1].real)   # average U with (U^-1)*
Pn = mm(st(Un), A); print(f"road two, average U with the conjugate transpose of its inverse; top-right entry: {', '.join(r(x) for x in trail)}")
print(f"road two: U = {mat(Un)}, P = U* A = {mat(Pn)}; road three: P = sqrt(A* A) by Cayley-Hamilton = {mat(psqrt(G))}")
print(f"U* U = I: {yn(gap(mm(st(Us), Us), I2) < 1e-12)}; U P = A: {yn(gap(mm(Us, Ps), A) < 1e-12)}; P's eigenvalues {r(eig(Ps)[0].real)} and {r(eig(Ps)[1].real)}")
PL, PN = psqrt(mm(A, st(A))), psqrt(mm(st(N), N)); UN, UW = mm(N, inv(PN)), mm(A, inv(PL))
print(f"left form: P' = sqrt(A A*) = {mat(PL)}, P' U = A: {yn(gap(mm(PL, Us), A) < 1e-12)}, P' = P: {yn(gap(PL, Ps) < 1e-12)}; "
      f"N: P = {mat(PN)}, U P = P U: {yn(gap(mm(UN, PN), mm(PN, UN)) < 1e-12)}")
print(f"mistake 1, plain transpose on R's eigenvectors: q1^T q2 = {c(q1[0] * q2[0] + q1[1] * q2[1])}, not 0")
print(f"mistake 2, order swapped: P U = {mat(mm(Ps, Us))}, not A")
print(f"mistake 3, stretch from A A* put on the right: A P'^-1 = {mat(UW)}, its U* U = {mat(mm(st(UW), UW))}")
print(f"mistake 4, Hermitian part (A + A*)/2 as the stretch: eigenvalues {', '.join(r(z.real) for z in eig(lin(0.5, A, 0.5, st(A))))}")
assert normal(R) and normal(H) and normal(N) and abs(TR[0][1]) < 1e-12 and not normal(A)  # commutator and Schur agree
assert abs(abs(TA[0][1]) ** 2 - (frob - lam2)) < 1e-12                                 # two roads to A's defect, 1
assert abs(dot(q1, q2)) < 1e-12 and gap(QDQ, R) < 1e-12 and abs(cosang - 1 / 3) < 1e-12
assert gap(Us, Un) < 1e-12 and gap(Ps, Pn) < 1e-12 and gap(Ps, psqrt(G)) < 1e-12       # three roads to U and P
assert gap(mm(Us, Ps), A) < 1e-12 and gap(Us, R) < 1e-12 and gap(Ps, M([[1, 0], [0, 2]])) < 1e-12
print("ALL CHECKS PASS")
