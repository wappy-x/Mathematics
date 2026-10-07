# Multivariate normal -- the check behind the card.  Standard library only.
# Three daily share returns in percent (bank, insurer, miner) are built as
# X = MU + L Z from three independent standard normal draws Z.  Roads: the
# covariance by L times L-transpose, by simulation, and L recovered from the
# covariance alone by Cholesky; the portfolio's bad-day chance by the normal
# formula and by counting simulated days; the density by two routes.
from math import sqrt, log, exp, pi

NAMES = ["bank", "insurer", "miner"]
MU = [0.04, 0.03, 0.05]                          # average daily return, percent
L = [[1.0, 0.0, 0.0], [0.9, 1.2, 0.0], [1.2, 0.0, 1.6]]
W = [50.0, 30.0, 20.0]                           # dollars per 1% move: $5,000, $3,000, $2,000
Z_DAY = [1.0, -0.5, 0.25]                        # one day's three draws
LOSS, N, BINS = -200.0, 200000, [-300 + 50 * k for k in range(13)]

def tr(A): return [list(r) for r in zip(*A)]
def mul(A, B): return [[sum(a * b for a, b in zip(r, c)) for c in zip(*B)] for r in A]
def mv(A, v): return [sum(a * b for a, b in zip(r, v)) for r in A]
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def row(v, f="{:8.4f}"): return " ".join(f.format(x) for x in v)

def cholesky(S):                                 # the factor, and each pivot before its root
    n, piv = len(S), []
    C = [[0.0] * n for _ in range(n)]
    for j in range(n):
        p = S[j][j] - sum(C[j][k] * C[j][k] for k in range(j))
        piv.append(p)
        if p <= 1e-9 * S[j][j]: return None, piv
        C[j][j] = sqrt(p)
        for i in range(j + 1, n):
            C[i][j] = (S[i][j] - sum(C[i][k] * C[j][k] for k in range(j))) / C[j][j]
    return C, piv

def solve(S, b):                                 # Gaussian elimination, no inverse formed
    n = len(b)
    A = [S[i][:] + [b[i]] for i in range(n)]
    for j in range(n):
        for i in range(j + 1, n):
            m = A[i][j] / A[j][j]
            A[i] = [a - m * c for a, c in zip(A[i], A[j])]
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (A[i][n] - sum(A[i][k] * x[k] for k in range(i + 1, n))) / A[i][i]
    return x

def det3(S):                                     # cofactor expansion along the top row
    return (S[0][0] * (S[1][1] * S[2][2] - S[1][2] * S[2][1])
            - S[0][1] * (S[1][0] * S[2][2] - S[1][2] * S[2][0])
            + S[0][2] * (S[1][0] * S[2][1] - S[1][1] * S[2][0]))

def Phi(x):                                      # standard normal area left of x, Taylor series
    term, total = x, x
    for n in range(1, 80):
        term *= -x * x / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)

MASK, state = (1 << 64) - 1, 20260928            # SplitMix64, seed 20260928
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

def normal_pair():                               # Marsaglia's polar method
    while True:
        u = 2 * (((splitmix() >> 11) + 0.5) / 2.0 ** 53) - 1
        v = 2 * (((splitmix() >> 11) + 0.5) / 2.0 ** 53) - 1
        s = u * u + v * v
        if 0 < s < 1:
            k = sqrt(-2 * log(s) / s)
            return u * k, v * k

S = mul(L, tr(L))                                # road 1: Sigma = L L^T
sd = [sqrt(S[i][i]) for i in range(3)]
C, piv = cholesky(S)                             # road 2: L back from Sigma alone
cond = [S[0][0]] + [S[j][j] - dot(S[j][:j], solve([r[:j] for r in S[:j]], S[j][:j])) for j in (1, 2)]
x_day = [m + d for m, d in zip(MU, mv(L, Z_DAY))]
q_elim = dot([a - m for a, m in zip(x_day, MU)], solve(S, [a - m for a, m in zip(x_day, MU)]))
d_cof, d_diag = det3(S), (L[0][0] * L[1][1] * L[2][2]) ** 2
norm = (2 * pi) ** 1.5 * sqrt(d_cof)
p_mean, p_var, c = dot(W, MU), dot(W, mv(S, W)), mv(tr(L), W); p_sd = sqrt(p_var)
tail = Phi((LOSS - p_mean) / p_sd)
print("model: daily returns in percent; means " + row(MU))
for nm, r in zip(NAMES, L): print(f"L       {nm:8s}" + row(r))
for nm, r in zip(NAMES, S): print(f"Sigma   {nm:8s}" + row(r))
print("sd " + row(sd) + f"; correlations {S[0][1] / sd[0] / sd[1]:.4f}, {S[0][2] / sd[0] / sd[2]:.4f}, {S[1][2] / sd[1] / sd[2]:.4f}")
for nm, r in zip(NAMES, C): print(f"Cholesky of Sigma {nm:8s}" + row(r))
print("pivots under each root " + row(piv) + "; conditional variances by regression " + row(cond))
print("one day: draws " + row(Z_DAY, "{:.2f}") + " -> returns " + row(x_day) + f"; portfolio ${dot(W, x_day):.2f}")
print(f"det Sigma by cofactors {d_cof:.6f}; (product of L's diagonal)^2 {d_diag:.6f}")
print(f"(x-mu)^T Sigma^-1 (x-mu) by elimination {q_elim:.6f}; |z|^2 {dot(Z_DAY, Z_DAY):.6f}")
print(f"density at the mean {1 / norm:.6f}; on that day {exp(-q_elim / 2) / norm:.6f}")
print(f"portfolio: mean ${p_mean:.2f}; w^T Sigma w {p_var:.2f}; L^T w = " + row(c, "{:.2f}")
      + f", |L^T w|^2 {dot(c, c):.2f}; sd ${p_sd:.2f}")
