# Inverse transform sampling -- the check behind the card.  Nothing is imported
# but math.log, math.exp and math.sqrt.  Uniform draws come from SplitMix64,
# written out below with seed 20260929, so the Rust program draws the same
# numbers.  Three roads: the exact formula, a grid of evenly spaced u values
# pushed through the quantile, and a seeded simulation with standard errors.
from math import log, exp, sqrt

MASK = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed):
        self.state = seed
    def uniform(self):                     # a number in [0, 1), 53 random bits
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        z ^= z >> 31
        return (z >> 11) / 9007199254740992.0

LAM = 0.25                                 # cars per minute: one every 4 minutes
def wait(u):                               # the exponential quantile
    return -log(1.0 - u) / LAM
def cdf(t):
    return 1.0 - exp(-LAM * t)

VALUES, CHANCES = [1, 2, 3, 4], [0.50, 0.30, 0.15, 0.05]
CUMUL = [sum(CHANCES[:i + 1]) for i in range(4)]
def passengers(u):                         # first value whose running total reaches u
    for v, c in zip(VALUES, CUMUL):
        if u <= c:
            return v
    return VALUES[-1]
def passengers_uncumulated(u):             # mistake: compares u with each chance alone
    for v, p in zip(VALUES, CHANCES):
        if u <= p:
            return v
    return VALUES[-1]

def mean_se(xs):
    m = sum(xs) / len(xs)
    var = sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
    return m, sqrt(var / len(xs))

N = 100000
rng = SplitMix64(20260929)
us = [rng.uniform() for _ in range(N)]
vs = [rng.uniform() for _ in range(N)]
waits = [wait(u) for u in us]
grid = [(i + 0.5) / N for i in range(N)]   # evenly spaced u, no randomness

print(f"toll booth: rate lambda = {LAM} cars per minute, mean gap {1 / LAM:.4f} min")
print("first five draws (SplitMix64, seed 20260929):")
for u in us[:5]:
    print(f"  u = {u:.6f}  ->  wait {wait(u):.4f} min")
for u in (0.10, 0.50, 0.90, 0.99):
    print(f"hand case: u = {u:.2f}, 1 - u = {1 - u:.2f}, ln(1 - u) = {log(1 - u):.4f}, wait = {wait(u):.4f} min")

