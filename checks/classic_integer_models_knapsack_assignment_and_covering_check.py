# Four classic integer models -- the check behind the card.  Standard library only.
# A festival books acts (knapsack), slots headliners (assignment), places first-aid
# posts (covering) and routes its van (routing); every answer is reached two ways.
from fractions import Fraction
def splitmix(s):                          # SplitMix64, a small fixed random-number generator
    s = (s + 0x9E3779B97F4A7C15) % 2**64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return s, z ^ (z >> 31)
def make_acts(seed):                      # 60 acts: fee in units of 500 pounds, draw in tickets
    acts, s = [], seed
    for _ in range(60):
        s, a = splitmix(s); s, b = splitmix(s)
        acts.append((1 + a % 12, 40 * (1 + a % 12) + b % 300))
    return acts
def table(acts, W):                       # road 1: K[i][w] = most tickets from acts 1..i in w units
    K = [[0] * (W + 1)]
    for fee, draw in acts:
        K.append([max(K[-1][w], K[-1][w - fee] + draw) if fee <= w else K[-1][w] for w in range(W + 1)])
    pick, w = [], W
    for i in range(len(acts), 0, -1):     # walk back up the table to read off the acts
        if K[i][w] != K[i - 1][w]: pick, w = [i] + pick, w - acts[i - 1][0]
    return K[-1][W], pick
def fill(acts, order, k, room, skip, total=0):   # take acts in order while they fit
    for i in order[k:]:
        if acts[i][0] <= room:
            room, total = room - acts[i][0], total + acts[i][1]
        elif not skip:
            return total, i, room         # the act that does not fit, and the room left
    return total, None, room
def branch_and_bound(acts, W):            # road 2: a search tree, cut by the fractional bound
    order = sorted(range(60), key=lambda i: (-Fraction(acts[i][1], acts[i][0]), i))
    best, nodes = [0], [0]
    def visit(k, room, value):
        nodes[0] += 1
        base, cut, left = fill(acts, order, k, room, False)
        if cut is None:                   # everything left fits: this branch is settled
            best[0] = max(best[0], value + base); return
        if (value + base) * acts[cut][0] + acts[cut][1] * left <= best[0] * acts[cut][0]:
            return                        # even the fractional bound cannot beat the best
        best[0] = max(best[0], value)
        if acts[order[k]][0] <= room:
            visit(k + 1, room - acts[order[k]][0], value + acts[order[k]][1])
        visit(k + 1, room, value)
    visit(0, W, 0)
    return best[0], nodes[0], order
def perms(items):                         # every ordering, written out
    return [list(items)] if len(items) <= 1 else [[x] + p for k, x in enumerate(items) for p in perms(items[:k] + items[k + 1:])]

acts, W = make_acts(7), 80
best, pick = table(acts, W)
bb, nodes, order = branch_and_bound(acts, W)
base, cut, left = fill(acts, order, 0, W, False)
lp = base + Fraction(acts[cut][1] * left, acts[cut][0])
greedy = fill(acts, order, 0, W, True)[0]
big = fill(acts, sorted(range(60), key=lambda i: (-acts[i][1], i)), 0, W, True)[0]
print(f"knapsack: 60 acts, budget 40000 pounds = {W} units of 500; maximise tickets; a full list has {2**60} subsets")
print(f"road 1, table of {60 * (W + 1)} cells: {best} tickets, {len(pick)} acts, fees {500 * sum(acts[i - 1][0] for i in pick)} pounds")
ids = lambda v: "\n".join(" ".join(f"{i}:{500 * acts[i - 1][0]}:{acts[i - 1][1]}" for i in row) for row in (v[:8], v[8:]))
print("acts booked (number:fee in pounds:tickets):\n" + ids(pick))
print(f"road 2, branch and bound: {bb} tickets, {nodes} nodes visited")
print(f"fractional bound: best {order.index(cut)} acts by tickets per pound = {base} tickets, {W - left} units, in rank order:\n"
      + ids([i + 1 for i in order[:order.index(cut)]]))
print(f"  then act {cut + 1} (fee {500 * acts[cut][0]}, {acts[cut][1]} tickets) fits {left}/{acts[cut][0]}, worth {lp - base}: bound {lp}")
print(f"gap between bound and best: {lp - best} tickets, {float((lp - best) * 100 / best):.2f} percent")
print(f"greedy by tickets per pound, skipping misfits: {greedy}; stopping at the first misfit: {base}; by biggest draw: {big}")
assert best == bb and best <= lp < best + 30                   # table, tree and bound agree
assert big < base < greedy < best                              # every shortcut falls short

# assignment: four headliners, four Saturday slots, crowd in hundreds; maximise
names, slots = ["Kestrel", "Lumen", "Marrow", "Nettle"], ["Main 21:00", "Main 19:00", "Tent 21:00", "Tent 19:00"]
crowd = [[92, 70, 55, 40], [88, 60, 64, 45], [75, 66, 50, 48], [70, 52, 58, 30]]
total = lambda p: sum(crowd[i][p[i]] for i in range(4))
plan = max(plans := perms([0, 1, 2, 3]), key=total)            # road 1: the 24 pairings
on = lambda m, i, j: m >> (4 * i + j) & 1
grids = [m for m in range(2**16) if all(sum(on(m, i, j) for j in range(4)) == 1 for i in range(4))
         and all(sum(on(m, i, j) for i in range(4)) == 1 for j in range(4))]
