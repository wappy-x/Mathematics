# Intersection multiplicity -- the check behind the card.  Imports: fractions,
# for exact rationals, and math, for binomial coefficients and one square root;
# neither knows any multiplicity.  A curve is a dict {(i, j): c} for c x^i y^j.
from fractions import Fraction as Q
from math import comb, sqrt
def shift(f, a, b):                       # f(u + a, v + b): the curve seen from P = (a, b)
    r = {}
    for (i, j), c in f.items():
        for p in range(i + 1):
            for q in range(j + 1):
                r[(p, q)] = r.get((p, q), 0) + c * comb(i, p) * a ** (i - p) * comb(j, q) * b ** (j - q)
    return {k: v for k, v in r.items() if v}
def mul2(f, g):
    r = {}
    for (i, j), c in f.items():
        for (k, l), d in g.items(): r[(i + k, j + l)] = r.get((i + k, j + l), 0) + c * d
    return {k: v for k, v in r.items() if v}
def rank(rows):                           # Gaussian elimination over the rationals
    rows, r = [[Q(x) for x in row] for row in rows], 0
    for c in range(len(rows[0]) if rows else 0):
        p = next((i for i in range(r, len(rows)) if rows[i][c] != 0), None)
        if p is None: continue
        rows[r], rows[p] = rows[p], rows[r]
        for i in range(len(rows)):
            if i != r and rows[i][c] != 0:
                k = rows[i][c] / rows[r][c]; rows[i] = [x - k * y for x, y in zip(rows[i], rows[r])]
        r += 1
    return r
def local_dim(f, g, P, N):                # road one: dim of k[u, v] / (F, G, every term of degree N)
    mons = [(i, d - i) for d in range(N) for i in range(d, -1, -1)]
    idx, rows = {m: k for k, m in enumerate(mons)}, []
    for h in (shift(f, *P), shift(g, *P)):
        for a, b in mons:
            row = [0] * len(mons)
            for (i, j), c in h.items():
                if i + a + j + b < N: row[idx[(i + a, j + b)]] += c
            rows.append(row)
    return len(mons) - rank(rows)
def trim(p): return list(p)[:max((i + 1 for i, c in enumerate(p) if c != 0), default=0)]
def add1(p, q): return trim([(p[i] if i < len(p) else 0) + (q[i] if i < len(q) else 0) for i in range(max(len(p), len(q)))])
def mul1(p, q):
    r = [0] * (len(p) + len(q) - 1) if p and q else []
    for i, j in ((i, j) for i in range(len(p)) for j in range(len(q))): r[i + j] += p[i] * q[j]
    return trim(r)
def in_y(f):                              # coefficients of y^0, y^1, ... as polynomials in x
    n = max(j for _, j in f)
    return [trim([f.get((i, j), 0) for i in range(max(i for i, _ in f) + 1)]) for j in range(n + 1)]
def perms(n):
    if n == 1: return [([0], 1)]
    return [(p[:i] + [n - 1] + p[i:], s * (-1) ** (n - 1 - i)) for p, s in perms(n - 1) for i in range(n)]
def res_y(f, g):                          # road two: the Sylvester determinant in y, a polynomial in x
    F, G = in_y(f)[::-1], in_y(g)[::-1]
    m, n = len(F) - 1, len(G) - 1
    S = [[[]] * i + F + [[]] * (n - 1 - i) for i in range(n)] + [[[]] * i + G + [[]] * (m - 1 - i) for i in range(m)]
    tot = []
    for p, s in perms(len(S)):
        term = [s]
        for r in range(len(S)): term = mul1(term, S[r][p[r]])
        tot = add1(tot, term)
    return tot
def order_at(p, a):                       # how many times x - a divides p
    k = 0
    while p:
        q, s = [], 0
        for c in reversed(p): s = s * a + c; q.append(s)
        if q[-1] != 0: return k
        p, k = q[-2::-1], k + 1
    return "infinite"
def along(f, P, d):                       # road three: f(P + t d), lowest power of t
    h = shift(f, *P)
    co = [sum(c * d[0] ** i * d[1] ** j for (i, j), c in h.items() if i + j == k) for k in range(5)]
    return next(k for k, c in enumerate(co) if c != 0), co
def show(p, v="x"):
    t = [(c, k) for k, c in enumerate(p) if c][::-1]
    s = " ".join(f"{'-' if c < 0 else '+'} {'' if abs(c) == 1 and k else abs(c)}{v if k else ''}{'^' + str(k) if k > 1 else ''}" for c, k in t)
    return (s[2:] if s.startswith("+") else "-" + s[2:]) if t else "0"

C = {(2, 0): 1, (0, 2): 1, (0, 0): -25}                 # the pipe: x^2 + y^2 = 25 (cm)
T = {(1, 0): 3, (0, 1): 4, (0, 0): -25}                 # the beam: 3x + 4y = 25, touching at (3, 4)
P = (3, 4)
print("pipe x^2 + y^2 = 25; beam 3x + 4y = 25; gradient of the pipe at P: (6, 8), beam normal (3, 4)")
print("local road at P, N = 1..5:", [local_dim(C, T, P, N) for N in range(1, 6)])
R = res_y(C, T)
print(f"resultant road: Res_y = {show(R)}, root x = 3 of order {order_at(R, 3)}")
print(f"line road: pipe along (3 + 4t, 4 - 3t) = {show(along(C, P, (4, -3))[1], 't')}, order {along(C, P, (4, -3))[0]}")
radial = {(1, 0): 4, (0, 1): -3}                          # the radius line 4x = 3y through P
print(f"radius line 4x - 3y = 0 at P: local {local_dim(C, radial, P, 5)}, along (3 + 3t, 4 + 4t) = "
      f"{show(along(C, P, (3, 4))[1], 't')}, order {along(C, P, (3, 4))[0]}")
