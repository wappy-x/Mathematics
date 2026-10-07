# Lognormal distribution -- the check behind the card.  Standard library only.
# A share at $50 today.  Its log return over the year, X = ln(S/S0), is
# normal with centre MU = 0.08 and spread SIGMA = 0.30, so the price in a
# year is S = S0 e^X.  Roads: the closed forms; Simpson's rule on the
# density; a seeded simulation of 200,000 years; an exact enumeration of a
# 252-day coin-flip year.  Nothing imported holds the answer.
from math import exp, log, sqrt, pi

S0, MU, SIGMA, DAYS = 50.0, 0.08, 0.30, 252

def phi(z):                                  # standard normal density
    return exp(-z * z / 2) / sqrt(2 * pi)
def Phi(z):                                  # standard normal area, Taylor series
    term, total = z, z
    for n in range(1, 200):
        term *= -z * z / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)
def f(s):                                    # lognormal density of the price, per dollar
    return phi((log(s / S0) - MU) / SIGMA) / (SIGMA * s)
def simpson(g, a, b, n=40000):               # Simpson's rule, n even
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

# road 1: the closed forms
median, mean, mode = S0 * exp(MU), S0 * exp(MU + SIGMA ** 2 / 2), S0 * exp(MU - SIGMA ** 2)
var = mean ** 2 * (exp(SIGMA ** 2) - 1)
sd = sqrt(var)
p_loss = Phi((log(1.0) - MU) / SIGMA)        # chance the year ends below $50
p_below_mean = Phi(SIGMA / 2)                # chance the year ends below the mean price
print(f"model: S0 = {S0:.2f}, log return centre {MU:.2f}, spread {SIGMA:.2f}")
print(f"formula: mode {mode:.4f}, median {median:.4f}, mean {mean:.4f}")
print(f"formula: variance {var:.4f}, spread of price {sd:.4f}")
print(f"formula: P(S < 50) = {p_loss:.4f}, P(S < mean) = {p_below_mean:.4f}")
print(f"by hand: e^0.08 = {exp(MU):.4f}, e^0.125 = {exp(MU + SIGMA ** 2 / 2):.4f}, e^-0.01 = {exp(MU - SIGMA ** 2):.4f},"
      f" e^0.09 - 1 = {exp(SIGMA ** 2) - 1:.4f}, z for $50 = {-MU / SIGMA:.4f}")
print(f"by hand: sigma^2/2 = {SIGMA ** 2 / 2:.4f}, mean^2 = {mean ** 2:.2f}, mean / median = {mean / median:.4f},"
      f" mean - median = {mean - median:.4f}")
print(f"average simple return {mean / S0 - 1:.4f}; average log return {MU:.4f}")

# road 2: Simpson's rule on the density itself, no moment formula used
lo, hi = 0.01, 1200.0
area = simpson(f, lo, hi)
mean_i = simpson(lambda s: s * f(s), lo, hi)
var_i = simpson(lambda s: (s - mean_i) ** 2 * f(s), lo, hi)
p_loss_i = simpson(f, lo, S0)
p_below_mean_i = simpson(f, lo, mean)
grid = [40 + i * 0.001 for i in range(20001)]  # density peak searched on a $0.001 grid
mode_i = max(grid, key=f)
print(f"Simpson: area {area:.9f}, mean {mean_i:.4f}, spread {sqrt(var_i):.4f}")
print(f"Simpson: P(S < 50) = {p_loss_i:.4f}, P(S < mean) = {p_below_mean_i:.4f}")
print(f"grid search: density peaks at {mode_i:.3f}, height {f(mode_i):.6f} per dollar")
s2_back = log(1 + var_i / mean_i ** 2)       # going back: mean and variance give sigma^2, then mu
print(f"back from the Simpson mean and variance: sigma^2 = {s2_back:.6f}, mu = {log(mean_i / S0) - s2_back / 2:.6f}")

# road 3: simulate 200,000 years (SplitMix64, seed 20260928; Marsaglia polar)
MASK = (1 << 64) - 1
state = 20260928
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def uniform():
    return ((splitmix() >> 11) + 0.5) / 2.0 ** 53
def normal_pair():
    while True:
        u, v = 2 * uniform() - 1, 2 * uniform() - 1
        q = u * u + v * v
        if 0 < q < 1:
            k = sqrt(-2 * log(q) / q)
            return u * k, v * k

