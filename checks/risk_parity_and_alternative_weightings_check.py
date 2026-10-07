# Risk parity -- the check behind the card.  Standard library only.
# Three assets: shares (8%, 20%), bonds (4%, 6%), gold (5%, 15%), correlations
# shares-bonds 0.2, shares-gold 0.1, bonds-gold 0.  Equal-risk weights by three
# roads (coordinate steps, Newton's method, a brute-force grid), Euler's sum by
# bumping weights, and risk shares a fourth way, by simulating returns.
from math import sqrt, log, cos, pi

VOL, MU = (0.20, 0.06, 0.15), (0.08, 0.04, 0.05)
RHO = ((1.0, 0.2, 0.1), (0.2, 1.0, 0.0), (0.1, 0.0, 1.0))
S = [[RHO[i][j] * VOL[i] * VOL[j] for j in range(3)] for i in range(3)]

def Sw(S, w): return [sum(S[i][j] * w[j] for j in range(len(w))) for i in range(len(w))]
def vol(S, w): return sqrt(sum(a * b for a, b in zip(w, Sw(S, w))))
def euler(S, w):                         # marginal risk (S w)_i / vol, contribution w_i times it
    s = vol(S, w)
    mrc = [x / s for x in Sw(S, w)]
    return mrc, [a * b for a, b in zip(w, mrc)]
def share(S, w): return [x / vol(S, w) for x in euler(S, w)[1]]
def norm(y): return [x / sum(y) for x in y]

def erc_steps(S, sweeps=300):            # road 1: each y_i solves S_ii y^2 + b y - 1 = 0 in turn
    y = [1.0] * len(S)
    for _ in range(sweeps):
        for i in range(len(S)):
            b = sum(S[i][j] * y[j] for j in range(len(S)) if j != i)
            y[i] = (-b + sqrt(b * b + 4.0 * S[i][i])) / (2.0 * S[i][i])
    return norm(y)

def solve(A, b):                         # Gaussian elimination with row swaps
    n = len(b)
    M = [A[i][:] + [b[i]] for i in range(n)]
    for k in range(n):
        p = max(range(k, n), key=lambda r: abs(M[r][k]))
        M[k], M[p] = M[p], M[k]
        for r in range(k + 1, n):
            f = M[r][k] / M[k][k]
            M[r] = [M[r][c] - f * M[k][c] for c in range(n + 1)]
    x = [0.0] * n
    for k in reversed(range(n)):
        x[k] = (M[k][n] - sum(M[k][c] * x[c] for c in range(k + 1, n))) / M[k][k]
    return x

def erc_newton(S):                       # road 2: Newton on S y - 1/y = 0, kept positive
    n = len(S)
    y = [1.0] * n
    for _ in range(60):
        g = [a - 1.0 / y[i] for i, a in enumerate(Sw(S, y))]
        H = [[S[i][j] + (1.0 / y[i] ** 2 if i == j else 0.0) for j in range(n)] for i in range(n)]
        d, t = solve(H, g), 1.0
        while any(y[i] - t * d[i] <= 0.0 for i in range(n)):
            t /= 2.0
        y = [y[i] - t * d[i] for i in range(n)]
    return norm(y)

def erc_grid(S, steps=1000):             # road 3: every weight in 0.1% steps, smallest spread
    grid = ((a / steps, b / steps, (steps - a - b) / steps)
            for a in range(1, steps) for b in range(1, steps - a))
    return list(min(grid, key=lambda w: max(euler(S, w)[1]) - min(euler(S, w)[1])))

w1, w2, w3 = erc_steps(S), erc_newton(S), erc_grid(S)
ew, sixty, iv = [1 / 3] * 3, [0.6, 0.4, 0.0], norm([1 / v for v in VOL])
mv = norm(solve(S, [1.0, 1.0, 1.0]))
def ret(w): return sum(a * b for a, b in zip(w, MU))

print("equal-risk weights      shares     bonds      gold")
for lab, w in (("road 1, coordinate steps", w1), ("road 2, Newton", w2), ("road 3, grid of 0.1%", w3)):
    print(f"{lab:<24}" + "".join(f"{x:10.6f}" for x in w))
mrc, rc = euler(S, w1)
h, s1 = 1e-6, vol(S, w1)
fd = [(vol(S, [w1[j] + (h if j == i else 0) for j in range(3)])
       - vol(S, [w1[j] - (h if j == i else 0) for j in range(3)])) / (2 * h) for i in range(3)]
print("covariance S, row by row: " + " | ".join(" ".join(f"{a:.4f}" for a in r) for r in S))
print(f"{'covariance times w, S w':<24}" + "".join(f"{x:10.6f}" for x in Sw(S, w1)))
print(f"{'marginal risk, formula':<24}" + "".join(f"{x:10.6f}" for x in mrc))
print(f"{'marginal risk, bumped':<24}" + "".join(f"{x:10.6f}" for x in fd))
print(f"{'risk contribution':<24}" + "".join(f"{x:10.6f}" for x in rc))
print(f"{'w times S w':<24}" + "".join(f"{a * b:10.6f}" for a, b in zip(w1, Sw(S, w1))) + f", total {s1 * s1:.6f}")
print(f"{'portfolio volatility':<24}{s1:10.6f}")
print(f"{'sum of contributions':<24}{sum(a * b for a, b in zip(w1, fd)):10.6f}")

