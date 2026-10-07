# Bipartite graphs -- the check behind the card.  Nothing is imported.  The roster joins 5
# workers to the 4 shifts they can cover; the cafes are 5 rivals in a ring.  "Does it split
# in two?" is answered twice: BFS layers by parity of steps, and trying every cut of the dots.
ROSTER = ("Ana Ben Cleo Dan Eve Mon-am Mon-pm Tue-am Tue-pm".split(),
          [(0, 5), (0, 6), (1, 5), (1, 7), (2, 6), (2, 8), (3, 7), (3, 8), (4, 5)])
CAFES = ("Bean Crema Drip Grind Latte".split(), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)])
METRO = (list("ABCDEF"), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)])
COVER = (ROSTER[0], ROSTER[1] + [(0, 1)])          # Ana covers Ben: a line inside a side
BOTH = (ROSTER[0] + CAFES[0], ROSTER[1] + [(u + 9, v + 9) for u, v in CAFES[1]])
def adj(names, edges):                             # who is joined to whom
    a = [[] for _ in names]
    for u, v in edges: a[u].append(v); a[v].append(u)
    return a
def layers(names, edges):                          # road one: BFS, colour = parity of steps out
    a, dist, parent = adj(names, edges), [-1] * len(names), [-1] * len(names)
    for root in range(len(names)):                 # every component gets its own root
        if dist[root] >= 0: continue
        dist[root], queue = 0, [root]
        while queue:
            v = queue.pop(0)
            for w in [w for w in a[v] if dist[w] < 0]: dist[w], parent[w] = dist[v] + 1, v; queue.append(w)
    clash = next(((u, v) for u, v in edges if dist[u] % 2 == dist[v] % 2), None)
    return dist, parent, clash
def odd_loop(parent, clash):                       # the clash line, plus both routes to the root
    def route(x, out=()):
        return route(parent[x], out + (x,)) if x >= 0 else list(out)
    ru, rv = route(clash[0]), route(clash[1])
    meet = next(x for x in ru if x in rv)          # the last dot the two routes share
    return ru[:ru.index(meet) + 1] + rv[:rv.index(meet)][::-1]
real = lambda a, c: len(set(c)) == len(c) >= 3 and all(c[(i + 1) % len(c)] in a[c[i]] for i in range(len(c)))
def cuts(names, edges):                            # road two: try every cut of the dots in two
    ok = [m for m in range(1 << len(names)) if all((m >> u & 1) != (m >> v & 1) for u, v in edges)]
    return len(ok), (ok[0] if ok else 0)
show = lambda names, keep: " ".join(n for i, n in enumerate(names) if keep(i))
CASES, kept = [("roster", ROSTER), ("cafes", CAFES), ("metro map", METRO),
               ("roster, Ana covers Ben", COVER), ("roster and cafes at once", BOTH)], {}
for label, (names, edges) in CASES:
    a, (good, first) = adj(names, edges), cuts(names, edges)
    dist, parent, clash = layers(names, edges)
    loop = odd_loop(parent, clash) if clash else []
    kept[label] = (good, first, dist, loop, clash)
    tri = sum(1 for u in range(len(names)) for v in a[u] for w in a[v] if u < v < w and u in a[w])
    clash_s = "none" if not clash else f"{names[clash[0]]}-{names[clash[1]]}, steps out {dist[clash[0]]} and {dist[clash[1]]}"
    tail = (f"heaps {show(names, lambda i: first >> i & 1)} | {show(names, lambda i: not first >> i & 1)}" if good
            else f"odd loop {' '.join(names[i] for i in loop)}, {len(loop)} lines, real cycle {'yes' if real(a, loop) else 'no'}")
    print(f"{label}: {len(names)} dots, {len(edges)} lines; working cuts {good} of {1 << len(names)}; "
          f"triangles {tri}; clash {clash_s}; {tail}")
names, deg, (_, first_r, dist_r, _, _) = ROSTER[0], [len(r) for r in adj(*ROSTER)], kept["roster"]
even, odd = show(names, lambda i: dist_r[i] % 2 == 0), show(names, lambda i: dist_r[i] % 2 == 1)
cut_a, cut_b = show(names, lambda i: first_r >> i & 1), show(names, lambda i: not first_r >> i & 1)
print(f"roster: 5 workers, 4 shifts, {len(ROSTER[1])} of the {5 * 4} possible pairs; lines per worker "
      f"{' '.join(map(str, deg[:5]))} = {sum(deg[:5])}, per shift {' '.join(map(str, deg[5:]))} = {sum(deg[5:])}")
print("BFS from Ana: " + " | ".join(f"{d} " + show(names, lambda i: dist_r[i] == d) for d in range(max(dist_r) + 1)))
print(f"even steps out {even}; odd steps out {odd}; the same two heaps as the first working cut of "
      f"{1 << len(names)}: {'yes' if {even, odd} == {cut_a, cut_b} else 'no'}")
assert {even, odd} == {cut_a, cut_b}                                       # two roads, one cut
assert real(adj(*CAFES), kept["cafes"][3]) and len(kept["cafes"][3]) == 5  # the certificate holds
assert sum(deg[:5]) == sum(deg[5:]) == len(ROSTER[1])                      # each side counts every line
assert all((v[4] is None) == (v[0] > 0) for v in kept.values())            # the roads agree, 5 graphs
print("ALL CHECKS PASS")
