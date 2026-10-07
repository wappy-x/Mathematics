# Aggregate claims: compound Poisson with lognormal sizes, and a Pareto fit to the large ones.
# Standard library only. Random numbers, integrals and the optimiser are written here.
from math import exp, log, sqrt, cos, sin, pi

POLICIES, RATE = 50_000, 0.05          # the motor book: 50,000 policies, 5% claim a year each
LAM = POLICIES * RATE                  # expected claims a year, lambda = 2,500
MED, SIG = 3000.0, 1.2                 # lognormal sizes: median $3,000, log-spread 1.2
M = log(MED)                           # mean of log size
U = 25_000.0                           # large-claim threshold for the Pareto fit
YEARS = 2000                           # simulated years

# ---- road 1: closed forms for the lognormal moments, then the compound Poisson formulas ----
mu = exp(M + SIG**2 / 2)               # E[X]
m2 = exp(2 * M + 2 * SIG**2)           # E[X^2]
var_x = m2 - mu**2
ES, VS = LAM * mu, LAM * m2            # E[S] = lambda E[X],  Var(S) = lambda E[X^2]
SD = sqrt(VS)

# ---- road 2: the same moments by Simpson's rule over the bell curve of log size ----
def simpson(f, a, b, n=20000):
    h = (b - a) / n
    acc = 0.0
    for k in range(1, n):
        acc += (4 if k % 2 else 2) * f(a + k * h)
    return (f(a) + f(b) + acc) * h / 3
phi = lambda z: exp(-z * z / 2) / sqrt(2 * pi)
size = lambda z: MED * exp(SIG * z)
mu_int = simpson(lambda z: size(z) * phi(z), -12, 12)
m2_int = simpson(lambda z: size(z) * size(z) * phi(z), -12, 14)
zu = (log(U) - M) / SIG                                   # threshold in bell-curve units
pu_int = simpson(phi, zu, 12)                             # P(X > u)
elog_int = simpson(lambda z: (M + SIG * z - log(U)) * phi(z), zu, 12) / pu_int
alpha_pop = 1 / elog_int                                  # what the Pareto fit tends to with endless data
big_mean_int = simpson(lambda z: size(z) * phi(z), zu, 14) / pu_int   # E[X | X > u]

# ---- road 3: simulate 2,000 years claim by claim (splitmix64, exponential gaps, Box-Muller) ----
state = 20260928
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0**-53 + 2.0**-54   # strictly inside (0, 1)
totals, counts, big_n, big_logsum, big_sum = [], [], 0, 0.0, 0.0
y1_n, y1_logsum = 0, 0.0
for year in range(YEARS):
    n, t = 0, -log(unif()) / LAM           # claim times arrive with exponential gaps
    while t <= 1.0:
        n += 1
        t += -log(unif()) / LAM
    s, k = 0.0, 0
    while k < n:                            # Box-Muller: two bell-curve draws per pair of uniforms
        r, th = sqrt(-2 * log(unif())), 2 * pi * unif()
        for z in (r * cos(th), r * sin(th)):
            if k < n:
                x = MED * exp(SIG * z)
                s += x
                k += 1
                if x > U:
                    big_n += 1; big_logsum += log(x / U); big_sum += x
                    if year == 0: y1_n += 1; y1_logsum += log(x / U)
    totals.append(s); counts.append(n)
mean_sim = sum(totals) / YEARS
sd_sim = sqrt(sum((v - mean_sim)**2 for v in totals) / (YEARS - 1))
n_mean = sum(counts) / YEARS
n_var = sum((c - n_mean)**2 for c in counts) / (YEARS - 1)

# ---- road 4: the Pareto fit, closed form against a golden-section search on the likelihood ----
alpha_hat = big_n / big_logsum                        # maximum-likelihood alpha, all simulated years
alpha_y1 = y1_n / y1_logsum                           # one year's large claims only
def loglik(a, n, ls): return n * log(a) - a * ls      # log likelihood, terms without alpha dropped
lo, hi, g = 0.1, 20.0, (sqrt(5) - 1) / 2
for _ in range(200):
    a1, a2 = hi - g * (hi - lo), lo + g * (hi - lo)
    if loglik(a1, big_n, big_logsum) > loglik(a2, big_n, big_logsum): hi = a2
    else: lo = a1
alpha_gold = (lo + hi) / 2
pu_sim = big_n / sum(counts)
pareto_big_mean = alpha_hat * U / (alpha_hat - 1)     # E[X | X > u] under the fitted Pareto
def tail_ln(x): return simpson(phi, (log(x) - M) / SIG, 14, 4000)
def tail_par(x): return pu_int * (U / x)**alpha_hat

