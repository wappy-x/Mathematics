# Exponential waiting times -- the check behind the card.  Nothing is imported.
# Help desk: emails arrive at a steady 12 per hour, rate LAM = 0.2 per minute.
# Roads: the closed form exp(-LAM t); thin time slices with chance LAM*d each;
# Simpson integration of the density; and a seeded stream of emails dropped at
# random moments, whose gaps and window counts never use the exponential formula.
from math import exp, log, sqrt
LAM, M64 = 0.2, (1 << 64) - 1

def surv(t):                          # road one: chance of no email for t minutes
    return exp(-LAM * t)

def dens(t):
    return LAM * exp(-LAM * t)

def slices(t, d):                     # road two: t/d slices, chance LAM*d in each
    return (1.0 - LAM * d) ** round(t / d)

def simpson(g, a, b, n):              # road three: area under g from a to b
    w = (b - a) / n
    total = g(a) + g(b)
    for j in range(1, n):
        total += (4.0 if j % 2 == 1 else 2.0) * g(a + j * w)
    return total * w / 3.0

class SplitMix64:                     # road four: the same random numbers in both languages
    def __init__(self, seed):
        self.s = seed
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def frac_se(hits, n):                 # a simulated fraction and its standard error
    p = hits / n
    return p, sqrt(p * (1.0 - p) / n)

def mean_se(xs):
    m = sum(xs) / len(xs)
    v = sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
    return m, sqrt(v / len(xs))

print(f"rate {LAM} emails per minute = {LAM * 60:.0f} per hour")
print(f"mean wait 1/rate = {1 / LAM:.4f} min; median ln2/rate = {log(2) / LAM:.4f} min")
print(f"wait with 0.9 of waits below: -ln(0.1)/rate = {-log(0.1) / LAM:.4f} min")
print(f"P(T > 5) = {surv(5):.4f}; P(T > 10) = {surv(10):.4f}; P(T > 15) = {surv(15):.4f}")
print(f"P(T <= 1) = {1 - surv(1):.4f}; P(T <= 5) = {1 - surv(5):.4f}")
print(f"memoryless: P(T > 15 | T > 10) = {surv(15) / surv(10):.4f} = P(T > 5) = {surv(5):.4f}")
print(f"hazard f(t)/S(t) at t = 0, 5, 20: {dens(0) / surv(0):.4f}, {dens(5) / surv(5):.4f}, {dens(20) / surv(20):.4f}")
for d in (1.0, 0.1, 0.01, 0.001):
    print(f"slices of {d} min: P(no email in 10 min) = {slices(10, d):.6f}")
print(f"closed form exp(-2)                  = {surv(10):.6f}")
mass = simpson(dens, 0.0, 200.0, 20000)
mean = simpson(lambda t: t * dens(t), 0.0, 200.0, 20000)
sq = simpson(lambda t: t * t * dens(t), 0.0, 200.0, 20000)
upto10 = simpson(dens, 0.0, 10.0, 2000)
print(f"Simpson: total area {mass:.8f}; mean {mean:.8f}; E[T^2] {sq:.8f}; variance {sq - mean * mean:.8f}")
print(f"Simpson: standard deviation {sqrt(sq - mean * mean):.4f} min")
print(f"Simpson: 1 - area up to 10 min = {1 - upto10:.8f}")
poisson0 = exp(-LAM * 10)             # Poisson count with mean 2: chance of zero
pmf = [poisson0]
for k in range(1, 7):
    pmf.append(pmf[-1] * (LAM * 10) / k)
print(f"Poisson(2): P(N = 0) = {poisson0:.4f}, the same event as T > 10")

rng = SplitMix64(2026)
K, SPAN = 24000, 120000.0             # 24,000 emails at random moments in 120,000 minutes
times = sorted(SPAN * rng.uniform() for _ in range(K))
gaps = [times[0]] + [times[i] - times[i - 1] for i in range(1, K)]
m, se = mean_se(gaps)
print(f"simulated, seed 2026: {K} emails over {SPAN:.0f} minutes, {K / SPAN} per minute")
print(f"simulated: mean gap {m:.4f} (se {se:.4f})")
p10, se10 = frac_se(sum(g > 10 for g in gaps), K)
print(f"simulated: P(gap > 10) = {p10:.4f} (se {se10:.4f})")
long = [g for g in gaps if g > 10]
pc, sec = frac_se(sum(g > 15 for g in long), len(long))
rest, serest = mean_se([g - 10 for g in long])
print(f"simulated: {len(long)} gaps passed 10 min; of those, P(> 15) = {pc:.4f} (se {sec:.4f})")
print(f"simulated: mean wait still to come after 10 quiet minutes = {rest:.4f} (se {serest:.4f})")
counts = [0] * 12000                  # emails in each 10-minute window
for x in times:
    counts[int(x / 10)] += 1
hist = [sum(c == k for c in counts) / 12000 for k in range(7)]
print(f"windows: {len(counts)} of 10 minutes each")
print("window counts k:       " + " ".join(f"{k:6d}" for k in range(7)))
print("Poisson(2) percent:    " + " ".join(f"{100 * p:6.2f}" for p in pmf))
print("simulated percent:     " + " ".join(f"{100 * h:6.2f}" for h in hist))
grid = list(range(0, 21, 2))
print("figure, minutes:       " + ", ".join(str(t) for t in grid))
print("figure, exact %:       " + ", ".join(f"{100 * surv(t):.2f}" for t in grid))
print("figure, slices %:      " + ", ".join(f"{100 * slices(t, 1.0):.2f}" for t in grid))
print("figure, simulated %:   " + ", ".join(f"{100 * sum(g > t for g in gaps) / K:.2f}" for t in grid))
print(f"mistake, rate read as a 12-minute mean wait: P(T > 10) = {exp(-10 / 12):.4f}")
print(f"mistake, forgetting the condition: P(T > 15) = {surv(15):.4f}, not {surv(5):.4f}")
print(f"mistake, mean read as median: P(T <= 5) = {1 - surv(5):.4f}, not 0.5")
u, fresh = (10.0 - 7.0) / (10.0 - 5.0), (10.0 - 2.0) / 10.0     # a sender who always writes within 10 min
print(f"with memory, uniform wait up to 10 min: P(T > 7 | T > 5) = {u:.4f}, fresh P(T > 2) = {fresh:.4f}")
assert abs(mass - 1.0) < 1e-9 and abs(mean - 1 / LAM) < 1e-8     # integration vs algebra
assert abs(sq - mean * mean - 1 / LAM ** 2) < 1e-6
assert abs((1 - upto10) - poisson0) < 1e-10                      # integral vs Poisson zero term
assert abs(slices(10, 0.001) - surv(10)) < 1e-4 < abs(slices(10, 1.0) - surv(10))
assert abs(p10 - surv(10)) < 4 * se10 and abs(pc - surv(5)) < 4 * sec   # simulation vs formula
assert abs(m - 1 / LAM) < 4 * se and abs(rest - 1 / LAM) < 4 * serest
assert all(abs(hist[k] - pmf[k]) < 4 * sqrt(pmf[k] * (1 - pmf[k]) / 12000) for k in range(7))
print("ALL CHECKS PASS")
