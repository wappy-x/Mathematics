# Poisson counts -- the check behind the card.  Standard library only: math for
# exp, log and sqrt; no statistics or random module.  A help desk receives 12
# emails an hour on average.  The chance of more than 20 in one hour is reached
# by five roads: the mass summed up to 20 and subtracted from 1, the tail summed
# upward with log-factorials, a geometric bracket, the binomial with the hour cut
# into ever finer slots, and a seeded simulation.
import math

LAM, CUT, TOP = 12.0, 20, 150

def pmf_recurrence(lam, top):             # p0 = e^-lam, then p(k+1) = p(k) lam/(k+1)
    p = [math.exp(-lam)]
    for k in range(top):
        p.append(p[-1] * lam / (k + 1))
    return p

def pmf_logs(lam, k):                     # e^(-lam + k ln lam - ln k!), ln k! summed
    return math.exp(-lam + k * math.log(lam) - sum(math.log(j) for j in range(2, k + 1)))

def binom_pmf(n, p, top):                 # (1-p)^n, then times (n-k)/(k+1) p/(1-p)
    b = [(1 - p) ** n]
    for k in range(top):
        b.append(b[-1] * (n - k) / (k + 1) * p / (1 - p) if k < n else 0.0)
    return b

def phi_normal(x):                        # normal area left of x, by its Taylor series
    term, total, j = x, x, 0
    while abs(term) > 1e-17:
        j += 1
        term *= x * x / (2 * j + 1)
        total += term
    return 0.5 + math.exp(-x * x / 2) / math.sqrt(2 * math.pi) * total

def poisson_tail(lam, cut):
    return 1 - sum(pmf_recurrence(lam, cut)[: cut + 1])

M64 = (1 << 64) - 1
def splitmix(state):                      # SplitMix64: returns new state, uniform in [0,1)
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    z ^= z >> 31
    return state, (z >> 11) * 2.0 ** -53

p = pmf_recurrence(LAM, TOP)
tail_a = 1 - sum(p[: CUT + 1])                                   # road 1
tail_b = sum(pmf_logs(LAM, k) for k in range(CUT + 1, TOP))      # road 2
lo, hi = p[CUT + 1], p[CUT + 1] / (1 - LAM / (CUT + 2))         # road 3
mean = sum(k * q for k, q in enumerate(p))
var = sum(k * k * q for k, q in enumerate(p)) - mean ** 2
fall2 = sum(k * (k - 1) * q for k, q in enumerate(p))
print(f"help desk: lambda = {LAM:g} emails an hour; question: P(X > {CUT})")
print(f"p0 = e^-12 = {p[0]:.4e}; p11 = {p[11]:.6f}; p12 = {p[12]:.6f}; p20 = {p[20]:.6f}; p21 = {p[21]:.6f}")
print(f"P(X <= 20) = {1 - tail_a:.6f}")
print(f"road 1, 1 minus the sum to 20:       P(X > 20) = {tail_a:.6f}")
print(f"road 2, tail summed upward by logs:  P(X > 20) = {tail_b:.6f}")
print(f"road 3, geometric bracket:  {lo:.6f} <= P(X > 20) <= {hi:.6f}")
print(f"read back: about one hour in {1 / tail_a:.0f}, or {100 * tail_a:.2f}% of hours")
print(f"sum of all masses = {sum(p):.12f}")
print(f"mean = {mean:.9f}; E[X(X-1)] = {fall2:.9f}; variance = {var:.9f}; sd = {math.sqrt(var):.4f}")
print("figure, Poisson(12) masses k=0..30:")
for r in range(0, 31, 8):
    print("  " + ", ".join(f"{p[k]:.4f}" for k in range(r, min(r + 8, 31))))
b60 = binom_pmf(60, LAM / 60, 30)
print("figure, Binomial(60, 0.2) masses k=0..30:")
for r in range(0, 31, 8):
    print("  " + ", ".join(f"{b60[k]:.4f}" for k in range(r, min(r + 8, 31))))
