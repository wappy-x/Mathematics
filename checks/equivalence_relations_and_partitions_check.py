# Equivalence relations and partitions -- the check behind the card.  Nothing is imported.  "Same reading on a 12-hour dial" on the 24 hours of a day, a sock drawer sorted into piles, and three rules that break.
HOURS, SOCKS, PILES = list(range(24)), list(range(9)), [[0, 1, 2, 3], [4, 5, 6], [7, 8]]; pile = {s: i for i, p in enumerate(PILES) for s in p}
def dial(h): return h - 12 if h >= 12 else h          # what a 12-hour face shows at hour h
def tests(rule, S):                                   # straight off the definitions: pairs, and triples for transitive
    return (all(rule(a, a) for a in S), all(rule(b, a) for a in S for b in S if rule(a, b)),
            all(rule(a, c) for a in S for b in S for c in S if rule(a, b) and rule(b, c)))
def blocks(rule, S): return sorted({tuple(b for b in S if rule(a, b)) for a in S})
def linked(rule, S): return sum(1 for a in S for b in S if rule(a, b))
def yn(t): return ", ".join(f"{n} {'yes' if v else 'no'}" for n, v in zip(("reflexive", "symmetric", "transitive"), t))
def fmt(bs): return ", ".join("{" + ", ".join(str(x) for x in b) + "}" for b in bs)
same, sockrule = (lambda a, b: dial(a) == dial(b)), (lambda a, b: pile[a] == pile[b])
B, PILE_TUPLES = blocks(same, HOURS), sorted(tuple(p) for p in PILES)
inblock = lambda a, b: any(a in blk and b in blk for blk in B)      # second road: the blocks hand a rule back
loose, near, floor = (lambda a, b: same(a, b) and a != b), (lambda a, b: abs(dial(a) - dial(b)) <= 1), (lambda a, b: sockrule(a, b) and a != 8 and b != 8)
agree = all(same(a, b) == inblock(a, b) for a in HOURS for b in HOURS)
print(f"24 hours, {len(HOURS) * len(HOURS)} ordered pairs to ask about; hour 3 shows {dial(3)}, hour 15 shows {dial(15)}, hour 23 shows {dial(23)}")
print("same reading on a 12-hour dial: " + yn(tests(same, HOURS)))
print(f"{len(B)} blocks of {len(B[0])}: {fmt(B[:3])}, ... , {fmt(B[-1:])}")
print(f"linked ordered pairs: {len(B)} blocks x {len(B[0])} x {len(B[0])} = {linked(same, HOURS)}")
print(f"those blocks back to a rule, in the same block: {linked(inblock, HOURS)} pairs, agrees on all {len(HOURS) * len(HOURS)} pairs: {'yes' if agree else 'no'}")
print(f"sock drawer, {len(SOCKS)} socks in piles of 4, 3 and 2: " + yn(tests(sockrule, SOCKS)))
print(f"linked ordered pairs: 4 x 4 + 3 x 3 + 2 x 2 = {linked(sockrule, SOCKS)}")
print(f"that rule's blocks are the {len(PILES)} piles back again: {'yes' if blocks(sockrule, SOCKS) == PILE_TUPLES else 'no'}")
print(f"same reading, different hour: {linked(loose, HOURS)} pairs, " + yn(tests(loose, HOURS)) + "; hour 0 is not in its own block")
print(f"readings at most 1 apart, no wrap: {linked(near, HOURS)} pairs, " + yn(tests(near, HOURS)) + "; 2 with 3 and 3 with 4 but not 2 with 4")
print(f"a sock left on the floor: {linked(floor, SOCKS)} pairs, " + yn(tests(floor, SOCKS)) + "; that sock is in no pile")
assert tests(same, HOURS) == (True, True, True) and len(B) == 12 and B[0] == (0, 12) and B[11] == (11, 23) and linked(same, HOURS) == 48
assert agree and linked(inblock, HOURS) == sum(len(b) * len(b) for b in B) and linked(sockrule, SOCKS) == 4 * 4 + 3 * 3 + 2 * 2 and blocks(sockrule, SOCKS) == PILE_TUPLES
assert (linked(loose, HOURS), linked(near, HOURS), linked(floor, SOCKS)) == (24, 136, 26) and not loose(0, 0) and not floor(8, 8) and near(2, 3) and near(3, 4) and not near(2, 4) and (tests(loose, HOURS), tests(near, HOURS), tests(floor, SOCKS)) == ((False, True, False), (True, True, False), (False, True, True))
print("ALL CHECKS PASS")