# ---- what breaks ----
sd_no_count = sqrt(LAM * var_x)                       # dropped the count's own randomness
sd_fixed_size = sqrt(LAM) * mu                        # dropped the size's randomness
es_median = LAM * MED                                 # used the median as the mean size
sd_added = LAM * sqrt(var_x)                          # added standard deviations, not variances

rows = [
    ("claims a year, lambda", LAM), ("log centre m = ln 3000", M), ("exp(sigma^2 / 2)", exp(SIG**2 / 2)),
    ("exp(2 sigma^2)", exp(2 * SIG**2)), ("threshold in bell-curve units", zu), ("mean claim E[X], formula", mu), ("mean claim E[X], integral", mu_int),
    ("E[X^2], formula", m2), ("E[X^2], integral", m2_int), ("sd of one claim", sqrt(var_x)),
    ("E[S], formula", ES), ("sd(S), formula", SD), ("pure premium per policy", ES / POLICIES),
    ("count part of Var(S), share", LAM * mu**2 / VS), ("size part of Var(S), share", LAM * var_x / VS),
    ("individual model: variance of count", POLICIES * RATE * (1 - RATE)),
    ("sim: mean claims a year", n_mean), ("sim: variance of claims a year", n_var),
    ("E[S], simulated", mean_sim), ("sd(S), simulated", sd_sim),
    ("P(X > 25,000), integral", pu_int), ("P(X > 25,000), simulated", pu_sim),
    ("large claims a year", LAM * pu_int), ("large claims, all years", big_n), ("large claims, year 1", y1_n),
    ("alpha, closed form, all years", alpha_hat), ("alpha, golden section", alpha_gold),
    ("alpha, year 1 only", alpha_y1), ("alpha, endless data (integral)", alpha_pop),
    ("alpha standard error, all years", alpha_hat / sqrt(big_n)), ("alpha standard error, year 1", alpha_y1 / sqrt(y1_n)),
    ("E[X | X > 25,000], lognormal", big_mean_int), ("E[X | X > 25,000], Pareto", pareto_big_mean),
    ("large-claim cost a year, lognormal", LAM * pu_int * big_mean_int),
    ("large-claim cost a year, Pareto", LAM * pu_int * pareto_big_mean),
    ("break: sd without count part", sd_no_count), ("break: sd with sizes fixed", sd_fixed_size),
    ("break: E[S] from median size", es_median), ("break: sd by adding sds", sd_added),
    ("sd(S) / E[S]", SD / ES), ("try: rate 10%, sd(S) / E[S]", sqrt(2 * LAM * m2) / (2 * LAM * mu)),
    ("try: log-spread 1.0, E[S]", LAM * exp(M + 0.5)), ("try: log-spread 1.0, sd(S)", sqrt(LAM * exp(2 * M + 2))),
    ("try: threshold 50,000, alpha endless", 1 / (simpson(lambda z: (M + SIG * z - log(5e4)) * phi(z), (log(5e4) - M) / SIG, 12)
                                                   / simpson(phi, (log(5e4) - M) / SIG, 12))),
]
for label, v in rows:
    print(f"{label:<38}{v:>18.6f}")
print("tail: claims a year above x, lognormal vs fitted Pareto")
for x in (25_000, 50_000, 100_000, 200_000, 400_000):
    print(f"  x = {x:>7}   lognormal {LAM * tail_ln(x):>10.4f}   Pareto {LAM * tail_par(x):>10.4f}")
edges = [13.4e6 + 0.4e6 * i for i in range(11)]
hist = [sum(1 for v in totals if edges[i] <= v < edges[i + 1]) for i in range(10)]
print("histogram, $M from:", " ".join(f"{e / 1e6:.1f}" for e in edges[:-1]))
print("histogram, years:  ", " ".join(str(h) for h in hist), " outside:", YEARS - sum(hist))

assert abs(mu_int / mu - 1) < 1e-9                                       # integral agrees with closed form
assert abs(m2_int / m2 - 1) < 1e-9                                       # and for the second moment
assert abs(mean_sim - ES) < 4 * SD / sqrt(YEARS)                        # simulation mean within 4 standard errors
assert abs(sd_sim / SD - 1) < 0.06                                       # simulated spread within 6%
assert abs(n_var / n_mean - 1) < 0.1                                     # Poisson counts: variance equals mean
assert abs(alpha_gold - alpha_hat) < 1e-6                                # optimiser finds the closed-form maximum
assert abs(alpha_hat - alpha_pop) < 4 * alpha_hat / sqrt(big_n)          # fit lands near its endless-data value
print("ALL CHECKS PASS")
