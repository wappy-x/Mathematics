# Five and four colour theorems -- the check behind the card.  Nothing is imported.  The
# map is 12 council wards: the centre A, the ring B C D E F round it, the outer ring G H
# I J K L.  Every ward's neighbours are listed both ways round, so the list checks itself.
# Four colours are reached three ways -- the six-colour peel run as a program, by hand in
# alphabetical order, and an exhaustive search that also settles three -- and then the
# five-colour proof's Kempe swap is run on the hard case, A's five neighbours in five colours.
MAP = {"A": "BCDEF", "B": "ACFGL", "C": "ABDGHI", "D": "ACEIJ", "E": "ADFJK", "F": "ABEKL",
       "G": "BCHL", "H": "CGI", "I": "CDHJ", "J": "DEIK", "K": "EFJL", "L": "BFGK"}
RING, OUT = "BCDEF", "GHIJKL"
def free(g, col, v, k):                     # the colours 1 to k no neighbour of v wears
    return [c for c in range(1, k + 1) if c not in {col.get(u) for u in g[v]}]
def proper(g, col):                         # no border with one colour on both sides
    return all(col[u] != col[v] for u in g for v in g[u] if u in col and v in col)
def greedy(g, order, col):                  # each ward in turn takes its lowest free colour
    col = dict(col)
    for v in order: col[v] = free(g, col, v, 9)[0]
    return col
def peel(g):                                # lift out the least busy ward, over and over
    left, out = dict(g), []
    while left:
        v = min(left, key=lambda u: (len(left[u]), u)); out.append(f"{v}{len(left[v])}")
        left = {a: left[a].replace(v, "") for a in left if a != v}
    return out
def count(g, k, col):                       # how many proper colourings with k colours
    rest = [v for v in g if v not in col]
    if not rest: return 1
    return sum(count(g, k, {**col, rest[0]: c}) for c in free(g, col, rest[0], k))
def chain(g, col, v, a, b):                 # the wards reached from v through colours a and b
    seen, stack = {v}, [v]
    while stack:
        for w in g[stack.pop()]:
            if w not in seen and col.get(w) in (a, b): seen.add(w); stack.append(w)
    return "".join(sorted(seen))
def swap(col, comp, a, b):                  # trade colours a and b all along one chain
    return {v: ({a: b, b: a}.get(c, c) if v in comp else c) for v, c in col.items()}
def show(col): return " ".join(f"{v}{col[v]}" for v in sorted(col))
def yn(c): return "yes" if c else "no"
DEG = {v: len(MAP[v]) for v in MAP}; V, E = len(MAP), sum(DEG.values()) // 2
peeled = peel(MAP); back = greedy(MAP, "".join(p[0] for p in reversed(peeled)), {})
hand, rev = greedy(MAP, "".join(sorted(MAP)), {}), greedy(MAP, "".join(sorted(MAP, reverse=True)), {})
counts = [count(MAP, k, {}) for k in (1, 2, 3, 4)]
hard = greedy(MAP, OUT, {v: i + 1 for i, v in enumerate(RING)})
kch, bad = chain(MAP, hard, "B", 1, 3), chain(MAP, hard, "B", 1, 2)
fixed, badfix = swap(hard, kch, 1, 3), swap(hard, bad, 1, 2)
five = {**fixed, "A": free(MAP, fixed, "A", 5)[0]}
print(f"the ward map: V = {V} wards, E = {E} borders, at most 3V - 6 = {3 * V - 6}; borders per ward {show(DEG)}, adding to {2 * E} = 2E, at most 6V - 12 = {6 * V - 12}, fewest {min(DEG.values())}, average {2 * E / V:.2f}")
print(f"road 1, lift out the least busy ward over and over: {' '.join(peeled)}; most borders at a lift {max(int(p[1:]) for p in peeled)}, the promise is 5\n  put them back in reverse, lowest free colour each time: {show(back)}, colours used {max(back.values())}, proper: {yn(proper(MAP, back))}")
print(f"road 2, by hand A to L, lowest free colour: {show(hand)}, colours used {max(hand.values())}, proper: {yn(proper(MAP, hand))}")
print(f"road 3, exhaustive: proper colourings with 1, 2, 3, 4 colours: {counts}; fewest colours that work {min(k for k in (1, 2, 3, 4) if counts[k - 1])}")
print(f"the hard case, A lifted out and its ring given five colours: {show(hard)}; colours free for A: {len(free(MAP, hard, 'A', 5))}\n  the {len(RING)} ring wards all bordering each other would need {len(RING) * (len(RING) - 1) // 2} lines, past the {3 * len(RING) - 6} a flat drawing on {len(RING)} dots allows")
print(f"  the 1-and-3 chain from B: {kch}; does it reach D, wearing 3: {yn('D' in kch)}\n  swap 1 and 3 along it: {show({v: fixed[v] for v in kch})}, whole map still proper: {yn(proper(MAP, fixed))}, colours free for A: {free(MAP, fixed, 'A', 5)}")
print(f"five colours over the whole map: {show(five)}, proper: {yn(proper(MAP, five))}, colours used {len(set(five.values()))}")
print(f"mistake 1, three colours on this map: {counts[2]} of {3 ** V} shadings proper\nmistake 2, the swap run on the neighbours B and C: the 1-and-2 chain {bad} takes C along, colours free for A still {len(free(MAP, badfix, 'A', 5))}")
print(f"mistake 3, colouring L back to A instead: {show(rev)}, colours used {max(rev.values())}")
assert min(DEG.values()) <= 5 and E <= 3 * V - 6 and all(v in MAP[u] for v in MAP for u in MAP[v])
assert proper(MAP, hand) and proper(MAP, back) and max(hand.values()) == 4 and counts[2] == 0 and counts[3] > 0
assert "D" not in kch and proper(MAP, fixed) and free(MAP, fixed, "A", 5) == [1] and proper(MAP, five) and len(set(five.values())) == 5
assert "C" in bad and free(MAP, badfix, "A", 5) == [] and max(rev.values()) == 5 and min(k for k in (1, 2, 3, 4) if counts[k - 1]) == max(hand.values())
print("ALL CHECKS PASS")
