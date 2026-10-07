# Directed graphs and topological order -- the check behind the card.  Nothing is
# imported.  A recipe's 8 prep steps, numbered alphabetically: 0 bake, 1 boil the
# water, 2 chop the onion, 3 cook the pasta sheets, 4 grate the cheese, 5 heat the
# oven, 6 layer the dish, 7 simmer the sauce.  An arrow u -> v means u before v.
NAMES = ["bake", "boil the water", "chop the onion", "cook the pasta sheets",
         "grate the cheese", "heat the oven", "layer the dish", "simmer the sauce"]
RECIPE = [(1, 3), (2, 7), (3, 6), (4, 6), (7, 6), (4, 0), (5, 0), (6, 0)]
BACK = RECIPE + [(6, 4)]                      # one back-arrow: layer -> grate
METRO = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]
def degs(n, arcs):                            # arrows in, then arrows out, step by step
    return ([sum(v == w for _, v in arcs) for w in range(n)], [sum(u == w for u, _ in arcs) for w in range(n)])
def kahn(n, arcs):                            # road one: peel the lowest-numbered source
    ins, left, order = degs(n, arcs)[0], list(range(n)), []
    while any(ins[x] == 0 for x in left):
        w = min(x for x in left if ins[x] == 0); left.remove(w); order.append(w)
        ins = [d - ((w, x) in arcs) for x, d in enumerate(ins)]
    return order, left
def forward(arcs, order):                     # arrows running left to right in a listing
    pos = {w: i for i, w in enumerate(order)}; return sum(pos[u] < pos[v] for u, v in arcs)
def listings(items):                          # every listing there is, generated here
    if not items: yield ()
    for i, x in enumerate(items):
        for rest in listings(items[:i] + items[i + 1:]): yield (x,) + rest
def valid(n, arcs):                           # road two: try every listing
    return [p for p in listings(tuple(range(n))) if forward(arcs, p) == len(arcs)]
def pieces(n, arcs):                          # road three: follow arrows to a standstill
    R = [{v for u, v in arcs if u == w} for w in range(n)]
    for _ in range(n): R = [r | {x for v in r for x in R[v]} for r in R]
    both = [sorted({w} | {v for v in R[w] if w in R[v]}) for w in range(n)]
    return ([w for w in range(n) if w in R[w]], [p for i, p in enumerate(both) if p not in both[:i]])
ins, outs = degs(8, RECIPE); order, left = kahn(8, RECIPE); ok = valid(8, RECIPE)
src = [w for w in range(8) if ins[w] == 0]; snk = [w for w in range(8) if outs[w] == 0]
tried = len(list(listings(tuple(range(8))))); sinks_first = kahn(8, [(v, u) for u, v in RECIPE])[0]
b_order, b_left = kahn(8, BACK); loops, parts = pieces(8, BACK)
where = {w: i for i, p in enumerate(parts) for w in p}
between = sorted({(where[u], where[v]) for u, v in BACK if where[u] != where[v]})
lined = len(kahn(len(parts), between)[0]) == len(parts); m_ins = degs(6, METRO)[0]
m_src = [w for w in range(6) if m_ins[w] == 0]; m_parts = pieces(6, METRO)[1]
print(f"recipe: 8 steps, {len(RECIPE)} arrows; alphabetical numbering, 0 {NAMES[0]} to 7 {NAMES[7]}")
print(f"arrows in,  step 0 to 7: {ins}  total {sum(ins)}")
print(f"arrows out, step 0 to 7: {outs}  total {sum(outs)}")
print(f"nothing pointing in (sources): {src}; nothing pointing out (sinks): {snk}")
print(f"Kahn, peeling the lowest-numbered source: {order}")
print("in words: " + ", ".join(NAMES[w] for w in order))
print(f"arrows running forward in that listing: {forward(RECIPE, order)} of {len(RECIPE)}")
print(f"second road, all {tried} listings tried: {len(ok)} valid; first {list(ok[0])}, last {list(ok[-1])}")
print(f"peeling sinks instead, written left to right: {sinks_first}; arrows forward: {forward(RECIPE, sinks_first)} of 8")
print(f"arrows read as an undirected degree sum: 2 x {len(RECIPE)} = {2 * len(RECIPE)}, not {len(RECIPE)}")
print(f"add one back-arrow, {NAMES[6]} -> {NAMES[4]}: {len(BACK)} arrows")
print(f"Kahn writes {len(b_order)} of 8 steps and jams: {b_order}; left {sorted(b_left)}, still pointed at")
print(f"all {tried} listings tried: {len(valid(8, BACK))} valid")
print(f"steps reachable from themselves: {loops}; pieces: {len(parts)}, sizes {sorted(len(p) for p in parts)}")
print(f"squash each piece to a dot: {len(between)} arrows between pieces, all {len(parts)} lined up: {'yes' if lined else 'no'}")
print(f"cross-check, the metro map with every line one-way: 6 stations, {len(METRO)} arrows, sources {m_src}")
print(f"all 720 listings tried: {len(valid(6, METRO))} valid; pieces: {len(m_parts)}, sizes {sorted(len(p) for p in m_parts)}")
assert ins == [3, 0, 0, 1, 0, 0, 3, 1] and outs == [0, 1, 1, 1, 2, 1, 1, 1] and sum(ins) == len(RECIPE) == sum(outs)
assert len(ok) == 210 and tuple(order) == ok[0] and left == [] and forward(RECIPE, order) == 8 and forward(RECIPE, sinks_first) == 0
assert valid(8, BACK) == [] and len(b_order) == 5 and loops == [4, 6] and lined and parts == [[0], [1], [2], [3], [4, 6], [5], [7]]
assert valid(6, METRO) == [] and m_parts == [[0, 1, 2, 3, 4, 5]] and m_src == []
print("ALL CHECKS PASS")