print(f"P(loss worse than $200) = Phi({(LOSS - p_mean) / p_sd:.4f}) = {tail:.4f}, 1 day in {1 / tail:.0f}")

sp, sp2, hist = [[0.0] * 3 for _ in range(3)], [[0.0] * 3 for _ in range(3)], [0] * 12
hits = pv = pv2 = zeros = cy = y_low = 0.0
for _ in range(N):
    z1, z2 = normal_pair(); z3, z4 = normal_pair()
    d = mv(L, [z1, z2, z3])                       # X - MU
    for i in range(3):
        for j in range(3):
            sp[i][j] += d[i] * d[j]; sp2[i][j] += (d[i] * d[j]) ** 2
    p = dot(W, [m + e for m, e in zip(MU, d)])
    hits += p < LOSS; pv += (p - p_mean) ** 2; pv2 += (p - p_mean) ** 4
    if BINS[0] <= p < BINS[-1]: hist[int((p - BINS[0]) // 50)] += 1
    y = z1 if z4 > 0 else -z1                     # mistake 4: coin-flipped copy of the bank draw
    zeros += z1 + y == 0; cy += z1 * y; y_low += y < -1
cov = [[sp[i][j] / N for j in range(3)] for i in range(3)]
se = [[sqrt((sp2[i][j] / N - cov[i][j] ** 2) / N) for j in range(3)] for i in range(3)]
print(f"simulation, {N} days, SplitMix64 seed 20260928, polar method")
for i in range(3): print(f"sample cov {NAMES[i]:8s}" + row(cov[i]) + "  SE" + row(se[i]))
ph, vh = hits / N, pv / N; vh_se = sqrt((pv2 / N - vh * vh) / N)
print(f"portfolio variance simulated {vh:.2f} (SE {vh_se:.2f}); "
      f"loss worse than $200 on {ph:.4f} of days (SE {sqrt(tail * (1 - tail) / N):.4f})")
print("chart, $50 bins from -300 to 300, percent of days: formula | simulated")
fb = [100 * (Phi((BINS[k + 1] - p_mean) / p_sd) - Phi((BINS[k] - p_mean) / p_sd)) for k in range(12)]
print("formula   " + row(fb, "{:.2f}") + "\nsimulated " + row([100 * h / N for h in hist], "{:.2f}"))
sd_ind = sqrt(sum((w * s) ** 2 for w, s in zip(W, sd)))
print(f"mistake 1, correlations dropped: sd ${sd_ind:.2f}, chance {Phi((LOSS - p_mean) / sd_ind):.4f}, "
      f"1 day in {1 / Phi((LOSS - p_mean) / sd_ind):.0f}")
print(f"mistake 2, L^T L for L L^T: bank variance {mul(tr(L), L)[0][0]:.4f}, not {S[0][0]:.4f}")
BAD = [[1.0, 0.9, 0.9], [0.9, 1.0, 0.0], [0.9, 0.0, 1.0]]; bad_C, bad_piv = cholesky(BAD)
print("mistake 3, correlations 0.9, 0.9, 0: pivots " + row(bad_piv) + f"; mix (1, -1, -1) variance {dot([1, -1, -1], mv(BAD, [1, -1, -1])):.4f}")
print(f"mistake 4, coin-flipped copy: P(copy < -1) {y_low / N:.4f} vs Phi(-1) {Phi(-1):.4f}; "
      f"correlation {cy / N:.4f}; sum exactly 0 on {zeros / N:.4f} of days")
S4 = [S[i] + [mv(S, W)[i]] for i in range(3)] + [mv(S, W) + [p_var]]
print(f"singular: portfolio added as a fourth reading, pivot left {abs(cholesky(S4)[1][3]):.6f}")
assert all(abs(C[i][j] - L[i][j]) < 1e-12 for i in range(3) for j in range(3)) and all(abs(p - v) < 1e-12 for p, v in zip(piv, cond))
assert abs(d_cof - d_diag) < 1e-12 and abs(q_elim - dot(Z_DAY, Z_DAY)) < 1e-12 and abs(dot(c, c) - p_var) < 1e-9
assert all(abs(cov[i][j] - S[i][j]) < 4 * se[i][j] for i in range(3) for j in range(3))
assert abs(ph - tail) < 4 * sqrt(tail * (1 - tail) / N) and abs(vh - p_var) < 4 * vh_se and all(
    abs(f / 100 - h / N) < 4 * sqrt(f / 100 * (1 - f / 100) / N) for f, h in zip(fb, hist))
assert bad_C is None and abs(bad_piv[0] * bad_piv[1] * bad_piv[2] - det3(BAD)) < 1e-12 and abs(cholesky(S4)[1][3]) < 1e-9 * p_var
assert abs(zeros / N - 0.5) < 4 * sqrt(0.25 / N) and abs(y_low / N - Phi(-1)) < 4 * sqrt(0.16 / N)
print("ALL CHECKS PASS")
