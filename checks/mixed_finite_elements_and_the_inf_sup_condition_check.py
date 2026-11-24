# Mixed finite elements and the inf-sup test: Stokes flow in the unit square, velocity zero on the walls, for
# Q1-P0, Taylor-Hood Q2-Q1 and Q1-Q1; and a 1-D bar, flux P1 with temperature P0 or P1. Standard library only.
import math, functools
G = [(0.5 - 0.5 * math.sqrt(0.6), 5.0 / 18.0), (0.5, 8.0 / 18.0), (0.5 + 0.5 * math.sqrt(0.6), 5.0 / 18.0)]
def dot(a, b): return functools.reduce(lambda s, xy: s + xy[0] * xy[1], zip(a, b), 0.0)
def b1(k, t):  # 1-D Lagrange basis of degree k = 1 or 2 on [0, 1]: values, slopes
    if k == 1: return [1.0 - t, t], [-1.0, 1.0]
    return [2.0 * (t - 0.5) * (t - 1.0), -4.0 * t * (t - 1.0), 2.0 * t * (t - 0.5)], [4.0 * t - 3.0, 4.0 - 8.0 * t, 4.0 * t - 1.0]
def stokes(n, kv, kp):
    # one velocity component's stiffness A and mass Mv; Bx, By = q times div v (the card's -B); pressure mass Mp
    h, m = 1.0 / n, kv * n + 1
    idx = {(i, j): (j - 1) * (m - 2) + i - 1 for j in range(1, m - 1) for i in range(1, m - 1)}
    N, P = len(idx), (n * n if kp == 0 else (n + 1) * (n + 1))
    A, Mv = [[0.0] * N for _ in range(N)], [[0.0] * N for _ in range(N)]
    Bx, By, Mp = [[0.0] * N for _ in range(P)], [[0.0] * N for _ in range(P)], [[0.0] * P for _ in range(P)]
    for cy, cx in [(y, x) for y in range(n) for x in range(n)]:
        for (tx, wx), (ty, wy) in [(gx, gy) for gx in G for gy in G]:
            w = wx * wy * h * h; vx, dx = b1(kv, tx); vy, dy = b1(kv, ty)
            loc = [(idx[(kv * cx + a, kv * cy + b)], dx[a] * vy[b] / h, vx[a] * dy[b] / h, vx[a] * vy[b])
                   for b in range(kv + 1) for a in range(kv + 1) if (kv * cx + a, kv * cy + b) in idx]
            ploc = [(cy * n + cx, 1.0)] if kp == 0 else [((cy + b) * (n + 1) + cx + a,
                    b1(1, tx)[0][a] * b1(1, ty)[0][b]) for b in range(2) for a in range(2)]
            for (I, gx, gy, f) in loc:
                for (J, hx, hy, g) in loc: A[I][J] += w * (gx * hx + gy * hy); Mv[I][J] += w * f * g
                for (Q, q) in ploc: Bx[Q][I] += w * q * gx; By[Q][I] += w * q * gy
            for (Q, q) in ploc:
                for (R, r) in ploc: Mp[Q][R] += w * q * r
    return A, Mv, Bx, By, Mp
def chol(A):
    n = len(A); L = [[0.0] * n for _ in range(n)]
    for j in range(n):
        L[j][j] = math.sqrt(A[j][j] - dot(L[j][:j], L[j][:j]))
        for i in range(j + 1, n): L[i][j] = (A[i][j] - dot(L[i][:j], L[j][:j])) / L[j][j]
    return L
def fsolve(L, b):  # solve L y = b
    y = b[:]
    for i in range(len(y)): y[i] = (y[i] - dot(L[i][:i], y[:i])) / L[i][i]
    return y
def schur(A, Bs):  # S = sum over the parts of B A^-1 B^T = W^T W with W = L^-1 B^T
    L = chol(A); P = len(Bs[0]); S = [[0.0] * P for _ in range(P)]
    for B in Bs:
        W = [fsolve(L, row) for row in B]
        for p in range(P):
            for q in range(P): S[p][q] += dot(W[p], W[q])
    return S
