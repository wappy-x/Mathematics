# Divisors and Riemann-Roch on the cubic y^2 = x^3 + x^2 + 1 -- the check behind the card.
# Standard library only; Fraction is exact arithmetic on fractions, nothing more.  A function is
# (A + B y)/C with A, B, C polynomials in x, lowest power first.  Orders come from Laurent series.
from fractions import Fraction as Fr
from math import isqrt
F = [Fr(1), Fr(0), Fr(1), Fr(1)]                       # x^3 + x^2 + 1, the smooth neighbour
def ev(p, x): return sum(c * x ** i for i, c in enumerate(p))
def pmul(p, q):
    r = [Fr(0)] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q): r[i + j] += a * b
    return r
def psub(p, q): return [(p[i] if i < len(p) else 0) - (q[i] if i < len(q) else 0) for i in range(max(len(p), len(q)))]
def deg(p): return max([i for i, c in enumerate(p) if c != 0], default=-1)
def shift(p, x0):                                      # rewrite p in powers of t = x - x0
    r = [Fr(0)]
    for c in reversed(p): r = psub(pmul(r, [Fr(x0), Fr(1)]), [-c])
    return r
def lowest(s): return next(i for i, c in enumerate(s) if c != 0)
def roots(p):                                          # integer roots with multiplicity
    out = {}
    for r in range(-10, 11):
        q = p[:]
        while deg(q) > 0 and ev(q, r) == 0:
            out[r] = out.get(r, 0) + 1; b = shift(q, r)[1:]; q = shift(b, -r)
    return out
N = 8
def ordP(f, x0, y0):                                   # order at an affine point with y0 != 0
    A, B, C = (shift(p, x0) + [Fr(0)] * N for p in f); fs = shift(F, x0) + [Fr(0)] * N
    y = [Fr(y0)]                                       # Laurent (here Taylor) series of y in t
    for n in range(1, N): y.append((fs[n] - sum(y[i] * y[n - i] for i in range(1, n))) / (2 * y0))
    num = [A[n] + sum(B[i] * y[n - i] for i in range(n + 1)) for n in range(N)]
    return lowest(num) - lowest(C)
def ordO(f):                                           # x has a double pole at O, y a triple one
    A, B, C = f
    return 2 * deg(C) - max(2 * deg(A) if deg(A) >= 0 else -1, 2 * deg(B) + 3 if deg(B) >= 0 else -1)
def div(f):                                            # every zero and pole, over the rationals
    A, B, C = f; nm = psub(pmul(A, A), pmul(pmul(B, B), F)); d = {}
    for x0 in sorted(set(roots(nm)) | set(roots(C))):
        s = isqrt(max(0, int(ev(F, x0))))
        for y0 in (s, -s):
            if s * s == ev(F, x0) and ordP(f, x0, y0): d[f"({x0}, {y0})"] = ordP(f, x0, y0)
    if ordO(f): d["O"] = ordO(f)
    return d, sum(roots(nm).values()) == deg(nm), sum(roots(C).values()) == deg(C)
def show(d): return " ".join(f"{v:+d}{k}" for k, v in d.items()) + f", degree {sum(d.values())}"
def disc(a, b, c): return 18 * a * b * c - 4 * a ** 3 * c + a * a * b * b - 4 * b ** 3 - 27 * c * c  # x^3 + ax^2 + bx + c
dsc = disc(F[2], F[1], F[0])
print(f"curve y^2 = x^3 + x^2 + 1; discriminant of the cubic {dsc}, not 0: smooth; genus (3-1)(3-2)/2 = {(3 - 1) * (3 - 2) // 2}")
print(f"nodal neighbour y^2 = x^3 + x^2: discriminant {disc(1, 0, 0)}: a node at (0, 0)")
assert dsc == -4 - 27 and disc(1, 0, 0) == 0             # by hand: only the c terms survive
P, Q = (0, 1), (-1, -1)
on = lambda pt: Fr(pt[1]) ** 2 == ev(F, Fr(pt[0]))
m = Fr(Q[1] - P[1], Q[0] - P[0]); k = P[1] - m * P[0]
cub = psub(F, pmul([k, m], [k, m]))                    # x^3 + x^2 + 1 - (mx + k)^2
xR = -cub[2] - P[0] - Q[0]; R = (xR, m * xR + k)
print(f"P = {P}, Q = {Q} on the curve: {on(P) and on(Q)}; line y = {m}x + {k}; cubic on it {[int(v) for v in reversed(cub)]}, roots {sorted(roots(cub))}")
print(f"third point R = ({R[0]}, {R[1]}): {R[1] ** 2} = {ev(F, R[0])}; reflection -R = ({R[0]}, {-R[1]})")
assert on(R) and sorted(roots(cub)) == [-1, 0, 4]
ell = ([-k, -m], [Fr(1)], [Fr(1)])                     # the line y - 2x - 1 as a function
vrt = ([-R[0], Fr(1)], [], [Fr(1)])                    # the vertical line x - 4
g = ([k, m], [Fr(1)], [Fr(0), Fr(1), Fr(1)])           # u = (y + 2x + 1)/(x(x + 1))
lhs = pmul([-R[0], Fr(1)], [Fr(0), Fr(1), Fr(1)]); rhs = psub(F, pmul([k, m], [k, m]))
print(f"(x - 4) x (x + 1) = {[int(v) for v in reversed(lhs)]} and y^2 - (2x + 1)^2 = {[int(v) for v in reversed(rhs)]}: so (x - 4)/(y - 2x - 1) = (y + 2x + 1)/(x(x + 1))")
assert lhs == rhs[:len(lhs)]
for name, f in (("line y - 2x - 1", ell), ("vertical x - 4", vrt), ("u", g), ("x", ([Fr(0), Fr(1)], [], [Fr(1)]))):
    d, z, p = div(f)
    print(f"div {name}: {show(d)}; every zero and pole found: {z and p}")
    assert sum(d.values()) == 0 and z and p