m_exact = 1 / LAM
m_grid = sum(wait(u) for u in grid) / N
m_sim, se_sim = mean_se(waits)
print(f"mean wait    exact 1/lambda {m_exact:.4f} | grid {m_grid:.4f} | sim {m_sim:.4f} (SE {se_sim:.4f})")
srt = sorted(waits)
med_sim = (srt[N // 2 - 1] + srt[N // 2]) / 2
flip_sim, flip_se = mean_se([-log(1.0 - u) / LAM for u in [1.0 - u for u in us]])
print(f"variant -ln(u) / lambda, since 1 - U is uniform too: sim mean {flip_sim:.4f} (SE {flip_se:.4f})")
print(f"distance from 1/lambda in standard errors: sim {(m_sim - 1 / LAM) / se_sim:.2f}, variant {(flip_sim - 1 / LAM) / flip_se:.2f}")
print(f"median wait  exact ln 2 / lambda {log(2) / LAM:.4f} | grid {wait(0.5):.4f} | sim {med_sim:.4f}")
p10 = exp(-10 * LAM)
p10_grid = sum(1 for u in grid if wait(u) > 10) / N
p10_sim = sum(1 for w in waits if w > 10) / N
se10 = sqrt(p10 * (1 - p10) / N)
print(f"P(T > 10)    exact e^(-10 lambda) {p10:.4f} | grid {p10_grid:.4f} | sim {p10_sim:.4f} (SE {se10:.4f})")

ts = list(range(0, 21, 2))
f_exact = [cdf(t) for t in ts]
f_sim = [sum(1 for w in waits if w <= t) / N for t in ts]
print("chart t (min): " + ", ".join(str(t) for t in ts))
print("chart exact F(t) %: " + ", ".join(f"{100 * f:.2f}" for f in f_exact))
print("chart sim F(t) %:   " + ", ".join(f"{100 * f:.2f}" for f in f_sim))
worst = max(abs(a - b) / sqrt(max(a * (1 - a), 1e-12) / N) for a, b in zip(f_exact, f_sim) if 0 < a)
print(f"largest CDF gap, in standard errors: {worst:.2f}")

print("passengers per car: values 1, 2, 3, 4; chances 0.50, 0.30, 0.15, 0.05")
print("running totals: " + ", ".join(f"{c:.2f}" for c in CUMUL))
for u in (0.30, 0.50, 0.87, 0.97):
    print(f"hand case: u = {u:.2f} -> passengers {passengers(u)}")
g_counts = [0] * 4
for u in [(i + 0.5) / 1000 for i in range(1000)]:
    g_counts[passengers(u) - 1] += 1
s_counts = [0] * 4
for v in vs:
    s_counts[passengers(v) - 1] += 1
print("grid counts over 1000 evenly spaced u: " + ", ".join(str(c) for c in g_counts))
print("exact shares %: " + ", ".join(f"{100 * p:.2f}" for p in CHANCES))
print("sim shares %: " + ", ".join(f"{100 * c / N:.2f}" for c in s_counts))
print("sim SE %:     " + ", ".join(f"{100 * sqrt(p * (1 - p) / N):.2f}" for p in CHANCES))
d_exact = sum(v * p for v, p in zip(VALUES, CHANCES))
d_sim, d_se = mean_se([passengers(v) for v in vs])
print(f"mean passengers  exact {d_exact:.4f} | grid {sum(k * c for k, c in zip(VALUES, g_counts)) / 1000:.4f} | sim {d_sim:.4f} (SE {d_se:.4f})")

wrong_rate, wr_se = mean_se([-LAM * log(1 - u) for u in us])
sq_exact = (2 - 2 * log(2)) / LAM          # integral of -ln(1 - u^2), divided by lambda
sq_grid = sum(wait(u * u) for u in grid) / N
sq_sim, sq_se = mean_se([wait(u * u) for u in us])
unc_sim, unc_se = mean_se([passengers_uncumulated(v) for v in vs])
unc_p, top = [], 0.0                       # chance each value is returned by the mistake
for p in CHANCES:
    unc_p.append(max(0.0, p - top)); top = max(top, p)
unc_p[-1] += 1 - top                       # every draw above the largest chance falls to 4
unc_exact = sum(v * q for v, q in zip(VALUES, unc_p))
print(f"mistake 1, rate used as the mean gap: mean {LAM:.4f} exact | {wrong_rate:.4f} sim (SE {wr_se:.4f})")
print(f"mistake 2, u squared fed in: mean {sq_exact:.4f} exact | {sq_grid:.4f} grid | {sq_sim:.4f} sim (SE {sq_se:.4f})")
print(f"mistake 3, chances not added up: mean {unc_exact:.4f} exact | {unc_sim:.4f} sim (SE {unc_se:.4f})")
print(f"longest possible wait from a 53-bit uniform: {wait(1 - 2.0 ** -53):.2f} min")

assert abs(m_grid - 1 / LAM) < 1e-3                         # grid of u vs the formula 1/lambda
assert abs(m_sim - 1 / LAM) < 4 * se_sim                     # simulation vs the formula
assert abs(flip_sim - 1 / LAM) < 4 * flip_se                 # the flipped input, same law
assert abs(p10_sim - p10) < 4 * se10 and worst < 4.0         # whole CDF within 4 SE
assert g_counts == [round(1000 * p) for p in CHANCES]        # grid counts vs the chances
assert all(abs(c / N - p) < 4 * sqrt(p * (1 - p) / N) for c, p in zip(s_counts, CHANCES))
assert abs(sq_sim - sq_exact) < 4 * sq_se and abs(sq_grid - sq_exact) < 1e-3
assert abs(d_sim - d_exact) < 4 * d_se and abs(unc_sim - unc_exact) < 4 * unc_se
assert abs(wrong_rate - LAM) < 4 * wr_se                     # mistake 1 lands on lambda, not 1/lambda
print("ALL CHECKS PASS")
