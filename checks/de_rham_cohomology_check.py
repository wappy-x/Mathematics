# de Rham cohomology of the torus -- the check behind the card.
# Standard library only.  Four roads to one answer, H^1(torus) has dimension 2:
#   road 1: loop integrals of closed 1-forms, Simpson's rule written out
#   road 2: Mayer-Vietoris, ranks of the restriction maps by exact integer elimination
#   road 3: Poincare duality, area integrals of wedge products, plus the Euler count
#   road 4: simplicial Betti numbers of a 3 x 3 grid torus, by exact rank
from math import pi, sin, cos, gcd
from functools import reduce
TAU = 2 * pi

def f6(x):  # six decimals, with no negative zero
    return "%.6f" % (0.0 if abs(x) < 5e-7 else x)

def simpson(g, a, b, n):
    h = (b - a) / n
    return (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n))) * h / 3

def loop(form, path, t1, n=2400):  # integral of P du + Q dv along path(t) = (u, v, du/dt, dv/dt)
    def g(t):
        u, v, du, dv = path(t)
        P, Q = form(u, v)
        return P * du + Q * dv
    return simpson(g, 0.0, t1, n)

def angle(x, y):  # the angle form on the punctured plane
    r2 = x * x + y * y
    return (-y / r2, x / r2)

def circle(cx, cy, r):
    return lambda t: (cx + r * cos(t), cy + r * sin(t), -r * sin(t), r * cos(t))

def encoder(amp):  # alpha = d(theta + amp cos(theta) cos(psi)), on the torus
    return lambda th, ps: (1 - amp * sin(th) * cos(ps), -amp * cos(th) * sin(ps))

DTH, DPS = (lambda th, ps: (1.0, 0.0)), (lambda th, ps: (0.0, 1.0))
turn_loop = lambda ps0: (lambda t: (t, ps0, 1.0, 0.0))
bob_loop = lambda th0: (lambda t: (th0, t, 0.0, 1.0))
ride = lambda k: (lambda t: (t, k * t, 1.0, float(k)))

def pair(f1, f2, n=60):  # integral over the torus of f1 ^ f2, midpoint rule
    h, s = TAU / n, 0.0
    for i in range(n):
        for j in range(n):
            P1, Q1 = f1((i + 0.5) * h, (j + 0.5) * h)
            P2, Q2 = f2((i + 0.5) * h, (j + 0.5) * h)
            s += P1 * Q2 - Q1 * P2
    return s * h * h

