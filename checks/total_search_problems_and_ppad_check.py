# Total search problems and PPAD -- the check behind the card.  Standard library only.
# A Sperner triangle cut into 16 small triangles is walked door by door and scanned;
# every legal colouring is counted; a staff-hours collision and a shift-swap game follow.
M = 4                                       # each side of the big triangle has 4 steps
V = [(a, b) for b in range(M + 1) for a in range(M + 1 - b)]   # a: steps right, b: rows up
COL = dict(zip(V, (1, 2, 2, 2, 2, 1, 1, 1, 2, 3, 2, 2, 1, 3, 3)))   # the card's colouring
UP = [((a, b), (a + 1, b), (a, b + 1)) for b in range(M) for a in range(M - b)]
DOWN = [((a + 1, b), (a + 1, b + 1), (a, b + 1)) for b in range(M - 1) for a in range(M - 1 - b)]
TRIS = UP + DOWN                            # 16 triangles, corners listed anticlockwise

def allowed(a, b):                          # Sperner's rule: a side uses only its corners' colours
    if (a, b) == (0, 0): return [1]
    if (a, b) == (M, 0): return [2]
    if (a, b) == (0, M): return [3]
    if b == 0: return [1, 2]
    if a == 0: return [1, 3]
    if a + b == M: return [2, 3]
    return [1, 2, 3]

def scan(col):                              # road one: look at all 16 triangles
    found = []
    for t in TRIS:
        cs = [col[v] for v in t]
        if sorted(cs) == [1, 2, 3]:         # +1 if 1, 2, 3 run anticlockwise, -1 if clockwise
            found.append((t, 1 if cs in ([1, 2, 3], [2, 3, 1], [3, 1, 2]) else -1))
    return found

def exit_door(t, col):                      # the edge whose colours run 2 then 1 anticlockwise
    for i in range(3):
        if (col[t[i]], col[t[(i + 1) % 3]]) == (2, 1):
            return frozenset((t[i], t[(i + 1) % 3]))
    return None                             # none: a 1, 2, 3 anticlockwise triangle, a sink

def walk(col, start):                       # road two: follow doors one triangle at a time
    path = [start]
    while True:
        door = exit_door(path[-1], col)
        if door is None: return path, "inside"
        nxt = [t for t in TRIS if door <= set(t) and t != path[-1]]
        if not nxt: return path, "outside"
        path.append(nxt[0])

def sperner_report(col, name):
    doors = [a for a in range(M) if {col[(a, 0)], col[(a + 1, 0)]} == {1, 2}]
    entry = [t for t in UP if t[0] == (doors[0], 0)][0]
    path, how = walk(col, entry)
    print(f"{name}: bottom-side doors {len(doors)}, first at a = {doors[0]} to {doors[0] + 1}")
    print(f"{name}: walk visits {len(path)} triangles, ends {how}, last {list(path[-1])}")
    print(f"{name}: colours along the walk " + " ".join("".join(str(col[v]) for v in t) for t in path))
    return path, how

path, how = sperner_report(COL, "card")
found = scan(COL)
print(f"scan of 16 triangles: {len(found)} three-coloured, signs {[s for _, s in found]}, sum {sum(s for _, s in found)}")
for t, s in found:
    print(f"  three-coloured {list(t)} sign {s:+d}")
src = [t for t, s in found if s == -1][0]
p2, how2 = walk(COL, src)
print(f"walk from the inside source ends {how2} after {len(p2)} triangles at {list(p2[-1])}")
assert how == "inside" and path[-1] in [t for t, _ in found]     # walk lands on a scan find
assert how2 == "inside" and p2[-1] != path[-1]
assert all(COL[v] in allowed(*v) for v in V) and len(found) == 3 and sum(s for _, s in found) == 1

opts = [allowed(*v) for v in V]
def every(opts):                            # road three: every colouring, odometer style
    idx = [0] * len(opts)
    while True:
        yield {v: o[i] for v, o, i in zip(V, opts, idx)}
        k = 0
        while k < len(idx) and idx[k] == len(opts[k]) - 1:
            idx[k] = 0; k += 1
        if k == len(idx): return
        idx[k] += 1
tally, total, signed_ok = {}, 0, True
for col in every(opts):
    f = scan(col)
    tally[len(f)] = tally.get(len(f), 0) + 1
    total += 1
    signed_ok = signed_ok and sum(s for _, s in f) == 1
print(f"legal colourings {total}; three-coloured counts " + ", ".join(f"{k}: {tally[k]}" for k in sorted(tally)))
print(f"every legal colouring: count odd {'yes' if all(k % 2 for k in tally) else 'no'}, signed sum 1 {'yes' if signed_ok else 'no'}")
assert total == 2 ** 9 * 3 ** 3 and all(k % 2 == 1 for k in tally) and signed_ok

