# Inflections and Cayley-Bacharach on the Fermat cubic x^3 + y^3 = z^3 -- the check behind the card.
# Standard library only.  Exact arithmetic in Z[w], where w is a cube root of 1 (w^2 = -1 - w);
# finite counts mod 7, where 2 is a cube root of 1.  Points are (x : y : z).
class W:                                     # the number a + b w, with whole numbers a and b
    def __init__(s, a, b=0): s.a, s.b = a, b
    def __add__(s, o): o = wr(o); return W(s.a + o.a, s.b + o.b)
    def __sub__(s, o): o = wr(o); return W(s.a - o.a, s.b - o.b)
    def __mul__(s, o): o = wr(o); return W(s.a * o.a - s.b * o.b, s.a * o.b + s.b * o.a - s.b * o.b)
    __radd__, __rmul__, __rsub__ = __add__, __mul__, lambda s, o: wr(o) - s
    def __eq__(s, o): o = wr(o); return s.a == o.a and s.b == o.b
def wr(v): return v if isinstance(v, W) else W(v)
NAME = {(0, 0): "0", (1, 0): "1", (-1, 0): "-1", (0, 1): "ω", (0, -1): "-ω", (-1, -1): "ω²", (1, 1): "-ω²"}
def show(P): return "(" + " : ".join(NAME[(wr(c).a, wr(c).b)] for c in P) + ")"
def pw(v, n): return v * pw(v, n - 1) if n else 1
FERMAT = [(1, 3, 0, 0), (1, 0, 3, 0), (-1, 0, 0, 3)]                  # x^3 + y^3 - z^3, as (coef, i, j, k)
NODAL = [(1, 0, 2, 1), (-1, 3, 0, 0), (-1, 2, 0, 1)]                  # y^2 z - x^3 - x^2 z: the house curve
NEIGH = NODAL + [(-1, 0, 0, 3)]                                       # y^2 z - x^3 - x^2 z - z^3: a smooth neighbour
def ev(f, P, d=()):                          # value of f at P, or of its partial derivatives in the directions d
    tot = 0
    for c, *e in f:
        for a in d: c, e[a] = c * e[a], e[a] - 1
        if min(e) >= 0: tot = c * pw(P[0], e[0]) * pw(P[1], e[1]) * pw(P[2], e[2]) + tot
    return tot
def det3(M): return (M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1]) - M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0])
                     + M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0]))
def hess(f, P): return det3([[ev(f, P, (a, b)) for b in range(3)] for a in range(3)])
def bord(f, P):                              # the affine flex test at z = 1: f_xx f_y^2 - 2 f_xy f_x f_y + f_yy f_x^2
    fx, fy = ev(f, P, (0,)), ev(f, P, (1,)); return ev(f, P, (0, 0)) * fy * fy - 2 * ev(f, P, (0, 1)) * fx * fy + ev(f, P, (1, 1)) * fx * fx
def cross(P, Q): return [P[1] * Q[2] - P[2] * Q[1], P[2] * Q[0] - P[0] * Q[2], P[0] * Q[1] - P[1] * Q[0]]
yn = lambda t: "yes" if t else "no"; G = range(-2, 3)
print("curve x^3 + y^3 = z^3 over the complex numbers; second partials 6x, 6y, -6z, mixed ones 0")
hv = [(hess(FERMAT, (a, b, c)), -216 * a * b * c) for a in G for b in G for c in G]; hok = all(h == e for h, e in hv)
print(f"Hessian determinant equals -216xyz at all {5 ** 3} points of a 5 x 5 x 5 grid: {yn(hok)}; so H = 0 is xyz = 0; mod 3 it is 0 at all of them: {yn(all(h % 3 == 0 for h, _ in hv))}")
R3 = [W(1), W(0, 1), W(-1, -1)]                                       # 1, w, w^2
flex = [(W(0), r, W(1)) for r in R3] + [(r, W(0), W(1)) for r in R3] + [(W(1), W(0) - r, W(0)) for r in R3]
for n, side in enumerate(("x = 0: y^3 = z^3", "y = 0: x^3 = z^3", "z = 0: x^3 = -y^3")):
    print(f"on {side:18s} " + ", ".join(show(P) for P in flex[3 * n:3 * n + 3]))
