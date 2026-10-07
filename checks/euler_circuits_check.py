# Euler circuits -- the check behind the card.  Nothing is imported.  Konigsberg's seven
# bridges, the same map with an eighth, two separate triangles, a figure-eight of two squares,
# and a 3 x 3 street grid before and after four streets are repeated.  Every verdict is
# reached twice: by counting odd dots, and by hunting a route line by line.
def dots(edges): return sorted({v for e in edges for v in e})
def deg(edges, v): return sum((a == v) + (b == v) for a, b in edges)
def odds(edges): return [v for v in dots(edges) if deg(edges, v) % 2]
def steps(edges, start):                            # steps out from one dot, settled by relaxing
    d, both = {start: 0}, [x for a, b in edges for x in ((a, b), (b, a))]
    for a, b in [e for _ in both for e in both]:     # enough passes to reach every ring
        if a in d and d.get(b, len(both)) > d[a] + 1: d[b] = d[a] + 1
    return d
def hunt(here, left, home):                         # road two: try every order of the lines
    if not left: return home is None or here == home
    for i, (u, v) in enumerate(left):
        rest = left[:i] + left[i + 1:]
        if (u == here and hunt(v, rest, home)) or (v == here and hunt(u, rest, home)): return True
    return False
def hierholzer(edges, start):                       # walk till stuck, splice the loops in
    left, stack, route = list(edges), [start], []
    while stack:
        on = [e for e in left if stack[-1] in e]
        if not on: route.append(stack.pop())
        else: left.remove(on[0]); stack.append(on[0][1] if on[0][0] == stack[-1] else on[0][0])
    return route[::-1]
def once_each(edges, route):                        # independent audit of a finished route
    return sorted(tuple(sorted(p)) for p in zip(route, route[1:])) == sorted(tuple(sorted(e)) for e in edges)
def repeats(edges):                                 # cheapest set of repeats, every set tried
    sets = [[e for i, e in enumerate(edges) if m >> i & 1] for m in range(1 << len(edges))]
    return min((s for s in sets if not odds(edges + s)), key=len)
KON = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
EIGHT = [("A", "B"), ("B", "C"), ("C", "D"), ("D", "A"), ("C", "E"), ("E", "F"), ("F", "G"), ("G", "C")]
GRID = [("A", "B"), ("B", "C"), ("D", "E"), ("E", "F"), ("G", "H"), ("H", "I"),
        ("A", "D"), ("D", "G"), ("B", "E"), ("E", "H"), ("C", "F"), ("F", "I")]
EXTRA, ODD = repeats(GRID), odds(GRID); e8 = hierholzer(EIGHT, "A")
CASES = [("Konigsberg, 7 bridges", KON), ("Konigsberg, an eighth bridge B-C", KON + [("B", "C")]),
         ("two separate triangles", [("A", "B"), ("B", "C"), ("C", "A"), ("D", "E"), ("E", "F"), ("F", "D")]),
         ("figure-eight of two squares", EIGHT), ("3 x 3 street grid", GRID), ("grid, 4 streets repeated", GRID + EXTRA)]
say = lambda shut, ajar: "closed route" if shut else ("open trail" if ajar else "no route")
yn = lambda claim: "yes" if claim else "no"          # the two verdict labels, printed below
print(f"{'graph':<36}{'dots':>5}{'lines':>6}{'odd':>4}{'one piece':>10}   {'by degrees':<14}by hand")
for name, es in CASES:
    piece = len(steps(es, es[0][0])) == len(dots(es))
    one = (piece and not odds(es), piece and len(odds(es)) in (0, 2))
    two = (any(hunt(s, tuple(es), s) for s in dots(es)), any(hunt(s, tuple(es), None) for s in dots(es)))
    print(f"{name:<36}{len(dots(es)):>5}{len(es):>6}{len(odds(es)):>4}{yn(piece):>10}   {say(*one):<14}{say(*two)}")
    assert one == two                               # the degree count against the brute-force hunt
print(f"Konigsberg degrees: {', '.join(f'{v} {deg(KON, v)}' for v in dots(KON))}, adding to "
      f"{sum(deg(KON, v) for v in dots(KON))} = 2 x {len(KON)} bridges")
print(f"figure-eight from A, the second square spliced in at C: {'-'.join(e8)}")
swept = hierholzer(GRID + EXTRA, "A")
costs = [steps(GRID, ODD[0])[ODD[i]] + steps(GRID, ODD[j])[ODD[k]] for i, j, k in ((1, 2, 3), (2, 1, 3), (3, 1, 2))]
print(f"grid odd junctions {' '.join(ODD)}: the three ways to pair them cost {costs} extra passes")
print(f"cheapest repeats, every set of streets tried: {len(EXTRA)}, namely {' '.join('-'.join(e) for e in EXTRA)}")
print(f"the swept route, {len(GRID)} streets + {len(EXTRA)} repeats = {len(swept) - 1} passes, closed "
      f"{yn(swept[0] == swept[-1])}, every street once {yn(once_each(GRID + EXTRA, swept))}: {'-'.join(swept)}")
assert once_each(EIGHT, e8) and e8[0] == e8[-1] and len(e8) - 1 == len(EIGHT)
assert len(EXTRA) == min(costs) and len(swept) - 1 == len(GRID) + len(EXTRA)
assert sum(deg(KON, v) for v in dots(KON)) == 2 * len(KON) and len(odds(KON)) == 4
print("ALL CHECKS PASS")
