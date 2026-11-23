# Karp's list -- the check behind the card.  Standard library only.  Three
# reductions are built and run: 3-SAT to vertex cover (gadgets), vertex cover
# to set cover (a special case), Hamiltonian cycle to travelling salesman (one
# weight per pair).  Each side is solved by its own exhaustive search, and the
# reduction must turn every yes into yes and every no into no.
M64 = (1 << 64) - 1
def splitmix(seed):                       # SplitMix64, written out (wing 09)
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & M64
        z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        yield z ^ (z >> 31)
def true_lit(l, a): return ((a >> (abs(l) - 1)) & 1) == (1 if l > 0 else 0)
def sat_count(n, cl):                     # road 1: try all 2^n assignments
    good = [a for a in range(1 << n) if all(any(true_lit(l, a) for l in c) for c in cl)]
    return len(good), (good[0] if good else -1)
def lit_vertex(l): return 2 * (abs(l) - 1) + (1 if l < 0 else 0)   # x_i: 2i-2, not x_i: 2i-1
def gadget(n, cl, var_edges=True, links=True):
    edges = [(2 * i, 2 * i + 1) for i in range(n)] if var_edges else []
    for j, c in enumerate(cl):
        t = [2 * n + 3 * j + p for p in range(3)]              # the clause triangle
        edges += [(t[0], t[1]), (t[0], t[2]), (t[1], t[2])]
        if links: edges += [(t[p], lit_vertex(c[p])) for p in range(3)]
    return 2 * n + 3 * len(cl), edges
