# Orientability -- the check behind the card.  Nothing is imported.
# A surface is a grid of square panels with glued sides, or the geodesic dome's
# 80 triangles.  A panel is its list of sides, walked anticlockwise: (edge, +1 or
# -1 for the way the walk runs along it).  Three roads test for a consistent
# turning sense: spreading one panel's sense, trying every choice, the gluing word.

SIDED = {True: "two-sided", False: "one-sided"}

def find(par, p):                         # union-find, written out here
    while par.setdefault(p, p) != p:
        p = par[p]
    return p

def grid(L, H, a_flip, b_glue, b_flip):   # L x H panels; right side glued to left
    par = {}                              # side (a); top to bottom (b) if b_glue
    for y in range(H + 1):
        par[find(par, (L, y))] = find(par, (0, H - y if a_flip else y))
    for x in range(L + 1) if b_glue else []:
        par[find(par, (x, H))] = find(par, (L - x if b_flip else x, 0))
    def side(p, q):                       # carry a glued segment to its partner
        if p[0] == q[0] == L:
            p, q = [(0, H - y if a_flip else y) for x, y in (p, q)]
        elif b_glue and p[1] == q[1] == H:
            p, q = [(L - x if b_flip else x, 0) for x, y in (p, q)]
        return (min(p, q), max(p, q)), (1 if p < q else -1)
    faces = [[side(c[k], c[(k + 1) % 4]) for k in range(4)] for i in range(L) for j in range(H)
             for c in [[(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]]]
    return faces, par

def links(faces, skip=()):                # twist t(e) = +1 if the two walks run opposite
    uses = {}
    for f, sides in enumerate(faces):
        for e, d in sides:
            uses.setdefault(e, []).append((f, d))
    nb = {f: [] for f in range(len(faces))}
    for e, u in uses.items():
        if len(u) == 2 and e not in skip:
            (f, d), (g, d2) = u
            nb[f].append((g, -d * d2))
            nb[g].append((f, -d * d2))
    return uses, nb

def spread(faces, skip=()):               # road one: one sense forces its neighbours
    uses, nb = links(faces, skip)
    s, pieces = {}, []
    for start in range(len(faces)):
        if start not in s:
            s[start], todo, size, ok = 1, [start], 0, True
            while todo:
                f = todo.pop()
                size += 1
                for g, t in nb[f]:
                    if g not in s:
                        s[g] = t * s[f]
                        todo.append(g)
                    elif s[g] != t * s[f]:
                        ok = False
            pieces.append((size, ok))
    return pieces

def brute(faces):                         # road two: try all 2^F choices of sense
    _, nb = links(faces)
    return sum(all(((m >> g) & 1) == ((m >> f) & 1) ^ (t < 0) for f in nb for g, t in nb[f])
               for m in range(2 ** len(faces)))

def word(a_flip, b_glue, b_flip):         # road three: sides read anticlockwise
    w = (["b"] if b_glue else []) + ["a^-1" if a_flip else "a"]
    return w + (["b" if b_flip else "b^-1"] if b_glue else []) + ["a^-1"]

def repeats(w, exact):                    # a letter met twice: same exponent, or at all
    return any([x if exact else x[0] for x in w].count(c) == 2 for c in set(w) | {"a", "b"})

def lap(faces, laps):                     # product of t(e) round the panels 0..L-1
    _, nb = links(faces)
    L, prod = len(faces), 1
    for k in range(L * laps):
        prod *= [t for g, t in nb[k % L] if g == (k + 1) % L][0]
    return prod

def rim(faces, par):                      # free edges joined into circles, 3 cm each
    uses, _ = links(faces)
    loops, free = {}, [e for e, u in uses.items() if len(u) == 1]
    for p, q in free:
        loops[find(loops, find(par, p))] = find(loops, find(par, q))
    roots = [find(loops, find(par, p)) for p, q in free]
    return " + ".join(f"{3 * roots.count(r)} cm" for r in sorted(set(roots))) or "none"

def cut(L, H, a_flip):                    # cut along every line between rows
    faces, _ = grid(L, H, a_flip, False, False)
    lines = {((i, y), (i + 1, y)) for i in range(L) for y in range(1, H)}
    return ", ".join(f"{3 * n} cm {SIDED[ok]}" for n, ok in sorted(spread(faces, lines)))

def dome():                               # icosahedron, each triangle cut in four
    ico = [t for i in range(5) for j in [(i + 1) % 5] for t in
           ((0, 1 + i, 1 + j), (11, 6 + i, 6 + j), (1 + i, 6 + i, 1 + j), (1 + j, 6 + i, 6 + j))]
    mid = {}
    def m(u, v):
        return mid.setdefault((min(u, v), max(u, v)), 12 + len(mid))
    tris = [t for a, b, c in ico for t in ((a, m(a, b), m(a, c)), (b, m(b, c), m(a, b)),
                                           (c, m(a, c), m(b, c)), (m(a, b), m(b, c), m(a, c)))]
    return [[((min(p, q), max(p, q)), 1 if p < q else -1) for p, q in zip(t, t[1:] + t[:1])]
            for t in tris]

SURFACES = [("paper band", 10, 1, False, False, False), ("Mobius strip", 10, 1, True, False, False),
            ("torus", 3, 3, False, True, False), ("Klein bottle", 3, 3, False, True, True),
            ("projective plane", 3, 3, True, True, True)]
res = {}
for name, L, H, af, bg, bf in SURFACES:
    faces, par = grid(L, H, af, bg, bf)
    V, E, F = len({find(par, (x, y)) for x in range(L + 1) for y in range(H + 1)}), len(links(faces)[0]), len(faces)
    ok, w = spread(faces)[0][1], word(af, bg, bf)
    res[name] = (ok, brute(faces), repeats(w, True), V - E + F, repeats(w, False))
    print(f"{name}: V {V}, E {E}, F {F}, chi {V - E + F}; word {' '.join(w)}; spread {SIDED[ok]}; "
          f"choices {res[name][1]} of {2 ** F}; word rule {SIDED[not repeats(w, True)]}; rim {rim(faces, par)}")
band, mob = grid(10, 1, False, False, False)[0], grid(10, 1, True, False, False)[0]
print(f"twist product, one lap: band {lap(band, 1)}, Mobius {lap(mob, 1)}; two laps: Mobius {lap(mob, 2)}")
print(f"cut down the middle: band {cut(10, 2, False)}; Mobius {cut(10, 2, True)}")
print(f"cut a third in: band {cut(10, 3, False)}; Mobius {cut(10, 3, True)}")
du = links(d := dome())[0]
dv = {v for e in du for v in e}
print(f"geodesic dome: V {len(dv)}, E {len(du)}, F {len(d)}, chi {len(dv) - len(du) + len(d)}; every edge on 2 "
      f"panels: {'yes' if all(len(u) == 2 for u in du.values()) else 'no'}; spread {SIDED[spread(d)[0][1]]}")
seam = {e for e, u in links(mob)[0].items() if len(u) == 2 and e[0][0] == 0}
print(f"mistake, chi alone: band {res['paper band'][3]} = Mobius {res['Mobius strip'][3]}, "
      f"torus {res['torus'][3]} = Klein {res['Klein bottle'][3]}")
print(f"mistake, Mobius strip with the glued seam left unchecked: {SIDED[spread(mob, seam)[0][1]]}")
print(f"mistake, any repeated letter taken as a twist: torus {SIDED[not res['torus'][4]]}, "
      f"yet {res['torus'][1]} consistent choices exist")
print("figure, 10 px per cm: band and strip 300 x 30 at (40, 40) and (40, 110); "
      "squares 120 x 120 at (40, 190), (220, 190), (400, 190)")
assert all((r[1] == 2) == r[0] and r[2] == (not r[0]) for r in res.values())   # three roads agree
assert [r[0] for r in res.values()] == [True, False, True, False, False]
assert [r[3] for r in res.values()] == [0, 0, 0, 0, 1]
assert (lap(band, 1), lap(mob, 1), lap(mob, 2)) == (1, -1, 1)
assert cut(10, 2, True) == "60 cm two-sided"
assert cut(10, 3, True) == "30 cm one-sided, 60 cm two-sided"
assert spread(d) == [(80, True)] and (len(dv), len(du)) == (42, 120)
print("ALL CHECKS PASS")
