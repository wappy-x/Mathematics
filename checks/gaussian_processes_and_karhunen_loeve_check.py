# Gaussian processes and the Karhunen-Loeve series -- the check behind the card.
# Standard library only.  The random numbers come from a generator written here.
from math import pi, sqrt, sin, cos, log, exp

def row(name, v): print(f"{name:<46} {v:>10.6f}")

# ---- 1. kernels: a Gaussian process with mean 0 is fixed by its covariance k(s, t) ----
kernels = [("Brownian motion  min(s,t)", lambda s, t: min(s, t)),
           ("bridge pinned at 5  min(s,t) - st/5", lambda s, t: min(s, t) - s * t / 5),
           ("Ornstein-Uhlenbeck  exp(-|t-s|)/2", lambda s, t: 0.5 * exp(-abs(t - s))),
           ("fractional BM, H = 0.7", lambda s, t: 0.5 * (s ** 1.4 + t ** 1.4 - abs(t - s) ** 1.4)),
           ("not a kernel  max(s,t)", lambda s, t: max(s, t))]

def cholesky(K):            # K = L L^T; stops at a pivot <= 0: below 0, K is no covariance; exactly 0, a degenerate one
    n = len(K); L = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            s = K[i][j] - sum(L[i][m] * L[j][m] for m in range(j))
            if i == j:
                if s <= 0: return L, i + 1, s      # failed at this pivot
                L[i][i] = sqrt(s)
            else:
                L[i][j] = s / L[j][j]
    return L, 0, min(L[i][i] ** 2 for i in range(n))
def det(A):                 # determinant by expansion along the first row: a second road, pivot i = det_i / det_(i-1)
    return A[0][0] if len(A) == 1 else sum((-1) ** j * A[0][j] * det([r[:j] + r[j + 1:] for r in A[1:]]) for j in range(len(A)))

times = [1.0, 2.0, 3.0, 4.0]                       # the grain, sampled every second
print("kernel on times 1, 2, 3, 4 s        Cholesky: smallest pivot, or failure")
for name, k in kernels:
    K = [[k(s, t) for t in times] for s in times]; L, bad, piv = cholesky(K)
    print(f"  {name:<36} " + (f"valid, pivot {piv:.6f}" if bad == 0 else f"FAILS at pivot {bad}: {piv:.6f}"))
    d = [1.0] + [det([r[:i] for r in K[:i]]) for i in range(1, 5)]   # leading minors
    if not name.startswith("not"):
        assert bad == 0, "the four example kernels must pass Cholesky"
        assert abs(piv - min(d[i] / d[i - 1] for i in range(1, 5))) < 1e-9, "smallest pivot = smallest minor ratio"
    if name.startswith("Brownian"): L_bm = L
    if name.startswith("not"): bad_max = (bad, piv)
print("  Brownian Cholesky row 4:", " ".join(f"{x:.1f}" for x in L_bm[3]))
var_diff_max = 1.0 + 2.0 - 2 * 2.0                 # Var(X_2 - X_1) if k were max(s,t)
row("max kernel: Var(X_2 - X_1) = 1 + 2 - 2*2", var_diff_max)

# ---- 2. Karhunen-Loeve for Brownian motion on [0, 1]: lambda_k = 1/((k - 1/2) pi)^2 ----
lam = lambda k: 1.0 / ((k - 0.5) * pi) ** 2
e = lambda k, t: sqrt(2) * sin((k - 0.5) * pi * t)
total = 0.5                                        # integral of Var W_t = t over [0, 1]
cum = 0.0
row("(pi/2)^2, first frequency squared", (pi / 2) ** 2); row("(3pi/2)^2, second frequency squared", (3 * pi / 2) ** 2)
row("pi^2/8 = 1 + 1/9 + 1/25 + ...", pi ** 2 / 8)
for k in range(1, 6):
    cum += lam(k)
    row(f"lambda_{k} closed form   (cumulative share)", lam(k)); row("    share of 1/2 after this term", cum / total)
n99, c = 0, 0.0
while c < 0.99 * total and n99 < 10 ** 6: n99 += 1; c += lam(n99)
print(f"{'terms needed for 99% of the variance':<46} {n99:>10d}")
series = sum(lam(k) for k in range(1, 1_000_001))
row("sum of 10^6 eigenvalues (should be 1/2)", series)
row("Mercer: sum lambda e(0.3) e(0.7), 20000 terms", sum(lam(k) * e(k, 0.3) * e(k, 0.7) for k in range(1, 20001)))
row("Var W_1 from series: sum 2 lambda sin^2", sum(2 * lam(k) * sin((k - 0.5) * pi) ** 2 for k in range(1, 20001)))

