# Edge colouring and the round-robin -- the check behind the card.  Nothing is imported.  Six teams
# A to F each meet the other five: F is pinned while A to E rotate, so the pin meets team i in round
# i and rotating teams i and j meet in round 3(i + j) mod 5.  Road two is a backtracking search that
# knows no formula and reports the fewest colours it can manage: it settles the six-team league, the
# five-team one, a doubled triangle, and two censuses of small networks against Vizing and Konig.
NAMES = "ABCDEF"
M = 5                                        # the rotating teams, labelled 0 to 4
def rotation():                              # road one: the closed form
    rounds = [[(i, M)] for i in range(M)]    # the pin, team 5, meets team i in round i
    for i in range(M):
        for j in range(i + 1, M): rounds[3 * (i + j) % M].append((i, j))
    return rounds
def maxdeg(n, edges): return max(sum((u == t) + (v == t) for u, v in edges) for t in range(n))
def fewest(n, edges):                        # road two: search, fewest colours first
    for k in range(len(edges) + 1):
        used = [[False] * k for _ in range(n)]
        def place(e):
            if e == len(edges): return True
            u, v = edges[e]
            for c in range(k):
                if not (used[u][c] or used[v][c]):
                    used[u][c] = used[v][c] = True
                    if place(e + 1): return True
                    used[u][c] = used[v][c] = False
            return False
        if place(0): return k
def clash(rs): return any(len({t for m in r for t in m}) != 2 * len(r) for r in rs)
def show(ms): return " ".join(NAMES[u] + "-" + NAMES[v] for u, v in ms)
def yn(c): return "yes" if c else "no"
def subsets(pool): return ([p for i, p in enumerate(pool) if m >> i & 1] for m in range(1 << len(pool)))
pairs6, pairs5 = [[(a, b) for a in range(n) for b in range(a + 1, n)] for n in (6, 5)]
bip = [(a, 3 + b) for a in range(3) for b in range(3)]        # 3 teachers against 3 classes
fat = [(0, 1), (0, 1), (1, 2), (1, 2), (0, 2), (0, 2)]        # a triangle, every match played twice
allsix = {(i, j) for k in range(6) for i in range(6) for j in range(i + 1, 6) if (i + j) % 6 == 2 * k % 6}
rounds = rotation()
grid = [[next((str(r + 1) for r, ms in enumerate(rounds) if (min(u, v), max(u, v)) in ms), ".") for v in range(6)] for u in range(6)]
five = [[m for m in r if M not in m] for r in rounds]         # the same rounds without the pin
d6, k6, d5, k5 = maxdeg(6, pairs6), fewest(6, pairs6), maxdeg(5, pairs5), fewest(5, pairs5)
tally = [0, 0, 0]                            # slot 2 catches any count Vizing forbids
for es in subsets(pairs5): tally[fewest(5, es) - maxdeg(5, es) if es else 0] += 1
konig = all(fewest(6, es) == maxdeg(6, es) for es in subsets(bip) if es)
latin = all(sorted(grid[u][v] for v in range(6) if v != u) == list("12345") for u in range(6))
print(f"six teams {NAMES}: {len(pairs6)} matches, every team meets {d6} others, so at least {d6} rounds")
for r, ms in enumerate(rounds): print(f"  round {r + 1}:  {show(ms)}")
print(f"all {len(pairs6)} pairs, each exactly once: {yn(sorted(m for r in rounds for m in r) == pairs6)}; nobody twice in one round: {yn(not clash(rounds))}\nroad two, a search knowing no formula: fewest rounds {k6}, the busiest team's count {d6}")
print(f"the fixture grid, entry = the round in which the row team meets the column team; every row holds rounds 1 to {M} once: {yn(latin)}\n  " + "    ".join(NAMES[u] + " " + " ".join(grid[u]) for u in range(6)))
print(f"five teams {NAMES[:M]}: {len(pairs5)} matches, every team meets {d5}, and a round holds only {len(five[0])} matches, so fewest rounds {k5} = {d5} + 1\n  " + " | ".join(f"round {r + 1}: {show(five[r])}, {NAMES[r]} rests" for r in range(M)))
print(f"all {1 << len(pairs5)} networks on five named teams: fewest = busiest degree in {tally[0]} of them, one more in {tally[1]}, never worse: {yn(tally[2] == 0)}\nall {1 << len(bip)} bipartite networks, 3 teachers against 3 classes: fewest = busiest degree every time: {yn(konig)}")
print(f"a triangle with every match played twice: busiest degree {maxdeg(3, fat)}, fewest rounds {fewest(3, fat)}, past Vizing's {maxdeg(3, fat) + 1}")
print(f"mistake, all six teams rotating: only {len(allsix)} of the {len(pairs6)} matches ever scheduled, and A-B is not among them: {yn((0, 1) not in allsix)}\nmistake, {len(pairs6)} matches in 4 rounds: 4 rounds x {len(rounds[0])} matches = {4 * len(rounds[0])}, short by {len(pairs6) - 4 * len(rounds[0])}\nmistake, five teams in the busiest count of {d5} rounds: {d5} rounds x {len(five[0])} matches = {d5 * len(five[0])}, short by {len(pairs5) - d5 * len(five[0])}")
assert sorted(m for r in rounds for m in r) == pairs6 and not clash(rounds)
assert k6 == 5 and d6 == 5 and latin
assert k5 == 5 and d5 == 4 and fewest(3, fat) == 6
assert tally == [951, 73, 0] and konig
print("ALL CHECKS PASS")
