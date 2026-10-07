# Vertex colouring and the chromatic number -- the check behind the card.  Nothing is imported.  Six
# exams clash when one student sits both, and the fewest sessions is reached twice: by trying every
# colouring, and by a floor from mutual clashes meeting the ceiling Brooks allows.
EXAMS = ["Algebra", "Biology", "Chemistry", "Drama", "Economics", "French"]
STUDENTS = [[0, 1, 2], [3, 4, 5], [0, 3], [1, 4], [2, 5]]
RING, GOOD, LISTED = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]], [0, 5, 1, 3, 2, 4], [0, 1, 2, 3, 4, 5]

def clash_graph(groups, n):                    # one line per pair of exams one student sits
    adj = [set() for _ in range(n)]
    for g in groups:
        for a in g: adj[a] |= {b for b in g if b != a}
    return adj
def biggest(adj, joined):                      # largest set with every pair joined, or none
    pick = ([i for i in range(len(adj)) if m >> i & 1] for m in range(1 << len(adj)))
    ok = [s for s in pick if all((b in adj[a]) == joined for a in s for b in s if a != b)]
    return max(ok, key=len)
def greedy(adj, order):                        # lowest colour no already-coloured neighbour has
    colour = [0] * len(adj)
    for v in order:
        colour[v] = next(c for c in range(1, len(adj) + 2) if c not in {colour[w] for w in adj[v]})
    return colour
def fewest(adj):                               # exhaustive: every assignment of k colours, k up
    n = len(adj)
    for k in range(1, n + 1):
        for m in range(k ** n):
            c = [m // k ** i % k + 1 for i in range(n)]
            if all(c[v] != c[w] for v in range(n) for w in adj[v]): return k

n, adj = len(EXAMS), clash_graph(STUDENTS, len(EXAMS))
edges, deg = sorted((a, b) for a in range(n) for b in adj[a] if a < b), [len(adj[v]) for v in range(n)]
clique, free = biggest(adj, True), biggest(adj, False)
omega, alpha, delta = len(clique), len(free), max(deg)
by_free, good, listed = -(-n // alpha), greedy(adj, GOOD), greedy(adj, LISTED)   # n/alpha, rounded up
ring, tri, inits = clash_graph(RING, 5), clash_graph([[0, 1, 2]], 3), lambda s: "".join(EXAMS[i][0] for i in s)
proper, y = lambda c: all(c[v] != c[w] for v in range(n) for w in adj[v]), lambda t: "yes" if t else "no"
reach = {0} | {w for v in adj[0] | {0} for w in adj[v]}   # every exam within two clashes of Algebra

print(f"exams {n}, students {len(STUDENTS)}, clashing pairs {len(edges)}")
print("clashes by initial: " + " ".join(inits(e) for e in edges))
print(f"clashes at each exam: {deg}, busiest count Delta = {delta}")
print(f"largest all-clashing set: {', '.join(EXAMS[i] for i in clique)} -> omega = {omega}")
print(f"largest clash-free set: {', '.join(EXAMS[i] for i in free)} -> alpha = {alpha}, so {n} exams "
      f"need at least {by_free} sessions")
print(f"greedy in the listed order {inits(LISTED)}: {listed} -> {max(listed)} sessions")
print(f"greedy in the order {inits(GOOD)}: {good} -> {max(good)} sessions")
print(f"Brooks test: one piece {y(len(reach) == n)}, every pair clashing {y(min(deg) == n - 1)}, a ring {y(delta == 2)}")
print(f"floor {max(omega, by_free)} meets Brooks ceiling {delta}, so chi = {max(omega, by_free)}, no search")
print(f"every colouring tried, no bounds used: chi = {fewest(adj)}")
for c in range(1, max(good) + 1):
    print(f"session {c}: " + ", ".join(EXAMS[i] for i in range(n) if good[i] == c))
print(f"no clash inside a session, over all {len(edges)} clashes: {y(proper(good))}")
print(f"mistake 1, the greedy count read as the answer: {max(listed)} sessions, not {fewest(adj)}")
print(f"mistake 2, Brooks on the {inits([0, 1, 2])} triangle alone: every pair clashes, so it is an "
      f"exception; it would claim {max(len(s) for s in tri)}, and chi = {fewest(tri)}")
print(f"mistake 3, the five-exam ring: omega = {len(biggest(ring, True))}, chi = {fewest(ring)}")
assert fewest(adj) == omega == max(good) and proper(good)
assert max(listed) == 4 and max(listed) <= delta + 1 and proper(listed)
assert alpha == 2 and by_free == fewest(adj) and len(reach) == n
assert fewest(ring) == 3 and len(biggest(ring, True)) == 2 and fewest(tri) == 3
print("ALL CHECKS PASS")
