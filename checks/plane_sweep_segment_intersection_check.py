# Plane sweep -- the check behind the card.  Standard library only.  A vertical line sweeps
# left to right over straight copper tracks.  Tracks are kept in up-down order and only next-door
# tracks are tested for a crossing.  Road two tests every pair (brute force); the answers must agree.
import heapq, math
TRACKS = [((0, 0), (6, 4)), ((0, 4), (6, 0)), ((1, 3), (5, 3)), ((5, 0), (6, 1))]
def orient(a, b, c):                   # twice the signed area of triangle a, b, c
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
def meet(s, t):                        # crossing point of two segments, or None
    (p, q), (r, u) = s, t; d1, d2 = orient(r, u, p), orient(r, u, q)
    if d1 * d2 >= 0 or orient(p, q, r) * orient(p, q, u) >= 0: return None    # no straddle, no crossing
    f = d1 / (d1 - d2)                 # fraction of the way from p to q
    return (p[0] + f * (q[0] - p[0]), p[1] + f * (q[1] - p[1]))
def y_at(s, x):                        # height of segment s where the sweep line stands
    return s[0][1] + (x - s[0][0]) * (s[1][1] - s[0][1]) / (s[1][0] - s[0][0])
def sweep(S, swap=True, log=None):     # an event is (x, kind 0 start / 1 crossing / 2 end, y, a, b)
    ev = [(p[0], 0, p[1], i, i) for i, (p, q) in enumerate(S)] + [(q[0], 2, q[1], i, i) for i, (p, q) in enumerate(S)]; heapq.heapify(ev)
    order, tested, found = [], set(), {}          # order: the tracks the line cuts, bottom to top
    def test(k):                                  # test the next-door pair at positions k, k + 1
        if 0 <= k < len(order) - 1 and (pair := tuple(sorted(order[k:k + 2]))) not in tested:
            tested.add(pair)
            if c := meet(S[pair[0]], S[pair[1]]):
                found[pair] = c
                heapq.heappush(ev, (c[0], 1, c[1]) + pair)
    while ev:
        x, kind, y, a, b = heapq.heappop(ev)
        if kind == 0:                             # a track starts: slot it in by height
            k = sum(y_at(S[j], x) < y for j in order)
            order.insert(k, a); test(k - 1); test(k)
        elif kind == 2:                           # a track ends: its two neighbours become next-door
            k = order.index(a); order.pop(k); test(k - 1)
        elif swap:                                # a crossing: the two tracks swap places
            k = min(order.index(a), order.index(b))
            order[k], order[k + 1] = order[k + 1], order[k]; test(k - 1); test(k + 1)
        if log is not None and (not ev or ev[0][0] != x):
            log.append(f"x = {x:g}: top to bottom " + (", ".join(f"S{j + 1} at {y_at(S[j], x):.2f}" for j in reversed(order)) or "(none left)"))
    return found, tested
def brute(S):                                     # road two: test every pair
    return {(i, j): c for i in range(len(S)) for j in range(i + 1, len(S)) if (c := meet(S[i], S[j]))}
log, names = [], lambda pairs: ", ".join(f"S{i + 1}-S{j + 1}" for i, j in sorted(pairs))
found, tested = sweep(TRACKS, log=log)
print("\n".join(log))
print("\n".join(f"S{i + 1} crosses S{j + 1} at ({x:.2f}, {y:.2f})" for (i, j), (x, y) in sorted(found.items(), key=lambda e: e[1])))
every = {(i, j) for i in range(4) for j in range(i + 1, 4)}
print(f"pairs tested {len(tested)} of {len(every)}: {names(tested)}; never tested: {names(every - tested)}")
r = [2026]                                        # a fixed pseudo-random sequence for a 1000-track board
while len(r) < 4001: r.append((r[-1] * 1103515245 + 12345) % 2 ** 31)
board = [((r[i] % 100000, 3000 + r[i + 1] % 100000), (r[i] % 100000 + 1 + r[i + 2] % 3000,
          r[i + 1] % 100000 + r[i + 3] % 6001)) for i in range(1, 4001, 4)]
bf, (bs, bt), n = brute(board), sweep(board), len(board); k, pairs = len(bs), n * (n - 1) // 2
print(f"board: {n} tracks, {k} crossings by sweep, {len(bf)} by all pairs; events 2n + k = {2 * n + k}")
print(f"board: sweep tested {len(bt)} pairs; all pairs is {pairs}; (n + k) log2 n = {(n + k) * math.log2(n):.0f}")
(ns, _), (nb, _) = sweep(TRACKS, swap=False), sweep(board, swap=False)
print(f"mistake 1, no swap at a crossing: finds {len(ns)} of 4, misses {names(set(found) - set(ns))}; board {len(nb)} of {k}")
print(f"mistake 2, all {n} cross each other (k = {pairs}): (n + k) log2 n = {(n + pairs) * math.log2(n):.0f}, more than {pairs}")
print(f"figure, sweep line x = 4 at {60 + 60 * 4}; crossings " + " ".join(f"({60 + 60 * x:g}, {280 - 60 * y:g})" for x, y in sorted(found.values())))
assert found == brute(TRACKS) and len(found) == 4 and len(tested) == 5              # two roads, one answer
assert bs == bf and len(bt) < pairs // 50                 # the board: same crossings, far fewer tests
assert all(abs(y - y_at(TRACKS[i], x)) + abs(y - y_at(TRACKS[j], x)) < 1e-12 for (i, j), (x, y) in found.items())
assert len(ns) < 4 and len(nb) < k                        # dropping the swap loses crossings
print("ALL CHECKS PASS")
