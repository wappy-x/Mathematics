# Divide-and-conquer recurrences -- the check behind the card.  A deck of 1,024
# cards is sorted by merging halves and searched by halving.  Each recurrence
# T(n) = a T(n/b) + f(n) is totalled twice: level by level, and by the closed
# form the proof gives.  The shuffle uses a generator written out here.
from math import log2                       # used for printing log_b a only
N, K = 1024, 10                             # 1024 cards, 10 halvings down to one
SHAPES = [(2, 1, "a=2 b=2 f(n)=n  "), (1, 0, "a=1 b=2 f(n)=1  "),
          (3, 1, "a=3 b=2 f(n)=n  "), (2, 2, "a=2 b=2 f(n)=n^2")]
def levels(a, d):                           # a^j jobs of size N/2^j, each costing size^d
    return [a ** j * (N // 2 ** j) ** d for j in range(K)]
def shuffled():                             # written out, so both languages agree
    deck, x = list(range(1, N + 1)), 20260914
    for i in range(N - 1, 0, -1):
        x = (1103515245 * x + 12345) % 2 ** 31
        j = x % (i + 1)
        deck[i], deck[j] = deck[j], deck[i]
    return deck
def merge_sort(cards, tally):               # road two: the comparisons actually made
    if len(cards) < 2: return cards
    h = len(cards) // 2
    a, b = merge_sort(cards[:h], tally), merge_sort(cards[h:], tally)
    out, i, j = [], 0, 0
    while i < len(a) and j < len(b):
        tally[0] += 1
        if a[i] <= b[j]: out.append(a[i]); i += 1
        else: out.append(b[j]); j += 1
    return out + a[i:] + b[j:]
def halvings(t, cards):                     # narrow the window until one card is left
    lo, hi, n = 0, len(cards) - 1, 0
    while lo < hi:
        mid, n = (lo + hi) // 2, n + 1
        lo, hi = (mid + 1, hi) if cards[mid] < t else (lo, mid)
    return n if cards[lo] == t else -1      # -1 would mark a search that missed
tally = [0]
deck = merge_sort(shuffled(), tally)
found = [halvings(t, deck) for t in deck]
tables = [levels(a, d) for a, d, _ in SHAPES]
totals = [sum(t) for t in tables]
closed = [K * N, K, 2 * (3 ** K - 2 ** K), 2 * N * (N - 1)]
names = {1: "case 1, the leaves win  ", 2: "case 2, every level ties", 3: "case 3, the top wins    "}
by_root = [1 if a > 2 ** d else 2 if a == 2 ** d else 3 for a, d, _ in SHAPES]
by_mass = [1 if s > K * t[0] else 2 if s == K * t[0] else 3 for s, t in zip(totals, tables)]
print(f"deck of {N} cards: {K} levels, piece sizes {[N // 2 ** j for j in range(K)]}, piles {[2 ** j for j in range(K)]}")
print(f"merge sort, road one, {K} levels of at most {N} comparisons: {K * N}")
print(f"merge sort, road two, {tally[0]} comparisons counted on the shuffled deck, which comes out in order: {'yes' if deck == list(range(1, N + 1)) else 'no'}")
print(f"binary search, road one, one probe per level: {totals[1]} probes")
print(f"binary search, road two, over all {N} targets: most {max(found)}, fewest {min(found)}")
for (a, d, tag), s, r in zip(SHAPES, totals, by_root):
    print(f"{tag}  log_b a = {log2(a):.6f}, f is n^{d:.6f}  ->  {names[r]}  total {s}")
print(f"level costs, a=3 b=2 f(n)=n:   {tables[2]}")
print(f"level costs, a=2 b=2 f(n)=n^2: {tables[3]}")
print(f"leaves alone 3^{K} = {3 ** K}; unrolled total {totals[2]} = 2 x (3^{K} - 2^{K})")
print(f"top level alone {tables[3][0]}; unrolled total {totals[3]} = 2 x {N} x {N - 1}")
print(f"mistake 1, quoting the top merge alone: {tables[0][0]}, not {totals[0]}")
print(f"mistake 2, a=3 read as n log n: {totals[0]}; mistake 3, leaves x levels: {3 ** K * K}")
assert totals == closed                     # level by level against the closed forms
assert deck == list(range(1, N + 1)) and tally[0] <= K * N
assert max(found) == K and min(found) == K  # measured halvings against the level count
assert by_root == by_mass and by_root == [2, 2, 1, 3]
print("ALL CHECKS PASS")
