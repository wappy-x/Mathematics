# Conditional probability -- the check behind the card.  Only math.sqrt is
# imported.  A screening test: 1% of people have the disease, the test flags
# 90% of those who have it and 5% of those who do not.  Three roads to the
# chance of disease given a positive result: the formula, a town of 10,000
# people counted one by one, and a seeded simulation of 1,000,000 people.
from math import sqrt

PREV, SENS, FPOS = 0.01, 0.90, 0.05      # P(D), P(T | D), P(T | not D)
TOWN, SIMS, SEED = 10_000, 1_000_000, 20260928
MASK = (1 << 64) - 1

def by_formula(prev, sens, fpos):
    both = prev * sens                    # multiplication rule: P(D and T)
    pos = both + (1 - prev) * fpos        # total probability: P(T)
    return both, pos, both / pos          # the definition: P(D | T)

def gcd(a, b):                            # Euclid, written out
    while b:
        a, b = b, a % b
    return a

class SplitMix64:                         # the same random numbers in Python and Rust
    def __init__(self, seed):
        self.s = seed
    def uniform(self):                    # a number in [0, 1) from 53 random bits
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def row(label, value):
    print(f"  {label:<40} {value}")

# ---- road 1: the formula ----
both, pos, answer = by_formula(PREV, SENS, FPOS)
print(f"inputs: P(D) = {PREV:.6f}, P(T | D) = {SENS:.6f}, P(T | not D) = {FPOS:.6f}")
print("road 1, the formula")
row("P(D and T) = P(D) P(T | D)", f"{both:.6f}")
row("P(not D and T) = P(not D) P(T | not D)", f"{(1 - PREV) * FPOS:.6f}")
row("P(T), by total probability", f"{pos:.6f}")
row("P(D | T) = P(D and T) / P(T)", f"{answer:.6f}")
row("P(not D | T) = 1 - P(D | T)", f"{1 - answer:.6f}")

# ---- road 2: a town of 10,000 people, listed and counted ----
sick_n, sick_pos_n = round(TOWN * PREV), round(TOWN * PREV * SENS)
well_pos_n = round(TOWN * (1 - PREV) * FPOS)
people = []                               # (has the disease, tests positive)
for i in range(TOWN):
    if i < sick_n:
        people.append((True, i < sick_pos_n))
    else:
        people.append((False, i - sick_n < well_pos_n))
sick = sum(1 for d, t in people if d)
sick_pos = sum(1 for d, t in people if d and t)
well_pos = sum(1 for d, t in people if not d and t)
positives = [d for d, t in people if t]   # keep only the people who tested positive
g = gcd(sick_pos, len(positives))
print(f"road 2, a town of {TOWN} people counted one by one")
row("have the disease", sick)
row("  and test positive", sick_pos)
row("  and test negative", sick - sick_pos)
row("do not have it", TOWN - sick)
row("  and test positive", well_pos)
row("  and test negative", TOWN - sick - well_pos)
row("test positive in all", len(positives))
row(f"P(D | T) = {sick_pos} / {len(positives)} = {sick_pos // g} / {len(positives) // g}",
    f"{sum(positives) / len(positives):.6f}")
row(f"P(not D | T) = {well_pos} / {len(positives)}", f"{well_pos / len(positives):.6f}")

# ---- road 3: simulate 1,000,000 people ----
rng = SplitMix64(SEED)
s_pos = s_both = 0
for _ in range(SIMS):
    d = rng.uniform() < PREV
    t = rng.uniform() < (SENS if d else FPOS)
    s_pos += t
    s_both += d and t
est_pos, est_ans = s_pos / SIMS, s_both / s_pos
se_pos = sqrt(est_pos * (1 - est_pos) / SIMS)       # standard error of each estimate
se_ans = sqrt(est_ans * (1 - est_ans) / s_pos)
miss_pos, miss_ans = abs(est_pos - pos) / se_pos, abs(est_ans - answer) / se_ans
print(f"road 3, a simulation of {SIMS} people, SplitMix64 seed {SEED}")
row("tested positive", s_pos)
row("  of whom have the disease", s_both)
row("P(T) estimate", f"{est_pos:.6f}  standard error {se_pos:.6f}")
row("P(D | T) estimate", f"{est_ans:.6f}  standard error {se_ans:.6f}")
row("misses, in standard errors", f"{miss_pos:.2f} and {miss_ans:.2f}")

# ---- what breaks ----
print("what breaks (right answer P(D | T) = %.6f)" % answer)
row("swap the condition: P(T | D)", f"{SENS:.6f}")
row("divide by everyone: P(D and T)", f"{both:.6f}")
row("equal weights: P(T) = (0.90 + 0.05) / 2", f"{(SENS + FPOS) / 2:.6f}")
row("  so P(D | T) comes out at", f"{both / ((SENS + FPOS) / 2):.6f}")
row("drop the healthy branch: P(T)", f"{both:.6f}")
row("  so P(D | T) comes out at", f"{both / both:.6f}")
row("multiply as if independent: P(D) P(T)", f"{PREV * pos:.6f}")
print("try: one input moved, P(D | T) by the formula")
row("false-alarm rate 5% -> 1%", f"{by_formula(PREV, SENS, 0.01)[2]:.6f}")
row("hit rate 90% -> 99%", f"{by_formula(PREV, 0.99, FPOS)[2]:.6f}")

# ---- the chart: P(D | T) as the disease gets commoner, formula against count ----
print("P(D | T) in percent as prevalence changes, formula and count of 100000")
sweep = [("0.1", 0.001, 100), ("0.5", 0.005, 500), ("1", 0.01, 1000), ("2", 0.02, 2000),
         ("5", 0.05, 5000), ("10", 0.10, 10000), ("20", 0.20, 20000), ("50", 0.50, 50000)]
worst = 0.0
for name, prev, sick_k in sweep:
    f = 100 * by_formula(prev, SENS, FPOS)[2]
    sp, wp = sick_k * 9 // 10, (100000 - sick_k) // 20   # integer counts: 90% and 5%
    c = 100 * sp / (sp + wp)
    worst = max(worst, abs(f - c))
    row(f"prevalence {name}%", f"{f:6.2f}  {c:6.2f}")

assert abs(answer - sick_pos / len(positives)) < 1e-12           # formula = count
assert abs(pos - len(positives) / TOWN) < 1e-12                   # total probability = count
assert abs((1 - answer) - well_pos / len(positives)) < 1e-12      # complement rule inside T
assert miss_pos < 4 and miss_ans < 4                              # simulation within 4 SE
assert worst < 1e-9                                               # sweep: formula = count
print("ALL CHECKS PASS")
