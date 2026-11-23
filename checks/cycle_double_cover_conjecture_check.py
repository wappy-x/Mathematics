# Cycle double cover -- the check behind the card.  Standard library only;
# math gives atan2, cos and sin for the drawings, perm for one count.  Every cycle of each small
# graph is listed by search, and double covers are found by an exact search
# that knows no theory.  Roads: faces of a flat drawing, colour pairs, search.
import math

ring = lambda n, s=0: [(s + i, s + (i + 1) % n) for i in range(n)]

CUBE = ring(4) + ring(4, 4) + [(i, i + 4) for i in range(4)]      # the 8-pad board
CUBE_XY = [(0, 0), (4, 0), (4, 4), (0, 4), (1, 1), (3, 1), (3, 3), (1, 3)]
PET = ring(5) + [(i, i + 5) for i in range(5)] + [(5 + i, 5 + (i + 2) % 5) for i in range(5)]
K4, K5 = ([(a, b) for a in range(n) for b in range(a + 1, n)] for n in (4, 5))
K33 = [(a, b) for a in range(3) for b in range(3, 6)]
DUMBBELL = ring(3) + ring(3, 3) + [(0, 3)]                       # two triangles and a bridge
BOWTIE = ring(3) + [(0, 3), (3, 4), (4, 0)]                       # two triangles, one shared dot
BOWTIE_XY = [(0, 0), (-2, 1), (-2, -1), (2, 1), (2, -1)]
size = lambda c: bin(c).count("1")                                # edges in a cycle mask

def nbrs(n, E):
    adj = [[] for _ in range(n)]
    for k, (a, b) in enumerate(E):
        adj[a].append((b, k)); adj[b].append((a, k))
    return adj

def cycles(n, E):                       # every cycle once, as a bitmask of its edges
    adj, found = nbrs(n, E), set()
    def walk(s, v, seen, mask):
        for w, k in adj[v]:
            if w == s and size(mask) >= 2 and not mask >> k & 1:
                found.add(mask | 1 << k)
            elif w > s and w not in seen:
                walk(s, w, seen | {w}, mask | 1 << k)
    for s in range(n):
        walk(s, s, {s}, 0)
    return sorted(found, key=lambda c: (size(c), c))

def double_cover(m, cyc, k):            # k cycles, repeats allowed, each edge exactly twice
    need = [2] * m
    def go(left):
        e = next((i for i in range(m) if need[i]), None)
        if left == 0 or e is None:
            return [] if left == 0 and e is None else None
        for c in cyc:                   # some cycle of the cover holds edge e
            if c >> e & 1 and all(need[i] for i in range(m) if c >> i & 1):
                for i in range(m):
                    need[i] -= c >> i & 1
                rest = go(left - 1)
                for i in range(m):
                    need[i] += c >> i & 1
                if rest is not None:
                    return [c] + rest
        return None
    return go(k)

def colourings(n, E):                   # proper 3-edge-colourings, counted by backtracking
    col, first = [-1] * len(E), []
    def go(i):
        if i == len(E):
            first[:] = first or col[:]
            return 1
        busy, out = {col[j] for j in range(i) if set(E[j]) & set(E[i])}, 0
        for c in range(3):
            if c not in busy:
                col[i] = c; out += go(i + 1); col[i] = -1
        return out
    return go(0), first

def pieces(n, E):
    adj, seen, count = nbrs(n, E), set(), 0
    for s in range(n):
        if s not in seen:
            count += 1; stack = [s]; seen.add(s)
            while stack:
                for w, _ in adj[stack.pop()]:
                    if w not in seen:
                        seen.add(w); stack.append(w)
    return count

def faces(n, E, xy):                    # trace a flat drawing's faces, dart by dart
    adj = nbrs(n, E)
    turn = [[w for w, _ in sorted(adj[v], key=lambda t: math.atan2(xy[t[0]][1] - xy[v][1],
             xy[t[0]][0] - xy[v][0]))] for v in range(n)]
    used, out = set(), []
    for v0 in range(n):
        for w0 in turn[v0]:
            walk, v, w = [], v0, w0
            while (v, w) not in used:
                used.add((v, w)); walk.append(v)
                v, w = w, turn[w][(turn[w].index(v) - 1) % len(turn[w])]
            out += [walk] if walk else []
    return out

