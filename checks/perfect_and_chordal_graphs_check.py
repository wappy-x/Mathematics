# Perfect and chordal graphs -- the check behind the card.  Nothing is imported.  Four meetings need two
# rooms and five rival cafes need three nights: counted by search, by elimination order, by a clock sweep.
MEET = [("Audit", 9.0, 11.0), ("Budget", 10.0, 12.0), ("Clients", 11.5, 13.0), ("Design", 12.5, 14.0)]
def graph(n, pairs):
    adj = [set() for _ in range(n)]
    for a, b in pairs: adj[a].add(b); adj[b].add(a)
    return adj
def ring(n): return graph(n, [(i, (i + 1) % n) for i in range(n)])
def flip(adj): return [{w for w in range(len(adj)) if w != v and w not in adj[v]} for v in range(len(adj))]
def sub(adj, keep): return [{keep.index(w) for w in adj[v] if w in keep} for v in keep]
def subsets(n): return ([i for i in range(n) if m >> i & 1] for m in range(1 << n))
def omega(adj): return max(len(s) for s in subsets(len(adj)) if all(b in adj[a] for a in s for b in s if a < b))
def chi(adj):                                  # fewest colours, by backtracking through every colouring
    def fits(c, k):
        v = len(c)
        return v == len(adj) or any(fits(c + [x], k) for x in range(k) if all(c[w] != x for w in adj[v] if w < v))
    return next(k for k in range(1, len(adj) + 1) if fits([], k))
def perfect(adj): return all(chi(h) == omega(h) for s in subsets(len(adj)) if s for h in [sub(adj, s)])
def eliminate(adj):                            # remove a dot whose remaining neighbours are all joined
    left, order = set(range(len(adj))), []
    while left:
        simp = [v for v in sorted(left) if all(b in adj[a] for a in adj[v] & left for b in adj[v] & left if a < b)]
        if not simp: return order                  # stuck: no perfect elimination order exists
        order.append(simp[0]); left.remove(simp[0])
    return order
def greedy(adj, order):                        # lowest colour no already-coloured neighbour holds
    col = {}
    for v in order: col[v] = min(c for c in range(1, len(adj) + 2) if c not in {col.get(w) for w in adj[v]})
    return [col[v] for v in range(len(adj))]
def is_peo(adj, o): return all(all(b in adj[a] for a in adj[v] & set(o[i + 1:]) for b in adj[v] & set(o[i + 1:]) if a < b) for i, v in enumerate(o))
clock = lambda t: f"{int(t)}:{round(t % 1 * 60):02d}"
n = len(MEET)
meet = graph(n, [(a, b) for a in range(n) for b in range(a + 1, n) if MEET[a][1] < MEET[b][2] and MEET[b][1] < MEET[a][2]])
for name, s, e in MEET:
    print(f"{name:8}|" + "".join("#" if s <= 9 + h / 2 < e else "." for h in range(10)) + f"| {clock(s)}-{clock(e)}")
print("overlapping pairs: " + ", ".join(f"{MEET[a][0]}-{MEET[b][0]}" for a in range(n) for b in sorted(meet[a]) if a < b))
sweep = max(sum(1 for _, s, e in MEET if s <= t < e) for _, t, _ in MEET)
peo = eliminate(meet)
by_peo, by_start, by_arrival = greedy(meet, peo[::-1]), greedy(meet, range(n)), greedy(meet, [0, 3, 1, 2])
print(f"most meetings running at one start time: {sweep}; largest clique {omega(meet)}; fewest rooms {chi(meet)}")
print("elimination order: " + ", ".join(MEET[v][0] for v in peo))
print(f"greedy along the reversed order: {by_peo}; greedy by start time: {by_start}")
print(f"chi = omega on all {2 ** n - 1} induced subgraphs: {'yes' if perfect(meet) else 'no'}")
c5, anti7, c4, mixed = ring(5), flip(ring(7)), ring(4), graph(8, [(i, (i + 1) % 5) for i in range(5)] + [(5, 6), (6, 7), (5, 7)])
print(f"cafe ring: omega {omega(c5)}, chi {chi(c5)}, eliminated {len(eliminate(c5))} of 5, perfect "
      f"{'yes' if perfect(c5) else 'no'}, alpha*omega = {omega(flip(c5))}*{omega(c5)} = {omega(flip(c5)) * omega(c5)} < 5")
print(f"seven-dot antihole: omega {omega(anti7)}, chi {chi(anti7)}")
print(f"ring of {len(c4)}: perfect {'yes' if perfect(c4) else 'no'}, eliminated {len(eliminate(c4))} of {len(c4)}")
flipped = flip(meet)                           # the pairs of meetings that do NOT overlap
print("never overlapping: " + ", ".join(f"{MEET[a][0]}-{MEET[b][0]}" for a in range(n) for b in sorted(flipped[a]) if a < b))
print(f"complement of the meetings: omega {omega(flipped)}, chi {chi(flipped)}, perfect {'yes' if perfect(flipped) else 'no'}")
print(f"mistake, bookings in arrival order Audit, Design, Budget, Clients: rooms {by_arrival} -> {max(by_arrival)}; an elimination order: {'yes' if is_peo(meet, [0, 3, 1, 2]) else 'no'}, reversed: {'yes' if is_peo(meet, [2, 1, 3, 0]) else 'no'}")
print(f"mistake, cafe ring beside a triangle: omega {omega(mixed)}, chi {chi(mixed)}, perfect {'yes' if perfect(mixed) else 'no'}")
assert sweep == omega(meet) == chi(meet) == max(by_peo) == max(by_start) == 2 and len(peo) == n
assert perfect(meet) and max(by_arrival) == 3 and is_peo(meet, peo) and is_peo(meet, [0, 3, 1, 2]) and not is_peo(meet, [2, 1, 3, 0])
assert omega(c5) == 2 and chi(c5) == 3 and eliminate(c5) == [] and not perfect(c5)
assert omega(anti7) == 3 and chi(anti7) == 4 and perfect(c4) and eliminate(c4) == []
assert omega(flipped) == chi(flipped) == 2 and perfect(flipped) and len(eliminate(flipped)) == n
assert omega(mixed) == chi(mixed) == 3 and not perfect(mixed)
print("ALL CHECKS PASS")
