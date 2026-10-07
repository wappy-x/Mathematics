# Connected or not -- the check behind the card.  Nothing is imported.  A town's cycle paths: nine
# junctions, S the station and A to H the rest; the river bridge D-F is shut, leaving ten paths.  Steps
# and pieces are found twice, by roads sharing no arithmetic: a flood ring by ring, and every route listed.
NAMES = "SABCDEFGH"
OPEN = [("S", "A"), ("S", "B"), ("A", "B"), ("A", "C"), ("B", "D"), ("C", "D"),
        ("C", "E"), ("D", "E"), ("D", "F"), ("F", "G"), ("G", "H")]
SHUT = [e for e in OPEN if e != ("D", "F")]           # the bridge shuts
def adj(edges):                                       # neighbours, both ways, sorted
    out = {v: [] for v in NAMES}
    for u, v in edges: out[u].append(v); out[v].append(u)
    return {v: sorted(ns) for v, ns in out.items()}
def flood(edges, start):                              # road one: a queue, ring by ring
    nb, queue, joins, dist = adj(edges), [start], 1, {v: 0 if v == start else -1 for v in NAMES}
    while queue:
        v = queue.pop(0)
        for w in nb[v]:
            if dist[w] < 0: dist[w] = dist[v] + 1; queue.append(w); joins += 1
    return dist, joins
def routes(edges, here, goal, seen=()):               # road two: every route, listed out
    seen = seen + (here,)
    if here == goal: yield seen; return
    for w in adj(edges)[here]:
        if w not in seen: yield from routes(edges, w, goal, seen)
def dive(edges, v, depth, deep, order):               # depth-first: dive and backtrack
    deep[v] = depth; order.append(v)
    for w in adj(edges)[v]:
        if w not in deep: dive(edges, w, depth + 1, deep, order)
def blocks(edges):                                    # a fresh flood at each unreached junction
    out, seen = [], set()
    for v in NAMES:
        if v in seen: continue
        d = flood(edges, v)[0]; r = [w for w in NAMES if d[w] >= 0]; out.append(r); seen |= set(r)
    return out
def show(d): return ", ".join(f"{v} {d[v] if d[v] >= 0 else 'none'}" for v in NAMES)

near, joins = flood(SHUT, "S")
parts, open_d = blocks(SHUT), flood(OPEN, "S")[0]
listed = {v: min((len(r) - 1 for r in routes(SHUT, "S", v)), default=-1) for v in NAMES}
deep, order = {}, []; dive(SHUT, "S", 0, deep, order)
to_e = sorted(routes(SHUT, "S", "E"), key=len)
inside = [e for e in SHUT if e[0] in parts[0] and e[1] in parts[0]]
print(f"town after the bridge D-F shuts: {len(NAMES)} junctions, {len(SHUT)} paths")
for k in range(5): print(f"  ring {k} from S: {' '.join(sorted(v for v in NAMES if near[v] == k)) or '(nothing new: it halts)'}")
print(f"steps from S, flooded:        {show(near)}")
print(f"the same, every route listed: {show(listed)}")
print(f"S to E: {len(to_e)} routes exist, the shortest is {'-'.join(to_e[0])} at {len(to_e[0]) - 1} steps")
print(f"pieces, a fresh flood at each unreached junction: {' | '.join(' '.join(p) for p in parts)}, "
      f"sizes {len(parts[0])} and {len(parts[1])}")
print(f"the station's piece holds {len(inside)} of the {len(SHUT)} paths, the other {len(SHUT) - len(inside)} "
      f"joining F G H; work: {joins} queue places, {len(inside)} paths seen twice = {2 * len(inside)}")
print(f"depth-first from S: order {' '.join(order)}, the same {len(order)} junctions, E at depth {deep['E']}, where the flood says {near['E']}")
print(f"bridge open again: {len(OPEN)} paths, {len(blocks(OPEN))} piece, steps to F G H = "
      f"{open_d['F']} {open_d['G']} {open_d['H']}, so H is {open_d['H']} steps off, not none")
print(f"one flood only, no fresh start: 1 piece of {len(parts[0])}, not {len(parts)} pieces sized {len(parts[0])} and {len(parts[1])}")
assert near == listed                                          # two roads, every step count
assert [len(p) for p in parts] == [6, 3] and set(parts[0]) == {v for v in NAMES if listed[v] >= 0}
assert order == list("SABDCE") and deep["E"] == 5 and near["E"] == 3
assert open_d == {"S": 0, "A": 1, "B": 1, "C": 2, "D": 2, "E": 3, "F": 3, "G": 4, "H": 5} and joins == 6
print("ALL CHECKS PASS")
