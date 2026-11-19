# Finitely many solutions -- the check behind the card.  Standard library only:
# fractions gives exact rationals, math gives sqrt.  Two conics, the arm's 5 m reach
# circle and an oval track, meet in four points, found as eigenvalues of
# multiplication matrices on the quotient ring, then checked by other roads.
from fractions import Fraction as Q
import math
GREVLEX = lambda m: (m[0] + m[1], m[0])          # x^i y^j as (i, j); x > y
LEX_YX = lambda m: (m[1], m[0])                  # lex with y > x: eliminates y

def P(*terms): return {(i, j): Q(c) for c, i, j in terms if c}
def add(f, g, s=1):
    h = dict(f)
    for m, c in g.items():
        h[m] = h.get(m, 0) + s * c
        if h[m] == 0: del h[m]
    return h
def mono(f, c, i, j): return {(a + i, b + j): c * v for (a, b), v in f.items()}
def lt(f, o): return max(f, key=o)
def show(f, o):
    out = ""
    for m in sorted(f, key=o, reverse=True):
        c, name = f[m], ("x" + ("^%d" % m[0] if m[0] > 1 else "")) * (m[0] > 0) + ("y" + ("^%d" % m[1] if m[1] > 1 else "")) * (m[1] > 0)
        s = ("(%s)" % abs(c) if c.denominator > 1 and name else str(abs(c))) if abs(c) != 1 or not name else ""
        out += (" - " if c < 0 else " + ") + s + name
    return out[3:] if out[1] == "+" else "-" + out[3:]
def nf(f, G, o):                                 # remainder of f on division by the list G
    f, r = dict(f), {}
    while f:
        m = lt(f, o)
        for g in G:
            n = lt(g, o)
            if m[0] >= n[0] and m[1] >= n[1]:
                f = add(f, mono(g, f[m] / g[n], m[0] - n[0], m[1] - n[1]), -1); break
        else:
            r[m] = f.pop(m)
    return r
def groebner(F, o):                              # Buchberger, then the reduced basis
    G, pairs = list(F), [(i, j) for j in range(len(F)) for i in range(j)]
    while pairs:
        i, j = pairs.pop()
        a, b = lt(G[i], o), lt(G[j], o)
        L = (max(a[0], b[0]), max(a[1], b[1]))
        s = add(mono(G[i], 1 / G[i][a], L[0] - a[0], L[1] - a[1]), mono(G[j], 1 / G[j][b], L[0] - b[0], L[1] - b[1]), -1)
        r = nf(s, G, o)
        if r: pairs += [(k, len(G)) for k in range(len(G))]; G.append(r)
    L = [lt(g, o) for g in G]                    # keep g unless another leading term divides its own
    G = [g for k, g in enumerate(G) if not any(h != k and a[0] <= L[k][0] and a[1] <= L[k][1] and (a != L[k] or h < k) for h, a in enumerate(L))]
    G = [nf(g, G[:k] + G[k + 1:], o) for k, g in enumerate(G)]
    return sorted([mono(g, 1 / g[lt(g, o)], 0, 0) for g in G], key=lambda g: o(lt(g, o)))
def standard(G, o, deg):                         # monomials no leading term divides
    L = [lt(g, o) for g in G]
    return sorted([(i, d - i) for d in range(deg + 1) for i in range(d + 1) if not any(i >= a and d - i >= b for a, b in L)], key=o)
def mult(f, G, B, o):                            # column k is NF(f * B[k]) in the basis B
    cols = [nf({(m[0] + b[0], m[1] + b[1]): c for m, c in f.items()}, G, o) for b in B]
    return [[cols[k].get(B[r], Q(0)) for k in range(len(B))] for r in range(len(B))]
def matmul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]
def charpoly(A):                                 # Faddeev-LeVerrier, exact: t^n + c t^(n-1) + ...
    n, c, M = len(A), [Q(1)], [[Q(0)] * len(A) for _ in A]
    for k in range(1, n + 1):
        M = matmul(A, M)
        for i in range(n): M[i][i] += c[-1]
        c.append(-sum(matmul(A, M)[i][i] for i in range(n)) / k)
    return {(n - k, 0): v for k, v in enumerate(c) if v}
