# Standard error -- the check behind the card; only math is imported.
# A poll of 1,000 voters: 520 answer yes (1) and 480 no (0).  Roads: the
# formulas; every possible answer list of a small poll, enumerated exactly;
# and 1,000 seeded polls from an electorate whose true yes share is 0.52.
import math

P, N, YES, POLLS, SEED = 0.52, 1000, 520, 1000, 20260928
PREFIX = (10, 25, 100, 250, 1000)          # poll sizes read off each simulated poll
HOMES, SIZE = 100, 10                       # the clustered poll: 100 homes of 10 alike
M64 = 0xFFFFFFFFFFFFFFFF
SIG2 = P * (1 - P)                          # one answer's variance, p(1 - p)

def splitmix64(s):                          # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def uniform(s):                             # a draw in [0, 1) from 53 random bits
    s, z = splitmix64(s)
    return s, (z >> 11) * 2.0 ** -53

def summaries(xs):                          # the mean, and squared deviations from it
    t = 0.0
    for x in xs:
        t += x
    m, q = t / len(xs), 0.0
    for x in xs:
        q += (x - m) * (x - m)
    return m, q

def exact(values, probs, n):                # expectations over every answer list
    em = em2 = es2 = ev = es = 0.0
    for code in range(len(values) ** n):
        xs, w, c = [], 1.0, code
        for _ in range(n):
            xs.append(values[c % len(values)])
            w *= probs[c % len(values)]
            c //= len(values)
        m, q = summaries(xs)
        em, em2 = em + w * m, em2 + w * m * m
        es2, ev, es = es2 + w * q / (n - 1), ev + w * q / n, es + w * math.sqrt(q / (n - 1))
    return em, em2 - em * em, es2, ev, es

def row(label, v):
    print(f"{label:<50} {v:>11.6f}")

m, q = summaries([1.0] * YES + [0.0] * (N - YES))   # road 1: the poll's own data
s2 = q / (N - 1)
se_hat = math.sqrt(s2) / math.sqrt(N)
row("one answer: variance p(1 - p)", SIG2)
row("one answer: SD, sqrt(p(1 - p))", math.sqrt(SIG2))
row("formula: SE of the average, sqrt(p(1-p)/n)", math.sqrt(SIG2 / N))
row("poll data: average of the 1,000 answers", m)
print(f"poll data: 520 x {(1 - m) * (1 - m):.4f} = {YES * (1 - m) * (1 - m):.3f}; "
      f"480 x {m * m:.4f} = {(N - YES) * m * m:.3f}; sqrt(1000) = {math.sqrt(N):.4f}")
row("poll data: sum of squared deviations", q)
row("poll data: S^2, that sum over n - 1 = 999", s2)
row("poll data: s, its square root", math.sqrt(s2))
row("poll data: estimated SE, s / sqrt(1000)", se_hat)
row("poll data: plug-in SE, sqrt(0.52 x 0.48 / 1000)", math.sqrt(m * (1 - m) / N))
row("poll data: 95% margin, 1.96 x estimated SE", 1.96 * se_hat)

print("exact, n  E[mean]  Var(mean)  p(1-p)/n  E[S^2]  E[V]    E[S]    as % of p(1-p): S^2, V")
EX = {}
for n in range(2, 9):                       # road 2: every answer list, 2^n of them
    EX[n] = exact([0.0, 1.0], [1 - P, P], n)
    em, vm, es2, ev, es = EX[n]
    print(f"exact, {n}  {em:.4f}  {vm:.6f}  {SIG2 / n:.6f}  {es2:.4f}  {ev:.4f}  {es:.4f}  {100 * es2 / SIG2:6.2f} {100 * ev / SIG2:6.2f}")
mix = 2 * P * (1 - P)                       # a poll of 2: one yes and one no
print(f"exact, n = 2: chance of a mixed pair {mix:.4f}; its S^2 0.5000, V 0.2500, S {math.sqrt(0.5):.4f}")
T = exact([1.0, 2.0, 3.0], [0.25, 0.5, 0.25], 4)   # a three-answer question, n = 4
print(f"exact, answers 1/2/3 at 0.25/0.5/0.25, n = 4: E[S^2] {T[2]:.4f}, E[V] {T[3]:.4f}")

