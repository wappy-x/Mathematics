# Cointegration in outline -- the check behind the card.  Only math is imported.
# Two petrol stations on one crossroads, a year of daily pump prices in dollars
# per gallon.  South follows the wholesale market; both stations answer a gap.
# Engle-Granger: fit the tie, test the leftover; then the error-correction model.
import math

MASK = (1 << 64) - 1

class Rng:                                       # SplitMix64, then Box-Muller
    def __init__(self, seed):
        self.s = seed
    def bits(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def normal(self):
        u1 = ((self.bits() >> 11) + 0.5) / 2.0 ** 53
        u2 = (self.bits() >> 11) / 2.0 ** 53
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

DAYS, C, A_N, A_S, SHOCK = 365, 0.06, -0.12, 0.03, 10.0

def stations(rng):                               # the built world: beta = 1, c = 6 cents
    north, south = [3.40 + C], [3.40]
    for _ in range(DAYS - 1):
        gap = north[-1] - C - south[-1]
        eta, e_n, e_s = 0.02 * rng.normal(), 0.015 * rng.normal(), 0.015 * rng.normal()
        north.append(north[-1] + A_N * gap + eta + e_n)
        south.append(south[-1] + A_S * gap + eta + e_s)
    return north, south

def walk(rng, sd):                               # a price with no home and no partner
    x = [3.40]
    for _ in range(DAYS - 1):
        x.append(x[-1] + sd * rng.normal())
    return x

diff = lambda x: [x[t] - x[t - 1] for t in range(1, len(x))]

def fit_line(y, x):                              # least squares y = c + b x, and R^2
    mx, my = sum(x) / len(x), sum(y) / len(y)
    sxy = sum((a - mx) * (b - my) for a, b in zip(x, y))
    sxx, syy = sum((a - mx) ** 2 for a in x), sum((b - my) ** 2 for b in y)
    b = sxy / sxx
    return my - b * mx, b, [v - my - b * (u - mx) for u, v in zip(x, y)], sxy * sxy / (sxx * syy)

def slope0(y, x):                                # y = r x, no constant: slope, standard error
    sxx = sum(a * a for a in x)
    r = sum(a * b for a, b in zip(x, y)) / sxx
    s2 = sum((b - r * a) ** 2 for a, b in zip(x, y)) / (len(x) - 1)
    return r, math.sqrt(s2 / sxx)

def eg(y, x):                                    # Engle-Granger: c, ratio, leftover, rho, se, tau, R^2
    c, b, z, r2 = fit_line(y, x)
    rho, se = slope0(diff(z), z[:-1])
    return c, b, z, rho, se, rho / se, r2

def search_ratio(y, x):                          # road two: shrink a bracket on the misfit
    my, mx = sum(y) / len(y), sum(x) / len(x)
    miss = lambda b: sum(((v - my) - b * (u - mx)) ** 2 for u, v in zip(x, y))
    lo, hi = 0.0, 2.0
    for _ in range(100):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, m2) if miss(m1) < miss(m2) else (m1, hi)
    return (lo + hi) / 2

def mackinnon(b0, b1, b2, b3, t):                # MacKinnon (2010): the 5% cutoff for t changes
    return b0 + b1 / t + b2 / t ** 2 + b3 / t ** 3

north, south = stations(Rng(2025))
c, beta, z, rho, se, tau, r2 = eg(north, south)
beta_search = search_ratio(north, south)
cut2 = mackinnon(-3.33613, -6.1101, -6.823, 0.0, DAYS - 1)   # two prices, ratio fitted
cut1 = mackinnon(-2.86154, -2.8903, -4.234, -40.040, DAYS - 1)    # one series, nothing fitted
a_n, se_n = slope0(diff(north), z[:-1])
a_s, se_s = slope0(diff(south), z[:-1])
_, b_o, z_o, _, _, tau_o, r2_o = eg(north, walk(Rng(52), 0.025))   # one unrelated price, picked to show the trap
days = list(range(0, DAYS, 14))
f2 = lambda xs: " ".join(f"{v:.2f}" for v in xs)
print(f"year of {DAYS} days; built with beta 1, c 0.06, alpha_N {A_N}, alpha_S {A_S}, phi {1 + A_N - A_S:.2f}")
print("figure, days", " ".join(str(d) for d in days))
for name, xs in (("north", north), ("south", south), ("tied leftover", z), ("unrelated leftover", z_o)):
    print(f"figure, {name}", f2(xs[d] for d in days))
