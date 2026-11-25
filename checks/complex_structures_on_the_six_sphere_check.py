# The six-sphere card's check.  Standard library only, exact fractions only.
# Roads: J^2 = -1 by direct product; the Nijenhuis tensor three ways
# (brackets of explicit fields, a connection formula, a closed form).
from fractions import Fraction as F

T7 = [(i, (i + 1) % 7, (i + 3) % 7) for i in range(7)]  # e1e2=e4, e2e3=e5, ...
T3 = [(0, 1, 2)]                                        # quaternions: ij = k

def cross(u, v, T):
    w = [F(0)] * len(u)
    for (i, j, k) in T:
        for (a, b, c) in ((i, j, k), (j, k, i), (k, i, j)):
            w[c] += u[a] * v[b] - u[b] * v[a]
    return w

def dot(u, v): return sum(a * b for a, b in zip(u, v))
def add(*vs): return [sum(c) for c in zip(*vs)]
def sc(s, v): return [s * a for a in v]
def basis(n, i): return [F(int(k == i)) for k in range(n)]
def show(v): return "(" + ", ".join(str(a) for a in v) + ")"

def nij_brackets(p, a, b, T):
    # Fields near the sphere: X = a - (a.p)p and JX = p x a; D = derivative.
    J = lambda v: cross(p, v, T)
    X = (add(a, sc(-dot(a, p), p)), lambda w: add(sc(-dot(a, w), p), sc(-dot(a, p), w)))
    Y = (add(b, sc(-dot(b, p), p)), lambda w: add(sc(-dot(b, w), p), sc(-dot(b, p), w)))
    JX = (cross(p, a, T), lambda w: cross(w, a, T))
    JY = (cross(p, b, T), lambda w: cross(w, b, T))
    br = lambda U, V: add(V[1](U[0]), sc(-1, U[1](V[0])))  # [U,V] = DV(U) - DU(V)
    return add(br(JX, JY), sc(-1, J(br(JX, Y))), sc(-1, J(br(X, JY))), sc(-1, br(X, Y)))

def nij_connection(p, X, Y, T):
    J = lambda v: cross(p, v, T)
    B = lambda U, V: add(cross(U, V, T), sc(-dot(p, cross(U, V, T)), p))  # (nabla_U J)V
    return add(B(J(X), Y), sc(-1, B(J(Y), X)), sc(-1, J(B(X, Y))), J(B(Y, X)))

def nij_closed(p, X, Y, T): return sc(-4, cross(p, cross(X, Y, T), T))

E = [basis(7, i) for i in range(7)]
print("table: e1e2=e4 e2e3=e5 e3e4=e6 e4e5=e7 e5e6=e1 e6e7=e2 e7e1=e3")
bad = 0
for u in E:
    for v in E:
        w = cross(u, v, T7)
        bad += dot(w, w) != dot(u, u) * dot(v, v) - dot(u, v) ** 2
assert bad == 0
print("length rule |u x v|^2 = |u|^2|v|^2 - (u.v)^2: 49 basis pairs, failures", bad)
jac = add(cross(E[0], cross(E[1], E[2], T7), T7), cross(E[1], cross(E[2], E[0], T7), T7),
          cross(E[2], cross(E[0], E[1], T7), T7))
print("Jacobi sum for e1, e2, e3 in 7D:", show(jac))
i3 = [basis(3, i) for i in range(3)]
jac3 = add(cross(i3[0], cross(i3[1], i3[2], T3), T3), cross(i3[1], cross(i3[2], i3[0], T3), T3),
           cross(i3[2], cross(i3[0], i3[1], T3), T3))
assert jac3 == [0, 0, 0] and jac != [0] * 7
print("Jacobi sum for i, j, k in 3D:", show(jac3))

