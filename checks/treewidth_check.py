# Treewidth -- the check behind the card.  Nothing imported.  Vertices are 1, 2, 3 ... on the card, 0, 1, 2 ... here, and a
# set of vertices is a bit mask.  Widths two ways (rules tested, every elimination order); independent sets two ways (DP, every subset).
def ring(n): return n, [(i, (i + 1) % n) for i in range(n)]
def grid(k): return k * k, [(r * k + c, r * k + c + 1) for r in range(k) for c in range(k - 1)] + [(i, i + k) for i in range(k * k - k)]
def bits(vs): return sum(1 << v for v in vs)
def show(m): return "{" + ",".join(str(v + 1) for v in range(m.bit_length()) if m >> v & 1) + "}"
size, path = (lambda m: bin(m).count("1")), (lambda k: [(i, i + 1) for i in range(k - 1)])
def width(n, es, bags, links):          # road one: test the three rules, return the width or None
    if any(not any(b >> v & 1 for b in bags) for v in range(n)) or any(not any(b >> x & 1 and b >> y & 1 for b in bags) for x, y in es): return None
    for v in range(n):                                                                   # rule 3
        hold = {i for i, b in enumerate(bags) if b >> v & 1}; reach = {min(hold)}
        while new := {j for i, j in links + [(j, i) for i, j in links] if i in reach and j in hold} - reach: reach |= new
        if reach != hold: return None
    return max(size(b) for b in bags) - 1
def exact_tw(n, es):                    # road two: the best elimination order, built up over subsets
    nb = [bits([y for x, y in es if x == v] + [x for x, y in es if y == v]) for v in range(n)]
    def q(s, v):                        # vertices outside s that v reaches by walking through s
        seen, todo = 1 << v, [v]
        while todo: u = todo.pop(); fresh = nb[u] & ~seen; seen |= fresh; todo += [w for w in range(n) if (fresh & s) >> w & 1]
        return size(seen & ~s) - 1
    tw = [-1] + [n] * ((1 << n) - 1)
    for s in range(1, 1 << n): tw[s] = min(max(tw[s & ~(1 << v)], q(s & ~(1 << v), v)) for v in range(n) if s >> v & 1)
    return tw[-1]
def indep(m, es): return not any(m >> x & 1 and m >> y & 1 for x, y in es)
def subsets(b): vs = [v for v in range(b.bit_length()) if b >> v & 1]; return [bits(v for j, v in enumerate(vs) if k >> j & 1) for k in range(1 << len(vs))]
def dp(bags, es, agree=True):           # one table per bag: chosen part of the bag -> (best size, its set)
    prev, pb, tabs = {0: (0, 0)}, 0, []
    for b in bags:
        table = {}
        for s in (s for s in subsets(b) if indep(s, es)):
            opts = [(z + size(s & ~pb), -(m | s)) for p, (z, m) in prev.items() if not agree or p & b == s & pb]
            if opts: z, m = max(opts); table[s] = (z, -m)
        prev, pb = table, b; tabs.append(table)
    z, m = max((z, -m) for z, m in prev.values()); return z, -m, tabs
TREE, C6, C60 = (7, [(0, 1), (1, 2), (1, 3), (3, 4), (3, 5), (5, 6)]), ring(6), ring(60)   # the village of the Trees card
BAGS, FAN, LANE_BAGS = [bits(b) for b in ([0, 1, 5], [1, 2, 5], [2, 4, 5], [2, 3, 4])], [bits([0, i, i + 1]) for i in range(1, 59)], [bits(e) for e in C6[1]]
w6, w_tree = width(*C6, BAGS, path(4)), width(*TREE, [bits(e) for e in TREE[1]], [(1, 0), (2, 0), (3, 2), (4, 2), (5, 4)])
exact = [exact_tw(*g) for g in (TREE, C6, grid(2), grid(3), grid(4))]
sweep = [width(*grid(k), [bits(range(j, j + k + 1)) for j in range(k * k - k)], path(k * k - k)) for k in (3, 4)]
floor = [min(sum(v in e for e in g[1]) for v in range(g[0])) for g in (TREE, C6, grid(3))]
(best, best_set, tabs), (big, _, big_tabs), bad, loose = dp(BAGS, C6[1]), dp(FAN, C60[1]), dp(LANE_BAGS, C6[1])[0], dp(BAGS, C6[1], False)
brute = [m for m in range(1 << 6) if indep(m, C6[1])]; top = max(map(size, brute)); rows = [len(t) for t in tabs]
print(f"6-cycle, bags {' '.join(show(b) for b in BAGS)}: width {w6}")
print(f"village tree, one bag per lane: width {w_tree}")
print(f"exact treewidth by search: tree {exact[0]}, 6-cycle {exact[1]}, grids 2x2 {exact[2]}, 3x3 {exact[3]}, 4x4 {exact[4]}")
print(f"grid sweep, k+1 vertices in reading order: 3x3 width {sweep[0]}, 4x4 width {sweep[1]}")
print(f"floor from the fewest neighbours: tree {floor[0]}, 6-cycle {floor[1]}, 3x3 grid {floor[2]}")
print(f"DP table sizes, bag by bag: {rows}, {sum(rows)} entries, at most 2^3 = 8 each")
for b, t in zip(BAGS, tabs): print(f"bag {show(b)}: " + " ".join(f"{show(s)}={z}" for s, (z, m) in sorted(t.items())))
print(f"DP answer: largest independent set {best}, {show(best_set)}")
print(f"all {1 << 6} subsets: {len(brute)} independent, largest {top}, by {' and '.join(show(m) for m in brute if size(m) == top)}")
print(f"{C60[0]}-cycle, {len(FAN)} fan bags, width {width(*C60, FAN, path(len(FAN)))}: DP finds {big} from {sum(len(t) for t in big_tabs)} entries; every subset: 2^{C60[0]} = {2 ** C60[0]}")
print(f"mistake 1, width read as bag size: 6-cycle {w6 + 1}, tree {w_tree + 1}")
print(f"mistake 2, the six edges as bags in a row: rules met {'no' if width(*C6, LANE_BAGS, path(6)) is None else 'yes'}, DP says {bad}")
print(f"mistake 3, tables joined without matching shared vertices: DP says {loose[0]}, {show(loose[1])}")
assert w6 == exact[1] == floor[1] == 2 and w_tree == exact[0] == 1          # decomposition = search
assert exact[2:] == [2, 3, 4] and sweep == exact[3:]                         # grids: the sweep is optimal
assert best == top == 3 and best_set == bits([0, 2, 4]) and big == 30        # DP = brute force
assert bad == 4 and width(*C6, LANE_BAGS, path(6)) is None and loose[0] > top and max(rows) <= 8
print("ALL CHECKS PASS")
