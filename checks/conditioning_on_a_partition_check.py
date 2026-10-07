# Conditioning on a partition -- the check behind the card.  Standard library
# only.  Twelve months, equally likely, each with its average rainfall in mm at
# one station.  The information is a partition of the months into cells.  The
# forecast from it is built by three roads that share no arithmetic: the
# within-cell average in exact fractions, a least-squares search over every
# cell-constant forecast on a grid, and a simulation driven by a SplitMix64
# generator written out below.  The code checks finite cases exactly; the
# statements for every partition and every integrable X are the proof's.
from fractions import Fraction as Q

MONTHS = ["Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
RAIN = [20, 30, 40, 45, 60, 75, 80, 100, 90, 55, 40, 25]
P = [Q(1, 12)] * 12
PARTITIONS = [
    ("nothing known", [list(range(12))]),
    ("half-year", [[9, 10, 11, 0, 1, 2], [3, 4, 5, 6, 7, 8]]),      # cool Sep-Feb, warm Mar-Aug
    ("season", [[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]]),      # winter, spring, summer, autumn
    ("month", [[i] for i in range(12)]),
]

def integral(f, A, p):                       # E[f 1_A]: the integral of f over the set A
    return sum((p[i] * f[i] for i in A), Q(0))

def cond(x, cells, p, null_value=0):         # road one: E[X 1_B] / P(B) on every cell
    y = [None] * len(x)
    for B in cells:
        pb = sum((p[i] for i in B), Q(0))
        c = integral(x, B, p) / pb if pb > 0 else Q(null_value)
        for i in B:
            y[i] = c
    return y

def least_squares(x, cells, p):              # road two: the cell-constant forecast with least squared error
    y = [None] * len(x)
    for B in cells:
        c = min(range(0, 121), key=lambda c: sum((p[i] * (x[i] - c) ** 2 for i in B), Q(0)))
        for i in B:
            y[i] = Q(c)
    return y

def unions(cells):                           # sigma(partition): every union of whole cells
    return [sorted(i for k, B in enumerate(cells) if m >> k & 1 for i in B) for m in range(1 << len(cells))]

def dec(q):                                  # exact fraction as a whole number, or rounded to 2 places
    if q.denominator == 1:
        return str(q.numerator)
    r = (200 * q.numerator + q.denominator) // (2 * q.denominator)
    return f"{r // 100}.{r % 100:02d}"

MASK = (1 << 64) - 1
def splitmix64(state):                       # one step of SplitMix64: returns (new state, output)
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

print("month rainfall, mm: " + ", ".join(f"{m} {r}" for m, r in zip(MONTHS, RAIN)))
print(f"plain mean E[X] = {dec(integral(RAIN, range(12), P))} mm")
results = {}
for name, cells in PARTITIONS:
    y1, y2 = cond(RAIN, cells, P), least_squares(RAIN, cells, P)
    G = unions(cells)
    match = all(integral(y1, A, P) == integral(RAIN, A, P) for A in G)
    levels_in_G = all(sorted(i for i in range(12) if y1[i] == v) in G for v in set(y1))
    mse = integral([(RAIN[i] - y1[i]) ** 2 for i in range(12)], range(12), P)
    results[name] = (y1, y2, len(set(map(tuple, G))), match, levels_in_G, mse)   # distinct sets
    print(f"{name}: cells {len(cells)}, sets in sigma {len(G)}; forecast by month: " + ", ".join(dec(v) for v in y1))
    print(f"  least squares agrees: {'yes' if y1 == y2 else 'no'}; constant on cells: {'yes' if levels_in_G else 'no'}; "
          f"integrals match on all {len(G)} sets: {'yes' if match else 'no'}; mean squared error {dec(mse)}")
season = results["season"][0]
cells = PARTITIONS[2][1]
print("season cells: " + "; ".join(f"{n} P = {dec(sum(P[i] for i in B))}, E[X 1_B] = {dec(integral(RAIN, B, P))}, average {dec(season[B[0]])}"
                                   for n, B in zip(["winter", "spring", "summer", "autumn"], cells)))
print(f"average of the season forecast: {dec(integral(season, range(12), P))} mm")
mean = integral(RAIN, range(12), P)
var_y = integral([(v - mean) ** 2 for v in season], range(12), P)
print(f"spread of the season forecast E[(Y - 55)^2] = {dec(var_y)}; plus its error {dec(results['season'][5])} = {dec(var_y + results['season'][5])}")
warm = cells[1] + cells[2]
print(f"spring or summer, a set in sigma(season): E[Y 1_A] = {dec(integral(season, warm, P))}, E[X 1_A] = {dec(integral(RAIN, warm, P))}")
# road three: simulate months, average the rainfall inside each season
seed, n = 20260929, 120000
state = seed
count, total, square = [0] * 4, [0] * 4, [0] * 4
for _ in range(n):
    state, z = splitmix64(state)
    m = z % 12
    k = m // 3
    count[k] += 1
    total[k] += RAIN[m]
    square[k] += RAIN[m] ** 2
sim = [total[k] / count[k] for k in range(4)]
se = [((square[k] / count[k] - sim[k] ** 2) / count[k]) ** 0.5 for k in range(4)]
print(f"simulation, seed {seed}, {n} draws: counts {count}; season averages " + ", ".join(f"{s:.2f}" for s in sim)
      + "; standard errors " + ", ".join(f"{s:.3f}" for s in se))
# what breaks
summer = cells[2]
print(f"mistake 1, forecast taken as the number 55: on summer E[55 1_B] = {dec(integral([Q(55)] * 12, summer, P))}, "
      f"E[X 1_B] = {dec(integral(RAIN, summer, P))}")
print("mistake 2, no division by P(B): 'forecasts' " + ", ".join(dec(integral(RAIN, B, P)) for B in cells))
jul = [7]
print(f"mistake 3, matching asked on July alone, not in sigma(season): E[Y 1_A] = {dec(integral(season, jul, P))}, "
      f"E[X 1_A] = {dec(integral(RAIN, jul, P))}")
x13, p13 = RAIN + [500], P + [Q(0)]                  # a 13th outcome: a test record with probability 0
cells13 = cells + [[12]]
v0, v999 = cond(x13, cells13, p13, 0), cond(x13, cells13, p13, 999)
both = all(integral(v, A, p13) == integral(x13, A, p13) for v in (v0, v999) for A in unions(cells13))
print(f"mistake 4, a cell of probability 0 holding a {x13[12]} mm test record: versions give it {dec(v0[12])} and {dec(v999[12])}; "
      f"both match on all 32 sets: {'yes' if both else 'no'}")
partial = [sum(Q(1, 2 ** j) * 2 ** j for j in range(1, t + 1)) for t in (10, 20, 40)]
print(f"mistake 5, X = 2^n with chance 2^-n on one cell: E[X 1_B] after 10, 20, 40 terms = "
      + ", ".join(dec(s) for s in partial))
fig = lambda mm: f"{(2100 - 15 * mm) // 10}.{(2100 - 15 * mm) % 10}"   # the picture's y for a height in mm
print("figure, 1.5 units per mm, baseline y 210, bar tops: " + ", ".join(f"{m} {fig(r)}" for m, r in zip(MONTHS, RAIN))
      + "; season lines y " + ", ".join(fig(int(season[B[0]])) for B in cells) + f"; mean line y {fig(55)}")
assert all(r[0] == r[1] for r in results.values())                 # two roads to every forecast
assert all(r[3] and r[4] for r in results.values())                # the defining property on all of sigma
assert [r[2] for r in results.values()] == [2, 4, 16, 4096]
assert integral(season, range(12), P) == sum(Q(r) for r in RAIN) / 12
assert all(abs(sim[k] - float(season[3 * k])) < 4 * se[k] for k in range(4))
assert integral(season, jul, P) != integral(RAIN, jul, P)           # outside sigma, no match
assert both                                                         # versions differ only where P is 0
assert cond(x13, cells[:2] + [cells[2] + [12], cells[3]], p13)[12] == 90  # a null record leaves summer at 90
assert var_y + results["season"][5] == results["nothing known"][5]  # between plus within = total spread
assert [r[5] for r in results.values()] == [Q(1900, 3), Q(700, 3), Q(325, 3), 0]
print("ALL CHECKS PASS")
