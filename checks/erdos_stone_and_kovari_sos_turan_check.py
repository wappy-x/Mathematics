# Erdos-Stone and Kovari-Sos-Turan -- the check behind the card.  Nothing is imported.  Points are
# 0 to n-1.  Road one is the cap formula; road two scans every walk a-b-c-d-a for a 4-cycle; road
# three counts cherries two ways; road four searches every network on up to 8 points.
def net(n, links):
    nb = [set() for _ in range(n)]
    for a, b in links: nb[a].add(b); nb[b].add(a)
    return nb
def four_cycles(nb):                    # road two: a-b-c-d-a, each cycle met 8 times
    return sum(1 for a in range(len(nb)) for b in nb[a] for c in nb[b] if c != a
               for d in nb[c] if d not in (a, b) and a in nb[d]) // 8
def cap(n): return n / 4 * (1 + (4 * n - 3) ** 0.5)
def links(nb): return sum(len(s) for s in nb) // 2
def search(n):                          # road four: add pairs one by one, refuse a 4-cycle
    ps, nb, best = [(a, b) for b in range(n) for a in range(b)], [set() for _ in range(n)], [0]
    def go(i, e):
        best[0] = max(best[0], e)
        if i == len(ps) or e + len(ps) - i <= best[0]: return
        a, b = ps[i]
        if not any(nb[x] & nb[a] - {b} for x in nb[b] - {a}):
            nb[a].add(b); nb[b].add(a); go(i + 1, e + 1); nb[a].discard(b); nb[b].discard(a)
        go(i + 1, e)
    go(0, 0); return best[0]
def chi(n, links):                      # fewest colours, by trying every colouring
    k = 1
    while not any(all(c // k ** a % k != c // k ** b % k for a, b in links) for c in range(k ** n)): k += 1
    return k
def polarity(q):                        # points of the plane over 0..q-1; link x, y when x.y = 0 mod q
    pts = [(1, y, z) for y in range(q) for z in range(q)] + [(0, 1, z) for z in range(q)] + [(0, 0, 1)]
    return net(len(pts), [(i, j) for j in range(len(pts)) for i in range(j)
                          if sum(u * v for u, v in zip(pts[i], pts[j])) % q == 0])
two = [(a, b) for b in range(5) for a in range(b)]            # Petersen: pairs from 5, linked if disjoint
pet_links = [(i, j) for j in range(10) for i in range(j) if not set(two[i]) & set(two[j])]
pet = net(10, pet_links); deg = [len(s) for s in pet]; cherries = sum(d * (d - 1) // 2 for d in deg)   # road three, by middles
ends = {(a, b) for v in range(10) for a in pet[v] for b in pet[v] if a < b}  # road three, by end pairs
grown = [four_cycles(net(10, pet_links + [(a, b)])) for b in range(10) for a in range(b) if b not in pet[a]]
found = net(10, [(0, 1), (0, 2), (1, 2), (0, 3), (0, 4), (3, 4), (1, 5), (1, 6), (5, 6), (2, 7), (3, 8), (5, 8), (7, 8), (4, 9), (6, 9), (7, 9)])
brute, pol = [search(n) for n in range(1, 9)], {q: polarity(q) for q in (2, 3)}
x = {"triangle": chi(3, [(0, 1), (1, 2), (0, 2)]), "Petersen": chi(10, pet_links), "4-cycle": chi(4, [(0, 1), (1, 2), (2, 3), (0, 3)])}
a, tri = (1 + 37 ** 0.5) / 2, 1000 * 1000 // 4
print(f"cap on 10 points: 2.5 x (1 + sqrt(37)) = 2.5 x {1 + 37 ** 0.5:.2f} = {cap(10):.2f}, rounded down {int(cap(10))}; 10^1.5 / 2 = {10 ** 1.5 / 2:.2f}")
print(f"Petersen graph: {len(pet)} points, {links(pet)} links, degrees {sorted(set(deg))}, 4-cycles found {four_cycles(pet)}")
print(f"cherries by middles 10 x C(3,2) = {cherries}; distinct end pairs {len(ends)} of C(10,2) = 45")
print(f"average degree 3: 3 x 2 = 6 <= 10 - 1 = 9; at the cap a = {a:.2f}, a(a - 1) = {a * (a - 1):.2f}")
print(f"each of its {len(grown)} missing links, added alone, makes a 4-cycle: {'yes' if min(grown) > 0 else 'no'}")
print(f"a network listed by hand: 10 points, {links(found)} links, 4-cycles {four_cycles(found)}")
print(f"most links with no 4-cycle, n = 1 to 8, by search: {brute}")
print(f"cap rounded down, n = 1 to 8:                       {[int(cap(n)) for n in range(1, 9)]}")
for q, g in pol.items(): print(f"polarity graph q = {q}: {len(g)} points, {links(g)} links, q(q+1)^2/2 = {q * (q + 1) ** 2 // 2}, 4-cycles {four_cycles(g)}, cap {int(cap(len(g)))}")
print(f"colours needed: triangle {x['triangle']}, Petersen {x['Petersen']}, 4-cycle {x['4-cycle']}")
print(f"Erdos-Stone share 1 - 1/(chi - 1): {', '.join(f'{k} {1 - 1 / (v - 1):.3f}' for k, v in x.items())}")
print(f"n = 1000, of 499500 pairs: no triangle {tri} ({tri / 499500:.3f}); no 4-cycle at most {int(cap(1000))}")
print(f"share of pairs at the 4-cycle cap, n = 10, 100, 1000, 10000: {', '.join(f'{int(cap(n)) / (n * (n - 1) // 2):.3f}' for n in (10, 100, 1000, 10000))}")
print(f"mistake, ends taken in order: {2 * cherries} > 45, yet the Petersen graph has {four_cycles(pet)} 4-cycles")
print(f"mistake, chi in place of chi - 1, no triangle, n = 10: {(1 - 1 / 3) * 50:.2f}, Mantel says 25")
assert brute == [0, 1, 3, 4, 6, 7, 9, 11] and all(b <= int(cap(n)) for n, b in zip(range(1, 9), brute))
assert all(abs(2 * cap(n) / n * (2 * cap(n) / n - 1) - (n - 1)) < 1e-6 for n in range(1, 10001))  # a(a-1) = n-1
assert four_cycles(pet) == 0 and len(ends) == cherries == 30 and min(grown) > 0
assert [links(g) for g in pol.values()] == [9, 24] and all(four_cycles(g) == 0 for g in pol.values())
assert list(x.values()) == [3, 3, 2] and links(found) == 16 and four_cycles(found) == 0
print("ALL CHECKS PASS")
