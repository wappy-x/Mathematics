# Root systems and Dynkin diagrams -- the check behind the card.  Standard library only.
# Roots are integer vectors (F4 and E8 doubled), so every axiom is tested exactly.  Roads:
# simple roots against the roots grown back from them, the Weyl group by closure against
# its Coxeter count, counts against formulas, the diagram list against a brute-force search.
import math
from itertools import permutations, product

def dot(a, b): return sum(x * y for x, y in zip(a, b))
def add(a, b, k=1): return tuple(x + k * y for x, y in zip(a, b))
def reflect(b, a): return add(b, a, -(2 * dot(b, a) // dot(a, a)))  # s_a(b)
def e(i, n, s=1): return tuple(s if k == i else 0 for k in range(n))
def signs(k): return product((1, -1), repeat=k)
def yn(c): return "yes" if c else "no"
def det(m):                    # Bareiss elimination, exact; each pivot is a leading minor, never 0 here
    m, prev, n = [r[:] for r in m], 1, len(m)
    for k in range(n - 1):
        for i in range(k + 1, n):
            for j in range(k + 1, n):
                m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) // prev
        prev = m[k][k]
    return m[n - 1][n - 1]

def analyse(roots):                            # axioms, positive and simple roots, Cartan matrix
    R, n = set(roots), len(roots[0])
    r2 = all(b in (a, add(a, a, -2)) for a in roots for b in roots if dot(a, b) ** 2 == dot(a, a) * dot(b, b))
    r4 = all(2 * dot(b, a) % dot(a, a) == 0 for a in roots for b in roots)
    r3 = r4 and all(reflect(b, a) in R for a in roots for b in roots)
    t = [2 ** (n - 1 - k) for k in range(n)]                  # a direction square to no root
    pos = {a for a in roots if dot(a, t) > 0}
    simple = sorted((a for a in pos if not any(add(a, b, -1) in pos for b in pos)),
                    key=lambda a: (dot(a, a), [-x for x in a]))
    grown, front = set(simple), set(simple)
    while front:                                              # add simple roots while still a root
        front = {add(b, s) for b in front for s in simple} & R - grown
        grown |= front
    C = [[2 * dot(a, b) // dot(b, b) for b in simple] for a in simple]
    r1 = e(0, n, 0) not in R and det(C) != 0 and grown == pos
    short = sum(dot(a, a) == min(dot(b, b) for b in roots) for a in roots)
    return dict(ok=(r1, r2, r3, r4), grown=grown == pos, pos=pos, simple=simple, C=C, short=short)
def shape(C):                                  # bonds, and arm lengths at a branch dot
    n = len(C); nb = lambda i: [j for j in range(n) if j != i and C[i][j]]
    bonds = sorted(C[i][j] * C[j][i] for i in range(n) for j in range(i + 1, n) if C[i][j])
    arms = []
    for b in [i for i in range(n) if len(nb(i)) == 3]:
        for s in nb(b):
            prev, cur, k = b, s, 1
            while len(nb(cur)) == 2:
                prev, cur, k = cur, [j for j in nb(cur) if j != prev][0], k + 1
            arms.append(k)
    return bonds, sorted(arms)

def weyl(roots, simple):                       # closure of the simple reflections, as shuffles of roots
    ix = {a: i for i, a in enumerate(roots)}
    gens = [tuple(ix[reflect(b, s)] for b in roots) for s in simple]
    seen = front = {tuple(range(len(roots)))}
    while front:
        front = {tuple(g[i] for i in p) for p in front for g in gens} - seen
        seen = seen | front
    return seen
A2 = [add(e(i, 3), e(j, 3), -1) for i in range(3) for j in range(3) if i != j]
G2 = A2 + [tuple(s * (3 * x - 1) for x in e(i, 3)) for i in range(3) for s in (1, -1)]
pairs = lambda n, c: [add(e(i, n, c * s), e(j, n, c * u)) for i in range(n) for j in range(i + 1, n) for s, u in signs(2)]
B3 = pairs(3, 1) + [e(i, 3, s) for i in range(3) for s in (1, -1)]
C3 = pairs(3, 1) + [e(i, 3, 2 * s) for i in range(3) for s in (1, -1)]
F4 = pairs(4, 2) + [e(i, 4, 2 * s) for i in range(4) for s in (1, -1)] + list(signs(4))
E8 = pairs(8, 2) + [v for v in signs(8) if v.count(-1) % 2 == 0]
E7 = [a for a in E8 if dot(a, (1,) * 8) == 0]
E6 = [a for a in E7 if dot(a, (-2, -2) + (0,) * 6) == 0]
systems = [("A2", A2), ("G2", G2), ("B3", B3), ("C3", C3), ("D4", pairs(4, 1)), ("F4", F4), ("E6", E6), ("E7", E7), ("E8", E8)]
info = {name: analyse(roots) for name, roots in systems}
for name, roots in systems[:2]:
    d = info[name]; W = weyl(roots, d["simple"]); i = roots.index(d["simple"][0])
    ang = sorted({round(math.degrees(math.acos(dot(a, b) / math.sqrt(dot(a, a) * dot(b, b))))) for a in roots for b in roots if a != b})
    four = sorted({4 * dot(a, b) ** 2 // (dot(a, a) * dot(b, b)) for a in roots for b in roots})
    m = {0: 2, 1: 3, 2: 4, 3: 6}[d["C"][0][1] * d["C"][1][0]]
    orbit, stab = len({p[i] for p in W}), sum(p[i] == i for p in W)
    print(f"{name}: {len(roots)} roots, {len(d['pos'])} positive, simple roots {d['simple'][0]} and {d['simple'][1]}")
    print(f"{name} axioms R1 R2 R3 R4: {' '.join(yn(x) for x in d['ok'])}; positive roots grown from the simple two: {yn(d['grown'])}")
    print(f"{name} angles between roots (degrees): {ang}; 4cos^2 values: {four}")
    print(f"{name} Cartan matrix {d['C']}, determinant {det(d['C'])}, bonds {shape(d['C'])[0]}")
    print(f"{name} Weyl group by closure: {len(W)}; Coxeter count 2m with m = {m}: {2 * m}; orbit of alpha1 {orbit} x stabiliser {stab} = {orbit * stab}")
    assert len(W) == 2 * m == orbit * stab and all(d["ok"]) and d["grown"]
print(f"A2 dimension: {len(A2)} roots + rank 2 = {len(A2) + 2}; n(n + 2) at n = 2: {2 * 4}; 3! = {math.factorial(3)}")
print("type rank roots positive short dimension det bonds arms Weyl")
for name, roots in systems:
    d = info[name]; r = len(d["simple"]); b, a = shape(d["C"])
    d["W"] = len(weyl(roots, d["simple"])) if len(roots) <= 48 else 0
    print(f"{name} {r} {len(roots)} {len(d['pos'])} {d['short']} {len(roots) + r} {det(d['C'])} {b} {a} {d['W'] or '-'}")
    assert all(d["ok"]) and d["grown"] and len(b) == r - 1      # axioms hold; the diagram is a tree
assert info["A2"]["C"] == [[2, -1], [-1, 2]] and info["G2"]["C"] == [[2, -1], [-3, 2]]
assert len(A2) + 2 == 2 * (2 + 2) and info["A2"]["W"] == math.factorial(3)
assert [len(B3) + 3, len(C3) + 3, len(pairs(4, 1)) + 4] == [3 * 7, 3 * 7, 4 * 7]   # n(2n+1), n(2n+1), n(2n-1)
assert info["B3"]["W"] == 2 ** 3 * 6 and info["D4"]["W"] == 2 ** 3 * 24   # signed shuffles
print(f"E8 roots by counting: 4 x C(8,2) + 2^7 = {4 * 28} + {2 ** 7} = {4 * 28 + 2 ** 7}; dimension {len(E8) + 8}")
assert len(E8) == 4 * math.comb(8, 2) + 2 ** 7 and shape(info["E8"]["C"])[1] == [1, 2, 4]

def posdef(M):                                 # Cholesky on the form with -cos(pi/m) off the diagonal
    n, c = len(M), [0.0, 0.5, math.sqrt(2) / 2, math.sqrt(3) / 2]
    a = [[1.0 if i == j else -c[M[i][j]] for j in range(n)] for i in range(n)]
    L = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            s = a[i][j] - sum(L[i][k] * L[j][k] for k in range(j))
            if i == j and s < 1e-9: return False
            L[i][j] = math.sqrt(s) if i == j else s / L[j][j]
    return True

canon = lambda M: min(tuple(M[p[i]][p[j]] for j in range(len(M)) for i in range(j)) for p in permutations(range(len(M))))
reps, brute = [[[0]]], [1]
for n in range(2, 10):                         # grow every connected diagram one dot at a time
    found = {}
    for M in reps:
        for ext in product(range(4), repeat=n - 1):
            N = [row + [x] for row, x in zip(M, ext)] + [list(ext) + [0]]
            if any(ext) and posdef(N): found.setdefault(canon(N), N)
    reps = list(found.values()); brute.append(len(reps))
listed = [1 + (n >= 2) + (n >= 4) + (n in (6, 7, 8)) + (n == 4) + (n == 2) for n in range(1, 10)]
print(f"connected positive-definite diagrams, ranks 1 to 9, brute force: {brute}")
print(f"the same ranks, counted from the list A, B = C, D, E, F4, G2:   {listed}")
assert brute == listed

ten = [(math.cos(k * math.pi / 5), math.sin(k * math.pi / 5)) for k in range(10)]
close = all(any(abs(r[0] - v[0] + 2 * dot(v, a) * a[0]) + abs(r[1] - v[1] + 2 * dot(v, a) * a[1]) < 1e-9 for r in ten) for a in ten for v in ten)
gold = 2 * dot(ten[1], ten[0])
print(f"mistake 1, ten roots 36 degrees apart: reflections close up {yn(close)}, but 2cos(36 deg) = {gold:.12f}, not whole")
assert close and abs(gold - (1 + math.sqrt(5)) / 2) < 1e-12 and abs(gold - round(gold)) > 0.1
tri = [[2, -1, -1], [-1, 2, -1], [-1, -1, 2]]
e9 = [[2 if i == j else -1 if abs(i - j) == 1 and max(i, j) < 8 or {i, j} == {2, 8} else 0 for j in range(9)] for i in range(9)]
print(f"mistake 2, three dots in a triangle: Cartan determinant {det(tri)}; E8's long arm made one dot longer: {det(e9)}")
assert det(tri) == 0 and det(e9) == 0 and not posdef([[0, 1, 1], [1, 0, 1], [1, 1, 0]])
G = lambda p: [[dot(A2[p[i]], A2[p[j]]) for j in range(6)] for i in range(6)]
sym = sum(G(p) == G(range(6)) for p in permutations(range(6)))
print(f"mistake 3, every symmetry of the hexagon: {sym}, but the Weyl group has {info['A2']['W']}")
print(f"mistake 4, dimension of sl(3) as roots only: {len(A2)}, not {len(A2) + 2}")
assert sym == 2 * info["A2"]["W"]
xy = lambda a: f"({(a[0] - a[1]) / math.sqrt(2):.3f}, {(a[0] + a[1] - 2 * a[2]) / math.sqrt(6):.3f})"
print("figure, A2 roots:", " ".join(xy(a) for a in A2))
print("figure, G2 long roots:", " ".join(xy(a) for a in G2[6:]))
print("ALL CHECKS PASS")
