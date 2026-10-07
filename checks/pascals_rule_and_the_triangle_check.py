# Pascal's rule and the triangle -- the check behind the card.  Nothing is imported.
# Five songs -- Anchor, Blue Hour, Cinders, Drift, Ember -- and a pick is which songs
# make the set, not the order they are played in.  The triangle is built three ways
# sharing no arithmetic: adding the two entries above, the factorial formula, and
# listing every pick one at a time.
ROWS = 10
SONGS = ["Anchor", "Blue Hour", "Cinders", "Drift", "Ember"]
def by_addition(top):                      # road one: each entry from the two above
    rows = [[1]]
    for n in range(1, top + 1):
        above = rows[-1]
        rows.append([1] + [above[k - 1] + above[k] for k in range(1, n)] + [1])
    return rows
def factorial(m):                          # 1 x 2 x ... x m, and 0! = 1
    out = 1
    for i in range(2, m + 1): out *= i
    return out
def choose(n, k):                          # road two: n! / (k! (n-k)!), zero off the row
    if k < 0 or k > n: return 0
    return factorial(n) // (factorial(k) * factorial(n - k))
def every_pick(n):                         # road three: one bit per song, in or out
    return [[i for i in range(n) if m >> i & 1] for m in range(2 ** n)]
def sizes(n):                              # how many of the listed picks are each size
    counts = [0] * (n + 1)
    for pick in every_pick(n): counts[len(pick)] += 1
    return counts
def as_number(row):                        # the row read as the digits of one number
    return sum(x * 10 ** (len(row) - 1 - i) for i, x in enumerate(row))
def elevens(k):                            # 11 multiplied in k times
    out = 1
    for _ in range(k): out *= 11
    return out
def yn(claim): return "yes" if claim else "no"

rows = by_addition(ROWS)
formula = [[choose(n, k) for k in range(n + 1)] for n in range(ROWS + 1)]
listed = [sizes(n) for n in range(ROWS + 1)]
sums = [sum(r) for r in rows]
doubling = [2 ** n for n in range(ROWS + 1)]
two = ["".join(SONGS[i][0] for i in p) for p in every_pick(5) if len(p) == 2]
out_e = [t for t in two if "E" not in t]
in_e = [t for t in two if "E" in t]
orders = [(a, b) for a in range(5) for b in range(5) if a != b]
print(f"five songs: {', '.join(SONGS)} -- a pick is which songs, not their order")
for n in range(ROWS + 1):
    print(f"row {n:>2}: {' '.join(str(x) for x in rows[n]):<36}adds to {sums[n]} = 2^{n}")
print(f"the same eleven rows from the factorial formula: {yn(formula == rows)}")
print(f"the same eleven rows by listing every pick: {yn(listed == rows)}")
print(f"the two-song picks, listed: {' '.join(two)}  ->  {len(two)}")
print(f"Pascal's rule at n = 5, k = 2: {len(out_e)} without Ember + {len(in_e)} with Ember = {len(two)}")
print(f"row 4 as one number: {as_number(rows[4])} = 11 multiplied in 4 times ({elevens(4)}); "
      f"row 5 carries to {as_number(rows[5])} = {elevens(5)}")
print(f"mistakes: dropping the empty and the full pick gives {sums[5] - 2}, not {sums[5]}; "
      f"adding C(4,2) twice gives {2 * choose(4, 2)}, not {choose(5, 2)}; "
      f"counting running orders gives {len(orders)}, not {len(two)}")
assert rows == formula                                   # addition against factorials
assert rows == listed                                    # addition against every pick listed
assert sums == doubling and sums[ROWS] == 1024           # row sums against doublings
assert as_number(rows[4]) == elevens(4) and len(out_e) + len(in_e) == choose(5, 2) == len(two)
print("ALL CHECKS PASS")
