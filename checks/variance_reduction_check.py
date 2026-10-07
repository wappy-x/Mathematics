# Variance reduction on the pi-dart estimate -- the check behind the card.
# Standard library only. Three roads: closed forms that use pi, midpoint sums
# over the square that never use pi, and a seeded simulation (SplitMix64).
from math import sqrt, asin, pi

MASK, state = (1 << 64) - 1, 20260929
def uniform():                                    # SplitMix64 -> a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def hit(u, v): return 4.0 if u * u + v * v <= 1.0 else 0.0   # one dart's score
def s(x): return sqrt(max(0.0, 1.0 - x * x))                # height of the arc at x
def G(x): return 0.5 * (x * s(x) + asin(x))                 # area under the arc from 0 to x

N, C, NU, K = 100, -3.0, 2.0 / 3.0, 10

# ---- road 1: closed forms (these use pi) ----
p = pi / 4
var_plain = 16 * p * (1 - p)
cov_anti = 16 * ((pi / 2 - 1) - p * p)            # both darts hit inside the lens
cov_hy = 4 * (pi / 8 - p * NU)                    # Cov(H, Y), Y = U^2 + V^2
var_y = 8.0 / 45.0; c_star = cov_hy / var_y       # Var(Y) = 2 Var(U^2) = 8/45
var_pair = (var_plain + cov_anti) / 2
var_ctrl_best = var_plain - cov_hy ** 2 / var_y
var_ctrl = var_ctrl_best + var_y * (C - c_star) ** 2

def cell_exact(x0, x1, y0, y1):                   # area of the quarter disc inside one cell
    a, b = s(y1), s(y0)                           # arc is above y1 left of a, above y0 left of b
    full = max(0.0, min(x1, a) - x0)
    lo, hi = max(x0, a), min(x1, b)
    part = G(hi) - G(lo) - y0 * (hi - lo) if hi > lo else 0.0
    return full * (y1 - y0) + part

def cell_mid(x0, x1, y0, y1, m=400):              # the same area by midpoint slices
    h, w = y1 - y0, (x1 - x0) / m
    return sum(min(h, max(0.0, s(x0 + (i + 0.5) * w) - y0)) for i in range(m)) * w

def strat_var(k, area):                           # Var of the stratified estimate, one dart per cell
    qs = [area(i / k, (i + 1) / k, j / k, (j + 1) / k) * k * k for i in range(k) for j in range(k)]
    return sum(16 * q * (1 - q) for q in qs) / k ** 4

var_strat = strat_var(K, cell_exact)
crossed = [(i, j) for i in range(K) for j in range(K) if i*i + j*j < K*K < (i+1)**2 + (j+1)**2]

# ---- road 2: midpoint sums over the square, no pi anywhere ----
M, A, lens, eyh, eu2, eu4 = 200000, 0.0, 0.0, 0.0, 0.0, 0.0
for i in range(M):
    x = (i + 0.5) / M
    A += s(x); eyh += x * x * s(x) + s(x) ** 3 / 3; lens += max(0.0, s(x) + s(1 - x) - 1)
    eu2 += x * x; eu4 += x ** 4                   # moments of U^2, for Var(Y)
A, lens, eyh, var_y_m = A / M, lens / M, eyh / M, 2 * (eu4 / M - (eu2 / M) ** 2)   # Var(Y) = 2 Var(U^2)
var_plain_m = 16 * A * (1 - A)
cov_anti_m = 16 * (lens - A * A)
cov_hy_m = 4 * (eyh - A * NU)
var_pair_m = (var_plain_m + cov_anti_m) / 2
var_ctrl_m = var_plain_m - 2 * C * cov_hy_m + C * C * var_y_m
var_strat_m = strat_var(K, cell_mid)