def roots(p):                                    # rational roots with multiplicity, our own search
    a, out = [p.get((k, 0), Q(0)) for k in range(max(m[0] for m in p) + 1)], []
    while len(a) > 1:
        if a[0] == 0: out.append(Q(0)); a = a[1:]; continue
        lead, cand = a[-1], set()
        for u in range(1, int(abs(a[0] * lead.denominator * a[0].denominator)) + 1):
            for v in range(1, int(abs(lead * a[0].denominator * lead.denominator)) + 1):
                cand |= {Q(u, v), Q(-u, v)}
        hit = next((r for r in sorted(cand) if sum(c * r ** k for k, c in enumerate(a)) == 0), None)
        if hit is None: break
        out.append(hit); b = [Q(0)] * (len(a) - 1); b[-1] = a[-1]
        for k in range(len(a) - 2, 0, -1): b[k - 1] = a[k] + hit * b[k]
        a = b
    return sorted(out, reverse=True)
def null(A):                                     # exact null space by row reduction
    A, piv, n = [r[:] for r in A], [], len(A[0])
    for col in range(n):
        r = next((i for i in range(len(piv), len(A)) if A[i][col] != 0), None)
        if r is None: continue
        A[len(piv)], A[r] = A[r], A[len(piv)]; row = A[len(piv)]; row[:] = [v / row[col] for v in row]
        for i in range(len(A)):
            if i != len(piv) and A[i][col] != 0: A[i] = [a - A[i][col] * b for a, b in zip(A[i], row)]
        piv.append(col)
    free = [c for c in range(n) if c not in piv]
    return [[Q(1) if c == f else -A[piv.index(c)][f] if c in piv else Q(0) for c in range(n)] for f in free]
def eigvec(M, lam, left=True):
    A = [[(M[j][i] if left else M[i][j]) - (lam if i == j else 0) for j in range(len(M))] for i in range(len(M))]
    return null(A)
def solve(F):                                    # the card's method, start to finish
    G = groebner(F, GREVLEX); B = standard(G, GREVLEX, 6)
    Mx, My = mult(P((1, 1, 0)), G, B, GREVLEX), mult(P((1, 0, 1)), G, B, GREVLEX)
    return G, B, Mx, My, roots(charpoly(Mx))
fmt = lambda B: "[" + ", ".join("1" if b == (0, 0) else show({b: Q(1)}, GREVLEX) for b in B) + "]"
circle, track = P((1, 2, 0), (1, 0, 2), (-25, 0, 0)), P((1, 2, 0), (1, 1, 1), (1, 0, 2), (-1, 1, 0), (-1, 0, 1), (-30, 0, 0))
G, B, Mx, My, ex = solve([circle, track])
print("reach circle:", show(circle, GREVLEX), "= 0;  track:", show(track, GREVLEX), "= 0")
print("Groebner basis, grevlex x > y:", " | ".join(show(g, GREVLEX) for g in G))
print("leading terms:", fmt([lt(g, GREVLEX) for g in G]), " pure power of x and of y: yes, so zero-dimensional")
print("standard monomials:", fmt(B), " dimension of the quotient:", len(B))
for name, M in (("M_x", Mx), ("M_y", My)):
    print(name, "rows:", "  ".join("[" + " ".join(str(v) for v in r) + "]" for r in M))
print("char poly of M_x:", show(charpoly(Mx), GREVLEX).replace("x", "t"), "  eigenvalues:", ", ".join(map(str, ex)))
print("char poly of M_y:", show(charpoly(My), GREVLEX).replace("x", "t"), "  eigenvalues:", ", ".join(map(str, roots(charpoly(My)))))
pts = []
for lam in ex:
    v = eigvec(Mx, lam)[0]; v = [c / v[B.index((0, 0))] for c in v]
    p = (v[B.index((1, 0))], v[B.index((0, 1))]); pts.append(p)
    res = [sum(c * p[0] ** m[0] * p[1] ** m[1] for m, c in f.items()) for f in (circle, track)]; vm = [sum(v[r] * Mx[r][k] for r in range(4)) for k in range(4)]
    print(f"eigenvalue {lam}: left eigenvector {fmt(B)} = ({', '.join(map(str, v))}) -> point ({p[0]}, {p[1]}); v M_x = ({', '.join(map(str, vm))}); residuals {res[0]}, {res[1]}")
