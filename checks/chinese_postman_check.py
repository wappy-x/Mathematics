# The Chinese postman -- the check behind the card.  Nothing is imported.  The round is a 3 x 3 grid of junctions A to
# I joined by 12 streets of 100 m each; the two-row map P to W has 10.  The shortest closed round is reached three ways:
# the odd junctions paired by shortest walks, every set of streets that could be repeated searched, and the round walked.
W = 100
GRID = ("ABCDEFGHI", ["AB", "BC", "AD", "BE", "CF", "DE", "EF", "DG", "EH", "FI", "GH", "HI"])
ROWS = ("PQRSTUVW", ["PQ", "QR", "RS", "TU", "UV", "VW", "PT", "QU", "RV", "SW"])
def degs(names, edges): return [sum(v in e for e in edges) for v in names]   # streets met at a junction
def odd_of(names, edges): return "".join(v for v, k in zip(names, degs(names, edges)) if k % 2)
def apsp(names, edges):                      # shortest walk between every pair: Floyd-Warshall
    d = {a + b: (0 if a == b else 10 ** 6) for a in names for b in names}
    for e in edges: d[e] = d[e[1] + e[0]] = W
    for k in names:
        for ab in d: d[ab] = min(d[ab], d[ab[0] + k] + d[k + ab[1]])
    return d
def pairings(items):                         # every way to pair a list up, two by two
    if not items: return [[]]
    r = items[1:]
    return [[(items[0], r[i])] + p for i in range(len(r)) for p in pairings(r[:i] + r[i + 1:])]
def repeats(names, edges, odd):              # road two: every set of streets, no pairing and no shortest walk used
    every = [[e for i, e in enumerate(edges) if m >> i & 1] for m in range(1 << len(edges))]
    fits = [p for p in every if odd_of(names, p) == odd]
    return [p for p in fits if len(p) == min(len(q) for q in fits)]
def circuit(edges):                          # road three: walk the round, Hierholzer's method
    left, stack, route = list(edges), [edges[0][0]], []
    while stack:
        v, nxt = stack[-1], next((e for e in left if stack[-1] in e), None)
        if nxt is None: route.append(stack.pop())
        else: left.remove(nxt); stack.append(nxt[1] if nxt[0] == v else nxt[0])
    return route
def spaced(names, ds): return "  ".join(f"{v} {k}" for v, k in zip(names, ds))
def listed(pcs): return " | ".join(f"({', '.join(a + '-' + b for a, b in p)}) {c}" for p, c in pcs)
def dfact(k): return 1 if k == 0 else (2 * k - 1) * dfact(k - 1)             # 1 x 3 x 5 x ... x (2k-1)
def yn(claim): return "yes" if claim else "no"
def report(label, names, edges, want):
    d, odd, street = apsp(names, edges), odd_of(names, edges), len(edges) * W
    pcs = [(p, sum(d[a + b] for a, b in p)) for p in pairings(list(odd))]
    best, worst, sets_ = min(c for _, c in pcs), max(c for _, c in pcs), repeats(names, edges, odd)
    aug = edges + sets_[0]
    route, after = circuit(aug), degs(names, aug)
    walked = sorted("".join(sorted(p)) for p in zip(route, route[1:]))
    opened = min(d[a + b] for i, a in enumerate(odd) for b in odd[i + 1:])
    print(f"{label}: {len(names)} junctions, {len(edges)} streets of {W} m, {street} m of street in all\n"
          f"degrees: {spaced(names, degs(names, edges))}; odd junctions {' '.join(odd)}, {len(odd)} of them, so no Euler circuit as the map stands\n"
          f"shortest walks between the odd junctions, in m: "
          f"{'  '.join(f'{a}-{b} {d[a + b]}' for i, a in enumerate(odd) for b in odd[i + 1:])}\n"
          f"the pairings and the metres each adds: {listed(pcs)}\n"
          f"road 1, the cheapest pairing adds {best} m: {street} + {best} = {street + best} m; the dearest would add {worst} m, giving {street + worst} m\n"
          f"road 2, over all {1 << len(edges)} sets of streets to repeat: {len(sets_)} cheapest sets, each {len(sets_[0]) * W} m, first in order {' '.join(sets_[0])}; degrees then {spaced(names, after)}, all even: {yn(all(k % 2 == 0 for k in after))}\n"
          f"road 3, the round walked, {len(aug)} streets: {'-'.join(route)} = {len(aug) * W} m; it walks every street of the map and every repeat once each: {yn(walked == sorted(''.join(sorted(e)) for e in aug))}")
    assert best == len(sets_[0]) * W and street + best == want        # the pairing road and the search agree
    assert walked == sorted("".join(sorted(e)) for e in aug) and len(route) == len(aug) + 1 and route[0] == route[-1]
    assert all(k % 2 == 0 for k in after) and sum(after) == 2 * len(aug)
    return street, best, worst, opened, len(sets_)
grid, rows = report("the round, a 3 x 3 grid", *GRID, 1600), report("the two-row map", *ROWS, 1200)
print(f"an open round, not returning to the van: one pair doubled, {grid[3]} m, giving {grid[0] + grid[3]} m; every street walked twice instead: {2 * grid[0]} m")
counts = [len(pairings(list(range(2 * k)))) for k in (2, 3, 4, 5)]
print(f"pairings to test for 4, 6, 8, 10 odd junctions, counted by listing them: {counts}; by 1 x 3 x 5 x ...: {[dfact(k) for k in (2, 3, 4, 5)]}")
assert grid[1] == grid[2] and grid[4] == 7 and rows[2] == 400 and counts == [dfact(k) for k in (2, 3, 4, 5)]
print("ALL CHECKS PASS")
