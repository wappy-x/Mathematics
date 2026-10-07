# Samples and estimators -- the check behind the card; only math is imported.
# A poll of 1,000 voters reads 52 percent.  The checks fix the electorate's
# true share at 0.52 and ask what the rule "count the yeses, divide by n" does
# over every possible poll.  Roads: the formula, the exact law of the count,
# a seeded simulation of 2,000 polls, and every sample from a town of 25.
import math

P, N, RY, RN, POLLS, SEED = 0.52, 1000, 0.5, 0.6, 2000, 20260928   # N: poll size (n on the card)
M64 = 0xFFFFFFFFFFFFFFFF

def splitmix64(s):                          # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def uniform(s):                             # a draw in [0, 1) from 53 random bits
    s, z = splitmix64(s)
    return s, (z >> 11) * 2.0 ** -53

def laws(c, sizes):                         # exact law of the yes count, one voter at a time
    law, out = [1.0], {}
    for n in range(1, max(sizes) + 1):
        law = [(law[k] * (1 - c) if k < n else 0.0) + (law[k - 1] * c if k > 0 else 0.0)
               for k in range(n + 1)]
        if n in sizes:
            out[n] = law
    return out

def moments(law, f):                        # mean and SD of f(count) under a law
    m = 0.0
    for k, q in enumerate(law): m += q * f(k)
    v = 0.0
    for k, q in enumerate(law): v += q * (f(k) - m) * (f(k) - m)
    return m, math.sqrt(v)

def within(law, lo, hi):                    # chance the count lies in lo..hi
    t = 0.0
    for k in range(max(lo, 0), min(hi, len(law) - 1) + 1): t += law[k]
    return t

def row(label, v):
    print(f"{label:<50} {v:>10.6f}")

Q = P * RY / (P * RY + (1 - P) * RN)        # the share among voters who answer
SIZES = (100, 200, 400, 1000)
honest, biased = laws(P, SIZES), laws(Q, (N,))
share = lambda n: (lambda k: k / n)
h_mean, h_sd = moments(honest[N], share(N))
b_mean, b_sd = moments(biased[N], share(N))
l_mean, l_sd = moments(honest[N], lambda k: (k + 1) / (N + 2))
f_mean, f_sd = moments([1 - P, P], share(1))

state, hs, hs2, hin, bs, bs2 = SEED, 0.0, 0.0, 0, 0.0, 0.0   # 2,000 polls of each kind
for poll in range(POLLS):
    yes = 0
    for i in range(N):
        state, u = uniform(state)
        yes += u < P
    hs, hs2, hin = hs + yes / N, hs2 + (yes / N) * (yes / N), hin + (abs(yes - 520) <= 30)
    yes = answered = 0
    while answered < N:                     # ask until 1,000 voters have answered
        state, u = uniform(state)
        state, v = uniform(state)
        if v < (RY if u < P else RN):
            answered += 1
            yes += u < P
    bs, bs2 = bs + yes / N, bs2 + (yes / N) * (yes / N)
sim_h, sim_b = hs / POLLS, bs / POLLS
sim_hsd = math.sqrt(hs2 / POLLS - sim_h * sim_h)
sim_bsd = math.sqrt(bs2 / POLLS - sim_b * sim_b)
se_h, se_b = sim_hsd / math.sqrt(POLLS), sim_bsd / math.sqrt(POLLS)

TOWN, YES, n5 = 25, 13, 5                   # every sample of 5 from a town of 25
count = s1 = s2 = 0.0
holds0 = 0
for a in range(TOWN):
    for b in range(a + 1, TOWN):
        for c in range(b + 1, TOWN):
            for d in range(c + 1, TOWN):
                for e in range(d + 1, TOWN):
                    k = (a < YES) + (b < YES) + (c < YES) + (d < YES) + (e < YES)
                    count, s1, s2 = count + 1, s1 + k / n5, s2 + (k / n5) * (k / n5)
                    holds0 += a == 0
t_mean, t_var = s1 / count, s2 / count - (s1 / count) * (s1 / count)
fpc = (TOWN - n5) / (TOWN - 1)