cf = faces(8, CUBE, CUBE_XY)
through = [sum(1 for f in cf for x, y in zip(f, f[1:] + f[:1]) if {x, y} == set(e)) for e in CUBE]
print(f"cube board: V 8, E 12, faces traced {len(cf)}, face lengths {[len(f) for f in cf]}")
print(f"faces by Euler's count E - V + 2 = {12 - 8 + 2}; every face a cycle: {all(len(set(f)) == len(f) for f in cf)}")
print(f"faces through each edge: {through}")
bf = faces(5, BOWTIE, BOWTIE_XY)
print(f"bowtie faces {[len(f) for f in bf]}; outer walk {max(bf, key=len)} passes dot 0 twice")
for name, n, E in [("cube", 8, CUBE), ("K3,3", 6, K33), ("Petersen", 10, PET)]:
    count, col = colourings(n, E)
    pairs = [[e for k, e in enumerate(E) if col[k] != c] for c in range(3)] if count else []
    even = all(sorted(a for e in p for a in e) == sorted(list(range(n)) * 2) for p in pairs)
    print(f"{name}: 3-edge-colourings {count}; cycles in the three colour pairs "
          f"{[pieces(n, p) for p in pairs] or 'none'}")
    assert even and (count == 0) == (name == "Petersen")             # Petersen alone has none
pc = cycles(10, PET)
print(f"Petersen cycles: {len(pc)}, by length {[(L, sum(1 for c in pc if size(c) == L)) for L in (5, 6, 8, 9)]}")
pent = [c for c in pc if size(c) == 5]
six = [[pent[i] for i in range(12) if s >> i & 1] for s in range(1 << 12) if size(s) == 6]
six = [p for p in six if all(sum(c >> e & 1 for c in p) == 2 for e in range(15))]
print(f"pentagons: {len(pent)}; sets of 6 covering every edge twice: {len(six)}; as faces, V - E + F = {10 - 15 + 6}")
for c in six[0]:
    print("  pentagon " + " ".join(f"{min(a, b)}{max(a, b)}" for k, (a, b) in enumerate(PET) if c >> k & 1))
print(f"Petersen flat? girth 5 allows at most 5(V - 2)/3 = {5 * 8 / 3:.2f} edges, it has 15")
print("graph, V, E, cycles, bridges, smallest double cover (cycles)")
best = {}
for name, n, E in [("K4", 4, K4), ("K3,3", 6, K33), ("cube", 8, CUBE), ("K5", 5, K5), ("Petersen", 10, PET)]:
    cyc = cycles(n, E)
    k = -(-2 * len(E) // max(size(c) for c in cyc))               # 2|E| over the longest cycle
    while double_cover(len(E), cyc, k) is None:
        k += 1
    best[name] = double_cover(len(E), cyc, k)
    br = sum(1 for e in E if pieces(n, [f for f in E if f != e]) > 1)
    assert all(sum(c >> e & 1 for c in best[name]) == 2 for e in range(len(E)))   # a real cover
    print(f"  {name}, {n}, {len(E)}, {len(cyc)}, {br}, {k}")
lens = sorted(size(c) for c in best["Petersen"])
print(f"Petersen, 5 cycles: lengths {lens}, adding to {sum(lens)} = 2 x 15; longest cycle 9, so at least {-(-30 // 9)}")
dc = cycles(6, DUMBBELL)
br = [e for e in DUMBBELL if pieces(6, [f for f in DUMBBELL if f != e]) > 1]
print(f"dumbbell: bridges {br}; cycles through edge 03: {sum(c >> 6 & 1 for c in dc)} of {len(dc)}; "
      f"double cover with up to 6 cycles: {any(double_cover(len(DUMBBELL), dc, k) for k in range(1, 7))}")
xy = [(round(210 + r * math.cos(math.radians(90 + 72 * i))), round(190 - r * math.sin(math.radians(90 + 72 * i))))
      for r in (150, 70) for i in range(5)]
print("figure," + ";".join(f"{x} {y}" for x, y in xy))
assert len(cf) == 12 - 8 + 2 and all(t == 2 for t in through)        # faces: two roads agree
assert len(six) == 2 and len(best["Petersen"]) == 5 and len(best["K4"]) == 3
assert br == [(0, 3)] and len(dc) == 2 and not any(c >> 6 & 1 for c in dc)   # bridge on no cycle
assert len(cycles(5, K5)) == sum(math.perm(5, L) // (2 * L) for L in range(3, 6))   # by formula
print("ALL CHECKS PASS")
