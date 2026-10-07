# Stochastic processes: outcomes, paths and the law -- the check behind the card.
# Standard library only.  A gambler holds 10 chips and bets 1 chip a round on a
# fair coin for 20 rounds; at 0 chips play stops.  Three roads to the law of the
# chip count: all 2^20 evenings enumerated one by one; a round-by-round count of
# evenings per chip total; a seeded simulation (SplitMix64, seed 20260929).
from math import sqrt

START, N, SEED, RUNS, TOP = 10, 20, 20260929, 100_000, 31
M64, TOTAL = (1 << 64) - 1, 1 << N

def step(x, won):                      # the house rule: +1 or -1 chip, stop at 0
    if x == 0:
        return 0
    return x + 1 if won else x - 1

def path(omega):                       # outcome omega: bit k-1 is 1 when round k is won
    xs = [START]
    for k in range(N):
        xs.append(step(xs[-1], omega >> k & 1))
    return xs

def choose(n, k):                      # binomial coefficient, multiplied out
    c = 1
    for i in range(k):
        c = c * (n - i) // (i + 1)
    return c

state = SEED
def coin():                            # SplitMix64; the top bit is one fair coin
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (z ^ (z >> 31)) >> 63

# Road 1: every outcome.  2^20 evenings, each with chance 1/2^20.
end, at7, pair, ruined, near, distinct = [0] * TOP, [0] * TOP, 0, 0, 0, 0
for omega in range(TOTAL):
    xs = path(omega)
    end[xs[N]] += 1
    at7[xs[7]] += 1
    pair += xs[1] == 11 and xs[2] == 12
    ruined += xs[N] == 0
    near += all(abs(b - a) <= 1 for a, b in zip(xs, xs[1:]))
    distinct += xs[N] > 0 or omega >> xs.index(0) == 0   # one outcome per ruined path

# Road 2: round by round, how many of the 2^n evenings sit on each chip count.
table = [[0] * TOP for _ in range(N + 1)]
table[0][START] = 1
for n in range(N):
    for x in range(TOP):
        for won in (0, 1):
            if table[n][x]:
                table[n + 1][step(x, won)] += table[n][x]
paths_to = [0] * TOP                                  # distinct paths, not outcomes
paths_to[START] = 1
for n in range(N):
    nxt = [0] * TOP
    for x in range(TOP - 1):                          # 30 chips only at round 20
        for won in ((0, 1) if x else (0,)):           # a ruined path has one future
            nxt[step(x, won)] += paths_to[x]
    paths_to = nxt
law = [[c / (1 << n) for c in row] for n, row in enumerate(table)]
mean20 = sum(x * p for x, p in enumerate(law[N]))

# Road 3: simulate.  The five sample paths are the first five evenings.
samples, hit10, hit0, total, total2 = [], 0, 0, 0, 0
for r in range(RUNS):
    xs = [START]
    for k in range(N):
        xs.append(step(xs[-1], coin()))
    if r < 5:
        samples.append(xs)
    hit10 += xs[N] == 10
    hit0 += xs[N] == 0
    total += xs[N]
    total2 += xs[N] * xs[N]
f10, f0, m = hit10 / RUNS, hit0 / RUNS, total / RUNS
se10, se0 = sqrt(f10 * (1 - f10) / RUNS), sqrt(f0 * (1 - f0) / RUNS)
sem = sqrt((total2 / RUNS - m * m) / RUNS)

# The same one-time tables, redrawn independently every round.
reach = [0.0] * TOP
reach[START] = 1.0
for n in range(1, N + 1):
    reach = [law[n][z] * sum(reach[y] for y in (z - 1, z, z + 1) if 0 <= y < TOP)
             for z in range(TOP)]
resampled = sum(reach)
reflect = choose(N, 5) + 2 * sum(choose(N, k) for k in range(5))
plain0 = choose(N, 5)

print(f"outcomes: {TOTAL} evenings of {N} rounds, each with chance 1/{TOTAL}")
for i, xs in enumerate(samples):
    print(f"sample path {i + 1}: " + ", ".join(str(x) for x in xs))
wl = "".join("W" if b > a else "L" for a, b in zip(samples[0], samples[0][1:]))
v7 = samples[0][7]
print(f"evening 1 as wins and losses: {wl}")
print(f"its X_7 = {v7}; P(X_7 = {v7}) = {table[7][v7]}/128 = {law[7][v7]:.4f} "
      f"(enumerated: {at7[v7]} of {TOTAL} = {at7[v7] / TOTAL:.4f})")
print("law of X_4: " + ", ".join(f"{x}:{table[4][x]}/16" for x in range(TOP) if table[4][x]))
print("law of X_20, exact: " + ", ".join(f"{x}:{law[N][x]:.4f}" for x in range(0, TOP, 2)))
print(f"distinct paths: enumerated {distinct}, counted round by round {sum(paths_to)}, "
      f"from {TOTAL} outcomes")
print(f"enumerated table equals round-by-round table: {'yes' if end == table[N] else 'no'}")
print(f"mean of X_20: exact {mean20:.4f}; simulated {m:.4f} +- {sem:.4f}")
print(f"P(X_20 = 10): exact {table[N][10]} of {TOTAL} = {law[N][10]:.4f}; "
      f"simulated {f10:.4f} +- {se10:.4f}")
print(f"P(ruined by round 20): enumerated {ruined}, round-by-round {table[N][0]}, "
      f"reflection count {reflect}, of {TOTAL} = {ruined / TOTAL:.4f}; simulated {f0:.4f} +- {se0:.4f}")
print(f"P(X_1 = 11 and X_2 = 12): enumerated {pair / TOTAL:.4f}; "
      f"product of one-time tables {law[1][11]:.4f} x {law[2][12]:.4f} = {law[1][11] * law[2][12]:.4f}")
print(f"P(every round moves at most 1 chip): process {near / TOTAL:.4f}; "
      f"same tables redrawn each round {resampled:.10f}, about 1 in {1 / resampled:.0f}")
print(f"mistake, stop rule dropped: P(X_20 = 0) = {plain0 / TOTAL:.4f}, "
      f"P(X_20 < 0) = {(reflect - plain0) // 2 / TOTAL:.4f}")
print(f"mistake, five paths as the law: P(none of 5 evenings ruined) = {(1 - ruined / TOTAL) ** 5:.4f}")
assert end == table[N]                                   # enumeration against recursion
assert distinct == sum(paths_to)                         # two roads to the path count
assert ruined == reflect                                 # against the reflection count
assert abs(f10 - law[N][10]) < 4 * se10                  # simulation against exact
assert abs(m - START) < 4 * sem
assert 4 * pair == TOTAL and law[1][11] * law[2][12] == 0.125  # W W: 1 in 4, tables say 1 in 8
assert near == TOTAL and resampled < 1e-6                # tables do not fix the law
assert at7[7] * 128 == choose(7, 2) * TOTAL == table[7][7] * TOTAL  # P(X_7 = 7) = 21/128
assert abs(mean20 - START) < 1e-12                       # fair game: the exact mean stays 10
print("ALL CHECKS PASS")
