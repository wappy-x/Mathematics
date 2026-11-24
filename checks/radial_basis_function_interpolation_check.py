# Radial basis functions -- the check behind the card.  Only math is imported.
# Hand example: nodes 0, 1, 2 with values 1, 2, 0 and the Gaussian exp(-r^2).
# Surface: 30 rate quotes at scattered (maturity, date) points on an illustrative model.
# Roads: Cholesky; Cramer's rule and elimination; Jacobi eigenvalues checked by trace and
# determinant; in 1-D the cubic kernel |r|^3 with a linear tail is the natural cubic spline.
import math

def add(xs):                                    # plain left-to-right sum, as in the Rust
    s = 0.0
    for v in xs: s += v
    return s
def sci(v): return f"{v:.3e}"
def cube(r): return abs(r) * abs(r) * abs(r)
def cholesky(A):                                # A = L L^T; stops at a pivot <= 0
    n = len(A); L = [[0.0] * n for _ in range(n)]
    for j in range(n):
        p = A[j][j] - add(L[j][k] * L[j][k] for k in range(j))
        if p <= 0.0: return None, j, p
        L[j][j] = math.sqrt(p)
        for i in range(j + 1, n): L[i][j] = (A[i][j] - add(L[i][k] * L[j][k] for k in range(j))) / L[j][j]
    return L, n, 0.0
def chol_solve(L, b):                           # forward sweep L y = b, back sweep L^T c = y
    n = len(b); y = [0.0] * n; c = [0.0] * n
    for i in range(n): y[i] = (b[i] - add(L[i][k] * y[k] for k in range(i))) / L[i][i]
    for i in range(n - 1, -1, -1): c[i] = (y[i] - add(L[k][i] * c[k] for k in range(i + 1, n))) / L[i][i]
    return y, c
def gauss(A, b):                                # elimination with partial pivoting
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]; x = [0.0] * n
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(M[i][k])); M[k], M[p] = M[p], M[k]
        for i in range(k + 1, n):
            f = M[i][k] / M[k][k]
            for j in range(k, n + 1): M[i][j] -= f * M[k][j]
    for i in range(n - 1, -1, -1): x[i] = (M[i][n] - add(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def jacobi(A):                                  # all eigenvalues of a symmetric matrix, by rotations
    A = [r[:] for r in A]; n = len(A)
    for sweep in range(60):
        if add(A[i][j] * A[i][j] for i in range(n) for j in range(n) if i != j) < 1e-40: break
        for p in range(n):
            for q in range(p + 1, n):
                if A[p][q] == 0.0: continue
                th = (A[q][q] - A[p][p]) / (2.0 * A[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1.0)); c = 1.0 / math.sqrt(t * t + 1.0); s = t * c
                for k in range(n): A[k][p], A[k][q] = c * A[k][p] - s * A[k][q], s * A[k][p] + c * A[k][q]
                for k in range(n): A[p][k], A[q][k] = c * A[p][k] - s * A[q][k], s * A[p][k] + c * A[q][k]
    return sorted(A[i][i] for i in range(n))
def det3(m): return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])

