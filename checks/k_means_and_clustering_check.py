# k-means -- the check behind the card.  Standard library: math only.
# A shop's 20,000 past orders, each described by 12 numbers on a common scale.
# SYNTHETIC: four customer groups, each a centre plus a bell-shaped wobble of
# spread 0.7 in every number, drawn from SplitMix64 with seed 2026.
# Roads: (1) every split of a six-order example, by brute force, against k-means;
# (2) the shift identity behind the update step; (3) the run's objective against
# the generating rule's expected value; (4) the found groups against the true ones.
import math
M64 = (1 << 64) - 1
state = 2026
def rnd():                                      # SplitMix64, a uniform number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def gauss():                                    # Box-Muller: one bell-shaped number from two uniforms
    u1, u2 = 1.0 - rnd(), rnd()
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
def sq(a, b): d = math.dist(a, b); return d * d  # squared straight-line distance
def assign(X, C):                               # each order to its nearest centre
    lab, J = [], 0.0
    for x in X:
        best, bd = 0, sq(x, C[0])
        for j in range(1, len(C)):
            d = sq(x, C[j])
            if d < bd:
                best, bd = j, d
        lab.append(best); J += bd
    return lab, J
def update(X, lab, C):                          # each centre to the mean of its orders
    S, n = [[0.0] * len(X[0]) for _ in C], [0] * len(C)
    for x, l in zip(X, lab):
        n[l] += 1
        for i in range(len(x)):
            S[l][i] += x[i]
    return [[s / n[j] for s in S[j]] if n[j] else C[j] for j in range(len(C))]
def cost(X, lab, C):
    J = 0.0
    for x, l in zip(X, lab):
        J += sq(x, C[l])
    return J
def kmeans(X, C, trace):                        # assign, update, repeat until no label moves
    lab = None
    while True:
        new, J1 = assign(X, C)
        if new == lab:
            return lab, C, J1, len(trace), trace
        lab = new
        C = update(X, lab, C)
        trace.append((J1, cost(X, lab, C)))
def plusplus(X, k):                             # k-means++: each new seed far from the old ones
    C = [X[int(rnd() * len(X))]]
    D = [sq(x, C[0]) for x in X]
    while len(C) < k:
        tot = 0.0
        for d in D:
            tot += d
        r, i = rnd() * tot, 0
        while r >= D[i] and i < len(X) - 1:
            r -= D[i]; i += 1
        C.append(X[i]); D = [min(D[t], sq(X[t], X[i])) for t in range(len(X))]
    return C
def kind(lab, truth, k):                        # orders sharing a group with the majority of their kind
    return sum(max(sum(1 for l, t in zip(lab, truth) if l == j and t == g) for g in range(4)) for j in range(k))

# road 1: six orders, two numbers each (basket value, discount share), k = 2, by hand
P = [(0, 4), (1, 3), (0, 2), (3, 0), (4, 1), (5, 0)]
lab6, C6, J6, it6, tr6 = kmeans(P, [P[0], P[1]], [])
print("six orders, J after each assign -> update:", ", ".join(f"{a:.4f} -> {b:.4f}" for a, b in tr6))
print(f"six orders: stable after {it6} passes; centres " + " and ".join(f"({c[0]:.4f}, {c[1]:.4f})" for c in C6) + f"; J = {J6:.4f}")
splits = [[m >> i & 1 for i in range(6)] for m in range(2, 64, 2)]   # every split with A in group 0: 31
best = min((cost(P, s, update(P, s, [P[0], P[0]])), s) for s in splits)
print(f"brute force over {len(splits)} splits: lowest J = {best[0]:.4f}, with A in a group of", " ".join(c for c, b in zip("ABCDEF", best[1]) if b == 0))
G = P[:3]; m = update(G, [0, 0, 0], [P[0]])[0]
lhs, rhs = cost(G, [0, 0, 0], [P[0]]), cost(G, [0, 0, 0], [m]) + 3 * sq(m, P[0])
print(f"shift identity on A, B, C with centre A: {lhs:.4f} = {cost(G, [0, 0, 0], [m]):.4f} + 3 x {sq(m, P[0]):.4f}")

# the shop: 20,000 orders, 12 numbers, 4 true groups in proportion 4 : 3 : 2 : 1
NAMES = ["family weekly shop", "bargain hunter", "late-night top-up", "big-ticket buyer"]
TRUE_C = [[0.5, 1.5, 0, 1.5, 1, -0.5, 0, 1, 0, 1, -1, -0.5], [-1, 0.5, 2, 0, 0.5, -0.5, 0.5, -1, 0, 0, 0, 0],
          [-0.5, -1, -0.5, -1, -1, 0, 0, 1, 2, 0, -0.5, 0], [2.5, -1, -1, -1, -0.5, 2.5, 0, 1, 0, 0, 2, 1]]
