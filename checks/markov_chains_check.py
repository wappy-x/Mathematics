# Markov chains -- the check behind the card.  Standard library only.
# Weather, one step a day: 0 sunny, 1 cloudy, 2 rainy.  Every chance is held
# as whole tenths, so a path's weight is an exact integer over a power of 10.
# Three roads to the two-day chances: the matrix product; every path listed
# and summed; a seeded simulation (SplitMix64, seed 20260929).
from math import sqrt

P = [[6, 3, 1], [3, 4, 3], [2, 4, 4]]     # tenths: row = today, column = tomorrow
SPELL = [1, 2, 7]                         # memory weather: the row after two rainy days
START = [5, 3, 2]                         # a start law: today's forecast, in tenths
L, NAME = "SCR", ["sunny", "cloudy", "rainy"]
SEED, RUNS, DAYS, M64 = 20260929, 100_000, 300_000, (1 << 64) - 1

def dec(n, places):                       # the exact decimal n / 10^places
    s = str(n).rjust(places + 1, "0")
    return s[:-places] + "." + s[-places:]

state = SEED
def digit():                              # SplitMix64, cut down to one digit 0..9
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (z ^ (z >> 31)) % 10

def draw(row):                            # the digit falls in one entry's slice of 0..9
    d, edge = digit(), 0
    for j, w in enumerate(row):
        edge += w
        if d < edge:
            return j

def row_for(memory, yesterday, today):    # the chain ignores yesterday; memory weather does not
    return SPELL if memory and yesterday == 2 and today == 2 else P[today]

def weight(path, memory):                 # start law times one row entry per day
    w = START[path[0]]
    for k in range(1, len(path)):
        w *= row_for(memory, path[k - 2] if k > 1 else -1, path[k - 1])[path[k]]
    return w

def breaks(memory):                       # 3-day histories whose next-day chances differ from today's row
    bad = 0
    for h in [(a, b, c) for a in range(3) for b in range(3) for c in range(3)]:
        ws = [weight(h + (j,), memory) for j in range(3)]
        bad += any(10 * ws[j] != sum(ws) * P[h[2]][j] for j in range(3))
    return bad

# Road 1: the matrix product, in hundredths.
P2 = [[sum(P[i][k] * P[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
# Road 2: all 81 four-day paths from the start law, in ten-thousandths.
paths = [(a, b, c, d) for a in range(3) for b in range(3) for c in range(3) for d in range(3)]
total = sum(weight(p, False) for p in paths)
pair = [[sum(weight(p, False) for p in paths if p[0] == i and p[2] == j) for j in range(3)] for i in range(3)]
routes = [P[0][k] * P[k][2] for k in range(3)]
week = [0, 0, 1, 1, 2, 2, 0]
wk = 1
for a, b in zip(week, week[1:]):
    wk *= P[a][b]
# Road 3: simulate.  A sample fortnight, then 100000 two-day runs from sunny.
x, fortnight = 0, "S"
for _ in range(13):
    x = draw(P[x])
    fortnight += " " + L[x]
end = [0, 0, 0]
for _ in range(RUNS):
    end[draw(P[draw(P[0])])] += 1
def triples(memory):                      # one long path: count (yesterday, today, tomorrow)
    c, y, t = [[[0] * 3 for _ in range(3)] for _ in range(3)], 0, 0
    for _ in range(DAYS):
        n = draw(row_for(memory, y, t))
        c[y][t][n] += 1
        y, t = t, n
    return c
def cond(c, y, t, j):                     # frequency of j after (y, t), with its standard error
    n = sum(c[y][t])
    f = c[y][t][j] / n
    return f, sqrt(f * (1 - f) / n)
chain, mem = triples(False), triples(True)

print("states: S sunny, C cloudy, R rainy; one step is one day")
for i in range(3):
    print(f"P    row {L[i]}: " + " ".join(dec(v, 1) for v in P[i]) + f"   (row sum {dec(sum(P[i]), 1)})")
for i in range(3):
    print(f"P^2  row {L[i]}: " + " ".join(dec(v, 2) for v in P2[i]))
print("sunny to rainy in two days: " + " + ".join(f"S {L[k]} R {dec(routes[k], 2)}" for k in range(3))
      + f" = {dec(sum(routes), 2)}")
print(f"81 four-day paths from start law {' '.join(dec(v, 1) for v in START)}: weights sum to {dec(total, 4)}")
print("P(today i, day after tomorrow j) / P(today i), from the path list:")
for i in range(3):
    print(f"  from {L[i]}: " + " ".join(dec(pair[i][j] // (10 * START[i]), 2) for j in range(3)))
print(f"chain: 3-day histories whose next day differs from today's row: {breaks(False)} of 27")
print(f"week S S C C R R S from a sunny Monday: {dec(wk, 6)}, about 1 in {round(10 ** 6 / wk)}")
print(f"one sample fortnight from sunny: {fortnight}")
se = [sqrt(e / RUNS * (1 - e / RUNS) / RUNS) for e in end]
print(f"simulated day-2 law from sunny, {RUNS} runs: "
      + ", ".join(f"{NAME[j]} {end[j] / RUNS:.4f} +- {se[j]:.4f}" for j in range(3)))
print(f"chain, {DAYS}-day path, P(rainy tomorrow | cloudy today, yesterday y):")
for y in range(3):
    f, s = cond(chain, y, 1, 2)
    print(f"  y = {NAME[y]}: {f:.4f} +- {s:.4f}   (row entry {dec(P[1][2], 1)})")
print(f"memory weather, {DAYS}-day path, P(rainy tomorrow | rainy today, yesterday y):")
for y in range(3):
    f, s = cond(mem, y, 2, 2)
    print(f"  y = {NAME[y]}: {f:.4f} +- {s:.4f}   (rule {dec(row_for(True, y, 2)[2], 1)})")
print(f"memory weather: 3-day histories whose next day differs from today's row: {breaks(True)} of 27")
print(f"mistake, one-day entry for two days: {dec(P[0][2], 1)}, not {dec(P2[0][2], 2)}")
print(f"mistake, squaring the entry: {dec(P[0][2] ** 2, 2)}, not {dec(P2[0][2], 2)}")
print(f"mistake, days taken as independent: P(S then S | S) = {dec(P[0][0], 1)} x {dec(P2[0][0], 2)} = "
      f"{dec(P[0][0] * P2[0][0], 3)}, not {dec(P[0][0] * P[0][0], 2)}")
cols = [sum(P[i][j] for i in range(3)) for j in range(3)]
print("mistake, reading columns as rows: column sums " + " ".join(dec(c, 1) for c in cols))
print("figure, nodes S (85,175) C (180,85) R (275,175), radius 26")
assert all(pair[i][j] == START[i] * P2[i][j] * 10 for i in range(3) for j in range(3))
assert total == 10 ** 4 and breaks(False) == 0 and breaks(True) == 3
assert all(abs(end[j] / RUNS - P2[0][j] / 100) < 4 * se[j] for j in range(3))
assert all(abs(cond(chain, y, 1, 2)[0] - 0.3) < 4 * cond(chain, y, 1, 2)[1] for y in range(3))
f_rr, s_rr = cond(mem, 2, 2, 2)
f_sr, s_sr = cond(mem, 0, 2, 2)
assert f_rr - f_sr > 10 * (s_rr + s_sr)                  # memory shows up in the data
print("ALL CHECKS PASS")