dg = div(g)[0]
assert dg == {"(0, 1)": -1, "(-1, -1)": -1, "(4, -9)": 1, "O": 1}
tq = ordP(([Fr(3), Fr(1)], [Fr(2)], [Fr(1)]), *Q)      # the tangent x + 2y + 3 at Q tests the series of y past y0
print(f"tangent x + 2y + 3 at Q: order {tq} there, a double zero, read off the series of y in t = x + 1")
dy = div(([], [Fr(1)], [Fr(1)]))[0]                    # div y: its norm -F has no rational root
lo, hi = -2.0, -1.0
for _ in range(80): mid = (lo + hi) / 2; lo, hi = (mid, hi) if ev(F, mid) < 0 else (lo, mid)
re = (-1 - lo) / 2; im = (-1 / lo - re * re) ** 0.5
print(f"div y over the complex numbers: zeros at x = {lo:.10f} and {re:.6f} +/- {im:.6f}i, -3O, degree 0")
print(f"mistake, div y over the rationals only: {sum(v > 0 for v in dy.values())} zeros, pole {show(dy)}")
print(f"mistake, div x with O left out: {show({k: v for k, v in div(([Fr(0), Fr(1)], [], [Fr(1)]))[0].items() if k != 'O'})}")
Ln = {}
for n in range(7):                                     # L(nO): monomials x^i y^j, j <= 1
    Ln[n] = [(i, j) for i, j in sorted(((i, j) for i in range(4) for j in (0, 1)), key=lambda e: 2 * e[0] + 3 * e[1]) if 2 * i + 3 * j <= n]
    basis = [("1" if i == 0 else "x" if i == 1 else f"x^{i}") if j == 0 else ("y" if i == 0 else "xy" if i == 1 else f"x^{i}y") for i, j in Ln[n]]
    rr = n + 1 - 1 + (1 if n == 0 else 0)              # l(K - D) = l(-nO) is 1 at n = 0, else 0
    print(f"L({n}O): pole orders 2i + 3j <= {n}: {', '.join(basis)}; l = {len(basis)}; Riemann-Roch {n} + 1 - 1 + l(K - D) = {rr}")
    assert len(basis) == rr
gaps = [n for n in Ln if n and len(Ln[n]) == len(Ln[n - 1])]   # pole orders no function reaches: the gaps at O
print(f"mistake, Riemann-Roch at D = 0 without l(K - D): 0 + 1 - 1 = {0 + 1 - 1}, but the constants give l(0) = 1")
top = -ordO(ell); D = {"(0, 1)": 1, "(-1, -1)": 1}     # D = P + Q; f(y - 2x - 1) lies in L(3O), 3 read off div of the line
row = [R[0] ** i * R[1] ** j for i, j in Ln[top]]      # the basis of L(3O) at R: h = a + bx + cy must vanish there
pv = next(c for c, v in enumerate(row) if v != 0)      # elimination on one nonzero row: a pivot, and each other column free
ker = [[Fr(c == e) - (row[e] / row[pv] if c == pv else 0) for c in range(len(row))] for e in range(len(row)) if e != pv]
dim, rank, genus = len(ker), len(row) - len(ker), len(gaps); rr2 = sum(D.values()) + 1 - genus
inL = []
for h in ker:                                          # h/(y - 2x - 1) = h(y + 2x + 1)/(y^2 - (2x + 1)^2), as (A + By)/C
    H = [[Fr(0)] * 4, [Fr(0)] * 4]
    for v, (i, j) in zip(h, Ln[top]): H[j][i] += v
    d, _, p = div((psub(pmul(H[0], [k, m]), pmul([-1], pmul(H[1], F))), psub(H[0], pmul([-1], pmul(H[1], [k, m]))), cub))
    inL.append(p and all(v >= -D.get(key, 0) for key, v in d.items()))
