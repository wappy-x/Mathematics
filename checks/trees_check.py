# Trees -- the check behind the card.  Nothing is imported.  The village: seven houses A to G and
# the six lanes A-B B-C B-D D-E D-F F-G.  Every claim is reached by two roads sharing no arithmetic:
# routes listed out one pair at a time, and a flood plus repeated peeling of one-lane houses.  The
# census at the end runs the same four descriptions over all 1024 lane maps on five houses.
NAMES, LANES = "ABCDEFG", [(0, 1), (1, 2), (1, 3), (3, 4), (3, 5), (5, 6)]
TRAP = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 6)]       # 6 lanes, a loop of 3, two pieces
def nbrs(n, es): return {v: sorted(w for e in es for w in e if v in e and w != v) for v in range(n)}
def routes(nb, u, goal, seen=()):             # road one: every route from u to goal repeating no house
    if u == goal: return [seen + (u,)]
    return [r for w in nb[u] if w not in seen + (u,) for r in routes(nb, w, goal, seen + (u,))]
def piece(nb, s):                             # road two: the houses a flood from s reaches
    block, more = set(), {s}
    while more: block |= more; more = {w for v in block for w in nb[v]} - block
    return tuple(sorted(block))
def pieces(n, es): nb = nbrs(n, es); return sorted({piece(nb, s) for s in range(n)})
def peel(n, es):                              # road two: strip off a house with one lane, and again
    left, rest, trail = list(range(n)), sorted(tuple(sorted(e)) for e in es), [(n, len(es))]
    while (ones := [v for v in left if sum(v in e for e in rest) == 1]):
        left.remove(ones[0]); rest = [e for e in rest if ones[0] not in e]; trail.append((len(left), len(rest)))
    return left, rest, trail
def pairs(n): return [(u, v) for u in range(n) for v in range(u + 1, n)]
def gaps(n, es): return [p for p in pairs(n) if p not in [tuple(sorted(e)) for e in es]]
def cut(n, es, e): return pieces(n, [f for f in es if f != e])
def one_each(n, es): nb = nbrs(n, es); return all(len(routes(nb, u, v)) == 1 for u, v in pairs(n))
def strand(n, es): return [e for e in es if len(cut(n, es, e)) > len(pieces(n, es))]
def choose(a, b): return 1 if b in (0, a) else choose(a - 1, b - 1) + choose(a - 1, b)  # Pascal's rule
def ln(e): return NAMES[e[0]] + "-" + NAMES[e[1]]

N, NB, miss = 7, nbrs(7, LANES), gaps(7, LANES)
counts, deg = [len(routes(NB, u, v)) for u, v in pairs(N)], [len(NB[v]) for v in range(N)]
blocks, (left, rest, trail) = pieces(N, LANES), peel(N, LANES)
cuts = [(ln(e), [len(b) for b in cut(N, LANES, e)]) for e in LANES]
closed = [(e, r) for e in miss for r in [routes(NB, e[0], e[1])[0]] for p in [peel(N, LANES + [e])] if sorted(p[0]) == sorted(r) and len(p[1]) == len(r)]
ring = next(r for e, r in closed if e == (0, 6))
f1, f2 = cut(N, LANES, (1, 3)), pieces(N, [f for f in LANES if f not in ((1, 3), (3, 5))])
maps = [[p for i, p in enumerate(pairs(5)) if mask >> i & 1] for mask in range(1 << 10)]   # every lane map on 5 houses
flags = [(len(pieces(5, es)) == 1, not peel(5, es)[1], len(es) == 4, one_each(5, es)) for es in maps]
sets = [[m for m, (w, lf, f, o) in zip(maps, flags) if t(w, lf, f, o)] for t in (lambda w, lf, f, o: w and lf,
        lambda w, lf, f, o: o, lambda w, lf, f, o: w and f, lambda w, lf, f, o: lf and f)]
four, same = sum(len(m) == 4 for m in maps), all(s == sets[0] for s in sets)

rows = [("seven houses A to G, the six lanes", f"{' '.join(ln(e) for e in LANES)}: {len(LANES)} lanes, {N} houses, one fewer"),
        ("routes listed out, one pair at a time", f"{len(counts)} pairs, fewest {min(counts)} route, most {max(counts)} route"),
        ("flood from A, then peel one-lane houses", f"{len(blocks)} piece of {len(blocks[0])}, peeled to {len(left)} house and {len(rest)} lanes"),
        ("houses and lanes down the peeling", " ".join(f"{h}-{m}" for h, m in trail)),
        ("degrees A to G, their sum, the leaves", f"{' '.join(str(d) for d in deg)}, sum {sum(deg)} = 2 x {len(LANES)} lanes, leaves {' '.join(NAMES[v] for v in range(N) if deg[v] == 1)}"),
        ("cut one lane, pieces left, A's side first", ", ".join(f"{a} {b[0]}+{b[1]}" for a, b in cuts)),
        ("lanes whose loss strands someone", f"{len(strand(N, LANES))} of {len(LANES)}, each cut leaving 2 pieces and {len(LANES) - 1} lanes = {N} - 2"),
        (f"add one of the {len(miss)} missing lanes", f"{len(closed)} of {len(miss)} close exactly one loop"),
        (f"A-G closes the loop {' '.join(NAMES[v] for v in ring)}", f"{len(ring)} houses, {len(ring)} lanes; now only {len(strand(N, LANES + [(0, 6)]))} of {len(LANES) + 1} lanes strand someone"),
        ("trap: triangle A-B-C beside path D-E-F-G", f"{len(TRAP)} lanes = {N} - 1, {len(pieces(N, TRAP))} pieces, a loop of {len(peel(N, TRAP)[1])}"),
        ("forest: cut B-D, then D-F as well", f"{len(f1)} pieces sized {len(f1[0])} and {len(f1[1])}, {len(LANES) - 1} lanes = {N} - 2; then {len(f2)} pieces, {len(LANES) - 2} lanes = {N} - 3"),
        (f"five houses, all {len(maps)} lane maps", f"connected and loop-free {len(sets[0])}, one route per pair {len(sets[1])}, connected with 4 lanes {len(sets[2])}, loop-free with 4 lanes {len(sets[3])}"),
        ("the four descriptions pick the same maps", f"{'yes' if same else 'no'}, {len(sets[0])} of them; {four} maps use 4 lanes, {four - len(sets[0])} of those not trees")]
for a, b in rows: print(f"{a:<46}{b}")
assert min(counts) == max(counts) == 1 and len(blocks) == 1 and (len(left), len(rest)) == (1, 0)
assert trail == [(7, 6), (6, 5), (5, 4), (4, 3), (3, 2), (2, 1), (1, 0)] and sum(deg) == 2 * len(LANES) and (len(pieces(N, TRAP)), len(peel(N, TRAP)[1]), len(f2)) == (2, 3, 3)
assert [b for _, b in cuts] == [[1, 6], [6, 1], [3, 4], [6, 1], [5, 2], [6, 1]] and len(closed) == len(miss) == 15 and (len(strand(N, LANES)), len(strand(N, LANES + [(0, 6)]))) == (6, 2)
assert same and len(sets[0]) == 125 and four == choose(10, 4) == 210
print("ALL CHECKS PASS")
