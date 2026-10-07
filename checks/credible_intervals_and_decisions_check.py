# Credible intervals and decisions -- the check behind the card.  Standard library only.
# A new coin shows 7 heads in 10 flips.  Flat prior, so the chance of heads has posterior
# Beta(8, 4).  Roads: (1) the posterior CDF as a binomial sum, (2) the same CDF by Simpson's
# rule on the density, (3) a seeded simulation that draws a chance from the flat prior, flips
# ten times and keeps only the runs with 7 heads; it never uses a beta formula.
N_FLIPS, HEADS, STAKE = 10, 7, 10.0
A, B = 1 + HEADS, 1 + N_FLIPS - HEADS            # posterior Beta(8, 4)
MASK = (1 << 64) - 1

def choose(n, k):
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

def cdf_sum(t, a, b):                            # road 1: P(chance <= t) = P(at least a of a+b-1 uniforms <= t)
    n = a + b - 1
    return sum(choose(n, j) * t ** j * (1 - t) ** (n - j) for j in range(a, n + 1))

def dens(t, a=A, b=B):                           # 1/B(a,b) = (a+b-1)!/((a-1)!(b-1)!) for whole a, b
    return (a + b - 1) * choose(a + b - 2, a - 1) * t ** (a - 1) * (1 - t) ** (b - 1)

def simpson(g, lo, hi, n=2000):
    h = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4 if i % 2 else 2) * g(lo + i * h) for i in range(1, n))
    return s * h / 3

def cdf_int(t):                                  # road 2: area under the density up to t
    return simpson(dens, 0.0, t)

def quantile(cdf, p):                            # bisection: the t with cdf(t) = p
    lo, hi = 0.0, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if cdf(mid) < p else (lo, mid)
    return (lo + hi) / 2

def q(p, a=A, b=B):
    return quantile(lambda t: cdf_sum(t, a, b), p)

lo1, hi1, med = q(0.025), q(0.975), q(0.5)
lo2, hi2 = quantile(cdf_int, 0.025), quantile(cdf_int, 0.975)
m, v, mode = A / (A + B), A * B / ((A + B) ** 2 * (A + B + 1)), (A - 1) / (A + B - 2)
below_half = cdf_int(0.5)                        # by hand: (165 + 55 + 11 + 1) / 2048 = 29/256
lo_share, hi_share = 0.0, 0.05                   # shortest 95%: slide the 5% between the tails
for _ in range(60):
    c1, c2 = lo_share + (hi_share - lo_share) / 3, hi_share - (hi_share - lo_share) / 3
    if q(c1 + 0.95) - q(c1) < q(c2 + 0.95) - q(c2):
        hi_share = c2
    else:
        lo_share = c1
hpd_lo, hpd_hi = q(lo_share), q(lo_share + 0.95)

state = 20260929                                 # road 3: SplitMix64, seed 20260929
def uniform():                                   # strictly between 0 and 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
kept = []
for _ in range(220000):                          # a chance from the flat prior, then ten flips
    theta = uniform()
    if sum(uniform() < theta for _ in range(N_FLIPS)) == HEADS:
        kept.append(theta)
kept.sort()
k = len(kept)
sim_m = sum(kept) / k
sim_se = (sum((t - sim_m) ** 2 for t in kept) / (k - 1) / k) ** 0.5
sim_p = sum(t > 0.5 for t in kept) / k
sim_p_se = (sim_p * (1 - sim_p) / k) ** 0.5

def heads(t):                                    # profit per flip of a $10 even-money bet on heads
    return STAKE * (2 * t - 1)
def post_avg(g):                                 # average of g over the posterior, by Simpson
    return simpson(lambda t: g(t) * dens(t), 0.0, 1.0)
profit_heads, profit_tails = post_avg(heads), post_avg(lambda t: -heads(t))
profit_tilt = post_avg(lambda t: 18 * t - 10)    # heads wins $8, tails loses $10
shortfall = post_avg(lambda t: max(0.0, -heads(t)))
sim_profit = sum(heads(t) for t in kept) / k
risk = [post_avg(lambda t, d=d: (t - d) ** 2) for d in (m, med, mode)]

def cover(theta, ints):                          # chance, at a fixed theta, that the recipe's interval holds it
    return sum(choose(N_FLIPS, x) * theta ** x * (1 - theta) ** (N_FLIPS - x)
               for x, (lo, hi) in enumerate(ints) if lo <= theta <= hi)
CRED = [(q(0.025, 1 + x, 1 + N_FLIPS - x), q(0.975, 1 + x, 1 + N_FLIPS - x)) for x in range(N_FLIPS + 1)]
EXACT = [(0.0 if x == 0 else q(0.025, x, N_FLIPS - x + 1),     # Clopper-Pearson ends are beta quantiles too
          1.0 if x == N_FLIPS else q(0.975, x + 1, N_FLIPS - x)) for x in range(N_FLIPS + 1)]
G = 20000
prior_avg = sum(cover((i + 0.5) / G, CRED) for i in range(G)) / G
grid = [j / 20 for j in range(1, 20)]
cov_c, cov_e = [cover(t, CRED) for t in grid], [cover(t, EXACT) for t in grid]
cp_lo, cp_hi = EXACT[HEADS]

