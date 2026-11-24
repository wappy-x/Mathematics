# Randomised SVD and the range finder -- the check behind the card.  Standard library only.
# A 2,000 by 500 matrix with singular values 0.8^(j-1), built from mirrors so it is dense.
# Road one: the randomised SVD on the dense matrix, its error by the Pythagoras identity
# and by summing every entry of the residual.  Road two: the same run in the matrix's own
# singular axes, where a Gaussian sketch has the same law.  Road three: 200 trials against
# the Halko-Martinsson-Tropp bound and the known best error from Eckart-Young.
from math import sqrt, log, log10, cos, pi

S, MASK = [2026], 2**64 - 1
def nxt():                                   # SplitMix64, seed 2026
    S[0] = (S[0] + 0x9E3779B97F4A7C15) & MASK; z = S[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def unif(): return ((nxt() >> 11) + 0.5) * 2.0**-53
def gauss(): return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())   # Box-Muller
def tsum(xs):                                 # plain left-to-right sum (built-in sum compensates)
    s = 0.0
    for x in xs: s += x
    return s
def dot(x, y):                               # plain left-to-right sum, as in the Rust
    s = 0.0
    for a, b in zip(x, y): s += a * b
    return s
def mirror(x, v, vv): c = 2.0 * dot(x, v) / vv; return [a - c * b for a, b in zip(x, v)]
def orth(Y):                                 # modified Gram-Schmidt, run twice per column
    Q = []
    for y in Y:
        w = list(y)
        for _ in range(2):
            for q in Q: c = dot(q, w); w = [a - c * b for a, b in zip(w, q)]
        r = sqrt(dot(w, w)); Q.append([a / r for a in w])
    return Q
