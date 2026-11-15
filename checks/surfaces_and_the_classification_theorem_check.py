# Closed surfaces classified -- the check behind the card.  Standard library only.
# A gluing diagram is a polygon with lettered edges; "a^-1" runs against the walk.
# Road 1 is the by-hand rule on the polygon's corners.  Road 2 cuts the polygon into
# a fan of thin triangles, counts everything again, and tries to orient them all.

def parse(w):                                # "a b^-1" -> [("a", 1), ("b", -1)]
    return [(x[0], -1 if x.endswith("^-1") else 1) for x in w.split()]

def find(p, x):
    while p[x] != x:
        x = p[x]
    return x

def by_corners(w):                           # road 1: corners, edge pairs, one face
    m, p, ends = len(w), list(range(len(w))), {}
    for k, (l, e) in enumerate(w):
        se = (k, (k + 1) % m) if e > 0 else ((k + 1) % m, k)
        if l in ends:                        # glue start to start, end to end
            p[find(p, se[0])] = find(p, ends[l][0])
            p[find(p, se[1])] = find(p, ends[l][1])
        ends[l] = se
    V, E = len({find(p, k) for k in range(m)}), len(ends)
    free = [l for l in ends if [x for x, _ in w].count(l) == 1]
    q = {find(p, k): find(p, k) for k in range(m)}          # rims: free edges joined
    for l in free:
        q[find(q, find(p, ends[l][0]))] = find(q, find(p, ends[l][1]))
    rims = len({find(q, find(p, ends[l][0])) for l in free})
    twisted = any(w[i] == w[j] for i in range(m) for j in range(i + 1, m))
    return V, E, 1, not twisted, rims

def analyse(V, tris):                        # count, test closed, try to orient
    uses = {}
    for i, t in enumerate(tris):
        for edge, sign in t:
            uses.setdefault(edge, []).append((i, sign))
    closed = all(len(u) == 2 for u in uses.values())
    links = {i: [] for i in range(len(tris))}
    for u in uses.values():
        if len(u) == 2:                      # the two must run the shared edge oppositely
            (i, si), (j, sj) = u
            links[i].append((j, -si * sj))
            links[j].append((i, -si * sj))
    side, todo, ok = {0: 1}, [0], True
    while todo:
        i = todo.pop()
        for j, rel in links[i]:
            if j not in side:
                side[j] = side[i] * rel
                todo.append(j)
            elif side[j] != side[i] * rel:
                ok = False
    return V, len(uses), len(tris), ok, closed

def by_fan(w, n):                            # road 2: n triangles per polygon edge
    N, marks, tris = len(w) * n, {}, []
    p = list(range(N + 1))                   # point N is the centre of the fan
    for k, (l, e) in enumerate(w):
        for s in range(n + 1):
            key, q = (l, s if e > 0 else n - s), (k * n + s) % N
            if key in marks and find(p, q) != find(p, marks[key]):
                p[find(p, q)] = find(p, marks[key])
            marks.setdefault(key, q)
        for s in range(n):
            q = k * n + s
            seg = (l, s if e > 0 else n - 1 - s)
            tris.append([(("spoke", q), 1), (seg, e), (("spoke", (q + 1) % N), -1)])
    return analyse(len({find(p, x) for x in range(N + 1)}), tris)

def dome():                                  # icosahedron in a + b*phi, each face cut in 4
    pts = []
    for s1 in (1, -1):
        for s2 in (1, -1):
            for c in range(3):
                v = [(0, 0), (s1, 0), (0, s2)]
                pts.append(tuple(v[(i - c) % 3] for i in range(3)))
    def d2(u, v):                            # squared distance, using phi^2 = phi + 1
        A = B = 0
        for (a1, b1), (a2, b2) in zip(u, v):
            a, b = a1 - a2, b1 - b2
            A, B = A + a * a + b * b, B + 2 * a * b + b * b
        return (A, B)
    near = lambda i, j: d2(pts[i], pts[j]) == (4, 0)
    faces = [(i, j, k) for i in range(12) for j in range(i + 1, 12) for k in range(j + 1, 12)
             if near(i, j) and near(j, k) and near(i, k)]
    mid = {}
    m = lambda i, j: mid.setdefault((min(i, j), max(i, j)), 12 + len(mid))
    small = []
    for i, j, k in faces:
        a, b, c = m(i, j), m(j, k), m(i, k)
        small += [(i, a, c), (a, j, b), (c, b, k), (a, b, c)]
    tris = [[((min(x, y), max(x, y)), 1 if x < y else -1) for x, y in zip(t, t[1:] + t[:1])]
            for t in small]
    return len(faces), analyse(12 + len(mid), tris)