# --- the hand example -------------------------------------------------------
xs, ys = [0.0, 1.0, 2.0], [1.0, 2.0, 0.0]
A = [[math.exp(-(a - b) * (a - b)) for b in xs] for a in xs]; L, _, _ = cholesky(A); y, c = chol_solve(L, ys)
print(f"hand: e^-1 = {A[0][1]:.9f}, e^-4 = {A[0][2]:.9f}")
for i in range(3): print(f"hand: L row {i + 1}: " + ", ".join(f"{L[i][k]:.9f}" for k in range(i + 1)))
print("hand: forward sweep v = " + ", ".join(f"{v:.9f}" for v in y) + "; coefficients c = " + ", ".join(f"{v:.9f}" for v in c))
D = det3(A); cr = [det3([[ys[i] if k == j else A[i][k] for k in range(3)] for i in range(3)]) / D for j in range(3)]
print(f"hand: determinant {D:.9f} = (L11 L22 L33)^2 = {L[0][0] * L[1][1] * L[2][2] * L[0][0] * L[1][1] * L[2][2]:.9f}; Cramer max gap {sci(max(abs(a - b) for a, b in zip(c, cr)))}")
assert max(abs(a - b) for a, b in zip(c, cr)) < 1e-14 and abs(D - L[0][0] * L[1][1] * L[2][2] * L[0][0] * L[1][1] * L[2][2]) < 1e-14
s = lambda x: add(cj * math.exp(-(x - xj) * (x - xj)) for cj, xj in zip(c, xs))
print(f"hand: s(0.5) = {s(0.5):.9f}; s(1.5) = {s(1.5):.9f}; worst miss at the nodes {sci(max(abs(s(x) - v) for x, v in zip(xs, ys)))}")
ev3 = jacobi(A); print("hand: eigenvalues " + ", ".join(f"{v:.9f}" for v in ev3) + f"; product {ev3[0] * ev3[1] * ev3[2]:.9f}")
assert max(abs(s(x) - v) for x, v in zip(xs, ys)) < 1e-14 and ev3[0] > 0 and abs(ev3[0] * ev3[1] * ev3[2] - D) < 1e-14
_, j, p = cholesky([[math.exp(-(a - b) * (a - b)) for b in (0.0, 1.0, 1.0)] for a in (0.0, 1.0, 1.0)]); print(f"break: node 1 quoted twice -> Cholesky stops at row {j + 1}, pivot {p:.3e}")
assert j == 2 and abs(p) < 1e-15
# --- the surface: 30 scattered quotes -----------------------------------------
st = [20261124]
def u01():                                      # SplitMix64, seed 20261124, then a uniform in [0, 1)
    st[0] = (st[0] + 0x9E3779B97F4A7C15) % 2 ** 64; z = st[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
def R(t, d): return 3.6 + 0.9 * (1 - math.exp(-t / 7)) - 0.3 * d / 250 + 0.2 * math.sin(math.pi * d / 250) * t / 30
def quotes(k): TD = [(0.25 + 29.75 * u01(), 250 * u01()) for _ in range(k)]; return TD, [(t / 30, d / 250) for t, d in TD], [R(t, d) for t, d in TD]
d2 = lambda a, b: (a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1])
T0, true0 = (0.5, 0.5), R(15, 125); G = [(i / 10, j / 10) for i in range(1, 10) for j in range(1, 10)]
def gauss_rbf(X, Y, eps):                       # interpolate the gap from the average quote
    ybar = add(Y) / len(Y); K = [[math.exp(-eps * eps * d2(a, b)) for b in X] for a in X]; L, j, p = cholesky(K)
    if L is None: return None, K, j, p, None
    cg = chol_solve(L, [v - ybar for v in Y])[1]
    f = lambda q: ybar + add(cj * math.exp(-eps * eps * d2(q, x)) for cj, x in zip(cg, X))
    loo = [ck / add(t * t for t in chol_solve(L, [float(i == k) for i in range(len(X))])[0]) for k, ck in enumerate(cg)]   # Rippa: c_k / (A^-1)_kk
    return f, K, L, max(abs(v) for v in cg), loo
worst = lambda f: max(abs(f(q) - R(30 * q[0], 250 * q[1])) for q in G) * 100
TD, X, Y = quotes(30); n = len(X)
print("surface: first 3 quotes (maturity yrs, day, rate %): " + "; ".join(f"{t:.2f}, {d:.1f}, {r:.4f}" for (t, d), r in list(zip(TD, Y))[:3]))
print(f"surface: average quote {add(Y) / n:.6f}%; target 15y on day 125, true {true0:.6f}%")
print("   eps    kappa       lam_min    node resid bp  worst err bp  err at target bp  largest |c|  LOO worst bp")
tab = {}
for eps in (8.0, 4.0, 2.0, 1.0, 0.7, 0.5, 0.3):                  # 0.3 is the break
    f, K, L, big, loo = gauss_rbf(X, Y, eps); ev = jacobi(K)
    if f is None: print(f"break: eps {eps:.1f}, Cholesky stops at row {L + 1}, pivot {sci(big)}; Jacobi lam_min {sci(ev[0])}"); break
    tab[eps] = (ev[-1] / ev[0], max(abs(f(x) - v) for x, v in zip(X, Y)) * 100, worst(f), (f(T0) - true0) * 100, ev, K, L, max(abs(e) for e in loo) * 100, loo)
    print(f"{eps:6.1f}  {sci(tab[eps][0])}  {sci(ev[0])}   {sci(tab[eps][1])}      {tab[eps][2]:9.4f}     {tab[eps][3]:9.4f}       {sci(big)}     {tab[eps][7]:7.4f}")