def rank(rows):  # exact rank by fraction-free integer elimination
    m, r = [list(x) for x in rows], 0
    for c in range(len(m[0]) if m else 0):
        p = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if p is None:
            continue
        m[r], m[p] = m[p], m[r]
        for i in range(r + 1, len(m)):
            if m[i][c] != 0:
                a, b = m[r][c], m[i][c]
                row = [a * x - b * y for x, y in zip(m[i], m[r])]
                g = reduce(gcd, row, 0)
                m[i] = [x // g for x in row] if g else row
        r += 1
    return r

def mv(maps):  # maps[k] = (dim H^k(overlap), dim H^k(U) + dim H^k(V), restriction matrix)
    rk = [rank(m) for (_, _, m) in maps]
    return [(maps[k - 1][0] - rk[k - 1] if k else 0) + maps[k][1] - rk[k] for k in range(3)], rk

def grid(n, twist):  # n x n grid of squares, each cut into 2 triangles, edges glued
    def v(i, j):
        if twist and j == n:
            i = -i
        return (i % n) + n * (j % n)
    tris = set()
    for i in range(n):
        for j in range(n):
            a, b, c, d = v(i, j), v(i + 1, j), v(i + 1, j + 1), v(i, j + 1)
            tris |= {tuple(sorted((a, b, c))), tuple(sorted((a, c, d)))}
    tris = sorted(tris)
    edges = sorted({e for t in tris for e in ((t[0], t[1]), (t[0], t[2]), (t[1], t[2]))})
    ei = {e: k for k, e in enumerate(edges)}
    d1 = [[(1 if e[1] == p else -1 if e[0] == p else 0) for e in edges] for p in range(n * n)]
    d2 = [[0] * len(tris) for _ in edges]
    for k, (a, b, c) in enumerate(tris):
        d2[ei[(b, c)]][k] += 1
        d2[ei[(a, c)]][k] -= 1
        d2[ei[(a, b)]][k] += 1
    assert all(sum(1 for x in row if x != 0) == 2 for row in d2)  # every edge on 2 triangles
    r1, r2 = rank(d1), rank(d2)
    V, E, F = n * n, len(edges), len(tris)
    return V, E, F, r1, r2, [V - r1, E - r1 - r2, F - r2]

print("carousel: ride 180 s, 15 s per turn, %d turns; crank 3 bobs per turn, %d bobs" % (180 // 15, 3 * 180 // 15))
pp = [loop(angle, circle(0, 0, 3), TAU), loop(angle, circle(0, 0, 6), TAU), loop(angle, circle(5, 0, 2), TAU)]
print("punctured plane, angle form: circle r 3 m round the pole %s, r 6 m %s, r 2 m centred 5 m out %s" % tuple(map(f6, pp)))
assert abs(pp[0] - TAU) < 1e-9 and abs(pp[1] - TAU) < 1e-9 and abs(pp[2]) < 1e-9
al, h = encoder(0.05), 1e-5
curl = (al(1 + h, 2)[1] - al(1 - h, 2)[1]) / (2 * h) - (al(1, 2 + h)[0] - al(1, 2 - h)[0]) / (2 * h)
print("encoder wobble 0.050000 rad = %s degrees; curl of alpha at (1, 2) %s" % (f6(0.05 * 180 / pi), f6(curl)))
A = [loop(al, turn_loop(p), TAU) for p in (0.0, 1.0, 2.0)]
B = [loop(al, bob_loop(t), TAU) for t in (0.0, 1.0, 2.0)]
print("road 1, turn loop gamma1 at psi = 0, 1, 2: %s %s %s" % tuple(map(f6, A)))
print("road 1, bob loop gamma2 at theta = 0, 1, 2: %s %s %s" % tuple(map(f6, B)))
c1 = (A[1] / TAU, B[1] / TAU)
print("road 1, class of alpha read by loops: (%s, %s)" % tuple(map(f6, c1)))
ra, rp = loop(al, ride(3), 12 * TAU, 24000), loop(DPS, ride(3), 12 * TAU, 24000)
print("ride path theta = t, psi = 3t, 12 turns: alpha %s = %s turns; dpsi %s = %s bobs" % (f6(ra), f6(ra / TAU), f6(rp), f6(rp / TAU)))
assert abs(curl) < 1e-6 and abs(ra - 24 * pi) < 1e-8 and abs(rp - 72 * pi) < 1e-8
R = [[-1, 1], [-1, 1]]
bt, rk = mv([(2, 2, R), (2, 2, R), (0, 0, [])])
print("road 2, Mayer-Vietoris on two cylinders: ranks %d, %d; torus %d %d %d" % (rk[0], rk[1], *bt))
bp, _ = mv([(2, 2, R), (0, 0, []), (0, 0, [])])
bs, _ = mv([(1, 2, [[-1, 1]]), (1, 0, []), (0, 0, [])])
print("road 2, Mayer-Vietoris: punctured plane %d %d %d; sphere %d %d %d" % (*bp, *bs))
assert bp == [1, 1, 0] and bs == [1, 0, 1]
v4 = pair(DTH, DPS)
M = [[pair(DTH, DTH), v4], [pair(DPS, DTH), pair(DPS, DPS)]]
print("road 3, <dtheta, dpsi> = %s = 4 pi^2; matrix [[%s, %s], [%s, %s]], det %s" % (f6(v4), *map(f6, M[0] + M[1]), f6(M[0][0] * M[1][1] - M[0][1] * M[1][0])))
c3 = (pair(al, DPS) / v4, pair(DTH, al) / v4)
print("road 3, class of alpha read by areas: (%s, %s)" % tuple(map(f6, c3)))
assert abs(v4 - 4 * pi * pi) < 1e-9 and abs(M[1][0] + v4) < 1e-9 and abs(c3[0] - c1[0]) < 1e-9 and abs(c3[1] - c1[1]) < 1e-9
V, E, F, r1, r2, bg = grid(3, False)
print("road 3, duality b2 = b0 = 1; Euler count %d - %d + %d = %d; b1 = 1 + 1 - %d = %d" % (V, E, F, V - E + F, V - E + F, 2 - (V - E + F)))
print("road 4, grid torus: V %d, E %d, F %d; rank d1 %d, rank d2 %d; Betti %d %d %d" % (V, E, F, r1, r2, *bg))
assert bg == bt and bt[1] == 2 - (V - E + F)  # simplicial = Mayer-Vietoris = duality count
V, E, F, r1, r2, bk = grid(3, True)
print("break 1, Klein bottle grid: V %d, E %d, F %d; Betti %d %d %d, so b2 is not b0" % (V, E, F, *bk))
assert bk == [1, 1, 0] and bk[2] != bk[0]
print("break 2, punctured plane, not compact: b0 %d, b2 %d" % (bp[0], bp[2]))
nc = [loop(lambda t, p: (sin(p), 0.0), turn_loop(p0), TAU) for p0 in (0.0, pi / 2)]
print("break 3, sin(psi) dtheta, not closed: turn loop at psi = 0 %s, at psi = pi/2 %s" % tuple(map(f6, nc)))
assert abs(nc[1] - nc[0] - TAU) < 1e-9
bw, _ = mv([(1, 2, [[-1, 1]]), (1, 2, [[-1, 1]]), (0, 0, [])])
print("break 4, overlap counted as one cylinder: %d %d %d" % tuple(bw))
assert bw[1] != bt[1]
r4, w2, g = loop(DPS, ride(4), 12 * TAU, 24000), encoder(0.2), 2  # g: the genus, the number of handles
print("try: 4 bobs per turn: dpsi over the ride %s = %s bobs" % (f6(r4), f6(r4 / TAU)))
print("try: wobble 0.2 rad: class (%s, %s); genus %d: chi %d, b1 = 1 + 1 - (%d) = %d" % (f6(loop(w2, turn_loop(1.0), TAU) / TAU), f6(loop(w2, bob_loop(1.0), TAU) / TAU), g, 2 - 2 * g, 2 - 2 * g, 2 - (2 - 2 * g)))
print("figure, square 0 to %s rad both ways; gamma1 at psi = 1; gamma2 at theta = 1; ride segments start at theta = 0.000000, %s, %s" % (f6(TAU), f6(TAU / 3), f6(2 * TAU / 3)))
print("ALL CHECKS PASS")
