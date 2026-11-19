# Bezout's theorem -- the check behind the card.  Standard library only.  House cubic C:
# y^2 = x^2(x + 1), equation F = y^2 - x^3 - x^2; its one point at infinity is O = (0 : 1 : 0).
# Each partner G is counted in the plane by two roads: the resultant Res_x(F, G), from Sylvester
# determinants at ten values of y, and G(t^2 - 1, t^3 - t), a polynomial in t.  A third road
# counts the meetings at O: the cut-off local count.  Plane plus O must give 3 x deg G.
from fractions import Fraction as Q
from functools import reduce
def trim(p): return p[:max((i + 1 for i, c in enumerate(p) if c != 0), default=0)]
def add(p, q): return trim([(p[i] if i < len(p) else 0) + (q[i] if i < len(q) else 0) for i in range(max(len(p), len(q)))])
def mul(p, q):                                   # polynomials as coefficient lists, low first
    out = [Q(0)] * max(len(p) + len(q) - 1, 0)
    for i, j in ((i, j) for i in range(len(p)) for j in range(len(q))): out[i + j] += p[i] * q[j]
    return trim(out)
def ev(p, v): return reduce(lambda s, c: s * v + c, reversed(p), 0 * v)   # Horner's rule
def show(p, v):                                  # leading term first
    out = ""
    for k in [k for k in range(len(p) - 1, -1, -1) if p[k] != 0]:
        a = abs(p[k])
        out += (" - " if p[k] < 0 else " + ") + (f"{a}" if a != 1 or k == 0 else "") \
            + (v if k else "") + (f"^{k}" if k > 1 else "")
    return (out[3:] if out[1] == "+" else "-" + out[3:]) if out else "0"
def deg(G): return max(i + j for i, j in G)      # a curve is {(i, j): c} for c x^i y^j
def elim(M):                                     # exact Gaussian elimination: rank and determinant
    M, d, r = [row[:] for row in M], Q(1), 0
    for c in range(len(M[0])):
        p = next((i for i in range(r, len(M)) if M[i][c] != 0), None)
        if p is None: d = Q(0); continue
        if p != r: M[r], M[p], d = M[p], M[r], -d
        d *= M[r][c]
        for i in (i for i in range(r + 1, len(M)) if M[i][c] != 0):
            f = M[i][c] / M[r][c]
            for k in range(c, len(M[0])): M[i][k] -= f * M[r][k]
        r += 1
    return r, d
def xrow(G, y):                                  # G's coefficients in x at this y, top first,
    n = deg(G); out = [Q(0)] * (n + 1)           # padded to the full degree of G
    for (i, j), c in G.items(): out[n - i] += c * y ** j
    return out
def sylvester(G, H, y):                         # n shifted rows of G's coefficients, m of H's
    a, b = xrow(G, y), xrow(H, y); m, n = len(a) - 1, len(b) - 1
    rows = [[Q(0)] * k + a + [Q(0)] * (n - 1 - k) for k in range(n)]
    return elim(rows + [[Q(0)] * k + b + [Q(0)] * (m - 1 - k) for k in range(m)])[1]
def resultant(G, H):                             # degree at most 9: ten samples fix it
    ys = [Q(k) for k in range(-4, 6)]; c = [sylvester(G, H, y) for y in ys]
    for k in range(1, 10):                       # Newton's divided differences
        for i in range(9, k - 1, -1): c[i] = (c[i] - c[i - 1]) / (ys[i] - ys[i - k])
    return reduce(lambda p, i: add(mul(p, [-ys[i], Q(1)]), [c[i]]), range(9, -1, -1), [])
def on_C(G):                                     # G(t^2 - 1, t^3 - t)
    X, Y = [Q(-1), Q(0), Q(1)], [Q(0), Q(-1), Q(0), Q(1)]
    return reduce(add, (reduce(mul, [X] * i + [Y] * j, [Q(c)]) for (i, j), c in G.items()), [])
