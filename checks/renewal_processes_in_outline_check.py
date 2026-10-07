# Renewal processes in outline -- the check behind the card.  Standard library
# only.  Buses leave a stop with gaps of 5 or 15 minutes, each with chance 0.5,
# the gaps independent.  Three roads: the formulas; an exact recursion over
# every bus pattern (in steps of 5 minutes, since every gap is a multiple of 5);
# and seeded simulations, each printed with its standard error.
from math import log, sqrt
MASK, SEED = (1 << 64) - 1, 20260929
GAPS, P = (5, 15), (0.5, 0.5)                 # minutes, and their chances

state = SEED
def unif():                                   # SplitMix64 -> a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
def bus_gap(): return 5.0 if unif() < 0.5 else 15.0
def exp_gap(): return -15.0 * log(1.0 - unif())   # house example: 4 calls an hour

# ---- road 1: the formulas ----
mu = sum(p * x for p, x in zip(P, GAPS))
ex2 = sum(p * x * x for p, x in zip(P, GAPS))
var = ex2 - mu * mu
wait = ex2 / (2 * mu)
long_share = P[1] * GAPS[1] / mu              # length-biased chance of a 15-minute gap
print(f"formula,mean gap mu,{mu:.6f}")
print(f"formula,mean square gap E[X^2],{ex2:.6f}")
print(f"formula,variance of gap,{var:.6f}")
print(f"formula,rate 1/mu per minute,{1 / mu:.6f}")
print(f"formula,rate per hour,{60 / mu:.6f}")
print(f"formula,mean wait E[X^2]/(2 mu),{wait:.6f}")
print(f"formula,mu/2 + var/(2 mu),{mu / 2 + var / (2 * mu):.6f}")
print(f"formula,share of time in 15-min gaps,{long_share:.6f}")
print(f"formula,mean gap a passenger lands in,{ex2 / mu:.6f}")
print(f"hand,share of time in 5-min gaps,{P[0] * GAPS[0] / mu:.6f}")
print(f"hand,mean wait inside a 5-min / 15-min gap,{GAPS[0] / 2:.6f} {GAPS[1] / 2:.6f}")
print(f"hand,extra wait var/(2 mu),{var / (2 * mu):.6f}")
print(f"hand,sandwich at t=60 lower upper,{60 / mu - 1:.6f} {75 / mu - 1:.6f}")
print(f"formula,wait at a 5-minute mark,{5 * sum(p * (x // 5) * (x // 5 - 1) / 2 for p, x in zip(P, GAPS)) / (mu / 5):.6f}")