state, acc = SEED, {n: [0.0, 0.0] for n in PREFIX}  # road 3: 1,000 seeded polls
s2_2 = s2_2sq = v_2 = se_sum = 0.0
inside = 0
for _ in range(POLLS):
    t, xs = 0.0, []
    for i in range(1, N + 1):
        state, u = uniform(state)
        x = 1.0 if u < P else 0.0
        xs.append(x)
        t += x
        if i in acc:
            acc[i][0] += t / i
            acc[i][1] += (t / i) * (t / i)
    a, q2 = summaries(xs[:2])               # the first two voters as a poll of 2
    s2_2, s2_2sq, v_2 = s2_2 + q2, s2_2sq + q2 * q2, v_2 + q2 / 2
    a, qq = summaries(xs)
    se_sum += math.sqrt(qq / (N - 1)) / math.sqrt(N)
    inside += abs(a - P) <= math.sqrt(SIG2 / N)
sd_sim = {}
print("chart, n, SE by formula, SD of 1,000 simulated averages and its SE, in points")
for n in PREFIX:
    mu = acc[n][0] / POLLS
    sd_sim[n] = math.sqrt(acc[n][1] / POLLS - mu * mu)
    print(f"chart, {n:>4} {100 * math.sqrt(SIG2 / n):6.2f} {100 * sd_sim[n]:6.2f} {100 * sd_sim[n] / math.sqrt(2 * POLLS):6.3f}")
mean_s2 = s2_2 / POLLS
se_s2 = math.sqrt(s2_2sq / POLLS - mean_s2 * mean_s2) / math.sqrt(POLLS)
row("sim, polls of 2: average S^2", mean_s2)
row("sim, polls of 2: its standard error", se_s2)
row("sim, polls of 2: average V, over n", v_2 / POLLS)
row("sim, polls of 1,000: average estimated SE", se_sum / POLLS)
row("sim, polls of 1,000: share within one SE of 0.52", inside / POLLS)
row("sim, polls of 1,000: that share's standard error", math.sqrt(inside / POLLS * (1 - inside / POLLS) / POLLS))

cs = cs2 = cse = 0.0                        # clustered: whole homes answer alike
for _ in range(POLLS):
    xs = []
    for h in range(HOMES):
        state, u = uniform(state)
        xs += [1.0 if u < P else 0.0] * SIZE
    a, qq = summaries(xs)
    cs, cs2, cse = cs + a, cs2 + a * a, cse + math.sqrt(qq / (N - 1)) / math.sqrt(N)
sd_cl = math.sqrt(cs2 / POLLS - (cs / POLLS) * (cs / POLLS))
row("clustered: SD of the averages, simulated", sd_cl)
row("clustered: formula for 100 answers", math.sqrt(SIG2 / HOMES))
row("clustered: average estimated SE, s / sqrt(1000)", cse / POLLS)

for n in EX:                                # enumerated against the proved formulas
    assert abs(EX[n][1] - SIG2 / n) < 1e-12 and abs(EX[n][0] - P) < 1e-12, n
    assert abs(EX[n][2] - SIG2) < 1e-12 and abs(EX[n][3] - SIG2 * (n - 1) / n) < 1e-12, n
assert abs(T[2] - 0.5) < 1e-12 and abs(T[3] - 0.375) < 1e-12, "three-answer law"
assert abs(EX[2][4] - mix * math.sqrt(0.5)) < 1e-12 and abs(EX[2][2] - mix * 0.5) < 1e-12, "n = 2 by hand"
assert abs(s2 - m * (1 - m) * N / (N - 1)) < 1e-12, "data loop vs closed form"
for n in PREFIX:                            # simulated spread within 4 standard errors
    assert abs(sd_sim[n] - math.sqrt(SIG2 / n)) < 4 * math.sqrt(SIG2 / n / (2 * POLLS)), n
assert abs(acc[N][0] / POLLS - P) < 4 * math.sqrt(SIG2 / N / POLLS), "averages centre on p"
assert abs(mean_s2 - SIG2) < 4 * se_s2 and SIG2 - v_2 / POLLS > 5 * se_s2, "n - 1"
assert abs(sd_cl - math.sqrt(SIG2 / 100)) < 4 * math.sqrt(SIG2 / 100 / (2 * POLLS)), "cluster"
assert sd_cl > 2.5 * cse / POLLS, "the estimated SE misses the clustering"
print("ALL CHECKS PASS")
