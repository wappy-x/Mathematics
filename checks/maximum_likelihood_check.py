# Maximum likelihood -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  Roads to each peak: the closed
# form, a brute grid, a golden-section search that uses no slopes, and a
# seeded simulation (SplitMix64, written out, same draws as the Rust check).
from math import log, sqrt, exp, cos, pi, inf

def loglik(k, n, p):                      # ln of p^k (1-p)^(n-k), with 0^0 = 1
    if (p <= 0 and k > 0) or (p >= 1 and k < n): return -inf
    return (k * log(p) if k else 0.0) + ((n - k) * log(1 - p) if n - k else 0.0)

def grid_argmax(f, lo, hi, steps):        # try every grid point, keep the best
    best, arg = -inf, lo
    for i in range(steps + 1):
        x = lo + (hi - lo) * i / steps
        v = f(x)
        if v > best: best, arg = v, x
    return arg

def golden(f, lo, hi):                    # shrink a bracket round the peak; no slopes
    g = (sqrt(5.0) - 1.0) / 2.0
    a, b = lo, hi
    for _ in range(100):
        c, d = b - g * (b - a), a + g * (b - a)
        if f(c) > f(d): b = d
        else: a = c
    return (a + b) / 2.0

M64 = (1 << 64) - 1
state = [20260928]
def unif():                               # SplitMix64: a uniform number in [0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def mean_sd(xs):                          # plain running sums, the same order as the Rust check
    s = 0.0
    for x in xs: s += x
    m, ss = s / len(xs), 0.0
    for x in xs: ss += (x - m) * (x - m)
    return m, sqrt(ss / (len(xs) - 1))

def show(label, v): print(f"{label:<46}{v:>12.6f}")

# ---- the poll: 520 yes out of 1,000 ----
n, k = 1000, 520
p_hat = k / n
f = lambda p: loglik(k, n, p)
p_grid, p_gold = grid_argmax(f, 0.0, 1.0, 10000), golden(f, 0.001, 0.999)
top = f(p_hat)
h = 1e-3
curv = (f(p_hat + h) - 2.0 * top + f(p_hat - h)) / (h * h)
se_formula, se_curv = sqrt(p_hat * (1 - p_hat) / n), 1.0 / sqrt(-curv)
log_choose = sum(log(i) for i in range(n - k + 1, n + 1)) - sum(log(i) for i in range(1, k + 1))
show("poll: p-hat, closed form k/n", p_hat)
show("poll: p-hat, grid of 10,001 points", p_grid)
show("poll: p-hat, golden-section search", p_gold)
show("poll: log-likelihood at the peak", top)
show("poll: the same, as a power of 10", top / log(10.0))
show("poll: relative likelihood at p = 0.50", exp(f(0.50) - top))
show("poll: relative likelihood at p = 0.55", exp(f(0.55) - top))
show("poll: chance of exactly 520 yes if p = 0.52", exp(log_choose + top))
show("poll: curvature, minus second difference", -curv)
show("poll: SE, formula sqrt(p(1-p)/n)", se_formula)
show("poll: SE, from the curvature of the peak", se_curv)
show("try: SE for 52 yes out of 100", sqrt(0.52 * 0.48 / 100))
print("chart, p          " + " ".join(f"{0.46 + 0.01 * i:5.2f}" for i in range(13)))
print("chart, n = 1000   " + " ".join(f"{f(0.46 + 0.01 * i) - top:5.2f}" for i in range(13)))
print("chart, n = 100    " + " ".join(f"{loglik(52, 100, 0.46 + 0.01 * i) - loglik(52, 100, 0.52):5.2f}" for i in range(13)))

# ---- road 4: rerun the poll 2,000 times with the true share set to 0.52 ----
sims = [sum(1 for _ in range(n) if unif() < 0.52) / n for _ in range(2000)]
sim_mean, sim_sd = mean_sd(sims)
show("sim: average p-hat over 2,000 polls", sim_mean)
show("sim: its standard error", sim_sd / sqrt(2000))
show("sim: spread (SD) of p-hat", sim_sd)

# ---- the edge: 0 yes out of 20 on a fringe measure ----
g = lambda p: loglik(0, 20, p)
show("edge: p-hat, closed form 0/20", 0 / 20)
e_grid, e_gold = grid_argmax(g, 0.0, 1.0, 10000), golden(g, 0.001, 0.999)
show("edge: p-hat, grid on [0, 1]", e_grid)
show("edge: golden search, walls at 0.001, 0.999", e_gold)
show("edge: slope of log-likelihood at p = 0", -20 / (1 - 0.0))
show("edge: SE formula at p-hat = 0", sqrt(0.0 * 1.0 / 20))
print("chart, edge p     " + " ".join(f"{0.02 * i:5.2f}" for i in range(11)))
print("chart, edge ll    " + " ".join(f"{g(0.02 * i):5.2f}" for i in range(11)))

