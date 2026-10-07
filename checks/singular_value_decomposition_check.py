# Singular value decomposition -- the check behind the card.  Nothing is imported.  The
# sprite transform A = [[3, 0], [4, 5]] turns the unit circle into an ellipse.  Road one:
# the stretch factors from the eigenvalues of G = A^T A; road two: measure every direction.
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def mv(a, v): return [dot(a[0], v), dot(a[1], v)]
def tp(a): return [[a[0][0], a[1][0]], [a[0][1], a[1][1]]]
def mm(a, b): return [[dot(r, c) for c in tp(b)] for r in a]
def det(a): return a[0][0] * a[1][1] - a[0][1] * a[1][0]
def unit(w): n = dot(w, w) ** 0.5; return [w[0] / n, w[1] / n]
def drift(a, b): return max(abs(a[i][j] - b[i][j]) for i in (0, 1) for j in (0, 1))
def f6(v): return "(" + ", ".join(f"{0.0 if abs(x) < 5e-7 else x:.6f}" for x in v) + ")"
def eig2(a):                                      # both roots of the characteristic quadratic
    mid = (a[0][0] + a[1][1]) / 2; gap = (mid * mid - det(a)) ** 0.5
    return [mid + gap, mid - gap]
def svd(a):                                       # road one: the eigen-pairs of G = A^T A
    g = mm(tp(a), a); lam = eig2(g); sig = [x ** 0.5 for x in lam]
    vs = [unit([g[0][1], L - g[0][0]]) for L in lam]          # solves (G - L I)v = 0 by hand
    us = [[x / s for x in mv(a, v)] if s > 1e-12 else [] for s, v in zip(sig, vs)]
    us = [u if u else [-us[0][1], us[0][0]] for u in us]      # a flattened axis: complete the pair
    return g, lam, sig, vs, us
def sweep(a, n):                                  # road two: the stretch in every direction
    hi, lo, hdir, seen = -1.0, 1e18, [0.0, 0.0], 0
    for k in range(n + 1):
        t = k / n; den = 1 + t * t                # (1 - t*t, 2t)/den has length 1 for every t
        for s in (1.0, -1.0):                     # a half turn is enough: -v stretches like v
            v = [(1 - t * t) / den, s * 2 * t / den]; w = mv(a, v); L = dot(w, w); seen += 1
            if L > hi: hi, hdir = L, v
            if L < lo: lo = L
    return hi ** 0.5, lo ** 0.5, hdir, seen
A, B, EYE = [[3.0, 0.0], [4.0, 5.0]], [[1.0, 2.0], [2.0, 4.0]], [[1.0, 0.0], [0.0, 1.0]]
G, lam, sig, vs, us = svd(A)
U, V, S = tp(us), tp(vs), [[sig[0], 0.0], [0.0, sig[1]]]
rebuilt = mm(mm(U, S), tp(V)); hi, lo, hdir, seen = sweep(A, 50000)
squares = sum(x * x for row in A for x in row); cols = [dot(c, c) ** 0.5 for c in tp(A)]
rank = sum(1 for s in sig if s > 1e-12)
GB, lamB, sigB, vsB, usB = svd(B); rankB = sum(1 for s in sigB if s > 1e-12)
print(f"sprite A rows: {f6(A[0])}; {f6(A[1])}; det A {det(A):.6f}")
print(f"G = A^T A rows: {f6(G[0])}; {f6(G[1])}")
print(f"eigenvalues of G: {f6(lam)}; singular values, their square roots: {f6(sig)}")
print(f"input axes v1, v2: {f6(vs[0])}; {f6(vs[1])}")
print(f"images A v1, A v2: {f6(mv(A, vs[0]))}; {f6(mv(A, vs[1]))}")
print(f"output axes u1, u2: {f6(us[0])}; {f6(us[1])}")
print(f"road two, longest and shortest stretch over {seen} directions: {f6([hi, lo])}, "
      f"longest along ({hdir[0]:.4f}, {hdir[1]:.4f})")
print(f"U S V^T rows: {f6(rebuilt[0])}; {f6(rebuilt[1])}; largest drift from perpendicular "
      f"unit axes, U then V: {drift(mm(tp(U), U), EYE):.6f}, {drift(mm(tp(V), V), EYE):.6f}")
print(f"product of singular values {sig[0] * sig[1]:.6f}; absolute determinant {abs(det(A)):.6f}")
print(f"eigenvalues added {lam[0] + lam[1]:.6f}; squares of A's entries added {squares:.6f}")
print(f"nonzero singular values, the rank: {rank}")
print(f"A's own eigenvalues, not the stretches: {f6(eig2(A))}; A's column lengths: {f6(cols)}")
print(f"eigenvalues left unrooted, product {lam[0] * lam[1]:.6f}, "
      f"not the area factor {sig[0] * sig[1]:.6f}")
print(f"flat matrix B rows: {f6(B[0])}; {f6(B[1])}; det B {det(B):.6f}; "
      f"singular values {f6(sigB)}; rank {rankB}")
print(f"B kills its second input axis {f6(vsB[1])}: image {f6(mv(B, vsB[1]))}")
assert abs(hi - sig[0]) < 1e-6 and abs(lo - sig[1]) < 1e-6      # two roads, same stretches
assert abs(sig[0] * sig[1] - abs(det(A))) < 1e-12 and abs(lam[0] + lam[1] - squares) < 1e-12
assert drift(rebuilt, A) < 1e-12 and drift(mm(tp(U), U), EYE) < 1e-12 and drift(mm(tp(V), V), EYE) < 1e-12
assert abs(sigB[0] - 5.0) < 1e-12 and dot(mv(B, vsB[1]), mv(B, vsB[1])) < 1e-24 and (rank, rankB) == (2, 1)
print("ALL CHECKS PASS")