gaps = []
for n in (60, 600, 3600, 36000):
    b = binom_pmf(n, LAM / n, CUT)
    t = 1 - sum(b)
    gaps.append(abs(t - tail_a))
    print(f"binomial, n = {n:>5} slots, p = {LAM / n:.6f}: P(X > 20) = {t:.6f}; gap {gaps[-1]:.2e};"
          f" n x gap = {n * gaps[-1]:.3f}; Le Cam bound 144/n = {144 / n:.4f}")
    assert gaps[-1] <= 144 / n
state, hours, total, total_sq, over = 20260928, 200000, 0, 0, 0
floor = math.exp(-LAM)
for _ in range(hours):                    # multiply uniforms until the product < e^-12
    k, prod = 0, 1.0
    while True:
        state, u = splitmix(state)
        prod *= u
        if prod < floor:
            break
        k += 1
    total, total_sq, over = total + k, total_sq + k * k, over + (k > CUT)
s_mean = total / hours
s_var = (total_sq - hours * s_mean ** 2) / (hours - 1)
s_tail = over / hours
se_tail = math.sqrt(tail_a * (1 - tail_a) / hours)
print(f"simulation, seed 20260928, {hours} hours: mean {s_mean:.4f} (se {math.sqrt(LAM / hours):.4f});"
      f" variance {s_var:.4f} (se {math.sqrt((LAM + 2 * LAM ** 2) / hours):.4f})")
print(f"simulation: P(X > 20) = {s_tail:.5f} (se {se_tail:.5f}); hours over 20: {over}")
at20 = tail_a + p[20]
z_plain, z_cc = (CUT - LAM) / math.sqrt(LAM), (CUT + 0.5 - LAM) / math.sqrt(LAM)
mix = 0.5 * poisson_tail(6.0, CUT) + 0.5 * poisson_tail(18.0, CUT)
pairs = poisson_tail(6.0, 10)
print(f"mistake, 'at least 20' for 'more than 20': P(X >= 20) = {at20:.6f}")
print(f"mistake, one email per minute at most: Binomial(60, 0.2) P(X > 20) = {1 - sum(b60[:21]):.6f};"
      f" variance {60 * 0.2 * 0.8:.1f}")
print(f"mistake, normal curve, z = {z_plain:.4f}: {1 - phi_normal(z_plain):.6f};"
      f" with the half-step, z = {z_cc:.4f}: {1 - phi_normal(z_cc):.6f}")
print(f"mistake, 12 used for a two-hour window: true P(X > 20) at lambda 24 = {poisson_tail(24.0, CUT):.6f}")
print(f"breaks, rate 6 or 18 on a coin flip (mean 12, variance 48): P(X > 20) = {mix:.6f}")
print(f"breaks, emails in pairs, 6 pairs an hour (mean 12, variance 24): P(X > 20) = {pairs:.6f}")
assert abs(tail_a - tail_b) < 1e-12                      # two sums, one tail
assert lo <= tail_a <= hi                                # bracket holds
assert abs(mean - LAM) < 1e-9 and abs(var - LAM) < 1e-9  # the theorem, by sums
assert gaps == sorted(gaps, reverse=True)                # slots finer, gap smaller
assert abs(sum(k * q for k, q in enumerate(binom_pmf(60, 0.2, 60))) - 60 * 0.2) < 1e-9
assert abs(s_tail - tail_a) < 4 * se_tail                # simulation agrees
assert abs(s_mean - LAM) < 4 * math.sqrt(LAM / hours)
assert abs(s_var - LAM) < 4 * math.sqrt((LAM + 2 * LAM ** 2) / hours)
q6, q18 = pmf_recurrence(6.0, TOP), pmf_recurrence(18.0, TOP)
mix_var = sum(k * k * (a + b) / 2 for k, (a, b) in enumerate(zip(q6, q18))) - LAM ** 2
pair_var = sum(4 * k * k * q for k, q in enumerate(q6)) - LAM ** 2
assert abs(mix_var - 48) < 1e-9                          # mixture variance 48
assert abs(pair_var - 24) < 1e-9                         # pairs variance 24
pairs_logs = sum(pmf_logs(6.0, k) for k in range(11, TOP))
assert abs(pairs - pairs_logs) < 1e-12 and mix > pairs > tail_a
print("ALL CHECKS PASS")