N = 200_000
prices = []
for _ in range(N // 2):
    for z in normal_pair():
        prices.append(S0 * exp(MU + SIGMA * z))
m_sim = sum(prices) / N
sd_sim = sqrt(sum((p - m_sim) ** 2 for p in prices) / (N - 1))
se_mean = sd_sim / sqrt(N)
fr_loss = sum(p < S0 for p in prices) / N
fr_mean = sum(p < mean for p in prices) / N
se_loss, se_fm = sqrt(fr_loss * (1 - fr_loss) / N), sqrt(fr_mean * (1 - fr_mean) / N)
prices.sort()
med_sim = (prices[N // 2 - 1] + prices[N // 2]) / 2
se_med = 1 / (2 * f(median) * sqrt(N))       # large-sample standard error of a median
print(f"simulated {N} years, seed 20260928; estimate (standard error)")
print(f"  mean {m_sim:.4f} ({se_mean:.4f}), spread {sd_sim:.4f}, median {med_sim:.4f} ({se_med:.4f})")
print(f"  P(S < 50) {fr_loss:.4f} ({se_loss:.4f}), P(S < mean) {fr_mean:.4f} ({se_fm:.4f})")
gaps = ((m_sim - mean) / se_mean, (med_sim - median) / se_med, (fr_loss - p_loss) / se_loss, (fr_mean - p_below_mean) / se_fm)
print("  gaps from the formulas, in standard errors: " + ", ".join(f"{g:.1f}" for g in gaps))

# road 4: a coin-flip year, enumerated exactly: each of 252 days the log price
# moves MU/252 + or - SIGMA/sqrt(252), with chance 1/2 each
a, b = MU / DAYS, SIGMA / sqrt(DAYS)
pk = 0.5 ** DAYS                              # chance of k up-days, k = 0 first
m_tree = cum = 0.0
med_tree = None
for k in range(DAYS + 1):
    s = S0 * exp(DAYS * a + (2 * k - DAYS) * b)
    m_tree += pk * s
    cum += pk
    if med_tree is None and cum >= 0.5:
        med_tree = s
    pk *= (DAYS - k) / (k + 1)
print(f"coin-flip year, daily step {b:.4f}, 253 outcomes: mean {m_tree:.4f}, median {med_tree:.4f}")

# what breaks
bare = simpson(lambda s: phi((log(s / S0) - MU) / SIGMA) / SIGMA, lo, hi)
bare_peak = max(grid, key=lambda s: phi((log(s / S0) - MU) / SIGMA))
print(f"mistake, median quoted as the mean: {median:.4f} instead of {mean:.4f}")
print(f"mistake, drop the 1/s: area {bare:.4f}; its peak sits at {bare_peak:.3f}, the median, not {mode:.4f}")
print(f"mistake, price spread as S0 sigma: {S0 * SIGMA:.4f} instead of {sd:.4f}")
print(f"mistake, price normal with the same mean and spread: P(S < 50) = {Phi((S0 - mean) / sd):.4f},"
      f" P(S < 0) = {Phi(-mean / sd):.5f}")
for lab, mu, sg in (("try: sigma = 0", MU, 0.0), ("try: sigma = 0.60", MU, 0.60), ("try: 4 years, mu = 0.32, variance 0.36", 4 * MU, 2 * SIGMA)):
    print(f"{lab}: mode {S0 * exp(mu - sg * sg):.4f}, median {S0 * exp(mu):.4f}, mean {S0 * exp(mu + sg * sg / 2):.4f}")
up, down = S0 * exp(MU + SIGMA), S0 * exp(MU - SIGMA)
print(f"a pair of years, Z = +1 and -1: e^{MU + SIGMA:.2f} and e^{MU - SIGMA:.2f}, prices {up:.4f} and {down:.4f}")
print(f"  gain over the median {up - median:.4f}, loss {median - down:.4f}, average price {(up + down) / 2:.4f}")

# figure: the price density and a normal with the same mean and spread, percent per dollar
xs = [10 * i for i in range(1, 13)]
print("figure, price $: " + ", ".join(f"{x}" for x in xs))
print("figure, lognormal: " + ", ".join(f"{100 * f(x):.2f}" for x in xs))
print("figure, same-moment normal: " + ", ".join(f"{100 * phi((x - mean) / sd) / sd:.2f}" for x in xs))

assert abs(area - 1) < 1e-8
assert abs(mean_i - mean) < 1e-6 and abs(var_i - var) < 1e-5
assert abs(p_loss_i - p_loss) < 1e-8 and abs(p_below_mean_i - p_below_mean) < 1e-8
assert abs(mode_i - mode) < 0.001
assert abs(s2_back - SIGMA ** 2) < 1e-7 and abs(log(mean_i / S0) - s2_back / 2 - MU) < 1e-7
assert abs(m_sim - mean) < 4 * se_mean and abs(med_sim - median) < 4 * se_med
assert abs(fr_loss - p_loss) < 4 * se_loss and abs(fr_mean - p_below_mean) < 4 * se_fm
assert abs(m_tree - mean) < 0.001
assert abs(bare - mean) < 1e-6 and abs(bare_peak - median) < 0.001
