# Bootstrap -- the check behind the card.  Standard library only.  200 insurance claims:
# how much would their median, and their mean, wobble on a fresh book of claims?
# Road 1: bootstrap by simulation.  Road 2: the same bootstrap law, exactly.  Road 3: the truth,
# from fresh books drawn from the known claim law.  Random numbers: SplitMix64, written out below.
from math import sqrt, log, exp, cos, pi, comb

N, H, B, FRESH, SEED = 200, 100, 2000, 2000, 2026092809     # H: the middle pair are draws H and H + 1
MED, SIG = 1500.0, 1.0              # claim law: log of a claim is normal, centre log 1500, spread 1
MASK, state = (1 << 64) - 1, SEED

def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

def claim():                         # Box-Muller normal draw, then exp: one claim in dollars
    u1 = ((splitmix() >> 11) + 0.5) / 2.0 ** 53
    u2 = ((splitmix() >> 11) + 0.5) / 2.0 ** 53
    return MED * exp(SIG * sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2))

def mean(xs): return sum(xs) / len(xs)

def spread(xs, d=1):                 # standard deviation with divisor len - d
    m = mean(xs)
    return sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - d))

def median(xs):
    s = sorted(xs)
    return (s[H - 1] + s[H]) / 2

def pct(vals):                       # percentile interval: the 2.5% and 97.5% points
    s = sorted(vals)
    return s[int(0.025 * len(s))], s[int(0.975 * len(s)) - 1]

# Road 2 for the median: P(resample median = (i-th + j-th smallest claim) / 2) depends on ranks only.
def tail(k, h=H):                    # P(at least h of N draws land on the k smallest claims)
    p, c, t = k / N, 1.0, 0.0
    for m in range(N + 1):
        if m >= h:
            t += c * p ** m * (1.0 - p) ** (N - m)
        c = c * (N - m) / (m + 1)
    return t
CH = comb(N, H)                      # C(200, 100): which 100 draws fall low
W = []
for i in range(1, N + 1):
    row = 0.0
    for j in range(i + 1, N + 1):    # 100th smallest draw is claim i, 101st is claim j
        w = CH * ((i / N) ** H - ((i - 1) / N) ** H) * (((N - j + 1) / N) ** H - ((N - j) / N) ** H)
        row += w
        if w > 1e-13:
            W.append((i, j, w))
    w = tail(i) - tail(i - 1) - row  # both middle draws are claim i
    if w > 1e-13:
        W.append((i, i, w))
KEPT = sum(w for _, _, w in W)
M101 = [sum(w for _, j, w in W if j == k) for k in range(N + 1)]   # law of the 101st smallest draw

def exact_median_law(s):             # exact bootstrap SE and percentile interval, sorted sample s
    pts = sorted(((s[i - 1] + s[j - 1]) / 2, w / KEPT) for i, j, w in W)
    m1 = sum(v * w for v, w in pts)
    se = sqrt(sum((v - m1) ** 2 * w for v, w in pts))
    cum, lo, hi = 0.0, None, None
    for v, w in pts:
        cum += w
        lo = v if lo is None and cum >= 0.025 else lo
        hi = v if hi is None and cum >= 0.975 else hi
    return se, lo, hi, pts

claims = [claim() for _ in range(N)]
s = sorted(claims)
xbar, med, sig_hat = mean(claims), median(claims), spread(claims, 0)
print(f"book of {N} claims, seed {SEED}: median ${med:.2f}, mean ${xbar:.2f}")
print(f"  smallest ${s[0]:.2f}, middle pair ${s[H - 1]:.2f} and ${s[H]:.2f}, largest ${s[-1]:.2f}")
print(f"  spread, divisor n: ${sig_hat:.2f}; divisor n - 1: ${spread(claims):.2f}")
bmean, bmed, bmax = [], [], []
for _ in range(B):                   # Road 1: resample 200 claims with replacement, B times
    r = [claims[splitmix() % N] for _ in range(N)]
    bmean.append(mean(r))
    bmed.append(median(r))
    bmax.append(max(r))
se_mean1, se_med1, se_mean2 = spread(bmean), spread(bmed), sig_hat / sqrt(N)
se_med2, lo2, hi2, pts = exact_median_law(s)
print(f"road 1, {B} resamples: SE of the mean ${se_mean1:.2f}, SE of the median ${se_med1:.2f}")
print(f"  simulation noise in each SE, about 1 part in {sqrt(2 * (B - 1)):.1f}; "
      f"percentile interval, mean ${pct(bmean)[0]:.2f} to ${pct(bmean)[1]:.2f}")
print(f"  percentile interval, median ${pct(bmed)[0]:.2f} to ${pct(bmed)[1]:.2f}")
print(f"road 2, exact: SE of the mean, spread / root n = ${se_mean2:.2f}; with n - 1: ${spread(claims) / sqrt(N):.2f}")
print(f"  poll, 520 of 1000 for one side: SE of the share {spread([1.0] * 520 + [0.0] * 480, 0) / sqrt(1000):.4f}; "
      f"median by rank counting: {len(W)} pairs of ranks, mass {KEPT:.12f}")
