# Generated sigma-algebras and Borel sets -- the check behind the card.
# Standard library only.  Part 1 works on a world of four whole-degree readings,
# where every family can be listed, and builds each generated sigma-algebra by
# three roads that share no code.  Part 2 checks the real-line steps at exact
# rational points; it shows instances, the proofs on the card cover every t.
from fractions import Fraction as Fr
from math import ceil, floor

R = [17, 18, 19, 20]                     # the four readings; a set is a 4-bit mask
FULL = 15

def show(m):
    return "{" + ", ".join(str(r) for i, r in enumerate(R) if m >> i & 1) + "}"

def mask(test):
    return sum(1 << i for i, r in enumerate(R) if test(r))

def closure(C):                          # road 1: add complements and unions until nothing new
    S, rounds = set(C), [len(set(C))]
    while True:
        new = S | {FULL ^ m for m in S} | {a | b for a in S for b in S}
        if new == S:
            return S, rounds
        S = new
        rounds.append(len(S))

def by_atoms(C):                         # road 2: group readings no generator can tell apart
    groups = {}
    for i in range(4):
        groups.setdefault(tuple(g >> i & 1 for g in C), []).append(i)
    atoms = [sum(1 << i for i in g) for g in groups.values()]
    unions = {sum(a for j, a in enumerate(atoms) if k >> j & 1) for k in range(1 << len(atoms))}
    return unions, sorted(atoms)

def is_sigma(fam):                       # the three rules, on a family of subsets
    mem = [s for s in range(16) if fam >> s & 1]
    return (fam & 1 and all(fam >> (FULL ^ m) & 1 for m in mem)
            and all(fam >> (a | b) & 1 for a in mem for b in mem))

SIGMAS = [f for f in range(1 << 16) if is_sigma(f)]

def by_intersection(C):                  # road 3: intersect every sigma-algebra holding C
    out = (1 << 16) - 1
    for f in SIGMAS:
        if all(f >> c & 1 for c in C):
            out &= f
    return {s for s in range(16) if out >> s & 1}

bell = [1]                               # Bell numbers count the ways to split a set into blocks
for n in range(4):
    row = [1]
    for k in range(1, n + 1):
        row.append(row[-1] * (n - k + 1) // k)
    bell.append(sum(row[k] * bell[k] for k in range(n + 1)))

families = [
    ("rays below t", sorted({mask(lambda r: r < t) for t in range(16, 22)})),
    ("open intervals", sorted({mask(lambda r: a < 2 * r < b) for a in range(32, 43) for b in range(32, 43) if a < b})),
    ("closed intervals", sorted({mask(lambda r: a <= r <= b) for a in R for b in R if a <= b})),
    ("gauge, t = 18, 20", [mask(lambda r: r < 18), mask(lambda r: r < 20)]),
]
print(f"four readings {R}: subsets 16, sigma-algebras {len(SIGMAS)}, Bell number {bell[4]}")
print("family             | generators | closure | atoms | intersection | rounds")
results = {}
for name, C in families:
    s1, rounds = closure(C)
    s2, atoms = by_atoms(C)
    s3 = by_intersection(C)
    assert s1 == s2 == s3, name                                    # three roads, one family
    results[name] = (s1, atoms)
    print(f"{name:18} | {len(C):10} | {len(s1):7} | {len(s2):5} | {len(s3):12} | {' -> '.join(map(str, rounds))}")
gs, gatoms = results["gauge, t = 18, 20"]
print("gauge atoms: " + " | ".join(show(a) for a in gatoms))
print(f"gauge settles 'exactly 19': {'yes' if mask(lambda r: r == 19) in gs else 'no'}; "
      f"'exactly 20': {'yes' if mask(lambda r: r == 20) in gs else 'no'}")
assert len(SIGMAS) == bell[4] == 15
assert mask(lambda r: r == 19) not in gs and mask(lambda r: r == 20) in gs and len(gs) == 2 ** len(gatoms) == 8

# ---- Part 2: the real line, at exact rational points ----
print("closed ray (-inf, 20] from open rays (-inf, 20 + 1/n): first n that leaves each point out")
for x in [Fr(41, 2), Fr(203, 10), Fr(2001, 100), Fr(200007, 10000)]:
    n = 1
    while x < 20 + Fr(1, n):              # search: shrink the ray until x falls outside
        n += 1
    formula = ceil(1 / (x - 20))           # formula: 20 + 1/n <= x exactly when n >= 1/(x - 20)
    assert n == formula
    print(f"  reading {float(x)}: search n = {n}, formula n = {formula}")
print(f"  by hand, reading 20.3: 20 + 1/3 = {float(20 + Fr(1, 3)):.4f} is above it, 20 + 1/4 = {float(20 + Fr(1, 4))} is not")
print("  reading 20: inside every ray, so inside (-inf, 20]")
print("sliver [20, 20 + 1/n) = (-inf, 20 + 1/n) minus (-inf, 20), length by n: "
      + ", ".join(f"n={n} {1 / n:g}" for n in [1, 2, 4, 10, 100, 1000]))

grid = [Fr(k, 4) for k in range(68, 85)] + [18 + Fr(s, 1000) for s in (-1, 1)] + [20 + Fr(s, 1000) for s in (-1, 1)]
below = lambda t: (lambda x: x < t)                          # the thermometer's question
closed_below = lambda t: (lambda x: all(x < t + Fr(1, n) for n in range(1, 10001)))
built = {
    "{20}": (lambda x: x == 20, lambda x: closed_below(20)(x) and not below(20)(x)),
    "(18, 20)": (lambda x: 18 < x < 20, lambda x: below(20)(x) and not closed_below(18)(x)),
    "[18, 20]": (lambda x: 18 <= x <= 20, lambda x: closed_below(20)(x) and not below(18)(x)),
}
for name, (direct, from_rays) in built.items():
    agree = sum(direct(x) == from_rays(x) for x in grid)
    assert agree == len(grid), name
    print(f"  {name:9} built from rays agrees with its definition at {agree} of {len(grid)} exact points")
print("  (a closed ray (-inf, t] is tested as the rays (-inf, t + 1/n) for n = 1 to 10000)")

lo, hi = 1.0, 2.0                        # square root of 2 by bisection, written out
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if mid * mid < 2 else (lo, mid)
print(f"band (0, sqrt 2), sqrt 2 = {lo:.6f} by bisection; union of rational intervals (0, p/q) inside it")
for q in [1, 10, 100, 1000]:
    p = 0
    while (p + 1) * (p + 1) < 2 * q * q:  # search: largest p with (p/q)^2 < 2, integers only
        p += 1
    assert p == floor(q * lo)             # the bisection root gives the same p
    print(f"  q = {q:4}: p = {p:4}, reach p/q = {p / q:.4f}, uncovered [p/q, sqrt 2) length {lo - p / q:.6f}")

print(f"  by hand, q = 100: 141*141 = {141 * 141} < 2*100*100 = {2 * 100 * 100} < 142*142 = {142 * 142}")
x = lambda t: 40 + 120 * (t - 19)          # the picture: 120 units per degree, 19 degrees at 40
print("figure, x(19) = %g, x(20) = %g, x(21) = %g, sliver right ends n=1,2,4: %g, %g, %g"
      % (x(19), x(20), x(21), x(20 + 1), x(20 + 1 / 2), x(20 + 1 / 4)))
print("ALL CHECKS PASS")
