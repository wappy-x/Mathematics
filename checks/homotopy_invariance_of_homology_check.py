# Homotopy invariance of homology -- the check behind the card.  Standard
# library only.  Solids are stacks of unit cubes, each cut into 6 tetrahedra
# along its main diagonal; the dome is an icosahedron with each face cut in 4.
# Road 1: hole counts from the full boundary matrices, by integer Smith form.
# Road 2: collapse the space onto a small core (a deformation), count by hand.
# Road 3: Euler characteristic, simplex counts against the alternating Betti sum.
# Road 4: the prism identity behind the proof, on every simplex of the doughnut.
from itertools import combinations, permutations

def closure(tops):                     # every face of every listed simplex
    return {f for s in tops for k in range(1, len(s) + 1) for f in combinations(s, k)}

def cubes(cells):                      # vertex (x, y, z) is numbered 100x + 10y + z
    return closure([(v, v + p[0], v + p[0] + p[1], v + 111) for x, y, z in cells
                    for v in [100 * x + 10 * y + z] for p in permutations((100, 10, 1))])

def facets(s):                         # (sign, face): drop vertex i, sign (-1)^i
    return [((-1) ** i, s[:i] + s[i + 1:]) for i in range(len(s))] if len(s) > 1 else []

def diagonal(a):                       # integer row and column moves to a diagonal
    piv = []
    while any(a):
        i, j = min(((i, j) for i, r in enumerate(a) for j in r), key=lambda e: abs(a[e[0]][e[1]]))
        p = a[i][j]
        for k, r in enumerate(a):      # clear column j by row moves
            if k != i and j in r:
                q = r[j] // p
                for c, v in a[i].items():
                    r[c] = r.get(c, 0) - q * v
                    if r[c] == 0: del r[c]
        if any(j in r for k, r in enumerate(a) if k != i): continue
        # column j is now clear: column moves leave remainders in row i
        rem = {c: v % p for c, v in a[i].items() if v % p}
        if rem: a[i] = {**rem, j: p}
        else: piv.append(abs(p)); a.pop(i)
    return piv

def homology(cx):                      # Betti numbers and torsion, over the integers
    top = max(len(s) for s in cx)
    by = [sorted(s for s in cx if len(s) == k + 1) for k in range(top)]
    idx = [{s: n for n, s in enumerate(b)} for b in by]
    rank, tors = [0] * (top + 1), []
    for k in range(1, top):            # boundary matrix from dimension k to k - 1
        rows = [{} for _ in by[k - 1]]
        for c, s in enumerate(by[k]):
            for sg, f in facets(s): rows[idx[k - 1][f]][c] = sg
        d = diagonal(rows)
        rank[k] = len(d); tors += [x for x in d if x > 1]
    return [len(b) for b in by], [len(by[k]) - rank[k] - rank[k + 1] for k in range(top)], tors

def collapse(cx):                      # remove a free face with its one coface, repeat
    cx, up = set(cx), {s: set() for s in cx}
    for s in cx:
        for _, f in facets(s): up[f].add(s)
    while free := [t for t in sorted(cx, key=lambda s: (len(s), s)) if len(up[t]) == 1][:1]:
        t = free[0]; s = up[t].pop()
        for x in (s, t):
            cx.discard(x)
            for _, f in facets(x): up[f].discard(x)
    return cx

def graph_betti(core):                 # a graph's counts by hand: pieces, E - V + pieces
    boss = {s[0]: s[0] for s in core if len(s) == 1}
    def find(v):
        return v if boss[v] == v else find(boss[v])
    for s in core:
        if len(s) == 2: boss[find(s[0])] = find(s[1])
    pieces = len({find(v) for v in boss})
    return [pieces, sum(len(s) == 2 for s in core) - len(boss) + pieces]

def chain_d(ch):                       # boundary of a chain {simplex: coefficient}
    out = {}
    for s, c in ch.items():
        for sg, f in facets(s): out[f] = out.get(f, 0) + sg * c
    return out

def prism_ok(cx):                      # d P + P d = top copy - bottom copy, every simplex
    P = lambda ch: {tuple((v, 0) for v in s[:i + 1]) + tuple((v, 1) for v in s[i:]): c * (-1) ** i
                    for s, c in ch.items() for i in range(len(s))}
    def plus(x, y):
        return {q: x.get(q, 0) + y.get(q, 0) for q in set(x) | set(y) if x.get(q, 0) + y.get(q, 0)}
    return all(plus(chain_d(P({s: 1})), P(chain_d({s: 1})))
               == {tuple((v, 1) for v in s): 1, tuple((v, 0) for v in s): -1} for s in cx)