on = all(ev(FERMAT, P) == 0 and hess(FERMAT, P) == 0 for P in flex)
dist = sum(cross(P, Q) != [0, 0, 0] for i, P in enumerate(flex) for Q in flex[i + 1:])
print(f"all nine on the curve and on H: {yn(on)}; distinct pairs {dist} of 36; Bezout 3 x 3 = 9, so each meeting is simple"); tri = 0
for P in flex:                               # road two: the tangent line meets the curve three times at P
    g = [ev(FERMAT, P, (a,)) for a in range(3)]
    Q = cross(g, (1, 2, 3)); assert cross(P, Q) != [0, 0, 0]
    v = [ev(FERMAT, [P[i] + t * Q[i] for i in range(3)]) for t in range(4)]
    tri += v[0] == 0 and not v[1] == 0 and all(v[t] == t ** 3 * v[1] for t in (2, 3))
print(f"tangent test, F(P + tQ) = c t^3 along the tangent: {tri} of 9 points meet it three times")
assert hok and on and dist == 36 and tri == 9
real = [P for P in flex if all(wr(c).b == 0 for c in P)]
lines = [(i, j, k) for i in range(9) for j in range(i + 1, 9) for k in range(j + 1, 9) if det3([flex[i], flex[j], flex[k]]) == 0]
print(f"real flexes {', '.join(show(P) for P in real)}; on the line x + y = z: {yn(all(ev([(1, 1, 0, 0), (1, 0, 1, 0), (-1, 0, 0, 1)], P) == 0 for P in real))}")
pairs = sorted(sum(1 for L in lines if i in L and j in L) for i in range(9) for j in range(i + 1, 9))
print(f"collinear triples among the nine flexes: {len(lines)} of 84; every pair of flexes on exactly one: {yn(pairs == [1] * 36)}")
assert len(real) == 3 and len(lines) == 12 and pairs == [1] * 36
L = [lambda P, r=r: P[0] + r * P[1] - r * r * P[2] for r in R3]       # x + y - z, x + wy - w^2 z, x + w^2 y - wz
G4 = [(a, b, c) for a in range(-1, 3) for b in range(-1, 3) for c in range(-1, 3)]
t1 = all(L[0](P) * L[1](P) * L[2](P) == ev(FERMAT, P) + 3 * P[0] * P[1] * P[2] for P in G4)
t2 = all(L[1](P) * L[2](P) == ev([(1, 2, 0, 0), (-1, 1, 1, 0), (1, 0, 2, 0), (1, 1, 0, 1), (1, 0, 1, 1), (1, 0, 0, 2)], P) for P in G4)
one = all(sum(Li(P) == 0 for Li in L) == 1 for P in flex)
print(f"(x + y - z)(x^2 - xy + y^2 + xz + yz + z^2) = x^3 + y^3 - z^3 + 3xyz at all 64 grid points: {yn(t1 and t2)}")
print(f"the conic is (x + ωy - ω²z)(x + ω²y - ωz); each flex lies on exactly one of the three lines: {yn(one)}")
t3 = all((P[0] + P[1] - P[2]) ** 3 - 3 * (P[0] - P[2]) * (P[1] - P[2]) * (P[0] + P[1]) == ev(FERMAT, P) for P in G4)
print(f"real flex tangents x = z, y = z, x + y = 0 and flex line x + y = z: (x + y - z)^3 - 3(x - z)(y - z)(x + y) = x^3 + y^3 - z^3 at all 64 grid points: {yn(t3)}")
assert t1 and t2 and one and t3
p = 7                                        # road three: everything again over the field of 7 elements
def m7(v): v = wr(v); return (v.a + 2 * v.b) % p
def norm(P): k = max(i for i in range(3) if P[i] % p); inv = pow(P[k], p - 2, p); return tuple(c * inv % p for c in P)
PTS = [(x, y, 1) for x in range(p) for y in range(p)] + [(x, 1, 0) for x in range(p)] + [(1, 0, 0)]
f7 = [norm([m7(c) for c in P]) for P in flex]
print(f"mod 7, with ω = 2: the flexes become {', '.join(str(P).replace(',', '') for P in f7)}")
def contact3(f, P, Q):
    v = [ev(f, [P[i] + t * Q[i] for i in range(3)]) % p for t in range(4)]
    return v[0] == 0 and all((v[t] - t ** 3 * v[1]) % p == 0 for t in (2, 3))
