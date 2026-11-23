# Jacobian conjecture -- the check behind the card.  Standard library only.
# Polynomials are dicts {exponents: integer or fraction}, so every number is
# exact.  Derivatives are taken two ways: term by term on the dict, and by
# dual numbers (a value carried together with its rate) at single points.
from fractions import Fraction as Q
from math import comb, prod

class P:  # polynomial in n variables
    def __init__(s, n, t): s.n, s.t = n, {e: c for e, c in t.items() if c}
    def up(s, b): return b if isinstance(b, P) else P(s.n, {(0,) * s.n: b})
    def __add__(s, b):
        r = dict(s.t)
        for e, c in s.up(b).t.items(): r[e] = r.get(e, 0) + c
        return P(s.n, r)
    def __mul__(s, b):
        r = {}
        for e1, c1 in s.t.items():
            for e2, c2 in s.up(b).t.items():
                e = tuple(i + j for i, j in zip(e1, e2)); r[e] = r.get(e, 0) + c1 * c2
        return P(s.n, r)
    __radd__, __rmul__ = __add__, __mul__
    def __sub__(s, b): return s + (-1) * s.up(b)
    def __eq__(s, b): return s.t == s.up(b).t
    def d(s, i): return P(s.n, {e[:i] + (e[i] - 1,) + e[i + 1:]: c * e[i] for e, c in s.t.items() if e[i]})
    def cut(s, D): return P(s.n, {e: c for e, c in s.t.items() if sum(e) <= D})
    def deg(s): return max(sum(e) for e in s.t)
    def coef(s, k): return s.t.get((k,), 0)
    def at(s, *v): return sum(c * prod(x ** k for x, k in zip(v, e)) for e, c in s.t.items())

class D:  # dual number: value v and rate r along one direction
    def __init__(s, v, r=0): s.v, s.r = v, r
    def up(s, b): return b if isinstance(b, D) else D(b)
    def __add__(s, b): b = s.up(b); return D(s.v + b.v, s.r + b.r)
    def __mul__(s, b): b = s.up(b); return D(s.v * b.v, s.v * b.r + s.r * b.v)
    __radd__, __rmul__ = __add__, __mul__
    def __sub__(s, b): return s + (-1) * s.up(b)

def var(i, n): return P(n, {tuple(int(j == i) for j in range(n)): 1})
def det(M):
    if len(M) == 1: return M[0][0]
    return sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M)))
def jac_sym(F, n): return [[f.d(j) for j in range(n)] for f in F]
def jac_dual(F, pt):  # column j = rates of F when coordinate j moves at rate 1
    cols = [F(*[D(v, int(i == j)) for i, v in enumerate(pt)]) for j in range(len(pt))]
    return [[cols[j][i].r for j in range(len(pt))] for i in range(len(pt))]
def show(v): return ", ".join(str(x) for x in v)

