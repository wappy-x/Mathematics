# Generalised eigenproblems -- the check behind the card.  Standard library only;
# nothing imported holds an answer.  Masses 2 kg and 1 kg, springs 3 N/m (wall to
# first mass) and 2 N/m (between): K x = lam M x.  Roots of det(K - lam M), Cholesky
# reduction, M-orthogonal modes, a light second mass down to a massless one, eigenvalue
# counts by Sylvester's law, and shift-invert Lanczos on a 200-mass chain.
from functools import reduce
from math import cos, log10, pi, sqrt

U, X0, T, H, NCH, KL = 2.0 ** -53, (0.10, 0.0), 5.0, 1e-3, 200, 12
DIAL = (1.0, 1e-2, 1e-4, 1e-6, 1e-8)

def sci(x): m, e = f"{x:.3e}".split("e"); return f"{m}e{int(e)}"
def row(label, vals): print(f"{label:<42}" + "".join(f"{v:>12.6f}" for v in vals))
def srow(label, vals): print(f"{label:<42}" + "".join(f"{sci(v):>12}" for v in vals))

def eig2(p, q, r):                  # textbook formula for [[p, q], [q, r]]: half-trace -/+ root
    h = (p + r) / 2.0; s = sqrt(h * h - (p * r - q * q))
    return h - s, h + s

def exact(m2):                      # det(K - lam M) = 2 m2 lam^2 - (4 + 5 m2) lam + 6, no cancellation
    a, b = 2.0 * m2, 4.0 + 5.0 * m2
    lo = 12.0 / (b + sqrt(b * b - 24.0 * a))
    return lo, (6.0 / (a * lo) if a > 0 else float("inf"))

def via_m(m2):                      # reduce with M = L L^T: C = L^-1 K L^-T
    l1, l2 = sqrt(2.0), sqrt(m2)
    return 5.0 / (l1 * l1), -2.0 / (l1 * l2), 2.0 / (l2 * l2)

def via_k(m2):                      # reduce with K = G G^T: B = G^-1 M G^-T has eigenvalues 1/lam
    g11 = sqrt(5.0); g21 = -2.0 / g11; g22 = sqrt(2.0 - g21 * g21)
    return 2.0 / (g11 * g11), -2.0 * g21 / (g11 * g11 * g22), 2.0 * g21 * g21 / (g11 * g11 * g22 * g22) + m2 / (g22 * g22)

def count_below(a, b, m, s):        # negative pivots of K - s M = L D L^T: eigenvalues below s
    n, d = 0, 1.0
    for i in range(len(a)):
        d = a[i] - s * m[i] - (b[i - 1] * b[i - 1] / d if i else 0.0)
        if d == 0.0: d = -1e-300
        n += d < 0.0
    return n

def bisect(a, b, m, j):             # j-th smallest eigenvalue of the tridiagonal pencil
    bb = [0.0] + [abs(v) for v in b] + [0.0]
    hi = max((abs(a[i]) + bb[i] + bb[i + 1]) / m[i] for i in range(len(a))); lo = -hi
    for _ in range(200):
        mid = (lo + hi) / 2.0
        if count_below(a, b, m, mid) >= j: hi = mid
        else: lo = mid
    return (lo + hi) / 2.0

def tot(xs): return reduce(lambda s, v: s + v, xs, 0.0)       # plain left-to-right sum
def mdot(x, y, m): return tot(m[i] * x[i] * y[i] for i in range(len(x)))
def kmul(a, b, x): return [a[i] * x[i] + (b[i - 1] * x[i - 1] if i else 0.0) + (b[i] * x[i + 1] if i < len(x) - 1 else 0.0) for i in range(len(x))]

def lanczos(op, m, k):              # k steps in the M inner product, full reorthogonalisation
    q = [1.0] * len(m); s = sqrt(mdot(q, q, m)); Q, al, be = [[v / s for v in q]], [], []
    for _ in range(k):
        w = op(Q[-1]); al.append(mdot(w, Q[-1], m))
        for _ in range(2):
            for qq in Q: c = mdot(w, qq, m); w = [w[i] - c * qq[i] for i in range(len(w))]
        s = sqrt(mdot(w, w, m)); be.append(s); Q.append([v / s for v in w])
    return al, be

