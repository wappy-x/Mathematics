# Hadwiger's conjecture -- the check behind the card.  Standard library only; math gives log and sqrt.
# A graph with no K(t) minor should need at most t - 1 colours.  For three small graphs the script
# finds the chromatic number chi and the largest complete minor h by search, and checks chi <= h.
import math

def graph(n, lines):                          # each dot's neighbours as a bitmask
    adj = [0] * n
    for a, b in lines:
        adj[a] |= 1 << b
        adj[b] |= 1 << a
    return adj

PETERSEN = [(i, (i + 1) % 5) for i in range(5)] + [(5 + i, 5 + (i + 2) % 5) for i in range(5)] + [(i, i + 5) for i in range(5)]
SPINDLE = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (0, 4), (0, 5), (4, 5), (4, 6), (5, 6), (3, 6)]
K22222 = [(a, b) for a in range(10) for b in range(a + 1, 10) if a // 2 != b // 2]

def colourings(adj, k):                       # road 1 to chi: count proper k-colourings, dot by dot
    n, col = len(adj), []
    def go(v):
        if v == n:
            return 1
        total = 0
        for c in range(k):
            if not any(adj[v] >> u & 1 and col[u] == c for u in range(v)):
                col.append(c)
                total += go(v + 1)
                col.pop()
        return total
    return go(0)

def chrom_poly(n, lines, k):                  # road 2: P(k) = sum over line sets S of (-1)^|S| k^(pieces of S)
    total = 0
    for s in range(1 << len(lines)):
        parent = list(range(n))
        def root(x):
            while parent[x] != x:
                x = parent[x]
            return x
        for i, (a, b) in enumerate(lines):
            if s >> i & 1:
                parent[root(a)] = root(b)
        total += (-1) ** bin(s).count("1") * k ** sum(1 for v in range(n) if root(v) == v)
    return total

def connected(adj, m):
    seen = m & -m
    while True:
        grown = seen
        for v in range(len(adj)):
            if seen >> v & 1:
                grown |= adj[v] & m
        if grown == seen:
            return seen == m
        seen = grown

def minor_models(adj, t, stop_at_first):      # K(t) minors: t disjoint joined-up branch sets, each pair touching
    n = len(adj)
    sets = []
    for m in range(1, 1 << n):
        if connected(adj, m):
            out = 0
            for v in range(n):
                if m >> v & 1:
                    out |= adj[v]
            sets.append((m, out & ~m, (m & -m).bit_length() - 1))
    found = 0
    def go(chosen, used, lo):
        nonlocal found
        if len(chosen) == t:
            found += 1
            return stop_at_first
        for m, out, low in sets:              # sets taken in order of their lowest dot, so each model once
            if low >= lo and not m & used and all(out & c for c in chosen) \
                    and n - bin(used | m).count("1") >= t - len(chosen) - 1:
                if go(chosen + [m], used | m, low + 1):
                    return True
        return False
    go([], 0, 0)
    return found

def chi(adj):
    return next(k for k in range(1, len(adj) + 1) if colourings(adj, k) > 0)

def hadwiger(adj):
    return next(t for t in range(1, len(adj) + 2) if minor_models(adj, t, True) == 0) - 1

pet, spin, k5x2 = graph(10, PETERSEN), graph(7, SPINDLE), graph(10, K22222)
tri = sum(1 for a in range(10) for b in range(a) for c in range(b) if pet[a] >> b & 1 and pet[a] >> c & 1 and pet[b] >> c & 1)
print(f"Petersen graph: {len(pet)} dots, {len(PETERSEN)} lines, {tri} triangles")
p2, p3 = colourings(pet, 2), colourings(pet, 3)
q2, q3 = chrom_poly(10, PETERSEN, 2), chrom_poly(10, PETERSEN, 3)
print(f"proper colourings, by search: 2 colours {p2}, 3 colours {p3}; by the chromatic polynomial: P(2) = {q2}, P(3) = {q3}")
spokes = [(1 << i) | (1 << (i + 5)) for i in range(5)]
touch = sum(1 for i in range(5) for j in range(i) if any(pet[v] & spokes[j] for v in range(10) if spokes[i] >> v & 1))
print(f"contract the 5 spokes: {touch} of 10 pairs of fused dots touch, so K(5) is a minor")
k5, k6 = minor_models(pet, 5, False), minor_models(pet, 6, False)
print(f"search: K(5) minor models {k5}, K(6) minor models {k6}; a K(5) set needs 4 exits, one dot has 3, so each model uses 10 dots")
need = next(s for s in range(1, 10) if 3 * s - 2 * (s - 1) >= 5)
print(f"count: a K(6) branch set of s dots has at most s + 2 exits, needs 5, so s >= {need}; 6 x {need} = {6 * need} > 10 dots")
hp, cp = hadwiger(pet), chi(pet)
print(f"Petersen: largest complete minor h = {hp}, chi = {cp}; no K({hp + 1}) minor, so the proved case t = {hp + 1} allows {hp} colours")
print(f"Moser spindle: 3-colourings {colourings(spin, 3)} of {3 ** 7}, P(3) = {chrom_poly(7, SPINDLE, 3)}; "
      f"4-colourings {colourings(spin, 4)}, P(4) = {chrom_poly(7, SPINDLE, 4)}")
hs, cs = hadwiger(spin), chi(spin)
print(f"Moser spindle: h = {hs}, chi = {cs}, equality")
hk, ck = hadwiger(k5x2), chi(k5x2)
om = max(bin(m).count("1") for m in range(1 << 10) if all(k5x2[v] | 1 << v | ~m & 1023 == 1023 for v in range(10) if m >> v & 1))
k8 = minor_models(k5x2, 8, False)
print(f"K(2,2,2,2,2): 10 dots, {len(K22222)} lines; h = {hk}, chi = {ck}; the t <= 7 line formula at t = 8 gives 6 x 10 - 21 = {6 * 10 - 21}")
print(f"K(2,2,2,2,2): K(8) minor models {k8}; count: 8 sets in 10 dots need >= {8 - 2} single dots, "
      f"all joined, but the largest all-joined group has {om}")
print("  t  conjecture  edge-count road 2t-4  best proved")
for t in range(3, 8):
    print(f"{t:>3}{t - 1:>12}{2 * t - 4:>22}{(t - 1 if t <= 6 else 8):>13}")
f = lambda x: 1 - x + 2 * x * math.log(x)
lo, hi = 0.1, 0.5
for _ in range(100):                          # road 1 to Thomason's lambda: bisection
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if f(mid) > 0 else (lo, mid)
x = 0.3
for _ in range(50):                           # road 2: Newton's method, f'(x) = 1 + 2 log x
    x -= f(x) / (1 + 2 * math.log(x))
alpha = (1 - lo) / math.sqrt(math.log(1 / lo))
print(f"Thomason: lambda = {lo:.6f} by bisection, {x:.6f} by Newton; alpha = {alpha:.5f}")
print("  t       extra factor sqrt(log t)  extra factor log log t")
for e in (2, 6, 100):
    lt = e * math.log(10)
    print(f"  10^{e:<5}{math.sqrt(lt):>24.2f}{math.log(lt):>24.2f}")
print(f"mistake 1, minor read as subgraph: no triangle in Petersen, so '2 colours'; true chi = {cp}")
print(f"mistake 2, read backwards: K({hp}) minor, so '{hp} colours'; true chi = {cp}")
print(f"mistake 3, t = 5 applied to Petersen: ceiling 4, but it has a K(5) minor; the case that applies is t = 6, ceiling 5")
print(f"mistake 4, Mader's count past t = 7: {len(K22222)} lines > {6 * 10 - 21}, yet no K(8) minor")
assert p2 == q2 == 0 and p3 == q3 > 0                     # two roads to chi(Petersen) = 3
assert touch == 10 and k5 == 6 and k6 == 0 and hp == 5
assert colourings(spin, 3) == chrom_poly(7, SPINDLE, 3) == 0 and colourings(spin, 4) == chrom_poly(7, SPINDLE, 4) > 0
assert (hs, cs) == (4, 4) and (hk, ck) == (7, 5) and k8 == 0 and om == 5 and len(K22222) > 6 * 10 - 21
assert all(c <= h for c, h in ((cp, hp), (cs, hs), (ck, hk)))  # the conjecture's instances, checked
assert abs(lo - x) < 1e-12 and abs(alpha - 0.63817) < 1e-5  # two roads to lambda; alpha as Thomason states it
print("ALL CHECKS PASS")