def at_O(G, H, N):                               # road three: dim k[x, z] / (G, H, all terms of degree N),
    gs = [{(i, deg(K) - i - j): c for (i, j), c in K.items()} for K in (G, H)]   # in the chart y = 1
    mons = [(i, d - i) for d in range(N) for i in range(d + 1)]; ix = {m: k for k, m in enumerate(mons)}
    rows = [[Q(0)] * len(mons) for _ in range(2 * len(mons))]
    for r, (g, (a, b)) in enumerate((g, m) for g in gs for m in mons):
        for (i, j), c in g.items():
            if i + j + a + b < N: rows[r][ix[(i + a, j + b)]] += c
    return len(mons) - elim(rows)[0]
def mult_O(G, H):                                # raise N until two counts agree: then the count is final
    s = [at_O(G, H, 1)]
    while len(s) < 2 or s[-1] != s[-2]: s.append(at_O(G, H, len(s) + 1))
    return s
def roots(p, lo, hi, n=2400):                    # sign changes on a grid, then halving
    p, out = [float(c) for c in p], []
    for k in range(n):
        a, b = lo + (hi - lo) * k / n, lo + (hi - lo) * (k + 1) / n
        if (ev(p, a) > 0) != (ev(p, b) > 0):
            for _ in range(60):
                m = (a + b) / 2
                if (ev(p, a) > 0) != (ev(p, m) > 0): b = m
                else: a = m
            out.append((a + b) / 2)
    return out
def distinct(p):                                 # roots in C counted once: deg p - deg gcd(p, p')
    a, b = p, trim([i * p[i] for i in range(1, len(p))])
    while b:                                     # Euclid: (a, b) becomes (b, a mod b)
        while len(a) >= len(b):
            f, s = a[-1] / b[-1], len(a) - len(b)
            a = trim([c - f * b[i - s] if i >= s else c for i, c in enumerate(a)])
        a, b = b, a
    return len(p) - len(a)
def yn(c): return "yes" if c else "no"
F = {(0, 2): 1, (3, 0): -1, (2, 0): -1}
L = {(0, 3): 54, (0, 2): 9, (0, 1): -6, (0, 0): -1}                  # (3y - 1)(3y + 1)(6y + 1)
G = {(1, 0): 1, (0, 3): -216, (0, 2): -36, (0, 1): 24, (0, 0): 4}   # x = 4(9y^2 - 1)(6y + 1)
E = {(0, 2): 10, (3, 0): -10, (2, 0): -10, (0, 0): 1}                # y^2 = x^2(x + 1) - 1/10
T, W = {(1, 0): 4, (0, 1): 16, (0, 0): 9}, {(1, 0): 1, (0, 0): 2}
partners = [("tangent line 4x + 16y + 9 = 0", T, (3, 0)),
            ("line x = 5/4", {(1, 0): 4, (0, 0): -5}, (2, 1)), ("line x = -2", W, (2, 1)),
            ("three lines y = 1/3, -1/3, -1/6", L, (9, 0)),
            ("cubic G: x = 4(9y^2 - 1)(6y + 1)", G, (9, 0)),
            ("cubic E: y^2 = x^2(x + 1) - 1/10", E, (0, 9))]
print("C: y^2 = x^2(x + 1); (t^2 - 1, t^3 - t) lies on C:", yn(on_C(F) == []))
plane = {}
for name, H, want in partners:
    R, P, e, cut = resultant(F, H), on_C(H), deg(H), mult_O(F, H)
    plane[name] = len(R) - 1
    print(f"{name}: degree {e}, Bezout 3 x {e} = {3 * e}")
    print(f"    in the plane: resultant road {len(R) - 1}, parametrisation road {len(P) - 1}")
    print(f"    at O, cut-off counts {cut}: {cut[-1]}; total {len(R) - 1} + {cut[-1]} = {len(R) - 1 + cut[-1]}")
    assert len(R) == len(P) and (len(R) - 1, cut[-1]) == want and len(R) - 1 + cut[-1] == 3 * e
    if e == 1: print(f"    Res_x = {show(R, 'y')}; on C: {show(P, 't')}")
P0, R0 = (Q(-3, 4), Q(-3, 8)), (Q(9, 16), Q(-45, 64))
assert all(y * y == x * x * (x + 1) and 4 * x + 16 * y + 9 == 0 for x, y in (P0, R0))
ok = on_C(T) == mul([Q(1, 4), -1, 1], [20, 16]) and resultant(F, T) == mul([9, 48, 64], [-45, -64])
print(f"tangent: P = ({P0[0]}, {P0[1]}) at t = 1/2, R = ({R0[0]}, {R0[1]}) at t = -5/4; on C "
      f"16(t - 1/2)^2(t + 5/4), Res_x -(8y + 3)^2(64y + 45): {yn(ok)}")