for name, f in (("x^3 + y^3 = z^3", FERMAT), ("y^2 = x^3 + x^2 + 1", NEIGH), ("y^2 = x^2(x + 1)", NODAL)):
    cur = [P for P in PTS if ev(f, P) % p == 0]
    smooth = [P for P in cur if any(ev(f, P, (a,)) % p for a in range(3))]
    brute = [P for P in smooth if any(contact3(f, P, Q) for Q in PTS if Q != P)]
    hz = [P for P in smooth if hess(f, P) % p == 0]; eu = all((P[2] ** 2 * hess(f, P) + 4 * bord(f, P)) % p == 0 for P in cur)
    print(f"mod 7, {name:19s}: {len(cur):2d} points, {len(smooth):2d} smooth; flexes by trying every line {len(brute)}, "
          f"by the Hessian {len(hz)}; same points: {yn(brute == hz)}; z^2 H = -4 x bordered Hessian at all of them: {yn(eu)}")
    assert brute == hz and eu
    if f is FERMAT: assert sorted(brute) == sorted(f7) and len(brute) == 9
MON3 = [(i, j, 3 - i - j) for i in range(3, -1, -1) for j in range(3 - i, -1, -1)]
MON2 = [(i, j, 2 - i - j) for i in range(2, -1, -1) for j in range(2 - i, -1, -1)]
def mono(P, m): return pw(P[0], m[0]) * pw(P[1], m[1]) * pw(P[2], m[2]) % p
def kernel(pts, mons):                       # rank of the conditions, and a basis of the curves through pts
    rows, piv, r = [[mono(P, m) for m in mons] for P in pts], [], 0
    for c in range(len(mons)):
        k = next((i for i in range(r, len(rows)) if rows[i][c]), None)
        if k is None: continue
        rows[r], rows[k] = rows[k], rows[r]; inv = pow(rows[r][c], p - 2, p); rows[r] = [v * inv % p for v in rows[r]]
        for i in range(len(rows)):
            if i != r and rows[i][c]: rows[i] = [(a - rows[i][c] * b) % p for a, b in zip(rows[i], rows[r])]
        piv.append(c); r += 1
    basis = []
    for c in [c for c in range(len(mons)) if c not in piv]:
        v = [0] * len(mons); v[c] = 1
        for i, pc in enumerate(piv): v[pc] = -rows[i][c] % p
        basis.append(v)
    return r, basis
def common(basis, mons): return [Q for Q in PTS if all(sum(b[n] * mono(Q, m) for n, m in enumerate(mons)) % p == 0 for b in basis)]
Fv, Xv, good = [[1, 0, 0, 0, 0, 0, 1, 0, 0, p - 1][n] for n in range(10)], [int(m == (1, 1, 1)) for m in MON3], 0
for k in range(9):                           # Cayley-Bacharach: leave out each flex in turn
    r, B = kernel(f7[:k] + f7[k + 1:], MON3)
    inF = all(sum(v[n] * mono(P, m) for n, m in enumerate(MON3)) % p == 0 for v in (Fv, Xv) for P in f7[:k] + f7[k + 1:])
    good += r == 8 and len(B) == 2 and inF and sorted(common(B, MON3)) == sorted(f7)
print(f"cubics through 8 of the 9 flexes, each of the 9 ways: rank 8 of 10, 2 free coefficients, spanned by "
      f"x^3 + y^3 - z^3 and xyz; common points of all of them: the 9 flexes, in {good} of 9 cases")
