# Dijkstra's algorithm -- the check behind the card.  Nothing is imported.  A van leaves the depot D for
# the stadium S over nine roads across four junctions, the number on a road being minutes.  Check one
# settles the cheapest unsettled point and relaxes its neighbours; check two lists every repeat-free route
# and reads off the smallest total, settling nothing.  The last line puts a negative cost in and breaks it.
PTS = ["D", "A", "B", "C", "E", "S"]
ROADS = [("D", "A", 4), ("D", "B", 2), ("B", "A", 1), ("A", "C", 5), ("B", "C", 8),
         ("B", "E", 10), ("C", "E", 2), ("C", "S", 6), ("E", "S", 3)]
BIG, iS = 10 ** 9, PTS.index("S")        # BIG stands in for "no route found yet"; iS is S's column
VAN = {p: [] for p in PTS}
for a, b, w in ROADS: VAN[a].append((b, w)); VAN[b].append((a, w))          # a road runs both ways
NEG = {"D": [("A", 4), ("B", 2)], "A": [("B", -3)], "B": []}                # one-way, one rebate of 3
def settle(adj, pts, start, first_only=False):            # check one: settle, then relax
    d = {p: BIG for p in pts}; back = {}; d[start] = 0; unsettled = list(pts); rows = []
    while unsettled:
        u = min(unsettled, key=lambda v: (d[v], pts.index(v)))      # the cheapest unsettled point
        unsettled.remove(u)                                         # settled: its cost is final
        for v, w in adj[u]:
            better = d[v] == BIG if first_only else d[u] + w < d[v]
            if v in unsettled and better: d[v], back[v] = d[u] + w, u    # relax the road u-v
        rows.append((u, [d[p] for p in pts]))
    return d, back, rows
def listing(adj, a, b, seen=()):                          # check two: every repeat-free route
    if a == b: return [(0, (b,))]
    out = []
    for v, w in adj[a]:
        if v not in seen and v != a: out += [(w + c, (a,) + r) for c, r in listing(adj, v, b, seen + (a,))]
    return out
def best(adj, a, b): return min(listing(adj, a, b))
def row(tag, nums): return f"{tag:<6}" + "".join(f"{'inf' if n >= BIG else n:>5}" for n in nums)
d, back, rows = settle(VAN, PTS, "D")
route = ["S"]
while route[-1] != "D": route.append(back[route[-1]])      # walk the predecessors home
route.reverse(); legs = set(zip(route, route[1:]))
paid = sum(w for a, b, w in ROADS if (a, b) in legs or (b, a) in legs)
to_S = sorted(listing(VAN, "D", "S")); few = min((len(r) - 1, c, r) for c, r in to_S)
first_S = next(snap[iS] for _, snap in rows if snap[iS] < BIG)
no_relax = settle(VAN, PTS, "D", first_only=True)[0]["S"]
print("roads (minutes): " + ", ".join(f"{a}-{b} {w}" for a, b, w in ROADS))
print("settle" + "".join(f"{p:>5}" for p in PTS))
print(row("init", [0 if p == "D" else BIG for p in PTS]))
for u, snap in rows: print(row(u, snap))
print("cheapest minutes from D, by settling:  " + ", ".join(f"{p} {d[p]}" for p in PTS))
print("the same, by listing every route:      " + ", ".join(f"{p} {best(VAN, 'D', p)[0]}" for p in PTS))
print(f"route to S, from the predecessors {'-'.join(route)}, by listing {'-'.join(to_S[0][1])}, 1 of {len(to_S)}")
print(f"its own roads add to {paid}; S reads {rows[4][1][iS]} after 5 settlements, {rows[5][1][iS]} after 6")
print(f"mistake, fewest roads: {'-'.join(few[2])}, {few[0]} roads, {few[1]} minutes")
print(f"mistake, quoting S's first guess: {first_S} minutes, before E improves it")
print(f"mistake, never improving a guess: {no_relax} minutes")
print(f"negative map D-A 4, D-B 2, one-way A-B -3: settling says {settle(NEG, ['D', 'A', 'B'], 'D')[0]['B']}, "
      f"listing says {best(NEG, 'D', 'B')[0]}")
assert d == {p: best(VAN, "D", p)[0] for p in PTS}         # two roads, every cheapest cost
assert paid == d["S"] == 13 and tuple(route) == to_S[0][1]
assert (few[0], few[1], first_S, no_relax) == (3, 15, 14, 16)
assert best(NEG, "D", "B")[0] == 1 and settle(NEG, ["D", "A", "B"], "D")[0]["B"] == 2
print("ALL CHECKS PASS")
