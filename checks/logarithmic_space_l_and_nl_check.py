# Logarithmic space -- the check behind the card.  Standard library only.  Space is work-tape bits; the input is read-only.
import math
def bits(k): return max(1, (k - 1).bit_length())   # bits to hold any one of k values
def grid(d):                                   # a valid d by d sudoku, d a square
    s = math.isqrt(d)
    return [(s * (r % s) + r // s + c) % d + 1 for r in range(d) for c in range(d)]
# ---- road 1: the log-space checker; it sees the grid only through one read per step ----
def logspace_check(cells, d):
    s, size, val, reads, ok = math.isqrt(d), {}, {}, 0, True
    def put(name, v, k):                       # one counter on the work tape, range k
        assert 0 <= v < k; size[name], val[name] = bits(k), v
    for kind in range(3):                      # rows, columns, boxes
        put("kind", kind, 3)
        for u in range(d):
            put("unit", u, d)
            for v in range(d):
                put("digit", v, d); put("count", 0, 2)
                for p in range(d):
                    put("pos", p, d)
                    r, c = [(u, p), (p, u), ((u // s) * s + p // s, (u % s) * s + p % s)][kind]
                    put("addr", r * d + c, d * d); reads += 1
                    if cells[val["addr"]] == v + 1:          # the one read of the input
                        ok = ok and val["count"] == 0; put("count", 1, 2)
                ok = ok and val["count"] == 1
    return ok, size, reads
def set_check(cells, d):                       # road 2: hold each row, column and box as a set
    s, R = math.isqrt(d), range(d)
    units = [[r * d + c for c in R] for r in R] + [[r * d + c for r in R] for c in R] + [
        [(br + i) * d + bc + j for i in range(s) for j in range(s)] for br in range(0, d, s) for bc in range(0, d, s)]
    return all(sorted(cells[i] for i in u) == list(range(1, d + 1)) for u in units)
g = grid(9)
ok, size, reads = logspace_check(g, 9)
W9 = sum(size.values())
print("9 x 9 grid by rows: " + " / ".join("".join(str(x) for x in g[r * 9:r * 9 + 9]) for r in range(9)))
print(f"input n = 81 cells x {bits(10)} bits = {81 * bits(10)} bits; log2 81 = {math.log2(81):.2f}, log2 9 = {math.log2(9):.2f}")
print("work counters: " + ", ".join(f"{k} {b}" for k, b in size.items()) + f"; total {W9} bits")
print(f"verdict {ok}, input reads {reads:,} = 3 x 9^3")
assert ok and set_check(g, 9) and reads == 3 * 9 ** 3
changed = [g[:i] + [v] + g[i + 1:] for i in range(81) for v in range(1, 10) if v != g[i]]
bad = sum(not logspace_check(h, 9)[0] for h in changed)
agree = sum(logspace_check(h, 9)[0] == set_check(h, 9) for h in changed)
print(f"one-cell changes: {bad} of {len(changed)} rejected; roads 1 and 2 agree on {agree}")
assert bad == agree == len(changed) == 648
print("sizes: d, input bits n, log2 n, work bits, work / log2 n, input reads")
for d in (4, 9, 16, 25, 36, 49):
    ok, size, reads = logspace_check(grid(d), d)
    n, w = d * d * bits(d + 1), sum(size.values())
    print(f"  d {d:>2}  n {n:>6,}  log2 n {math.log2(n):5.2f}  work {w:>2}  ratio {w / math.log2(n):.2f}  reads {reads:>7,}")
    assert ok and w <= 3 * math.log2(n)       # logarithmic in n, not linear
# ---- the 1,000-room maze: two one-way doors per room, SplitMix64 seed 2029 ----
MASK = (1 << 64) - 1
class Rng:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK; z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
def maze(rng, rooms): return [[rng.next() % rooms, rng.next() % rooms] for _ in range(rooms)]
def bfs(adj, s):                               # road A: breadth-first search, one mark per room
    dist, queue = {s: 0}, [s]
    for u in queue:
        for v in adj[u]:
            if v not in dist:
                dist[v] = dist[u] + 1; queue.append(v)
    return dist
def branches(adj, s, t, cap):                  # road B: run every guess sequence of the walker
    count, level = 0, [s]
    for _ in range(cap):
        level = [v for u in level for v in adj[u]]; count += level.count(t)
    return count
rng, N, T = Rng(2029), 1000, 999
adj = maze(rng, N)
dist = bfs(adj, 0)
t_no = min(x for x in range(N) if x not in dist)
print(f"maze: {N:,} rooms; room {T} is {dist[T]} doors from room 0; {len(dist)} rooms reachable; room {t_no} is not")
hits = branches(adj, 0, T, dist[T])
print(f"walker: {hits} of the 2^{dist[T]} = {2 ** dist[T]:,} guess sequences of {dist[T]} doors reach room {T}")
print(f"walker stores room ({bits(N)} bits) + steps ({bits(N)} bits) = {2 * bits(N)} bits; BFS marks {N:,} bits")
assert hits > 0 and branches(adj, 0, T, dist[T] - 1) == 0 and branches(adj, 0, t_no, 14) == 0
walk, cur, short = [0], 0, []                  # a blind walk, then cut out its loops
while cur != T:
    cur = adj[cur][rng.next() % 2]; walk.append(cur)
for r in walk:
    short = (short[:short.index(r)] if r in short else short) + [r]
print(f"a random walk reaches room {T} in {len(walk) - 1:,} doors; cutting loops leaves {len(short) - 1} doors")
assert all(b in adj[a] for a, b in zip(short, short[1:])) and dist[T] <= len(short) - 1 <= N - 1
# ---- road C: Savitch: a path of at most 2^k doors splits at a midpoint ----
def reach(adj, u, v, k, depth, st):
    st[0], st[1] = st[0] + 1, max(st[1], depth)
    if k == 0:
        return u == v or v in adj[u]
    return any(reach(adj, u, w, k - 1, depth + 1, st) and reach(adj, w, v, k - 1, depth + 1, st) for w in range(len(adj)))
small, K, st = maze(rng, 8), bits(7), [0, 0]
pairs = [(bfs(small, s).get(e, -1), s, e) for s in range(8) for e in range(8)]
agree, far = sum(reach(small, s, e, K, 0, st) == (d >= 0) for d, s, e in pairs), max(pairs)
print(f"small maze {small}: Savitch with {K} levels agrees with BFS on {agree} of 64 pairs")
print(f"  {st[0]:,} calls in all, at most {st[1]} levels below the top; farthest pair: rooms {far[1]} to {far[2]}, {far[0]} doors")
assert agree == 64 and st[1] == K
print("bits: rooms, walker 2m, Savitch layout 2m + k(m + 1), (log2 rooms)^2, BFS marks; log10 of Savitch call bound (2N)^k")
for r in [10 ** e for e in range(1, 7)]:
    m, k = bits(r), bits(r - 1)
    print(f"  rooms {r:>9,}  walker {2 * m:>2}  savitch {2 * m + k * (m + 1):>3}  square {math.log2(r) ** 2:6.1f}  bfs {r:>9,}  calls {k * math.log10(2 * r):6.1f}")
assert 2 * bits(N) + bits(N - 1) * (bits(N) + 1) == 130 and abs(math.log2(N) ** 2 - 99.3) < 0.05
# ---- road D: an NL machine on a 4 by 4 grid, turned into a PATH question ----
D = 4                                          # "some row repeats a digit": guess a row and two columns
def moves(cfg, sym):                           # cfg = (state, head, row, col1, col2, digit)
    q, h, r, a, b, v = cfg
    if q == 0:
        return [(1, h, r2, a2, b2, 0) for r2 in range(D) for a2 in range(D) for b2 in range(a2 + 1, D)]
    if q == 3:
        return []
    goal = r * D + (a if q == 1 else b)
    if h != goal:                              # walk the input head one cell
        return [(q, h + (1 if h < goal else -1), r, a, b, v)]
    return [(2, h, r, a, b, sym)] if q == 1 else [(3, 0, 0, 0, 0, 0)] if sym == v else []
ALL = [(q, h, r, a, b, v) for q in range(4) for h in range(D * D) for r in range(D) for a in range(D) for b in range(D) for v in range(D + 1)]
def to_path(cells):                            # the reduction: list every edge, one at a time
    return {c: moves(c, cells[c[1]]) for c in ALL}
base = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1]
tests = [base] + [base[:i] + [v] + base[i + 1:] for i in range(16) for v in range(1, 5) if v != base[i]]
tests += [base[:r * 4] + [base[r * 4 + (b if j == a else a if j == b else j)] for j in range(4)] + base[r * 4 + 4:]
          for r in range(4) for a in range(4) for b in range(a + 1, 4)]
yes = agree = 0
for cells in tests:
    direct = any(cells[r * D + a] == cells[r * D + b] for r in range(D) for a in range(D) for b in range(a + 1, D))
    yes, agree = yes + direct, agree + (direct == ((3, 0, 0, 0, 0, 0) in bfs(to_path(cells), ALL[0])))
print(f"reduction: {len(ALL):,} configurations = 4 x 16 x 4 x 4 x 4 x 5, index {bits(len(ALL))} bits; {sum(len(x) for x in to_path(base).values()):,} edges for the solved grid")
print(f"  {len(tests)} grids, {yes} with a repeated digit in a row; machine and PATH agree on {agree}")
assert agree == len(tests) and yes == 48
# ---- what breaks ----
print(f"wrong: copying the 9 x 9 grid to the work tape: {81 * bits(10)} bits, against {W9}")
print(f"wrong: walker capped at {dist[T] - 1} steps: {branches(adj, 0, T, dist[T] - 1)} branches reach room {T}")
seen, cur, step = {}, 0, 0
while cur not in seen and cur != T:
    seen[cur], cur, step = step, adj[cur][0], step + 1
print(f"wrong: always the first door: room {cur} repeats at step {step} (first seen at step {seen[cur]}), so room {T} is never reached")
assert cur != T
print(f"wrong: Savitch with 1 level, rooms {far[1]} to {far[2]}: {reach(small, far[1], far[2], 1, 0, [0, 0])}")
assert far[0] > 2 and not reach(small, far[1], far[2], 1, 0, [0, 0])
print("ALL CHECKS PASS")
