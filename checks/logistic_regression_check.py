# Logistic regression -- the check behind the card.  Standard library only.  500 loans drawn with
# SplitMix64 (seed 20260928, same draws as the Rust check), fitted by Newton's method, by a climb that
# nudges instead of using the slope formula, and for two groups by a 2x2 table; SEs two ways.
from math import exp, log, sqrt
M64 = (1 << 64) - 1
state = [20260928]
def unif():                               # SplitMix64: a uniform number in [0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def sig(z):                               # the logistic curve, written to avoid overflow
    return 1.0 / (1.0 + exp(-z)) if z >= 0 else exp(z) / (1.0 + exp(z))
def dot(b, x):
    s = 0.0
    for bj, xj in zip(b, x): s += bj * xj
    return s
def loglik(b, X, y):                      # sum of y*score - ln(1 + e^score)
    s = 0.0
    for x, yi in zip(X, y):
        z = dot(b, x)
        s += yi * z - (max(z, 0.0) + log(1.0 + exp(-abs(z))))
    return s
def solve(A, v):                          # Gaussian elimination with row swaps
    k = len(v); M = [A[i][:] + [v[i]] for i in range(k)]
    for c in range(k):
        r = max(range(c, k), key=lambda i: abs(M[i][c]))
        M[c], M[r] = M[r], M[c]
        for i in range(c + 1, k):
            f = M[i][c] / M[c][c]
            M[i] = [a - f * b for a, b in zip(M[i], M[c])]
    out = [0.0] * k
    for i in reversed(range(k)):
        s = M[i][k]
        for j in range(i + 1, k): s -= M[i][j] * out[j]
        out[i] = s / M[i][i]
    return out
def info(b, X, y):                        # the slopes and the curvature (information)
    k = len(b)
    g, H = [0.0] * k, [[0.0] * k for _ in range(k)]
    for x, yi in zip(X, y):
        p = sig(dot(b, x))
        w = p * (1.0 - p)
        for j in range(k):
            g[j] += x[j] * (yi - p)
            for m in range(k): H[j][m] += w * x[j] * x[m]
    return g, H
def newton(X, y, steps=60):               # step = curvature^-1 times slopes, from zero
    b = [0.0] * len(X[0])
    for it in range(1, steps + 1):
        g, H = info(b, X, y)
        d = solve(H, g)
        b = [bj + dj for bj, dj in zip(b, d)]
        if max(abs(v) for v in d) < 1e-10: break
    return b, it
def ses(b, X, y):                         # square roots of the inverse curvature's diagonal
    H = info(b, X, y)[1]
    return [sqrt(solve(H, [1.0 if i == j else 0.0 for i in range(len(b))])[j]) for j in range(len(b))]
def nudge(c, j, e): return [cj + (e if i == j else 0.0) for i, cj in enumerate(c)]
def show(label, v): print(f"{label:<48}{v:>12.4f}")
def row(label, vs): print(f"{label:<14}" + " ".join(f"{v:5.2f}" for v in vs))
TRUE, n = [-2.55, -0.03, 0.08], 500
X, y = [], []
for _ in range(n):                        # income $25k-$125k, debt ratio 10%-60%
    inc, debt = 25 + int(101 * unif()), 10 + int(51 * unif())
    X.append([1.0, float(inc), float(debt)])
    y.append(1 if unif() < sig(TRUE[0] + TRUE[1] * inc + TRUE[2] * debt) else 0)
print(f"loans {n}; first four (income $k, debt %, default): "
      + ", ".join(f"({x[1]:.0f}, {x[2]:.0f}, {yi})" for x, yi in zip(X[:4], y[:4])))
print(f"defaults among the {n}: {sum(y)}, a share of {sum(y) / n:.4f}")
b, its = newton(X, y)
g = info(b, X, y)[0]
se = ses(b, X, y)
Hinv = [solve(info(b, X, y)[1], [1.0 if i == j else 0.0 for i in range(3)]) for j in range(3)]
print(f"Newton steps to converge: {its}; largest slope below 1e-9: {'yes' if max(map(abs, g)) < 1e-9 else 'no'}")
show("log-likelihood at the peak", loglik(b, X, y))
m1, m2 = sum(x[1] for x in X) / n, sum(x[2] for x in X) / n     # road 2: rescale, nudge, climb
s1, s2 = (sqrt(sum((x[j] - m) ** 2 for x in X) / n) for j, m in ((1, m1), (2, m2)))
Z = [[1.0, (x[1] - m1) / s1, (x[2] - m2) / s2] for x in X]
c, h = [0.0, 0.0, 0.0], 1e-5
for _ in range(300):
    gr = [(loglik(nudge(c, j, h), Z, y) - loglik(nudge(c, j, -h), Z, y)) / (2 * h) / n for j in range(3)]
    c = [cj + 4.0 * gj for cj, gj in zip(c, gr)]
climb = [c[0] - c[1] * m1 / s1 - c[2] * m2 / s2, c[1] / s1, c[2] / s2]
reps, cover = [], 0                       # road 3: 400 fresh loan books from the fitted model
for _ in range(400):
    ys = [1 if unif() < sig(dot(b, x)) else 0 for x in X]
    r = newton(X, ys)[0]
    reps.append(r)
    if abs(r[2] - b[2]) < 1.96 * ses(r, X, ys)[2]: cover += 1
