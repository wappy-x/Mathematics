# Measures -- the check behind the card.  Standard library only; fractions keeps
# the shares exact.  A city of three districts, N, C and S.  Every set of
# districts gets a size under several rules.  Road one adds the pieces'
# weights; road two measures each union directly (a 0.1 km grid, a random
# sample of residents, the town hall's position); road three checks
# additivity on every pair of disjoint sets, for rules that pass and fail.
from fractions import Fraction

NAMES = ["N", "C", "S"]
PEOPLE = [40000, 25000, 10000]          # residents per district
AREA = [12, 5, 8]                       # square km per district
EDGE = [0, 48, 68, 100]                 # district edges along the strip, in 0.1 km
HALL = 58                               # town hall at 5.8 km, inside C
TOTAL = sum(PEOPLE)
INF = float("inf")

def label(m):
    return ",".join(NAMES[i] for i in range(3) if m >> i & 1) or "empty"

def weighted(w):                        # road one: add the weights of the points
    return lambda m: sum(w[i] for i in range(3) if m >> i & 1)

rules = {
    "districts": weighted([1, 1, 1]),                     # counting measure
    "residents": weighted(PEOPLE),
    "share": lambda m: Fraction(weighted(PEOPLE)(m), TOTAL),
    "area": weighted(AREA),
    "town hall": weighted([0, 1, 0]),                     # point mass at C
    "never-finite": lambda m: INF if m else 0,
}
broken = {
    "density": lambda m: Fraction(rules["residents"](m), rules["area"](m)) if m else 0,
    "largest district": lambda m: max([PEOPLE[i] for i in range(3) if m >> i & 1] or [0]),
    "residents minus 30000": lambda m: rules["residents"](m) - 30000,
}

def district_of(x):                     # which district holds position x (0.1 km)
    return next(i for i in range(3) if EDGE[i] <= x < EDGE[i + 1])

def grid_area(m):                       # road two for area: count 0.01 km2 cells
    cells = sum(1 for col in range(100) for row in range(25) if m >> district_of(col) & 1)
    return Fraction(cells, 100)

state = 20260929                        # SplitMix64, seed 20260929
def draw():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return z ^ (z >> 31)

DRAWS = 20000
hits = [0, 0, 0]
for _ in range(DRAWS):                  # a resident picked at random, by register number
    k = draw() % TOTAL
    hits[0 if k < PEOPLE[0] else (1 if k < PEOPLE[0] + PEOPLE[1] else 2)] += 1

print(f"{'set':<8}{'districts':>10}{'residents':>11}{'share':>8}{'area km2':>10}{'town hall':>11}")
for m in range(8):
    r = rules
    print(f"{label(m):<8}{r['districts'](m):>10}{r['residents'](m):>11}"
          f"{float(r['share'](m)):>8.4f}{r['area'](m):>10}{r['town hall'](m):>11}")
grid = [grid_area(m) for m in range(8)]
assert all(grid[m] == rules["area"](m) for m in range(8))
print("area counted on a 0.1 km grid:", ", ".join(str(g) for g in grid))
est = [sum(hits[i] for i in range(3) if m >> i & 1) / DRAWS for m in range(8)]
for m in range(8):
    p = float(rules["share"](m))
    assert abs(est[m] - p) <= 4 * (p * (1 - p) / DRAWS) ** 0.5 + 1e-12
print(f"share from {DRAWS} random residents:", ", ".join(f"{e:.4f}" for e in est))
hall = [int(m >> district_of(HALL) & 1) for m in range(8)]
assert hall == [rules["town hall"](m) for m in range(8)]
print("town hall found by position:", ", ".join(str(h) for h in hall))
print("city strip: 10 km by 2.5 km; edges at", ", ".join(f"{e / 10:g}" for e in EDGE),
      f"km; town hall at {HALL / 10:g} km; draws from SplitMix64, seed 20260929")
