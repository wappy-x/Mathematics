# Counting chances -- the check behind the card.  Nothing is imported.
# A five-card poker hand from a shuffled 52-card deck: the chance of a flush,
# five cards of one suit.  Road 1 counts unordered hands with C(n, k).  Road 2
# counts ordered deals.  Road 3 lists all 2,598,960 hands.  Road 4 deals a
# million hands with a seeded SplitMix64 generator written out here.
MASK = (1 << 64) - 1

def choose(n, k):                        # C(n, k), multiplied and divided in turn
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

def falling(n, k):                       # n x (n-1) x ... , k factors: ordered picks
    out = 1
    for i in range(k):
        out *= n - i
    return out

class SplitMix64:                        # a small seeded generator, same in Rust
    def __init__(self, seed):
        self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def below(self, n):                  # a whole number from 0 to n - 1
        return (self.next() * n) >> 64

SHAPES = ["5", "4-1", "3-2", "3-1-1", "2-2-1", "2-1-1-1"]

# Road 1: unordered hands.  Pick the suit, then five of its 13 ranks.
hands = choose(52, 5)
flush = 4 * choose(13, 5)
straight_flush = 4 * 10                  # lowest card ace (low) up to ten, in each suit
p_flush, p_proper = flush / hands, (flush - straight_flush) / hands
# The suit shapes by formula: which suits play which part, then ranks inside each.
c = [choose(13, j) for j in range(6)]
shape_formula = {"5": 4 * c[5], "4-1": 4 * 3 * c[4] * c[1], "3-2": 4 * 3 * c[3] * c[2],
                 "3-1-1": 4 * 3 * c[3] * c[1] ** 2, "2-2-1": 4 * 3 * c[2] ** 2 * c[1],
                 "2-1-1-1": 4 * c[2] * c[1] ** 3}

# Road 2: ordered deals.  Any first card, then 12 of the 51 left share its suit, ...
ordered_all = falling(52, 5)
ordered_flush = 52 * falling(12, 4)

# Road 3: list every hand.  A hand's suit counts are packed as one number in base 6.
w = [6 ** (card // 13) for card in range(52)]
tally = [0] * 6 ** 4
for a in range(48):
    for b in range(a + 1, 49):
        ab = w[a] + w[b]
        for d in range(b + 1, 50):
            abd = ab + w[d]
            for e in range(d + 1, 51):
                t = abd + w[e]
                for f in range(e + 1, 52):
                    tally[t + w[f]] += 1
shape_listed = {s: 0 for s in SHAPES}
for code in range(6 ** 4):
    if tally[code]:
        counts = sorted((code // 6 ** s % 6 for s in range(4)), reverse=True)
        shape_listed["-".join(str(x) for x in counts if x)] += tally[code]
listed_hands = sum(tally)
listed_sf = 0                            # straights inside one suit, ranks 0 = two ... 12 = ace
for r in [(p, q, u, v, x) for p in range(13) for q in range(p + 1, 13) for u in range(q + 1, 13)
          for v in range(u + 1, 13) for x in range(v + 1, 13)]:
    if r[4] - r[0] == 4 or r == (0, 1, 2, 3, 12):
        listed_sf += 4

# Road 4: deal a million hands, five swaps of a partial shuffle each.
rng, deck, deals, hits = SplitMix64(20260928), list(range(52)), 1_000_000, 0
for _ in range(deals):
    for i in range(5):
        j = i + rng.below(52 - i)
        deck[i], deck[j] = deck[j], deck[i]
    s = deck[0] // 13
    hits += all(deck[i] // 13 == s for i in range(1, 5))
p_sim = hits / deals
se = (p_sim * (1 - p_sim) / deals) ** 0.5

# The house example: two dice, 36 ordered pairs, against 11 sums taken as equal.
sevens = sum(1 for x in range(1, 7) for y in range(1, 7) if x + y == 7)

print(f"road 1, hands C(52, 5) = {hands:,}; one suit C(13, 5) = {falling(13, 5):,} / 120 = {choose(13, 5):,}; flushes 4 x {choose(13, 5):,} = {flush:,}")
print(f"P(five of one suit) = {flush:,} / {hands:,} = {p_flush:.7f}, about 1 in {hands / flush:.1f}")
print(f"less {straight_flush} straight flushes: {flush - straight_flush:,} / {hands:,} = {p_proper:.7f}, about 1 in {hands / (flush - straight_flush):.1f}")
print(f"road 2, ordered deals 52x51x50x49x48 = {ordered_all:,}; ordered flushes 52x12x11x10x9 = {ordered_flush:,}")
print(f"ordered ratio = {ordered_flush / ordered_all:.7f}; both counts / 5! = 120: {ordered_all // 120:,} and {ordered_flush // 120:,}")
print(f"road 3, hands listed one by one: {listed_hands:,}; five of one suit: {shape_listed['5']:,}; straight flushes: {listed_sf}")
print("shape, hands by formula, hands listed, percent of all hands")
for s in SHAPES:
    print(f"shape {s}, {shape_formula[s]:,}, {shape_listed[s]:,}, {100 * shape_listed[s] / hands:.3f}")
print(f"road 4, {deals:,} seeded deals: {hits:,} flushes, estimate {p_sim:.7f}, standard error {se:.7f}")
print(f"distance from road 1 in standard errors: {(p_sim - p_flush) / se:.2f}")
print(f"mistake 1, ordered top 4 x 13x12x11x10x9 = {4 * falling(13, 5):,} over unordered {hands:,} = {4 * falling(13, 5) / hands:.4f}")
print(f"mistake 2, each later card a fresh 1/4 chance: 0.25^4 = {0.25 ** 4:.8f}, {0.25 ** 4 / p_flush:.2f} times too big")
print(f"mistake 3, the {choose(8, 3)} suit patterns taken as equal: 4 / {choose(8, 3)} = {4 / choose(8, 3):.4f}")
print(f"mistake 4, two dice: 7 in {sevens} of 36 pairs = {sevens / 36:.4f}; 11 sums taken as equal gives {1 / 11:.4f}")
assert listed_hands == hands and shape_listed["5"] == flush         # listing agrees with C(n, k)
assert shape_listed == shape_formula and listed_sf == straight_flush
assert ordered_flush * hands == flush * ordered_all                 # the two ratios are equal
assert abs(p_sim - p_flush) < 4 * se                                # simulation within 4 errors
assert sevens == min(7 - 1, 13 - 7) and choose(8, 3) == sum(1 for p in range(6) for q in range(6) for u in range(6)
                                           if p + q + u <= 5)       # 56 patterns, counted twice
print("ALL CHECKS PASS")
