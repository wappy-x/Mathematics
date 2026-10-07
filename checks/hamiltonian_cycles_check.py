# Hamiltonian cycles -- the check behind the card.  Nothing is imported.  Three networks:
# the 8 corners of a cube-shaped warehouse, that cube plus four gangways across the middle,
# and the Petersen network of 10 depots.  Every round is counted twice, by backtracking over
# routes and by a tally over sets of corners that builds no route at all.
deg = lambda x: bin(x).count("1")          # a degree: the 1 bits of a neighbour set
low = lambda w: (w & -w).bit_length() - 1  # the lowest-numbered corner in a bit set
fact = lambda k: 1 if k < 2 else k * fact(k - 1)             # k! = 1 x 2 x ... x k
FMT = "{:<17}{:>3}{:>7}{:>9}{:>9}{:>5}{:>7}{:>10}{:>8}{:>9}"
def masks(n, edges):                       # each corner's neighbours, as bits
    return [sum(1 << (v if u == i else u) for u, v in edges if i in (u, v)) for i in range(n)]
def search(m, close=True):                 # road one: backtracking, a route at a time
    n, out, opened = len(m), [], [0]
    def walk(path, left):
        opened[0] += 1                     # one more partial route opened
        if not left and (not close or (m[path[-1]] >> path[0] & 1 and path[1] < path[-1])):
            out.append(path + [path[0]] if close else path)
        w = m[path[-1]] & left
        while w:
            b = w & -w; w -= b
            walk(path + [low(b)], left - b)
    walk([0], (1 << n) - 2)
    return out, opened[0]
def subsets(m):                            # road two: a tally over sets of corners
    n, full = len(m), (1 << len(m)) - 1
    cnt = [[0] * n for _ in range(full + 1)]; cnt[1][0] = 1   # one route: at 0, no step yet
    for s in range(1, full + 1, 2):        # every set of corners that holds corner 0
        for v in range(n):
            c, w = cnt[s][v], m[v] & ~s
            while c and w:
                b = w & -w; w -= b
                cnt[s | b][low(b)] += c    # the same routes, one corner longer
    return sum(cnt[full][v] for v in range(n) if m[0] >> v & 1) // 2
CUBE = [(x, y) for x in range(8) for y in range(x + 1, 8) if deg(x ^ y) == 1]
GANG = CUBE + [(x, 7 - x) for x in range(4)]          # gangways to opposite corners
PET = ([(i, (i + 1) % 5) for i in range(5)] + [(i, i + 5) for i in range(5)]
       + [(i + 5, (i + 2) % 5 + 5) for i in range(5)])
NETS = [("cube warehouse", 8, CUBE), ("cube + gangways", 8, GANG), ("Petersen depots", 10, PET)]
M, found, tally, opened = {}, {}, {}, {}
print(FMT.format("network", "n", "links", "min deg", "odd deg", "n/2", "Dirac", "(n-1)!/2", "search", "subsets"))
for name, n, edges in NETS:
    M[name] = m = masks(n, edges); rounds, opened[name] = search(m)
    found[name], tally[name] = len(rounds), subsets(m)
    d, e, o = min(map(deg, m)), sum(map(deg, m)) // 2, sum(x % 2 for x in map(deg, m))
    print(FMT.format(name, n, e, d, o, f"{n / 2:.1f}", "yes" if d >= n / 2 else "no", fact(n - 1) // 2, found[name], tally[name]))
print("one round on the cube: " + "-".join(map(str, search(M["cube warehouse"])[0][0])))
print(f"partial routes opened by the search: cube {opened['cube warehouse']}, Petersen {opened['Petersen depots']}")
print(f"rounds on cube + gangways, from the K(4,4) count 4! x 3! / 2: {fact(4) * fact(3) // 2}")
print("route over all 10 depots that will not close: " + "-".join(map(str, search(M["Petersen depots"], False)[0][0])))
pairs, dirac, ham, both = [(i, j) for i in range(6) for j in range(i + 1, 6)], 0, 0, 0
for bits in range(1 << 15):                # every network on 6 labelled corners
    m = masks(6, [pairs[i] for i in range(15) if bits >> i & 1])
    d, h = min(map(deg, m)) >= 3, bool(search(m)[0])
    dirac, ham, both = dirac + d, ham + h, both + (d and h)
print(f"of all {1 << 15} networks on 6 corners, {dirac} meet Dirac and all {both} of those have a round")
print(f"of the same {1 << 15}, {ham} have a round, so {ham - both} have one with Dirac silent")
assert [found[k] for k, _, _ in NETS] == [tally[k] for k, _, _ in NETS]   # the two roads agree
assert found["cube + gangways"] == fact(4) * fact(3) // 2 and found["cube + gangways"] == 72
assert found["cube warehouse"] == 6 and found["Petersen depots"] == 0
assert dirac == both < ham                 # Dirac is never wrong, and never necessary
print("ALL CHECKS PASS")
