# The travelling salesman -- the check behind the card.  Nothing is imported.  Six
# towns, A home, and the rep's mileage chart.  The cheapest tour is found twice over:
# by listing every order of the five towns after A, and by the set-by-set method,
# which keeps the cheapest way to reach each set of towns and end at each of them.
NAMES, N = "ABCDEF", 6
D = [[0, 34, 42, 18, 28, 19], [34, 0, 28, 51, 26, 35], [42, 28, 0, 58, 14, 54],
     [18, 51, 58, 0, 44, 25], [28, 26, 14, 44, 0, 42], [19, 35, 54, 25, 42, 0]]
def orders(rest):                        # every order of the towns after home
    return [()] if not rest else [(x,) + t for x in rest for t in orders([y for y in rest if y != x])]
def cost(t): return sum(D[t[k]][t[(k + 1) % N]] for k in range(N))   # legs, plus the drive home
def show(t): return "-".join(NAMES[c] for c in t) + "-" + NAMES[t[0]]
def fact(k): return 1 if k < 2 else k * fact(k - 1)
def fold(t):                             # one name per tour: rotations, both directions
    rots = [t[k:] + t[:k] for k in range(N)]
    return min(min(rots), min(tuple(reversed(r)) for r in rots))
def nearest(start):                      # greed: drive to the nearest town not yet seen
    seen = [start]
    while len(seen) < N:
        seen.append(min((D[seen[-1]][v], v) for v in range(N) if v not in seen)[1])
    return tuple(seen)
tours = [(0,) + p for p in orders(list(range(1, N)))]
ranked = sorted((cost(t), t) for t in tours)          # road one: every order, costed
best, worst, distinct = ranked[0], ranked[-1], len({fold(t) for t in tours})
sym = all(D[u][v] == D[v][u] for u in range(N) for v in range(N))
tri = all(D[u][v] <= D[u][w] + D[w][v] for u in range(N) for v in range(N) for w in range(N))
paths = {(1 << (v - 1), v): D[0][v] for v in range(1, N)}       # second road: set by set
for _ in range(N - 2):
    grown = dict(paths)
    for (s, v), c in paths.items():
        for w in range(1, N):
            if not s >> (w - 1) & 1 and c + D[v][w] < grown.get((s | 1 << (w - 1), w), 10 ** 9):
                grown[(s | 1 << (w - 1), w)] = c + D[v][w]
    paths = grown
setbest = min(paths[((1 << (N - 1)) - 1, v)] + D[v][0] for v in range(1, N))   # all five seen
inn, legs, tree = [0], [], 0
while len(inn) < N:                      # the cheapest connecting tree, grown from A
    w, u, v = min((D[u][v], u, v) for u in inn for v in range(N) if v not in inn)
    inn.append(v); legs.append(f"{NAMES[u]}-{NAMES[v]} {w}"); tree += w
nnt = nearest(0)
nnc, nns = cost(nnt), [cost(nearest(s)) for s in range(N)]
print("six towns, A home; the rep's mileage chart in miles, rows and columns A to F:")
for u in range(N):
    print(f"  {NAMES[u]} " + "".join(f"{D[u][v]:>4}" for v in range(N)))
print(f"chart symmetric: {'yes' if sym else 'no'}; no detour shorter than the direct road: {'yes' if tri else 'no'}")
print(f"orders of the five towns after A: 5! = {len(tours)}; tours (6-1)!/2 = {fact(N - 1) // 2}; by folding rotations and reversals: {distinct}")
print(f"cheapest tour, from all {len(tours)} orders: {show(best[1])} = {best[0]} miles")
print(f"the same cost from the set-by-set method: {setbest} miles, kept in {len(paths)} records")
print(f"dearest tour: {show(worst[1])} = {worst[0]} miles")
print(f"nearest neighbour from A: {show(nnt)} = {nnc} miles, {(nnc - best[0]) * 100 / best[0]:.2f}% above {best[0]}")
print(f"nearest neighbour restarted at each town A to F: {nns}; cheapest of the six {min(nns)}, still above {best[0]}")
print(f"cheapest connecting tree: {', '.join(legs)} = {tree} miles; the bracket {tree} <= {best[0]} <= {2 * tree}")
print(f"tours to check as towns are added: 6 -> {fact(5) // 2}, 7 -> {fact(6) // 2}, 10 -> {fact(9) // 2}, 15 -> {fact(14) // 2}, 20 -> {fact(19) // 2}")
print(f"records the set-by-set method keeps: 6 towns {len(paths)}, 20 towns {19 * 2 ** 18}")
print(f"mistake, every order of six towns counted as a tour: {fact(N)} instead of {distinct}")
print(f"mistake, stopping at the nearest-neighbour route: {nnc} miles, {nnc - best[0]} more than {best[0]}; the tree read as a route: {tree} miles, {best[0] - tree} short")
assert best[0] == setbest == 148 and worst[0] == 267
assert distinct == fact(N - 1) // 2 and len(tours) == fact(N - 1)
assert sym and tri and tree < best[0] <= 2 * tree
assert len(paths) == (N - 1) * 2 ** (N - 2) and nns == [160, 160, 171, 170, 161, 158] and best[0] < min(nns)
print("ALL CHECKS PASS")
