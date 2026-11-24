# Graph minors and Wagner's theorem -- the check behind the card.  Nothing is imported.  Road one counts:
# a flat drawing with no ring shorter than g has E <= g(V - 2)/(g - 2).  Road two contracts Petersen's five
# spokes by hand.  Road three knows no theory: it tries every split of the dots into connected branch sets.
def adj(n, es): return [{b if a == u else a for a, b in es if u in (a, b)} for u in range(n)]
def complete(n): return [(u, v) for u in range(n) for v in range(u + 1, n)]
def perms(xs): return [[x] + p for i, x in enumerate(xs) for p in perms(xs[:i] + xs[i + 1:])] or [[]]
RING = [(i, (i + 1) % 5) for i in range(5)]
PET = RING + [(5 + i, 5 + (i + 2) % 5) for i in range(5)] + [(i, 5 + i) for i in range(5)]
CUBE = [(i, (i + 1) % 4) for i in range(4)] + [(4 + i, 4 + (i + 1) % 4) for i in range(4)] + [(i, 4 + i) for i in range(4)]
K5, K33, K4 = complete(5), [(u, v) for u in range(3) for v in range(3, 6)], complete(4)
def girth(n, es):                                  # shortest ring: drop a line, walk round to its ends
    best = n + 1
    for u, v in es:
        a, dist, todo = adj(n, [e for e in es if e != (u, v)]), {u: 0}, [u]
        for x in todo:
            for y in a[x] - dist.keys(): dist[y] = dist[x] + 1; todo.append(y)
        best = min(best, dist.get(v, n) + 1)
    return best
def fuse(lab, es):                                 # each set becomes one dot; loops and repeats vanish
    return {(min(lab[u], lab[v]), max(lab[u], lab[v])) for u, v in es if lab[u] != lab[v] and min(lab[u], lab[v]) >= 0}
def connected(block, a):
    seen, todo = {block[0]}, [block[0]]
    for x in todo: todo += [y for y in a[x] & set(block) - seen]; seen |= a[x] & set(block)
    return len(seen) == len(block)
def models(n, es, k, h):                           # road three: label each dot unused (-1) or a set 0..k-1
    a, out, ps = adj(n, es), [], perms(list(range(k)))
    def go(v, lab, used):
        if n - v < k - used: return
        if v == n:
            blocks, q = [[x for x in range(n) if lab[x] == b] for b in range(k)], fuse(lab, es)
            if all(connected(b, a) for b in blocks) and any(all((min(p[x], p[y]), max(p[x], p[y])) in q for x, y in h) for p in ps):
                out.append(sorted(tuple(b) for b in blocks if len(b) > 1))
            return
        for c in range(-1, min(used, k - 1) + 1): go(v + 1, lab + [c], max(used, c + 1))
    go(0, [], 0)
    return out
def matchings(free, es):                           # perfect matchings, counted straight from the lines
    if not free: return [[]]
    u = min(free)
    return [[(u, v)] + m for v in sorted(adj(10, es)[u] & free) for m in matchings(free - {u, v}, es)]
V, E, g, spoked = 10, len(PET), girth(10, PET), fuse([0, 1, 2, 3, 4, 0, 1, 2, 3, 4], PET)
k5_pet, k33_pet, pm = models(10, PET, 5, K5), models(10, PET, 6, K33), matchings(set(range(10)), PET)
cube, big, nv = [len(models(8, CUBE, 5, K5)), len(models(8, CUBE, 6, K33)), len(models(8, CUBE, 4, K4))], sum(len(s) >= 4 for s in adj(V, PET)), len({x for e in spoked for x in e})
print(f"Petersen: V = {V}, E = {E}, degrees {sorted({len(s) for s in adj(V, PET)})}, girth {g}")
print(f"edge ceiling 3V - 6 = {3 * V - 6}: {E} lines fit, so the count is silent")
print(f"girth ceiling {g}(V - 2)/{g - 2} = {g * (V - 2) / (g - 2):.2f}: {E} lines is over; {2 * E} sides fill at most {2 * E // g} regions, Euler needs {E - V + 2}")
print(f"contract the {V - nv} spokes: V = {nv}, E = {len(spoked)}, pairs among {nv} dots = {nv * (nv - 1) // 2}, K(5): {'yes' if spoked == set(K5) else 'no'}")
print(f"search for K(5) in Petersen: {len(k5_pet)} families, set sizes {sorted({len(s) for m in k5_pet for s in m})}")
print(f"perfect matchings of Petersen, counted directly: {len(pm)}; the same line sets: {'yes' if sorted(pm) == sorted(k5_pet) else 'no'}")
print(f"search for K(3,3) in Petersen: {len(k33_pet)} families")
print(f"cube, 8 dots and {len(CUBE)} lines: K(5) {cube[0]} families, K(3,3) {cube[1]}, K(4) {cube[2]}")
print(f"mistake 1, the edge ceiling as permission: {E} <= {3 * V - 6}, yet K(5) is a minor")
print(f"mistake 2, the ring-of-four ceiling 2V - 4 = {2 * V - 4}: {E} fits; girth {g} gives {g * (V - 2) / (g - 2):.2f}")
print(f"mistake 3, hunting only for K(5) with dots along its lines: {big} dots of degree 4, yet {len(k33_pet)} K(3,3) families")
k5e = [e for e in K5 if e != (3, 4)]
print(f"mistake 4, closure read backwards: K(5) minus one line has {len(models(5, k5e, 5, K5))} K(5) and {len(models(5, k5e, 6, K33))} K(3,3) families, so it is flat")
assert g == 5 and E > g * (V - 2) / (g - 2) and E <= 3 * V - 6        # counting: silent, then decisive
assert spoked == set(K5) and len(k5_pet) == len(pm) == 6 and sorted(pm) == sorted(k5_pet)   # three roads, one K(5)
assert big == 0 and len(k33_pet) > 0 and cube[:2] == [0, 0] and cube[2] > 0   # Petersen fails Wagner, the cube passes
print("ALL CHECKS PASS")
