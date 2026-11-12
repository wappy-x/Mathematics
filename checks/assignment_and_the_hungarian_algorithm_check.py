# The assignment problem -- the check behind the card.  Nothing is imported.  Four bakery drivers,
# four rounds; a cell is that driver's miles on that round.  Road one: the Hungarian method, with
# its receipt.  Road two: every pairing tried.  Road three: a faster method that counts its steps.
DRIVERS, ROUNDS = ["Ana", "Ben", "Cara", "Dev"], ["Riverside", "Hills", "Coast", "Town"]
C = [[70, 24, 62, 21],
     [41, 66, 47, 24],
     [45, 64, 51, 23],
     [27, 73, 27, 34]]
BIG = 1000                                         # stands for "not allowed" in a cost table

def orders(n):                                     # every way to give n drivers n different rounds
    if n == 0: return [[]]
    return [o[:k] + [n - 1] + o[k:] for o in orders(n - 1) for k in range(n)]

def zero_matching(A):                              # most zeros with no two in a row or column
    n, mate = len(A), [-1] * len(A)                # mate[j]: the row holding column j, or -1
    def grow(i, seen):                             # one augmenting path out of row i
        for j in range(n):
            if A[i][j] == 0 and j not in seen:
                seen.add(j)
                if mate[j] < 0 or grow(mate[j], seen):
                    mate[j] = i; return True
        return False
    for i in range(n): grow(i, set())
    return mate

def hungarian(C, log=None):                        # ROAD ONE: the method as done by hand
    n = len(C)
    u = [min(r) for r in C]                        # take each row's smallest number off its row
    v = [min(C[i][j] - u[i] for i in range(n)) for j in range(n)]   # then each column's
    A = [[C[i][j] - u[i] - v[j] for j in range(n)] for i in range(n)]
    if log is not None: log += [("rows", u[:], sum(u)), ("columns", v[:], sum(u) + sum(v), A)]
    while True:
        mate = zero_matching(A)
        if min(mate) >= 0: break                   # n zeros, no two sharing a row or column
        zr = {i for i in range(n) if i not in mate}  # Konig: alternating walks from free rows
        zc, grew = set(), True
        while grew:
            grew = False
            for i in list(zr):
                for j in range(n):
                    if A[i][j] == 0 and j not in zc:
                        zc.add(j); zr.add(mate[j]); grew = True
        lines = (n - len(zr)) + len(zc)            # rows outside the walk, columns inside it
        assert lines == n - mate.count(-1)         # Konig: as many lines as matched zeros
        d = min(A[i][j] for i in zr for j in range(n) if j not in zc)
        for i in zr: u[i] += d                     # take d off every uncovered row ...
        for j in zc: v[j] -= d                     # ... and give it back on every covered column
        A = [[C[i][j] - u[i] - v[j] for j in range(n)] for i in range(n)]
        assert min(min(r) for r in A) >= 0         # no cell may go below zero
        if log is not None: log.append(("adjust", lines, d, sum(u) + sum(v), A))
    pick = [mate.index(i) for i in range(n)]       # driver i takes the column it holds
    return pick, u, v

def fast(C):                                       # ROAD THREE: shortest augmenting paths, O(n^3)
    n, INF, ops = len(C), 10 ** 9, 0
    u, v, p, way = [0] * (n + 1), [0] * (n + 1), [0] * (n + 1), [0] * (n + 1)
    for i in range(1, n + 1):
        p[0], j0, minv, used = i, 0, [INF] * (n + 1), [False] * (n + 1)
        while True:
            used[j0], i0, d, j1 = True, p[j0], INF, 0
            for j in range(1, n + 1):
                if not used[j]:
                    ops += 1                       # one cell looked at: the counted operation
                    cur = C[i0 - 1][j - 1] - u[i0] - v[j]
                    if cur < minv[j]: minv[j], way[j] = cur, j0
                    if minv[j] < d: d, j1 = minv[j], j
            for j in range(n + 1):
                if used[j]: u[p[j]] += d; v[j] -= d
                else: minv[j] -= d
            j0 = j1
            if p[j0] == 0: break
        while j0:
            j1 = way[j0]; p[j0] = p[j1]; j0 = j1
    return sum(C[p[j] - 1][j - 1] for j in range(1, n + 1)), ops

def subsets(C):                                    # exact check at n = 8: best cost per set of rounds used
    n, best = len(C), [0] + [10 ** 9] * ((1 << len(C)) - 1)
    for m in range(1, 1 << n):
        i = bin(m).count("1") - 1                  # driver i takes one of the rounds in m
        best[m] = min(best[m & ~(1 << j)] + C[i][j] for j in range(n) if m >> j & 1)
    return best[-1]