tot = []
for c, name in ((24, "secant"), (25, "tangent"), (30, "miss")):
    L = {(1, 0): 3, (0, 1): 4, (0, 0): -c}
    R = res_y(C, L)
    disc = R[1] ** 2 - 4 * R[2] * R[0]
    print(f"beam 3x + 4y = {c} ({name}): Res_y = {show(R)}, discriminant {disc}")
    tot.append((c, R, disc))
pts = [(Q(4), Q(3)), (Q(44, 25), Q(117, 25))]
L24 = {(1, 0): 3, (0, 1): 4, (0, 0): -24}
print("secant points:", ", ".join(f"({a}, {b}) local {local_dim(C, L24, (a, b), 4)}" for a, b in pts))
print(f"miss: x = 18/5 +- {sqrt(17600) / 50:.4f} i, two complex points, none real")
for s in (Q(1, 5), Q(1, 100), Q(1, 10000)):
    ch = 2 * sqrt(10 * s - s * s)
    print(f"beam moved {float(s):.4f} cm in: chord {ch:.4f} cm, chord / sqrt(move) {ch / sqrt(s):.4f}")
print(f"square-root law: 2 sqrt(10) = {2 * sqrt(10):.4f}")
D = {(2, 0): 1, (1, 0): -12, (0, 2): 1, (0, 1): -16, (0, 0): 75}  # pipe of radius 5 centred at (6, 8)
RD = res_y(C, D)
print(f"two pipes, centres (0, 0) and (6, 8): local {[local_dim(C, D, P, N) for N in range(1, 5)]}, "
      f"Res_y = {show(RD)}, order {order_at(RD, 3)}")
same = all(D.get(k, 0) - C.get(k, 0) == -4 * T.get(k, 0) for k in set(D) | set(C) | set(T))
print(f"second pipe minus first = -4 x beam: {'yes' if same else 'no'}; plane total 2, Bezout 2 x 2 = 4")
Nd = {(0, 2): 1, (3, 0): -1, (2, 0): -1}                # house example: y^2 = x^2 (x + 1), node at O
for k in (2, 1):
    L = {(0, 1): 1, (1, 0): -k}
    R = res_y(Nd, L)
    print(f"nodal cubic and y = {k if k > 1 else ''}x: local at O {local_dim(Nd, L, (0, 0), 5)}, "
          f"Res_y = {show(R)}, order at 0: {order_at(R, 0)}, at 3: {order_at(R, 3)}")
V = {(1, 0): 1, (0, 0): -3}                             # mistake: a vertical beam x = 3
RV = res_y(C, V)
print(f"mistake, vertical beam x = 3: Res_y = {show(RV)}, order {order_at(RV, 3)}; "
      f"local at (3, 4) {local_dim(C, V, (3, 4), 4)}, at (3, -4) {local_dim(C, V, (3, -4), 4)}")
CT = mul2(C, T)                                         # mistake: a shared piece
print(f"mistake, pipe against pipe x beam: Res_y = {show(res_y(C, CT))}, local N = 1..5: "
      f"{[local_dim(C, CT, P, N) for N in range(1, 6)]}")
print("mistake, distinct real points: secant 2, tangent 1, miss 0; with multiplicity over C: 2, 2, 2")
s6, X5, cub = Q(1, 10 ** 6), {(1, 0): 1, (0, 0): -5}, {(0, 1): 1, (3, 0): -1}   # the four "try changing" answers
print(f"try: y = x^3 against y = 0 at O, N = 1..5: {[local_dim(cub, {(0, 1): 1}, (0, 0), N) for N in range(1, 6)]}; "
      f"beam x = 5: local {local_dim(C, X5, (5, 0), 5)}, Res_y = {show(res_y(C, X5))}; node with y = -x: "
      f"{local_dim(Nd, {(0, 1): 1, (1, 0): 1}, (0, 0), 5)}, with y = 0: {local_dim(Nd, {(0, 1): 1}, (0, 0), 5)}; "
      f"move 0.000001 cm: chord {2 * sqrt(10 * s6 - s6 * s6):.4f} cm, ratio {2 * sqrt(10 * s6 - s6 * s6) / sqrt(s6):.4f}")
print("figure, pipe r 5 centre (0, 0), tangent 3x + 4y = 25 at (3, 4), secant 3x + 4y = 24 at (4, 3) and (1.76, 4.68)")
assert [local_dim(C, T, P, N) for N in range(2, 6)] == [2] * 4                 # local ring gives 2
assert res_y(C, T) == [225, -150, 25] and order_at(res_y(C, T), 3) == 2        # resultant gives 2
assert along(C, P, (4, -3))[1][:3] == [0, 0, 25]                               # the line gives 2
assert local_dim(C, radial, P, 5) == 1 == along(C, P, (3, 4))[0]
assert [t[2] for t in tot] == [3136, 0, -17600] and order_at(tot[0][1], 4) == 1
assert all(a * a + b * b == 25 and 3 * a + 4 * b == 24 for a, b in pts)
assert local_dim(C, D, P, 4) == order_at(RD, 3) == 2 and order_at(RV, 3) == 2 and same
assert local_dim(Nd, {(0, 1): 1, (1, 0): -1}, (0, 0), 5) == 3 and res_y(C, CT) == []
s = Q(1, 5)                                             # chord formula against the two secant points
assert (pts[0][0] - pts[1][0]) ** 2 + (pts[0][1] - pts[1][1]) ** 2 == 4 * (10 * s - s * s)
print("ALL CHECKS PASS")
