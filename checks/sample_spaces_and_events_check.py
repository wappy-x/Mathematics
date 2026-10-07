# Sample spaces and events -- the check behind the card.  Nothing is imported.
# Two dice, first and second: the sample space is the 36 ordered pairs.
# An event is a subset.  Road 1 lists outcomes and tests each one.  Road 2
# stores each event as 36 on/off bits and combines events with bit operations.
# Road 3 rolls dice with a SplitMix64 generator written out here.
FACES = range(1, 7)
OMEGA = [(i, j) for i in FACES for j in FACES]          # first die i, second die j
FULL = (1 << 36) - 1

def bit(i, j):                           # outcome (i, j) -> its bit position
    return 6 * (i - 1) + (j - 1)

def mask(test):                          # road 2: an event as 36 bits
    m = 0
    for i, j in OMEGA:
        if test(i, j):
            m |= 1 << bit(i, j)
    return m

def ones(m):
    return bin(m).count("1")

def seven(i, j): return i + j == 7
def six(i, j): return i == 6 or j == 6
def double(i, j): return i == j

def show(outs):
    return " ".join(f"({i},{j})" for i, j in outs)

A = [w for w in OMEGA if seven(*w)]                      # road 1: listing
S = [w for w in OMEGA if six(*w)]
D = [w for w in OMEGA if double(*w)]
mA, mS, mD = mask(seven), mask(six), mask(double)
print(f"sample space: {len(OMEGA)} ordered pairs (first die, second die)")
print(f"A  total is 7     {len(A):2d} outcomes: {show(A)}")
print(f"S  a six shows    {len(S):2d} outcomes")
print(f"D  a double       {len(D):2d} outcomes")
partner = sum(1 for i in FACES if 1 <= 7 - i <= 6)       # one partner per first die
print(f"|A| by listing {len(A)}; by one partner per first die {partner}")
by_list = [sum(1 for i, j in OMEGA if i + j == s) for s in range(2, 13)]
by_rule = [6 - abs(s - 7) for s in range(2, 13)]
print("totals 2..12, by listing:     " + " ".join(str(c) for c in by_list))
print("totals 2..12, by 6 - |s - 7|: " + " ".join(str(c) for c in by_rule))
tot = [mask(lambda i, j, s=s: i + j == s) for s in range(2, 13)]
cover, overlap = 0, 0
for m in tot:
    overlap += ones(cover & m)
    cover |= m
print(f"the 11 total events cover {ones(cover)} outcomes and overlap in {overlap}")

AandS = [w for w in OMEGA if seven(*w) and six(*w)]
AorS = [w for w in OMEGA if seven(*w) or six(*w)]
notA = [w for w in OMEGA if not seven(*w)]
nor1 = [w for w in OMEGA if not (seven(*w) or six(*w))]
nor2 = [w for w in OMEGA if (not seven(*w)) and (not six(*w))]
print(f"A and S  listing {len(AandS):2d}, bits {ones(mA & mS):2d}: {show(AandS)}")
print(f"A or S   listing {len(AorS):2d}, bits {ones(mA | mS):2d}, "
      f"inclusion-exclusion {len(A)} + {len(S)} - {len(AandS)} = {len(A) + len(S) - len(AandS)}")
print(f"not A    listing {len(notA):2d}, bits {ones(FULL ^ mA):2d}")
print(f"A and D  listing {sum(1 for w in OMEGA if seven(*w) and double(*w)):2d}, bits {ones(mA & mD):2d}")
print(f"not (A or S) {len(nor1)}; (not A) and (not S) {len(nor2)}; "
      f"bits {ones(FULL ^ (mA | mS))} and {ones((FULL ^ mA) & (FULL ^ mS))}")
events = 1
for _ in OMEGA:
    events *= 2                          # each outcome is in or out
print(f"events on this space: 2^36 = {events}; largest bit pattern + 1 = {FULL + 1}")
split = [s for s, m in zip(range(2, 13), tot) if m & mS and m & (FULL ^ mS)]
print("totals that 'a six shows' splits: " + " ".join(str(s) for s in split))

state = 20260928                         # road 3: SplitMix64, seed stated
def next64():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return z ^ (z >> 31)

N = 100000
hit7 = hit34 = hit33 = hitS = 0
for _ in range(N):
    i, j = next64() % 6 + 1, next64() % 6 + 1
    hit7 += i + j == 7
    hit34 += (i, j) in ((3, 4), (4, 3))
    hit33 += (i, j) == (3, 3)
    hitS += i == 6 or j == 6
p7 = hit7 / N
se = (p7 * (1 - p7) / N) ** 0.5
print(f"simulation: {N} rolls, SplitMix64 seed 20260928")
print(f"  share with total 7   {p7:.6f}, standard error {se:.6f}")
print(f"  exact 6/36           {6 / 36:.6f}, {abs(p7 - 6 / 36) / se:.1f} standard errors away")
print(f"  share a six shows    {hitS / N:.6f}; exact 11/36 {11 / 36:.6f}")
print(f"  share a 3 and a 4    {hit34 / N:.6f}; share two 3s {hit33 / N:.6f}")
for name, wrong in (("11 totals, equally likely: 1/11", 1 / 11),
                    ("21 unordered pairs, equally likely: 3/21", 3 / 21)):
    print(f"mistake, {name} = {wrong:.6f}, {abs(p7 - wrong) / se:.1f} standard errors away")
print(f"mistake, A or S by adding: {len(A)} + {len(S)} = {len(A) + len(S)}, not {len(AorS)}")
print(f"mistake, a six shows as 6 + 6 = {6 + 6}, not {len(S)}: (6,6) counted twice")

xy = [(45 + 30 * i, 215 - 30 * j) for i, j in A]         # figure: to scale, 30 units a face
print("figure, total-7 dots: " + " ".join(f"({x},{y})" for x, y in xy))
print(f"figure, grid (60,20) to (240,200); a six shows: column x {45 + 30 * 6 - 15}..{45 + 30 * 6 + 15}, "
      f"row y {215 - 30 * 6 - 15}..{215 - 30 * 6 + 15}")

assert by_list == by_rule and len(A) == partner == 6                  # listing vs rule
assert ones(mA | mS) == len(AorS) == len(A) + len(S) - len(AandS) == 15
assert len(nor1) == ones((FULL ^ mA) & (FULL ^ mS)) == 21             # De Morgan, two roads
assert ones(cover) == 36 and overlap == 0 and events == FULL + 1
assert abs(p7 - 6 / 36) < 4 * se and abs(p7 - 1 / 11) > 20 * se      # simulation vs counts
print("ALL CHECKS PASS")