def name(chi, orient):
    if orient:
        g = (2 - chi) // 2
        return {0: "sphere, genus 0", 1: "torus, genus 1"}.get(g, f"genus {g}")
    k = 2 - chi
    return {1: "projective plane, 1 crosscap", 2: "Klein bottle, 2 crosscaps"}.get(k, f"{k} crosscaps")

yn = lambda b: "yes" if b else "no"
CASES = [("inner tube", "a b a^-1 b^-1"), ("Klein bottle", "a b a^-1 b"), ("sphere", "a a^-1 b b^-1"),
         ("projective plane", "a b a b"), ("torus # torus", "a b a^-1 b^-1 c d c^-1 d^-1"),
         ("torus # proj. plane", "a b a^-1 b^-1 c c"), ("three crosscaps", "a a b b c c"),
         ("two crosscaps", "a a b b"), ("half-twist strip", "a b a c"), ("plain band", "a b a^-1 c")]
chi = {}
for label, word in CASES:
    w = parse(word)
    V, E, F, orient, rims = by_corners(w)
    v2, e2, f2, orient2, closed2 = by_fan(w, 3)
    chi[label] = V - E + F
    assert chi[label] == v2 - e2 + f2 and orient == orient2 and (rims == 0) == closed2
    for n in (2, 4, 5):
        v, e, f, _, _ = by_fan(w, n)
        assert v - e + f == chi[label]
    verdict = name(chi[label], orient) if rims == 0 else f"not closed: {rims} rim" + "s" * (rims > 1)
    print(f"{label:20} {word:28} corners {V}-{E}+{F} = {chi[label]:2}; fan {v2}-{e2}+{f2} = "
          f"{v2 - e2 + f2:2}; two-sided {yn(orient)} -> {verdict}")
print("fan cut 2, 3, 4 and 5 triangles per edge: same V - E + F every time: yes")
for a, b, s in [("inner tube", "inner tube", "torus # torus"), ("inner tube", "projective plane", "torus # proj. plane")]:
    print(f"connected sum: {chi[a]} + {chi[b]} - 2 = {chi[a] + chi[b] - 2}, counted {chi[s]}")
    assert chi[a] + chi[b] - 2 == chi[s]
assert chi["inner tube"] == chi["Klein bottle"] == 0 and chi["sphere"] == 2
assert chi["torus # proj. plane"] == chi["three crosscaps"] == -1 and chi["two crosscaps"] == 0
nf, (V, E, F, orient, closed) = dome()
print(f"geodesic dome: icosahedron {nf} faces, each cut in 4: {V} - {E} + {F} = {V - E + F}; "
      f"closed {yn(closed)}, two-sided {yn(orient)} -> {name(V - E + F, orient)}")
assert (nf, V, E, F, closed, orient) == (20, 42, 120, 80, True, True)
tube = parse("a b a^-1 b^-1")
print(f"mistake 1, inner tube with its {len(tube)} corners left unglued: {len(tube)} - 2 + 1 = "
      f"{len(tube) - 2 + 1}, above 2")
V, E, F, orient, _ = by_corners([(l, 1) for l, _ in tube])
print(f"mistake 2, inner tube read with every arrow dropped: chi = {V - E + F}, "
      f"two-sided {yn(orient)} -> {name(V - E + F, orient)}")
assert (V - E + F, orient) == (1, False)
print(f"mistake 3, connected sum with no -2: 0 + 0 = 0 -> torus, but counted {chi['torus # torus']}")
print(f"mistake 4, chi alone: inner tube {chi['inner tube']} and Klein bottle {chi['Klein bottle']}")
print("figure, squares at x = 20, 180, 340, y = 40, side 120; arrows mid-edge")
print("ALL CHECKS PASS")
