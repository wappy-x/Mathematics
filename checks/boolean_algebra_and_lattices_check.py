# Boolean algebra -- the check behind the card.  A porch light is on when (motion
# AND dark) OR override.  Road one evaluates that rule row by row; road two closes
# ideal switches and hunts for a live path.  The eight subsets of {a, b, c} are then
# ordered by inclusion, and meet and join are found twice: by search, and by set algebra.
from itertools import product

ROWS = list(product((0, 1), repeat=3))               # motion, dark, override
SUBSETS = [frozenset("abc"[i] for i in range(3) if k >> i & 1) for k in range(8)]
U = frozenset("abc")

def rule(m, d, o): return bool((m and d) or o)       # road one: the rule as written
def off_rule(m, d, o): return ((not m) or (not d)) and (not o)   # the off condition
def bits(flags): return sum(1 << i for i, f in enumerate(flags) if f)
def name(s): return "".join(sorted(s))
def lows(A, B): return [s for s in SUBSETS if s <= A and s <= B]
def ups(A, B): return [s for s in SUBSETS if A <= s and B <= s]
def show(m): return ", ".join("".join(map(str, ROWS[i])) for i in range(8) if m >> i & 1)

def switches(m, d, o):                               # road two: parallel pairs in series
    wires = [(0, 1, m), (0, 1, o), (1, 2, d), (1, 2, o)]
    live = {0}                                       # 0 the live rail, 2 the lamp
    for _ in wires:                                  # spread current along closed wires
        for a, b, closed in wires:
            if closed and a in live: live.add(b)
    return 2 in live

def extreme(cands, upper):     # the one candidate all the others sit below, or above
    hits = [s for s in cands if all((t <= s) if upper else (s <= t) for t in cands)]
    return hits[0] if len(hits) == 1 else None

on, net, off = [rule(*r) for r in ROWS], [switches(*r) for r in ROWS], [off_rule(*r) for r in ROWS]
for r, a, b, c in zip(ROWS, on, net, off):
    print(f"MDO={r[0]}{r[1]}{r[2]}: rule={int(a)} switches={int(b)} off={int(c)}")
print(f"light on in {sum(on)} of the {len(ROWS)} rows, off in {sum(off)}")
mM, mD, mO = [bits([r[k] for r in ROWS]) for k in range(3)]
on_set, off_set = (mM & mD) | mO, ((255 ^ mM) | (255 ^ mD)) & (255 ^ mO)
print(f"on rows from set algebra: {show(on_set)}; off rows from its complement: {show(off_set)}")
meets = [(extreme(lows(A, B), True), A & B) for A in SUBSETS for B in SUBSETS]
joins = [(extreme(ups(A, B), False), A | B) for A in SUBSETS for B in SUBSETS]
edges = sum(1 for A in SUBSETS for B in SUBSETS if A < B and len(B - A) == 1)
pairs = [(A, B) for i, A in enumerate(SUBSETS) for B in SUBSETS[i + 1:]]
comp, incomp = sum(1 for A, B in pairs if A <= B or B <= A), sum(1 for A, B in pairs if not (A <= B or B <= A))
print(f"subset cube of {{a, b, c}}: {len(SUBSETS)} vertices, {edges} upward edges; "
      f"meet and join agree on all {len(meets)} pairs")
print(f"order: {comp} of the {len(pairs)} pairs are comparable, {incomp} are not")
A, B = frozenset("ab"), frozenset("bc")
print(f"A=ab, B=bc: meet by search={name(extreme(lows(A, B), True))}, by intersection="
      f"{name(A & B)}; join by search={name(extreme(ups(A, B), False))}, by union={name(A | B)}")
print(f"complement in U=abc: of A=ab it is {name(U - A)}, of the empty set it is {name(U - frozenset())}")
xor_bad = [bool((m and d) ^ o) != on[i] for i, (m, d, o) in enumerate(ROWS)]
neg_bad = [(((not m) and (not d)) and (not o)) != off[i] for i, (m, d, o) in enumerate(ROWS)]
half_bad = [bool((m or o) and d) != on[i] for i, (m, d, o) in enumerate(ROWS)]
print(f"exclusive-or instead of OR: fails {sum(xor_bad)} of 8 rows, at MDO={show(bits(xor_bad))}")
print(f"NOT(M AND D) as (NOT M) AND (NOT D): fails {sum(neg_bad)} of 8 rows, at MDO={show(bits(neg_bad))}")
print(f"override dropped from the second bracket: fails {sum(half_bad)} of 8 rows, at MDO={show(bits(half_bad))}")
assert net == on and off == [not a for a in on]
assert on_set == bits(on) and off_set == 255 ^ on_set
assert all(s == i for s, i in meets) and all(s == u for s, u in joins) and edges == 3 * 2 ** 2
assert comp == 3 ** 3 - 2 ** 3 and incomp == (4 ** 3 - 2 * 3 ** 3 + 2 ** 3) // 2 and [sum(xor_bad), sum(neg_bad), sum(half_bad)] == [1, 2, 2]
print("ALL CHECKS PASS")
