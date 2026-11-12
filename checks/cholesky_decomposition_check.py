# Cholesky -- the check behind the card.  Standard library only; nothing
# imported holds an answer.  Three shares with volatilities 20%, 30% and 25%
# and correlations 0.6, 0.28 and 0.5 give a covariance matrix in percent
# squared.  Factor it as L L^T, count flops against LU, solve with the
# factor, walk to the edge of positive definiteness, and mix random draws.
from math import exp, sqrt

A = [[400.0, 360.0, 140.0], [360.0, 900.0, 375.0], [140.0, 375.0, 625.0]]
SPOTS, U, N, SEED, BIG = (80.0, 100.0, 120.0), 2.0 ** -53, 20000, 20261111, 500
DIAL = (375.0, 675.0, 697.5, 701.25, 702.0, 705.0, 712.5)   # a23 = 750 x rho23

def cov(a23): return [[400.0, 360.0, 140.0], [360.0, 900.0, a23], [140.0, a23, 625.0]]

def chol(a):                                # column by column; None at a pivot <= 0
    n, f = len(a), 0
    L = [[0.0] * n for _ in range(n)]
    for j in range(n):
        s = a[j][j]
        for k in range(j): s -= L[j][k] * L[j][k]; f += 2
        if s <= 0.0: return None, s, f
        L[j][j] = sqrt(s); f += 1
        for i in range(j + 1, n):
            t = a[i][j]
            for k in range(j): t -= L[i][k] * L[j][k]; f += 2
            L[i][j] = t / L[j][j]; f += 1
    return L, s, f

def lu_flops(a):                            # elimination, counted as on the LU card
    m, n, f = [r[:] for r in a], len(a), 0
    for k in range(n):
        for i in range(k + 1, n):
            r = m[i][k] / m[k][k]; f += 1
            for j in range(k + 1, n): m[i][j] -= r * m[k][j]; f += 2
    return f

def chol_solve(L, b):                       # forward L y = b, then back L^T x = y
    n = len(b); y = [0.0] * n; x = [0.0] * n
    for i in range(n):
        s = b[i]
        for k in range(i): s -= L[i][k] * y[k]
        y[i] = s / L[i][i]
    for i in reversed(range(n)):
        s = y[i]
        for k in range(i + 1, n): s -= L[k][i] * x[k]
        x[i] = s / L[i][i]
    return x, y

def det3(m):
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))

def cramer(m, b):                           # exact on these entries until the final division
    return [det3([[b[i] if j == c else m[i][j] for j in range(3)] for i in range(3)]) / det3(m) for c in range(3)]

def kappa1(m):                              # ||A||_1 times ||A^-1||_1, the inverse by Cramer's rule
    cols = [cramer(m, [1.0 if i == c else 0.0 for i in range(3)]) for c in range(3)]
    return max(sum(abs(m[i][c]) for i in range(3)) for c in range(3)) * max(sum(abs(v) for v in col) for col in cols)

def backward(a, L):                         # worst |A - L L^T| entry over sqrt(a_ii a_jj)
    n = len(a)
    return max(abs(sum(L[i][k] * L[j][k] for k in range(n)) - a[i][j]) / sqrt(a[i][i] * a[j][j]) for i in range(n) for j in range(n))

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, (z ^ (z >> 31)) >> 11

def sci(x): m, e = f"{x:.3e}".split("e"); return f"{m}e{int(e)}"
def row(label, vals): print(f"{label:<44}" + "".join(f"{v:>12.6f}" for v in vals))
def srow(label, vals): print(f"{label:<44}" + "".join(f"{sci(v):>12}" for v in vals))
def fc(n): return (2 * n ** 3 + 3 * n ** 2 + n) // 6      # Cholesky flops, square roots included
def fl(n): return (4 * n ** 3 - 3 * n ** 2 - n) // 6      # LU flops

