# Flows and Ford-Fulkerson -- the check behind the card.  The diamond: plant s, depots
# A and B, port t; 3 lorry-loads a night on each outer road, 1 on the cross A->B.  Three
# ways: push along shortest leftover routes, try every whole plan, price the four splits.
from itertools import product
CAP = {("s", "A"): 3, ("s", "B"): 3, ("A", "t"): 3, ("B", "t"): 3, ("A", "B"): 1}
ARCS, NODES = list(CAP), ["s", "A", "B", "t"]
SIDES = [("s",), ("s", "A"), ("s", "B"), ("s", "A", "B")]   # the four splits
def left(f, u, v, stubs=True):        # leftover on u->v: spare capacity, plus undoable
    if not stubs and (u, v) not in CAP: return 0
    return CAP.get((u, v), 0) - f.get((u, v), 0) + f.get((v, u), 0)
def netout(f, S):                     # loads leaving the side S, less loads entering it
    return sum(f.get(a, 0) * ((a[0] in S) - (a[1] in S)) for a in ARCS)
def price(S):                         # the price of a split: capacity of roads leaving S
    return sum(w for (u, v), w in CAP.items() if u in S and v not in S)
def shortest(f, stubs):               # the leftover route s to t with the fewest roads
    routes = [["s"]]
    while routes:
        p = routes.pop(0)
        if p[-1] == "t": return p
        routes += [p + [v] for v in NODES if v not in p and left(f, p[-1], v, stubs) > 0]
    return None
def run(forced=(), stubs=True, limit=9):    # way one: push until no route is left
    f, log, todo = {}, [], list(forced)
    while len(log) < limit:
        p = todo.pop(0) if todo else shortest(f, stubs)
        if p is None: break
        b = min(left(f, u, v, stubs) for u, v in zip(p, p[1:]))
        for u, v in zip(p, p[1:]):
            k = (u, v) if (u, v) in CAP else (v, u)     # a stub undoes the real road
            f[k] = f.get(k, 0) + (b if k == (u, v) else -b)
        log.append(("-".join(p), b, netout(f, SIDES[0])))
    return f, log
CROSS = [["s", "A", "B", "t"]]                   # the tempting first route
(f_ek, log_ek), (f_x, log_x) = run(), run(CROSS)
(f_1, _), (f_g, _) = run(CROSS, limit=1), run(CROSS, stubs=False)   # one push; no undoing
PLANS = [dict(zip(ARCS, v)) for v in product(*[range(CAP[a] + 1) for a in ARCS])]
LEGAL = [g for g in PLANS if all(netout(g, S) == netout(g, SIDES[0]) for S in SIDES)]
best = max(netout(g, SIDES[0]) for g in LEGAL)   # way two: a plan strands nothing at a depot
cuts = [("{" + ",".join(S) + "}", price(S)) for S in SIDES]   # exactly when the four splits
cheap = min(c for _, c in cuts)                               # all see the same net crossing
print("diamond capacities: " + ", ".join(f"{u}->{v} {w}" for (u, v), w in CAP.items()))
for title, log in (("shortest leftover route first", log_ek), ("the cross route first", log_x)):
    print("Ford-Fulkerson, " + title)
    for i, (p, b, v) in enumerate(log, 1):
        print(f"  push {i}  {p:<9} bottleneck {b}  value {v}" + ("   rides the backward stub B->A" if "B-A" in p else ""))
print("leftover after the cross route: " + ", ".join(f"{u}->{v} {left(f_1, u, v)}" for u, v in ARCS)
      + "; backward stubs " + ", ".join(f"{v}->{u} {left(f_1, v, u)}" for u, v in ARCS if left(f_1, v, u) > 0))
print("final loads: " + ", ".join(f"{u}->{v} {f_ek.get((u, v), 0)}" for u, v in ARCS)
      + "; from the cross-first run: " + ", ".join(str(f_x.get(a, 0)) for a in ARCS))
print(f"way two, {len(PLANS)} whole-number plans tried, {len(LEGAL)} strand nothing: largest value {best}")
print("way three, the four splits: " + ", ".join(f"{n} {c}" for n, c in cuts)
      + f"; cheapest {cheap}, and {sum(c == cheap for _, c in cuts)} splits price it")
print(f"mistake 1, no backward stub after the cross route: value {netout(f_g, SIDES[0])}, not {best}")
print(f"mistake 2, the cheapest single road read as the bottleneck: {min(CAP.values())}, not {best}")
print(f"mistake 3, the split {{s,A}} read as the ceiling: {price(SIDES[1])}, not {cheap}")
assert netout(f_ek, SIDES[0]) == best == cheap == 6          # three ways, one value
assert netout(f_x, SIDES[0]) == best and len(log_x) == 4 and f_x.get(("A", "B"), 0) == 0
assert netout(f_g, SIDES[0]) == 5 and log_x[3][0] == "s-B-A-t"
assert {a: f_ek.get(a, 0) for a in ARCS} in LEGAL and len(LEGAL) == 25 and sum(c == cheap for _, c in cuts) == 3
print("ALL CHECKS PASS")
