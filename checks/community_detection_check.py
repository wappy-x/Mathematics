# Communities: modularity and a greedy merge, checked.  Python standard library only.
# Synthetic league: 4 divisions of 6 clubs, each division a round robin, plus cup ties
# drawn across divisions by SplitMix64.  Q is kept exact as an integer over 4m^2.
M64 = (1 << 64) - 1
def rng(state):                                   # SplitMix64: returns (new state, 64-bit draw)
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)
def league(seed, ties, divs=4, size=6):           # round robins plus random cross-division ties
    n, edges = divs * size, []
    for g in range(divs):
        edges += [(g * size + i, g * size + j) for i in range(size) for j in range(i + 1, size)]
    st, added = seed, 0
    while added < ties:
        st, r = rng(st); u = r % n
        st, r = rng(st); v = r % n
        e = (min(u, v), max(u, v))
        if u // size != v // size and e not in edges:
            edges.append(e); added += 1
    return n, edges
def degrees(n, edges, lab):                       # total degree d_c and inside lines L_c per group
    d, inside = [0] * n, [0] * n
    for u, v in edges:
        d[lab[u]] += 1; d[lab[v]] += 1
        if lab[u] == lab[v]: inside[lab[u]] += 1
    return d, inside
def qnum(n, edges, lab):                          # 4m^2 Q, community form: sum of 4m L_c - d_c^2
    m = len(edges); d, inside = degrees(n, edges, lab)
    return sum(4 * m * inside[c] - d[c] * d[c] for c in range(n))
def qnum_pairs(n, edges, lab):                    # 4m^2 Q, pair form: sum over i, j of 2m A_ij - k_i k_j
    m, A, k = len(edges), [[0] * n for _ in range(n)], [0] * n
    for u, v in edges: A[u][v] = A[v][u] = 1; k[u] += 1; k[v] += 1
    return sum(2 * m * A[i][j] - k[i] * k[j] for i in range(n) for j in range(n) if lab[i] == lab[j])
def greedy(n, edges):                             # merge the pair with the biggest gain until one group
    m, lab = len(edges), list(range(n))
    q = qnum(n, edges, lab); curve, best, stop = [q], (q, lab[:]), None
    for groups in range(n, 1, -1):
        d, _ = degrees(n, edges, lab); between = {}
        for u, v in edges:
            a, b = min(lab[u], lab[v]), max(lab[u], lab[v])
            if a != b: between[(a, b)] = between.get((a, b), 0) + 1
        pick = None
        for (a, b) in sorted(between):            # gain in units of 1/(2m^2): 2m l_ab - d_a d_b
            gain = 2 * m * between[(a, b)] - d[a] * d[b]
            if pick is None or gain > pick[0]: pick = (gain, a, b)
        if pick is None: break
        gain, a, b = pick
        if gain <= 0 and stop is None: stop = groups
        lab = [a if c == b else c for c in lab]
        new = qnum(n, edges, lab)
        assert new - q == 2 * gain, "merge formula disagrees with a fresh count"
        q = new; curve.append(q)
        if q > best[0]: best = (q, lab[:])
    return best, curve, stop
def best_move(n, edges, lab):                     # biggest gain from moving one club to another group
    base, top = qnum(n, edges, lab), None
    for i in range(n):
        for g in sorted(set(lab)):
            if g != lab[i]:
                trial = lab[:]; trial[i] = g
                gain = qnum(n, edges, trial) - base
                if top is None or gain > top[0]: top = (gain, i, g)
    return top