rows = [
    ("posterior Beta(a, b), 1/B(a, b)", f"{A} {B} {(A + B - 1) * choose(A + B - 2, A - 1)}"), ("mean, sd", f"{m:.4f} {v ** 0.5:.4f}"),
    ("median, mode", f"{med:.4f} {mode:.4f}"),
    ("P(chance <= 1/2) Simpson, 29/256", f"{below_half:.6f} {29 / 256:.6f} = "
     + " + ".join(str(choose(11, j)) for j in range(8, 12)) + " over 2048"),
    ("P(chance > 1/2)", f"{1 - below_half:.4f}"),
    ("95% equal-tailed, binomial sum", f"{lo1:.4f} {hi1:.4f}"),
    ("95% equal-tailed, Simpson", f"{lo2:.4f} {hi2:.4f}"),
    ("95% shortest", f"{hpd_lo:.4f} {hpd_hi:.4f}"),
    ("widths: equal-tailed, shortest", f"{hi1 - lo1:.4f} {hpd_hi - hpd_lo:.4f}"),
    ("sim: prior draws, runs kept, share, 1/11", f"220000 {k} {k / 220000:.4f} {1 / 11:.4f}"),
    ("sim: mean, se", f"{sim_m:.4f} {sim_se:.4f}"),
    ("sim: P(chance > 1/2), se", f"{sim_p:.4f} {sim_p_se:.4f}"),
    ("sim: 2.5% and 97.5% points", f"{kept[int(0.025 * k)]:.4f} {kept[int(0.975 * k)]:.4f}"),
    ("profit/flip: heads, tails, decline ($)", f"{profit_heads:.4f} {profit_tails:.4f} 0.0000"),
    ("  10 (2 mean - 1), sim ($)", f"{STAKE * (2 * m - 1):.4f} {sim_profit:.4f}"),
    ("  shortfall of heads when tails-heavy ($)", f"{shortfall:.4f}"),
    ("tilted 8 to 10: profit ($), P(loses)", f"{profit_tilt:.4f} {cdf_int(10 / 18):.4f}"),
    ("  payout that breaks even ($)", f"{STAKE * (1 - m) / m:.4f}"),
    ("sq risk: mean, median, mode", f"{risk[0]:.6f} {risk[1]:.6f} {risk[2]:.6f}"),
    ("  var, var + (mode - mean)^2", f"{v:.6f} {v + (mode - m) ** 2:.6f}"),
    ("95% exact confidence (Clopper-Pearson)", f"{cp_lo:.4f} {cp_hi:.4f}"),
    ("  its posterior mass", f"{cdf_sum(cp_hi, A, B) - cdf_sum(cp_lo, A, B):.4f}"),
    ("coverage at 0.5: credible, exact", f"{cover(0.5, CRED):.4f} {cover(0.5, EXACT):.4f}"),
    ("coverage at 0.02: credible, exact", f"{cover(0.02, CRED):.4f} {cover(0.02, EXACT):.4f}"),
    ("coverage at 0.002: credible, exact", f"{cover(0.002, CRED):.4f} {cover(0.002, EXACT):.4f}"),
    ("credible coverage averaged over prior", f"{prior_avg:.4f}"),
    ("mistake: MLE 0.7 in the profit ($)", f"{STAKE * (2 * 0.7 - 1):.4f}"),
    ("mistake: Beta(heads, tails), interval", f"{q(0.025, 7, 3):.4f} {q(0.975, 7, 3):.4f}"),
    ("try: 70 of 100, interval", f"{q(0.025, 71, 31):.4f} {q(0.975, 71, 31):.4f}"),
    ("try: prior Beta(2,2), mean, P(> 1/2), 95%", f"{9 / 14:.4f} {1 - cdf_sum(0.5, 9, 5):.4f} {q(0.025, 9, 5):.4f} {q(0.975, 9, 5):.4f}"),
    ("try: 99% equal-tailed", f"{q(0.005):.4f} {q(0.995):.4f}"),
]
for name, val in rows:
    print(f"{name:<42} {val}")
print("figure, density at 0, 0.05, .., 1: " + ", ".join(f"{dens(j / 20):.2f}" for j in range(21)))
print("figure, coverage credible 0.05..0.95: " + ", ".join(f"{c:.2f}" for c in cov_c))
print("figure, coverage exact 0.05..0.95: " + ", ".join(f"{c:.2f}" for c in cov_e))
assert abs(lo1 - lo2) < 1e-8 and abs(hi1 - hi2) < 1e-8          # two roads to the interval
assert abs(below_half - 29 / 256) < 1e-10                       # Simpson against the hand count
assert abs(sim_m - m) < 4 * sim_se and abs(sim_p - (1 - below_half)) < 4 * sim_p_se
assert abs(profit_heads - STAKE * (2 * m - 1)) < 1e-9           # integral against linearity
assert abs(risk[2] - (v + (mode - m) ** 2)) < 1e-9 and risk[0] < risk[1] < risk[2]
assert abs(prior_avg - 0.95) < 1e-3 and min(cov_e) >= 0.95 > min(cov_c)
print("ALL CHECKS PASS")