print(f"step 1: beta_hat {beta:.4f}, c_hat {c:.4f}; by bracket search {beta_search:.4f}")
print(f"step 2: rho_hat {rho:.4f}, se {se:.4f}, tau {tau:.2f}, phi {1 + rho:.4f}")
print(f"half-life of a gap, fitted: {math.log(0.5) / math.log(1 + rho):.2f} days; built: "
      f"{math.log(0.5) / math.log(1 + A_N - A_S):.2f} days")
print(f"5% cutoff, two prices: {cut2:.3f}; one series: {cut1:.3f}; tied: {'yes' if tau < cut2 else 'no'}")
print(f"ecm: alpha_N {a_n:.4f} (se {se_n:.4f}), alpha_S {a_s:.4f} (se {se_s:.4f})")
print(f"alpha_N - beta_hat alpha_S = {a_n - beta * a_s:.4f}, the step-2 rho {rho:.4f}")
gap, moves = SHOCK, []                           # a 10-cent jump at North, traced
for day in range(400):
    moves.append((gap, A_N * gap, A_S * gap))
    gap += (A_N - A_S) * gap
for d in range(6):
    print(f"shock, day {d}: excess gap {moves[d][0]:.2f} cents, North {moves[d][1]:+.2f}, South {moves[d][2]:+.2f}")
tot_n, tot_s = sum(m[1] for m in moves), sum(m[2] for m in moves)
form_n, form_s = A_N * SHOCK / (A_S - A_N), A_S * SHOCK / (A_S - A_N)
print(f"shock totals, summed: North {tot_n:+.2f}, South {tot_s:+.2f}; by formula {form_n:+.2f}, {form_s:+.2f}")
toy = [4, 3, 1, 2, 0, -1, 0]                     # the by-hand table, in cents
toy_rho, _ = slope0(diff(toy), toy[:-1])
print(f"toy: sum lag*change {sum(a * b for a, b in zip(toy[:-1], diff(toy)))}, "
      f"sum lag^2 {sum(a * a for a in toy[:-1])}, rho {toy_rho:.4f}")
M, K, rng = 4000, 500, Rng(99)                   # unrelated pairs, then tied years
taus, r2s = [], []
for _ in range(M):
    out = eg(walk(rng, 1.0), walk(rng, 1.0))
    taus.append(out[5])
    r2s.append(out[6])
taus.sort(), r2s.sort()
p2, p1 = sum(t < cut2 for t in taus) / M, sum(t < cut1 for t in taus) / M
print(f"{M} unrelated pairs: simulated 5% cutoff {taus[M // 20]:.3f}; median R^2 {r2s[M // 2]:.2f}")
for cut, p in ((cut2, p2), (cut1, p1)):
    print(f"passed at {cut:.3f}: {100 * p:.2f}% (se {100 * math.sqrt(p * (1 - p) / M):.2f})")
betas, hits = [], 0
for _ in range(K):
    out = eg(*stations(rng))
    betas.append(out[1])
    hits += out[5] < cut2
mb = sum(betas) / K
sb = math.sqrt(sum((b - mb) ** 2 for b in betas) / (K - 1))
print(f"{K} tied years: judged tied {100 * hits / K:.2f}%; beta_hat mean {mb:.4f}, spread {sb:.4f}")
ms = sum(south) / DAYS
se_naive = math.sqrt(sum(v * v for v in z) / (DAYS - 2) / sum((s - ms) ** 2 for s in south))
_, b_d, _, _ = fit_line(diff(north), diff(south))
print(f"break 1, one-series cutoff on unrelated pairs: {100 * p1:.2f}% pass, not 5%")
print(f"break 2, unrelated price against North: R^2 {r2_o:.2f}, ratio {b_o:.2f}, tau {tau_o:.2f}")
print(f"break 3, textbook se of beta_hat {se_naive:.4f}, against the spread {sb:.4f} over {K} years")
print(f"break 4, changes on changes: slope {b_d:.2f}, not 1")
assert abs(beta - beta_search) < 1e-6                         # two roads to the ratio
assert abs(a_n - A_N) < 3 * se_n and abs(a_s - A_S) < 3 * se_s   # estimates near the build
assert abs(p2 - 0.05) < 3 * math.sqrt(0.05 * 0.95 / M)         # simulated vs published cutoff
assert abs(tot_n - form_n) < 1e-9                             # summed trace vs geometric series
assert abs(toy_rho + 14 / 31) < 1e-12                          # the by-hand fraction
assert tau < cut2 and abs(a_n - beta * a_s - rho) < 1e-12        # the verdict; pulls rebuild rho
assert p1 > 0.05 + 3 * math.sqrt(0.05 * 0.95 / M)              # break 1: one-series cutoff over-passes
print("ALL CHECKS PASS")