name = lambda i: "ABCD"[i // 6] + str(i % 6 + 1)
same = lambda lab, n: sum(all((lab[i] == lab[j]) == (i // 6 == j // 6) for j in range(n)) for i in range(n))
f = lambda num, m: num / (4 * m * m)
SEED, TIES = 2026, 16; n, E = league(SEED, TIES); m = len(E); planted = [i // 6 * 6 for i in range(n)]
print(f"league: {n} clubs, 60 division fixtures + {TIES} cup ties = {m} fixtures, seed {SEED}")
print("cup ties:", " ".join(name(u) + "-" + name(v) for u, v in E[60:]))
d, inside = degrees(n, E, planted)
print("division degree totals d_c:", " ".join(f"{name(c)[0]} {d[c]}" for c in range(0, n, 6)), "sum", sum(d))
qa, qb = qnum(n, E, planted), qnum_pairs(n, E, planted)
assert qa == qb, "two forms of Q disagree"
print(f"Q of the divisions: community form {f(qa, m):.4f}, pair form {f(qb, m):.4f}")
print(f"  inside share {sum(inside)}/{m} = {sum(inside) / m:.4f}, expected by chance {sum(x * x for x in d)}/{(2 * m) ** 2} = {sum(x * x for x in d) / (2 * m) ** 2:.4f}")
(qg, lab), curve, stop = greedy(n, E)
k = degrees(n, E, list(range(n)))[0]
g1, u1, v1 = max((2 * m - k[u] * k[v], -u, -v) for u, v in E); u1, v1 = -u1, -v1
print(f"first merge {name(u1)}+{name(v1)}: gain (2*{m}*1 - {k[u1]}*{k[v1]})/(2*{m}^2) = {g1 / (2 * m * m):.4f}")
assert curve[1] - curve[0] == 2 * g1, "first merge disagrees with the hand formula"
print("Q by number of groups, 24 down to 1:")
print(" ".join(f"{f(x, m):.4f}" for x in curve[:12])); print(" ".join(f"{f(x, m):.4f}" for x in curve[12:]))
peak = n - curve.index(max(curve))
print(f"greedy best: {len(set(lab))} groups, Q {f(qg, m):.4f}; peak at {peak} groups; first gain <= 0 at {stop} groups")
assert stop == peak == 4, "stop rule and peak disagree"
print("greedy groups:", " | ".join(" ".join(name(i) for i in range(n) if lab[i] == g) for g in sorted(set(lab))))
print(f"clubs grouped exactly as their division: {same(lab, n)} of {n}")
assert same(lab, n) == n, "planted divisions not recovered"
mv = best_move(n, E, lab)
print(f"best single move: {name(mv[1])} to {name(mv[2])}'s group, change in Q {f(mv[0], m):+.4f}")
assert mv[0] < 0, "greedy answer is not a local peak"
n9, E9 = league(2026, 3, 3, 3)                    # mini league: 3 divisions of 3, every partition
def every(lab, mx):                               # each partition once: the next club joins an old group or opens one
    if len(lab) == n9: yield lab; return
    for g in range(mx + 2): yield from every(lab + [g], max(mx, g))
qs = [qnum(n9, E9, lab) for lab in every([0], 0)]; count, top = len(qs), max(qs)
(q9, _), _, _ = greedy(n9, E9)
print(f"mini league, 9 clubs, 12 fixtures: {count} partitions, best Q {f(top, 12):.4f}, greedy {f(q9, 12):.4f}")
assert count == 21147 and top == q9, "brute force disagrees with greedy"
row = []
for ties in (8, 16, 24, 32, 40, 48):
    ok = 0
    for s in range(1, 21):
        nn, EE = league(s, ties); (_, lb), _, _ = greedy(nn, EE); ok += same(lb, nn) == nn
    row.append(ok)
print("planted test, 20 seeds each: cup ties -> divisions recovered exactly\n  " + "  ".join(f"{t}:{k}" for t, k in zip((8, 16, 24, 32, 40, 48), row)))
assert row[0] == 20 and all(row[i] >= row[i + 1] for i in range(5)), "recovery should fall as ties rise"
print(f"what breaks:\n  no chance term: one big group {1:.4f}, the divisions {sum(inside) / m:.4f}")
print(f"  k_i k_j / m instead of / 2m: the divisions {sum(2 * m * inside[c] - d[c] ** 2 for c in range(n)) / (2 * m * m):.4f}")
n4, E4 = league(2026, 24); m4 = len(E4); (q4, lab4), _, _ = greedy(n4, E4); p4 = qnum(n4, E4, planted)
mv4 = best_move(n4, E4, lab4)
print(f"  24 cup ties: greedy {f(q4, m4):.4f}, divisions {f(p4, m4):.4f}, misplaced",
      " ".join(name(i) for i in range(n4) if lab4[i] != lab4[i // 6 * 6]) + " with " + str(sum(lab4[u] == lab4[v] and u // 6 != v // 6 for u, v in E4)) + " cup ties into its new group" +
      f"; moving {name(mv4[1])} back gives {f(q4 + mv4[0], m4):.4f}")
assert p4 > q4 and q4 + mv4[0] == p4, "greedy should miss here and one move should repair it"
st, R = 2026, []
while len(R) < 76:
    st, r = rng(st); u = r % 24
    st, r = rng(st); v = r % 24
    if u != v and (min(u, v), max(u, v)) not in R: R.append((min(u, v), max(u, v)))
(qr, labr), _, _ = greedy(24, R)
print(f"  76 fixtures at random, no divisions: greedy still finds {len(set(labr))} groups, Q {f(qr, 76):.4f}")
assert qr > 0.15, "random network should still score well"
def ring_q(R):                                    # ring of R five-club cliques: Q with each clique alone, then in pairs
    ring = [(c * 5 + i, c * 5 + j) for c in range(R) for i in range(5) for j in range(i + 1, 5)] + [(c * 5, (c + 1) % R * 5 + 1) for c in range(R)]
    return [f(qnum(5 * R, ring, [i // s for i in range(5 * R)]), len(ring)) for s in (5, 10)]
RING = 30; q1, q2 = ring_q(RING)
print(f"  ring of {RING} five-club cliques: each clique alone {q1:.4f}, in pairs {q2:.4f}")
assert q2 > q1, "resolution limit should show"
hexagon = [(i, (i + 1) % 6) for i in range(6)]; qh = qnum(6, hexagon, [i % 2 for i in range(6)])
print(f"  a 6-cycle split into its two bipartite sides: Q {f(qh, 6):.4f}"); assert qh == -2 * 6 * 6, "sides should score -1/2"
print("figure, division centres (90,65) (270,65) (90,175) (270,175), club ring radius 40")
for s, t in ((8, 16), (2026, 8)):                 # the two other leagues in "Try changing"
    nt, Et = league(s, t); mt = len(Et); (qt, lt), _, _ = greedy(nt, Et)
    mis = [name(i) for i in range(nt) if lt[i] != lt[i // 6 * 6]]; pull = sum(lt[u] == lt[v] and u // 6 != v // 6 for u, v in Et)
    print(f"try: seed {s}, {t} cup ties: greedy {f(qt, mt):.4f}, divisions {f(qnum(nt, Et, planted), mt):.4f}, misplaced {' '.join(mis) or 'none'}, cup ties inside groups {pull}")
print("try: ring of 20 five-club cliques: each clique alone {:.4f}, in pairs {:.4f}".format(*ring_q(20)))
print("ALL CHECKS PASS")