def dome(out):                         # 42 joints, 120 struts, 80 panels; centres in out
    u, l, ico = (lambda i: 1 + i % 5), (lambda i: 6 + i % 5), []
    for i in range(5):
        ico += [(0, u(i), u(i + 1)), (u(i), u(i + 1), l(i)),
                (u(i + 1), l(i), l(i + 1)), (11, l(i), l(i + 1))]
    mid, kept, struts = {}, [], []
    m = lambda a, b: mid.setdefault((min(a, b), max(a, b)), 12 + len(mid))
    for n, (a, b, c) in enumerate(ico):
        ab, ac, bc = m(a, b), m(a, c), m(b, c)
        for t in [(a, ab, ac), (b, ab, bc), (c, ac, bc), (ab, ac, bc)]:
            t = tuple(sorted(t)); struts += combinations(t, 2)
            if not (n in out and t[0] >= 12): kept.append(t)
    return closure(kept + struts)

block = [(x, y, z) for x in range(3) for y in range(3) for z in range(3)]
cup = [c for c in block if c not in [(1, 1, 1), (1, 1, 2)]]       # a well 2 deep, open on top
handle = [(3, 1, 0), (4, 1, 0), (4, 1, 1), (4, 1, 2), (3, 1, 2)]  # gap at (3, 1, 1)
ring = [(x, y, 0) for x in range(3) for y in range(3) if (x, y) != (1, 1)]
lid = [(x, y, 3) for x in range(3) for y in range(3)]
spaces = [("solid block", cubes(block)), ("mug", cubes(cup + handle)),
          ("doughnut", cubes(ring)), ("dome, 3 panels out", dome({0, 14, 19})),
          ("doughnut cut", cubes([c for c in ring if c != (1, 0, 0)])),
          ("closed dome", dome(set())), ("dome, 1 panel out", dome({0})),
          ("mug with a lid", cubes(cup + handle + lid))]
print(f"cubes: block {len(block)}, mug {len(cup + handle)} (cup {len(cup)}, handle {len(handle)}), "
      f"doughnut {len(ring)}, lid {len(lid)}; each cut into {len(list(permutations('xyz')))} tetrahedra")
print("figure, cup x 0-3 z 0-3, well x 1-2 z 1-3, handle x 3-5 z 0-3, gap x 3-4 z 1-2; "
      "ring x 0-3 y 0-3, gap x 1-2 y 1-2")
res = {}
for name, cx in spaces:
    n, b, t = homology(cx)
    core = collapse(cx)
    cn = [sum(len(s) == k + 1 for s in core) for k in range(max(len(s) for s in core))]
    chi, alt = (sum((-1) ** k * x for k, x in enumerate(v)) for v in (n, b))
    res[name] = b
    print(f"{name}: simplices {n}, chi {chi}")
    print(f"  Smith: Betti {b}, alternating sum {alt}, torsion {t if t else 'none'}")
    if len(cn) <= 2:
        print(f"  collapsed core: V {cn[0]}, E {sum(cn[1:])}; pieces and loops by hand {graph_betti(core)}")
        assert graph_betti(core) == b[:2] and not any(b[2:])      # road 2 against road 1
    else:                              # split the core: triangles with their faces, then bare edges
        shell = closure([s for s in core if len(s) == 3])
        print(f"  collapse stalls at {cn}, no free face: a closed shell "
              f"{[sum(len(s) == k + 1 for s in shell) for k in range(3)]} and {sum(len(s) == 2 for s in core - shell)} bare edges")
    bc = homology(core)[1]                                        # the core's own Smith form
    assert bc + [0] * (len(b) - len(bc)) == b and chi == alt and not t   # roads 2, 3 against 1
ok = prism_ok(cubes(ring))
print(f"prism identity on all {len(cubes(ring))} doughnut simplices: {'holds' if ok else 'fails'}")
assert ok                                                         # road 4
assert res["solid block"] == [1, 0, 0, 0] and res["dome, 3 panels out"] == [1, 2, 0]
assert res["mug"] == res["doughnut"] == [1, 1, 0, 0] and res["doughnut cut"] == [1, 0, 0, 0]
assert res["closed dome"] == [1, 0, 1] and res["dome, 1 panel out"] == [1, 0, 0]
assert res["mug with a lid"] == [1, 1, 1, 0]
print("ALL CHECKS PASS")