mean = [sum(r[j] for r in reps) / 400 for j in range(3)]
sim = [sqrt(sum((r[j] - mean[j]) ** 2 for r in reps) / 399) for j in range(3)]
print("coefficient     Newton   climb    truth    SE curvature  SE 400 refits")
for j, name in enumerate(("b0 intercept", "b1 income", "b2 debt")):
    print(f"{name:<13}{b[j]:9.4f}{climb[j]:9.4f}{TRUE[j]:9.4f}{se[j]:11.4f}{sim[j]:15.4f}")
show("coverage of b2 +/- 1.96 SE over 400 refits", cover / 400)
for lab, j in (("+10 points of debt ratio", 2), ("+$10k of income", 1)):
    print(f"odds ratio, {lab:<25}{exp(10 * b[j]):.4f}; 95% interval "
          f"{exp(10 * (b[j] - 1.96 * se[j])):.4f} to {exp(10 * (b[j] + 1.96 * se[j])):.4f}")
for lab, inc, debt in (("A", 50, 45), ("A, debt 35", 50, 35), ("A, debt 55", 50, 55),
                       ("B", 100, 20), ("B, debt 30", 100, 30)):
    z = b[0] + b[1] * inc + b[2] * debt
    sz = sqrt(sum(u * v * Hinv[j][k] for j, u in enumerate((1, inc, debt)) for k, v in enumerate((1, inc, debt))))
    print(f"applicant {lab:<10} income part {b[1] * inc:8.4f}  debt part {b[2] * debt:7.4f}"
          f"  score {z:8.4f}  odds {exp(z):7.4f}  chance {sig(z):.4f}, 95% {sig(z - 1.96 * sz):.4f} to {sig(z + 1.96 * sz):.4f}")
show("mistake: odds ratio used on A's chance, debt 55", sig(b[0] + 50 * b[1] + 45 * b[2]) * exp(10 * b[2]))
show("mistake: intercept as a typical chance, Λ(b0)", sig(b[0]))
ls = solve([[sum(r[j] * r[k] for r in X) for k in range(3)] for j in range(3)],
           [sum(r[j] * yi for r, yi in zip(X, y)) for j in range(3)])        # the straight line
show("mistake: straight line, income 125, debt 10", ls[0] + 125 * ls[1] + 10 * ls[2])
show("mistake: straight line, income 25, debt 60", ls[0] + 25 * ls[1] + 60 * ls[2])
show("logistic model, income 125, debt 10", sig(b[0] + 125 * b[1] + 10 * b[2]))
G = [[1.0, 1.0 if x[2] >= 40 else 0.0] for x in X]                        # two groups
nh, dh = sum(1 for r in G if r[1]), sum(yi for r, yi in zip(G, y) if r[1])
nl, dl = n - nh, sum(y) - dh
bg = newton(G, y)[0]
print(f"two groups: debt under 40%: {dl} of {nl} defaulted, odds {dl / (nl - dl):.4f}; "
      f"40% or more: {dh} of {nh}, odds {dh / (nh - dh):.4f}; ratio {dh / (nh - dh) / (dl / (nl - dl)):.4f}")
show("two groups: slope, log of the odds ratio by hand", log(dh / (nh - dh)) - log(dl / (nl - dl)))
show("two groups: slope, Newton", bg[1])
row("chart, debt", [10 + 5 * i for i in range(11)])
row("chart, $40k", [sig(b[0] + 40 * b[1] + b[2] * (10 + 5 * i)) for i in range(11)])
row("chart, $100k", [sig(b[0] + 100 * b[1] + b[2] * (10 + 5 * i)) for i in range(11)])
S = [[1.0, d] for d in (20.0, 25.0, 30.0, 35.0, 45.0, 50.0, 55.0, 60.0)]      # separated book
sy = [0, 0, 0, 0, 1, 1, 1, 1]
for k in (5, 10, 15, 20, 25):
    bs = newton(S, sy, k)[0]
    print(f"separated, {k:2d} Newton steps: slope {bs[1]:.4f}  log-lik {loglik(bs, S, sy):.10f}"
          f"  SE of slope {ses(bs, S, sy)[1]:.1f}")
ts = [0.1 * i for i in range(9)]
row("chart, t", ts)
row("chart, loglik", [loglik([-40 * t, t], S, sy) for t in ts])
assert max(abs(p - q) for p, q in zip(b, climb)) < 1e-6, "Newton and the slope-free climb must agree"
assert all(abs(b[j] - TRUE[j]) < 3 * se[j] for j in range(3)), "fit within 3 SE of the truth"
assert all(abs(sim[j] / se[j] - 1) < 0.15 for j in range(3)), "curvature SE must match the refits"
assert abs(bg[1] - (log(dh / (nh - dh)) - log(dl / (nl - dl)))) < 1e-9, "two-group closed form"
assert loglik(newton(S, sy, 25)[0], S, sy) > loglik(newton(S, sy, 20)[0], S, sy), "separation climbs"
print("ALL CHECKS PASS")