N, SIG = 20000, 0.7
truth = [[0, 0, 0, 0, 1, 1, 1, 2, 2, 3][i % 10] for i in range(N)]
X = [[TRUE_C[t][d] + SIG * gauss() for d in range(12)] for t in truth]
runs = {k: [kmeans(X, plusplus(X, k), []) for _ in range(3)] for k in range(1, 9)}   # 3 starts per k
lab, C, J, it, trace = min(runs[4], key=lambda r: r[2])
print("k = 4, three k-means++ starts stop at J =", ", ".join(f"{r[2]:.1f} ({r[3]} passes)" for r in runs[4]))
for p, (a, b) in enumerate(trace):
    print(f"  best start, pass {p + 1}: J {a:.1f} after assign -> {b:.1f} after update")
expect, sd = N * 12 * SIG * SIG, SIG * SIG * math.sqrt(2 * N * 12)   # N x 12 squared wobbles: mean, SD
print(f"final J = {J:.1f}, per order {J / N:.4f}; the generating rule expects about {expect:.1f} = 20000 x 12 x 0.7^2, SD {sd:.1f}")
for j in range(4):
    cnt = [sum(1 for l, t in zip(lab, truth) if l == j and t == g) for g in range(4)]
    g = cnt.index(max(cnt))
    print(f"  group {j}: {sum(cnt)} orders, {cnt[g]} of them {NAMES[g]}; centre's basket value {C[j][0]:.2f}, discount {C[j][2]:.2f}")
right = kind(lab, truth, 4)
print(f"orders grouped with their own kind: {right} of {N} = {right / N:.4f}")

# choosing k: the elbow on all orders, the silhouette on every 19th order
Js = {k: min(r[2] for r in runs[k]) for k in runs}
S = list(range(0, N, 19))
dist = [[math.dist(X[a], X[b]) for b in S] for a in S]
def silhouette(D, L, k):                        # mean over the orders of (b - a) / max(a, b); D: their distances
    tot = 0.0
    for i in range(len(D)):
        sums, cnt = [0.0] * k, [0] * k
        for j in range(len(D)):
            sums[L[j]] += D[i][j]; cnt[L[j]] += 1
        if cnt[L[i]] > 1:
            a = sums[L[i]] / (cnt[L[i]] - 1)
            b = min(sums[c] / cnt[c] for c in range(k) if c != L[i] and cnt[c])
            tot += (b - a) / max(a, b)
    return tot / len(D)
sil = {k: silhouette(dist, [min(runs[k], key=lambda r: r[2])[0][s] for s in S], k) for k in range(2, 9)}
sil_hand = silhouette([[abs(a - b) for b in (0, 1, 3, 4)] for a in (0, 1, 3, 4)], [0, 0, 1, 1], 2)
for k in range(1, 9):
    print(f"k = {k}: J = {Js[k]:9.1f}" + (f", drop from k - 1 = {Js[k - 1] - Js[k]:8.1f}, silhouette = {sil[k]:.4f}" if k > 1 else ""))
best_k = max(sil, key=lambda k: sil[k])
print(f"silhouette sample: {len(S)} orders; it picks k = {best_k}; lowest J picks k = {min(Js, key=lambda k: Js[k])}")

# what breaks
wl, wC, JB, _, _ = max(runs[4], key=lambda r: r[2])
print(f"worst k = 4 start: J = {JB:.1f}, {JB / J:.4f} times the best; with own kind {kind(wl, truth, 4)}; basket values",
      ", ".join(f"{c[0]:.2f}" for c in wC))
XP = [[45 + 30 * x[0]] + x[1:] for x in X]                   # basket value left in pounds, not on the common scale
rightP = kind(kmeans(XP, plusplus(XP, 4), [])[0], truth, 4)
print(f"basket value left in pounds: grouped with their own kind {rightP} of {N} = {rightP / N:.4f}")
fig = S[::11]                                   # every 11th sampled order goes on the figure
print("figure, centres (basket value, discount):", "; ".join(f"({c[0]:.2f}, {c[2]:.2f})" for c in C) + f"; {len(fig)} orders drawn")

assert abs(best[0] - J6) < 1e-9 and abs(J6 - 16 / 3) < 1e-9 and it6 == 2      # k-means meets brute force
assert abs(lhs - rhs) < 1e-9 and abs(lhs - 6) < 1e-9                             # shift identity
assert all(b <= a + 1e-9 for a, b in trace) and all(trace[i + 1][0] <= trace[i][1] + 1e-9 for i in range(len(trace) - 1))
assert all(Js[k + 1] < Js[k] for k in range(1, 8))                             # more centres, lower J
assert abs(J - expect) < 3 * sd                                                 # run against the generating rule, 3 SD
assert abs(sil_hand - 23 / 35) < 1e-12          # orders at 0, 1 | 3, 4 by hand: (5/7 + 3/5 + 3/5 + 5/7) / 4 = 23/35
assert right / N > 0.99 and best_k == 4 and JB > 1.05 * J and rightP / N < 0.9
print("ALL CHECKS PASS")
