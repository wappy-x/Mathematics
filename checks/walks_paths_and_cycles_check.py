# Walks, paths and cycles -- the check behind the card.  Nothing is imported.  The
# graph is the metro map: stations A to F, the lines A-B B-C C-D D-E E-F F-A and the
# crossings B-E and C-F.  Distance and the shortest loop are each found twice, by
# roads sharing no arithmetic: listing every repeat-free route, and sweeping outward.
NAMES, INF = "ABCDEF", 99
EDGES = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]
def nbrs(edges):                           # the stations one line away from each station
    return {v: sorted(w for e in edges for w in e if v in e and w != v) for v in range(6)}
def routes(nb, u, v, seen=()):             # road one: every route u to v repeating no station
    seen = seen + (u,)
    if u == v:
        return [seen]
    return [r for w in nb[u] if w not in seen for r in routes(nb, w, v, seen)]
def sweep(nb, s):                          # road two: what lies 0, 1, 2 ... steps from s
    dist, front, step = {s: 0}, [s], 0
    while front:
        step += 1
        front = sorted({w for u in front for w in nb[u] if w not in dist})
        dist.update({w: step for w in front})
    return [dist.get(v, INF) for v in range(6)]
def name(p): return "-".join(NAMES[v] for v in p)
NB = nbrs(EDGES)
allr = [p for u in range(6) for v in range(6) for p in routes(NB, u, v)]
listed = [[min(len(p) - 1 for p in allr if (p[0], p[-1]) == (u, v)) for v in range(6)] for u in range(6)]
swept = [sweep(NB, u) for u in range(6)]
ecc = [max(r) for r in swept]
diam, rad = max(ecc), min(ecc)
centre = " ".join(NAMES[v] for v in range(6) if ecc[v] == rad)
rim = " and ".join(NAMES[v] for v in range(6) if ecc[v] == diam)
best = sorted(name(p) for p in allr if (p[0], p[-1]) == (0, 3) and len(p) - 1 == swept[0][3])
longest = max(len(p) - 1 for p in allr)
long_name = sorted(name(p) for p in allr if len(p) - 1 == longest)[0]
walk = (0, 1, 0, 1, 2, 3)                  # A-B-A-B-C-D, a walk that doubles back
cut = walk[:1] + walk[3:]                  # drop the stretch between the two B's
cut_ok = all(frozenset(p) in [frozenset(e) for e in EDGES] for p in zip(cut, cut[1:]))
tri_ok = all(swept[u][w] <= swept[u][v] + swept[v][w] for u in range(6) for v in range(6) for w in range(6))
loops = [p for u, v in EDGES + [(v, u) for u, v in EDGES] for p in routes(NB, u, v) if len(p) >= 3]
girth = min(len(p) for p in loops)
loop_name = sorted(name(p + p[:1]) for p in loops if len(p) == girth)[0]
girth_cut = min(1 + sweep(nbrs([f for f in EDGES if f != e]), e[0])[e[1]] for e in EDGES)
print(f"metro: 6 stations, {len(EDGES)} lines; steps from station to station, worst case at the end")
print("     " + "".join(f"{NAMES[v]:>3}" for v in range(6)) + f"{'worst':>8}")
for u in range(6):
    print(f"{NAMES[u]:>4} " + "".join(f"{d:>3}" for d in swept[u]) + f"{ecc[u]:>8}")
print(f"radius {rad} at {centre}; diameter {diam}, reached only by {rim}")
print(f"the same table by listing every repeat-free route: {'yes' if listed == swept else 'no'}")
print(f"{len(best)} shortest A to D routes, {swept[0][3]} steps each: {', '.join(best)}")
print(f"the walk {name(walk)} takes {len(walk) - 1} steps; cut the stretch between the two B's and "
      f"{name(cut)} is left, {len(cut) - 1} steps, every pair a line: {'yes' if cut_ok else 'no'}")
print(f"triangle rule over all {6 ** 3} ordered triples: {'holds' if tri_ok else 'fails'}; "
      f"and radius {rad} <= diameter {diam} <= 2 x radius = {2 * rad}")
print(f"shortest loop {girth} stations, {loop_name}; by cutting each line and re-measuring its ends: {girth_cut}")
print(f"mistake 1, stations counted instead of steps: A to D reads {swept[0][3] + 1}, not {swept[0][3]}")
print(f"mistake 2, longest repeat-free route read as the diameter: {longest} steps, {long_name}, not {diam}")
print(f"mistake 3, a doubling-back loop allowed: B-C-B closes in {2 * swept[1][2]} steps, not {girth}")
assert listed == swept
assert ecc == [3, 2, 2, 3, 2, 2] and diam == 3 and rad == 2 and centre == "B C E F"
assert tri_ok and cut_ok and len(cut) - 1 == swept[0][3] and rad <= diam <= 2 * rad
assert girth == girth_cut == 4 and longest == 5 and len(best) == 4
print("ALL CHECKS PASS")
