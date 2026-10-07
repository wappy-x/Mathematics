# Stopping the sieve early -- the check behind the card.  Nothing is imported.
# A 30-day log at an airfield: 12 rainy days, 8 windy, 5 foggy, some days under
# two headings and one under all three.  The bad-day count is reached by listing
# the log and again by the sieve, and every truncation is then tested as a bound
# on all 4096 families of three subsets of a four-day month.
RAINY = set(range(1, 13))                        # days 1 to 12
WINDY = {8, 9, 10, 12, 13, 14, 15, 16}           # 8, 9, 10 and 12 are rainy too
FOGGY = {11, 12, 17, 18, 19}                     # 11 and 12 are rainy too
LOG = [RAINY, WINDY, FOGGY]

def layer(sets, j):                              # S_j: all j-at-a-time overlaps added
    total = 0
    for pick in range(1, 1 << len(sets)):        # every group of sets, as a bit pattern
        chosen = [s for i, s in enumerate(sets) if pick >> i & 1]
        if len(chosen) == j:
            total += len(set.intersection(*chosen))
    return total

def truncate(sets, m):                           # the sieve stopped after m layers
    return sum((-1) ** (j + 1) * layer(sets, j) for j in range(1, m + 1))

def yn(claim): return "yes" if claim else "no"

pascal = [[1] + [0] * 5]                         # C(n, k) by Pascal's rule, rows 0 to 5
for r in range(1, 6):
    pascal.append([1] + [pascal[r - 1][i - 1] + pascal[r - 1][i] for i in range(1, 6)])
S = [0] + [layer(LOG, j) for j in (1, 2, 3)]
trunc = [truncate(LOG, m) for m in (1, 2, 3)]
listed = len(RAINY | WINDY | FOGGY)                        # road one: list the log out
by_k = [sum(1 for d in range(1, 31) if sum(d in s for s in LOG) == k) for k in range(4)]
tally = [[truncate([{0}] * k, m) for m in (1, 2, 3, 4)] for k in (1, 2, 3, 4)]
closed = [[1 - (-1) ** m * pascal[k - 1][m] for m in (1, 2, 3, 4)] for k in (1, 2, 3, 4)]
pieces = [{d for d in range(4) if mask >> d & 1} for mask in range(16)]
families, out_of_bounds, tight = 0, 0, 0
for fam in [[a, b, c] for a in pieces for b in pieces for c in pieces]:
    families, u = families + 1, len(fam[0] | fam[1] | fam[2])
    for m in (1, 2, 3):
        t = truncate(fam, m)
        out_of_bounds += (t < u) if m % 2 else (t > u)
        tight += m == 1 and t == u               # ceiling exact: no two sets share a day
biggest = max(len(RAINY & WINDY), len(RAINY & FOGGY), len(WINDY & FOGGY))
wrong = [S[1], S[1] - S[2], S[1] - S[2] - S[3], S[1] - biggest]

print(f"30-day log: rainy {len(RAINY)}, windy {len(WINDY)}, foggy {len(FOGGY)}")
print(f"layer totals: S1 = {S[1]}, S2 = {S[2]}, S3 = {S[3]}")
print(f"sieve stopped after 1, 2, 3 layers: {trunc[0]}, {trunc[1]}, {trunc[2]}")
print(f"bad days by listing the log: {listed}")
print(f"days under 0, 1, 2, 3 headings: {by_k[0]}, {by_k[1]}, {by_k[2]}, {by_k[3]}")
print(f"one layer over-counts by {trunc[0] - listed}, two layers under-count by {listed - trunc[1]}")
print("tally for one day under k headings, m = 1 2 3 4:")
for k in (1, 2, 3, 4):
    print(f"  k = {k}: {tally[k - 1]}")
print(f"the same tallies from 1 - (-1)^m C(k-1, m): {yn(tally == closed)}")
print(f"sweep: {families} families of 3 subsets of 4 days, out of bounds: {out_of_bounds}, ceiling exact: {tight}")
print(f"mistakes come out at {wrong[0]}, {wrong[1]}, {wrong[2]} and {wrong[3]}, against the true {listed}")
assert listed == trunc[2]                                  # listing the log vs the full sieve
assert (trunc[0], trunc[1]) == (25, 18) and trunc[0] >= listed >= trunc[1]
assert tally == closed and tally[2] == [3, 0, 1, 1]        # counted vs the closed form
assert out_of_bounds == 0 and tight == 4 ** 4              # one home per day: set 1, 2, 3 or none
print("ALL CHECKS PASS")