def splitmix(seed, n):                             # synthetic miles 10..99 from SplitMix64
    M, s, out = (1 << 64) - 1, seed, []
    for _ in range(n * n):
        s = (s + 0x9E3779B97F4A7C15) & M
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        out.append(10 + (z ^ (z >> 31)) % 90)
    return [out[r * n:(r + 1) * n] for r in range(n)]
cost = lambda C, o: sum(C[i][o[i]] for i in range(len(C)))
name = lambda o: ", ".join(f"{DRIVERS[i]}-{ROUNDS[j]} {C[i][j]}" for i, j in enumerate(o))
def show(title, T):
    print(title.ljust(6) + "".join(r.rjust(10) for r in ROUNDS))
    for d, row in zip(DRIVERS, T): print(d.ljust(6) + "".join(str(x).rjust(10) for x in row))
show("miles", C)
log = []
pick, u, v = hungarian(C, log)
print(f"row minimums {log[0][1]}, total {log[0][2]}")
print(f"column minimums after that {log[1][1]}, bound {log[1][2]}")
show("cut", log[1][3])
for _, lines, d, bound, A in log[2:]:
    print(f"zeros covered by {lines} lines, smallest uncovered {d}, bound rises {d} x (4 - {lines}) to {bound}")
    show("moved", A)
print(f"road one, Hungarian method: {name(pick)}; total {cost(C, pick)} miles")
print(f"receipt: driver numbers u = {u}, round numbers v = {v}, sum {sum(u) + sum(v)}")
slack = [C[i][j] - u[i] - v[j] for i in range(4) for j in range(4)]
print(f"receipt: smallest u + v gap below a cell = {min(slack)}; cells with no gap = {slack.count(0)}")
all4 = [cost(C, o) for o in orders(4)]
best4 = [o for o in orders(4) if cost(C, o) == min(all4)]
print(f"road two, all {len(all4)} pairings: fewest {min(all4)} miles, most {max(all4)}, pairings at the fewest {len(best4)}")
taken, greedy = set(), 0                           # mistake: each driver in turn grabs the nearest free round
for i in range(4):
    j = min((j for j in range(4) if j not in taken), key=lambda j: C[i][j])
    taken.add(j); greedy += C[i][j]
ban = [r[:] for r in C]; ban[3][1] = 0             # Dev may not drive Hills, typed in as 0
ok = [r[:] for r in C]; ok[3][1] = BIG             # ... and typed in correctly as a huge number
pz, po = hungarian(ban)[0], hungarian(ok)[0]
print(f"mistakes: driver-by-driver grab {greedy} ({greedy - min(all4)} more); each driver's nearest round {log[0][2]}; stop at the bound {log[1][2]}")
print(f"ban typed as 0: {cost(ban, pz)} miles, Dev on {ROUNDS[pz[3]]}; typed as {BIG}: {cost(C, po)} miles, Dev on {ROUNDS[po[3]]}")
f, _ = fast(C)
print(f"road three, shortest augmenting paths: {f} miles")
s8 = splitmix(2026, 8)
h8, d8 = cost(s8, hungarian(s8)[0]), subsets(s8)
print(f"synthetic 8 x 8, seed 2026: Hungarian {h8}, best over all {1 << 8} round sets {d8}, fast {fast(s8)[0]}")
for n in (10, 20, 30):
    s = splitmix(2026 + n, n)
    (fc, ops), hc = fast(s), cost(s, hungarian(s)[0])
    print(f"synthetic {n} x {n}: Hungarian {hc}, fast {fc}, cells looked at {ops} <= n^3 = {n ** 3}")
    assert fc == hc and ops <= n ** 3              # the two methods agree; the n^3 ceiling holds
fact = 1
for k in range(2, 31): fact *= k
print(f"pairings to try by brute force for 30 vans: 30! = {fact}")
assert cost(C, pick) == min(all4) == 115 and best4 == [pick]          # method meets brute force
assert min(slack) == 0 and sum(u) + sum(v) == cost(C, pick)          # receipt: feasible and tight
assert f == 115 and cost(C, po) == min(cost(ok, o) for o in orders(4))
assert h8 == d8 and greedy == 186 and cost(ban, pz) == 113 and pz[3] == 1    # the 0 sends Dev to Hills
assert [e[2] for e in log[:2]] == [95, 98] and [e[1:4] for e in log[2:]] == [(3, 17, 115)]   # the walkthrough
assert u == [21, 41, 40, 27] and v == [0, 3, 0, -17]                  # the receipt on the card
print("ALL CHECKS PASS")
