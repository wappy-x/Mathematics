# Sums of squares -- the check behind the card.  Standard library only.
# Eigenvalues come from Jacobi rotations written out below; no linear-algebra or optimisation library.
from math import sqrt, cos, acos

def eig(A):                                   # Jacobi: rotate away off-diagonal entries; eigenvalues, sorted
    n = len(A); A = [r[:] for r in A]
    for _ in range(60):
        if sum(A[i][j] ** 2 for i in range(n) for j in range(n) if i != j) < 1e-30: break
        for p in range(n):
            for q in range(p + 1, n):
                if A[p][q] == 0.0: continue
                th = (A[q][q] - A[p][p]) / (2 * A[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(th * th + 1)); c = 1 / sqrt(t * t + 1); s = t * c
                for k in range(n): a, b = A[k][p], A[k][q]; A[k][p], A[k][q] = c * a - s * b, s * a + c * b
                for k in range(n): a, b = A[p][k], A[q][k]; A[p][k], A[q][k] = c * a - s * b, s * a + c * b
    return sorted(A[i][i] for i in range(n))

def show(label, v): print(f"{label:<46} {0.0 if abs(v) < 5e-10 else v:.6f}")   # specks below 5e-10 print as 0
def gram(c, g, t):                            # c = (c0..c4) of a quartic; Gram matrix of p - g on (1, x, x^2)
    return [[c[0] - g, c[1] / 2, t], [c[1] / 2, c[2] - 2 * t, c[3] / 2], [t, c[3] / 2, c[4]]]
def best_t(c, g):                             # golden section: the t that makes the smallest eigenvalue largest
    lo, hi, r = -50.0, 50.0, (sqrt(5) - 1) / 2
    for _ in range(120):
        a, b = hi - r * (hi - lo), lo + r * (hi - lo)
        if eig(gram(c, g, a))[0] < eig(gram(c, g, b))[0]: lo = a
        else: hi = b
    t = (lo + hi) / 2
    return t, eig(gram(c, g, t))[0]
def sos_bound(c):                             # bisection on g: largest g whose Gram matrix can be made PSD
    lo, hi, k = -100.0, c[0], 0               # g = p(0) = c0 is never beaten by a lower bound
    while hi - lo > 1e-12:
        mid = (lo + hi) / 2; k += 1
        if best_t(c, mid)[1] >= -1e-12: lo = mid
        else: hi = mid
    return lo, k
def pv(c, x): return c[0] + c[1] * x + c[2] * x ** 2 + c[3] * x ** 3 + c[4] * x ** 4

# ---- the example: p(x) = x^4 - 4x^3 + 6x^2 - 4x + 5, minimised over every real x ----
P = (5.0, -4.0, 6.0, -4.0, 1.0)
for x in (0, 1, 2, 3): show(f"p({x})", pv(P, x))
print("chart p(x) at x = -1, -0.5, ..., 3:", ", ".join(f"{pv(P, i / 2 - 1):.4f}" for i in range(9)))
g1, k1 = sos_bound(P); t1, l1 = best_t(P, g1)
print(f"road 1 bisection on g with golden section on t: {k1} halvings")
show("  SOS lower bound g*", g1); show("  free Gram entry t at g*", t1); show("  smallest eigenvalue there", l1)
show("  g = 4.01: best smallest eigenvalue", best_t(P, 4.01)[1])
show("  g = 3: best smallest eigenvalue", best_t(P, 3.0)[1])
# road 2: exact algebra.  det Q(g, t) = 2(1 - t)(4 - g - (t - 1)^2); minors force t <= 1, det forces t >= 1 when g >= 4
det = lambda g, t: (lambda Q: Q[0][0] * (Q[1][1] * Q[2][2] - Q[1][2] ** 2) - Q[0][1] * (Q[0][1] * Q[2][2] - Q[1][2] * Q[0][2])
                    + Q[0][2] * (Q[0][1] * Q[1][2] - Q[1][1] * Q[0][2]))(gram(P, g, t))
show("road 2 det Q(4.01, 0.5) by cofactors", det(4.01, 0.5)); show("  formula 2(1-t)(4-g-(t-1)^2)", 2 * 0.5 * (4 - 4.01 - 0.25))
Qs = gram(P, 4.0, 1.0); ev = eig(Qs)
print("  Q at g = 4, t = 1:", [[int(v) for v in r] for r in Qs])
show("  its eigenvalues: largest", ev[2]); show("  middle", ev[1]); show("  smallest", ev[0])
v = (1, -2, 1)                                # Q = v v^T, so p - 4 = (1 - 2x + x^2)^2 = (x - 1)^4
sq = [sum(v[i] * v[k - i] for i in range(3) if 0 <= k - i <= 2) for k in range(5)]
print("  coefficients of (1 - 2x + x^2)^2 + 4:", [sq[0] + 4] + sq[1:])
# road 3: the dual.  The point mass at x = 1 has moment matrix Y = all ones; <Q, Y> = L(p) - g for every Gram Q
Y = [[1.0] * 3 for _ in range(3)]
show("road 3 dual value L(p) = p(1)", pv(P, 1.0)); show("  smallest eigenvalue of Y", eig(Y)[0])
show("  <Q, Y> at g = 4, t = 1 (the gap)", sum(Qs[i][j] * Y[i][j] for i in range(3) for j in range(3)))
gm = min(pv(P, -2 + i / 10000) for i in range(60001))
show("road 4 grid on [-2, 4], step 0.0001: min p", gm)

# ---- what breaks ----
Qb = gram(P, 10.0, 1.0); show("wrong: match coefficients only, g = 10, eig", eig(Qb)[0])
R = (0.0, 1.0, -4.0, 0.0, 1.0)                # r(x) = x^4 - 4x^2 + x, two valleys
def descend(x, k=0):
    while abs(4 * x ** 3 - 8 * x + 1) > 1e-10 and k < 10000: x -= 0.05 * (4 * x ** 3 - 8 * x + 1); k += 1
    return x, k
xd, kd = descend(2.0); print(f"wrong: descent on r from x = 2, step 0.05: {kd} steps")
show("  lands at x", xd); show("  r there", pv(R, xd))
gr, _ = sos_bound(R); show("  SOS lower bound on r", gr); show("  grid min of r on [-3, 3]", min(pv(R, -3 + i / 10000) for i in range(60001)))

# ---- Motzkin: M = x^4 y^2 + x^2 y^4 - 3 x^2 y^2 + 1 ----
def motzkin_forced(cxy):                      # Gram rows on monomials of degree <= 3 forced to zero, then the first forced entry
    B = [(a, b) for a in range(4) for b in range(4 - a)]; C = {(4, 2): 1, (2, 4): 1, (2, 2): cxy}
    zero, changed = set(), True
    while changed:
        changed = False
        for m in B:
            e = (2 * m[0], 2 * m[1])
            pairs = [(a, b) for a in B for b in B if a not in zero and b not in zero and (a[0] + b[0], a[1] + b[1]) == e]
            if m in zero or pairs != [(m, m)] or e == (0, 0): continue
            if C.get(e, 0) == 0: zero.add(m); changed = True
            elif C[e] < 0: return zero, m, C[e]
    return zero, None, 0
name = lambda m: "*".join(s + ("^" + str(k) if k > 1 else "") for s, k in (("x", m[0]), ("y", m[1])) if k) or "1"
z, m, cm = motzkin_forced(-3)
print("Motzkin: Gram rows forced to zero:", ", ".join(sorted(name(u) for u in z)))
print(f"Motzkin: diagonal entry ({name(m)}, {name(m)}) forced to {cm}: no Gram matrix is PSD, for any g")
Mz = lambda x, y, c=-3: x ** 4 * y ** 2 + x ** 2 * y ** 4 + c * x ** 2 * y ** 2 + 1
show("Motzkin at (1, 1)", Mz(1, 1)); show("  grid min on [-2, 2]^2, step 0.01", min(Mz(i / 100, j / 100) for i in range(-200, 201) for j in range(-200, 201)))
def pmul(a, b):
    r = {}
    for ea, ca in a.items():
        for eb, cb in b.items(): e = (ea[0] + eb[0], ea[1] + eb[1]); r[e] = r.get(e, 0) + ca * cb
    return {e: c for e, c in r.items() if c != 0}
def padd(*ps):
    r = {}
    for w, p in ps:
        for e, c in p.items(): r[e] = r.get(e, 0) + w * c
    return {e: c for e, c in r.items() if c != 0}
Mp = {(4, 2): 1, (2, 4): 1, (2, 2): -3, (0, 0): 1}
lhs = pmul({(0, 0): 4, (2, 0): 4, (0, 2): 4}, Mp)       # 4 (1 + x^2 + y^2) M, all integers
sqs = [(4, {(2, 1): 1, (0, 1): -1}), (4, {(1, 2): 1, (1, 0): -1}), (4, {(2, 2): 1, (0, 0): -1}),
       (1, {(1, 3): 1, (3, 1): -1}), (3, {(1, 3): 1, (3, 1): 1, (1, 1): -2})]
rhs = padd(*[(w, pmul(q, q)) for w, q in sqs])
print(f"(1 + x^2 + y^2) M = five squares, exact: {'yes' if lhs == rhs else 'no'}, {len(lhs)} coefficients matched")
gt, _ = sos_bound((7.0, -4.0, 6.0, -4.0, 1.0)); show("try: constant 7, SOS bound", gt)
xt, kt = descend(-2.0); show("try: descent on r from x = -2, lands at", xt); show("  r there", pv(R, xt))
print(f"try: Motzkin with -2: entry forced to {motzkin_forced(-2)[2]}")
show("  grid min on [-2, 2]^2", min(Mz(i / 100, j / 100, -2) for i in range(-200, 201) for j in range(-200, 201))); show("  19/27", 19 / 27)

assert abs(g1 - 4) < 1e-6 and abs(t1 - 1) < 1e-4                 # road 1 against the exact square
assert abs(g1 - gm) < 1e-6 and abs(pv(P, 1.0) - g1) < 1e-6         # road 1 against grid and dual value
assert abs(det(4.01, 0.5) - 2 * 0.5 * (4 - 4.01 - 0.25)) < 1e-12 and ev[0] > -1e-12 and abs(ev[2] - 6) < 1e-12
assert [sq[0] + 4] + sq[1:] == [5, -4, 6, -4, 1] and best_t(P, 4.01)[1] < 0
assert abs(gr - min(pv(R, -3 + i / 10000) for i in range(60001))) < 1e-6 and pv(R, xd) > gr + 1
assert abs(xd - 2 * sqrt(2 / 3) * cos(acos(-0.1875 * sqrt(1.5)) / 3)) < 1e-9 and abs(R[1] + 2 * R[2] * xd + 4 * R[4] * xd ** 3) < 1e-8  # root of r', by the cosine formula
assert cm == -3 and m == (1, 1) and lhs == rhs and z == {(1, 0), (2, 0), (3, 0), (0, 1), (0, 2), (0, 3)}   # Step 6: x, x^2, x^3, y, y^2, y^3 drop out
print("ALL CHECKS PASS")
