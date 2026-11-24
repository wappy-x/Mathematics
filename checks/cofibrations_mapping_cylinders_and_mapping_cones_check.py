# Cofibrations -- mapping cylinder and cone of z -> z^2, and an edge of the theta graph collapsed.
# A complex is a recipe: vertices, edges (name, tail, head) and 2-cells, each 2-cell the word read
# round its rim; a capital letter runs that edge backwards.  Road 1 reads the loop group off the
# recipe by shrinking a spanning tree; its abelianised form comes from a Smith normal form.
# Road 2 counts mod-2 holes by brute force over every subset of edges and of 2-cells.
# Road 3 builds one space by two recipes and compares.  Exact, except the winding check and the figure.
from fractions import Fraction as Fr
from math import atan2, cos, sin, pi

def find(boss, v):
    while boss[v] != v: v = boss[v]
    return v

def presentation(V, E, F):                    # road 1: shrink a spanning tree, keep the rest
    boss, gens = {v: v for v in V}, []
    for name, tail, head in E:
        t, h = find(boss, tail), find(boss, head)
        if t == h: gens.append(name)
        else: boss[t] = h
    return gens, [''.join(c for c in w if c.lower() in gens) for w in F]

def snf(M):                                   # diagonal of the Smith normal form, whole numbers
    M, d = [r[:] for r in M], []
    while any(any(r) for r in M):
        _, i, j = min((abs(x), i, j) for i, r in enumerate(M) for j, x in enumerate(r) if x)
        M[0], M[i] = M[i], M[0]
        for r in M: r[0], r[j] = r[j], r[0]
        p, done = M[0][0], True
        for i in range(1, len(M)):
            q = M[i][0] // p
            M[i] = [a - q * b for a, b in zip(M[i], M[0])]
            done = done and M[i][0] == 0
        for j in range(1, len(M[0])):
            q = M[0][j] // p
            for r in M: r[j] -= q * r[0]
            done = done and M[0][j] == 0
        if not done: continue
        bad = [r for r in M[1:] if any(x % p for x in r)]
        if bad: M[0] = [a + b for a, b in zip(M[0], bad[0])]; continue
        d.append(abs(p)); M = [r[1:] for r in M[1:]]
    return d

def abelianised(gens, rels):
    d = snf([[w.count(g) - w.count(g.upper()) for g in gens] for w in rels])
    return len(gens) - len(d), sorted(x for x in d if x > 1)

def betti2(V, E, F):                          # road 2: mod-2 hole counts, every subset tried
    ends = [(1 << V.index(t)) ^ (1 << V.index(h)) for _, t, h in E]
    rims = [sum(1 << k for k, e in enumerate(E) if sum(c.lower() == e[0] for c in w) % 2) for w in F]
    def xor(masks, S):
        x = 0
        for k, m in enumerate(masks):
            if S >> k & 1: x ^= m
        return x
    z1 = sum(xor(ends, S) == 0 for S in range(1 << len(E))).bit_length() - 1
    z2 = sum(xor(rims, S) == 0 for S in range(1 << len(F))).bit_length() - 1
    b1, boss = len(F) - z2, {v: v for v in V}
    for _, t, h in E: boss[find(boss, t)] = find(boss, h)    # pieces counted by union-find, not by V - E + z1
    return len({find(boss, v) for v in V}), z1 - b1, z2

def collapse(V, E, F, names):                 # squash the named edges and their end points
    boss = {v: v for v in V}
    for n, t, h in E:
        if n in names and find(boss, t) != find(boss, h): boss[find(boss, t)] = find(boss, h)
    return ([v for v in V if find(boss, v) == v], [(n, find(boss, t), find(boss, h)) for n, t, h in E if n not in names],
            [''.join(c for c in w if c.lower() not in names) for w in F])

def show(label, X):
    gens, rels = presentation(*X)
    rank, tors = abelianised(gens, rels)
    b = betti2(*X)
    chi = len(X[0]) - len(X[1]) + len(X[2])
    assert chi == b[0] - b[1] + b[2]                          # cells against mod-2 holes
    assert b[1] == rank + sum(t % 2 == 0 for t in tors)       # presentation against brute force
    rel = ', '.join(r or '1' for r in rels) or 'no relations'
    print(f"{label}: cells {len(X[0])}, {len(X[1])}, {len(X[2])}; chi {chi}; pi1 = <{', '.join(gens)} | {rel}>; "
          f"abelianised rank {rank}, torsion {tors}; mod-2 betti {b[0]}, {b[1]}, {b[2]}")
    return rank, tors, chi

Y = (['v'], [('a', 'v', 'v')], [])
MF = (['v', 'p0', 'p1'], [('b', 'p0', 'v'), ('d', 'p1', 'v'), ('a', 'v', 'v'), ('p', 'p0', 'p1'), ('j', 'p1', 'p0')],
      ['pdAB', 'jbAD'])                                     # square over p: p, up d, back along f(p) = a, down b