grid_best = max(sum(crowd[i][j] * on(m, i, j) for i in range(4) for j in range(4)) for m in grids)
free, grab = [0, 1, 2, 3], 0                                   # road 2 above: all 65536 0-1 grids
for i in range(4):                                             # each act grabs its best free slot
    j = max(free, key=lambda j: crowd[i][j]); free.remove(j); grab += crowd[i][j]
print("assignment, crowd in hundreds: " + "; ".join(f"{names[i]} {crowd[i]}" for i in range(4)))
print("  best: " + ", ".join(f"{names[i]} -> {slots[plan[i]]}" for i in range(4)))
print(f"  crowd {total(plan)} hundred; 0-1 grids obeying the rules {len(grids)} of {2**16}, best {grid_best}; "
      f"worst plan {min(map(total, plans))}; grab {grab}")
assert len(grids) == len(plans) == 24 and grid_best == total(plan) and grab < total(plan)

# covering: eight zones, six possible first-aid posts; every zone covered; minimise cost
posts = {"P1": ({3, 4, 5}, 3000), "P2": ({1, 2, 3, 8}, 4500), "P3": ({1, 6, 8}, 3200),
         "P4": ({2, 5, 7}, 3200), "P5": ({1, 2, 3, 4, 6, 7}, 5700), "P6": ({8}, 1500)}
print("covering, zones and pounds: " + "; ".join(f"{p} {sorted(posts[p][0])} {posts[p][1]}" for p in posts))
picks = lambda m: [f"P{k + 1}" for k in range(6) if m >> k & 1]
count = lambda ch, z: sum(1 for p in ch if z in posts[p][0])
cost = lambda ch: sum(posts[p][1] for p in ch)
covers = [picks(m) for m in range(64) if all(count(picks(m), z) >= 1 for z in range(1, 9))]
exact = [picks(m) for m in range(64) if all(count(picks(m), z) == 1 for z in range(1, 9))]
cover = min(covers, key=cost)                                  # road 1: all 64 choices
dp = [0] + [10**9] * 255                                       # road 2: cheapest cost per zone set
for p in posts:
    mask = sum(1 << (z - 1) for z in posts[p][0])
    for s in range(255, -1, -1): dp[s | mask] = min(dp[s | mask], dp[s] + posts[p][1])
left, gcost, gpicks = set(range(1, 9)), 0, []
while left:                                                    # greedy: cheapest per new zone
    p = min((p for p in posts if posts[p][0] & left), key=lambda p: Fraction(posts[p][1], len(posts[p][0] & left)))
    left, gcost, gpicks = left - posts[p][0], gcost + posts[p][1], gpicks + [p]
print(f"  best {'+'.join(cover)} = {cost(cover)} pounds; zone-set table {dp[255]}; {len(covers)} of 64 choices cover")
print(f"  greedy {'+'.join(gpicks)} = {gcost} pounds; 'exactly once' plans: {len(exact)}")
assert cost(cover) == dp[255] == 9400 and gcost > cost(cover) and not exact
# routing: van from the gate G round five stops and back; metres; minimise
stops, edge = "GMFTNS", {"GM": 300, "GF": 200, "MF": 250, "TN": 300, "TS": 350, "NS": 400, "GT": 900, "GN": 1100,
              "GS": 800, "MT": 600, "MN": 800, "MS": 900, "FT": 700, "FN": 1000, "FS": 650}
print("routing, metres: " + " ".join(f"{k}={v}" for k, v in edge.items()))
def routing(edge, show):
    d = [[0 if a == b else edge.get(a + b, edge.get(b + a)) for b in stops] for a in stops]
    tours = [[0] + p for p in perms([1, 2, 3, 4, 5])]          # road 1: all 120 directed tours
    length = lambda t: sum(d[t[k]][t[(k + 1) % 6]] for k in range(6))
    tour = min(tours, key=length)
    moves = [p for p in perms(list(range(6))) if all(p[i] != i for i in range(6))]
    cuts, rounds = [], []                                      # road 2: assignment, then cut loops
    while True:
        ok = [p for p in moves if all(sum(1 for i in S if p[i] in S) <= len(S) - 1 for S in cuts)]
        nxt = min(ok, key=lambda p: sum(d[i][p[i]] for i in range(6)))
        found, seen = [], set()
        for i in range(6):                                     # split the next-stop list into loops
            loop = []
            while i not in seen: seen.add(i); loop.append(i); i = nxt[i]
            found += [loop] if loop else []
        rounds.append(sum(d[i][nxt[i]] for i in range(6)))
        if show:
            print(f"routing round {len(rounds)}: {len(ok)} allowed, best {rounds[-1]} m, loops " + " ".join("".join(stops[k] for k in L) for L in found))
        if len(found) == 1:
            return "".join(stops[k] for k in tour) + "G", length(tour), rounds, len(tours)
        cuts += [set(L) for L in found]
tour, tlen, rounds, ntours = routing(edge, True)
print(f"routing: all {ntours} directed tours, best {tour} = {tlen} m")
assert rounds == sorted(rounds) and rounds[-1] == tlen and rounds[0] < tlen   # cut loop meets brute force
print(f"try: budget 30000 -> {table(acts, 60)[0]} tickets; budget 50000 -> {table(acts, 100)[0]}")
t2, _, r2, _ = routing({**edge, "GT": 500}, False)
print(f"try: track G-T cut to 500 m -> {t2} = {r2[-1]} m after {len(r2)} rounds")
print("ALL CHECKS PASS")
