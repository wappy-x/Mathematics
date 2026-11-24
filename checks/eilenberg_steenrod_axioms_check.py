# Eilenberg-Steenrod axioms -- the check behind the card.  Standard library only.
# Road 1: the axioms' bookkeeping walks one Z from a point up the spheres.  Road 2:
# simplicial homology over Z by integer Smith form, on discs, rims, pairs, spheres
# and a 42-joint dome.  Road 3: collapses (homotopy axiom) and cells, no matrices.
from itertools import combinations
from math import sin, pi, floor, ceil

def smith(m):                        # invariant factors of an integer matrix
    m, out = [r[:] for r in m if any(r)], []
    while m:
        _, i, j = min((abs(v), i, j) for i, r in enumerate(m) for j, v in enumerate(r) if v)
        m[0], m[i] = m[i], m[0]
        for r in m: r[0], r[j] = r[j], r[0]
        p = m[0][0]
        for r in m[1:]:              # clear column 0, then row 0, by the pivot
            q = r[0] // p
            r[:] = [a - q * b for a, b in zip(r, m[0])]
        q = [v // p for v in m[0]]
        for r in m: r[1:] = [a - k * r[0] for a, k in zip(r[1:], q[1:])]
        if any(r[0] for r in m[1:]) or any(m[0][1:]):
            continue                 # a smaller remainder becomes the next pivot
        bad = [r for r in m[1:] if any(v % p for v in r)]
        if bad:                      # pivot fails to divide the rest: mix a row in
            m[0] = [a + b for a, b in zip(m[0], bad[0])]
            continue
        out.append(abs(p))
        m = [r[1:] for r in m[1:] if any(r[1:])]
    return out

def homology(cx, rel=()):            # groups of complex cx relative to subcomplex rel
    cells = [[] for _ in range(max(map(len, cx)) + 1)]
    for s in sorted(set(cx) - set(rel)):
        cells[len(s) - 1].append(s)
    facs = [[]]
    for k in range(1, len(cells)):
        pos = {s: i for i, s in enumerate(cells[k - 1])}
        mat = [[0] * len(cells[k]) for _ in cells[k - 1]]
        for j, s in enumerate(cells[k]):
            for i in range(len(s)):  # face i of s, with sign (-1)^i
                if s[:i] + s[i + 1:] in pos:
                    mat[pos[s[:i] + s[i + 1:]]][j] = (-1) ** i
        facs.append(smith(mat))
    return [(len(cells[k]) - len(facs[k]) - len(facs[k + 1]),
             [d for d in facs[k + 1] if d > 1]) for k in range(len(cells) - 1)]

def show(h):                         # "Z^2 + Z/2" style, one group per degree
    return ", ".join(" + ".join((["Z" if r == 1 else f"Z^{r}"] if r else [])
                                + [f"Z/{d}" for d in t]) or "0" for r, t in h)

def closure(top):                    # every face of every listed simplex
    return sorted({f for s in top for k in range(1, len(s) + 1) for f in combinations(s, k)})

def axiom_spheres(point, n_max):     # reduced ranks by degree: S0 is the point's, then shift
    rows = [dict(point)]
    for _ in range(n_max):           # pair sequence with D contractible, then excision
        rows.append({k + 1: r for k, r in rows[-1].items()})
    return [[d.get(k, 0) for k in range(n_max + 1)] for d in rows]

up, lo = [1, 2, 3, 4, 5], [6, 7, 8, 9, 10]      # icosahedron: top 0, two rings, bottom 11
ico = [f for i in range(5) for f in ((0, up[i], up[i - 4]), (up[i], up[i - 4], lo[i]),
       (up[i - 4], lo[i], lo[i - 4]), (11, lo[i], lo[i - 4]))]
mid, dome, centre = {}, [], []
for a, b, c in ico:                  # each face into four panels, struts halved
    ab, bc, ca = (mid.setdefault(tuple(sorted(e)), 12 + len(mid)) for e in ((a, b), (b, c), (c, a)))
    dome += [tuple(sorted(t)) for t in ((a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca))]
    centre.append(tuple(sorted((ab, bc, ca))))
holes = [centre[0], centre[13], centre[19]]     # three panels with no joint in common

def collapse(panels):                # remove free struts with their panel, then leaf struts
    faces = set(panels)
    edges = {e for f in faces for e in combinations(f, 2)}
    while free := [e for e in sorted(edges) if sum(set(e) <= set(f) for f in faces) == 1]:
        faces = {f for f in faces if not set(free[0]) <= set(f)}
        edges.discard(free[0])
    verts = sorted({v for e in edges for v in e})
    while len(verts) > 1 and (leaf := [v for v in verts if sum(v in e for e in edges) <= 1]):
        verts.remove(leaf[0])
        edges = {e for e in edges if leaf[0] not in e}
    return len(faces), len(verts), len(edges)

def warsaw(n):                       # grid cells of side 1/n meeting the Warsaw circle
    h, xe = 1 / n, 1 / pi            # sine part for 0 < x <= 1/pi, bar at x = 0,
    ie = floor(xe / h)               # arc down to y = -2, across, and up the bar
    hit = {(i, j) for i in (-1, 0) for j in range(-2 * n - 1, n + 1)}
    hit |= {(i, j) for i in range(-1, ie + 1) for j in (-2 * n - 1, -2 * n)}
    hit |= {(ie, j) for j in range(-2 * n - 1, 1)}
    for i in range(1, ie + 1):       # sin(1/x) over one column: ends, peak, trough
        u, v = 1 / min((i + 1) * h, xe), 1 / (i * h)
        ys = [sin(u), sin(v)]
        if pi / 2 + 2 * pi * ceil((u - pi / 2) / (2 * pi)) <= v:
            ys.append(1.0)
        if -pi / 2 + 2 * pi * ceil((u + pi / 2) / (2 * pi)) <= v:
            ys.append(-1.0)
        hit |= {(i, j) for j in range(ceil(min(ys) / h) - 1, floor(max(ys) / h) + 1)}
    free = {(i, j) for i in range(-3, ie + 3) for j in range(-2 * n - 3, n + 3)} - hit
    seen, parts = set(), 0
    for c in sorted(free):           # flood-fill the free cells, edge to edge
        if c not in seen:
            parts, stack, seen = parts + 1, [c], seen | {c}
            while stack:
                i, j = stack.pop()
                for d in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                    if d in free and d not in seen:
                        seen.add(d)
                        stack.append(d)
    return len(hit), parts - 1       # one free part is the outside

spheres = axiom_spheres({0: 1}, 4)
print("road 1, axioms only: reduced ranks of S^n by degree, from H0(point) = Z")
for n, row in enumerate(spheres):
    print(f"S{n}: {row}")
shifted = axiom_spheres({0: 1, 2: 1}, 4)[2]
print(f"no dimension axiom, point Z in degrees 0 and 2: S2 ranks {[shifted[k] + (k in (0, 2)) for k in range(5)]}")
print(f"mistake, unreduced H0(S0) pushed up: H1(S1) rank {2 * spheres[0][0]}; truly {spheres[1][1]}")
print("road 2, Smith form over Z: disc D^n, rim S^(n-1), pair (D^n, rim), sphere S^n")
for n in range(1, 5):
    disc, rim = closure([tuple(range(n + 1))]), closure(combinations(range(n + 1), n))
    sph = closure(combinations(range(n + 2), n + 1))
    print(f"n={n}: D {show(homology(disc))}; rim {show(homology(rim))}; "
          f"pair {show(homology(disc, rim))}; S{n} {show(homology(sph))}")
full, cut = closure(dome), closure([p for p in dome if p not in holes])
counts = [sum(len(s) == k for s in full) for k in (1, 2, 3)]
print(f"dome: joints, struts, panels {counts}; chi {counts[0] - counts[1] + counts[2]}")
print(f"dome, Smith form: {show(homology(full))}")
print(f"dome less 3 panels, Smith form: {show(homology(cut))}")
one, three = collapse([p for p in dome if p != holes[0]]), collapse([p for p in dome if p not in holes])
print(f"road 3, dome less 1 panel collapses to panels, joints, struts {list(one)}")
print("so dome = point + one 2-cell; cellular chains Z, 0, Z with zero boundaries: Z, 0, Z")
print(f"dome less 3 panels collapses to panels, joints, struts {list(three)}; "
      f"loops {three[2] - three[1] + 1}: {show([(1, []), (three[2] - three[1] + 1, []), (0, [])])}")
print("Warsaw circle, singular H1 = 0 (stated, not computed); grid of side 1/N:")
grid = [(n,) + warsaw(n) for n in (10, 20, 40, 80, 160)]
print("\n".join(f"N={n}: cells met {c}, holes enclosed {k}" for n, c, k in grid))
assert spheres == [[int(k == n) for k in range(5)] for n in range(5)]
assert show(homology(closure(combinations(range(4), 3)))) == show(homology(full)) == "Z, 0, Z"
assert all(homology(closure([tuple(range(n + 1))]), closure(combinations(range(n + 1), n)))
           == [(0, [])] * n + [(1, [])] for n in range(1, 5))
assert homology(cut)[1][0] == three[2] - three[1] + 1 == 2 and one == (0, 1, 0)
assert counts == [42, 120, 80] and all(k == 1 for _, _, k in grid)
print("ALL CHECKS PASS")