CF = (MF[0] + ['tip'], MF[1][:2] + [('k', 'tip', 'p0')] + MF[1][2:] + [('m', 'tip', 'p1')], MF[2] + ['kpM', 'mjK'])
RP2 = (['v'], [('a', 'v', 'v')], ['aa'])
TH = (['u', 'w'], [('x', 'u', 'w'), ('y', 'u', 'w'), ('e', 'u', 'w')], [])
y = show("target circle Y, 1 vertex + 1 edge", Y)
m = show("mapping cylinder M_f of z -> z^2", MF)
c1 = show("mapping cone C_f, M_f + cone point", CF)
c2 = show("mapping cone C_f, M_f with X squashed", collapse(*MF, 'pj'))
c3 = show("projective plane recipe, disc on aa", RP2)
t0 = show("theta graph, 2 vertices + 3 edges", TH)
t1 = show("theta graph with edge e collapsed", collapse(*TH, 'e'))
fmap = {'p': 'a', 'j': 'a'}                               # f sends each half of X once round Y
image = ''.join(fmap[e] for e in 'pj')
ang = [atan2(sin(4 * pi * k / 12), cos(4 * pi * k / 12)) for k in range(13)]
turn = sum((b - a + pi) % (2 * pi) - pi for a, b in zip(ang, ang[1:])) / (2 * pi)
print(f"domain loop pj slides down the cylinder to {image}: net count of a {image.count('a')}")
print(f"winding number of z -> z^2, angle sum over 12 samples: {round(turn)}")
assert m[:2] == y[:2] and m[2] == y[2] == 0               # M_f has the target's invariants
assert c1[:2] == c2[:2] == c3[:2] == (0, [2]) and c1[2] == c3[2] == 1   # three recipes, one space
assert t0[:2] == t1[:2] == (2, []) and round(turn) == image.count('a') == 2

def r(x, t, c):                               # project (x, t) from (0, c) onto floor or walls
    if c * abs(x) <= c - t: return (c * x / (c - t), Fr(0))
    return (Fr(1 if x > 0 else -1), c - (c - t) / abs(x))
grid = [(Fr(i, 8), Fr(j, 8)) for i in range(-8, 9) for j in range(9)]
on = lambda p: p[1] == 0 or abs(p[0]) == 1
img = [r(x, t, 2) for x, t in grid]
seam = [(x, t) for x, t in grid if 2 * abs(x) == 2 - t]
ok = (all(map(on, img)), all(q == p for p, q in zip(grid, img) if on(p)),
      all(r(*q, 2) == q for q in img), all((Fr(1 if x > 0 else -1), 2 - (2 - t) / abs(x)) == r(x, t, 2) for x, t in seam))
yes = lambda b: 'yes' if b else 'no'
print(f"radial retraction of [-1, 1] x [0, 1] from (0, 2), grid 17 x 9 = {len(grid)} points:")
print(f"  every image on floor or walls: {yes(ok[0])}; floor and walls fixed: {yes(ok[1])}; "
      f"r(r(p)) = r(p): {yes(ok[2])}; both formulas agree on the {len(seam)} seam points: {yes(ok[3])}")
gap = lambda c: abs(r(Fr(1, 1000), Fr(1), c)[0] - r(Fr(-1, 1000), Fr(1), c)[0]) + abs(r(Fr(1, 1000), Fr(1), c)[1] - r(Fr(-1, 1000), Fr(1), c)[1])
print(f"  (-1/1000, 1) and (1/1000, 1), 1/500 apart, land {gap(2)} apart")
f, h = (lambda x: x), (lambda e, t: e + t if e > 0 else e)    # lead along a line; dog's end walks 1 m out
H = lambda x, t: (lambda q: f(q[0]) if q[1] == 0 else h(q[0], q[1]))(r(x, t, 2))
marks = [Fr(-1), Fr(-1, 2), Fr(0), Fr(1, 2), Fr(3, 4), Fr(1)]
print(f"extended homotopy at t = 1: marks {', '.join(map(str, marks))} go to {', '.join(str(H(x, 1)) for x in marks)}")
assert all(ok) and gap(2) == Fr(1, 250) and all(H(x, 0) == x for x, _ in grid) and all(H(1, t) == 1 + t for _, t in grid)
m1 = show("mistake 1, theta with the loop x, y collapsed", collapse(*TH, 'xy'))
m2 = show("mistake 2, Y / f(X), the image squashed", collapse(*Y, 'a'))
print(f"mistake 3, project from (0, 1) on the top face: the same two points land {gap(1)} apart")
m4 = show("mistake 4, cylinder without its two squares", (MF[0], MF[1], []))
assert m1[0] == 1 and m1[2] == 0 and m2[:2] == (0, []) and gap(1) == 2 and m4[0] == 3
spokes = [(150 + 90 * cos(k * pi / 4), 70 + 22 * sin(k * pi / 4), 150 + 90 * cos(k * pi / 2), 210 + 22 * sin(k * pi / 2)) for k in range(8)]
print("figure, schematic; spokes " + ' '.join('({:.1f}, {:.1f})-({:.1f}, {:.1f})'.format(*s) for s in spokes))
print("ALL CHECKS PASS")