def eigs(S, M, k):
    # the k smallest eigenvalues of S x = lam M x: C = L^-1 S L^-T, Householder, Sturm bisection
    L = chol(M); n = len(S); T = [fsolve(L, [S[i][j] for i in range(n)]) for j in range(n)]
    C = [fsolve(L, [T[j][i] for j in range(n)]) for i in range(n)]; d, e = [0.0] * n, [0.0] * n
    for k0 in range(n - 2):
        x = [C[i][k0] for i in range(k0 + 1, n)]; al = -math.copysign(math.sqrt(dot(x, x)), x[0])
        v = x[:]; v[0] -= al; vn = dot(v, v); m = n - k0 - 1
        if vn > 0.0:
            p = [2.0 * dot(C[k0 + 1 + i][k0 + 1:], v) / vn for i in range(m)]; K = dot(v, p) / vn
            q = [p[i] - K * v[i] for i in range(m)]
            for i in range(m):
                row = C[k0 + 1 + i]
                for j in range(m): row[k0 + 1 + j] -= v[i] * q[j] + q[i] * v[j]
        e[k0] = al
    d = [C[i][i] for i in range(n)]; e[n - 2] = C[n - 2][n - 1]
    def below(t):  # Sturm count: eigenvalues below t
        c, piv = 0, 1.0
        for i in range(n):
            piv = d[i] - t - (e[i - 1] * e[i - 1] / piv if i > 0 else 0.0)
            piv = piv if piv != 0.0 else 1e-300; c += 1 if piv < 0.0 else 0
        return c
    out, hi = [], 1.0 + max(abs(x) for x in d) + 2.0 * max(abs(x) for x in e)  # Gershgorin bound
    for j in range(k):
        lo, up = -1.0, hi
        for _ in range(80): mid = 0.5 * (lo + up); lo, up = (lo, mid) if below(mid) > j else (mid, up)
        out.append(0.5 * (lo + up))
    return out
def negpivots(S, M, t):  # inertia road: LDL^T of S - t M, no pivoting; Sylvester counts eigenvalues below t
    n = len(S); D = [[S[i][j] - t * M[i][j] for j in range(n)] for i in range(n)]; c = 0
    for k in range(n):
        if D[k][k] < 0.0: c += 1
        for i in range(k + 1, n):
            f = D[i][k] / D[k][k]
            for j in range(k + 1, n): D[i][j] -= f * D[k][j]
    return c
def bar(n, kp):  # 1-D bar, length 1: flux in P1 (norm: integral of tau^2 + tau'^2), temperature P0 or P1
    h = 1.0 / n; A = [[0.0] * (n + 1) for _ in range(n + 1)]; P = n if kp == 0 else n + 1
    B, M = [[0.0] * (n + 1) for _ in range(P)], [[0.0] * P for _ in range(P)]
    for e in range(n):
        for a, b in ((0, 0), (0, 1), (1, 0), (1, 1)):
            A[e + a][e + b] += h * (2.0 if a == b else 1.0) / 6.0 + (1.0 if a == b else -1.0) / h
            if kp == 1: M[e + a][e + b] += h * (2.0 if a == b else 1.0) / 6.0; B[e + a][e + b] += 0.5 * (2 * b - 1)
        if kp == 0: M[e][e] = h; B[e][e] -= 1.0; B[e][e + 1] += 1.0
    return A, B, M
NS, beta = (4, 6, 8, 10, 12), lambda lam: math.sqrt(max(lam, 0.0))
bars = [beta(eigs(schur(A, [B]), M, 1)[0]) for (A, B, M) in (bar(n, kp) for kp in (0, 1) for n in (4, 8, 16))]
print("1-D bar, beta at n = 4, 8, 16: temperature P0 " + " ".join(f"{b:.5f}" for b in bars[:3])
      + "; temperature P1 " + " ".join(f"{b:.5f}" for b in bars[3:]))
cf = [math.sqrt(s / (s + m)) for n in (4, 8, 16) for (s, m) in [((2 - 2 * math.cos(math.pi / n)) * n, (2 + math.cos(math.pi / n)) / (3 * n))]]
print("  P0 closed form sqrt(s/(s + m)), s = (2 - 2 cos(pi/n))/h, m = h (2 + cos(pi/n))/3: " + " ".join(f"{c:.5f}" for c in cf))
A1, B1, M1 = bar(4, 1); zz = max(abs(dot([B1[j][i] for j in range(5)], [1.0, -1.0, 1.0, -1.0, 1.0])) for i in range(5))
Ab, Bb, _ = bar(4, 0); K9 = [Ab[i] + [Bb[j][i] for j in range(4)] for i in range(5)] + [Bb[j] + [0.0] * 4 for j in range(4)]
print(f"zigzag 1,-1,1,-1,1: largest |B^T z| = {zz:.1e}; bar saddle matrix 9 x 9: negative pivots {negpivots(K9, K9, 0.0)}")
print("4 x 4 grid, (velocity, pressure) unknowns: " + "; ".join(f"{nm} ({2 * len(s[0])}, {len(s[4])})" for nm, s in
      (("Q1-P0", stokes(4, 1, 0)), ("Taylor-Hood", stokes(4, 2, 1)), ("Q1-Q1", stokes(4, 1, 1)))))
