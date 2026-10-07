# Normal subgroups and quotient groups -- the check behind the card.  No imports.
# Two collapses: the integers by the multiples of 12, giving the clock, and the 8 ways a
# square tile sits down, by its 4 turns.  A move is (r, f): r quarter turns, f = 1 if flipped.
def mul(a, b):                         # do b first, then a, as with functions
    return ((a[0] + (-1) ** a[1] * b[0]) % 4, a[1] ^ b[1])
def inv(a):                            # the move that undoes a
    return ((-(-1) ** a[1] * a[0]) % 4, a[1])
def pile_of(g, H):                     # the coset g * H, as a sorted tuple
    return tuple(sorted(mul(g, h) for h in H))
def act(a):                            # the tile again, as a map of the 4 corners
    return tuple((a[0] + (-1) ** a[1] * i) % 4 for i in range(4))
def multiple_of_12(d):                 # road one: no remainder operator at all
    d = -d if d < 0 else d
    while d >= 12: d -= 12
    return d == 0
back = lambda p: (p[1] - p[0]) % 4 == 3    # corners running backwards: the move flipped

W, G, Z24 = range(-24, 36), [(r, f) for r in range(4) for f in range(2)], range(24)
by_subtraction = sorted({tuple(b for b in W if multiple_of_12(a - b)) for a in W})
by_remainder = sorted({tuple(b for b in W if b % 12 == a % 12) for a in W})
print(f"integers -24 to 35 collapsed by the multiples of 12: {len(by_subtraction)} "
      f"piles by subtraction, {len(by_remainder)} by remainder")
print(f"15 and -9 read {15 % 12} and {-9 % 12} on the face; 7 plus 8 is pile {(7 + 8) % 12}")
TURNS, FLIPS = [(r, 0) for r in range(4)], [(0, 0), (0, 1)]
turns_normal = all(mul(mul(g, h), inv(g)) in TURNS for g in G for h in TURNS)
geometry = all(act(mul(a, b)) == tuple(act(a)[i] for i in act(b)) for a in G for b in G)
parity = all(back(act(mul(a, b))) == (back(act(a)) + back(act(b))) % 2 for a in G for b in G)
turn_piles = sorted({pile_of(g, TURNS) for g in G})
seats = {frozenset(mul(mul(g, a), inv(g)) for g in G) for a in G}
classes, inside = sorted(len(c) for c in seats), sorted(len(c) for c in seats if c <= set(TURNS))
print(f"tile moves {len(G)}, turns {len(TURNS)}: all {len(G) * len(TURNS)} conjugates of "
      f"a turn are turns {turns_normal}, piles {len(turn_piles)}")
print(f"the same 8 moves as corner maps: all {len(G) ** 2} products agree {geometry}; a "
      f"flip is the corners running backwards, and flips add mod 2 {parity}: the 2-clock")
print(f"classes of look-alike moves: {len(classes)}, by size {classes}; the turns are "
      f"whole classes {inside} adding to {sum(inside)}")
quarter, flip, half = (1, 0), (0, 1), (2, 0)
conj, same = mul(mul(quarter, flip), inv(quarter)), mul(mul(half, flip), inv(half))
one, two = pile_of(quarter, FLIPS), pile_of(mul(flip, quarter), FLIPS)
print(f"flip subgroup {FLIPS}, piles {len({pile_of(g, FLIPS) for g in G})}: a quarter turn "
      f"carries {flip} to {conj}, outside it; the half turn carries it to {same}, inside")
print(f"one pile, two names, each times a quarter turn: {list(one)} and {list(two)}")
ker, image = [x for x in Z24 if x % 12 == 0], sorted({x % 12 for x in Z24})
kernel_pile = lambda x: tuple(sorted((x + k) % 24 for k in ker))
labels = {p: p[0] % 12 for p in sorted({kernel_pile(x) for x in Z24})}
onto = sorted(labels.values()) == image
keeps = all(labels[kernel_pile(x + y)] == (x % 12 + y % 12) % 12 for x in Z24 for y in Z24)
print(f"24-clock under x -> x mod 12: 13 reads {13 % 12}; kernel {ker} of {len(ker)}; "
      f"piles {len(labels)}; {len(Z24)} / {len(ker)} = {len(Z24) // len(ker)}; image {len(image)}")
print(f"pile to value is one-to-one and onto the image {onto}, and keeps addition on "
      f"all {len(Z24) ** 2} pairs {keeps}")
whole = {tuple(sorted((x + k) % 24 for k in Z24)) for x in Z24}
print(f"the four mistakes: {len({one, two})} answers for one product, {len(G)} members "
      f"counted instead of {len(turn_piles)} piles, a flip subgroup passing a half-turn-only "
      f"test ({same in FLIPS}), and {len(whole)} pile against an image of {len(image)}")
assert by_subtraction == by_remainder and len(by_subtraction) == 12
assert turns_normal and geometry and parity and len(turn_piles) == 2 and inside == [1, 1, 2]
assert conj == (2, 1) and conj not in FLIPS and same == flip and one != two
assert len(labels) == len(Z24) // len(ker) == len(image) == 12 and onto and keeps
print("ALL CHECKS PASS")