# 1. The plane map with Jacobian 1, its inverse, and the formal inverse
def F2(x, y): u = x + y; return (x + u * u, y - u * u)
def G2(a, b): w = a + b; return (a - w * w, b + w * w)
X, Y = var(0, 2), var(1, 2)
assert det(jac_sym(F2(X, Y), 2)) == 1                          # road 1: symbolic
grid2 = [(x, y) for x in range(-3, 4) for y in range(-3, 4)]
assert all(det(jac_dual(F2, p)) == 1 for p in grid2)          # road 2: dual numbers
J12 = jac_dual(F2, (1, 2)); N12 = [[J12[0][0] - 1, J12[0][1]], [J12[1][0], J12[1][1] - 1]]
NN = [[sum(N12[i][k] * N12[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
assert NN == [[0, 0], [0, 0]] and F2(1, 2) == (10, -7) and G2(10, -7) == (1, 2)
assert G2(*F2(X, Y)) == (X, Y) and F2(*G2(X, Y)) == (X, Y)      # road 3: compose both ways
g, rounds = (X, Y), 0
while True:                                                     # road 4: g = (a, b) - H(g)
    u = g[0] + g[1]; new = ((X - u * u).cut(9), (Y + u * u).cut(9)); rounds += 1
    if new == g: break
    g = new
assert g == G2(X, Y) and max(p.deg() for p in g) == 2
print("plane, u = x + y =", 1 + 2, " u^2 =", (1 + 2) ** 2, " F(1, 2):", show(F2(1, 2)), "  G(10, -7):", show(G2(10, -7)))
print("plane, J at (1, 2):", J12, " det:", det(J12), " J - I:", N12, " (J - I)^2:", NN)
print("plane, det J = 1 at all", len(grid2), "grid points and as a polynomial; G(F) = F(G) = identity")
print("plane, formal inverse stable after round", rounds - 1, "of g = (a, b) - H(g), highest degree", g[0].deg())

# 2. One variable: constant derivative forces degree 1; what fails without it
T = var(0, 1); good = 0
for c0 in range(-2, 3):
    for c1 in range(-2, 3):
        for c2 in range(-2, 3):
            for c3 in range(-2, 3):
                f = c0 + c1 * T + c2 * T * T + c3 * T * T * T
                if f.d(0).t and f.d(0).deg() == 0:
                    good += 1; assert f.deg() == 1 and all((c0 + c1 * Q(y - c0, c1)) == y for y in range(5))
assert good == 5 * 4                                            # c2 = c3 = 0, c1 != 0
print("one variable, polynomials with coefficients -2..2 up to degree 3:", 5 ** 4, " constant nonzero f':", good, " all degree 1 and inverted")
for k, name in ((2, "x + x^2"), (3, "x + x^3")):
    h = T
    for _ in range(12): h = (T - h * h if k == 2 else T - h * h * h).cut(13)
    cs = [h.coef(m) for m in range(1, 14) if h.coef(m)][:6]
    exact = [(-1) ** j * comb(k * j, j) // ((k - 1) * j + 1) for j in range(6)]
    assert cs == exact
    print("formal inverse of", name, "coefficients:", show(cs), " never stop")
cube = T + T * T * T
print("x + x^3: rate 1 + 3x^2 >= 1, f(1) =", cube.at(1), " f(2) =", cube.at(2), " inverse has no polynomial form")
fp = T - T * T * T * T * T
vals = [(x - x ** 5) % 5 for x in range(5)]
assert vals == [0] * 5 and {e: c % 5 for e, c in fp.d(0).t.items() if c % 5} == {(0,): 1}
print("mod 5, f(x) = x - x^5: f' = 1 - 5x^4 = 1 mod 5, values at 0..4:", show(vals))

# 3. Three variables: the counterexample announced 2026-07-20
def F3(x, y, z):
    s, t = 1 + x * y, 4 + 3 * x * y
    return (s * s * s * z + y * y * s * t, y + 3 * x * s * s * z + 3 * x * y * y * t, 2 * x - 3 * x * x * y - x * x * x * z)
X3 = [var(i, 3) for i in range(3)]
J3 = jac_sym(F3(*X3), 3)
assert det(J3) == -2                                              # road 1: symbolic
grid3 = [(x, y, z) for x in range(-2, 3) for y in range(-2, 3) for z in range(-2, 3)]
assert all(det(jac_dual(F3, p)) == -2 for p in grid3)            # road 2: dual numbers
pts = [(0, 0, Q(-1, 4)), (1, Q(-3, 2), Q(13, 2)), (-1, Q(3, 2), Q(13, 2))]
imgs = [F3(*p) for p in pts]
assert len(set(pts)) == 3 and all(v == (Q(-1, 4), 0, 0) for v in imgs)
assert all(det(jac_dual(F3, p)) == -2 for p in pts)
print("3-d, degree of the map:", max(f.deg() for f in F3(*X3)), " det J = -2 as a polynomial and at all", len(grid3), "grid points")
for p, v in zip(pts, imgs): print("3-d, F(" + show(p) + ") =", show(v), " det J there:", det(jac_dual(F3, p)))
x_, y_, z_ = pts[1]; s_, t_ = 1 + x_ * y_, 4 + 3 * x_ * y_
terms = [s_ ** 3 * z_, y_ * y_ * s_ * t_, y_, 3 * x_ * s_ * s_ * z_, 3 * x_ * y_ * y_ * t_, 2 * x_, -3 * x_ * x_ * y_, -x_ ** 3 * z_]
assert [sum(terms[:2]), sum(terms[2:5]), sum(terms[5:])] == list(imgs[1])
print("3-d, at (1, -3/2, 13/2): s = 1 + xy =", s_, " t = 4 + 3xy =", t_, " terms:", show(terms))
J3n = [[Q(-1, 2) * e for e in J3[0]]] + J3[1:]
assert det(J3n) == 1
print("3-d, first output times -1/2: det J =", det(J3n).at(0, 0, 0), " all three points go to", show((Q(-1, 2) * imgs[0][0], 0, 0)))

# 4. A symmetric cubic map over the Gaussian integers (pairs a + bi)
def cm(a, b): return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])
def ca(a, b, s=1): return (a[0] + s * b[0], a[1] + s * b[1])
I = (0, 1)
def Hs(x, y): u = ca(x, cm(I, y)); u3 = cm(u, cm(u, u)); return u3, cm(I, u3)
def Fs(x, y): h = Hs(x, y); return ca(x, h[0]), ca(y, h[1])
def Gs(a, b): w = ca(a, cm(I, b)); w3 = cm(w, cm(w, w)); return ca(a, w3, -1), ca(b, cm(I, w3), -1)
def cs_(a): return f"{a[0]}{'+' if a[1] >= 0 else '-'}{abs(a[1])}i"
Ns = [[(1, 0), I], [I, (-1, 0)]]
NNs = [[ca(cm(Ns[i][0], Ns[0][j]), cm(Ns[i][1], Ns[1][j])) for j in range(2)] for i in range(2)]
assert NNs == [[(0, 0), (0, 0)], [(0, 0), (0, 0)]]
gauss = [((a, b), (c, e)) for a in range(-1, 2) for b in range(-1, 2) for c in range(-1, 2) for e in range(-1, 2)]
assert all(Gs(*Fs(*p)) == p for p in gauss)
print("symmetric, F(1, 1) =", ", ".join(cs_(v) for v in Fs((1, 0), (1, 0))), " G of that:", ", ".join(cs_(v) for v in Gs(*Fs((1, 0), (1, 0)))))
print("symmetric, Hessian direction [[1, i], [i, -1]] squared: 0; G(F(p)) = p at all", len(gauss), "Gaussian points")
def d5(j, k):  # dH_k / d(coordinate j) at (1, 1) by a 5-point difference, exact for cubics
    sh = lambda m: Hs(*[(1 + m * (i == j), 0) for i in range(2)])[k]
    return tuple((8 * (sh(1)[r] - sh(-1)[r]) - (sh(2)[r] - sh(-2)[r])) // 12 for r in range(2))
v = ca((1, 0), I); f3v2 = cm((3, 0), cm(v, v)); JH = [d5(m % 2, m // 2) for m in range(4)]
assert JH == [cm(f3v2, e) for row in Ns for e in row]
print("symmetric, at (1, 1): v = 1+1i  3v^2 =", cs_(f3v2), " J_H by 5-point differences:", ", ".join(cs_(g) for g in JH))
print("ALL CHECKS PASS")
