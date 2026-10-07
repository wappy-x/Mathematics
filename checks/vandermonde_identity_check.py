# Vandermonde's identity -- the check behind the card.  Nothing is imported.  Ten
# musicians, 6 guitarists and 4 drummers, and a band is 5 of them, order ignored.
# The bands are counted twice by roads sharing no arithmetic: every band listed one
# at a time, and the split C(6,k) x C(4,5-k) read off a triangle built by addition
# alone.  Equal groups then turn the same sum into a sum of squares.
GUITARS, DRUMS, SEATS = 6, 4, 5
def triangle(top):                      # every count from addition alone, no factorials
    rows = [[1]]
    for n in range(1, top + 1):
        up = rows[-1]
        rows.append([1] + [up[k - 1] + up[k] for k in range(1, n)] + [1])
    return rows
T = triangle(16)
def C(n, k):                            # picks of k from n, and zero off the row
    return 0 if k < 0 or k > n else T[n][k]
def listed(pool, seats, first):         # road one: every band listed, split by first-group size
    counts = [0] * (seats + 1)
    for mask in range(1 << pool):
        chosen = [i for i in range(pool) if mask >> i & 1]
        if len(chosen) == seats:
            counts[sum(1 for i in chosen if i < first)] += 1
    return counts
def split(m, n, r):                     # road two: k from the first group, the rest from the second
    return [C(m, k) * C(n, r - k) for k in range(r + 1)]
def grid(name, xs): print(f"{name:<33}" + "".join(f"{x:>6}" for x in xs))
def flat(xs): return " ".join(str(x) for x in xs)
by_hand = listed(GUITARS + DRUMS, SEATS, GUITARS)
terms = split(GUITARS, DRUMS, SEATS)
whole = C(GUITARS + DRUMS, SEATS)
even = listed(2 * SEATS, SEATS, SEATS)
squares = [C(SEATS, k) ** 2 for k in range(SEATS + 1)]
triples = [(m, n, r) for m in range(9) for n in range(9) for r in range(m + n + 3)]
holds = sum(1 for m, n, r in triples if C(m + n, r) == sum(split(m, n, r)))
same_k = [C(GUITARS, k) * C(DRUMS, k) for k in range(DRUMS + 1)]
stopped = sum(terms[:SEATS])
lineups, orderings = 1, 1
for i in range(SEATS): lineups *= GUITARS + DRUMS - i
for i in range(1, SEATS + 1): orderings *= i
shared = sum(listed(GUITARS + DRUMS - 1, SEATS, 0))
print(f"{GUITARS + DRUMS} musicians: {GUITARS} guitarists and {DRUMS} drummers; "
      f"a band is {SEATS} of them, order ignored")
grid("guitarists in the band, k", list(range(SEATS + 1)))
grid("ways to choose those guitarists", [C(GUITARS, k) for k in range(SEATS + 1)])
grid("ways to fill the rest from 4", [C(DRUMS, SEATS - k) for k in range(SEATS + 1)])
grid("bands with that many guitarists", terms)
print(f"road one, every band listed and sorted by guitarist count: {flat(by_hand)}, adding to {sum(by_hand)}")
print(f"road two, the products above added: {sum(terms)}; the whole pool at once, C(10,5) = {whole}")
print(f"row 10 of the triangle: {flat(T[10])}, adding to {sum(T[10])}, middle entry {T[10][SEATS]}")
print(f"5 guitarists and 5 drummers instead: {flat(even)}, adding to {sum(even)}")
print(f"the same six terms as the squares of row 5 ({flat(T[5])}): {flat(squares)}")
print(f"the identity on every m, n up to 8 and every r up to m+n+2: {holds} of {len(triples)} triples hold")
print(f"mistake 1, the same k in both groups: {' + '.join(str(x) for x in same_k)} = {sum(same_k)}, not {whole}")
print(f"mistake 2, k stopped at 4, the drummer count: {stopped}, not {whole}")
print(f"mistake 3, line-ups counted instead of bands: {lineups} = {whole} x {orderings}, not {whole}")
print(f"mistake 4, one player on both lists: 9 people give {shared} bands, the split still says {sum(terms)}")
assert by_hand == terms and sum(by_hand) == whole          # listing against the split, and against C(10,5)
assert even == squares and sum(even) == whole              # equal groups: listing against squares of row 5
assert holds == len(triples) and lineups == whole * orderings
assert shared == C(GUITARS + DRUMS - 1, SEATS) and sum(same_k) == C(GUITARS + DRUMS, DRUMS)
print("ALL CHECKS PASS")
