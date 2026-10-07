# Many tests -- the check behind the card.  Only math.sqrt, exp, log, cos, pi
# are imported.  100 genes, each tested at the 5% level.  Three roads: exact
# formulas, exact enumeration of small discrete models, and a seeded simulation
# (SplitMix64, seed 20260928) printed with standard errors.
from math import sqrt, exp, log, cos, pi
M64, ALPHA, M, M0, SHIFT, RUNS = (1 << 64) - 1, 0.05, 100, 90, 3.0, 20000

class SplitMix:                                   # the random numbers, written out
    def __init__(self, seed): self.s = seed
    def unif(self):                               # a draw strictly between 0 and 1
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
    def normal(self):                             # Box-Muller: two uniforms, one bell draw
        a = self.unif()
        return sqrt(-2.0 * log(a)) * cos(2.0 * pi * self.unif())

def Q(z):                                         # bell area to the right of z
    if z < 0: return 1.0 - Q(-z)
    if z < 3.0:                                   # Taylor series of the area from 0 to z
        term, total, j = z, z, 0
        while abs(term) > 1e-17:
            j += 1
            term *= -z * z * (2 * j - 1) / (2 * j * (2 * j + 1))
            total += term
        return 0.5 - total / sqrt(2.0 * pi)
    f = 0.0                                       # Laplace's continued fraction, far tail
    for k in range(60, 0, -1): f = k / (z + f)
    return exp(-0.5 * z * z) / sqrt(2.0 * pi) / (z + f)

def Q_inv(t):                                     # the z with area t to its right, by halving
    a, b = -10.0, 10.0
    for _ in range(200):
        c = 0.5 * (a + b)
        if Q(c) > t: a = c
        else: b = c
    return 0.5 * (a + b)

def bh_stepup(ps, q):                             # road one: largest rank under its line
    s, m = sorted(ps), len(ps)
    return max([0] + [k for k in range(1, m + 1) if s[k - 1] <= q * k / m])

def bh_count(ps, q):                              # road two: largest r with r p-values under q r/m
    m = len(ps)
    for r in range(m, 0, -1):
        if sum(p <= q * r / m for p in ps) >= r: return r
    return 0

def first_fail(ps, q):                            # the mistake: stop at the first rank that fails
    s, m, k = sorted(ps), len(ps), 0
    while k < m and s[k] <= q * (k + 1) / m: k += 1
    return k

def holm(ps, a):                                  # step down: rank k against a/(m-k+1)
    s, m, k = sorted(ps), len(ps), 0
    while k < m and s[k] <= a / (m - k): k += 1
    return k

def row(label, v, d=6): print(f"{label:<44}{v:>12.{d}f}")

row("expected false alarms, 100 nulls, m x alpha", M * ALPHA)
row("chance of at least one, 1 - 0.95^100", 1 - (1 - ALPHA) ** M)
row("Bonferroni cutoff alpha/m", ALPHA / M)
row("Sidak cutoff 1 - 0.95^(1/100)", 1 - (1 - ALPHA) ** (1 / M))
row("Bonferroni FWER, 100 nulls, independent", 1 - (1 - ALPHA / M) ** M)
row("Bonferroni FWER, 90 nulls, independent", 1 - (1 - ALPHA / M) ** M0)
row("union bound, 90 nulls, 90 x alpha/m", M0 * ALPHA / M)
row("BH promise q m0/m, 90 nulls", ALPHA * M0 / M)
row("BY cutoff divisor 1 + 1/2 + ... + 1/100", sum(1 / k for k in range(1, M + 1)))
row("best of 100 nulls at or below 0.01", 1 - 0.99 ** M)
row("bell cutoff, one-sided 0.05", Q_inv(ALPHA), 4)
row("bell cutoff, one-sided 0.0005", Q_inv(ALPHA / M), 4)
LIST = [0.00002, 0.00011, 0.0004, 0.0009, 0.0015, 0.0021, 0.0036, 0.0038,
        0.0052, 0.0071, 0.021, 0.034] + [0.05 + 0.01 * j for j in range(1, 89)]
print("rank, p and BH line, then both in thousandths")
for k in range(1, 11):
    p, line = sorted(LIST)[k - 1], ALPHA * k / M
    print(f"  {k:>2} {p:>9.5f} {line:>9.5f} {1000 * p:>8.2f} {1000 * line:>8.2f}")
r1, r2 = bh_stepup(LIST, ALPHA), bh_count(LIST, ALPHA)
print(f"BH rank scan {r1}; BH by counting {r2}; first-failure stop {first_fail(LIST, ALPHA)}")
print(f"Bonferroni {sum(p <= ALPHA / M for p in LIST)}; Holm {holm(LIST, ALPHA)}; "
      f"uncorrected {sum(p <= ALPHA for p in LIST)}; BH cutoff {ALPHA * r1 / M:.4f}")