row("formula: p(1 - p)", P * (1 - P))
row("formula: SD of the share, sqrt(p(1-p)/n)", math.sqrt(P * (1 - P) / N))
row("exact law: chance within 3 points of 0.52", within(honest[N], 490, 550))
row("simulated 2,000 polls: mean share", sim_h)
row("  its standard error", se_h)
row("simulated: SD of the share", sim_hsd)
row("simulated: share of polls within 3 points", hin / POLLS)
print(f"biased: answering, yes {P * RY:.3f} + no {(1 - P) * RN:.3f} = {P * RY + (1 - P) * RN:.6f}")
row("biased: yes share among answerers, formula", Q)
row("biased: bias, that minus 0.52", Q - P)
row("biased exact law: chance within 3 points of 0.52", within(biased[N], 490, 550))
row("biased simulated 2,000 polls: mean share", sim_b)
row("  its standard error", se_b)
print("chart, noise: n, SD by formula, SD by exact law (bias stays -0.0455)")
for n in (100, 200, 400, 1000, 2000, 4000, 10000):
    ex = f"{moments(honest[n], share(n))[1]:.4f}" if n in honest else "-"
    print(f"chart, {n:>5} {math.sqrt(P * (1 - P) / n):.4f} {ex:>6}")
print("rules on the same poll, exact law:              mean       bias         SD")
for name, m, sd in (("share K/n", h_mean, h_sd), ("first voter only", f_mean, f_sd),
                    ("always 0.5", 0.5, 0.0), ("(K+1)/(n+2)", l_mean, l_sd),
                    ("biased poll's share", b_mean, b_sd)):
    print(f"  {name:<40} {m:>10.6f} {m - P:>10.6f} {sd:>10.6f}")
row("clustered, 100 homes of 10: SD by formula", math.sqrt(P * (1 - P) / 100))
row("clustered: SD by exact law", moments(honest[100], share(100))[1])
row("clustered: chance within 3 points of 0.52", within(honest[100], 49, 55))
print(f"{'town of 25, 13 yes: samples of 5, counted':<50} {count:>10.0f}")
row("town: chance a given voter is in the sample", holds0 / count)
row("town: mean of the share over every sample", t_mean)
row("town: variance of the share, enumerated", t_var)
row("town: formula p(1-p)/n x (N-n)/(N-1)", P * (1 - P) / n5 * fpc)
row("town: iid formula p(1-p)/n, drawn with replacement", P * (1 - P) / n5)
row("electorate of 1,000,000: factor (N-n)/(N-1)", (10 ** 6 - N) / (10 ** 6 - 1))
print("chart, bins of one point: centre, honest poll, biased poll, in percent")
for j in range(15):
    kc = 430 + 10 * j
    print(f"chart, {kc / 1000:.2f} {100 * within(honest[N], kc - 5, kc + 4):5.2f} "
          f"{100 * within(biased[N], kc - 5, kc + 4):5.2f}")

assert all(abs(moments(honest[n], share(n))[1] - math.sqrt(P * (1 - P) / n)) < 1e-9
           for n in SIZES), "exact law vs the formula's noise"
assert abs(h_mean - P) < 1e-9, "exact law vs the formula's mean"
assert abs(b_mean - Q) < 1e-9, "biased exact law vs the answerers' share"
assert abs(sim_h - P) < 4 * se_h, "simulated honest polls centre on the truth"
assert abs(sim_b - Q) < 4 * se_b, "simulated biased polls centre on the answerers' share"
assert P - sim_b > 10 * se_b, "and far below the truth"
assert abs(sim_hsd - h_sd) < 4 * h_sd / math.sqrt(2 * POLLS), "simulated vs exact noise"
hw = within(honest[N], 490, 550)
assert abs(hin / POLLS - hw) < 4 * math.sqrt(hw * (1 - hw) / POLLS), "simulated vs exact within 3 points"
assert abs(t_mean - YES / TOWN) < 1e-12, "town: unbiased without replacement"
assert abs(t_var - P * (1 - P) / n5 * fpc) < 1e-12, "town: enumerated vs corrected formula"
assert abs(holds0 / count - n5 / TOWN) < 1e-12, "every voter equally likely to be drawn"
assert abs(l_mean - (N * P + 1) / (N + 2)) < 1e-9, "shrunk rule's mean by law vs formula"
print("ALL CHECKS PASS")
