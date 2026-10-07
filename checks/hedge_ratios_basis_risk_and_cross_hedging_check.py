# Minimum-variance hedge ratio -- the check behind the card.  Standard library only.
# Jet fuel bought in three months, hedged with heating oil futures.  Prices in dollars
# per gallon; sS, sF = spread (standard deviation) of the three-month price changes.
from math import sqrt, log, cos, pi

sS, sF, rho = 0.18, 0.20, 0.943          # jet fuel spread, heating oil spread, correlation
Q, LOT = 2_000_000, 42_000               # gallons to buy; gallons per futures contract

def var_hedged(h):                       # variance of dS - h dF, from the three inputs
    return sS * sS - 2 * h * rho * sS * sF + h * h * sF * sF

def grid_min(f, lo=0.0, hi=1.5, step=1e-4):   # brute force: try every h on a fine grid
    best_h, best_v, n = lo, f(lo), int(round((hi - lo) / step))
    for i in range(1, n + 1):
        h = lo + i * step
        v = f(h)
        if v < best_v: best_h, best_v = h, v
    return best_h

class Rng:                               # splitmix64, then Box-Muller for normal draws
    def __init__(self, seed): self.x = seed
    def u(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        z ^= z >> 31
        return ((z >> 11) + 0.5) / 9007199254740992.0
    def normal(self): return sqrt(-2.0 * log(self.u())) * cos(2.0 * pi * self.u())

def draws(seed, n):                      # n quarters of (dS, dF) with the stated spreads and correlation
    g, out = Rng(seed), []
    for _ in range(n):
        z1, z2 = g.normal(), g.normal()
        out.append((sS * (rho * z1 + sqrt(1 - rho * rho) * z2), sF * z1))
    return out

def ols(data):                           # least squares of dS on dF: slope, R^2, residual spread, slope's std error
    n = len(data)
    ms = sum(s for s, _ in data) / n; mf = sum(f for _, f in data) / n
    sxx = sum((f - mf) ** 2 for _, f in data); syy = sum((s - ms) ** 2 for s, _ in data)
    sxy = sum((f - mf) * (s - ms) for s, f in data)
    b = sxy / sxx; ssr = syy - b * sxy
    return b, 1 - ssr / syy, sqrt(ssr / (n - 1)), sqrt(ssr / (n - 2) / sxx)

def sample_var(data, h):                 # spread of the hedged change, measured on the data
    xs = [s - h * f for s, f in data]; m = sum(xs) / len(xs)
    return sum((x - m) ** 2 for x in xs) / (len(xs) - 1)

# road 1: the formula.  road 2: brute-force grid on the variance
h_star = rho * sS / sF
h_grid = grid_min(var_hedged)
resid = sS * sqrt(1 - rho * rho)
# road 3: regression on 200,000 simulated quarters.  road 4: grid on the same sample
mc = draws(20260928, 200_000)
b_mc, r2_mc, res_mc, _ = ols(mc)
sub = mc[:20_000]
h_sub_ols = ols(sub)[0]
h_sub_grid = grid_min(lambda h: sample_var(sub, h), 0.7, 1.0, 1e-4)
# a short history: 40 quarters, as a desk would actually have
b_40, r2_40, res_40, se_40 = ols(draws(7, 40))

N_exact = h_star * Q / LOT
N = round(N_exact)
h_used = N * LOT / Q
res_used = sqrt(var_hedged(h_used))

rows = [
    ("1 formula  rho sS / sF", h_star, 6), ("2 grid minimum of variance", h_grid, 6),
    ("3 regression, 200,000 quarters", b_mc, 6), ("4 grid on 20,000 quarters", h_sub_grid, 6),
    ("  regression, same 20,000", h_sub_ols, 6),
    ("covariance  rho sS sF", rho * sS * sF, 6), ("1 - rho^2", 1 - rho * rho, 6),
    ("sqrt(1 - rho^2)", sqrt(1 - rho * rho), 6), ("unhedged spread, $/gal", sS, 6), ("residual spread  sS sqrt(1-rho^2)", resid, 6),
    ("  simulated residual spread", res_mc, 6), ("spread cut, fraction", 1 - resid / sS, 6),
    ("variance cut  rho^2", rho * rho, 6), ("  simulated R^2", r2_mc, 6),
    ("contracts, exact  h Q / LOT", N_exact, 4), ("contracts, rounded", N, 0),
    ("hedge ratio actually held", h_used, 4), ("residual spread at 40 contracts", res_used, 6),
    ("unhedged spread, $ on 2m gal", sS * Q, 2), ("hedged spread, $ on 2m gal", res_used * Q, 2),
    ("40 quarters: slope", b_40, 4), ("40 quarters: std error of slope", se_40, 4),
    ("40 quarters: R^2", r2_40, 4), ("40 quarters: two std errors", 2 * se_40, 4),
    ("gap, road 3 minus road 1", b_mc - h_star, 6),
    ("basis-change spread (h = 1)", sqrt(var_hedged(1.0)), 6),
    ("penalty check  resid^2 + sF^2 (1-h*)^2", sqrt(resid ** 2 + sF ** 2 * (1 - h_star) ** 2), 6),
    ("wrong: sign flipped, h = -h*, spread", sqrt(var_hedged(-h_star)), 6),
    ("wrong: h = rho, spread", sqrt(var_hedged(rho)), 6),
    ("wrong: h = sS / sF, spread", sqrt(var_hedged(sS / sF)), 6),
    ("wrong: reversed regression h", rho * sF / sS, 6),
    ("  its spread", sqrt(var_hedged(rho * sF / sS)), 6),
    ("story: futures gain per gal, 2.50 to 2.90", h_used * (2.90 - 2.50), 4),
    ("story: net cost per gal, jet 2.40 to 2.75", 2.75 - h_used * (2.90 - 2.50), 4),
    ("story: net cost minus today's 2.40", 2.75 - h_used * (2.90 - 2.50) - 2.40, 4),
    ("beta hedge: 1.2 x 10,000,000 / 250,000", 1.2 * 10_000_000 / 250_000, 2),
    ("try: rho = 0.8, hedge ratio", 0.8 * sS / sF, 4), ("try: sF = 0.40, hedge ratio", rho * sS / 0.40, 4),
    ("try: 400 quarters, std error of slope", ols(draws(7, 400))[3], 4),
    ("try: 48 contracts, ratio held", 48 * LOT / Q, 4),
    ("try: 48 contracts, spread", sqrt(var_hedged(48 * LOT / Q)), 6),
]
for lab, v, d in rows: print(f"{lab:<42}{v:>16.{d}f}")

hs = [0.0, 0.25, 0.5, 0.75, 0.85, 1.0, 1.25, 1.5]
print("chart, hedge ratio      " + "".join(f"{h:>7.2f}" for h in hs))
print("chart, spread in cents  " + "".join(f"{100 * sqrt(var_hedged(h)):>7.2f}" for h in hs))
rs = [0.5, 0.7, 0.8, 0.9, 0.943, 0.97, 0.99]
print("chart, correlation      " + "".join(f"{r:>7.3f}" for r in rs))
print("chart, spread cut, %    " + "".join(f"{100 * (1 - sqrt(1 - r * r)):>7.2f}" for r in rs))

assert abs(h_grid - h_star) < 1e-4, "grid disagrees with the formula"
assert abs(b_mc - h_star) < 0.005, "simulated regression disagrees with the formula"
assert abs(h_sub_grid - h_sub_ols) < 1e-4, "least squares is not the minimum-variance hedge"
assert abs(res_mc - resid) < 0.001, "simulated residual spread disagrees"
assert abs(sqrt(sample_var(mc, 1.0)) - sqrt(var_hedged(1.0))) < 0.001, "h = 1 spread disagrees"
print("ALL CHECKS PASS")
