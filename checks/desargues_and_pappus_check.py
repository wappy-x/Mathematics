# Desargues and Pappus -- the check behind the card.  Nothing is imported.
# A point (x, y) is the whole-number triple (x, y, 1) or any nonzero multiple.
# The line through two points and the meet of two lines are cross products;
# three points share a line, or three lines a point, when the 3 x 3 determinant
# of their triples is 0.  All arithmetic is exact, in whole numbers.
def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def det(a, b, c): return sum(x * y for x, y in zip(cross(a, b), c))
def meet(p, q, r, s): return cross(cross(p, q), cross(r, s))       # line pq meets line rs
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def gcd(a, b): return gcd(b, a % b) if b else abs(a)
def fr(n, d): g = gcd(n, d) * (1 if d > 0 else -1); return str(n // g) if d == g else f"{n // g}/{d // g}"
def pt(p): return f"({fr(p[0], p[2])}, {fr(p[1], p[2])})" if p[2] else str(p)
def slopes(p, q, r): return [fr(v[1]*u[2] - u[1]*v[2], v[0]*u[2] - u[0]*v[2]) for u, v in ((p, q), (q, r))]
def sides(a, b, c, a2, b2, c2): return meet(a, b, a2, b2), meet(b, c, b2, c2), meet(c, a, c2, a2)
def pappus(d, t): return meet(d[0], t[1], d[1], t[0]), meet(d[0], t[2], d[2], t[0]), meet(d[1], t[2], d[2], t[1])
O, A, B, C, A2, B2, C2 = (0, 0, 1), (1, 0, 1), (0, 1, 1), (1, 2, 1), (2, 0, 1), (0, 3, 1), (3, 6, 2)
print("triangles A B C =", *map(pt, (A, B, C)), " A' B' C' =", *map(pt, (A2, B2, C2)), " centre O", pt(O))
P, Q, R = sides(A, B, C, A2, B2, C2)
print("road 1, meets of matching sides: P", pt(P), "Q", pt(Q), "R", pt(R), "| det", det(P, Q, R), "| slopes", *slopes(P, Q, R))
def scaled(a, a2):                        # s, s2, k with s*a - s2*a2 = k*O, read off cross products
    D = cross(a, a2); i = 0 if D[0] else (1 if D[1] else 2)
    return cross(O, a2)[i], cross(O, a)[i], D[i]
pairs, g = [(A, A2), (B, B2), (C, C2)], 0
sc = [scaled(*p) for p in pairs]
reps = [tuple(sc[i][j] * sc[0][2] * sc[1][2] * sc[2][2] // sc[i][2] * x for x in pairs[i][j]) for i in range(3) for j in (0, 1)]
for x in sum(reps, ()): g = gcd(g, x)
a, a2, b, b2, c, c2 = [tuple(x // g for x in v) for v in reps]
print("road 2, rescaled: a", a, "a'", a2, "b", b, "b'", b2, "c", c, "c'", c2, "| each pair differs by", sub(a, a2))
print("road 2: a - b =", sub(a, b), "->", pt(sub(a, b)), " b - c =", sub(b, c), "->", pt(sub(b, c)), " c - a =", sub(c, a), "->", pt(sub(c, a)))
dual = sides(cross(B, C), cross(C, A), cross(A, B), cross(B2, C2), cross(C2, A2), cross(A2, B2))   # lines in, lines out
print("dual, the sides fed in as points: lines", *dual, "| det", det(*dual), "| common point", pt(cross(dual[0], dual[1])))
D, T = [(0, 0, 1), (1, 0, 1), (3, 0, 1)], [(0, 2, 1), (2, 2, 1), (5, 2, 1)]
M = pappus(D, T)
print("Pappus, x = 0 1 3 on y = 0, x = 0 2 5 on y = 2: M12", pt(M[0]), "M13", pt(M[1]), "M23", pt(M[2]), "| det", det(*M), "| slopes", *slopes(*M))
V = [(d[0] * t[0], 2 * d[0], d[0] + t[0]) for d, t in zip(D, T)]          # V_i = (d t, h d, d + t)
diffs = [sub(V[1], V[0]), sub(V[2], V[0]), sub(V[2], V[1])]
print("Pappus road 2: V =", *V, "| V2 - V1, V3 - V1, V3 - V2 ->", *map(pt, diffs))
S, n = [2026], [0, 0, 0, 0, 0]            # random state; genuine cases, off the line; nudged, off; nudged, flat ABC
def rnd():                                # a 64-bit congruential generator, whole numbers -9 to 9
    S[0] = (S[0] * 6364136223846793005 + 1442695040888963407) % 2**64; return (S[0] >> 33) % 19 - 9
def on(p, q): k = rnd() or 10; return tuple(k * x + y for x, y in zip(p, q))   # on line pq, not p or q
for _ in range(2000):
    o, x, y, z, u = [(rnd(), rnd(), rnd()) for _ in range(5)]
    cases = [sides(x, y, z, on(o, x), on(o, y), on(o, z)), pappus([on(u, o) for _ in "123"], [on(x, y) for _ in "123"]),
             sides(x, y, z, on(o, x), on(o, y), sub(on(o, z), cross(o, z)))]
    for i, pqr in enumerate(cases):
        if (0, 0, 0) not in pqr: n[i // 2 * 2] += 1; n[i // 2 * 2 + 1] += det(*pqr) != 0; n[4] += i == 2 and det(x, y, z) == 0
print(f"road 3, 2000 random cases of each theorem: {n[0]} with three genuine meets, {n[1]} of them off one line; nudge C' off its ray: {n[3]} of {n[2]} off the line, {n[4]} with a flat triangle ABC")
W = sides(A, B, C, C2, A2, B2); N = sides(A, B, C, A2, B2, (3, 5, 2)); K = pappus(D[:2] + [(6, 1, 2)], T)
print("mistakes: AB with C'A', BC with A'B', CA with B'C' -> slopes", *slopes(*W), "| C' = (3/2, 5/2) -> slopes", *slopes(*N))
print("mistakes: A - B unscaled ->", sub(A, B), "| D3 = (3, 1/2) -> slopes", *slopes(*K))
f = lambda p, x0, y0: f"({(x0 + 40 * p[0] / p[2]):.1f}, {(y0 - 40 * p[1] / p[2]):.1f})"
print("figure, Desargues 40 per unit:", " ".join(f(p, 60, 280) for p in (O, A, B, C, A2, B2, C2, P, Q, R)))
print("figure, Pappus 40 per unit:", " ".join(f(p, 330, 260) for p in D + T + list(M)))
assert det(P, Q, R) == 0 and [pt(P), pt(Q), pt(R)] == ["(4, -3)", "(2, 3)", "(1, 6)"]
assert sub(a, a2) == sub(b, b2) == sub(c, c2) and all(cross(r, m) == (0, 0, 0) for r, m in zip([sub(a, b), sub(b, c), sub(c, a)], [P, Q, R]))
assert det(*dual) == 0 and cross(dual[0], dual[1])[:2] == (0, 0) and det(*M) == 0
assert all(cross(r, m) == (0, 0, 0) for r, m in zip(diffs, M)) and n[1] == 0 and n[0] > 3000 and n[3] + n[4] == n[2]
print("ALL CHECKS PASS")
