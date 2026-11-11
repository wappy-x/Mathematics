# Semidefinite programs -- the check behind the card.  Standard library only.
# Eigenvalues come from Jacobi rotations written out below; no linear-algebra library.
from math import sqrt, cos, acos, pi

def eig(A):                                   # Jacobi: rotate away off-diagonal entries
    n = len(A); A = [r[:] for r in A]; V = [[float(i == j) for j in range(n)] for i in range(n)]
    for _ in range(100):
        if sum(A[i][j] ** 2 for i in range(n) for j in range(n) if i != j) < 1e-30: break
        for p in range(n):
            for q in range(p + 1, n):
                if A[p][q] == 0.0: continue
                th = (A[q][q] - A[p][p]) / (2 * A[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(th * th + 1)); c = 1 / sqrt(t * t + 1); s = t * c
                for M, rows in ((A, False), (A, True), (V, False)):
                    for k in range(n):
                        if rows: a, b = M[p][k], M[q][k]; M[p][k], M[q][k] = c * a - s * b, s * a + c * b
                        else: a, b = M[k][p], M[k][q]; M[k][p], M[k][q] = c * a - s * b, s * a + c * b
    return [A[i][i] for i in range(n)], V

def psd_part(A):                              # nearest PSD matrix: clip negative eigenvalues to zero
    w, V = eig(A); n = len(A)
    return [[sum(max(w[k], 0.0) * V[i][k] * V[j][k] for k in range(n)) for j in range(n)] for i in range(n)]

def dist(A, B): return sqrt(sum((A[i][j] - B[i][j]) ** 2 for i in range(len(A)) for j in range(len(A))))
def quad(A, w): return sum(w[i] * A[i][j] * w[j] for i in range(len(A)) for j in range(len(A)))
def show(label, v): print(f"{label:<44} {0.0 if abs(v) < 5e-10 else v:.6f}")   # specks below 5e-10 print as 0
def corr(x, y, z): return [[1.0, x, y], [x, 1.0, z], [y, z, 1.0]]   # UK, Europe, property

# ---- the broken matrix: UK-Europe 0.9, UK-property 0.2, Europe-property 0.9 ----
C = corr(0.9, 0.2, 0.9)
lam = sorted(eig(C)[0]); mix = [1.0, -1.0, 1.0]
show("eigenvalue, smallest", lam[0]); show("eigenvalue, middle", lam[1]); show("eigenvalue, largest", lam[2])
show("variance of long UK, short Europe, long property", quad(C, mix))
show("  in pounds squared, 100000 each at 20% vol", quad(C, mix) * 20000.0 ** 2)
x, y = 0.9, 0.2
S = [[1 - x * x, y - x * x], [y - x * x, 1 - x * x]]           # Schur complement, pivot on Europe
show("Schur complement corner 1 - x^2", S[0][0]); show("Schur complement off-corner y - x^2", S[0][1])
show("det of Schur complement", S[0][0] * S[1][1] - S[0][1] ** 2)
det3 = 1 + 2 * x * y * x - 2 * x * x - y * y
show("det of C by cofactors", det3); show("product of eigenvalues", lam[0] * lam[1] * lam[2])
show("least UK-property allowed, 2x^2 - 1", 2 * x * x - 1)

# ---- road 1: dual ascent, nu <- nu + (1 - diag((C + Diag nu)+)), from nu = 0 ----
def shift(C, nu): return [[C[i][j] + (nu[i] if i == j else 0.0) for j in range(3)] for i in range(3)]
def repair(C, tol):
    nu, k = [0.0, 0.0, 0.0], 0
    while k < 1000:                           # cap, so a broken update fails an assert instead of hanging
        X = psd_part(shift(C, nu)); g = [1 - X[i][i] for i in range(3)]
        if max(abs(v) for v in g) < tol: break
        nu = [nu[i] + g[i] for i in range(3)]; k += 1
    d = [sqrt(X[i][i]) for i in range(3)]
    return [[X[i][j] / (d[i] * d[j]) for j in range(3)] for i in range(3)], nu, k   # exact unit diagonal
X, nu, k = repair(C, 1e-10); Z = [[0.0] * 3] * 3
primal = 0.5 * dist(X, C) ** 2
dual = 0.5 * dist(C, Z) ** 2 + sum(nu) - 0.5 * dist(psd_part(shift(C, nu)), Z) ** 2
print(f"road 1 dual ascent: {k} steps to max |1 - diag| < 1e-10")
show("  repaired UK-Europe = Europe-property", X[0][1]); show("  repaired UK-property", X[0][2])
show("  multiplier nu, UK and property", nu[0]); show("  multiplier nu, Europe", nu[1])
show("  distance moved, Frobenius", dist(X, C)); show("  smallest eigenvalue after repair", min(eig(X)[0]))
show("  primal half-distance^2 minus dual bound", primal - dual)

# ---- road 2: Higham's alternating projections with Dykstra's correction ----
def higham(C, dykstra):
    Y = [r[:] for r in C]; dS = [[0.0] * 3 for _ in range(3)]; it = 0
    while it < 1000:
        R = [[Y[i][j] - dS[i][j] for j in range(3)] for i in range(3)]
        P = psd_part(R); dS = [[(P[i][j] - R[i][j]) * dykstra for j in range(3)] for i in range(3)]
        Ynew = [[1.0 if i == j else P[i][j] for j in range(3)] for i in range(3)]; it += 1
        done = dist(Ynew, Y) < 1e-12; Y = Ynew
        if done: break
    return Y, it
Y, it = higham(C, 1.0)
print(f"road 2 Dykstra projections: {it} rounds"); show("  repaired UK-Europe", Y[0][1]); show("  repaired UK-property", Y[0][2])

# ---- road 3: on the boundary y = 2x^2 - 1, minimise 4(x-0.9)^2 + 2(y-0.2)^2: root of 4x^3 - 1.4x - 0.9 ----
lo, hi = 0.0, 1.0
for _ in range(80):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if 4 * mid ** 3 - 1.4 * mid - 0.9 < 0 else (lo, mid)
show("road 3 boundary root x", lo); show("  y = 2x^2 - 1", 2 * lo * lo - 1)
show("variance of the same mix, repaired", quad(X, mix))
show("  its risk in pounds", 20000.0 * sqrt(quad(X, mix)))

# ---- what breaks ----
Pc = psd_part(C)
show("wrong: clip only, diagonal UK", Pc[0][0]); show("wrong: clip only, diagonal Europe", Pc[1][1])
dc = [sqrt(Pc[i][i]) for i in range(3)]; Rc = [[Pc[i][j] / (dc[i] * dc[j]) for j in range(3)] for i in range(3)]
show("wrong: clip then rescale, UK-Europe", Rc[0][1]); show("wrong: clip then rescale, distance", dist(Rc, C))
bad = [[-1.0, 1.0], [1.0, 0.0]]
show("negative pivot: d - b^2/a", bad[1][1] - bad[0][1] ** 2 / bad[0][0]); show("  yet smallest eigenvalue", min(eig(bad)[0]))
print(f"figure, C ({x:.2f}, {y:.2f}); X* ({X[0][1]:.4f}, {X[0][2]:.4f}); clip-rescale ({Rc[0][1]:.4f}, {Rc[0][2]:.4f})")

# ---- max-cut on a ring of five assets: edges i -- i+1 ----
E = [(i, (i + 1) % 5) for i in range(5)]
cuts = [sum(1 for i, j in E if (m >> i & 1) != (m >> j & 1)) for m in range(32)]
print(f"max-cut by listing all 32 sign patterns: {max(cuts)} edges, reached by {cuts.count(max(cuts))} patterns")
v = [[1.0, float(i), float(i * i)] for i in range(5)]
v = [[a / sqrt(sum(b * b for b in u)) for a in u] for u in v]
val = lambda: sum((1 - sum(v[i][t] * v[j][t] for t in range(3))) / 2 for i, j in E)
move, sweeps = 1.0, 0
while move > 1e-12 and sweeps < 1000:        # stop when no vector moves more than 1e-12
    move = 0.0; sweeps += 1
    for i in range(5):
        s = [-(v[(i - 1) % 5][t] + v[(i + 1) % 5][t]) for t in range(3)]; nrm = sqrt(sum(a * a for a in s))
        move = max(move, max(abs(s[t] / nrm - v[i][t]) for t in range(3))); v[i] = [a / nrm for a in s]
Xc = [[sum(v[i][t] * v[j][t] for t in range(3)) for j in range(5)] for i in range(5)]
yd = [(2 - Xc[i][(i - 1) % 5] - Xc[i][(i + 1) % 5]) / 4 for i in range(5)]
Lq = [[(yd[i] if i == j else 0.0) - (0.5 if i == j else (-0.25 if (j - i) % 5 in (1, 4) else 0.0)) for j in range(5)] for i in range(5)]
print(f"SDP by mixing sweeps: {sweeps} sweeps"); show("  SDP value, upper bound on every cut", val())
show("  neighbour inner product v_i.v_j", Xc[0][1]); show("  dual bound, sum of u_i", sum(yd))
show("  smallest eigenvalue of Diag(u) - L/4", min(eig(Lq)[0])); show("  closed form 2.5(1 + cos(pi/5))", 2.5 * (1 + cos(pi / 5)))
expct = sum(acos(max(-1.0, min(1.0, Xc[i][j]))) / pi for i, j in E)
r = [1.0, 0.5, 0.25]; side = [sum(v[i][t] * r[t] for t in range(3)) > 0 for i in range(5)]
alpha = min(2 * (t / 1e5 * pi) / (pi * (1 - cos(t / 1e5 * pi))) for t in range(1, 100001))
show("expected cut, random hyperplane", expct); print(f"cut from hyperplane (1, 0.5, 0.25): {sum(side[i] != side[j] for i, j in E)} edges")
show("ratio best cut / SDP bound", max(cuts) / val()); show("guarantee constant alpha", alpha)
print(f"try: stop at 1e-4, steps {repair(C, 1e-4)[2]}"); show("try: UK-property 0.7, distance moved", dist(repair(corr(0.9, 0.7, 0.9), 1e-10)[0], corr(0.9, 0.7, 0.9)))
show("try: no Dykstra correction, UK-Europe", higham(C, 0.0)[0][0][1]); show("try: no Dykstra correction, distance", dist(higham(C, 0.0)[0], C))

assert lam[0] < 0 and abs(det3 - lam[0] * lam[1] * lam[2]) < 1e-12           # Schur/cofactor vs eigenvalues
assert abs(X[0][1] - Y[0][1]) < 1e-7 and abs(X[0][2] - Y[0][2]) < 1e-7         # road 1 vs road 2
assert abs(X[0][1] - lo) < 1e-7 and abs(X[0][2] - (2 * lo * lo - 1)) < 1e-7     # road 1 vs road 3
assert abs(primal - dual) < 1e-9 and min(eig(X)[0]) > -1e-12                     # certificate, both sides
assert dist(Rc, C) > dist(X, C) + 1e-3                                           # rescaling is not nearest
assert min(eig(Lq)[0]) > -1e-9                                                   # max-cut SDP certificate
assert abs(val() - 2.5 * (1 + cos(pi / 5))) < 1e-9 and max(cuts) == 4          # mixing vs closed form
print("ALL CHECKS PASS")