print(f"L(P + Q): f x (y - 2x - 1) = a + bx + cy, zero at R: a + {row[1]}b + {row[2]}c = 0, rank {rank}, so l(P + Q) = {len(row)} - {rank} = {dim}")
print(f"kernel in 1, x, y: {[[int(v) for v in h] for h in ker]}; each over y - 2x - 1 has at most simple poles at P and Q, none elsewhere: {all(inL)}")
print(f"Riemann-Roch: l(P + Q) = deg {sum(D.values())} + 1 - genus {genus} = {rr2}, the genus counted as the gaps {gaps} in the pole orders at O")
idn = [b - c - 2 * a for a, b, c in zip(ker[0], ker[1], [-k, -m, Fr(1)])]   # (y - 9) - (y - 2x - 1) - 2(x - 4), in 1, x, y
print(f"second solution (y - 9)/(y - 2x - 1) = 1 + 2u: (y - 9) - (y - 2x - 1) - 2(x - 4) = {[int(v) for v in idn]}")
assert dim == rr2 == 2 and genus == (3 - 1) * (3 - 2) // 2 and all(inL) and tq == 2 and not any(idn) and dg["(0, 1)"] == dg["(-1, -1)"] == -1
print(f"mistake, Riemann-Roch with genus 0 on the cubic: l(P + Q) = {2 + 1 - 0}, but the count above gives {dim}")
print(f"test P + Q ~ (4, -9) + O: difference = -div u, so equivalent; the chord gives P + Q = ({R[0]}, {-R[1]}) in the group law")
M = [[Fr(1), Fr(P[0])], [Fr(1), Fr(Q[0])]]            # h = a + bx at P and at Q
det = M[0][0] * M[1][1] - M[0][1] * M[1][0]
print(f"test P + Q ~ 2O: h in L(2O) = span(1, x) with zeros P, Q needs a + 0b = 0, a - b = 0; determinant {det}: only h = 0, not equivalent")
assert det != 0
print(f"test P ~ Q: l(Q) = 1 + 1 - 1 = {1 + 1 - genus}, constants only, so no function has divisor P - Q: not equivalent")
ts = range(-3, 4)                                      # nodal cubic: x = t^2 - 1, y = t(t^2 - 1)
ok = all(Fr(t * (t * t - 1)) ** 2 == Fr(t * t - 1) ** 3 + Fr(t * t - 1) ** 2 for t in ts)
print(f"nodal y^2 = x^3 + x^2: x = t^2 - 1, y = t^3 - t fits at 7 values of t, a degree-6 identity: {ok}")
mt = roots(psub([Fr(0), Fr(0), Fr(1), Fr(1)], [Fr(0), Fr(0), Fr(4)]))   # where the line y = 2x meets it: x^3 + x^2 - (2x)^2 = 0
x2 = max(mt)
print(f"nodal, on its smooth model (the t-line): y = 2x meets it {mt[0]} times at the node (t = 1 and t = -1) and once at ({x2}, {2 * x2}), "
      f"so t = y/x is 2 only there; one simple pole at O, so l(O) = 2, not the smooth cubic's {len(Ln[1])}")
assert ok and mt == {0: 2, 3: 1} and ordO(([], [Fr(1)], [Fr(0), Fr(1)])) == -1
sv = lambda x, y: f"{70 + 20 * x:.1f},{230 - 20 * y:.1f}"
xs = [lo + (4.4 - lo) * (i / 16) ** 2 for i in range(17)]
print("figure, 20 per unit, origin (70,230), upper curve:", " ".join(sv(x, max(0.0, ev(F, x)) ** 0.5) for x in xs))
print("figure, P", sv(0, 1), "Q", sv(-1, -1), "R", sv(4, 9), "-R", sv(4, -9), "line", sv(-1.5, -2), "to", sv(4.5, 10), "vertical", sv(4, 10.5), "to", sv(4, -10.5))
print("ALL CHECKS PASS")