def jeig(G):                                 # Jacobi eigenvalues and vectors of a small symmetric G
    n = len(G); G = [r[:] for r in G]; W = [[float(i == j) for j in range(n)] for i in range(n)]
    for _ in range(30):
        if tsum(G[i][j] * G[i][j] for i in range(n) for j in range(n) if i != j) < 1e-32: break
        for p in range(n - 1):
            for q in range(p + 1, n):
                if abs(G[p][q]) < 1e-300: continue
                th = (G[q][q] - G[p][p]) / (2 * G[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(1 + th * th)); c = 1 / sqrt(1 + t * t); s = c * t
                for M in (G, W):
                    for r in M: a, b = r[p], r[q]; r[p] = c * a - s * b; r[q] = s * a + c * b
                G[p], G[q] = [c * a - s * b for a, b in zip(G[p], G[q])], [s * a + c * b for a, b in zip(G[p], G[q])]
    o = sorted(range(n), key=lambda i: -G[i][i])
    return [G[i][i] for i in o], [[W[r][i] for r in range(n)] for i in o]
def rsvd(mul, mult, Om, q):                  # range finder, q power steps, then the small SVD
    Q = orth(mul(Om))
    for _ in range(q): Q = orth(mul(orth(mult(Q))))
    B = mult(Q)                              # rows of B = Q^T A, each n long
    ev, W = jeig([[dot(x, y) for y in B] for x in B])
    return Q, B, ev, W

m, n, k, p = 2000, 500, 10, 5; l = k + p
sig = [0.8**j for j in range(n)]
tot = tsum(s * s for s in sig); best = sqrt(tsum(s * s for s in sig[k:]))
vU = [[gauss() for _ in range(m)] for _ in range(2)]; vV = [[gauss() for _ in range(n)] for _ in range(2)]
def VT(x):                                   # V^T x, with V = H1 H2 (two mirrors in R^500)
    for v in vV: x = mirror(x, v, dot(v, v))
    return x
cols = []
for j in range(n):                           # column j of A = U [Sigma; 0] V^T, U = G1 G2 in R^2000
    c = [s * vt for s, vt in zip(sig, VT([float(i == j) for i in range(n)]))] + [0.0] * (m - n)
    for v in reversed(vU): c = mirror(c, v, dot(v, v))
    cols.append(c)
rows = [list(r) for r in zip(*cols)]
fro2 = tsum(dot(r, r) for r in rows)
print(f"A: {m} x {n}, sigma_j = 0.8^(j-1); ||A||_F^2 from entries {fro2:.10f}, from sigmas {tot:.10f}")
print(f"best rank-{k} error: Frobenius {best:.6f} = {100 * best / sqrt(tot):.1f}% of ||A||_F {sqrt(tot):.6f}, spectral sigma_11 {sig[k]:.6f}")
print("bound factor sqrt(1 + k/(p-1)) for p = 2, 5, 10, 20: " + " ".join(f"{sqrt(1 + k / (pp - 1)):.4f}" for pp in (2, 5, 10, 20)))
print(f"expected-error bounds at p = {p}: rank-{l} projection {sqrt(1 + k / (p - 1)) * best:.6f}, rank-{k} answer {sqrt(2 + k / (p - 1)) * best:.6f} (factor {sqrt(2 + k / (p - 1)):.4f})")
assert abs(fro2 - tot) < 1e-10 * tot

dmul = lambda X: [[dot(r, x) for r in rows] for x in X]
dmult = lambda X: [[dot(c, x) for c in cols] for x in X]
fmul = lambda X: [[s * a for s, a in zip(sig, x)] for x in X]          # A in its own axes: Sigma
Om = [[gauss() for _ in range(n)] for _ in range(l)]
res = {}
for q in (0, 1):
    Q, B, ev, W = rsvd(dmul, dmult, Om, q)
    proj, trunc = sqrt(tot - tsum(ev)), sqrt(tot - tsum(ev[:k]))
    _, _, evf, _ = rsvd(fmul, fmul, [VT(w) for w in Om], q)
    res[q] = (Q, B, ev, W, trunc)
    print(f"q = {q}: {2 + 2 * q} products with A or A^T, m n l = {m * n * l} multiplications each, {(2 + 2 * q) * m * n * l} in all")
    print(f"q = {q}: error of QQ^T A (rank {l}) {proj:.6f}, ratio to best {proj / best:.4f}; rank-{k} error {trunc:.6f}, ratio {trunc / best:.4f}, {100 * trunc / sqrt(tot):.1f}% of ||A||_F")
    print(f"q = {q}: same sketch in the singular axes, rank-{k} error {sqrt(tot - tsum(evf[:k])):.6f}")
    print(f"q = {q}: log10 of estimated sigma_1..15: " + " ".join(f"{log10(sqrt(e)):.2f}" for e in ev))
    assert abs(sqrt(tot - tsum(evf[:k])) - trunc) < 1e-10 and trunc >= best * (1 - 1e-12)
print("true log10 sigma_1..15: " + " ".join(f"{log10(s):.2f}" for s in sig[:l]))
print(f"cost: m n^2 = {m * n * n}, a dense SVD's leading term; ratio to the q = 0 products {m * n * n / (2 * m * n * l):.1f}")

Q, B, ev, W, trunc = res[0]                  # road one, second half: sum every residual entry
Uk = [[dot(w, [qq[r] for qq in Q]) for w in W[:k]] for r in range(m)]
Ck = [[dot(w, [b[j] for b in B]) for j in range(n)] for w in W[:k]]
direct = 0.0
for r in range(m):
    a = rows[r][:]
    for t in range(k): ct = Uk[r][t]; a = [x - ct * y for x, y in zip(a, Ck[t])]
    direct += dot(a, a)
print(f"rank-{k} error by summing all {m * n} residual entries {sqrt(direct):.6f}; Pythagoras identity {trunc:.6f}")
assert abs(sqrt(direct) - trunc) < 1e-9
e10 = sqrt(tot - tsum(dot(b, b) for b in B[:k]))   # keep Q's first k columns, skip the small SVD
print(f"first {k} columns of Q, no small SVD: error {e10:.6f}, ratio {e10 / best:.4f}")

Qf, Bf, evf, _ = rsvd(fmul, fmul, [VT(w) for w in Om], 0)   # a posteriori estimate, 10 fresh vectors
def resid(x):                                # (I - Q Q^T) Sigma x
    y = [s * a for s, a in zip(sig, x)]
    for qq in Qf: c = dot(qq, y); y = [a - c * b for a, b in zip(y, qq)]
    return y
tests = [sqrt(dot(y, y)) for y in (resid([gauss() for _ in range(n)]) for _ in range(10))]
estF, bound2 = sqrt(tsum(t * t for t in tests) / 10), 10 * sqrt(2 / pi) * max(tests)
x = [1.0] * n
for _ in range(300):                         # true spectral error by power iteration
    y = resid(x); z = [s * a for s, a in zip(sig, y)]; nz = sqrt(dot(z, z)); x = [a / nz for a in z]
true2, trueF = sqrt(dot(resid(x), resid(x))), sqrt(tot - tsum(evf))
print(f"a posteriori, 10 test vectors: Frobenius estimate {estF:.6f} vs true {trueF:.6f}, ratio {estF / trueF:.4f}")
print(f"a posteriori, spectral: bound 10 sqrt(2/pi) max {bound2:.6f} vs true {true2:.6f}, ratio {bound2 / true2:.2f}")
assert 0.5 < estF / trueF < 2.0 and bound2 >= true2

def trial(ll, q):                            # one fresh sketch, in the singular axes
    _, _, e, _ = rsvd(fmul, fmul, [[gauss() for _ in range(n)] for _ in range(ll)], q)
    return sqrt(max(tot - tsum(e), 0.0)) / best, sqrt(max(tot - tsum(e[:k]), 0.0)) / best
T = 200
for ll, q in ((l, 0), (l, 1), (k, 0)):
    rs = [trial(ll, q) for _ in range(T)]
    for i, name in ((0, f"rank-{ll} projection"), (1, f"rank-{k} answer"))[ll == k:]:
        v = [r[i] for r in rs]; mu = tsum(v) / T; se = sqrt(tsum((a - mu) * (a - mu) for a in v) / (T - 1) / T)
        print(f"{T} trials, l = {ll}, q = {q}, {name}: mean ratio {mu:.4f} (se {se:.4f}), worst {max(v):.4f}")
        if ll == l and q == 0: assert mu + 3 * se <= sqrt(1 + k / (p - 1) + i)   # sqrt(3.5), then sqrt(4.5)
        if q == 1 and i == 1: assert abs(mu - 1.0) < 0.01
    assert min(r[1] for r in rs) >= 1 - 1e-12

qq = 12                                      # power steps with no orthonormalising in between
Yb = [[s**(2 * qq + 1) * a for s, a in zip(sig, w)] for w in (VT(w) for w in Om)]
Qb = orth(Yb); Bb = fmul(Qb)
lost = max(abs(dot(a, b) - (i == j)) for i, a in enumerate(Qb) for j, b in enumerate(Qb))
print(f"break, q = {qq} with no re-orthonormalising: loss of orthogonality {lost:.4f}; ||A||_F^2 - ||B||_F^2 = {tot - tsum(dot(b, b) for b in Bb):.4f}")
assert lost > 0.1
print("ALL CHECKS PASS")
