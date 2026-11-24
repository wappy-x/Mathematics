# k-d trees and nearest neighbours -- the check behind the card. Nothing is imported.
# Road one searches the tree and skips whole regions; road two measures every depot (brute force).
DEPOTS, Q, Q2, INF = [(2, 3), (5, 4), (9, 6), (4, 7), (8, 1), (7, 2)], (9, 2), (6.5, 0), float("inf")
d2 = lambda p, q: sum((a - b) ** 2 for a, b in zip(p, q))
km, pt = lambda p, q: f"{d2(p, q) ** 0.5:.2f}", lambda p: "(" + ", ".join(f"{c:g}" for c in p) + ")"
px = lambda p: f"({30 + 30 * p[0]:g},{270 - 30 * p[1]:g})"  # figure position: 1 km = 30 units
def build(pts, depth=0):  # the median along this level's axis sits at the node; smaller left, the rest right
    if not pts: return None
    a = depth % len(pts[0]); pts = sorted(pts, key=lambda p: p[a]); m = len(pts) // 2
    return (pts[m], a, build(pts[:m], depth + 1), build(pts[m + 1:], depth + 1))
def nearest(node, q, best, log, rule=lambda gap2, best2: gap2 < best2):  # best = [squared distance, depot]
    if node is None: return best
    p, a, left, right = node; near, far = (left, right) if q[a] < p[a] else (right, left)
    nearest(near, q, best, log, rule)                        # go down the side the query is on
    log.append(p)                                            # on the way back up, measure this depot
    if d2(p, q) < best[0]: best[:] = [d2(p, q), p]
    if rule((q[a] - p[a]) ** 2, best[0]): nearest(far, q, best, log, rule)  # cross only if the line is closer
    return best
def inbox(node, lo, hi, log, out):  # range search: every depot in the box lo..hi
    if node is None: return out
    p, a, left, right = node; log.append(p)
    if all(l <= c <= h for l, c, h in zip(lo, p, hi)): out.append(p)
    if lo[a] <= p[a]: inbox(left, lo, hi, log, out)          # left holds coordinates <= the split
    if hi[a] >= p[a]: inbox(right, lo, hi, log, out)         # right holds coordinates >= the split
    return out
pts_of, depth = lambda t: [] if t is None else [t[0]] + pts_of(t[2]) + pts_of(t[3]), lambda t: 0 if t is None else 1 + max(depth(t[2]), depth(t[3]))
ok = lambda t: t is None or (all(s[t[1]] <= t[0][t[1]] for s in pts_of(t[2])) and all(s[t[1]] >= t[0][t[1]] for s in pts_of(t[3])) and ok(t[2]) and ok(t[3]))
show = lambda t: "-" if t is None else pt(t[0]) + (f" {'xy'[t[1]]}={t[0][t[1]]} {{{show(t[2])} | {show(t[3])}}}" if t[2] or t[3] else "")
T = build(DEPOTS); log = []; b = nearest(T, Q, [INF, None], log); skipped = [p for p in DEPOTS if p not in log]
print(f"tree: {show(T)}\ndepth {depth(T)} levels for n = {len(DEPOTS)}; every split rule holds: {ok(T)}")
print(f"query {pt(Q)}: measured " + ", ".join(f"{pt(p)} {km(p, Q)}" for p in log) + f" -> nearest {pt(b[1])} at {b[0] ** 0.5:.2f}")
print(f"skipped beyond x = 7 (gap {abs(Q[0] - 7):.2f} > {b[0] ** 0.5:.2f}): " + " ".join(f"{pt(p)} {km(p, Q)}" for p in skipped))
brute = min(DEPOTS, key=lambda p: d2(p, Q)); rlog = []; found = inbox(T, (7.5, 0), (10, 3), rlog, [])
print("brute force: " + " ".join(f"{pt(p)} {km(p, Q)}" for p in DEPOTS) + f" -> nearest {pt(brute)} at {km(brute, Q)}")
print(f"box 7.5 <= x <= 10, 0 <= y <= 3: tree visited {len(rlog)} depots, found " + " ".join(map(pt, found)))
l1, l2, l3 = [], [], []; m1, m2 = nearest(T, Q2, [INF, None], l1, lambda g, b: False), nearest(T, Q2, [INF, None], l2)
nearest(T, Q, [INF, None], l3, lambda g, b: True)                # no skipping at all
print(f"mistake 1, never cross a line, query {pt(Q2)}: {pt(m1[1])} at {m1[0] ** 0.5:.2f}; first leaf {pt(l1[0])} at {km(l1[0], Q2)}; true {pt(m2[1])} at {m2[0] ** 0.5:.2f}")
print(f"mistake 2, never skip, query {pt(Q)}: {len(l3)} depots measured, not {len(log)}")
def rnd(seed=[2026]):  # a fixed linear congruential generator, so Python and Rust draw the same numbers
    seed[0] = (seed[0] * 6364136223846793005 + 1442695040888963407) % 2 ** 64; return (seed[0] >> 33) % 1000000
for k, n in [(2, 100), (2, 1000), (2, 10000), (4, 10000), (8, 10000), (16, 10000)]:
    pts = [tuple(rnd() for _ in range(k)) for _ in range(n)]; tree = build(pts); cost = match = 0
    for _ in range(200):
        q = tuple(rnd() for _ in range(k)); lg = []; bq = nearest(tree, q, [INF, None], lg)
        cost += len(lg); match += bq[0] == min(d2(p, q) for p in pts)
    print(f"random, {k} dims, n = {n}: depth {depth(tree)}, measured per query {cost / 200:.1f}, {match} of 200 match brute force")
    assert match == 200 and depth(tree) == n.bit_length() and (k > 2 or cost < 400 * depth(tree))  # exact; log2 n levels; 2 dims: under 2 per level
arena, worst = [], 0                  # 1000 depots on a diagonal, added one at a time in order, no median
for i in range(1000):                 # depot (i, i) walks down from the root and hangs where a branch is empty
    j, d, nd = 0, 1, None
    while j is not None and j < len(arena): nd = arena[j]; side = 3 if i >= nd[0][nd[1]] else 2; j, d = nd[side], d + 1
    if nd: nd[side] = len(arena)
    arena.append([(i, i), (d - 1) % 2, None, None]); worst = max(worst, d)
print(f"1000 depots on a diagonal: added in order, depth {worst}; built at the median, depth {depth(build([(i, i) for i in range(1000)]))}")
print("figure, 1 km = 30 units, depots " + " ".join(map(px, DEPOTS)) + f", query {px(Q)}, circle radius {30 * b[0] ** 0.5:.2f}")
assert b[1] == brute and b[0] == d2(brute, Q) and m2[0] == min(d2(p, Q2) for p in DEPOTS)  # tree against brute force
assert found == [p for p in DEPOTS if 7.5 <= p[0] <= 10 and 0 <= p[1] <= 3]             # range search against a filter
assert ok(T) and skipped == [p for p in DEPOTS if p[0] < 7] and all(d2(p, Q) >= (Q[0] - 7) ** 2 for p in skipped)  # west half skipped, safely
print("ALL CHECKS PASS")