assert good == 9
print("rank 8 mod 7 forces rank 8 over Z[ω]; so over C too every cubic through 8 flexes is a·(x^3 + y^3 - z^3) + b·xyz")
def m2(f, P): return ev(f, P, (0, 0)) * ev(f, P, (1, 1)) - ev(f, P, (0, 1)) * ev(f, P, (0, 1))   # the plain 2 x 2 Hessian
aff, aff2 = (sum(1 for P in flex if not P[2] == 0 and t(FERMAT, P) == 0) for t in (bord, m2))   # what breaks
print(f"mistake, affine plane: the bordered Hessian of x^3 + y^3 = 1 is 0 at {aff} flexes (the plain 2 x 2 Hessian, by luck, at {aff2}); the 3 on the line at infinity z = 0 are lost")
lin = all(m2(NEIGH, (x, y, 1)) == -12 * x - 4 for x in G for y in G); off = [(m2(NEIGH, (-1, y, 3)), hess(NEIGH, (-1, y, 3))) for y in range(4)]
print(f"mistake, plain 2 x 2 Hessian of y^2 = x^3 + x^2 + 1: equals -12x - 4 on the 5 x 5 grid: {yn(lin)}; on the line x = -1/3, at (-1 : y : 3) for y = 0..3, "
      f"(2 x 2, H) = {off}: the 2 x 2 test says flex, H is never 0, so no flex lies there")
nod = all(hess(NODAL, (t * t - 1, t ** 3 - t, 1)) == 8 * (t * t - 1) ** 3 * (3 * t * t + 1) for t in range(10))
print(f"mistake, a node: on y^2 = x^2(x + 1), put x = t^2 - 1, y = t^3 - t; H = 8(t - 1)^3(t + 1)^3(3t^2 + 1) at t = 0..9: {yn(nod)}")
print(f"  the node (t = 1 and t = -1) takes 3 + 3 = 6 of the 9 meetings; flexes: (0 : 1 : 0), on H: "
      f"{yn(ev(NODAL, (0, 1, 0)) == 0 and hess(NODAL, (0, 1, 0)) == 0)}, and two complex ones at 3t^2 + 1 = 0: 3 in all")
rc, Bc = kernel([(1, 1, 1), (1, p - 1, 1), (p - 1, 1, 1)], MON2)            # conics through 3 corners of the square
cv = [(x - 1) * (1 - y) for x, y in ((1, 1), (1, -1), (-1, 1), (-1, -1))]
print(f"mistake, conics: x^2 = 1 and y^2 = 1 meet at 4 corners; conics through 3 corners have {len(Bc)} free coefficients, "
      f"not 2; (x - 1)(1 - y) at the corners: {cv}")
line4 = [(0, 0, 1), (1, 0, 1), (2, 0, 1), (3, 0, 1), (0, 1, 1), (1, 3, 1), (3, 2, 1), (5, 6, 1)]
r4, B4 = kernel(line4, MON3); c4 = common(B4, MON3); on4 = sum(1 for Q in c4 if Q[1] == 0)
print(f"mistake, 8 points with 4 on the line y = 0 (mod 7): rank {r4}, but every cubic through them contains the line; "
      f"common points {len(c4)}: {on4} on the line y = 0, {len(c4) - on4} off it; not 9")
assert aff == aff2 == 6 and lin and all(a == 0 and h != 0 for a, h in off) and nod and rc == 3 and (p - 1, p - 1, 1) not in common(Bc, MON2)
assert r4 == 8 and on4 == p + 1 and len(c4) == 12
# figure: the real curve x^3 + y^3 = 1; put x = (w + s)/2, y = (w - s)/2, then w^3 + 3 s^2 w = 4 has one real root
def wroot(s):
    w = 1.5
    for _ in range(60): w -= (w * w * w + 3 * s * s * w - 4) / (3 * w * w + 3 * s * s)
    return w
sv = lambda x, y: f"{210 + 60 * x:.1f},{210 - 60 * y:.1f}"
pts = [(-6.5 + 0.25 * i, wroot(-6.5 + 0.25 * i)) for i in range(53)]
print("figure, 1 unit = 60, origin (210,210), curve:", " ".join(sv((w + s) / 2, (w - s) / 2) for s, w in pts))
print("figure, flexes", sv(1, 0), sv(0, 1), "line x + y = 1", sv(-2.4, 3.4), "to", sv(3.4, -2.4), "asymptote", sv(-3.4, 3.4), "to", sv(3.4, -3.4),
      "tangents", sv(1, 3.4), "to", sv(1, -3.4), "and", sv(-3.4, 1), "to", sv(3.4, 1))
print("ALL CHECKS PASS")