# ---- road 2: exact recursion, step = 5 minutes, gaps of 1 or 3 steps ----
K = 1200                                      # 6000 minutes
steps = [(x // 5, p) for x, p in zip(GAPS, P)]
m = [0.0] * (K + 2)                           # m[k] = E[N(5k)], buses after time 0 up to 5k
D = [0.0] * (K + 2)                           # D[k] = E[first bus at or after 5k] - 5k, in steps
u = [1.0] + [0.0] * (K + 1)                   # u[k] = chance a bus leaves at exactly 5k
for k in range(1, K + 2):
    m[k] = sum(p * (1 + m[k - s]) for s, p in steps if s <= k)
    D[k] = sum(p * (s - k if s >= k else D[k - s]) for s, p in steps)
    u[k] = sum(p * u[k - s] for s, p in steps if s <= k)
# brute force: all 2**12 patterns of 12 gaps (bit i set: gap i + 1 is 3 steps), buses by step 12, whole numbers
A12 = sum(sum(1 for n in range(1, 13) if sum(1 + 2 * ((b >> i) & 1) for i in range(n)) <= 12) for b in range(4096))
print(f"exact,E[N(60)] by brute force over all 4096 patterns of 12 gaps,{A12}/4096")
print(f"exact,E[N(60)],{m[12]:.6f}")
ok_bounds = all(5 * k / mu - 1 < m[k] <= (5 * k + 15) / mu - 1 for k in range(1, K + 1))
for t in (15, 30, 60, 120, 240, 480, 6000):
    print(f"exact,buses per hour m(t)/t*60 at t={t},{60 * m[t // 5] / t:.6f}")
print("chart,m(t)/t*60 at t=15 30 60 120 240 480," + " ".join(f"{60 * m[t // 5] / t:.2f}" for t in (15, 30, 60, 120, 240, 480)))
wald_l, wald_r = (mu / 5) * (m[K] + 1), K + 1 + D[K + 1]
print(f"exact,Wald mu*(m(t)+1) at t=6000 (steps),{wald_l:.6f}")
print(f"exact,E[time of first bus after t] (steps),{wald_r:.6f}")
for T in (60, 600, 6000):
    k = T // 5
    print(f"exact,mean wait over arrivals in [0 {T}),{5 * sum(D[j + 1] + 0.5 for j in range(k)) / k:.6f}")
ex_share = sum(0.5 * sum(u[i] for i in (j - 2, j - 1, j) if i >= 0) for j in range(120)) / 120
print(f"exact,share of [0 600) in 15-min gaps,{ex_share:.6f}")
print(f"exact,wait arriving exactly at t=6000,{5 * D[K]:.6f}")
print(f"exact,wait arriving at t=6000.001,{5 * D[K + 1] + 5 - 0.001:.6f}")

# ---- road 3: seeded simulation ----
def passengers(n, gap, horizon):              # each passenger gets a fresh bus run
    w = w2 = hit = 0.0
    for _ in range(n):
        s, b = horizon * unif(), 0.0
        while b < s: a, b = b, b + gap()
        w += b - s; w2 += (b - s) ** 2; hit += (b - a) > 10
    mean = w / n
    return mean, sqrt((w2 / n - mean * mean) / (n - 1)), hit / n
NP = 40000
sw, sse, sh = passengers(NP, bus_gap, 600.0)
print(f"sim,mean wait arriving in [0 600),{sw:.6f}")
print(f"sim,standard error,{sse:.6f}")
print(f"sim,share landing in a 15-min gap,{sh:.6f}")
print(f"sim,standard error of share,{sqrt(sh * (1 - sh) / NP):.6f}")
pw, pse, _ = passengers(NP, exp_gap, 600.0)
print(f"sim,house example wait (4 calls/hour),{pw:.6f}")
print(f"sim,house standard error,{pse:.6f}")
print(f"formula,house example wait E[X^2]/(2 mu),{2 * 15.0 ** 2 / (2 * 15.0):.6f}")
b, cnt, batches = 0.0, [0] * 100, 10000.0     # one long run, counted in 100 batches
while True:
    b += bus_gap()
    if b >= 100 * batches: break
    cnt[int(b // batches)] += 1
rates = [60 * c / batches for c in cnt]
rm = sum(rates) / 100
rse = sqrt(sum((r - rm) ** 2 for r in rates) / 99 / 100)
print(f"sim,buses per hour over 1000000 min,{rm:.6f}")
print(f"sim,standard error of rate,{rse:.6f}")

# ---- what breaks ----
print(f"breaks,half the mean gap,{mu / 2:.6f}")
print(f"breaks,mean gap counted per bus,{mu:.6f}")
dep = 0.5 * (6000 // 5) / 6000 * 60 + 0.5 * (6000 // 15) / 6000 * 60
print(f"breaks,every gap = the first gap: buses per hour at t=6000,{dep:.6f}")

for name, g, q in (("even 10 min", (10, 10), (0.5, 0.5)), ("short 0.75", (5, 15), (0.75, 0.25)), ("1 or 19", (1, 19), (0.5, 0.5))):
    m1, m2 = q[0] * g[0] + q[1] * g[1], q[0] * g[0] ** 2 + q[1] * g[1] ** 2
    print(f"try,{name}: mean gap / per hour / wait / half gap,{m1:.6f} {60 / m1:.6f} {m2 / (2 * m1):.6f} {m1 / 2:.6f}")

# ---- figure: the sawtooth over one hour, gaps 5 15 5 5 15 15 ----
fig, x = [], 0
for g in (5, 15, 5, 5, 15, 15):
    fig.append(f"{40 + 5 * x}:{190 - 10 * g}"); x += g
area = sum(g * g / 2 for g in (5, 15, 5, 5, 15, 15))
print("figure,tooth start x:top y," + " ".join(fig) + f",end x {40 + 5 * x},mean line y {190 - 10 * area / 60}")
print(f"figure,tooth areas small large,{5 * 5 / 2:.6f} {15 * 15 / 2:.6f}")
print(f"figure,sawtooth area / 60,{area / 60:.6f}")

assert ok_bounds, "sandwich t/mu - 1 < m(t) <= (t + 15)/mu - 1 failed"
assert abs(60 * m[K] / 6000 - 60 / mu) < 60 * 1.5 / 6000, "elementary renewal theorem"
assert abs(wald_l - wald_r) < 1e-9, "Wald's identity: two recursions disagree"
assert A12 == m[12] * 4096, "brute force over every gap pattern vs recursion"
assert abs(5 * D[K] - 5 * sum(p * (x // 5) * (x // 5 - 1) / 2 for p, x in zip(P, GAPS)) / (mu / 5)) < 1e-6, "wait at a 5-minute mark: exact vs formula"
assert abs(5 * sum(D[j + 1] + 0.5 for j in range(K)) / K - wait) < 0.01, "exact wait vs formula"
assert abs(sw - 5 * sum(D[j + 1] + 0.5 for j in range(120)) / 120) < 4 * sse, "sim wait vs exact"
assert abs(sh - ex_share) < 4 * sqrt(sh * (1 - sh) / NP), "length bias: sim vs exact"
assert abs(sum(0.5 * sum(u[i] for i in (j - 2, j - 1, j) if i >= 0) for j in range(K)) / K - long_share) < 0.01, "length bias: exact vs formula"
assert abs(pw - 15.0) < 4 * pse, "Poisson wait is the full mean gap"
assert abs(rm - 60 / mu) < 4 * rse, "simulated rate"
print("all checks passed")
