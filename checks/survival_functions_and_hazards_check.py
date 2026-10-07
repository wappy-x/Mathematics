# Survival functions and hazards -- the check behind the card.  Only math primitives.
# Patients followed from diagnosis.  Model: a hazard of 0.30, 0.20, 0.15, 0.10, 0.10
# deaths per patient-year in years 1 to 5 (0.10 after).  Roads: S = exp(-H); a product
# of survived slices that never calls exp; ten censored records fitted by the formula
# D/E and by a search over the log-likelihood; and 2,000 simulated patients, each
# living slice by slice, observed through entry, dropout and the study's close.
from math import exp, log, sqrt
RATES, W, M64 = [0.30, 0.20, 0.15, 0.10, 0.10], 0.01, (1 << 64) - 1

def h(t):                                   # hazard at age t, in years
    return RATES[min(int(t), 4)]

def H(t, rates=RATES):                      # cumulative hazard: the area under h
    return sum(r * min(max(t - j, 0.0), 1.0) for j, r in enumerate(rates)) + 0.10 * max(t - 5, 0.0)

def slices(t, d):                           # survive each slice of d years in turn
    s = 1.0
    for i in range(round(t / d)):
        s *= 1.0 - h((i + 0.5) * d) * d
    return s

class SplitMix64:                           # the same random numbers in both languages
    def __init__(self, seed):
        self.s = seed
    def uniform(self):                      # strictly between 0 and 1
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53

def yearly_rates(recs):                     # deaths / person-years inside each year
    out = []
    for j in range(5):
        d = sum(1 for y, e in recs if e == 1 and j < y <= j + 1)
        ex = sum(min(max(y - j, 0.0), 1.0) for y, _ in recs)
        out.append((d, ex))
    return out

def s_hat(fit, t):                          # survival from the fitted yearly rates
    return exp(-H(min(t, 5.0), [d / ex for d, ex in fit]))

def se_s5(fit):                             # standard error of S(5), by the delta method
    return s_hat(fit, 5) * sqrt(sum(d / ex ** 2 for d, ex in fit))

print("year  hazard  H(t)    S(t)=exp(-H)  slices of 0.0001  one-year death chance q")
for j in range(1, 6):
    print(f"{j:>4}  {RATES[j-1]:.2f}   {H(j):.4f}  {exp(-H(j)):.6f}      {slices(j, 0.0001):.6f}          {1 - exp(-RATES[j-1]):.4f}")
S5 = exp(-H(5))
print(f"hazard limit at t = 1.5: P(die within 0.001 | alive) / 0.001 = {(1 - exp(-H(1.501)) / exp(-H(1.5))) / 0.001:.6f}")
print(f"alive at 2, reaches 5: S(5)/S(2) = {S5 / exp(-H(2)):.6f}; fresh patient S(5) = {S5:.6f}")
FLAT = [0.17] * 5                           # a constant hazard with the same H(5)
print(f"constant 0.17: S(5) = {exp(-H(5, FLAT)):.6f}; alive at 2, reaches 5 = {exp(-H(5, FLAT)) / exp(-H(2, FLAT)):.6f}")
print(f"jump: 5% die on the day of surgery: 1 - 0.05 = {1 - 0.05:.4f}, exp(-0.05) = {exp(-0.05):.4f}")
print("chart, t in years " + " ".join(f"{0.5 * i:.1f}" for i in range(11)))
print("chart, true S(t)   " + " ".join(f"{exp(-H(0.5 * i)):.2f}" for i in range(11)))

# ---- ten patients, a constant hazard fitted to their records ----
TEN = [(0.4, 1), (1.0, 0), (1.3, 1), (2.1, 1), (2.5, 0), (3.0, 0), (3.6, 1), (4.2, 0), (5.0, 0), (5.0, 0)]
D, E = sum(e for _, e in TEN), sum(y for y, _ in TEN)
lam = D / E
def loglik(l):                              # each death gives log h - H(y), each censor - H(y)
    return sum(e * log(l) - l * y for y, e in TEN)
lo, hi = 0.001, 2.0                         # golden-section search for the peak
for _ in range(200):
    a, b = hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)
    lo, hi = (lo, b) if loglik(a) > loglik(b) else (a, hi)
