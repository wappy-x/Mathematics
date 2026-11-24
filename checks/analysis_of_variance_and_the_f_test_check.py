# Analysis of variance and the F-test -- the check behind the card.  Standard library only.
# Three fertilisers, four plots each, yields in kg per plot.  Roads: group sums of squares;
# least squares on the full and reduced models; an exact permutation count; a seeded simulation.
from math import sqrt, log, cos, sin, atan, pi
Y = {"A": [20, 22, 19, 23], "B": [25, 27, 24, 28], "C": [22, 21, 23, 22]}
y = [float(v) for g in "ABC" for v in Y[g]]
n, k, grand = 12, 3, sum(y) / 12
def dot(u, v):
    s = 0.0
    for a, b in zip(u, v):
        s += a * b
    return s
def solve(M, rhs):                           # elimination; X^T X needs no pivoting
    m = len(M)
    A = [row[:] + [r] for row, r in zip(M, rhs)]
    for c in range(m):
        for i in range(c + 1, m):
            f = A[i][c] / A[c][c]
            for j in range(c, m + 1):
                A[i][j] -= f * A[c][j]
    x = [0.0] * m
    for c in range(m - 1, -1, -1):
        x[c] = (A[c][m] - dot(A[c][c + 1:m], x[c + 1:])) / A[c][c]
    return x
def rss(cols, v):                            # least squares: fitted values and squared misses
    b = solve([[dot(a, c) for c in cols] for a in cols], [dot(a, v) for a in cols])
    fit = [dot([c[i] for c in cols], b) for i in range(len(v))]
    return fit, sum((v[i] - fit[i]) ** 2 for i in range(len(v)))
def anova(groups):                           # between SS, within SS, F, group means
    allv = [v for g in groups for v in g]
    gm, ms = sum(allv) / len(allv), [sum(g) / len(g) for g in groups]
    ssb = sum(len(g) * (m - gm) ** 2 for g, m in zip(groups, ms))
    ssw = sum((v - m) ** 2 for g, m in zip(groups, ms) for v in g)
    return ssb, ssw, (ssb / (len(groups) - 1)) / (ssw / (len(allv) - len(groups))), ms
gh = lambda m: sqrt(pi) if m == 1 else 1.0 if m == 2 else (m / 2 - 1) * gh(m - 2)   # Gamma(m/2)
f_dens = lambda x, a, b: (gh(a + b) / (gh(a) * gh(b)) * (a / b) ** (a / 2) * x ** (a / 2 - 1) * (1 + a * x / b) ** (-(a + b) / 2))
def beta_cdf(z, a, b):                       # needs a whole-number b
    if b != int(b):
        return 1 - beta_cdf(1 - z, b, a)
    term = s = 1.0
    for j in range(1, int(b)):
        term *= (a + j - 1) / j * (1 - z)
        s += term
    return z ** a * s
def f_tail(x, a, b):                         # P(F > x) on (a, b), through the beta share
    return 1 - beta_cdf(a * x / (b + a * x), a / 2, b / 2)
