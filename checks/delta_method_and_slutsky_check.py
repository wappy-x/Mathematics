# Delta method and Slutsky -- the check behind the card.  Standard library only.
# A trial: 60 of 400 patients on a drug and 100 of 400 on placebo needed hospital care.
# Road 1: the delta method's standard error of the log odds ratio (Woolf's formula).
# Road 2: the exact law of the estimate, every pair of outcomes (x, y) enumerated.
# Road 3: 4,000 simulated trials, patient by patient, from a SplitMix64 generator.
from math import sqrt, log, exp, pi
A, B, C, D = 60, 340, 100, 300                  # drug: 60 yes, 340 no; placebo: 100 yes, 300 no
N = A + B                                       # patients per group, 400 in each
P1, P2 = A / N, C / N                           # the checks take the true chances to be 0.15, 0.25
SEED, R = 20260928, 4000
def Phi(z):                                     # standard normal area left of z, by series
    if abs(z) > 8:
        return 0.0 if z < 0 else 1.0
    term, total = z, z
    for k in range(1, 300):
        term *= -z * z / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2 * pi)

def quantile(q):                                # Phi^(-1)(q) by bisection
    lo, hi = -10.0, 10.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if Phi(mid) < q else (lo, mid)
    return (lo + hi) / 2
def logit(p):                                   # the log odds, g(p) = ln(p / (1 - p))
    return log(p / (1 - p))
def pmf(n, p):                                  # binomial chances of 0..n events
    out = [(1 - p) ** n]
    for k in range(n):
        out.append(out[-1] * (n - k) / (k + 1) * p / (1 - p))
    return out
Z = quantile(0.975)
THETA = logit(P1) - logit(P2)                   # the true log odds ratio
def exact(n, p1, p2, fixed=(), bins=False):     # road 2: every outcome pair of a trial
    f1, f2 = pmf(n, p1), pmf(n, p2)
    tse = sqrt(1 / (n * p1 * (1 - p1)) + 1 / (n * p2 * (1 - p2)))
    s, cf, hist = [0.0] * 9, [0.0] * len(fixed), [0.0] * 11
    for x in range(n + 1):
        for y in range(n + 1):
            w = f1[x] * f2[y]
            if x in (0, n) or y in (0, n):
                s[0] += w                       # a zero cell: no estimate, no interval
                continue
            est = log(x / (n - x)) - log(y / (n - y))
            se = sqrt(1 / x + 1 / (n - x) + 1 / y + 1 / (n - y))
            s[1] += w * est; s[2] += w * est * est
            s[3] += w * (abs(est - THETA) <= Z * se)                        # plug-in, log scale
            s[4] += w * (abs(est - THETA) <= Z * tse)                       # true spread, log scale
            s[5] += w * (abs(exp(est) - exp(THETA)) <= Z * exp(est) * se)   # plug-in, odds-ratio scale
            s[6] += w * ((est - THETA) / se) ** 2; s[7] += w * se; s[8] += w * se * se
            for i, fs in enumerate(fixed):
                cf[i] += w * (abs(est - THETA) <= Z * fs)
            if bins and abs(est - THETA) < 0.55:
                hist[int((est - THETA) * 10 + 5.5)] += w
    k = 1 - s[0]
    m, sm = s[1] / k, s[7] / k
    return dict(zero=s[0], mean=m, sd=sqrt(s[2] / k - m * m), cov=s[3], cov_true=s[4], cov_or=s[5],
                tse=tse, t_sd=sqrt(s[6] / k), se_mean=sm, se_sd=sqrt(s[8] / k - sm * sm), fixed=cf, hist=hist)

MASK, state = (1 << 64) - 1, SEED
def uniform():                                  # SplitMix64, top 53 bits as a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
odds1, odds2 = A / B, C / D
est0 = log(odds1 / odds2)
se0 = sqrt(1 / A + 1 / B + 1 / C + 1 / D)
se_p, se_one = sqrt(P1 * (1 - P1) / N + P2 * (1 - P2) / N), sqrt(1 / A + 1 / B)   # two wrong spreads
se_add = se_one + sqrt(1 / C + 1 / D)                                            # and a third
slope_num = (logit(P1 + 1e-5) - logit(P1 - 1e-5)) / 2e-5
print(f"odds: drug {odds1:.6f}, placebo {odds2:.6f}; odds ratio {exp(est0):.6f}; log odds ratio {est0:.6f}")
print(f"slope of the log odds at 0.15: 1/(p(1-p)) {1 / (P1 * (1 - P1)):.6f}; central difference {slope_num:.6f}")
print(f"drug group: one patient's spread {sqrt(P1 * (1 - P1)):.6f}; spread of p-hat {sqrt(P1 * (1 - P1) / N):.6f}; "
      f"slope x spread {slope_num * sqrt(P1 * (1 - P1) / N):.6f}; sqrt(1/60 + 1/340) {se_one:.6f}")
print(f"placebo group: spread of p-hat {sqrt(P2 * (1 - P2) / N):.6f}; slope {1 / (P2 * (1 - P2)):.6f}; "
      f"slope x spread {sqrt(P2 * (1 - P2) / N) / (P2 * (1 - P2)):.6f}")
print(f"road 1, delta method: 1/60 + 1/340 + 1/100 + 1/300 = {se0 ** 2:.6f}, standard error {se0:.6f}")
print(f"  z = Phi^(-1)(0.975) = {Z:.6f}; half-width {Z * se0:.6f}")
print(f"  95% interval, log scale {est0 - Z * se0:.6f} to {est0 + Z * se0:.6f}; "
      f"odds ratio {exp(est0 - Z * se0):.4f} to {exp(est0 + Z * se0):.4f}")
