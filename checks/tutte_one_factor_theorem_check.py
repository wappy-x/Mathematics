# Tutte's theorem -- the check behind the card.  Nothing is imported; a graph is one bitmask of neighbours per dot.
# Roads: Tutte's count over every set S, a matching search that never mentions S, Petersen's count of lines
# leaving odd pieces, and a census of the Petersen graph's perfect matchings.
def build(n, lines):
    adj = [0] * n
    for a, b in lines: adj[a] |= 1 << b; adj[b] |= 1 << a
    return adj
def pieces(adj, gone):                  # the pieces of G - S, each as a bitmask
    seen, out = gone, []
    for v in range(len(adj)):
        if not seen >> v & 1:
            stack, piece, seen = [v], 1 << v, seen | 1 << v
            while stack:
                new = adj[stack.pop()] & ~seen
                seen, piece = seen | new, piece | new
                stack += [w for w in range(len(adj)) if new >> w & 1]
            out.append(piece)
    return out
def odd(adj, s): return sum(p.bit_count() % 2 for p in pieces(adj, s))
def tutte_berge(adj): return min((len(adj) + s.bit_count() - odd(adj, s)) // 2 for s in range(1 << len(adj)))
def worst(adj): return max(odd(adj, s) - s.bit_count() for s in range(1 << len(adj)))
def nu(adj, free, memo):                # road two: largest matching by search
    if free == 0: return 0
    if free not in memo:
        v = (free & -free).bit_length() - 1; rest = free & ~(1 << v)
        memo[free] = max([nu(adj, rest, memo)] + [1 + nu(adj, rest & ~(1 << w), memo)
                         for w in range(len(adj)) if (rest & adj[v]) >> w & 1])
    return memo[free]
def perfect(adj, free):                 # every perfect matching, listed
    if free == 0: return [[]]
    v = (free & -free).bit_length() - 1; rest = free & ~(1 << v)
    return [[(v, w)] + m for w in range(len(adj)) if (rest & adj[v]) >> w & 1 for m in perfect(adj, rest & ~(1 << w))]
def bridges(adj, lines): return sum(len(pieces(build(len(adj), [e for e in lines if e != f]), 0)) > len(pieces(adj, 0)) for f in lines)
def mask(dots): return sum(1 << d for d in set(dots))
def sends(adj, s): return [sum((adj[u] & s).bit_count() for u in range(len(adj)) if p >> u & 1) for p in pieces(adj, s) if p.bit_count() % 2]
SPOKES = [(i, i + 5) for i in range(5)]
PET = [tuple(sorted((i, (i + 1) % 5))) for i in range(5)] + SPOKES + [tuple(sorted((5 + i, 5 + (i + 2) % 5))) for i in range(5)]
CUBIC = [e for b in (1, 6, 11) for e in [(0, b), (b, b + 1), (b, b + 2), (b + 1, b + 3), (b + 1, b + 4), (b + 2, b + 3), (b + 2, b + 4), (b + 3, b + 4)]]
HOTEL = [(i, 6 + j) for i, js in enumerate([[0, 5], [0, 5], [5], [1, 2, 3], [2, 4], [3, 4, 1]]) for j in js]
STAR, PATH, TRI = [(0, 1), (0, 2), (0, 3)], [(0, 1), (1, 2), (2, 3)], [(0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5)]   # TRI: two triangles
for name, n, lines, s in [("star K(1,3)", 4, STAR, [0]), ("Petersen", 10, PET, [1, 4, 5]), ("16-dot cubic", 16, CUBIC, [0]),
                          ("hotel", 12, HOTEL, [6, 11]), ("path a-b-c-d", 4, PATH, [1])]:
    adj = build(n, lines); tb, m, w = tutte_berge(adj), nu(adj, (1 << n) - 1, {}), worst(adj)
    print(f"{name}: {n} dots, {len(lines)} lines; S = {s} leaves pieces of {sorted(p.bit_count() for p in pieces(adj, mask(s)))} dots, {odd(adj, mask(s))} odd; "
          f"worst odd - |S| = {w}; Tutte-Berge {tb}; search {m}; perfect {'yes' if 2 * m == n else 'no'}")
    assert tb == m and (w <= 0) == (2 * m == n)      # Tutte-Berge equals the search; Tutte's test decides
pet, cub, tri = build(10, PET), build(16, CUBIC), build(6, TRI); pms = perfect(pet, (1 << 10) - 1)
rings = [sorted(p.bit_count() for p in pieces(build(10, [e for e in PET if e not in pm]), 0)) for pm in pms]
out = [sends(pet, s) for s in range(1 << 10)]
hall = sum(mask([w for v in range(6) if g >> v & 1 for w in range(6) if tri[v] >> w & 1]).bit_count() >= g.bit_count() for g in range(1, 64))
print(f"Petersen: bridges {bridges(pet, PET)}; perfect matchings {len(pms)}; the 5 spokes among them: {'yes' if SPOKES in pms else 'no'}")
print(f"Petersen: lines left after each perfect matching form cycles of lengths {rings[0]}, the same for {rings.count([5, 5])} of {len(rings)}")
print(f"Petersen, all 1024 sets S: fewest lines from one odd piece to S = {min(min(x) for x in out if x)}; most odd pieces - |S| = {worst(pet)}")
print(f"16-dot cubic: bridges {bridges(cub, CUBIC)}; lines from each odd piece to S = centre: {sends(cub, 1)}")
print(f"mistake 1, star tested with S = [] only: {odd(build(4, STAR), 0)} odd pieces <= 0 passes, yet largest matching {nu(build(4, STAR), 15, {})} of 2")
print(f"mistake 2, two triangles under Hall's test: {hall} of 63 groups pass, yet largest matching {nu(tri, 63, {})} for 6 dots")
assert len(pms) == 6 and rings.count([5, 5]) == 6 and bridges(pet, PET) == 0 and bridges(cub, CUBIC) == 3
assert all(len(x) <= s.bit_count() and all(k >= 3 for k in x) for s, x in enumerate(out))   # Petersen's count
assert nu(build(12, HOTEL), (1 << 12) - 1, {}) == 5 and nu(cub, (1 << 16) - 1, {}) == 7 and hall == 63 and nu(tri, 63, {}) == 2
print("ALL CHECKS PASS")