A, Mv, Bx, By, Mp = stokes(4, 1, 0); cb = [(-1.0) ** (i // 4 + i % 4) for i in range(16)]
print("node (2,2), x-part of -B in its four cells: " + " ".join(f"{Bx[c][4]:+.3f}" for c in (5, 6, 9, 10))
      + f"; checkerboard signs {cb[5]:+.0f} {cb[6]:+.0f} {cb[9]:+.0f} {cb[10]:+.0f}")
assert abs(A[4][4] - 8.0 / 3.0) < 1e-14 and all(abs(abs(Bx[c][4]) - 0.125) < 1e-15 for c in (5, 6, 9, 10)), "by hand"
res = max(abs(dot([B[q][I] for q in range(16)], cb)) for B in (Bx, By) for I in range(9))
print(f"Q1-P0 checkerboard: largest |B^T p| = {res:.1e}; times 1000 = {1000.0 * res:.1e}")
ev = eigs(schur(A, [Bx, By]), Mp, 16); z0 = len([v for v in ev if v < 1e-10])
A, Mv, Bx, By, Mp = stokes(4, 1, 1); q11 = len([v for v in eigs(schur(A, [Bx, By]), Mp, 25) if v < 1e-10])
print(f"zero eigenvalues at n=4: Q1-P0 {z0} of 16 (rank of B {16 - z0}); Q1-Q1 {q11} of 25 (25 - 18 = 7 forced)")
rows = []; print("   n      h  Q1-P0 beta  Q1-P0 next   order  Taylor-Hood beta  beta^2  1/beta")
for n in NS:
    A, Mv, Bx, By, Mp = stokes(n, 1, 0); e0 = eigs(schur(A, [Bx, By]), Mp, 3)
    A, Mv, Bx, By, Mp = stokes(n, 2, 1); S2 = schur(A, [Bx, By]); e2 = eigs(S2, Mp, 3)
    rows.append((n, beta(e0[1]), beta(e0[2]), beta(e2[1]), e2[1]))
    o = f"{math.log(rows[-2][2] / rows[-1][2]) / math.log(n / rows[-2][0]):7.3f}" if len(rows) > 1 else "      -"
    print(f"{n:4d} {1.0 / n:6.4f} {rows[-1][1]:11.6f} {rows[-1][2]:11.6f} {o} {rows[-1][3]:17.6f} {e2[1]:7.4f} {1.0 / rows[-1][3]:7.3f}")
    if n == 4: S4, M4, l4, l5, Mv4, B4 = S2, Mp, e2[1], e2[2], Mv, (Bx, By)
t1, t2 = 0.999 * l4, 0.5 * (l4 + l5); i1, i2 = negpivots(S4, M4, t1), negpivots(S4, M4, t2)
print(f"inertia, Taylor-Hood n=4: eigenvalues below {t1:.6f}: {i1}; below {t2:.6f}: {i2}; next eigenvalue {l5:.6f}")
print(f"wrong norm (velocity size, not its slope), Taylor-Hood n=4: beta {beta(eigs(schur(Mv4, B4), M4, 2)[1]):.4f}")
print(f"wrong: count the constant pressure, Taylor-Hood n=4: beta {beta(eigs(S4, M4, 1)[0]):.6f}")
A, Mv, Bx, By, Mp = stokes(4, 2, 1); V = [i * (8 - i) * j * (8 - j) / 4096 for j in range(1, 8) for i in range(1, 8)]
sw, vav = [(1.0 if i % 2 == 0 else 2.0) / 12.0 for i in range(1, 8)], dot(V, [dot(r, V) for r in A])   # Simpson: h/3, 2h/3
gb = max(abs(dot([B[Q][I] for Q in range(25)], [(Q % 5 if B is Bx else Q // 5) / 4.0 for Q in range(25)]) + sw[I % 7] * sw[I // 7])
         for B in (Bx, By) for I in range(49))   # pressure x (or y) against div v: -integral of v, by parts
print(f"Taylor-Hood n=4 against exact integrals: v = x(1-x)y(1-y), V^T A V = {vav:.6f}, 1/45 = {1 / 45:.6f}; pressures x, y"
      f" against -Simpson weights, gap {gb:.1e}; total of M_p {sum(sum(r) for r in Mp):.6f}")
print(f"figure, grid px left 40 bottom 220 cell 45; node (2,2) at ({40 + 45 * 2},{220 - 45 * 2})")
print("chart, log10 h          " + " ".join(f"{math.log10(1.0 / r[0]):6.3f}" for r in rows))
print("chart, log10 Q1-P0 next " + " ".join(f"{math.log10(r[2]):6.3f}" for r in rows))
print("chart, log10 TH beta    " + " ".join(f"{math.log10(r[3]):6.3f}" for r in rows))
assert res < 1e-14 and z0 == 2, "Q1-P0: the constant and the checkerboard are invisible to B"
assert q11 >= 25 - 18, "more pressures than velocities leaves invisible pressures"
assert zz < 1e-14 and all(abs(b - c) < 1e-12 and b <= 1.0 for b, c in zip(bars, cf)), "1-D: zigzag invisible; P0 = closed form"
assert abs(vav - 1 / 45) < 1e-14 and gb < 1e-14 and abs(sum(sum(r) for r in Mp) - 1.0) < 1e-12, "assembly = exact integrals"
assert i1 == 1 and i2 == 2, "inertia (no eigen solver) brackets the Taylor-Hood beta^2"
assert all(0.45 < r[3] <= 1.0 for r in rows), "Taylor-Hood beta on these grids: above 0.45, below the ceiling 1"
assert rows[-1][2] < 0.5 * rows[0][2], "Q1-P0's best non-checkerboard constant still decays"
print("ALL CHECKS PASS")