# ---- the normal: five earlier polls of the same race ----
polls = [0.49, 0.51, 0.52, 0.54, 0.54]
m = len(polls)
def nll(mu, v, xs): return -len(xs) / 2.0 * log(2.0 * pi * v) - sum((x - mu) ** 2 for x in xs) / (2.0 * v)
mu_hat = sum(polls) / m
Q = sum((x - mu_hat) ** 2 for x in polls)
best = (-inf, 0.0, 0.0)
for i in range(401):                      # road 2: brute grid over mean and variance together
    for j in range(1, 1001):
        val = nll(0.50 + 0.0001 * i, 0.000001 * j, polls)
        if val > best[0]: best = (val, 0.50 + 0.0001 * i, 0.000001 * j)
show("normal: mean-hat, closed form x-bar", mu_hat)
show("normal: mean-hat, grid", best[1])
show("normal: Q, sum of squared gaps", Q)
show("normal: v-hat = Q/n, closed form", Q / m)
show("normal: v-hat, grid", best[2])
show("normal: sigma-hat = sqrt(Q/n)", sqrt(Q / m))
show("normal: SE of mean-hat, sigma-hat/sqrt(n)", sqrt(Q / m) / sqrt(m))
show("normal: SE of v-hat, v-hat * sqrt(2/n)", Q / m * sqrt(2.0 / m))
show("normal: Q/(n-1), the unbiased variance", Q / (m - 1))
same, col = [0.52] * 5, []
for lab, v in (("0.001", 1e-3), ("0.00001", 1e-5), ("0.0000001", 1e-7)):
    col.append(nll(0.52, v, same))
    show("all five at 0.52: log-lik at v = " + lab, col[-1])
drop = lambda v: -Q / (2.0 * v)           # the likelihood with the v^(-n/2) factor dropped
show("dropped factor: best v on the grid (0, 1]", v_drop := grid_argmax(drop, 0.0001, 1.0, 9999))

# ---- what breaks: the bias of v-hat, and clustered households ----
v_true = 0.52 * 0.48 / 1000
ratios = []
for _ in range(20000):
    xs = [0.52 + sqrt(v_true) * sqrt(-2.0 * log(1.0 - unif())) * cos(2.0 * pi * unif()) for _ in range(5)]
    xb = sum(xs) / 5
    ratios.append(sum((x - xb) ** 2 for x in xs) / 5 / v_true)
r_mean, r_sd = mean_sd(ratios)
show("bias sim: average v-hat / true v, 20,000 sets", r_mean)
show("bias sim: its standard error", r_sd / sqrt(20000))
pairs = [2 * sum(1 for _ in range(500) if unif() < 0.52) / 1000 for _ in range(2000)]
show("pairs: true SE sqrt(p(1-p)/500)", sqrt(0.52 * 0.48 / 500))
show("pairs: simulated SD of p-hat, 2,000 polls", pair_sd := mean_sd(pairs)[1])

assert abs(p_grid - p_hat) < 1e-4 and abs(p_gold - p_hat) < 1e-6, "searches must find k/n"
assert abs(se_curv - se_formula) < 1e-6, "curvature SE must match p(1-p)/n"
assert abs(sim_mean - 0.52) < 4 * sim_sd / sqrt(2000) and abs(sim_sd - se_formula) < 0.001, "simulation"
assert abs(best[1] - mu_hat) < 1e-4 and abs(best[2] - Q / m) < 1.5e-6, "normal grid must find x-bar and Q/n"
assert abs(r_mean - 0.8) < 4 * r_sd / sqrt(20000), "v-hat averages (n-1)/n of the truth"
assert e_grid == 0.0 and abs(e_gold - 0.001) < 1e-6, "edge: peak at p = 0; a walled search stops at its wall"
assert col[0] < col[1] < col[2] and v_drop > 0.999, "collapsed normal climbs; dropped factor runs to the top"
assert abs(pair_sd - sqrt(0.52 * 0.48 / 500)) < 4 * pair_sd / sqrt(2 * 1999) and pair_sd > 1.3 * se_formula, "households"
print("ALL CHECKS PASS")
