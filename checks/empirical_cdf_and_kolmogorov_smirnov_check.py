# Empirical CDF and Kolmogorov-Smirnov -- the check behind the card.
# Standard library only.  Every number on the card is printed here.  The KS
# null laws are built from scratch: all 12,870 splits, a lattice-path count,
# the Marsaglia-Tsang-Wang matrix and a seeded simulation (SplitMix64).
import math
from itertools import combinations

A = [1.2, 1.9, 2.4, 2.8, 3.1, 3.5, 4.2, 5.0]   # shop A waits, minutes
B = [2.6, 3.3, 3.9, 4.4, 4.8, 5.5, 6.1, 7.0]   # shop B waits, minutes
MEAN = 3.0                                      # the model: exponential, mean 3 min

def ecdf(xs, t):              # share of the sample at or below t
    return sum(1 for x in xs if x <= t) / len(xs)

def model(t, mean=MEAN):      # exponential CDF
    return 1.0 - math.exp(-t / mean) if t > 0 else 0.0

def d_one(xs, cdf):           # sup |F_n - F|: check both sides of every step
    xs, n = sorted(xs), len(xs)
    return max(max((i + 1) / n - cdf(x), cdf(x) - i / n) for i, x in enumerate(xs))

def d_two(xs, ys):            # sup |F_A - F_B|, read at every data point
    return max(abs(ecdf(xs, t) - ecdf(ys, t)) for t in xs + ys)

def kolmogorov_q(lam):        # Kolmogorov's limit: P(sup |bridge| > lam)
    return 2 * sum((-1) ** (k - 1) * math.exp(-2 * k * k * lam * lam) for k in range(1, 101))
def kolmogorov_theta(lam):    # the same limit by its second series (Jacobi's theta identity)
    return 1 - math.sqrt(2 * math.pi) / lam * sum(math.exp(-(2 * k - 1) ** 2 * math.pi ** 2 / (8 * lam * lam)) for k in range(1, 101))

def mtw_below(n, d):          # exact P(D_n < d), Marsaglia-Tsang-Wang matrix
    k = int(n * d) + 1; m = 2 * k - 1; h = k - n * d
    H = [[1.0 if i - j + 1 >= 0 else 0.0 for j in range(m)] for i in range(m)]
    for i in range(m):
        H[i][0] -= h ** (i + 1); H[m - 1][i] -= h ** (m - i)
    H[m - 1][0] += (2 * h - 1) ** m if 2 * h - 1 > 0 else 0.0
    for i in range(m):
        for j in range(m):
            if i - j + 1 > 0: H[i][j] /= math.factorial(i - j + 1)
    P = [[float(i == j) for j in range(m)] for i in range(m)]
    for _ in range(n):
        P = [[sum(P[i][t] * H[t][j] for t in range(m)) for j in range(m)] for i in range(m)]
    return P[k - 1][k - 1] * math.factorial(n) / n ** n

def dkw(n, alpha):            # DKW half-width: 2 exp(-2 n eps^2) = alpha
    return math.sqrt(math.log(2 / alpha) / (2 * n))

state = 20261123              # SplitMix64, written out so Rust matches
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

def draw(n):                  # inverse transform: exponential waits, mean 3
    return [-MEAN * math.log(1.0 - unif()) for _ in range(n)]

print("staircases at each pooled wait (counts out of 8):")
for t in sorted(A + B):
    print(f"  {t:.1f} min   A {round(8 * ecdf(A, t))}   B {round(8 * ecdf(B, t))}   gap {abs(ecdf(A, t) - ecdf(B, t)):.3f}")

# ---- two-sample test: shop A against shop B ----
D2 = d_two(A, B)
walk, i, j = 0.0, 0, 0                              # road 2 for D: merge walk
for t in sorted(A + B):
    while i < 8 and A[i] <= t: i += 1
    while j < 8 and B[j] <= t: j += 1
    walk = max(walk, abs(i - j) / 8)
pool = A + B
hits = sum(1 for c in combinations(range(16), 8)    # road 1: all 12,870 splits
           if d_two([pool[k] for k in c], [pool[k] for k in range(16) if k not in c]) >= D2 - 1e-12)
paths = [[0] * 9 for _ in range(9)]                 # road 2: lattice paths with |i-j| < 4
for a in range(9):
    for b in range(9):
        if abs(a - b) * 1.0 / 8 >= D2 - 1e-12: continue
        paths[a][b] = 1 if a == b == 0 else (paths[a - 1][b] if a else 0) + (paths[a][b - 1] if b else 0)
lam2 = math.sqrt(8 * 8 / 16) * D2
print(f"two-sample D = {D2:.3f} ({round(8 * D2)}/8), at 3.1 min: A {ecdf(A, 3.1):.3f}, B {ecdf(B, 3.1):.3f}")
print(f"exact p: {hits} of 12870 splits = {hits / 12870:.4f}; lattice paths inside: {paths[8][8]}")
print(f"Kolmogorov limit: lambda = {lam2:.3f}, p = {kolmogorov_q(lam2):.4f}")

