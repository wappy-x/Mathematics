# Indexed families -- the check behind the card.  Nothing is imported.  The deck
# indexed by rank and by suit, then the intervals [0, 1/n) and [1/n, 1].
SUITS = ["clubs", "diamonds", "hearts", "spades"]
RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
DECK = [(s, r) for s in SUITS for r in RANKS]
A = {r: [c for c in DECK if c[1] == r] for r in RANKS}   # the family: rank -> its 4 cards
B = {s: [c for c in DECK if c[0] == s] for s in SUITS}   # suit -> its 13 cards
union = [c for c in DECK if any(c in A[r] for r in RANKS)]
inter = [c for c in DECK if all(c in A[r] for r in RANKS)]
hearts = [c for c in union if c in B["hearts"]]; by_rank = [c for r in RANKS for c in A[r] if c in B["hearts"]]  # distributive law
picks = [[]]                                  # one card from each suit, a suit at a time
for s in SUITS:
    picks = [p + [c] for p in picks for c in B[s]]
G = 60; pts, ns = range(G + 1), range(1, G + 1)   # points k/60, k = 0..60; sets n = 1..60
in_every = [k for k in pts if all(k * n < G for n in ns)]       # in every [0, 1/n)
in_some = [k for k in pts if any(k * n >= G for n in ns)]       # in some [1/n, 1]
outside = [k for k in pts if k not in in_some]                  # complement of the union
no_flip = [k for k in pts if any(k * n < G for n in ns)]        # union of [0, 1/n): wrong
drop = next(n for n in range(1, 10 ** 6) if not 1 * n < 1000)   # 1/1000 is in [0, 1/n) while 1*n < 1000
print(f"rank family: {len(A)} sets of {len(A['ace'])} cards; union {len(union)}, intersection {len(inter)}")
print(f"distributive law: hearts in the union {len(hearts)}; union of the hearts in each pile {len(by_rank)}")
print(f"one card from each suit: {len(picks)} picks, by formula 13^4 = {13 ** 4}")
print(f"points tested: {len(pts)}; in every [0, 1/n): {len(in_every)}, at x = {in_every[0]}")
print(f"in some [1/n, 1]: {len(in_some)}; outside that union: {len(outside)}, at x = {outside[0]}")
print(f"0.001 drops out of [0, 1/n) at n = {drop}")
print(f"the three mistakes come out at {len(union)}, {4 ** 13} and {len(no_flip)}")
assert len(union) == 13 * 4 and inter == [] and hearts == by_rank and len(hearts) == 13 and len(DECK) == 52
assert len(picks) == 13 ** 4 and all(p[i][0] == SUITS[i] for p in picks for i in range(4))
assert outside == in_every == [0] and len(in_some) == G and len(no_flip) == G   # De Morgan
print("ALL CHECKS PASS")
