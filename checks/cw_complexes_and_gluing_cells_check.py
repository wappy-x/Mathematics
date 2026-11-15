# CW complexes -- the check behind the card.  Standard library only.
# A complex is a recipe: vertices, edges (name: tail, head) and 2-cells, each
# 2-cell the word read round its rim.  Lower case runs an edge forwards and the
# capital runs it backwards, so A is a^-1.  Road 1 reads the loop group off the
# recipe: a spanning tree of edges is shrunk, the other edges are generators and
# each 2-cell gives one relation.  Road 2 lifts every short loop to a cover where
# a loop shrinks only if its lift closes up: the square grid for the torus, the
# branching tree for the figure eight.  The closed lifts are counted against
# formulas.  Chi is counted from the cells and, separately, from triangles.
from itertools import combinations, product
from math import comb, gcd

INV = {"a": "A", "A": "a", "b": "B", "B": "b"}

def chi(X):                                # cells counted with signs + - + -
    V, E, F, C3 = X
    return len(V) - len(E) + len(F) - C3

def presentation(X):                       # road 1: shrink a spanning tree
    V, E, F, C3 = X
    boss = {v: v for v in V}
    def find(x):
        return x if boss[x] == x else find(boss[x])
    gens = []
    for name, (tail, head) in E.items():
        if find(tail) == find(head):
            gens.append(name)              # this edge closes a loop: a generator
        else:
            boss[find(tail)] = find(head)  # this edge joins the tree
    rels = ["".join(c for c in w if c.lower() in gens) for w in F]
    return gens, rels

def det(m):                                # whole-number determinant, by rows
    if not m:
        return 1
    return sum((-1) ** j * m[0][j] * det([r[:j] + r[j + 1:] for r in m[1:]])
               for j in range(len(m)) if m[0][j])

