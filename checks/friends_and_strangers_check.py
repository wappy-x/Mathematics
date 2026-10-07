# Friends and strangers -- the check behind the card.  Nothing is imported.  Six guests, every
# pair labelled acquainted (1) or strangers (0): all 32768 labellings are searched for a trio all
# alike, and the card's pigeonhole route must find one in each.  Then five guests in a ring.
NAMES = ["Ada", "Ben", "Cleo", "Dev", "Eve", "Finn"]
RING = [(0, 1), (1, 2), (2, 3), (3, 4), (0, 4)]        # five guests, each knows two

def pairs(n): return [(i, j) for i in range(n) for j in range(i + 1, n)]
def triples(n): return [(i, j, k) for (i, j) in pairs(n) for k in range(j + 1, n)]
def lab(col, idx, i, j): return (col >> idx[(min(i, j), max(i, j))]) & 1
def names(ps): return ", ".join(f"{NAMES[i]}-{NAMES[j]}" for (i, j) in ps)
def orders(xs): return [[x] + p for i, x in enumerate(xs) for p in orders(xs[:i] + xs[i + 1:])] or [[]]
def mono(col, idx, tris):                    # road one: scan every trio for one all alike
    return [t for t in tris if lab(col, idx, t[0], t[1])
            == lab(col, idx, t[0], t[2]) == lab(col, idx, t[1], t[2])]
def by_proof(col, idx, n):                   # road two: the card's pigeonhole route
    kinds = {w: [u for u in range(1, n) if lab(col, idx, 0, u) == w] for w in (0, 1)}
    if len(kinds[0]) < 3 and len(kinds[1]) < 3: return None
    a, b, c = kinds[w := 1 if len(kinds[1]) >= 3 else 0][:3]   # one kind holds three
    for (x, y) in ((a, b), (a, c), (b, c)):
        if lab(col, idx, x, y) == w: return tuple(sorted((0, x, y)))
    return (a, b, c)
def rings(n):                                # road two to the 12: every guest ring, as lines
    return {frozenset(frozenset((p[i], p[(i + 1) % n])) for i in range(n)) for p in orders(list(range(n)))}

P6, T6, P5, T5 = pairs(6), triples(6), pairs(5), triples(5)
I6, I5 = {p: t for t, p in enumerate(P6)}, {p: t for t, p in enumerate(P5)}
TX = [t for t in T6 if not (4 in t and 5 in t)]        # trios avoiding one dropped pair
counts, proved, agreed, dropped = [], 0, 0, 0
for col in range(1 << len(P6)):
    ms, w = mono(col, I6, T6), by_proof(col, I6, 6)
    counts.append(len(ms)); proved += w is not None; agreed += w in ms
    if not lab(col, I6, 4, 5) and not mono(col, I6, TX): dropped += 1
ring, free5 = sum(1 << I5[p] for p in RING), [c for c in range(1 << len(P5)) if not mono(c, I5, T5)]
blind = sum(by_proof(c, I5, 5) is None for c in free5)
teams = sum(1 << I6[(i, j)] for (i, j) in P6 if (i < 3) != (j < 3))
tmono = mono(teams, I6, T6)
friends = len([t for t in tmono if lab(teams, I6, t[0], t[1]) == 1])
hold, forced, R5 = sum(1 for c in counts if c), -(-5 // 2), rings(5)
esc, rings5, all6, all5 = sum(frozenset(frozenset(p) for p in P5 if lab(c, I5, *p)) in R5 for c in free5), len(R5), 1 << len(P6), 1 << len(P5)

print(f"six guests {', '.join(NAMES)}: pairs C(6,2) = {len(P6)}, labellings 2^{len(P6)} = {all6}, trios C(6,3) = {len(T6)}\n"
      f"one guest faces {len(NAMES) - 1} others; 5 relationships into 2 kinds, rounded up: {forced} alike; pairs among those three: {len(pairs(3))}")
print(f"all {all6} labellings searched: {hold} hold a trio all alike, {all6 - hold} do not\n"
      f"trios all alike in one labelling: fewest {min(counts)}, most {max(counts)}")
print(f"the pigeonhole route finds a trio in {proved} of {all6} labellings, and the search holds it every time: {agreed}")
print(f"five guests {', '.join(NAMES[:5])} in a ring, each knowing only the two beside them\n"
      f"acquainted: {names(RING)}\nstrangers: {names([p for p in P5 if p not in RING])}")
print(f"the {len(T5)} trios of five guests: {len(mono(ring, I5, T5))} all alike -- every trio mixes the two kinds\n"
      f"all {all5} labellings of five guests: {len(free5)} hold no trio at all\n"
      f"the same {len(free5)}, by counting five-guest rings: {len(orders(list(range(5))))} orders / (5 starts x 2 directions) = {rings5}; escapes that are rings: {esc}")
print(f"the route on five guests: among those {len(free5)}, no kind holds three, so it reports nothing {blind} times")
print(f"mistake 1, 5 into 2 kinds rounded down: {5 // 2}, not {forced}\n"
      f"mistake 2, five guests taken as enough: {len(free5)} of the {all5} labellings dodge a trio\n"
      f"mistake 3, two teams of three, every cross pair acquainted: {friends} trios of friends, {len(tmono) - friends} of strangers")
print(f"one pair left undecided: {dropped} of the {1 << (len(P6) - 1)} labellings of the other {len(P6) - 1} pairs hold no trio")
assert hold == all6 and min(counts) == 2 and max(counts) == len(T6)
assert proved == agreed == all6
assert len(free5) == rings5 == esc == 12 and blind == len(free5) and not mono(ring, I5, T5)
assert friends == 0 and len(tmono) == 2 and dropped == 12
print("ALL CHECKS PASS")