print("figure, tests m      " + " ".join(f"{m:>5}" for m in (1, 2, 5, 10, 20, 50, 100)))
print("figure, uncorrected  " + " ".join(f"{1 - 0.95 ** m:>5.2f}" for m in (1, 2, 5, 10, 20, 50, 100)))
print("figure, Bonferroni   " + " ".join(f"{1 - (1 - 0.05 / m) ** m:>5.2f}" for m in (1, 2, 5, 10, 20, 50, 100)))

enum = []                                         # road two: every outcome of 3 tests on a quarter grid
for m0 in range(4):                               # m0 nulls uniform on 1/4..1, the rest p = 0, level 3/4
    fdr6 = bon = 0
    for code in range(4 ** m0):
        ps = [((code >> (2 * i)) % 4 + 1) / 4 for i in range(m0)] + [0.0] * (3 - m0)
        r = bh_stepup(ps, 0.75); v = sum(p <= 0.75 * r / 3 for p in ps[:m0])
        fdr6 += 6 * v // max(r, 1); bon += any(p <= 0.25 for p in ps[:m0])
    enum.append((4 * fdr6 == 6 * m0 * 4 ** m0, bon == 4 ** m0 - 3 ** m0))
    print(f"enumerate m0={m0}: BH FDR {fdr6 / (6 * 4 ** m0):.6f} vs 0.75 m0/3; "
          f"Bonferroni FWER {bon / 4 ** m0:.6f} vs 1 - 0.75^m0")
DEP = [((0.05, 1.0), 1), ((1.0, 0.05), 1), ((0.1, 0.1), 1), ((1.0, 1.0), 17)]  # weights in 20ths
dep_bh = sum(w for ps, w in DEP if bh_count(list(ps), 0.1) > 0) / 20
dep_bon = sum(w for ps, w in DEP if min(ps) <= 0.05) / 20
print(f"dependent pair, both null, q = 0.10: BH FDR {dep_bh:.2f}; Bonferroni FWER {dep_bon:.2f}")

rng, agree, T = SplitMix(20260928), 0, {}
def tally(key, x):
    s = T.setdefault(key, [0.0, 0.0]); s[0] += x; s[1] += x * x
for _ in range(RUNS):
    u = [rng.unif() for _ in range(M)]
    k = sum(p <= ALPHA for p in u)                # scenario A: all 100 genes null
    tally("A false alarms", k); tally("A any, uncorrected", k > 0)
    tally("A any, Bonferroni", any(p <= ALPHA / M for p in u))
    ps = u[:M0] + [Q(rng.normal() + SHIFT) for _ in range(M - M0)]   # B: 90 null, 10 real
    r = bh_stepup(ps, ALPHA); agree += r == bh_count(ps, ALPHA)
    v = sum(p <= ALPHA * r / M for p in ps[:M0])
    tally("B BH FDP", v / max(r, 1)); tally("B BH any false", v > 0); tally("B BH real found", r - v)
    tally("B Bonferroni any false", any(p <= ALPHA / M for p in ps[:M0]))
    tally("B Bonferroni real found", sum(p <= ALPHA / M for p in ps[M0:]))
    r0, v0 = sum(p <= ALPHA for p in ps), sum(p <= ALPHA for p in ps[:M0])
    tally("B uncorrected FDP", v0 / max(r0, 1)); tally("B uncorrected real found", r0 - v0)
EST = {}
print(f"simulation, {RUNS} experiments of 100 genes, estimate and standard error")
for key, (s, s2) in T.items():
    mean = s / RUNS; se = sqrt(max(s2 / RUNS - mean * mean, 0.0) / RUNS); EST[key] = (mean, se)
    print(f"  {key:<30}{mean:>10.4f}{se:>10.4f}")
row("exact real found per 10, Bonferroni", 10 * Q(Q_inv(ALPHA / M) - SHIFT), 4)
row("exact real found per 10, uncorrected", 10 * Q(Q_inv(ALPHA) - SHIFT), 4)
print(f"BH two roads agree in {agree} of {RUNS} experiments")

def near(key, exact): return abs(EST[key][0] - exact) < 4 * EST[key][1]
assert r1 == r2 == 8 and agree == RUNS                     # two BH roads, one answer
assert all(a and b for a, b in enum) and dep_bh > 0.1 >= dep_bon   # enumeration; dependence breaks BH
assert near("A any, uncorrected", 1 - (1 - ALPHA) ** M) and near("A false alarms", M * ALPHA)
assert near("A any, Bonferroni", 1 - (1 - ALPHA / M) ** M) and near("B BH FDP", ALPHA * M0 / M)
assert near("B Bonferroni real found", 10 * Q(Q_inv(ALPHA / M) - SHIFT))
assert near("B Bonferroni any false", 1 - (1 - ALPHA / M) ** M0)
assert abs(Q_inv(ALPHA) - 1.6448536) < 1e-6 and abs(Q_inv(ALPHA / M) - 3.2905267) < 1e-6   # tabled bell cutoffs
assert near("B uncorrected real found", 10 * Q(Q_inv(ALPHA) - SHIFT))
print("ALL CHECKS PASS")
