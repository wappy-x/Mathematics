# Transversality and cobordism -- the check behind the card.  Standard library only.
# Loops on a map sheet with opposite edges glued (a flat torus) and circles on the globe,
# counted with signs.  Roads: the formula ad - bc, a lattice count, a crossing finder on
# wiggled loops, and the net vertical turns; then Euler characteristics of cell complexes.
import math
TAU, R, Y0 = 2 * math.pi, 6371.0, 0.25            # R: the globe's radius in km (a model)
def sgn(x): return 0 if abs(x) < 1e-9 else (1 if x > 0 else -1)
def det(u, v): return u[0] * v[1] - u[1] * v[0]
def cross(u, v): return (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def root(g, a, b):                                 # bisection on a cell where g changes sign
    for _ in range(60): m = (a + b) / 2; a, b = (a, m) if g(a) * g(m) <= 0 else (m, b)
    return (a + b) / 2
def lattice(p, q):                                 # road 2: (0, Y0) + t p = u q + (m, n), t, u in [0, 1)
    D, pts = det(p, (-q[0], -q[1])), []
    for w in ((m, n - Y0) for m in range(-9, 10) for n in range(-9, 10)):
        t, u = det(w, (-q[0], -q[1])) / D, det(p, w) / D
        if -1e-9 <= t < 1 - 1e-9 and -1e-9 <= u < 1 - 1e-9:
            pts.append(sgn(det(p, q)))             # sign: do the tangents (A, B) turn left?
    return pts
def crossings(fa, fb, n=3001):                     # road 3: loops as graphs y = f(x), x in [0, 1)
    h, out, e = (lambda x: fb(x) - fa(x)), [], 1e-6
    for i in range(n):
        a, b = i / n, (i + 1) / n
        ka, kb = math.floor(h(a)), math.floor(h(b))
        if ka != kb:                               # fb - fa passes a whole number: the loops meet
            x = root(lambda t: h(t) - max(ka, kb), a, b)
            ta, tb = (1, (fa(x + e) - fa(x - e)) / (2 * e)), (1, (fb(x + e) - fb(x - e)) / (2 * e))
            out.append((x, fa(x) % 1, sgn(det(ta, tb))))
    return out
def net_turns(fa, fb, n=3000):                     # road 4: positions only, angle 2 pi (fb - fa)
    ps = [(math.cos(TAU * (fb(i / n) - fa(i / n))), math.sin(TAU * (fb(i / n) - fa(i / n)))) for i in range(n + 1)]
    return sum(math.atan2(det(p, q), dot(p, q)) for p, q in zip(ps, ps[1:])) / TAU
print("map sheet: A = (1,0) along y = 0.25, B = (1,2) from the corner (0,0)")
for p, q in (((1, 0), (1, 2)), ((1, 0), (0, 1)), ((2, 1), (1, 3)), ((1, 1), (1, -1)), ((1, 2), (1, 0))):
    pts, f = lattice(p, q), p[0] * q[1] - p[1] * q[0]
    print(f"pair {p} {q}: ad - bc = {f}; lattice count {len(pts)} points, signed {sum(pts)}, mod 2 {len(pts) % 2}")
    assert len(pts) == abs(f), "lattice count disagrees with ad - bc"
fA, fB = (lambda x: Y0), (lambda x: 2 * x)
c0 = crossings(fA, fB)
print("crossings of A and B:", " ".join(f"({x:.3f}, {y:.3f}) sign {s:+d}" for x, y, s in c0))
def wig(w, v): return (lambda x: Y0 + v * math.sin(2 * TAU * x)), (lambda x: 2 * x + w * math.sin(3 * TAU * x))
for w, v in ((0.3, 0.0), (0.0, 0.2), (0.3, 0.2)):
    cs, nt = crossings(*wig(w, v)), net_turns(*wig(w, v))
    print(f"wiggle B by {w:.1f}, A by {v:.1f}: {len(cs)} points at x = " + " ".join(f"{x:.3f}" for x, _, _ in cs)
          + f"; signs {''.join('+' if s > 0 else '-' for _, _, s in cs)}; signed {sum(s for _, _, s in cs)}; net turns {nt:.6f}")
    assert sum(s for _, _, s in cs) == 2 and abs(nt - 2) < 1e-9 and len(cs) % 2 == 0
raw = set()
for k in range(61):                                # the whole slide from straight to wiggled
    cs = crossings(*wig(0.3 * k / 60, 0.2 * k / 60))
    raw.add(len(cs)); assert sum(s for _, _, s in cs) == 2
print(f"slide in 61 steps: raw counts seen {sorted(raw)}, signed count 2 at every step")
print(f"order swapped, I(B, A) = {sum(s for _, _, s in crossings(fB, fA))}")
def circle(s):                                     # the moving circle: plane n . p = h on the globe
    al, h = math.pi * s / 2, s * R * math.cos(math.radians(10))
    n, r, e2 = (0.0, math.cos(al), math.sin(al)), math.sqrt(R * R - h * h), (0.0, -math.sin(al), math.cos(al))
    P = lambda t: tuple(h * n[i] + r * ((math.cos(t) if i == 0 else 0.0) + math.sin(t) * e2[i]) for i in range(3))
    T = lambda t: tuple(r * ((-math.sin(t) if i == 0 else 0.0) + math.cos(t) * e2[i]) for i in range(3))
    return P, T, h, al, r
def lon(p): return (math.degrees(math.atan2(p[1], p[0])) + 360) % 360
def sign_at(p, tc): return dot(cross((-p[1] / R, p[0] / R, 0.0), tc), p)   # (east, circle, up)
def globe(s, n=3001, raw=False):                   # where circle s crosses the equator: signs, or determinants
    P, T, h, al, r = circle(s)
    cells = [(TAU * (i + 0.5) / n, TAU * (i + 1.5) / n) for i in range(n)]
    ts = [root(lambda t: P(t)[2], a, b) for a, b in cells if P(a)[2] * P(b)[2] < 0]
    return sorted((lon(P(t)), (lambda d: d if raw else sgn(d))(sign_at(P(t), T(t)) / (R * r))) for t in ts)
sstar = root(lambda s: s * math.cos(math.radians(10)) - math.cos(math.pi * s / 2), 0.0, 1.0)
print(f"globe, R = {R:.0f} km: the circles cross the equator, signs from (east, circle, up)")
for s in (0.0, 0.25, 0.5, 0.59, sstar, 0.75, 1.0):
    P, T, h, al, r = circle(s)
    if s == sstar:                                 # the touching point, lowest on the circle
        p, z = P(-math.pi / 2), (s - 0.01, s - 0.001)  # crossing determinants just before the touch
        dd = [globe(x, raw=True)[0][1] for x in z]; s0 = z[1] + dd[1] ** 2 * (z[1] - z[0]) / (dd[0] ** 2 - dd[1] ** 2)
        print(f"s = {s:.4f}: circle radius {r:.1f} km touches at lon {lon(p):.2f}, height {abs(p[2]):.6f} km; crossing determinant "
              f"{dd[0]:.4f} at s = {z[0]:.4f}, {dd[1]:.4f} at s = {z[1]:.4f}, extrapolated to 0 at s = {s0:.4f}: not transverse")
        assert abs(p[2]) < 1e-6 and abs(s0 - sstar) < 1e-4; continue  # det^2 is straight in s near the touch
    g = globe(s)
    km = f"; apart {R * math.radians(g[1][0] - g[0][0]):.0f} km" if g else ""
    print(f"s = {s:.4f}: circle radius {r:.1f} km; crossings " + (" ".join(f"lon {x:.2f} ({e:+d})" for x, e in g) or "none")
          + f"; signed {sum(e for _, e in g)}{km}")
    assert sum(e for _, e in g) == 0 and len(g) == (2 if s < sstar else 0)
    if g: th = math.degrees(math.asin(h / (R * math.cos(al)))); assert abs(g[0][0] - th) + abs(g[1][0] - 180 + th) < 1e-6
    assert all(e == sgn(math.cos(math.radians(x))) for x, e in g)   # +1 where the circle heads north, at cos(lon) > 0
counts = {len(globe(k / 50)) for k in range(51)}
print(f"51 circles from s = 0 to 1: raw counts {sorted(counts)}, signed count 0 at all")
arc = [sum(1 for i in range(600) if math.cos(math.radians(60 - d + i / 10)) * math.cos(math.radians(60 - d + (i + 1) / 10)) < 0) for d in (0, 40)]
print(f"meridian arc from 30N to 30S, polar angles 60-120 deg: {arc[0]} crossing; slid 40 deg north: {arc[1]}")
assert arc == [1, 0]
def surface(tris):                                 # Euler characteristic, closedness, orientability
    E = {frozenset(e) for t in tris for e in ((t[0], t[1]), (t[1], t[2]), (t[0], t[2]))}
    closed = all(sum(1 for t in tris if e <= set(t)) == 2 for e in E)
    orient, todo, ok = {0: tris[0]}, [0], True
    while todo:
        i = todo.pop(); a, b, c = orient[i]
        for x, y in ((a, b), (b, c), (c, a)):      # a neighbour must run the shared edge backwards
            for j, t in enumerate(tris):
                if j != i and {x, y} <= set(t):
                    want = (y, x, [v for v in t if v not in (x, y)][0])
                    if j not in orient: orient[j] = want; todo.append(j)
                    elif orient[j] not in (want, want[1:] + want[:1], want[2:] + want[:2]): ok = False
    return len({v for t in tris for v in t}) - len(E) + len(tris), closed, ok
def grid(twist, n=4):                              # n by n squares, glued straight or with a flip
    def v(i, j): return (i % n, (-j if twist and i >= n else j) % n)
    return [t for i in range(n) for j in range(n)
            for t in ((v(i, j), v(i + 1, j), v(i + 1, j + 1)), (v(i, j), v(i + 1, j + 1), v(i, j + 1)))]
rp2 = [(1, 2, 3), (1, 3, 4), (1, 4, 5), (1, 5, 6), (1, 6, 2), (2, 3, 5), (3, 4, 6), (4, 5, 2), (5, 6, 3), (6, 2, 4)]
chi = {}
for name, tris in (("sphere", [(0, 1, 2), (0, 1, 3), (0, 2, 3), (1, 2, 3)]), ("torus", grid(False)),
                   ("Klein bottle", grid(True)), ("projective plane", rp2)):
    chi[name], closed, ok = surface(tris)
    print(f"surface {name}: {len(tris)} triangles, chi = {chi[name]}, closed {closed}, orientable {ok}")
    assert closed and ok == (name in ("sphere", "torus"))
def solid(ring, twist):                            # unit cubes in a ring of `ring` (0: one cube)
    def key(c, st):                                # a cell: st[d] = 0 low side, 1 high side, 2 whole edge
        pts = [(c + x, y, z) for x in (0, 1) for y in (0, 1) for z in (0, 1)
               if all(s in (2, o) for s, o in zip(st, (x, y, z)))]
        if ring: pts = [(x % ring, 1 - y if twist and x >= ring else y, z) for x, y, z in pts]
        return frozenset(pts)
    def subs(st): return [u for u in ((a, b, c) for a in range(3) for b in range(3) for c in range(3)) if all(s in (2, o) for s, o in zip(st, u))]
    cells, faces = {}, {}
    for c in range(ring or 1):
        for st in subs((2, 2, 2)):
            cells[key(c, st)] = st.count(2)
            if st.count(2) == 2: faces.setdefault(key(c, st), []).append((c, st))
    bd = {key(c, s2): s2.count(2) for fs in faces.values() if len(fs) == 1 for c, st in fs for s2 in subs(st)}
    return sum((-1) ** d for d in cells.values()), sum((-1) ** d for d in bd.values())
for name, ring, tw in (("ball, 1 cube", 0, False), ("torus, 4 cubes", 4, False), ("Mobius band x interval", 4, True)):
    cw, cb = solid(ring, tw)
    print(f"solid {name}: chi(W) = {cw}, chi(its boundary) = {cb}")
    assert cb == 2 * cw, "the boundary of a compact 3-manifold has chi = 2 chi(W)"
print(f"so a boundary has even chi; the projective plane has chi = {chi['projective plane']}: it bounds nothing")
assert chi["projective plane"] % 2 == 1 and chi["Klein bottle"] % 2 == 0
print("figure,square 0 0 1 1; A y=0.250; B (0,0)-(0.5,1) and (0.5,0)-(1,1); crossings "
      + " ".join(f"({x:.3f},{y:.3f})" for x, y, _ in c0))
print("ALL CHECKS PASS")
