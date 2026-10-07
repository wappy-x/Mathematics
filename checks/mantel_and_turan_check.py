# Mantel and Turan -- the check behind the card.  Nothing is imported.  Servers are
# numbered 0 to n-1 and a link is a pair (a, b) with a < b.  Road one is the formula;
# road two builds each network pair by pair and scans every trio or foursome in it;
# road three searches every possible network on up to 6 servers.
def pairs(xs): return [(a, b) for i, a in enumerate(xs) for b in xs[i + 1:]]
def subsets(xs, k):
    return [[]] if k == 0 else [[x] + s for i, x in enumerate(xs) for s in subsets(xs[i + 1:], k - 1)]
def c2(n): return n * (n - 1) // 2
def turan(n, r):                        # road one: all pairs minus the pairs inside each group
    sizes = [n // r + (1 if i < n % r else 0) for i in range(r)]
    return c2(n) - sum(c2(s) for s in sizes), sizes
def groups_graph(sizes):                # road two: link every pair that sits in different groups
    tag = [g for g, s in enumerate(sizes) for _ in range(s)]
    return {(a, b) for (a, b) in pairs(list(range(len(tag)))) if tag[a] != tag[b]}
def cliques(links, n, k):               # every k servers that are all linked to each other
    return [q for q in subsets(list(range(n)), k) if all(p in links for p in pairs(q))]
def added(links, n, k):                 # cliques made by each missing link, added on its own
    return [len(cliques(links | {m}, n, k)) for m in pairs(list(range(n))) if m not in links]
def best(n, k):                         # road three: every network on n servers, no k all linked
    ps = pairs(list(range(n)))
    masks = [sum(1 << ps.index(p) for p in pairs(q)) for q in subsets(list(range(n)), k)]
    return max(bin(g).count("1") for g in range(1 << len(ps)) if all(g & m != m for m in masks))
N = 10
k55 = groups_graph([5, 5])
deg = [sum(1 for l in k55 if v in l) for v in range(N)]
around = [deg[a] + deg[b] for (a, b) in k55]
star, t3, t2 = groups_graph([1, 9]), groups_graph([4, 3, 3]), groups_graph([5, 5])
tri, grow, grow_star = cliques(k55, N, 3), added(k55, N, 3), added(star, N, 3)
t_formula, t_sizes = turan(N, 3)
quads, grow4 = cliques(t3, N, 4), added(t3, N, 4)
brute3, brute4 = [best(n, 3) for n in range(1, 7)], [best(n, 4) for n in range(1, 7)]
print(f"servers {N}, pairs C(10,2) = {c2(N)}")
print(f"two groups of 5, every cross pair linked: {len(k55)} links; trios all linked: {len(tri)} of {len(subsets(list(range(N)), 3))}")
print(f"Mantel's bound 10 x 10 / 4 = {N * N / 4:.2f}, rounded down: {N * N // 4}")
print(f"each of the {len(grow)} within-group links, added as a 26th: {min(grow)} to {max(grow)} triangles")
print(f"around each link deg(u) + deg(v) = {min(around)} to {max(around)}; summed over links {sum(around)}; "
      f"squared degrees {sum(d * d for d in deg)}; 4 x 25 x 25 / 10 = {4 * len(k55) ** 2 // N}")
print(f"splits 1+9 to 5+5, links: {[len(groups_graph([a, N - a])) for a in range(1, 6)]}")
print(f"star, 1 hub and 9 leaves: {len(star)} links; a triangle from each of its {len(grow_star)} missing links: {'yes' if min(grow_star) > 0 else 'no'}")
print(f"9 servers: 81 / 4 = {81 / 4:.2f}, most links with groups of 4 and 5: {len(groups_graph([4, 5]))}")
print(f"no four all linked, groups {t_sizes}: formula 45 - 6 - 3 - 3 = {t_formula}, counted pair by pair {len(t3)}")
print(f"foursomes all linked in it: {len(quads)} of {len(subsets(list(range(N)), 4))}; bound (1 - 1/3) x 100 / 2 = {(1 - 1 / 3) * N * N / 2:.2f}")
print(f"each of the {len(grow4)} within-group links, added: {min(grow4)} to {max(grow4)} foursomes all linked")
print(f"two groups instead of three, no four all linked: {len(t2)} links, {t_formula - len(t2)} short of {t_formula}")
print(f"share of all pairs, no triangle: 10 servers {N * N // 4} of {c2(N)}, 100 servers {turan(100, 2)[0]} of {c2(100)} = {turan(100, 2)[0] / c2(100):.3f}")
print(f"networks on 6 servers searched: {1 << c2(6)}")
print(f"most links with no triangle, n = 1 to 6, by search:     {brute3}")
print(f"n x n / 4 rounded down:                                  {[n * n // 4 for n in range(1, 7)]}")
print(f"most links with no four all linked, n = 1 to 6, search: {brute4}")
print(f"Turan graph, three groups, by formula:                  {[turan(n, 3)[0] for n in range(1, 7)]}")
assert brute3 == [n * n // 4 for n in range(1, 7)]                # search agrees with Mantel
assert brute4 == [turan(n, 3)[0] for n in range(1, 7)]            # search agrees with Turan
assert len(k55) == N * N // 4 and not tri and min(grow) > 0       # 25 built, triangle-free, full
assert len(t3) == t_formula and not quads and min(grow4) > 0      # 33 built, no foursome, full
print("ALL CHECKS PASS")
