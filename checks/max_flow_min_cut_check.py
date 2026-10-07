# Max-flow min-cut -- the check behind the card.  The diamond (plant s, depots A and B, port
# t; 3 loads on each outer road, 1 on the cross A->B), then five volunteers on five tasks as
# a flow with every road 1.  Road one: push along shortest leftover routes, read off the
# reachable side.  Road two: price every cut.  Road three: every pairing, every group.
def maxflow(cap, nodes):                     # road one; nodes run from s first to t last
    s, t, f = nodes[0], nodes[-1], {}
    left = lambda u, v: cap.get((u, v), 0) - f.get((u, v), 0) + f.get((v, u), 0)
    while True:
        prev, queue = {s: None}, [s]         # breadth-first: fewest roads first
        for u in queue:
            for v in nodes:
                if v not in prev and left(u, v) > 0: prev[v] = u; queue.append(v)
        if t not in prev: return sum(f.get((s, v), 0) for v in nodes), f, [v for v in nodes if v in prev]
        path, v = [], t
        while prev[v] is not None: path.append((prev[v], v)); v = prev[v]
        b = min(left(u, v) for u, v in path)
        for u, v in path:                    # cancel loads going the other way first
            undo = min(b, f.get((v, u), 0))
            f[(v, u)] = f.get((v, u), 0) - undo; f[(u, v)] = f.get((u, v), 0) + b - undo
def price(cap, S): return sum(c for (u, v), c in cap.items() if u in S and v not in S)
def cuts(cap, nodes):                        # road two: every split, s inside, t outside
    mid = nodes[1:-1]
    return [(S, price(cap, S)) for m in range(2 ** len(mid)) for S in [[nodes[0]] + [x for i, x in enumerate(mid) if m >> i & 1]]]
def side(S): return "{" + ",".join(S) + "}"
DIAMOND = {("s", "A"): 3, ("s", "B"): 3, ("A", "t"): 3, ("B", "t"): 3, ("A", "B"): 1}
dval, _, dR = maxflow(DIAMOND, ["s", "A", "B", "t"])
dcuts = cuts(DIAMOND, ["s", "A", "B", "t"]); dmin = min(c for _, c in dcuts)
print("diamond: " + ", ".join(f"{u}->{v} {c}" for (u, v), c in DIAMOND.items()))
print(f"diamond, road one: max flow {dval}; reachable side {side(dR)}, priced {price(DIAMOND, dR)}")
print("diamond, road two: " + ", ".join(f"{side(S)} {c}" for S, c in dcuts) + f"; cheapest {dmin}, priced by {sum(c == dmin for _, c in dcuts)} cuts")
TASKS = ["registration", "first aid", "water", "parking", "timing"]
CAN = {"Priya": ["registration", "first aid"], "Omar": ["water", "parking"], "Lena": ["first aid", "timing"], "Sam": ["water", "parking"], "Tomas": ["registration"]}
def volunteers(can, name):
    P, E = list(can), [(p, j) for p in can for j in can[p]]
    cap, N = {("s", p): 1 for p in P} | {e: 1 for e in E} | {(j, "t"): 1 for j in TASKS}, ["s"] + P + TASKS + ["t"]
    (val, f, R), cs = maxflow(cap, N), cuts(cap, N); low = min(c for _, c in cs)
    sizes = [bin(m).count("1") for m in range(2 ** len(E)) if len({x for i in range(len(E)) if m >> i & 1 for x in E[i]}) == 2 * bin(m).count("1")]
    groups = [[p for i, p in enumerate(P) if m >> i & 1] for m in range(2 ** len(P))]
    short = max(len(X) - len({j for p in X for j in can[p]}) for X in groups)   # worst crowding
    pairs = [(p, j) for p, j in E if f.get((p, j), 0) == 1]     # the roads the flow uses
    print(f"{name}: {len(cap)} roads of capacity 1; road one: max flow {val}, pairs " + ", ".join(f"{p}-{j}" for p, j in pairs))
    print(f"  reachable side {side(R)}, priced {price(cap, R)}")
    print(f"  road two: {len(cs)} cuts, cheapest {low}, priced by {sum(c == low for _, c in cs)} cuts")
    print(f"  road three: {len(sizes)} sets of pairings, largest {max(sizes)}; worst group short by {short}, so {len(P)} - {short} = {len(P) - short}")
    return val, low, max(sizes), len(P) - short, R, pairs
val, low, big, hall, R, pairs = volunteers(CAN, "volunteers")
BROKEN = dict(CAN, Priya=["registration"])
val2, low2, big2, hall2, R2, _ = volunteers(BROKEN, "Priya off first aid")
X = [p for p in CAN if p in R2]; NX = sorted({j for p in X for j in BROKEN[p]})
print(f"  volunteers on the reachable side {side(X)} reach {side(NX)}: {len(X)} people, {len(NX)} task")
used = set()                                 # greedy: each takes the first free task listed
for p in CAN: used |= set([j for j in CAN[p] if j not in used][:1])
print(f"mistake 1, the cross road read as the cut: {DIAMOND[('A', 'B')]}, not {dmin}")
print(f"mistake 2, {{s,B}} priced with the road entering it too: {price(DIAMOND, ['s', 'B']) + DIAMOND[('A', 'B')]}, not {dmin}")
print(f"mistake 3, greedy pairing in list order read as the most: {len(used)}, not {big}")
assert dval == dmin == price(DIAMOND, dR) == 6 and sum(c == dmin for _, c in dcuts) == 3   # flow meets cut
assert val == low == big == hall == 5 == len(pairs) and len({x for e in pairs for x in e}) == 2 * big > 2 * len(used)
assert val2 == low2 == big2 == hall2 == 4 and len(NX) < len(X)      # the cut names the crowded group
print("ALL CHECKS PASS")
