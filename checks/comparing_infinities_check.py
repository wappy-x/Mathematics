# Comparing infinities -- the check behind the card.  Nothing is imported.
# Part one: a four-room hotel and its sixteen guest lists.  Part two: the
# points of a segment and of a square, written out to four decimal digits.
ROOMS = [1, 2, 3, 4]
LISTS = [tuple(r for r in ROOMS if n // 2 ** (r - 1) % 2) for n in range(16)]
SAMPLE = {1: (1, 2), 2: (1, 3, 4), 3: (), 4: (2, 4)}
def show(lst): return "{" + ",".join(str(r) for r in lst) + "}"
def diagonal(a): return tuple(r for r in ROOMS if r not in a[r])   # left off its own list
def row(name, value): print(f"{name:<38}{value:>7}")
row("rooms in the hotel", len(ROOMS))
row("possible guest lists, all different", len(set(LISTS)))
row("the sample assignment", " ".join(f"{r}:{show(SAMPLE[r])}" for r in ROOMS))
row("the guest list it misses", show(diagonal(SAMPLE)))
missed = 0
for n in range(16 ** 4):                     # every way to hand one list to each room
    a = {r: LISTS[n // 16 ** (r - 1) % 16] for r in ROOMS}
    missed += diagonal(a) not in a.values()
row("all ways to give one list to each room", 16 ** 4)
row("ways the diagonal list is still missed", missed)
sq = [(a, b) for a in range(100) for b in range(100)]
weave = {p: f"{p[0] // 10}{p[1] // 10}{p[0] % 10}{p[1] % 10}" for p in sq}  # square point to segment point
back = {p: (int(s[0] + s[2]), int(s[1] + s[3])) for p, s in weave.items()}  # and back again
row("square points, two digits per side", len(sq))
row("segment points, four digits", 10 * 10 * 10 * 10)
row("interleave into the segment, distinct", len(set(weave.values())))
row("each point comes back as itself", sum(p == q for p, q in back.items()))
assert diagonal(SAMPLE) == (2, 3) and diagonal(SAMPLE) not in SAMPLE.values()
assert missed == 16 ** 4 and len(set(LISTS)) == 16
assert len(set(weave.values())) == 10000 and all(p == q for p, q in back.items())
print("ALL CHECKS PASS")