print("line x = 5/4 meets C at (5/4, 15/8), (5/4, -15/8) and O = (0 : 1 : 0):", yn(Q(15, 8) ** 2 == Q(25, 16) * Q(9, 4)))
print(f"line x = -2: y^2 = (-2)^2(-2 + 1) = {(-2) ** 2 * (-2 + 1)}, so y = 2i or -2i, and O")
tG, yG, tL = roots(on_C(G), -3, 3), roots(resultant(F, G), -1, 1), roots(on_C(L), -3, 3)
pts = sorted((t * t - 1, t ** 3 - t) for t in tG)
assert all(abs(y * y - x * x * (x + 1)) < 1e-9 and abs(ev([-4, -24, 36, 216], y) - x) < 1e-9 for x, y in pts)  # on both
print(f"C and G: {len(pts)} real points, (x, y) =")
for k in range(0, 9, 3): print("    " + "; ".join(f"({x:.4f}, {y:.4f})" for x, y in pts[k:k + 3]))
same = len(yG) == 9 and max(abs(a - b) for a, b in zip(sorted(y for _, y in pts), yG)) < 1e-9
print("    the same nine y-values from the resultant's roots:", yn(same))
print(f"C and the three lines: {len(tL)} real points, 3 on each line")
assert same and len(pts) == 9 and len(tL) == 9
print(f"C and E: Res_x(F, E) = {show(resultant(F, E), 'y')}, a nonzero constant; E on C's parametrisation: {show(on_C(E), 't')}")
B1 = {(2, 0): 1, (0, 2): 1, (0, 0): -25}                          # beacon A: 5 m around (0, 0)
B2 = {(2, 0): 1, (0, 2): 1, (1, 0): -8, (0, 1): -8, (0, 0): -17}  # beacon B: 7 m around (4, 4)
RB = resultant(B1, B2)
fix = all(x * x + y * y == 25 and (x - 4) ** 2 + (y - 4) ** 2 == 49 for x, y in [(4, -3), (-3, 4)])
top = [x * x + y * y for x, y in [(1, 1j), (1, -1j)]]             # both circles' degree-2 part
print(f"beacon circles: Res_x = {show(RB, 'y')}: {len(RB) - 1} in the plane + {5 - len(RB)} at infinity")
print(f"    real fixes (4, -3), (-3, 4) on both: {yn(fix)}; (1 : i : 0), (1 : -i : 0) on both: {yn(top == [0, 0])}")
assert fix and top == [0, 0] and len(RB) == 3 and ev(RB, Q(-3)) == 0 == ev(RB, Q(4))
Z = resultant(F, {k: 2 * v for k, v in F.items()})
print(f"C against 2F, a shared curve: Res_x = {show(Z, 'y')}, so no finite count")
assert Z == [] and distinct(on_C(T)) == 2 and ok and on_C(F) == [] and Q(15, 8) ** 2 == Q(25, 16) * Q(9, 4)
print(f"mistakes: C and E in the plane only: {plane[partners[5][0]]}; tangent line as distinct points: {distinct(on_C(T))}")
print(f"    C and x = -2 in the real plane: {len(roots(on_C(W), -3, 3))}; "
      f"beacon circles in the real plane: {len(roots(RB, -10, 10, 2401))}")
tries = [("cubic S", {(0, 1): 1, (3, 0): -1, (2, 0): 4, (0, 0): -3}), ("line y = 2x", {(0, 1): 1, (1, 0): -2}),
         ("line x = 0", {(1, 0): 1}), ("E flipped", {**E, (0, 0): -1})]          # the "try changing" answers
print("try: " + "; ".join(f"{n} {len(resultant(F, H)) - 1} + {mult_O(F, H)[-1]}, on C {show(on_C(H), 't')}" for n, H in tries))
print(f"figure, window x -1.2 to 0.6, y -0.8 to 0.45; P ({float(P0[0])}, {float(P0[1])}), "
      f"R ({float(R0[0])}, {float(R0[1])}); node (0, 0)")
print("ALL CHECKS PASS")
