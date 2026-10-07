# Jensen's inequality -- the check behind the card.  Standard library only;
# math gives log, exp and sqrt, nothing more.  The fund: each year a fair coin
# turns every $1 into $1.50 (up 50%) or $0.60 (down 40%).  Three roads: exact
# sums over the two outcomes, all 1,024 ten-year paths enumerated one by one,
# and a seeded simulation printed with its standard error.
from math import log, exp, sqrt

UP, DOWN, YEARS, M64 = 1.5, 0.6, 10, (1 << 64) - 1
FUND = [(UP, 0.5), (DOWN, 0.5)]                       # (growth factor, chance)
INDEX = [(0.80, 0.25), (1.08, 0.50), (1.30, 0.25)]    # second case: a calmer year
SWING = [(-0.40, 0.5), (0.10, 0.5)]                   # returns fed to a cube

def E(f, law):                        # expectation: the chance-weighted average of f
    return sum(p * f(x) for x, p in law)

def choose(n, k):                     # C(n, k) by the product rule, written out
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

state = 20260928                      # SplitMix64, seed 20260928
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def show(label, *vals, d=6):
    print(label + ": " + ", ".join(f"{v:.{d}f}" for v in vals))

# ---- one year: square, then logarithm ----
m = E(lambda x: x, FUND)
sq = E(lambda x: x * x, FUND)
var = E(lambda x: (x - m) ** 2, FUND)                 # road two: the definition
tan_sq = lambda x: m * m + 2 * m * (x - m)            # supporting line of x^2 at m
mlog, logm = E(log, FUND), log(m)
tan_log = lambda x: logm + (x - m) / m                # tangent of ln at m, above ln
typical = exp(mlog)
show("mean growth E[X]", m)
show("mean of squares E[X^2], square of mean", sq, m * m)
show("gap, and Var(X) as average squared distance", sq - m * m, var)
show("x^2 minus its line at m, at 1.5 and 0.6", UP * UP - tan_sq(UP), DOWN * DOWN - tan_sq(DOWN))
show("mean of logs E[ln X], log of mean ln E[X]", mlog, logm)
show("log gap", logm - mlog)
show("tangent of ln at m, at 1.5 and 0.6", tan_log(UP), tan_log(DOWN))
show("ln itself at 1.5 and 0.6", log(UP), log(DOWN))
show("typical growth exp(E[ln X]), and sqrt(1.5 x 0.6)", typical, sqrt(UP * DOWN))
show("drag rule mu - var/2, and the true E[ln X]", (m - 1) - var / 2, mlog)
show("1.5^2, 0.6^2, 1.5 - m, var/2, 1.5 x 0.6", UP * UP, DOWN * DOWN, UP - m, var / 2, UP * DOWN)

# ---- ten years: every path, then the counting formula ----
tot_w = tot_lw = 0.0
below = 0
for path in range(1 << YEARS):
    w = 1.0
    for year in range(YEARS):
        w *= UP if (path >> year) & 1 else DOWN
    tot_w += w
    tot_lw += log(w)
    below += w < 1.0
paths = 1 << YEARS
by_count = sum(choose(YEARS, k) for k in range(YEARS + 1) if k * log(UP) + (YEARS - k) * log(DOWN) < 0)
mean_formula = 1.0
for _ in range(YEARS):
    mean_formula *= m
print(f"ten years, {paths} paths; ending below the start: {below} by enumeration, {by_count} by counting")
show("mean wealth per $1: enumerated, formula 1.05^10", tot_w / paths, mean_formula)
show("mean log wealth: enumerated, 10 x E[ln X]", tot_lw / paths, YEARS * mlog)
show("chance of ending below the start", below / paths)
show("$100 in: mean, median (5 up, 5 down), best path", 100 * mean_formula, 100 * (UP * DOWN) ** 5, 100 * UP ** YEARS, d=2)

# ---- ten years: seeded simulation ----
N = 200000
s1 = s2 = l1 = l2 = 0.0
lo = 0
for _ in range(N):
    w = 1.0
    for year in range(YEARS):
        w *= UP if uniform() < 0.5 else DOWN
    s1 += w; s2 += w * w; l1 += log(w); l2 += log(w) ** 2
    lo += w < 1.0
sm, sl, sp = s1 / N, l1 / N, lo / N
se_m, se_l, se_p = sqrt((s2 / N - sm * sm) / N), sqrt((l2 / N - sl * sl) / N), sqrt(sp * (1 - sp) / N)
print(f"simulation: {N} paths of {YEARS} years, SplitMix64 seed 20260928")
show("  mean wealth, standard error", sm, se_m)
show("  mean wealth off the exact value, in standard errors", (sm - tot_w / paths) / se_m)
show("  mean log wealth, standard error", sl, se_l)
show("  chance below the start, standard error", sp, se_p)

# ---- second case: a calmer year ----
m2 = E(lambda x: x, INDEX)
v2 = E(lambda x: (x - m2) ** 2, INDEX)
ml2 = E(log, INDEX)
show("calmer year: E[X], E[X^2] - E[X]^2, Var(X)", m2, E(lambda x: x * x, INDEX) - m2 * m2, v2)
show("calmer year: E[ln X], ln E[X], gap, var/(2 m^2)", ml2, log(m2), log(m2) - ml2, v2 / (2 * m2 * m2))

# ---- what breaks: a cube on returns that are mostly negative ----
er = E(lambda r: r, SWING)
show("cube, returns -40% or +10%: E[R^3], (E[R])^3", E(lambda r: r ** 3, SWING), er ** 3)

# ---- the charts ----
xs = [0.6 + 0.05 * i for i in range(19)]
slope = (log(UP) - log(DOWN)) / (UP - DOWN)
print("figure, x: " + ", ".join(f"{x:.2f}" for x in xs))
print("figure, ln x: " + ", ".join(f"{log(x):.2f}" for x in xs))
print("figure, chord: " + ", ".join(f"{log(DOWN) + slope * (x - DOWN):.2f}" for x in xs))
print("figure, tangent: " + ", ".join(f"{tan_log(x):.2f}" for x in xs))
wm, wt, a, b = 100.0, 100.0, [], []
for n in range(YEARS + 1):
    a.append(wm); b.append(wt); wm *= m; wt *= typical
print("figure, mean $: " + ", ".join(f"{v:.2f}" for v in a))
print("figure, typical $: " + ", ".join(f"{v:.2f}" for v in b))

assert abs((sq - m * m) - var) < 1e-12                        # shortcut against definition
assert abs((m - 1) - var / 2 - mlog) < 0.002                 # drag rule is close
assert all(x * x >= tan_sq(x) and log(x) <= tan_log(x) for x, _ in FUND + INDEX)
assert sq > m * m and mlog < logm and ml2 < log(m2)           # Jensen, both directions
assert abs(tot_w / paths - mean_formula) < 1e-12 and below == by_count
assert abs(sm - tot_w / paths) < 4 * se_m and abs(sl - tot_lw / paths) < 4 * se_l
assert abs(sp - below / paths) < 4 * se_p                     # simulation agrees
assert E(lambda r: r ** 3, SWING) < er ** 3                   # no convexity, no Jensen
print("ALL CHECKS PASS")