bad = [o if v != (0, M) else [2] for v, o in zip(V, opts)]  # rule broken: top corner coloured 2
nb = [not scan(col) for col in every(bad)]   # one entry per colouring: True if it has none
none = sum(nb)
broken = dict(COL); broken[(0, M)] = 2
print(f"top corner coloured 2: {none} of {len(nb)} colourings have none; the card's colouring then has {len(scan(broken))}")
three = dict(COL); three[(2, 0)] = 1                 # bottom 1,2,1,2,2: three doors
p3, how3 = sperner_report(three, "three doors")
assert none > 0 and len(nb) == total and how3 == "outside"

for n in (8, 12, 16):                       # a line of 2^n nodes named by n bits (Gray code)
    node, steps = 0, 0
    while True:
        i, g = node, node >> 1
        while g: i ^= g; g >>= 1             # decode the Gray name to a position
        if i == 2 ** n - 1: break
        node = (i + 1) ^ ((i + 1) >> 1)      # successor: next position, re-encoded
        steps += 1
    print(f"line of {n}-bit nodes walked: {steps} steps; 2^{n} - 1 = {2 ** n - 1}")
    assert steps == 2 ** n - 1
print(f"a 40-bit line: up to {2 ** 40 - 1:,} steps")

HOURS = [38, 12, 25, 40, 16, 33, 21, 45, 8, 29]     # ten staff, weekly hours, each at most 48
seen, pair = {}, None
for mask in range(2 ** len(HOURS)):
    s = sum(h for j, h in enumerate(HOURS) if mask >> j & 1)
    if s in seen: pair = (seen[s], mask); break
    seen[s] = mask
common = pair[0] & pair[1]
g1, g2 = [[HOURS[j] for j in range(10) if (m & ~common) >> j & 1] for m in pair]
print(f"staff groups {2 ** 10}; hours each at most 48, so totals 0 to {10 * 48}: {10 * 48 + 1} values; after {pair[1] + 1} groups: {g1} and {g2}, both {sum(g1)} hours")
assert sum(g1) == sum(g2) and not set(g1) & set(g2) and g1 != g2

A = {("E", "E"): 2, ("E", "L"): 0, ("L", "E"): 0, ("L", "L"): 1}   # rows: A's shift, cols: B's
B = {("E", "E"): 1, ("E", "L"): 0, ("L", "E"): 0, ("L", "L"): 2}
pn, pd = B["L", "L"] - B["L", "E"], B["E", "E"] - B["L", "E"] - B["E", "L"] + B["L", "L"]
rn, rd = A["L", "L"] - A["E", "L"], A["E", "E"] - A["E", "L"] - A["L", "E"] + A["L", "L"]
print(f"formula: A takes Early with chance {pn}/{pd}, B takes Early with chance {rn}/{rd}, Late {rd - rn}/{rd}")
eqs = []
for k in range(61):                         # road two: every pair of chances in steps of 1/60
    for l in range(61):
        pr, pc = (k, 60 - k), (l, 60 - l)    # (Early, Late) weights, out of 60
        uA = [sum(A[s, t] * w for t, w in zip("EL", pc)) for s in "EL"]   # A's pure payoffs x60
        uB = [sum(B[s, t] * w for s, w in zip("EL", pr)) for t in "EL"]
        if (k * uA[0] + (60 - k) * uA[1] == 60 * max(uA) and l * uB[0] + (60 - l) * uB[1] == 60 * max(uB)):
            eqs.append((k, l, (k * uA[0] + (60 - k) * uA[1]), (l * uB[0] + (60 - l) * uB[1])))
for k, l, a, b in eqs:
    print(f"equilibrium: A Early {k}/60, B Early {l}/60; payoffs A {a / 3600:.4f}, B {b / 3600:.4f}")
print(f"equilibria found by search: {len(eqs)} (odd)")
assert [(k, l) for k, l, _, _ in eqs] == [(0, 0), (40, 20), (60, 60)]
assert eqs[1][0] * pd == 60 * pn and eqs[1][1] * rd == 60 * rn   # formula meets search
own = (A["L", "L"] - A["L", "E"], A["E", "E"] - A["L", "E"] - A["E", "L"] + A["L", "L"])
print(f"wrong: A's mix from A's own payoffs, Early {own[0]}/{own[1]}; B then gets Early {B['E', 'E'] * own[0]}/{own[1]}, Late {B['L', 'L'] * (own[1] - own[0])}/{own[1]}")
print(f"figure, side 320 px, corners (40, 330) (360, 330) (200, {330 - 160 * 3 ** 0.5:.2f}); walk {len(path)} triangles")
print("ALL CHECKS PASS")
