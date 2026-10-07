# Inclusion-exclusion for any number of sets -- the check behind the card.  Nothing
# is imported.  A hotel of 100 guests with three amenities, then the numbers 1 to
# 1000 sieved by 2, 3, 5 and by 2, 3, 5, 7.  Every count is reached twice: by the
# signed sum of overlaps, and by walking the members one at a time.
REGIONS = {("B", "P", "S"): 5, ("B", "P"): 15, ("B", "S"): 10, ("P", "S"): 5,
           ("B",): 20, ("P",): 15, ("S",): 10, (): 20}
ROSTER = [set(r) for r, n in REGIONS.items() for _ in range(n)]

def pick(items, j):                      # every j of the items, order kept
    if j == 0: return [()]
    return [(x,) + r for i, x in enumerate(items) for r in pick(items[i + 1:], j - 1)]

def overlaps(items, size):               # every j-at-a-time overlap, layer by layer
    return [[size(c) for c in pick(items, j)] for j in range(1, len(items) + 1)]

def union(ls):                           # S_1 - S_2 + S_3 - ...
    return sum((-1) ** j * sum(layer) for j, layer in enumerate(ls))

def choose(n, k):                        # Pascal's triangle, built here
    row = [1]
    for _ in range(n): row = [a + b for a, b in zip([0] + row, row + [0])]
    return row[k]

def guests_with(names):                  # guests holding every amenity named
    return sum(1 for g in ROSTER if set(names) <= g)
def prod(ds): return ds[0] * prod(ds[1:]) if ds else 1
def multiples_of_all(ds): return 1000 // prod(ds)     # 1 to 1000 divisible by all of ds
def none_of(ds, limit):                  # road two: test every number in turn
    return sum(1 for x in range(1, limit + 1) if all(x % d for d in ds))
def yn(claim): return "yes" if claim else "no"

th = overlaps(list("BPS"), guests_with)
hl = [sum(layer) for layer in th]
hotel, walk = union(th), sum(1 for g in ROSTER if g)
ones = [sum((-1) ** (j + 1) * choose(k, j) for j in range(1, k + 1)) for k in range(1, 9)]
t3, t4 = overlaps([2, 3, 5], multiples_of_all), overlaps([2, 3, 5, 7], multiples_of_all)
l3, l4 = [sum(x) for x in t3], [sum(x) for x in t4]
none3, none4 = 1000 - union(t3), 1000 - union(t4)
blocks, per, spare = 1000 // 30, none_of([2, 3, 5], 30), sum(1 for x in range(991, 1001) if all(x % d for d in (2, 3, 5)))
print(f"hotel: {len(ROSTER)} guests; singles {th[0]}, pairs {th[1]}, all three {th[2]}")
print(f"layers S1 {hl[0]}, S2 {hl[1]}, S3 {hl[2]}  ->  union {hl[0]} - {hl[1]} + {hl[2]} = {hotel}")
print(f"the same {hotel}, by walking the roster guest by guest: {yn(hotel == walk)}")
print(f"guests who took nothing: {len(ROSTER)} - {hotel} = {len(ROSTER) - hotel}")
print(f"a guest in k of the amenities is counted, for k = 1 to 8: {ones}")
print(f"Pascal's row for k = 4, the counts that alternate: {[choose(4, j) for j in range(5)]}")
print(f"mistake 1, add the three counts and stop: {hl[0]}, not {hotel}")
print(f"mistake 2, stop after the pairs: {hl[0] - hl[1]}, not {hotel}")
print(f"mistake 3, subtract the triple instead of adding: {hl[0] - hl[1] - hl[2]}, not {hotel}")
print(f"1 to 1000, none of 2, 3, 5: layers {l3}  ->  union {union(t3)}, none {none3}")
print(f"1 to 1000, none of 2, 3, 5: by testing each number {none_of([2, 3, 5], 1000)}")
print(f"1 to 1000, none of 2, 3, 5: {blocks} blocks of 30 x {per} + {spare} left over = {blocks * per + spare}")
print(f"1 to 1000, by 2, 3, 5, 7: singles {t4[0]}, pairs {t4[1]}, triples {t4[2]}, all four {t4[3]}")
print(f"1 to 1000, none of 2, 3, 5, 7: layers {l4}  ->  union {union(t4)}, none {none4}")
print(f"1 to 1000, none of 2, 3, 5, 7: by testing each number {none_of([2, 3, 5, 7], 1000)}")
assert hotel == walk and hotel == 80                       # sieve against a head count
assert len(ROSTER) - hotel == 20 and hl == [120, 45, 5]    # the layers, one at a time
assert none3 == none_of([2, 3, 5], 1000) and none3 == blocks * per + spare
assert none4 == none_of([2, 3, 5, 7], 1000) and ones == [1] * 8
print("ALL CHECKS PASS")