# ---- one-sample test: shop A against an exponential model, mean 3 min ----
D1 = d_one(A, model)
grid = max(abs(ecdf(A, t / 1000) - model(t / 1000)) for t in range(1, 10001))
grid = max(grid, max(abs(ecdf(A, x - 1e-9) - model(x)) for x in A))
print(f"model at 1.9 min: {model(1.9):.4f}; staircase just below 1.9: {ecdf(A, 1.8):.3f}")
print(f"one-sample D = {D1:.4f}; by a 0.001-min grid: {grid:.4f}")
p1 = 1 - mtw_below(8, D1)
R, sim1, simdkw, simest = 100000, 0, 0, 0
Dest = d_one(A, lambda t: model(t, sum(A) / 8))
for _ in range(R):
    xs = draw(8)
    d = d_one(xs, model)
    sim1 += d >= D1; simdkw += d >= dkw(8, 0.05)
    simest += d_one(xs, lambda t: model(t, sum(xs) / 8)) >= Dest
print(f"exact p = {p1:.4f}; simulated ({R} samples of 8) p = {sim1 / R:.4f}")

# ---- the DKW band, and the exact 5% line it stands in for ----
eps, lo, hi = dkw(8, 0.05), 0.2, 0.8
for _ in range(60): mid = (lo + hi) / 2; lo, hi = (mid, hi) if 1 - mtw_below(8, mid) > 0.05 else (lo, mid)
miss = 1 - mtw_below(8, eps)
print(f"DKW half-width, n 8, 95%: sqrt(ln 40/16) = {eps:.4f}; Massart bound 2exp(-2n eps^2) = {2 * math.exp(-16 * eps * eps):.4f}")
print(f"chance D_8 >= {eps:.4f}: exact {miss:.4f}, simulated {simdkw / R:.4f}; exact 5% line {hi:.4f}")
print("band for shop A at each wait (lower, upper):")
print("  " + "  ".join(f"{x}:{max(0, (i + 1) / 8 - eps):.3f}-{min(1, (i + 1) / 8 + eps):.3f}" for i, x in enumerate(A[:4])))
print("  " + "  ".join(f"{x}:{max(0, (i + 5) / 8 - eps):.3f}-{min(1, (i + 5) / 8 + eps):.3f}" for i, x in enumerate(A[4:])))

# ---- Glivenko-Cantelli: one seeded run from the model, n growing ----
for n in (8, 80, 800, 8000):
    print(f"GC n {n:5d}: sup|F_n - F| = {d_one(draw(n), model):.4f}   DKW 95% half-width {dkw(n, 0.05):.4f}")

# ---- what breaks ----
right_only = max((i + 1) / 8 - model(x) for i, x in enumerate(A))
print(f"break: right side of steps only, D = {right_only:.4f} (right {D1:.4f})")
print(f"break: two-sample scale sqrt(8) not sqrt(4): p = {kolmogorov_q(math.sqrt(8) * D2):.4f} (exact {hits / 12870:.4f})")
print(f"break: limit law for n 8 one-sample: p = {kolmogorov_q(math.sqrt(8) * D1):.4f} (exact {p1:.4f})")
print(f"break: mean fitted from data ({sum(A) / 8:.4f}): D = {Dest:.4f}, table p = {1 - mtw_below(8, Dest):.4f}, honest p = {simest / R:.4f}")
print(f"break: ln(1/alpha) for ln(2/alpha): half-width {math.sqrt(math.log(20) / 16):.4f} (right {eps:.4f})")

# ---- try changing ----
print(f"try: n 32, DKW 95% half-width {dkw(32, 0.05):.4f}; n 8 at 90%: {dkw(8, 0.10):.4f}")
print(f"try: shop B 1 min faster, D = {d_two(A, [b - 1.0 for b in B]):.3f}")
D1b = d_one(A, lambda t: model(t, 2.0))
print(f"try: model mean 2 min, D = {D1b:.4f}, exact p = {1 - mtw_below(8, D1b):.4f}")

# ---- figure: x 40 + 50 px per minute, y 260 - 200 px per unit ----
print(f"figure, gap line x {40 + 50 * 3.1:.0f}, from y {260 - 200 * ecdf(B, 3.1):.0f} to {260 - 200 * ecdf(A, 3.1):.0f}")

assert abs(D2 - 0.5) < 1e-12 and abs(walk - D2) < 1e-12          # D by two roads
assert hits == 12870 - paths[8][8]                                # p by enumeration = by paths
assert abs(D1 - grid) < 1e-6                                      # D at the steps = D on a fine grid
assert abs(sim1 / R - p1) < 0.006                                 # exact null law = simulation
assert abs(eps - 0.4802) < 1e-4 and miss <= 0.05                  # DKW is safe at n = 8
assert abs(simdkw / R - miss) < 0.004
assert hi < eps                                                   # DKW band is wider than exact
assert abs(1 - mtw_below(1, 0.7) - 0.6) < 1e-12                   # n = 1: P(D_1 >= d) = 2(1 - d)
assert all(abs(kolmogorov_q(l) - kolmogorov_theta(l)) < 1e-12 for l in (lam2, math.sqrt(8) * D2, math.sqrt(8) * D1))  # Q by two series
assert simest / R < (1 - mtw_below(8, Dest)) / 2                  # fitting the mean shrinks the null gaps
print("ALL CHECKS PASS")