p = [F(2, 7), F(3, 7), F(6, 7), F(0), F(0), F(0), F(0)]
v = [F(3), F(-2), F(0), F(1), F(0), F(0), F(0)]
Jv = cross(p, v, T7); JJv = cross(p, Jv, T7)
print("point x =", show(p), " |x|^2 =", dot(p, p))
print("tangent v =", show(v), " x.v =", dot(p, v), " |v|^2 =", dot(v, v))
print("Jv = x x v =", show(Jv), " |Jv|^2 =", dot(Jv, Jv), " x.Jv =", dot(p, Jv))
print("J(Jv) =", show(JJv))
assert dot(p, p) == 1 and JJv == sc(-1, v) and dot(Jv, Jv) == dot(v, v)
for s in range(1, 6):  # J^2 = -1 on more tangent vectors, built by projection
    w = [F((s * k * k + 3 * k + s) % 11 - 5) for k in range(7)]
    w = add(w, sc(-dot(w, p), p))
    assert cross(p, cross(p, w, T7), T7) == sc(-1, w)
print("J(Jw) = -w checked for 5 more tangent vectors at x")

X, Y = E[3], E[4]
N1 = nij_brackets(p, X, Y, T7); N2 = nij_connection(p, X, Y, T7); N3 = nij_closed(p, X, Y, T7)
print("X = e4, Y = e5: JX.Y =", dot(cross(p, X, T7), Y))
print("N(X,Y) by brackets   =", show(N1))
print("N(X,Y) by connection =", show(N2))
print("N(X,Y) = -4 x(XxY)   =", show(N3))
assert N1 == N2 == N3
print("|N(X,Y)|^2 =", dot(N1, N1))
assert dot(N1, N1) == 16
zero = nz = 0
for a in range(1, 7):
    for b in range(a + 1, 7):
        n1 = nij_brackets(E[0], E[a], E[b], T7)
        assert n1 == nij_closed(E[0], E[a], E[b], T7) == nij_connection(E[0], E[a], E[b], T7)
        zero += n1 == [0] * 7; nz += dot(n1, n1) == 16
assert zero + nz == 15
print("at e1, 15 pairs of basis tangents: N = 0 for", zero, "pairs, |N|^2 = 16 for", nz)
a, b = E[0], E[1]  # e1, e2 are not tangent at x, so the plain bracket [X,Y] is not 0 there
Xa, Yb = add(a, sc(-dot(a, p), p)), add(b, sc(-dot(b, p), p))
n4 = nij_brackets(p, a, b, T7)
assert n4 == nij_connection(p, Xa, Yb, T7) == nij_closed(p, Xa, Yb, T7) != [0] * 7
print("X, Y from e1, e2, not tangent at x: three roads agree, N =", show(n4))

q = [F(2, 7), F(3, 7), F(6, 7)]
a2, b2 = [F(3), F(-2), F(0)], [F(0), F(6), F(-3)]
n2 = nij_brackets(q, a2, b2, T3)
assert dot(q, a2) == dot(q, b2) == 0 and n2 == nij_closed(q, a2, b2, T3) == [0, 0, 0]
print("S^2 at", show(q), "J(3,-2,0) =", show(cross(q, a2, T3)), " N =", show(n2))

print("n, sphere, (n-1)!, test: c_n = Euler number 2 must be a multiple of (n-1)!")
f = 1
for n in range(1, 9):
    f = f * (n - 1) if n > 1 else 1
    ok = 2 % f == 0
    note = "passes" if ok else "fails"
    if n == 2:  # S^4, quoted facts, not checked here: c1 = 0 and c2 = 2 give p1 = c1^2 - 2 c2, but p1(S^4) = 0
        p1 = 0 * 0 - 2 * 2
        note = "passes, but p1 = -2 c2 = " + str(p1) + ", not 0: fails"
    print(n, "S^" + str(2 * n), f, note)
    assert ok == (n <= 3)

print("what breaks, off the sphere: x' = 2x gives J(Jv) =", show(cross(sc(2, p), cross(sc(2, p), v, T7), T7)))
e1 = E[0]
print("what breaks, not tangent: v = e1 gives J(Jv) =", show(cross(p, cross(p, e1, T7), T7)))
print("ALL CHECKS PASS")