lam_search = (lo + hi) / 2
print(f"ten patients: deaths D = {D}, person-years E = {E:.2f}")
print(f"  rate D/E = {lam:.6f} per year, se {lam / sqrt(D):.6f}; by log-likelihood search {lam_search:.6f}")
print(f"  S(5) = exp(-5 D/E) = {exp(-5 * lam):.4f} (se {exp(-5 * lam) * 5 * lam / sqrt(D):.4f}); death by 5 = {1 - exp(-5 * lam):.4f}")
known = [e for y, e in TEN if e == 1 or y >= 5]
print(f"wrong: fraction not seen to die          {1 - D / len(TEN):.4f}")
print(f"wrong: drop those censored before 5      {known.count(0) / len(known):.4f}")
print(f"wrong: censored counted as deaths        {exp(-5 * len(TEN) / E):.4f} (rate {len(TEN) / E:.4f})")
print(f"wrong: hazard x 5 years read as a chance {5 * lam:.4f}")

# ---- 2,000 simulated patients: entry over 3 years, study closes at year 6, dropouts ----
g, recs, lives = SplitMix64(2026), [], []
for _ in range(2000):
    close = 6.0 - 3.0 * g.uniform()         # follow-up until the study closes
    c = min(close, -log(g.uniform()) / 0.08)   # dropout at 0.08 per year, whichever first
    t = 99.0                                # alive past year 6
    for i in range(600):                    # live slice by slice: die with chance h * W
        if g.uniform() < h((i + 0.5) * W) * W:
            t = (i + 1) * W
            break
    lives.append(t)
    recs.append((min(t, c), 1 if t <= c else 0))
fit = yearly_rates(recs)
truth = slices(5, W)                        # the simulated patients' exact S(5)
print(f"simulation, 2000 patients, seed 2026: {sum(e for _, e in recs)} deaths seen, {sum(1 - e for _, e in recs)} censored")
for j, (d, ex) in enumerate(fit):
    print(f"  year {j + 1}: deaths {d:>3}, person-years {ex:8.2f}, rate {d / ex:.4f} (se {sqrt(d) / ex:.4f}), true {RATES[j]:.2f}")
alive = sum(1 for t in lives if t > 5) / 2000
print(f"  S(5) from censored records {s_hat(fit, 5):.4f} (se {se_s5(fit):.4f}); truth {truth:.4f}")
print(f"  every lifetime known: fraction alive at 5 = {alive:.4f} (se {sqrt(alive * (1 - alive) / 2000):.4f})")

# ---- informative dropout: half the patients about to die leave half a year before ----
inf = []
for (y, e), t in zip(recs, lives):
    leave = g.uniform() < 0.5
    inf.append((t - 0.5, 0) if e == 1 and t > 0.5 and leave else (y, e))
fit_inf = yearly_rates(inf)
print(f"  informative dropout: S(5) estimate {s_hat(fit_inf, 5):.4f} (se {se_s5(fit_inf):.4f}); truth {truth:.4f}")
print("chart, estimate    " + " ".join(f"{s_hat(fit, 0.5 * i):.2f}" for i in range(11)))
print("chart, informative " + " ".join(f"{s_hat(fit_inf, 0.5 * i):.2f}" for i in range(11)))

assert abs(slices(5, 0.0001) - S5) < 1e-4                  # slice product vs exp(-H)
assert abs(lam_search - lam) < 1e-6                         # search vs the formula D/E
assert abs((1 - exp(-H(1.501)) / exp(-H(1.5))) / 0.001 - RATES[1]) < 1e-3   # slice chance / slice vs h
assert abs(sum(ex for _, ex in yearly_rates(TEN)) - E) < 1e-9     # exposure year by year vs in one sum
assert abs(s_hat(fit, 5) - truth) < 4 * se_s5(fit)          # censored records vs truth
assert abs(alive - truth) < 4 * sqrt(truth * (1 - truth) / 2000)
assert s_hat(fit_inf, 5) - truth > 4 * se_s5(fit_inf)       # informative dropout is biased
print("ALL CHECKS PASS")