SURVEY = [0, 1, 6, 7]                   # a survey that records only "lives in North?"
assert all(7 ^ a in SURVEY and a | b in SURVEY for a in SURVEY for b in SURVEY)
print("survey recording only North: sets", ", ".join(label(m) for m in SURVEY) + "; residents",
      ", ".join(str(rules["residents"](m)) for m in SURVEY))

pairs = [(a, b) for a in range(8) for b in range(8) if a & b == 0]
def failures(f):
    return sum(1 for a, b in pairs if f(a | b) != f(a) + f(b))
print("disjoint pairs checked per rule:", len(pairs))
print("additivity failures:", ", ".join(f"{n} {failures(f)}" for n, f in rules.items()))
print("additivity failures:", ", ".join(f"{n} {failures(f)}" for n, f in broken.items()))
assert all(failures(f) == 0 for f in rules.values())
assert [failures(f) for f in broken.values()] == [12, 12, 27]
d = broken["density"]
print(f"density of N, C and N,C: {float(d(1)):.2f}, {float(d(2)):.2f}, {float(d(3)):.2f}"
      f" (parts add to {float(d(1) + d(2)):.2f})")
g = broken["largest district"]
print(f"largest district in N, C and N,C: {g(1)}, {g(2)}, {g(3)} (parts add to {g(1) + g(2)})")
print("residents minus 30000 on the empty set:", broken["residents minus 30000"](0))
print("residents of N,C plus residents of C,S:", rules["residents"](3) + rules["residents"](6),
      "against the whole city", rules["residents"](7))

# finite-or-not rule on whole numbers.  A set is stored exactly in 18 bits: bits
# 0-11 are its members below 12; bits 12-17 are the remainders mod 6 of its
# members from 12 on.  It is infinite exactly when one of bits 12-17 is set.
def finite_or_not(s):                   # 0 on a finite set, inf on an infinite one
    return INF if s >> 12 else 0
kinds, fails = [0, 0, 0], 0
for _ in range(3000):                   # random disjoint pairs, finite and infinite
    x, y, u, v = draw(), draw(), draw(), draw()
    a = x % 2 ** (12 + 6 * (u % 2))
    b = y % 2 ** (12 + 6 * (v % 2)) & ~a
    kinds[(a >> 12 > 0) + (b >> 12 > 0)] += 1
    fails += finite_or_not(a | b) != finite_or_not(a) + finite_or_not(b)
assert fails == 0 and min(kinds) > 0
print(f"finite-or-not rule: 3000 random disjoint pairs (both finite {kinds[0]}, one infinite"
      f" {kinds[1]}, both infinite {kinds[2]}), additivity failures {fails}")
print(f"finite-or-not rule: each singleton {finite_or_not(1)}, union of {{0}} to {{11}}"
      f" {finite_or_not(2**12 - 1)}, all whole numbers {finite_or_not(2**18 - 1)}")
finite = [m for m in range(8) if rules["never-finite"](m) < INF]
cover = 0
for m in finite:
    cover |= m
assert cover != 7
print("never-finite rule: sets of finite size:", ", ".join(label(m) for m in finite)
      + "; their union:", label(cover) + ", not the whole city")

for k in (1, 2, 3, 5, 10, 100):         # unit intervals [n, n+1), n = -k .. k-1
    pieces = [(n, n + 1) for n in range(-k, k)]
    runs = []
    for a, b in sorted(pieces):         # merge touching pieces into runs
        if runs and runs[-1][1] == a:
            runs[-1] = (runs[-1][0], b)
        else:
            runs.append((a, b))
    assert len(runs) == 1 and runs[0][1] - runs[0][0] == sum(b - a for a, b in pieces) == 2 * k
    print(f"unit intervals from {-k} to {k}: {len(pieces)} pieces, lengths add to {2 * k},"
          f" merged run [{runs[0][0]}, {runs[0][1]}) has length {runs[0][1] - runs[0][0]}")
print("figure, city strip: 30 units per km, edges x =",
      ", ".join(str(30 + 3 * e) for e in EDGE) + f"; town hall x = {30 + 3 * HALL}; height 75 = 2.5 km")
print("ALL CHECKS PASS")