x = [0x2545F4914F6CDD1D]                 # road 4: simulate returns, split the variance
def unif():
    x[0] = (x[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = x[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 1e-18
L = [[0.0] * 3 for _ in range(3)]        # Cholesky: S = L L^T
for i in range(3):
    for j in range(i + 1):
        t = S[i][j] - sum(L[i][k] * L[j][k] for k in range(j))
        L[i][j] = sqrt(t) if i == j else t / L[j][j]
N, acc, accp = 200000, [0.0] * 3, 0.0
for _ in range(N):
    e = [sqrt(-2 * log(unif())) * cos(2 * pi * unif()) for _ in range(3)]
    r = [sum(L[i][k] * e[k] for k in range(3)) for i in range(3)]
    parts = [w1[i] * r[i] for i in range(3)]
    p = sum(parts)
    acc = [acc[i] + parts[i] * p for i in range(3)]
    accp += p * p
sim = [a / accp for a in acc]
print(f"{'risk share, formula':<24}" + "".join(f"{x:10.6f}" for x in share(S, w1)))
print(f"{'risk share, simulated':<24}" + "".join(f"{x:10.6f}" for x in sim))

print()
print("portfolio              shares   bonds    gold    vol  return  | risk share: shares bonds gold")
for lab, w in (("equal money", ew), ("60/40 shares/bonds", sixty), ("inverse volatility", iv),
               ("minimum variance", mv), ("equal risk", w1)):
    print(f"{lab:<20}" + "".join(f"{100 * a:8.2f}" for a in w) + f"{100 * vol(S, w):7.2f}{100 * ret(w):7.2f}"
          + "  |" + "".join(f"{100 * a:7.2f}" for a in share(S, w)))
rs = [sum(row) for row in RHO]
print("inverse volatility, correlation row sums " + " ".join(f"{a:.2f}" for a in rs) + f" of {sum(rs):.2f}: "
      + " ".join(f"{100 * a / sum(rs):.2f}" for a in rs))
print(f"minimum variance, marginal risk each: " + " ".join(f"{a:.6f}" for a in euler(S, mv)[0]))
lev = vol(S, sixty) / s1
print(f"return per unit of risk: 60/40 {ret(sixty) / vol(S, sixty):.4f}, equal risk {ret(w1) / s1:.4f}; levered "
      f"{lev:.4f}x to 60/40's vol: {100 * lev * ret(w1):.2f}% before, {100 * (lev * ret(w1) - (lev - 1) * 0.05):.2f}% after borrowing at 5%")
print(f"wrong: own-variance shares at equal risk: "
      + " ".join(f"{100 * w1[i] ** 2 * S[i][i] / s1 ** 2:.2f}" for i in range(3))
      + f", summing to {sum(100 * w1[i] ** 2 * S[i][i] / s1 ** 2 for i in range(3)):.2f}")
S2 = [[0.04, 0.2 * 0.2 * 0.06], [0.2 * 0.2 * 0.06, 0.0036]]
S2n = [[0.04, -0.5 * 0.2 * 0.06], [-0.5 * 0.2 * 0.06, 0.0036]]
print(f"two assets, correlation 0.2: bonds {erc_steps(S2)[1]:.6f}; correlation -0.5: bonds "
      f"{erc_steps(S2n)[1]:.6f}; 0.20/(0.20+0.06) = {0.20 / 0.26:.6f}")
print()
g = w1[0] / (w1[0] + w1[2])
print(f"chart: shares and gold kept {100 * g:.0f}:{100 - 100 * g:.0f} as in the equal-risk mix; bonds' weight across")
print("bonds' weight, %     " + "".join(f"{100 * b:7.0f}" for b in (0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)))
for lab, k in (("bonds' risk share, %", 1), ("shares' risk share, %", 0)):
    vals = [100 * share(S, [(1 - b) * g, b, (1 - b) * (1 - g)])[k] for b in (0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)]
    print(f"{lab:<21}" + "".join(f"{v:7.2f}" for v in vals))
assert max(abs(a - b) for a, b in zip(w1, w2)) < 1e-10, "coordinate steps and Newton disagree"
assert max(abs(a - b) for a, b in zip(w1, w3)) < 2e-3, "grid lands away from the equal-risk mix"
assert max(abs(a - b) for a, b in zip(mrc, fd)) < 1e-8, "marginal risk formula disagrees with the bump"
assert abs(sum(a * b for a, b in zip(w1, fd)) - s1) < 1e-9, "Euler: bumped contributions must sum to vol"
assert max(abs(a - 1 / 3) for a in sim) < 0.01, "simulated risk shares are not a third each"
assert abs(erc_steps(S2n)[1] - 0.20 / 0.26) < 1e-10, "two assets: equal risk is inverse volatility"
assert vol(S, mv) < vol(S, w1) < vol(S, ew), "volatility order min-variance < equal-risk < equal-money"
print("ALL CHECKS PASS")