L = groebner([circle, track], LEX_YX)
print("lex y > x basis:", " | ".join(show(g, LEX_YX) for g in L))
print("eliminant equals char poly of M_x:", L[0] == charpoly(Mx), "  M_x M_y = M_y M_x:", matmul(Mx, My) == matmul(My, Mx))
p101 = sum(1 for x in range(101) for y in range(101) if (x * x + y * y - 25) % 101 == 0 and (x * x + x * y + y * y - x - y - 30) % 101 == 0)
print("count over F_101 by trying all 10201 pairs:", p101, "  Bezout 2 x 2 =", 4)
d = [math.sqrt(2 * t * t) for t in ((2 + math.sqrt(364)) / 6, (2 - math.sqrt(364)) / 6)]
print(f"track on the line y = x: {d[0]:.3f} m and {d[1]:.3f} m from the shoulder;  track size {2 * math.sqrt(182 / 3):.3f} m by {2 * math.sqrt(182 / 9):.3f} m, centre (1/3, 1/3)")
w = eigvec(Mx, Q(3), left=False)[0]; w = [c / w[0] for c in w]
print(f"wrong: right eigenvector of M_x at 3, read as (1, y, x, y^2): {', '.join(map(str, w))} -> point ({w[2]}, {w[1]})")
G2, B2, Mx2, My2, ex2 = solve([circle, P((16, 2, 0), (9, 0, 2), (-288, 0, 0))])
Mc = [[a + 2 * b for a, b in zip(r, s)] for r, s in zip(Mx2, My2)]
print("shared x, 16x^2 + 9y^2 = 288: M_x eigenvalues", ", ".join(map(str, ex2)), "; eigenvectors at 3:", len(eigvec(Mx2, Q(3))), "; M_(x+2y) eigenvalues", ", ".join(map(str, roots(charpoly(Mc)))))
G3, B3, Mx3, My3, ex3 = solve([circle, P((1, 2, 0), (1, 1, 1), (1, 0, 2), (-4, 1, 0), (-5, 0, 1), (-5, 0, 0))])
print("tangent at (5, 0): dimension", len(B3), " eigenvalues", ", ".join(map(str, ex3)), " distinct points", len(set(ex3)))
G4 = groebner([P((1, 2, 0), (-1, 0, 2)), P((1, 2, 0), (-1, 1, 1), (-2, 1, 0), (2, 0, 1))], GREVLEX)
print("shared line y = x:", " | ".join(show(g, GREVLEX) for g in G4), "; standard monomials up to degree 2, 4, 8:", [len(standard(G4, GREVLEX, k)) for k in (2, 4, 8)])
G5, B5, Mx5, My5, ex5 = solve([circle, P((1, 1, 0), (1, 0, 1), (-1, 0, 0))])
print("try: line x + y = 1: dimension", len(B5), " M_x eigenvalues", ", ".join(map(str, ex5)))
print("try: M_(x+2y) on the track:", ", ".join(map(str, roots(charpoly([[a + 2 * b for a, b in zip(r, s)] for r, s in zip(Mx, My)])))), "  trace of M_x:", sum(Mx[i][i] for i in range(4)))
print("figure, points", " ".join(f"({x},{y})" for x, y in pts), f"circle r 5, track centre (1/3,1/3) semi-axes {math.sqrt(182 / 3):.3f} along y=-x, {math.sqrt(182 / 9):.3f} along y=x")
assert len(B) == 4 == len(ex) == len(set(pts)) == p101          # quotient size = eigenvalues = points = mod-p count
assert sorted(pts) == sorted([(Q(4), Q(3)), (Q(3), Q(4)), (Q(0), Q(-5)), (Q(-5), Q(0))])
assert all(sum(c * x ** m[0] * y ** m[1] for m, c in f.items()) == 0 for f in (circle, track) for x, y in pts)
assert L[0] == charpoly(Mx)                                     # elimination road = eigenvalue road
assert matmul(Mx, My) == matmul(My, Mx)
assert [p[0] for p in pts] == ex                                # eigenvector's x entry = its eigenvalue
assert len(eigvec(Mx2, Q(3))) == 2 and len(set(ex3)) == 3 and len(B3) == 4
print("ALL CHECKS PASS")