def min_cover(nv, edges):                 # road 2: branch on a busiest vertex
    adj = [0] * nv
    for u, v in edges: adj[u] |= 1 << v; adj[v] |= 1 << u
    best = [nv + 1, 0]
    def go(gone, size, chosen):
        if size >= best[0]: return
        degs = [(adj[v] & ~gone).bit_count() if not gone >> v & 1 else 0 for v in range(nv)]
        d = max(degs)
        if d == 0: best[0], best[1] = size, chosen; return
        if size + -(-(sum(degs) // 2) // d) >= best[0]: return   # each pick covers <= d edges
        v = degs.index(d); nb = adj[v] & ~gone
        go(gone | 1 << v, size + 1, chosen | 1 << v)            # v is in the cover
        go(gone | nb | 1 << v, size + d, chosen | nb)           # or all its neighbours are
    go(0, 0, 0); return best[0], best[1]
def covers(edges, mask): return all(mask >> u & 1 or mask >> v & 1 for u, v in edges)
def min_set_cover(n_elems, sets):         # road 3: branch on the first uncovered element
    full, best, most = (1 << n_elems) - 1, [len(sets) + 1], max(s.bit_count() for s in sets)
    def go(got, size):
        if got == full: best[0] = min(best[0], size); return
        left = ~got & full
        if size + -(-left.bit_count() // most) >= best[0]: return   # a set covers <= most
        e = left & -left
        for s in sorted((s for s in sets if s & e), key=lambda s: -(s & left).bit_count()):
            go(got | s, size + 1)
    go(0, 0); return best[0]
def edge_sets(nv, edges): return [sum(1 << i for i, (u, v) in enumerate(edges) if w in (u, v)) for w in range(nv)]
def max_matching(nv, edges):              # Konig's number, by search over the lowest free vertex
    adj = [0] * nv
    for u, v in edges: adj[u] |= 1 << v; adj[v] |= 1 << u
    def go(free):
        if free == 0: return 0
        u = (free & -free).bit_length() - 1; rest = free & ~(1 << u)
        best = go(rest)
        for v in range(nv):
            if rest >> v & 1 and adj[u] >> v & 1: best = max(best, 1 + go(rest & ~(1 << v)))
        return best
    return go((1 << nv) - 1)
def ham_cycles(nv, edges):                # walks from vertex 0, each cycle found twice
    adj = [0] * nv
    for u, v in edges: adj[u] |= 1 << v; adj[v] |= 1 << u
    def go(v, seen):
        if seen == (1 << nv) - 1: return 1 if adj[v] & 1 else 0
        return sum(go(w, seen | 1 << w) for w in range(nv) if adj[v] >> w & 1 and not seen >> w & 1)
    return go(0, 1) // 2
def cheapest_tour(nv, edges, far=2):      # Held-Karp table; a non-edge costs `far`
    es = {(u, v) for u, v in edges} | {(v, u) for u, v in edges}
    w = lambda a, b: 1 if (a, b) in es else far
    big = 10 ** 9; dp = [[big] * nv for _ in range(1 << nv)]; dp[1][0] = 0
    for mask in range(1, 1 << nv, 2):
        for v in range(nv):
            if dp[mask][v] < big:
                for u in range(nv):
                    if not mask >> u & 1: dp[mask | 1 << u][u] = min(dp[mask | 1 << u][u], dp[mask][v] + w(v, u))
    return min(dp[(1 << nv) - 1][v] + w(v, 0) for v in range(1, nv))
def show(a, n): return ", ".join(f"x{i + 1}={'T' if a >> i & 1 else 'F'}" for i in range(n))

phi = [(1, 2, 3), (-1, -2, 3), (1, -2, -3)]
n, m = 3, len(phi); k = n + 2 * m
(count, a), (nv, E) = sat_count(n, phi), gadget(n, phi)
tau, solver_cover = min_cover(nv, E)
print(f"phi: n = {n} variables, m = {m} clauses, satisfying assignments {count} of {1 << n}")
print(f"first satisfying assignment: {show(a, n)}")
print(f"G_phi: vertices {nv} (2n + 3m = {2 * n + 3 * m}), edges {len(E)} (n + 6m = {n + 6 * m}), target k = n + 2m = {k}")
built = sum(1 << lit_vertex(i + 1 if a >> i & 1 else -(i + 1)) for i in range(n))
for j, c in enumerate(phi):              # leave out one true literal's corner, take the other two
    keep = next(p for p in range(3) if true_lit(c[p], a))
    built |= sum(1 << (2 * n + 3 * j + p) for p in range(3) if p != keep)
print(f"cover built from the assignment: vertices {[v for v in range(nv) if built >> v & 1]}, size {built.bit_count()}, covers every edge: {covers(E, built)}")
def read_back(cov, n): return sum(1 << i for i in range(n) if cov >> (2 * i) & 1)   # x_i true when its vertex is in the cover
back = read_back(solver_cover, n); back_ok = all(any(true_lit(l, back) for l in c) for c in phi)
print(f"smallest vertex cover found by search: {tau}; assignment read back from it: {show(back, n)}, satisfies phi: {back_ok}")
sc = min_set_cover(len(E), edge_sets(nv, E))
print(f"set cover: {len(E)} elements (the edges), {nv} sets (one per vertex), fewest sets covering all: {sc}")
psi = [(s1, 2 * s2, 3 * s3) for s1 in (1, -1) for s2 in (1, -1) for s3 in (1, -1)]
cpsi, _ = sat_count(3, psi); nvp, Ep = gadget(3, psi); kp = 3 + 2 * len(psi)
taup, _ = min_cover(nvp, Ep); scp = min_set_cover(len(Ep), edge_sets(nvp, Ep))
print(f"psi, all 8 clauses on x1..x3: satisfying assignments {cpsi}; G_psi: vertices {nvp}, edges {len(Ep)}, target {kp}")
print(f"smallest vertex cover of G_psi: {taup}; fewest sets in its set cover: {scp}")
assert count > 0 and tau == k and built.bit_count() == k and covers(E, built) and back_ok
assert covers(E, solver_cover) and solver_cover.bit_count() == tau and sc == tau
assert cpsi == 0 and taup == kp + 1 and scp == taup
pool = [tuple(sg[p] * vs[p] for p in range(3)) for d in range(4) for vs in [[v for v in (1, 2, 3, 4) if v != d + 1]]
        for sg in [(s1, s2, s3) for s1 in (1, -1) for s2 in (1, -1) for s3 in (1, -1)]]
rng, tally, agree, backs = splitmix(2026), [0, 0], 0, 0
for t in range(40):                       # 40 random formulas: 4 variables, 11 to 14 distinct clauses
    left, cl = pool[:], []
    for _ in range(11 + t % 4): cl.append(left.pop(next(rng) % len(left)))
    c, _ = sat_count(4, cl); gv, ge = gadget(4, cl); tc, tcov = min_cover(gv, ge)
    tally[c == 0] += 1; agree += (c > 0) == (tc <= 4 + 2 * len(cl))
    bk = read_back(tcov, 4); backs += c > 0 and all(any(true_lit(l, bk) for l in q) for q in cl)
print(f"random batch, seed 2026: 40 formulas, satisfiable {tally[0]}, unsatisfiable {tally[1]}, reduction agrees on {agree}, assignments read back and checked {backs}")
assert agree == 40 and tally[1] > 0 and backs == tally[0]
cube = [(u, u ^ b) for u in range(8) for b in (1, 2, 4) if u < u ^ b]
pet = [(i, (i + 1) % 5) for i in range(5)] + [(i, i + 5) for i in range(5)] + [(5 + i, 5 + (i + 2) % 5) for i in range(5)]
hc, hp = ham_cycles(8, cube), ham_cycles(10, pet)
tc, tp, tp1 = cheapest_tour(8, cube), cheapest_tour(10, pet), cheapest_tour(10, pet, far=1)
print(f"cube: 8 vertices, {len(cube)} edges, Hamiltonian cycles {hc}, cheapest tour {tc} against budget 8")
print(f"Petersen: 10 vertices, {len(pet)} edges, Hamiltonian cycles {hp}, cheapest tour {tp} against budget 10")
assert hc == 6 and tc == 8 and hp == 0 and tp == 11 and len(cube) == 12
_, el = gadget(3, psi, links=False); _, ev = gadget(3, psi, var_edges=False)
nl, nvar, mm = min_cover(30, el)[0], min_cover(30, ev)[0], max_matching(nv, E)
print(f"mistake, target n + m = {n + m} on phi: smallest cover {tau} is above it, so a satisfiable formula reads as no")
print(f"mistake, links dropped on psi: smallest cover {nl} <= {kp}, so an unsatisfiable formula reads as yes")
print(f"mistake, variable edges dropped on psi: smallest cover {nvar} <= {kp}, the same false yes")
print(f"mistake, Konig's matching on G_phi: largest matching {mm} against smallest cover {tau}")
print(f"mistake, non-edges cost 1 on Petersen: cheapest tour {tp1} <= 10, a false yes")
assert nl <= kp and nvar <= kp and mm < tau and tp1 == 10
print("sizes: variables, clauses, vertices, edges built, edges by formula, assignments 2^n")
for sn, smm in ((10, 43), (40, 172), (100, 430)):
    big = [(next(rng) % sn + 1, -(next(rng) % sn + 1), next(rng) % sn + 1) for _ in range(smm)]
    gv, ge = gadget(sn, big)
    print(f"  {sn}, {smm}, {gv}, {len(ge)}, {sn + 6 * smm}, {1 << sn}")
    assert gv == 2 * sn + 3 * smm and len(ge) == sn + 6 * smm
for g in (9, 16, 25):
    print(f"sudoku {g} by {g}: {g * g} cells; checking a filled grid reads {3 * g} groups of {g}, {3 * g * g} cells")
print("ALL CHECKS PASS")