def abelianised(gens, rels):               # rank and torsion, from the gcds of minors
    m = [[w.count(g) - w.count(g.upper()) for g in gens] for w in rels]
    d, inv = [1], []
    for k in range(1, min(len(m), len(gens)) + 1):
        g = 0
        for rows in combinations(m, k):
            for cols in combinations(range(len(gens)), k):
                g = gcd(g, det([[r[c] for c in cols] for r in rows]))
        if g == 0:
            break
        inv.append(g // d[-1])
        d.append(g)
    return len(gens) - len(inv), [t for t in inv if t > 1]

def show(label, X):
    gens, rels = presentation(X)
    rank, tors = abelianised(gens, rels)
    rel = ", ".join(r or "1" for r in rels) or "no relations"
    return (f"{label}: cells {len(X[0])}, {len(X[1])}, {len(X[2])}, {X[3]}; chi {chi(X)}; "
            f"pi1 = <{', '.join(gens)} | {rel}>; abelianised rank {rank}, torsion {tors}")

def free_reduce(w):                        # lift to the tree: cancel aA, Bb, ...
    out = []
    for c in w:
        if out and out[-1] == INV[c]:
            out.pop()
        else:
            out.append(c)
    return "".join(out)

def grid_end(w):                           # lift to the square grid: a is one step right
    return (w.count("a") - w.count("A"), w.count("b") - w.count("B"))

def tree_closed(n):                        # closed walks on the 4-branch tree, by depth
    ways = [1] + [0] * n
    for _ in range(n):
        ways = [ways[1]] + [ways[d - 1] * (4 if d == 1 else 3) + (ways[d + 1] if d < n else 0)
                            for d in range(1, n + 1)]
    return ways[0]

one = ["v"]
circle1 = (one, {"a": ("v", "v")}, [], 0)
circle2 = (["v", "w"], {"p": ("v", "w"), "q": ("w", "v")}, [], 0)
eight = (one, {"a": ("v", "v"), "b": ("v", "v")}, [], 0)
torus = (one, {"a": ("v", "v"), "b": ("v", "v")}, ["abAB"], 0)
sphere1 = (one, {}, [""], 0)
sphere2 = (["n", "s"], {"p": ("n", "s"), "q": ("n", "s")}, ["pQ", "qP"], 0)
ball = (one, {}, [""], 1)
klein = (one, {"a": ("v", "v"), "b": ("v", "v")}, ["abAb"], 0)
rp2 = (one, {"a": ("v", "v")}, ["aa"], 0)
box = (one, {"a": ("v", "v"), "b": ("v", "v"), "c": ("v", "v")}, ["abAB", "acAC", "bcBC"], 1)
twist = (one, {"a": ("v", "v"), "b": ("v", "v")}, ["aabb", "aaBB"], 0)  # two torsion numbers: tests 2 x 2 minors
for label, X in (("circle, 1 vertex + 1 edge", circle1), ("circle, 2 vertices + 2 edges", circle2),
                 ("figure eight, 1 vertex + 2 edges", eight), ("torus, 1 vertex + 2 edges + 1 square", torus),
                 ("sphere, 1 vertex + 1 disc", sphere1), ("sphere, 2 vertices + 2 edges + 2 discs", sphere2),
                 ("ball, sphere + 1 solid ball", ball), ("klein bottle, square abAb", klein),
                 ("projective plane, disc aa", rp2), ("3-torus box, 1 + 3 + 3 + 1 cells", box),
                 ("two discs, rims aabb and aaBB", twist)):
    print(show(label, X))
tor_tri = {tuple(sorted(t)) for i, j in product(range(3), repeat=2) for t in
           ((3 * i + j, 3 * ((i + 1) % 3) + j, 3 * ((i + 1) % 3) + (j + 1) % 3),
            (3 * i + j, 3 * i + (j + 1) % 3, 3 * ((i + 1) % 3) + (j + 1) % 3))}
tor_edges = {e for t in tor_tri for e in combinations(t, 2)}
tet = list(combinations(range(4), 3))
tet_edges = {e for t in tet for e in combinations(t, 2)}
chi_tor, chi_tet = 9 - len(tor_edges) + len(tor_tri), 4 - len(tet_edges) + len(tet)
print(f"chi from triangles: torus 9 - {len(tor_edges)} + {len(tor_tri)} = {chi_tor}; "
      f"sphere 4 - {len(tet_edges)} + {len(tet)} = {chi_tet}")
print("loops of length n that shrink to a point (road 2, every word of n letters):")
counts = {}
for n in (2, 4, 6):
    words = ["".join(w) for w in product("aAbB", repeat=n)]
    t = [w for w in words if grid_end(w) == (0, 0)]
    e = [w for w in words if free_reduce(w) == ""]
    counts[n] = (len(t), len(e), set(t) - set(e))
    print(f"  n {n}: of {len(words)} words, torus {len(t)} (formula C({n},{n // 2})^2 = "
          f"{comb(n, n // 2) ** 2}), figure eight {len(e)} (tree walk {tree_closed(n)})")
print(f"  checked on {sum(4 ** n for n in counts)} words")
extra = sorted(counts[4][2])
rims = sorted({r[i:] + r[:i] for r in ("abAB", "baBA") for i in range(4)})
print(f"length 4, closed on the torus only: {len(extra)} words: {' '.join(extra)}")
print(f"  the square's rim abAB read from each corner, either way round: {'yes' if extra == rims else 'no'}")
plan = "aaaBB"
print(f"arm plan abAB: torus lift ends at {grid_end('abAB')}, so it shrinks to staying at home")
print(f"arm plan {plan}: torus lift ends at {grid_end(plan)}, so shoulder 3 turns, elbow -2 turns")
print(f"mistake 1, square left out: abAB on the figure eight reduces to {free_reduce('abAB')}, not 1")
print(f"mistake 2, every edge a generator on the 2-vertex circle: rank {abelianised(list(circle2[1]), [])[0]}, not 1")
print(f"mistake 3, square read abAb (one arrow flipped): rank {abelianised(*presentation(klein))[0]}, "
      f"torsion {abelianised(*presentation(klein))[1]}")
print(f"mistake 4, torus cells counted without signs: 1 + 2 + 1 = {len(torus[0]) + len(torus[1]) + len(torus[2])}, "
      f"not {chi(torus)}")
print("figure, schematic square side 200 at (40, 40); grid unit 40, origin (330, 200); "
      f"abAB corners (0, 0) (1, 0) (1, 1) (0, 1); {plan} ends {grid_end(plan)}")
assert [chi(X) for X in (circle1, circle2, torus, sphere1, sphere2, ball, box)] == [0, 0, 0, 2, 2, 1, 0]
assert chi(torus) == chi_tor and chi(sphere1) == chi_tet          # cells against triangles
assert all(counts[n][0] == comb(n, n // 2) ** 2 and counts[n][1] == tree_closed(n) for n in counts)
assert extra == rims and free_reduce("abAB") == "abAB" and grid_end("abAB") == (0, 0)
assert presentation(circle2) == (["q"], []) and presentation(sphere2) == (["q"], ["Q", "q"])  # tree edge p shrunk
assert [abelianised(*presentation(X)) for X in (circle2, torus, sphere2, klein, rp2, box, twist)] == \
    [(1, []), (2, []), (0, []), (1, [2]), (0, [2]), (3, []), (0, [2, 4])]
print("ALL CHECKS PASS")