# ---- road 3: seeded simulation, R batches of N darts per method ----
R = 1000
MIRROR = {"antithetic": lambda u, v: (1 - u, 1 - v), "swap mirror": lambda u, v: (v, u)}
def batch(method):
    if method == "plain":
        return sum(hit(uniform(), uniform()) for _ in range(N)) / N
    if method in MIRROR:                          # N/2 darts, each scored with its mirror
        t = 0.0
        for _ in range(N // 2):
            u, v = uniform(), uniform(); t += hit(u, v) + hit(*MIRROR[method](u, v))
        return t / N
    if method in ("control", "wrong nu"):
        nu = NU if method == "control" else 0.5
        t = 0.0
        for _ in range(N):
            u, v = uniform(), uniform(); t += hit(u, v) - C * (u * u + v * v - nu)
        return t / N
    if method == "stratified":
        return sum(hit((i + uniform()) / K, (j + uniform()) / K) for i in range(K) for j in range(K)) / N
    if method == "unweighted":                    # 75 darts left of x = 0.5, 25 right, plain average
        return (sum(hit(0.5 * uniform(), uniform()) for _ in range(75))
                + sum(hit(0.5 + 0.5 * uniform(), uniform()) for _ in range(25))) / N

exact = {"plain": var_plain / N, "antithetic": var_pair / (N // 2),
         "control": var_ctrl / N, "stratified": var_strat, "swap mirror": var_plain / (N // 2)}
print(f"{'method':<12}{'run 1':>8}{'mean of runs':>14}{'+/-':>8}{'exact SE':>10}{'SD of runs':>12}{'gain':>7}")
sim = {}
for meth in ("plain", "antithetic", "control", "stratified", "swap mirror", "wrong nu", "unweighted"):
    ests = [batch(meth) for _ in range(R)]
    mean = sum(ests) / R
    sd = sqrt(sum((e - mean) ** 2 for e in ests) / (R - 1))
    sim[meth] = (mean, sd)
    ex = exact.get(meth)
    tail = f"{sqrt(ex):>10.4f}{sd:>12.4f}{var_plain / N / ex:>7.2f}" if ex else f"{'':>10}{sd:>12.4f}"
    print(f"{meth:<12}{ests[0]:>8.4f}{mean:>14.4f}{sd / sqrt(R):>8.4f}" + tail)

left = (G(0.5) - G(0.0)) / 0.5                    # chance a dart in the left strip hits
wrong_nu, unweighted = pi - C * (NU - 0.5), 4 * (0.75 * left + 0.25 * (2 * p - left))
rows = [("pi/4, share of darts that hit", p), ("  by midpoint sums", A),
        ("sigma^2, plain variance per dart", var_plain), ("  by midpoint sums", var_plain_m),
        ("plain Var, 100 darts", var_plain / N), ("two independent darts, Var of average", var_plain / 2),
        ("lens area, both mirror darts hit", pi / 2 - 1), ("  by midpoint sums", lens),
        ("Cov(H, H') mirror pair", cov_anti), ("  by midpoint sums", cov_anti_m),
        ("variance of a mirror pair average", var_pair), ("  by midpoint sums", var_pair_m),
        ("Cov(H, Y) dart and distance^2", cov_hy), ("  by midpoint sums", cov_hy_m),
        ("c* best coefficient", c_star), ("correlation of H and Y", cov_hy / sqrt(var_plain * var_y)),
        ("control variance, c = c*", var_ctrl_best), ("control variance, chosen c", var_ctrl),
        ("  by midpoint sums", var_ctrl_m),
        ("stratified Var, 10 x 10 cells", var_strat), ("  by midpoint slices", var_strat_m),
        ("stratified, per-dart N*Var", N * var_strat),
        ("wrong nu = 1/2: expected estimate", wrong_nu),
        ("left strip mean score", 4 * left), ("right strip mean score", 4 * (2 * p - left)),
        ("unweighted 75/25: expected estimate", unweighted)]
for name, v in rows:
    print(f"{name:<40} {v:>12.6f}")
print("crossed cells, 10 x 10:", len(crossed))
ks = (1, 2, 4, 5, 10, 20, 40)
chart = [k * k * strat_var(k, cell_exact) for k in ks]
print("chart, cells per side    " + " ".join(f"{k:>6}" for k in ks))
print("chart, per-dart variance " + " ".join(f"{v:>6.2f}" for v in chart))
print("chart, plain, antithetic, control " + " ".join(f"{v:.2f}" for v in (var_plain, 2 * var_pair, var_ctrl)))
print("chart, times k           " + " ".join(f"{v * k:>6.2f}" for v, k in zip(chart, ks)))
print("figure, square 200 units at (80,20), arc radius 200 about (80,220), cell 20, shaded (i,j):",
      " ".join(f"{i},{j}" for i, j in crossed))

assert abs(var_plain - var_plain_m) < 1e-5, "plain variance: closed form vs midpoint"
assert abs(cov_anti - cov_anti_m) < 1e-5, "mirror covariance: closed form vs midpoint"
assert abs(var_ctrl - var_ctrl_m) < 1e-5, "control variance: closed form vs midpoint"
assert abs(var_strat - var_strat_m) < 1e-6, "stratified variance: antiderivative vs slices"
assert len(crossed) == sum(1 for c in range(K * K) if 1e-9 < cell_exact((c // K) / K, (c // K + 1) / K,
    (c % K) / K, (c % K + 1) / K) * K * K < 1 - 1e-9), "integer corner test vs cell areas"
for meth, ex in exact.items():
    assert abs(sim[meth][1] / sqrt(ex) - 1) < 0.1, f"{meth}: simulated spread vs exact SE"
for meth in ("plain", "antithetic", "control", "stratified"):
    assert abs(sim[meth][0] - pi) < 4 * sqrt(exact[meth] / R), f"{meth}: centred on pi"
for meth, target in (("wrong nu", wrong_nu), ("unweighted", unweighted)):
    assert abs(sim[meth][0] - target) < 4 * sim[meth][1] / sqrt(R), f"{meth}: simulated bias vs exact"
print("ALL CHECKS PASS")