print(f"  SE of the median ${se_med2:.2f}; percentile interval ${lo2:.2f} to ${hi2:.2f}")
def bins(vw): return " ".join(f"{100 * sum(w for v, w in vw if 1100 + 100 * k <= v < 1200 + 100 * k):.2f}" for k in range(8))
print("chart, bin centre: " + " ".join(f"{1150 + 100 * k}" for k in range(8)))
print("chart, road 1 %:   " + bins([(v, 1 / B) for v in bmed]))
print("chart, road 2 %:   " + bins(pts))

fmean, fmed, fmax, fse, cov_med, cov_mean = [], [], [], [], 0, 0
TRUE_MEAN = MED * exp(SIG * SIG / 2)
for _ in range(FRESH):               # Road 3: fresh books from the claim law itself
    f = sorted(claim() for _ in range(N))
    fmean.append(mean(f))
    fmed.append((f[H - 1] + f[H]) / 2)
    fmax.append(f[-1])
    e_se, e_lo, e_hi, _ = exact_median_law(f)
    fse.append(e_se)
    cov_med += e_lo <= MED <= e_hi
    cov_mean += abs(fmean[-1] - TRUE_MEAN) <= 1.96 * spread(f, 0) / sqrt(N)
true_se_mean = TRUE_MEAN * sqrt(exp(SIG * SIG) - 1) / sqrt(N)
true_se_med = MED * SIG * sqrt(2 * pi) / (2 * sqrt(N))
c1, c2 = cov_med / FRESH, cov_mean / FRESH
print(f"road 3, {FRESH} fresh books: spread of their medians ${spread(fmed):.2f}, of their means ${spread(fmean):.2f}")
print(f"  by formula: median ${true_se_med:.2f} (large n), mean ${true_se_mean:.2f}; true mean ${TRUE_MEAN:.2f}")
print(f"  bootstrap SE of the median across the fresh books: average ${mean(fse):.2f}, spread ${spread(fse):.2f}")
print(f"  percentile interval for the median caught ${MED:.0f} in {c1:.4f} of books (SE {sqrt(c1 * (1 - c1) / FRESH):.4f})")
print(f"  mean +- 1.96 bootstrap SEs caught ${TRUE_MEAN:.2f} in {c2:.4f} of books (SE {sqrt(c2 * (1 - c2) / FRESH):.4f})")

atom = 1 - (1 - 1 / N) ** N
atom1 = sum(v == s[-1] for v in bmax) / B
print("what breaks")
print(f"  largest claim: resamples repeating the sample's largest, exact {atom:.4f}, simulated {atom1:.4f}")
print(f"  largest claim: bootstrap SE ${spread(bmax):.2f}, true spread across fresh books ${spread(fmax):.2f}")
print("  largest claim, exact %: " + " ".join(f"{100 * ((k / N) ** N - ((k - 1) / N) ** N):.2f}" for k in range(N, N - 6, -1)))
shuf = [median(sorted(claims, key=lambda _: splitmix())) for _ in range(20)]   # without replacement
print(f"  without replacement, 20 reshuffles: spread of the medians ${spread(shuf):.2f}")
print(f"  SE of the median divided again by root B: ${se_med1 / sqrt(B):.2f}")
half = claims[:H]
print(f"  100 claims each logged twice: bootstrap SE of the mean ${spread(half + half, 0) / sqrt(N):.2f}, "
      f"honest ${spread(half, 0) / sqrt(H):.2f}, ratio {sqrt(H / N):.4f}")

assert max(abs(M101[k] - tail(k, H + 1) + tail(k - 1, H + 1)) for k in range(1, N + 1)) < 1e-9, "pair formula"
assert abs(se_mean1 - se_mean2) < 4 * se_mean2 / sqrt(2 * (B - 1)), "simulated vs exact SE of the mean"
assert abs(se_med1 - se_med2) < 4 * se_med2 / sqrt(2 * (B - 1)), "simulated vs exact SE of the median"
assert abs(mean(fse) - spread(fmed)) < 4 * sqrt(spread(fse) ** 2 / FRESH + spread(fmed) ** 2 / (2 * FRESH)), "bootstrap vs truth"
assert abs(spread(fmean) - true_se_mean) < 5 * true_se_mean / sqrt(2 * FRESH), "fresh means vs the formula"
assert abs(c1 - 0.95) < 4 * sqrt(0.95 * 0.05 / FRESH), "percentile interval covers about 95%"
assert abs(atom1 - atom) < 4 * sqrt(atom * (1 - atom) / B), "largest-claim atom, simulated vs exact"
print("ALL CHECKS PASS")