print(f"  odds-ratio scale: standard error {exp(est0) * se0:.6f}, interval "
      f"{exp(est0) - Z * exp(est0) * se0:.4f} to {exp(est0) + Z * exp(est0) * se0:.4f}")
ex = exact(N, P1, P2, fixed=(se_p, se_add, se_one), bins=True)
print(f"road 2, exact law over 401 x 401 outcomes: zero-cell chance {ex['zero']:.1e}")
print(f"  mean of the estimate {ex['mean']:.6f} (true {THETA:.6f}); spread {ex['sd']:.6f} "
      f"against the delta method's {ex['tse']:.6f}")
print(f"  coverage of the 95% interval: plug-in spread {ex['cov']:.4f}, true spread {ex['cov_true']:.4f}, "
      f"odds-ratio scale {ex['cov_or']:.4f}")
print(f"  Slutsky: plug-in standard error averages {ex['se_mean']:.6f}, varies by {ex['se_sd']:.6f}; "
      f"studentised spread {ex['t_sd']:.4f}")
print("chart 2, bin centre: " + " ".join(f"{THETA + k / 10:.2f}" for k in range(-5, 6)))
print("chart 2, exact %:    " + " ".join(f"{100 * h:.2f}" for h in ex["hist"]))
bell = [Phi((k + 0.5) / 10 / ex["tse"]) - Phi((k - 0.5) / 10 / ex["tse"]) for k in range(-5, 6)]
print("chart 2, bell %:     " + " ".join(f"{100 * b:.2f}" for b in bell))

sums, hits = [0.0, 0.0], 0
for _ in range(R):                              # a zero cell has chance 6e-29 here, so none is met
    x = sum(uniform() < P1 for _ in range(N))
    y = sum(uniform() < P2 for _ in range(N))
    est = log(x / (N - x)) - log(y / (N - y))
    se = sqrt(1 / x + 1 / (N - x) + 1 / y + 1 / (N - y))
    sums[0] += est; sums[1] += est * est
    hits += abs(est - THETA) <= Z * se
sim_m = sums[0] / R
sim_sd = sqrt((sums[1] - R * sim_m ** 2) / (R - 1))
sim_cov, sd_se = hits / R, sim_sd / sqrt(2 * (R - 1))
cov_se = sqrt(sim_cov * (1 - sim_cov) / R)
print(f"road 3, {R} simulated trials, seed {SEED}: mean {sim_m:.4f}; spread {sim_sd:.4f} (standard error {sd_se:.4f})")
print(f"  coverage {sim_cov:.4f} (standard error {cov_se:.4f})")
print("n per group, zero-cell chance, exact spread, delta spread, coverage log %, coverage odds-ratio %")
grid = (25, 50, 100, 200, 400, 800)
rows = [exact(n, P1, P2) for n in grid]
for n, r in zip(grid, rows):
    print(f"  {n:>3}  {r['zero']:.4f}  {r['sd']:.4f}  {r['tse']:.4f}  {100 * r['cov']:.2f}  {100 * r['cov_or']:.2f}")
print("chart 1, p-hat:   " + " ".join(f"{p / 100:.2f}" for p in range(9, 22)))
print("chart 1, curve:   " + " ".join(f"{logit(p / 100):.2f}" for p in range(9, 22)))
print("chart 1, tangent: " + " ".join(f"{logit(P1) + (p / 100 - P1) / (P1 * (1 - P1)):.2f}" for p in range(9, 22)))
print(f"what breaks: the right standard error is {se0:.4f} and coverage {ex['cov']:.4f}")
print(f"  no slope, spread of the risks used: {se_p:.4f}, coverage {ex['fixed'][0]:.4f}")
print(f"  standard errors added, not variances: {se_add:.4f}, coverage {ex['fixed'][1]:.4f}")
print(f"  placebo odds taken as known: {se_one:.4f}, coverage {ex['fixed'][2]:.4f}")
f = pmf(N, P2)                                  # no drug effect: both chances 0.25
m1 = m2 = 0.0
for x in range(1, N):
    for y in range(1, N):
        v = (log(x / (N - x)) - log(y / (N - y))) ** 2
        m1 += f[x] * f[y] * v; m2 += f[x] * f[y] * v * v
print(f"  no effect, squared log odds ratio: delta spread 0; exact mean {m1:.6f}, exact spread {sqrt(m2 - m1 * m1):.6f}")
assert abs(ex["sd"] - se0) < 0.005, "exact spread of the estimate vs the delta method"
assert abs(sim_sd - ex["sd"]) < 4 * sd_se, "simulated spread vs the exact law"
assert abs(sim_cov - ex["cov"]) < 4 * cov_se, "simulated coverage vs the exact law"
assert abs(ex["cov"] - 0.95) < 0.01 and abs(rows[-1]["cov"] - 0.95) < 0.01, "Slutsky: plug-in coverage near 95%"
assert abs(ex["t_sd"] - 1) < 0.03, "Slutsky: the studentised estimate has spread near 1"
assert abs(1 / (P1 * (1 - P1)) - slope_num) < 1e-6, "slope of the log odds, two ways"
assert abs(Z - 1.959964) < 1e-6, "bisection quantile vs the tabled 1.959964"
print("ALL CHECKS PASS")