def t_tail2(t, v):                           # P(|T| > t), odd v
    th = atan(t / sqrt(v))
    c, w, s = cos(th), 1.0, 0.0
    for j in range((v - 1) // 2):
        s += w * c ** (2 * j + 1)
        w *= (2 * j + 2) / (2 * j + 3)
    return 1 - 2 / pi * (th + sin(th) * s)
# Road 1: group means and the two sums of squares
ssb, ssw, F, ms = anova([Y[g] for g in "ABC"])
mean = dict(zip("ABC", ms))
sst, msb, msw = sum((v - grand) ** 2 for v in y), ssb / (k - 1), ssw / (n - k)
for g in "ABC":
    print(f"group {g}: mean {mean[g]:.2f}, between piece {4 * (mean[g] - grand) ** 2:.2f}, within piece {sum((v - mean[g]) ** 2 for v in Y[g]):.2f}")
print(f"{'source':<10}{'SS':>8}{'df':>5}{'mean square':>13}{'F':>9}")
print(f"{'between':<10}{ssb:>8.2f}{k - 1:>5}{msb:>13.4f}{F:>9.4f}")
print(f"{'within':<10}{ssw:>8.2f}{n - k:>5}{msw:>13.4f}")
print(f"{'total':<10}{sst:>8.2f}{n - 1:>5}   grand mean {grand:.2f}")
# Road 2: the same F as a nested-model test, from two least-squares fits
one, dB, dC = [1.0] * n, [1.0 * (4 <= i < 8) for i in range(n)], [1.0 * (i >= 8) for i in range(n)]
(fit_f, rss_f), (fit_r, rss_r) = rss([one, dB, dC], y), rss([one], y)
F2 = ((rss_r - rss_f) / 2) / (rss_f / (n - k))
cross = dot([a - b for a, b in zip(fit_f, fit_r)], [a - b for a, b in zip(y, fit_f)])
print(f"nested fits: RSS one mean {rss_r:.4f}, three means {rss_f:.4f}; F {F2:.4f}; fit-to-fit . miss below 1e-9: {'yes' if abs(cross) < 1e-9 else 'no'}")
# Tail chances three ways, and the 5 percent cutoff
p_closed, p_beta = (1 + 2 * F / 9) ** -4.5, f_tail(F, 2, 9)   # F(2, 9) has a closed-form tail
h = F / 20000                                # Simpson's rule on the density, 0 to F
p_simp = 1 - h / 3 * sum((1 if i in (0, 20000) else 4 if i % 2 else 2) * f_dens(i * h, 2, 9) for i in range(20001))
cut = 4.5 * (0.05 ** (-1 / 4.5) - 1)
print(f"P(F > {F:.4f}) on (2, 9): closed form {p_closed:.6f}; beta series {p_beta:.6f}; Simpson {p_simp:.6f}")
print(f"5 percent cutoff on (2, 9): {cut:.4f}; tail there {f_tail(cut, 2, 9):.4f}")
print("chart, tail on (2, 9) at x = 0..12: " + " ".join(f"{f_tail(x, 2, 9):.4f}" for x in range(13)))
# Road 3: exact permutation count over every way to deal the 12 yields into three plots of 4
obs, yi = sum(sum(Y[g]) ** 2 for g in "ABC"), [int(v) for v in y]
full, hits, total = (1 << n) - 1, 0, 0
for a in range(1 << n):
    rest = full & ~a
    s = rest if bin(a).count("1") == 4 else 0
    while s:
        if bin(s).count("1") == 4:
            sa, sb = (sum(yi[i] for i in range(n) if m >> i & 1) for m in (a, s))
            sc = sum(yi) - sa - sb
            total += 1
            hits += sa * sa + sb * sb + sc * sc >= obs
        s = (s - 1) & rest
print(f"permutation: {total} deals, {hits} with between SS at least 56; p {hits / total:.6f}")
# F = t^2 for two groups, then pairwise follow-up tests on the pooled spread
_, w_ab, F_ab, _ = anova([Y["A"], Y["B"]])
t_ab = (mean["B"] - mean["A"]) / sqrt(w_ab / 6 * 0.5)
print(f"A against B alone: pooled t {t_ab:.4f}, t squared {t_ab * t_ab:.4f}, F {F_ab:.4f}")
lo, hi = 1.0, 4.0
for _ in range(100):                         # t cutoff on 9 df, by bisection
    lo, hi = ((lo + hi) / 2, hi) if t_tail2((lo + hi) / 2, 9) > 0.05 else (lo, (lo + hi) / 2)
tcut = (lo + hi) / 2
for g, q, merged in [("B", "A", dC), ("C", "A", dB), ("B", "C", [b + c for b, c in zip(dB, dC)])]:
    t = (mean[g] - mean[q]) / sqrt(msw * 0.5)
    print(f"pair {g}-{q}: gap {mean[g] - mean[q]:.2f}, t {t:.4f} on 9, p {t_tail2(t, 9):.6f}, times 3 {min(1, 3 * t_tail2(t, 9)):.6f}")
    assert abs(t * t - (rss([one, merged], y)[1] - rss_f) / (rss_f / 9)) < 1e-9   # t squared = F for merging the pair
# Road 4: simulation under "no fertiliser effect", normal plots, SplitMix64 seed 20261123
MASK, state = (1 << 64) - 1, 20261123
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
R, big, over, fam = 100000, 0, 0, 0
for _ in range(R):
    v = []
    for _ in range(6):                       # Box-Muller: two uniforms, two normals
        u1, u2 = 1.0 - uniform(), uniform()
        r = sqrt(-2 * log(u1))
        v += [r * cos(2 * pi * u2), r * sin(2 * pi * u2)]
    _, w, f, m = anova([v[0:4], v[4:8], v[8:12]])
    big, over = big + (f > F), over + (f > cut)
    fam += max(abs(m[0] - m[1]), abs(m[0] - m[2]), abs(m[1] - m[2])) / sqrt(w / 9 * 0.5) > tcut
se = lambda q: sqrt(q * (1 - q) / R)
print(f"simulated {R} null fields: F > {F:.4f} {big / R:.5f} ({se(big / R):.5f}); F > cutoff {over / R:.5f} ({se(over / R):.5f})")
print(f"t cutoff on 9 df {tcut:.4f}; three unadjusted pairwise tests, any false alarm {fam / R:.5f} ({se(fam / R):.5f})")
# The general test on the shelf's twelve house sales: drop age and distance, keep area
AREA = [62.0, 75, 80, 88, 95, 104, 110, 118, 125, 136, 148, 160]
AGE = [35.0, 12, 28, 5, 40, 18, 8, 30, 15, 22, 10, 3]
DIST = [0.5, 1.8, 0.6, 1.4, 0.9, 2.6, 1.0, 1.5, 3.0, 2.2, 2.4, 3.6]
PRICE = [124.0, 140, 172, 200, 180, 171, 260, 210, 226, 250, 301, 298]
r4, r2 = rss([one, AREA, AGE, DIST], PRICE)[1], rss([one, AREA], PRICE)[1]
Fh = ((r2 - r4) / 2) / (r4 / 8)
print(f"houses: RSS area only {r2:.4f}, area, age and distance {r4:.4f}; F {Fh:.4f} on (2, 8), p {f_tail(Fh, 2, 8):.6f}")
print(f"mistake, sums not mean squares: ratio {ssb / ssw:.4f}, p {f_tail(ssb / ssw, 2, 9):.4f}; F read on (9, 2): p {f_tail(F, 9, 2):.4f}")
print(f"mistake, spread measured round the grand mean: F {msb / (sst / 9):.4f}, p {f_tail(msb / (sst / 9), 2, 9):.4f}")
assert ssb == 56 and ssw == 22 and abs(sst - ssb - ssw) < 1e-9 and abs(cross) < 1e-9   # Pythagoras
assert abs(F2 - F) < 1e-9 and abs(rss_r - sst) < 1e-9 and abs(rss_f - ssw) < 1e-9 and abs(r4 - 460.8341) < 1e-4
assert abs(p_closed - p_beta) < 1e-12 and abs(p_simp - p_closed) < 1e-7 and abs(f_tail(Fh, 2, 8) - (1 + Fh / 4) ** -4) < 1e-12
assert abs(big / R - p_closed) < 4 * se(p_closed) and abs(over / R - 0.05) < 4 * se(0.05)
assert abs(t_ab * t_ab - F_ab) < 1e-9 and total == 34650 and abs(hits / total - p_closed) < 0.001 and fam / R > 0.07 and abs(tcut - 2.262157) < 1e-6
print("ALL CHECKS PASS")