ev, K, L = tab[2.0][4:7]; v = [1.0] * n
for _ in range(200): w = [add(K[i][k] * v[k] for k in range(n)) for i in range(n)]; lam = math.sqrt(add(t * t for t in w)); v = [t / lam for t in w]
ld = add(math.log(t) for t in ev); lc = 2 * add(math.log(L[i][i]) for i in range(n))
print(f"eps 2 check: trace {add(ev):.9f} (n = 30); log det by eigenvalues {ld:.6f}, by Cholesky {lc:.6f}; lam_max by power {lam:.9f}, by Jacobi {ev[-1]:.9f}")
assert abs(add(ev) - n) < 1e-9 and abs(ld - lc) < 1e-6 and abs(lam - ev[-1]) < 1e-9 and all(tab[e][4][0] > 0 for e in (8.0, 4.0, 2.0, 1.0))
assert tab[1.0][0] > 1e11 and tab[0.7][0] > 1e12 and tab[0.7][2] < tab[2.0][2] / 10 and tab[0.5][1] > 1e6 * tab[2.0][1] and 0.3 not in tab
z2, K2 = [v - add(Y) / n for v in Y], tab[2.0][5]                 # eps 2: leave quote 1 out and refit by brute force
e1 = z2[0] - add(cj * K2[0][k + 1] for k, cj in enumerate(gauss([r[1:] for r in K2[1:]], z2[1:])))
pk, bst = min(tab, key=lambda e: tab[e][7]), min(tab, key=lambda e: tab[e][2])
print(f"leave-one-out, eps 2, quote 1: Rippa {tab[2.0][8][0] * 100:.6f} bp, refit {e1 * 100:.6f} bp; LOO picks eps {pk:.1f}, worst err {tab[pk][2]:.4f} bp; best {tab[bst][2]:.4f} bp at eps {bst:.1f}")
c5 = gauss(tab[0.5][5], z2); w5 = worst(lambda q: add(Y) / n + add(cj * math.exp(-0.25 * d2(q, x)) for cj, x in zip(c5, X)))
print(f"eps 0.5 by elimination with row swaps: worst err {w5:.4f} bp (Cholesky {tab[0.5][2]:.4f} bp; eps 0.7 {tab[0.7][2]:.4f} bp)")
assert abs(tab[2.0][8][0] - e1) < 1e-12 and tab[pk][2] < 1.5 * tab[bst][2] and w5 > tab[0.7][2] and abs(w5 - tab[0.5][2]) < tab[0.5][2] - tab[0.7][2]
# --- thin-plate spline: r^2 log r with the tail b0 + b1 x1 + b2 x2 ----------
tp = lambda r2: 0.0 if r2 == 0 else 0.5 * r2 * math.log(r2); Phi = [[tp(d2(a, b)) for b in X] for a in X]
S = [Phi[i] + [1.0, X[i][0], X[i][1]] for i in range(n)] + [[1.0] * n + [0, 0, 0], [x[0] for x in X] + [0, 0, 0], [x[1] for x in X] + [0, 0, 0]]
sol = gauss(S, Y + [0.0, 0.0, 0.0]); ct, tl = sol[:n], sol[n:]
g = lambda p: tl[0] + tl[1] * p[0] + tl[2] * p[1] + add(cj * tp(d2(p, x)) for cj, x in zip(ct, X))
evp = jacobi(Phi); q = add(ct[i] * add(Phi[i][k] * ct[k] for k in range(n)) for i in range(n)); wt = worst(g)
print(f"thin plate: trace of r^2 log r matrix {add(Phi[i][i] for i in range(n)):.1f}; eigenvalues {sum(1 for t in evp if t > 0)} positive, {sum(1 for t in evp if t < 0)} negative")
print(f"thin plate: side sums of c {sci(abs(add(ct)))}, {sci(abs(add(cj * x[0] for cj, x in zip(ct, X))))}; c^T Phi c = {q:.9f} > 0")
print(f"thin plate: target {g(T0):.6f}%, error {(g(T0) - true0) * 100:.4f} bp; worst on grid {wt:.4f} bp; node resid {sci(max(abs(g(x) - v) for x, v in zip(X, Y)) * 100)} bp")
assert evp[0] < 0 < evp[-1] and q > 0 and wt < 10 and abs(g(T0) - true0) * 100 < 1
_, j, p = cholesky(Phi); nt = gauss(Phi, Y); hn = lambda p: add(cj * tp(d2(p, x)) for cj, x in zip(nt, X))
print(f"break: Cholesky on the thin-plate matrix stops at row {j + 1}, pivot {p:.1f}")
print(f"break: thin plate with no tail, target {hn(T0):.6f}%, error {(hn(T0) - true0) * 100:.4f} bp; worst on grid {worst(hn):.4f} bp")
mq = jacobi([[math.sqrt(1 + 4 * d2(a, b)) for b in X] for a in X]); im = jacobi([[1 / math.sqrt(1 + 4 * d2(a, b)) for b in X] for a in X])
print(f"multiquadric eps 2: {sum(1 for t in mq if t > 0)} positive, {sum(1 for t in mq if t < 0)} negative eigenvalues; inverse multiquadric smallest {sci(im[0])}")
assert j == 0 and worst(hn) > 3 * wt and sum(1 for t in mq if t > 0) == 1 and im[0] > 0
TD2, X2, Y2 = quotes(30); f60, K60, *_ = gauss_rbf(X + X2, Y + Y2, 2.0); e60 = jacobi(K60)   # try: 60 quotes
print(f"try: 60 quotes, eps 2: kappa {sci(e60[-1] / e60[0])}, worst err {worst(f60):.4f} bp (30 quotes: {sci(tab[2.0][0])}, {tab[2.0][2]:.4f} bp)")
assert e60[-1] / e60[0] > 10 * tab[2.0][0] and worst(f60) < tab[2.0][2]
# --- 1-D: the cubic kernel |r|^3 + linear tail is the natural cubic spline ----
def z(t): x = t / 2.0; l1 = (1 - math.exp(-x)) / x; return 4.5 - 0.2 * l1 - 2.0 * (l1 - math.exp(-x))
tq = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0]; zq = [z(t) for t in tq]; m = len(tq)
C = [[cube(a - b) for b in tq] + [1.0, a] for a in tq] + [[1.0] * m + [0, 0], tq + [0, 0]]
cc = gauss(C, zq + [0.0, 0.0]); r15 = cc[m] + cc[m + 1] * 15 + add(cj * cube(15 - t) for cj, t in zip(cc, tq))
h = [tq[i + 1] - tq[i] for i in range(m - 1)]                   # natural spline: moments M, with M = 0 at both ends
T = [[2 * (h[i] + h[i + 1]) if k == i else (h[max(i, k)] if abs(i - k) == 1 else 0.0) for k in range(m - 2)] for i in range(m - 2)]
M = [0.0] + gauss(T, [6 * ((zq[i + 2] - zq[i + 1]) / h[i + 1] - (zq[i + 1] - zq[i]) / h[i]) for i in range(m - 2)]) + [0.0]
A5, B5 = tq[6] - 15, 15 - tq[5]; sp = (M[5] * cube(A5) + M[6] * cube(B5)) / (6 * h[5]) + (zq[5] / h[5] - M[5] * h[5] / 6) * A5 + (zq[6] / h[5] - M[6] * h[5] / 6) * B5
print(f"1-D yield curve, 15y: cubic kernel {r15:.6f}%, natural spline {sp:.6f}%, true {z(15):.6f}%")
assert abs(r15 - sp) < 1e-9 and abs(sp - 4.211993) < 1e-6
print(f"cost, n = 30: Cholesky about n^3/3 = {n ** 3 // 3} flops; thin-plate system n + 3 = 33, about 2(33)^3/3 = {2 * 33 ** 3 // 3} flops")
print("chart, eps: " + ", ".join(f"{e:.1f}" for e in tab))
print("chart, log10 kappa: " + ", ".join(f"{math.log10(tab[e][0]):.2f}" for e in tab))
print("chart, log10 worst err bp: " + ", ".join(f"{math.log10(tab[e][2]):.2f}" for e in tab))
print("ALL CHECKS PASS")