L, piv, f3 = chol(A)
hand = [[20.0, 0.0, 0.0], [18.0, 24.0, 0.0], [7.0, 249.0 / 24.0, sqrt(625.0 - 49.0 - (249.0 / 24.0) ** 2)]]
hand_gap = max(abs(L[i][j] - hand[i][j]) for i in range(3) for j in range(3))
growth = max(abs(L[i][j]) / sqrt(A[i][i]) for i in range(3) for j in range(3))
for i in range(3): row(f"L row {i + 1}, then pivot {i + 1}", L[i] + [L[i][i] * L[i][i]])
row("gap to hand factor; max |l_ij|/sqrt(a_ii)", [hand_gap, growth])
D = [[v / 10000.0 for v in r] for r in cov(702.0)]          # the edge matrix, written in decimals
LD, pd, _ = chol(D)
gamma = 4 * U / (1 - 4 * U)
srow("backward error: A, decimal edge; gamma_4", [backward(A, L), backward(D, LD), gamma, backward(D, LD) / gamma])
w1, (wc, yc) = cramer(A, [1.0] * 3), chol_solve(L, [1.0] * 3)
gc = max(abs(wc[i] - w1[i]) / abs(w1[i]) for i in range(3))
mv = [v / sum(wc) for v in wc]
var = sum(mv[i] * A[i][j] * mv[j] for i in range(3) for j in range(3))
srow("forward step y, from L y = ones", yc)
srow("back step x = A^-1 ones, from L^T x = y", wc)
srow("worst relative gap to Cramer's rule", [gc])
row("minimum-variance weights", mv)
row("w^T A w, 1/(1^T A^-1 1), volatility", [var, 1.0 / sum(wc), sqrt(var)])
B = [[float(min(i, j) + 1) for j in range(40)] for i in range(40)]   # a random walk's covariance: L is all ones
LB, _, f40 = chol(B)
ones_gap = max(abs(LB[i][j] - (1.0 if j <= i else 0.0)) for i in range(40) for j in range(40))
for n, c, l in ((3, f3, lu_flops(A)), (40, f40, lu_flops(B))):
    print(f"n = {n:<3} flops counted: Cholesky {c:>7,}  LU {l:>7,}   formulas {fc(n):>7,} {fl(n):>7,}")
print(f"n = {BIG} Cholesky {fc(BIG):,}  LU {fl(BIG):,}  ratio {fc(BIG) / fl(BIG):.6f}  two solves {2 * BIG * BIG:,}")
dial = []
for a23 in DIAL:
    Lm, p, _ = chol(cov(a23))
    d = det3(cov(a23)) / 230400.0
    dial.append((p, d, Lm is not None))
    k = sci(kappa1(cov(a23))) if d > 0 else "none"
    print(f"rho23 {a23 / 750:.6f}  third pivot {p:>11.6f}  det/det2 {d:>11.6f}  kappa1 {k:>9}  {'passes' if Lm else 'fails'}")
for t in range(10):
    Lt, _, _ = chol(cov(750.0 * 0.104 * t))
    print(f"figure, rho23 {0.104 * t:.3f}, L33 {Lt[2][2] if Lt else 0.0:.2f}")
print(f"edge in percent^2: third pivot {dial[4][0]:.6f}, {'fails' if dial[4][0] <= 0 else 'passes'}; det2 = {400.0 * 900.0 - 360.0 * 360.0:.0f}")
print(f"edge in decimals: third pivot {sci(pd)}, L33 {sci(LD[2][2])}, {'passes' if LD else 'fails'}")
state, sxx, first = SEED, [[0.0] * 3 for _ in range(3)], None
for s in range(N):
    z = []
    for i in range(3):
        t = 0.0
        for _ in range(12): state, r = splitmix(state); t += r * 2.0 ** -53
        z.append(t - 6.0)                   # 12 uniforms minus 6: mean 0, variance 1
    v = [sum(L[i][k] * z[k] for k in range(3)) for i in range(3)]   # correlated shocks, percent
    if first is None: first = (z, v)
    for i in range(3):
        for j in range(3): sxx[i][j] += v[i] * v[j]
S = [[v / N for v in r] for r in sxx]
row("first draw z", first[0])
row("first draw v = L z, percent", first[1])
row("prices a year on, from $80, $100, $120", [SPOTS[i] * exp(first[1][i] / 100 - A[i][i] / 20000) for i in range(3)])  # lognormal, no drift
for i in range(3): row(f"sample covariance row {i + 1}, {N} draws", S[i])
se = max(abs(S[i][j] - A[i][j]) / sqrt((A[i][i] * A[j][j] + A[i][j] ** 2) / N) for i in range(3) for j in range(3))
row("worst gap to A, in standard errors", [se])
TL = [[sum(L[k][i] * L[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
row("wrong: L^T as the mixer, volatilities", [sqrt(TL[i][i]) for i in range(3)])
row("wrong: L^T as the mixer, correlation 1-2", [TL[0][1] / sqrt(TL[0][0] * TL[1][1])])
assert hand_gap < 1e-12 and growth <= 1.0          # the factor by hand; no entry above its diagonal's root
assert backward(D, LD) <= gamma                     # the rounding bound holds
assert gc < 1e-13 and abs(var - 1.0 / sum(wc)) < 1e-9
assert ones_gap == 0.0 and (f3, f40, lu_flops(B)) == (fc(3), fc(40), fl(40))
assert all(abs(p - d) < 1e-9 for p, d, _ in dial)      # last pivot = det / leading 2 by 2 det
assert [ok for _, _, ok in dial] == [True] * 4 + [False] * 3 and pd > 0   # the verdicts
assert se < 4.0
print("ALL CHECKS PASS")