# ---- 3. road two: eigenvalues of the kernel on a grid, by power iteration ----
n = 2000; h = 1.0 / n; tg = [(i + 0.5) * h for i in range(n)]
def apply(v):              # (A v)_i = h * sum_j min(t_i, t_j) v_j, done with running sums
    left, out, acc = 0.0, [0.0] * n, sum(v)
    for i in range(n):
        acc -= v[i]; left += tg[i] * v[i]
        out[i] = h * (left + tg[i] * acc)
    return out
found = []
for k in range(1, 4):
    v = [1.0 + 0.001 * i for i in range(n)]
    for _ in range(60):
        for u in found:                            # deflate: remove earlier modes
            d = sum(a * b for a, b in zip(v, u)); v = [a - d * b for a, b in zip(v, u)]
        w = apply(v); nv = sqrt(sum(x * x for x in w)); v = [x / nv for x in w]
    lam_num = sum(a * b for a, b in zip(v, apply(v)))
    found.append(v)
    row(f"lambda_{k} by power iteration on 2000 points", lam_num)
    assert abs(lam_num - lam(k)) < 1e-6, "grid eigenvalue must match 1/((k - 1/2) pi)^2"
best_line = 3 * h * sum(a * b for a, b in zip(tg, apply(tg))) / total   # best multiple of the wave sqrt(3) t
row("best multiple of the line t, on the grid: share", best_line)
assert abs(best_line - 0.8) < 1e-5 and best_line < lam(1) / total, "line shape: 2/5 of 1/2, below 8/pi^2"

# ---- 4. road three: simulate paths, project on e_1 ----
state = 20261123
def u01():                 # splitmix64, then a uniform in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
paths, steps = 10000, 200; dt = 1.0 / steps
e1 = [e(1, (j + 1) * dt) for j in range(steps)]
s_c1, s_c1sq, s_int, s_w1 = 0.0, 0.0, 0.0, 0.0
for p in range(paths):
    w, c1, iw2 = 0.0, 0.0, 0.0
    for j in range(0, steps, 2):                   # Box-Muller: two normals per pair of uniforms
        r, a = sqrt(-2 * log(u01())), 2 * pi * u01()
        for z, jj in ((r * cos(a), j), (r * sin(a), j + 1)):
            w += sqrt(dt) * z; c1 += w * e1[jj] * dt; iw2 += w * w * dt
    s_c1 += c1; s_c1sq += c1 * c1; s_int += iw2; s_w1 += w * w
row("simulated mean of first coefficient", s_c1 / paths)
row("simulated variance of first coefficient", s_c1sq / paths)
row("simulated mean of integral of W^2", s_int / paths)
row("simulated Var W_1", s_w1 / paths)
row("simulated share of first term", s_c1sq / s_int)

# ---- 5. what breaks, and try changing ----
row("wrong: bridge modes sin(k pi t), total variance", sum(1 / (k * pi) ** 2 for k in range(1, 1_000_001)))
row("wrong: share measured against Var W_1 = 1", lam(1) / 1.0)
row("wrong: drop the sqrt 2, total variance", sum(lam(k) for k in range(1, 1_000_001)) / 2)
row("straight line t*W_1 as first term: share", (1 / 3) / total)
row("try: three terms, share", (lam(1) + lam(2) + lam(3)) / total)
row("try: bridge on [0,1], first term share 6/pi^2", (1 / pi ** 2) / (1 / 6))
row("try: 10 seconds, lambda_1 = 100 * 4/pi^2", 100 * lam(1))
print("chart, t          " + " ".join(f"{0.1 * i:6.1f}" for i in range(11)))
for k in range(1, 4):
    print(f"chart, mode {k}     " + " ".join(f"{round(sqrt(lam(k)) * e(k, 0.1 * i), 3) + 0.0:6.3f}" for i in range(11)))

assert bad_max == (2, -2.0), "max(s,t) must fail at the second pivot"
assert all(abs(x - 1.0) < 1e-12 for x in L_bm[3]), "Cholesky of min(i, j) is the all-ones triangle"
assert abs(series - 0.5) < 1e-6, "eigenvalues sum to the integral of t"
assert abs(sum(lam(k) * e(k, 0.3) * e(k, 0.7) for k in range(1, 20001)) - 0.3) < 1e-4, "Mercer gives min(0.3, 0.7)"
assert abs(s_c1sq / paths - lam(1)) < 0.02 and abs(s_c1sq / s_int - 8 / pi ** 2) < 0.03, "simulation vs 4/pi^2"
print("ALL CHECKS PASS")