l1, l2 = exact(1.0); om = [sqrt(l1), sqrt(l2)]
row("det(K - lam M) = a lam^2 + b lam + c", [2.0, -9.0, 6.0])
row("lam1, lam2 (1/s^2), stable formula", [l1, l2])
row("omega (rad/s), period (s)", om + [2 * pi / w for w in om])
print("Sylvester counts below 0.5, 2, 4:", [count_below([5.0, 2.0], [-2.0], [2.0, 1.0], s) for s in (0.5, 2.0, 4.0)])
bl = [bisect([5.0, 2.0], [-2.0], [2.0, 1.0], j) for j in (1, 2)]
row("lam1, lam2 by bisection on the counts", bl)
C = via_m(1.0); ce = eig2(*C)
row("L = chol(M) diagonal", [sqrt(2.0), 1.0])
row("C = L^-1 K L^-T: c11 c21 c22, trace, det", list(C) + [C[0] + C[2], C[0] * C[2] - C[1] * C[1]])
row("eigenvalues of C", list(ce))
V = [[1.0, (5.0 - 2.0 * lam) / 2.0] for lam in (l1, l2)]
Y = [[C[1], lam - C[0]] for lam in ce]                              # eigenvectors of C
VB = [[y[0] / sqrt(2.0), y[1] / 1.0] for y in Y]; VB = [[1.0, v[1] / v[0]] for v in VB]   # v = L^-T y
row("mode shapes v1, v2 (second entry, first = 1)", [V[0][1], V[1][1]])
row("same, from C's eigenvectors y, v = L^-T y", [VB[0][1], VB[1][1]])
row("wrong: C's eigenvectors read as shapes", [Y[0][1] / Y[0][0], Y[1][1] / Y[1][0]])
KM, MM = [[5.0, -2.0], [-2.0, 2.0]], [2.0, 1.0]
res = [max(abs(tot(KM[i][j] * V[k][j] for j in range(2)) - lam * MM[i] * V[k][i]) for i in range(2)) for k, lam in ((0, l1), (1, l2))]
srow("residuals |K v - lam M v|", res)
pdot, mx, kx = V[0][0] * V[1][0] + V[0][1] * V[1][1], mdot(V[0], V[1], MM), tot(V[0][i] * KM[i][j] * V[1][j] for i in range(2) for j in range(2))
print(f"v1.v2 plain {pdot:.6f}   v1^T M v2 {sci(mx)}   v1^T K v2 {sci(kx)}")
cm = [mdot(v, X0, MM) / mdot(v, v, MM) for v in V]; cp = [tot(v[i] * X0[i] for i in range(2)) / tot(t * t for t in v) for v in V]
row("release (0.1, 0): c1, c2 (m); v^T M v", cm + [mdot(v, v, MM) for v in V])
row("rebuilt start c1 v1 + c2 v2 (m)", [cm[0] * V[0][i] + cm[1] * V[1][i] for i in range(2)])
row("wrong: shares by the plain dot", cp)
row("wrong: rebuilt start", [cp[0] * V[0][i] + cp[1] * V[1][i] for i in range(2)])
en = [0.5 * lam * c * c * mdot(v, v, MM) for lam, c, v in zip((l1, l2), cm, V)]
E0 = 0.5 * (5.0 * X0[0] * X0[0] - 4.0 * X0[0] * X0[1] + 2.0 * X0[1] * X0[1])     # x^T K x / 2
row("energy (J): start, mode 1, mode 2, sum", [E0] + en + [tot(en)])
x, v = list(X0), [0.0, 0.0]; acc = lambda x: [-(5.0 * x[0] - 2.0 * x[1]) / 2.0, -(-2.0 * x[0] + 2.0 * x[1])]
a0 = acc(x)
for _ in range(round(T / H)):
    v = [v[i] + H / 2 * a0[i] for i in range(2)]; x = [x[i] + H * v[i] for i in range(2)]; a0 = acc(x); v = [v[i] + H / 2 * a0[i] for i in range(2)]
xm = [tot(cm[k] * cos(om[k] * T) * V[k][i] for k in range(2)) for i in range(2)]
row("x(5 s) from modes; from 5,000 leapfrog steps", xm + x)
ke = eig2(5.0, -2.0, 2.0)
row("wrong: eigenvalues of K alone, omegas", list(ke) + [sqrt(t) for t in ke])
dial = []
for m2 in DIAL:
    ex = exact(m2)[0]; cc = via_m(m2); a, big = eig2(*cc); bk = 1.0 / eig2(*via_k(m2))[1]
    sm = (cc[0] * cc[2] - cc[1] * cc[1]) / big                       # same C, small root as det(C) / lam_max: no subtraction
    dial.append((abs(a - ex) / ex, abs(bk - ex) / ex, U * big / ex, abs(sm - ex) / ex)); em, ek, bd, es = dial[-1]
    print(f"m2 {sci(m2):>9}  lam1 {ex:.9f}  kappa(M) {sci(2.0 / m2 if m2 < 2 else m2 / 2):>9}  M h-s {sci(em):>9}  M det/max {sci(es):>9}  K-route {sci(ek):>9}  estimate {sci(bd):>9}  ratio {em / bd:.3f}")
