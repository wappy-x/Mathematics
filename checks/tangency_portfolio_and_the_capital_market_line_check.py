# Tangency portfolio and capital market line: house market (shares, bonds, gold), riskless rate 2%.
# Roads: (1) solve Sigma z = d; (2) sqrt(d.z); (3) grid search on the Sharpe ratio;
# (4) frontier geometry from a, b, c; (5) least variance for a target return, bank allowed.
from math import sqrt

mu = [0.08, 0.04, 0.05]                      # expected one-year returns
sd = [0.20, 0.06, 0.15]                      # standard deviations
rho = [[1.0, 0.2, 0.1], [0.2, 1.0, 0.0], [0.1, 0.0, 1.0]]
rf = 0.02                                    # riskless one-year return
n = 3
S = [[rho[i][j] * sd[i] * sd[j] for j in range(n)] for i in range(n)]

def solve(A, b):                             # Gaussian elimination, partial pivoting
    m = len(b)
    M = [list(A[i]) + [b[i]] for i in range(m)]
    for c in range(m):
        p = max(range(c, m), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        for r in range(m):
            if r != c:
                f = M[r][c] / M[c][c]
                M[r] = [x - f * y for x, y in zip(M[r], M[c])]
    return [M[i][m] / M[i][i] for i in range(m)]

def dot(x, y):
    return sum(a * b for a, b in zip(x, y))

def stats(w, cov=S):                         # mean and standard deviation of a mix
    v = sum(w[i] * cov[i][j] * w[j] for i in range(n) for j in range(n))
    return dot(w, mu), sqrt(v)

def sharpe(w, r=rf):
    m, s = stats(w)
    return (m - r) / s

def tangency(r, cov=S, means=mu):            # w_T = Sigma^-1 d / (1' Sigma^-1 d)
    z = solve(cov, [x - r for x in means])
    t = sum(z)
    return [x / t for x in z], t, z

def row(label, vals, p=6):
    print(f"{label:<38}" + "".join(f"{v:>11.{p}f}" for v in vals))

# road 1: the formula
d = [x - rf for x in mu]
wT, D, z = tangency(rf)
mT, sT = stats(wT)
shT = (mT - rf) / sT
for i in range(n):
    row(f"covariance Sigma, row {i + 1}", S[i])
row("excess returns d = mu - rf", d)
row("road 1  z solving Sigma z = d", z)
row("        D = sum of z", [D])
row("        tangency weights w_T", wT)
row("        terms w_i mu_i", [w * m for w, m in zip(wT, mu)])
row("        mean, sd of w_T", [mT, sT])
row("        Sharpe (mu_T - rf)/sigma_T", [shT])
# road 2: Sharpe as a quadratic form, no weights
H = dot(d, z)
row("road 2  terms d_i z_i", [p * q for p, q in zip(d, z)])
row("        H = d . z, sqrt(H)", [H, sqrt(H)])
# road 3: zooming grid search over w1, w2 (w3 = 1 - w1 - w2)
c1, c2, half = 1.0 / 3.0, 1.0 / 3.0, 1.0
for _ in range(60):
    best = (-1e9, c1, c2)
    for i in range(-10, 11):
        for j in range(-10, 11):
            w1, w2 = c1 + half * i / 10.0, c2 + half * j / 10.0
            s = sharpe([w1, w2, 1.0 - w1 - w2])
            if s > best[0]:
                best = (s, w1, w2)
    _, c1, c2 = best
    half *= 0.5
wG = [c1, c2, 1.0 - c1 - c2]
row("road 3  grid-search weights", wG)
row("        grid-search Sharpe", [sharpe(wG)])
# road 4: the risky-only frontier, sigma^2 = (a m^2 - 2 b m + c) / (a c - b^2)
za, zb = solve(S, [1.0] * n), solve(S, mu)
a, b, c = sum(za), sum(zb), dot(mu, zb)
Dl = a * c - b * b
mF = (c - b * rf) / (b - a * rf)
sF = sqrt((a * mF * mF - 2 * b * mF + c) / Dl)
slope = Dl * sF / (a * mF - b)
row("road 4  a, b, c", [a, b, c])
row("        min-variance mean, sd", [b / a, 1.0 / sqrt(a)])
row("        mean where CML meets frontier", [mF])
row("        frontier slope at that point", [slope])
# road 5: least variance for a target return with the bank; two-fund separation
def kkt(target):                             # Sigma x = lam d, d.x = target - rf
    A = [S[i] + [-d[i]] for i in range(n)] + [d + [0.0]]
    x = solve(A, [0.0] * n + [target - rf])[:n]
    y = sum(x)
    return x, y, sqrt(sum(x[i] * S[i][j] * x[j] for i in range(n) for j in range(n)))
out = {}
for label, target in (("cautious 3%", 0.03), ("bold 8%", 0.08)):
    x, y, s = kkt(target)
    out[label] = (x, y, s, target)
    row(f"road 5  {label}: risky y, bank", [y, 1.0 - y])
    row(f"        {label}: mix x / y", [v / y for v in x])
    row(f"        {label}: sd, CML sd", [s, (target - rf) / sqrt(H)])
    row(f"        {label}: dollars of 10,000", [10000 * v for v in x] + [10000 * (1 - y)], 2)
# single assets and other mixes, by Sharpe
gmv = [v / a for v in za]
for name, w in (("shares", [1, 0, 0]), ("bonds", [0, 1, 0]), ("gold", [0, 0, 1]),
                ("equal thirds", [1 / 3] * 3), ("min-variance", gmv), ("tangency", wT)):
    row(f"Sharpe: {name}", [sharpe(w)], 4)
# what breaks: each wrong fund, levered to the bold investor's sd
w0 = tangency(0.0)[0]
wd = tangency(rf, [[S[i][j] if i == j else 0.0 for j in range(n)] for i in range(n)])[0]
yb, sb = out["bold 8%"][1], out["bold 8%"][2]
row("wrong: forgot rf, weights", w0)
row("wrong: no correlations, weights", wd)
for name, w in (("forgot rf", w0), ("no correlations", wd), ("min-variance fund", gmv)):
    row(f"wrong: {name}, Sharpe, mean", [sharpe(w), rf + sharpe(w) * sb])
row("wrong: borrow at 4%, bold mean", [yb * mT - (yb - 1) * 0.04])
fr4 = (b + sqrt(Dl * (a * sb * sb - 1))) / a    # borrowing dear: the curve itself is best at sd sb
row("borrow at 4%: frontier mean at bold sd", [fr4])
# try changing the riskless rate
for r in (0.01, 0.03):
    w, t, _ = tangency(r)
    row(f"try: rf = {r:.2f}, weights, Sharpe", w + [sharpe(w, r)], 4)
row("try: rf = 0.05, D, excess mean", [tangency(0.05)[1], dot(tangency(0.05)[0], mu) - 0.05])
# chart: upper frontier and CML, sd 6..20 percent
xs = [0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20]
row("chart, sd %", [100 * s for s in xs], 2)
row("chart, frontier mean %", [100 * (b + sqrt(Dl * (a * s * s - 1))) / a for s in xs], 2)
row("chart, CML mean %", [100 * (rf + sqrt(H) * s) for s in xs], 2)

assert max(abs(p - q) for p, q in zip(wG, wT)) < 1e-6, "grid search must find the formula's weights"
assert abs(shT - sqrt(H)) < 1e-12, "Sharpe from weights vs quadratic form"
assert abs(mF - mT) < 1e-12 and abs(slope - shT) < 1e-9, "frontier touches the CML at w_T"
for x, y, s, tg in out.values():
    assert max(abs(v / y - t) for v, t in zip(x, wT)) < 1e-10, "every efficient mix holds w_T"
    assert abs(s - y * sT) < 1e-12 and abs(s - (tg - rf) / sqrt(H)) < 1e-12, "on the CML"
assert abs(D - (b - rf * a)) < 1e-12, "D from Sigma^-1 d vs b - rf a"
assert rf + sqrt(H) * sb > fr4 > yb * mT - (yb - 1) * 0.04, "CML above curve above levering at 4%"
assert tangency(0.05)[1] < 0 and dot(tangency(0.05)[0], mu) < 0.05, "rf above b/a: D < 0, lower branch"
assert [round(100 * v, 1) for v in wT] == [15.8, 67.6, 16.6] and round(sqrt(H), 3) == 0.446, "prose figures"
print("ALL CHECKS PASS")
