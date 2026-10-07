# Binomial: the number of successes in n independent tries -- the check behind
# the card.  Only math.sqrt is imported.  Ten coin flips: the fair coin
# (p = 0.5) and a bent coin that lands heads 60% of the time (p = 0.6).
# Four roads: the formula, weighing all 1024 head-tail strings, adding one
# flip at a time (Pascal's rule), and a seeded simulation (SplitMix64).
from math import sqrt
N, M64 = 10, 2**64 - 1

def choose(n, k):                        # C(n, k) by the multiplicative rule
    c = 1
    for j in range(1, k + 1):
        c = c * (n + 1 - j) // j
    return c

def formula(n, p):                       # road 1: C(n, k) p^k (1 - p)^(n - k)
    return [choose(n, k) * p**k * (1 - p)**(n - k) for k in range(n + 1)]

def strings(n, p):                       # road 2: weigh every string, file it by its heads
    law, count = [0.0] * (n + 1), [0] * (n + 1)
    for s in range(2**n):
        w, heads = 1.0, 0
        for i in range(n):
            if s >> i & 1:
                w, heads = w * p, heads + 1
            else:
                w = w * (1 - p)
        law[heads] += w
        count[heads] += 1
    return law, count

def one_flip_at_a_time(n, p):            # road 3: new[k] = p old[k-1] + (1-p) old[k]
    law = [1.0]
    for _ in range(n):
        old = [0.0] + law + [0.0]
        law = [p * old[k] + (1 - p) * old[k + 1] for k in range(len(law) + 1)]
    return law

state = 20260928                         # road 4: SplitMix64 with a stated seed
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 2.0**53

def simulate(p, runs):                   # runs of ten flips; tally the heads
    tally = [0] * (N + 1)
    for _ in range(runs):
        tally[sum(1 for _ in range(N) if uniform() < p)] += 1
    return tally

def moments(law):
    mean = sum(k * w for k, w in enumerate(law))
    return mean, sum(k * k * w for k, w in enumerate(law)) - mean * mean

def row(label, v, d=6):
    print(f"{label:<44}{v:>12.{d}f}")

RUNS = 100000
count = strings(N, 0.5)[1]               # the tally of strings does not depend on p
print("strings with k = 0..10 heads  " + " ".join(str(c) for c in count))
print(f"{'strings with exactly 7 heads, of 1024':<44}{count[7]:>12d}")
print(f"{'strings with 7 or more heads':<44}{sum(count[7:]):>12d}")
res = {}
for name, p in (("fair", 0.5), ("bent", 0.6)):
    f1, f2, f3 = formula(N, p), strings(N, p)[0], one_flip_at_a_time(N, p)
    tally = simulate(p, RUNS)
    mean, var = moments(f3)
    s7, s_tail = tally[7] / RUNS, sum(tally[7:]) / RUNS
    s_mean = sum(k * t for k, t in enumerate(tally)) / RUNS
    s_var = sum(k * k * t for k, t in enumerate(tally)) / RUNS - s_mean**2
    print(f"--- {name} coin, p = {p}")
    row("one string with 7 heads, p^7 (1-p)^3", p**7 * (1 - p)**3, 10)
    row("P(X = 7)  1 formula", f1[7])
    row("P(X = 7)  2 all strings", f2[7])
    row("P(X = 7)  3 one flip at a time", f3[7])
    row(f"P(X = 7)  4 simulated, {RUNS} runs", s7)
    row("          standard error", sqrt(s7 * (1 - s7) / RUNS))
    row("P(X >= 7) 1 formula", sum(f1[7:]))
    row("P(X >= 7) 3 one flip at a time", sum(f3[7:]))
    row("P(X >= 7) 4 simulated", s_tail)
    row("          standard error", sqrt(s_tail * (1 - s_tail) / RUNS))
    row("mean: n p", N * p)
    row("mean: sum of k P(X = k)", mean)
    row("mean: simulated", s_mean)
    row("          standard error", sqrt(s_var / RUNS))
    row("variance: n p (1 - p)", N * p * (1 - p))
    row("variance: sum of k^2 P(X = k) - mean^2", var)
    row("variance: simulated", s_var)
    print("chart, " + name + "  " + " ".join(f"{w:.4f}" for w in f1))
    res[name] = (p, f1, f2, f3, s7, s_tail, mean, var)

print("--- what breaks, fair coin")
row("no C(10,7): one string only", 0.5**10)
row("every count equally likely, 1/11", 1 / 11)
row("tail without 7 itself, P(X > 7)", sum(formula(N, 0.5)[8:]))
copy = [0.5] + [0.0] * 9 + [0.5]        # one flip copied ten times: all heads or none
row("one flip copied ten times: P(X = 7)", copy[7])
row("one flip copied ten times: P(X >= 7)", sum(copy[7:]))
row("one flip copied ten times: variance", moments(copy)[1])
print("--- try changing")
row("try: 20 fair flips, exactly 14 heads", formula(20, 0.5)[14])
row("try: p = 0.4, exactly 3 heads", formula(N, 0.4)[3])
row("try: 100 fair flips, 60 or more heads", sum(one_flip_at_a_time(100, 0.5)[60:]))
row("try: p = 0.7, variance", moments(one_flip_at_a_time(N, 0.7))[1])

for name, (p, f1, f2, f3, s7, s_tail, mean, var) in res.items():
    assert all(abs(a - b) < 1e-12 and abs(a - c) < 1e-12 for a, b, c in zip(f1, f2, f3)), "three exact roads"
    assert abs(mean - N * p) < 1e-12 and abs(var - N * p * (1 - p)) < 1e-12, "moments from the law vs np, np(1-p)"
    se7, se_t = sqrt(f1[7] * (1 - f1[7]) / RUNS), sqrt(sum(f1[7:]) * (1 - sum(f1[7:])) / RUNS)
    assert abs(s7 - f1[7]) < 4 * se7 and abs(s_tail - sum(f1[7:])) < 4 * se_t, "simulation within 4 SE"
assert count[7] == choose(N, 7) and sum(count[7:]) == 176, "strings counted one by one vs C(10, k)"
assert abs(moments(copy)[1] - 25.0) < 1e-12, "copied flip: variance n^2 p (1-p), not n p (1-p)"
print("ALL CHECKS PASS")