B0 = via_k(0.0); mu = eig2(*B0)
print(f"m2 0: chol(M) fails (pivot m2 = 0); det(K - lam M) = 6 - 4 lam, lam1 = {exact(0.0)[0]:.6f}, lam2 = {exact(0.0)[1]}")
print(f"m2 0: K-route mu {sci(mu[0])} {mu[1]:.6f}; lam1 = 1/mu_max = {1.0 / mu[1]:.6f}; (alpha, beta) = (3, 2), (1, 0)")
mc = [2.0 if i % 2 == 0 else 1.0 for i in range(NCH)]; ks = [3.0 if i % 2 == 0 else 2.0 for i in range(NCH)] + [0.0]
ac, bc = [ks[i] + ks[i + 1] for i in range(NCH)], [-ks[i + 1] for i in range(NCH - 1)]
ref = [bisect(ac, bc, mc, j) for j in (1, 2, 3)]
d, lf = [ac[0]], []
for i in range(1, NCH): lf.append(bc[i - 1] / d[-1]); d.append(ac[i] - lf[-1] * bc[i - 1])
def solve(y):                       # K x = y with the stored L D L^T: 5n - 4 flops
    x = y[:]
    for i in range(1, NCH): x[i] -= lf[i - 1] * x[i - 1]
    x = [x[i] / d[i] for i in range(NCH)]
    for i in range(NCH - 2, -1, -1): x[i] -= lf[i] * x[i + 1]
    return x
si = lanczos(lambda q: solve([mc[i] * q[i] for i in range(NCH)]), mc, KL)
pl = lanczos(lambda q: [t / mc[i] for i, t in enumerate(kmul(ac, bc, q))], mc, KL)
def ritz(al, be, k, j, inv): return 1.0 / bisect(al[:k], be[:k - 1], [1.0] * k, k + 1 - j) if inv else bisect(al[:k], be[:k - 1], [1.0] * k, j)
sl, pv = [ritz(*si, KL, j, True) for j in (1, 2, 3)], ritz(*pl, KL, 1, False)
srow("chain: lam1..3 by bisection; lam2/lam1", ref + [ref[1] / ref[0]])
srow("shift-invert Lanczos, 12 steps", sl)
srow("relative gaps to bisection", [abs(sl[j] - ref[j]) / ref[j] for j in range(3)])
srow("plain Lanczos lam1, relative gap", [pv, abs(pv - ref[0]) / ref[0]])
print(f"cost: 12 solves of {5 * NCH - 4} flops each = {12 * (5 * NCH - 4):,} flops after the {3 * (NCH - 1)}-flop factorisation")
for k in range(1, KL + 1):
    es, ep = (abs(ritz(*s, k, 1, inv) - ref[0]) / ref[0] for s, inv in ((si, True), (pl, False)))
    print(f"figure, k {k}, shift-invert {log10(max(es, 1e-16)):.2f}, plain {log10(max(ep, 1e-16)):.2f}")
assert max(abs(bl[0] - l1), abs(bl[1] - l2), abs(ce[0] - l1), abs(ce[1] - l2)) < 1e-12   # three roads to lam
assert max(abs(VB[k][1] - V[k][1]) for k in range(2)) < 1e-12 and max(res) < 1e-14
assert abs(mx) < 1e-14 and abs(kx) < 1e-13 and abs(pdot + 1.0) < 1e-12      # M-orthogonal, not plain
assert max(abs(xm[i] - x[i]) for i in range(2)) < 1e-5 and abs(tot(en) - E0) < 1e-15
assert all(ek < 1e-14 and es < 1e-14 for _, ek, _, es in dial) and dial[-1][0] > 1e-11 and all(em <= 4 * bd for em, _, bd, _ in dial)
assert abs(1.0 / mu[1] - exact(0.0)[0]) < 1e-15 and max(abs(sl[j] - ref[j]) / ref[j] for j in range(3)) < 1e-10
assert abs(pv - ref[0]) / ref[0] > 1e-2
print("ALL CHECKS PASS")
