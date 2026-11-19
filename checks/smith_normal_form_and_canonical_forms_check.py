# Smith normal form and canonical forms -- the check behind the card.  Nothing is imported.
# One routine diagonalises over Z (a 12-cell supercell N -> 1, 2, 6) and over Q[x] (x I - A ->
# A's invariant factors and rational canonical form), with moves the ring can undo.  Other roads:
# gcds of minors; orders by brute force; kernel sizes and minimal polynomials; A P = P C multiplied out.
class P:                                   # a polynomial, integer coefficients, lowest first
    def __init__(s, c):
        s.c = list(c)
        while s.c and s.c[-1] == 0: s.c.pop()
    def __add__(s, o): n = max(len(s.c), len(o.c)); return P((s.c + [0] * n)[i] + (o.c + [0] * n)[i] for i in range(n))
    def __mul__(s, o):
        if isinstance(o, int): return P(o * x for x in s.c)
        r = [0] * (len(s.c) + len(o.c))
        for i, x in enumerate(s.c):
            for j, y in enumerate(o.c): r[i + j] += x * y
        return P(r)
    __rmul__ = __mul__
    def __sub__(s, o): return s + o * -1
    def __eq__(s, o): return s.c == o.c
    def __bool__(s): return bool(s.c)
    def __repr__(s):
        out = ""
        for k in range(len(s.c) - 1, -1, -1):
            a = s.c[k]
            if a:
                w = (str(abs(a)) if abs(a) != 1 or k == 0 else "") + ("x" if k else "") + (f"^{k}" if k > 1 else "")
                out += (" - " if a < 0 else " + ") + w if out else ("-" if a < 0 else "") + w
        return out or "0"
X = P([0, 1])
def zdiv(a, p): return 1, (a - a % abs(p)) // p              # unit u, quotient q: |a - q p| < |p|
def pdiv(a, p):                                              # pseudo-division: u is a constant, a unit of Q[x]
    c, r, q = p.c[-1], a, P([])
    u = c ** max(len(a.c) - len(p.c) + 1, 0); r = r * u
    while r and len(r.c) >= len(p.c):
        m = P([0] * (len(r.c) - len(p.c)) + [r.c[-1] // c]); q, r = q + m, r - m * p
    return u, q
ZR = (abs, zdiv, lambda a: -1 if a < 0 else 1, 1)            # size, divide, sign fix, one
QX = (lambda a: len(a.c), pdiv, lambda a: -1 if a.c[-1] < 0 else 1, P([1]))
def show(M): return "[" + ", ".join("[" + ", ".join(map(str, r)) + "]" for r in M) + "]"
def smith(M, ring, log=None):                                # returns S, D, T with S M T = D
    size, div, fix, one = ring
    m, n, D = len(M), len(M[0]), [r[:] for r in M]
    S = [[one if i == j else one - one for j in range(m)] for i in range(m)]
    T = [[one if i == j else one - one for j in range(n)] for i in range(n)]
    def note(w):
        if log is not None: log.append(f"{w} -> {show(D)}")
    def row(i, k, u, q):                                     # row i := u row i - q row k
        for A in (D, S): A[i] = [u * x - q * y for x, y in zip(A[i], A[k])]
    def col(j, k, u, q):
        for A in (D, T):
            for r in A: r[j] = u * r[j] - q * r[k]
    t = 0
    while t < min(m, n):
        live = [(size(D[i][j]), i, j) for i in range(t, m) for j in range(t, n) if D[i][j]]
        if not live: break
        _, i, j = min(live)
        if i != t: D[t], D[i], S[t], S[i] = D[i], D[t], S[i], S[t]; note(f"swap rows {t + 1}, {i + 1}")
        if j != t:
            for r in D + T: r[t], r[j] = r[j], r[t]
            note(f"swap columns {t + 1}, {j + 1}")
        for i in range(t + 1, m):
            if D[i][t]: u, q = div(D[i][t], D[t][t]); row(i, t, u, q); note(f"row {i + 1} := {u} row {i + 1} - ({q}) row {t + 1}")
        for j in range(t + 1, n):
            if D[t][j]: u, q = div(D[t][j], D[t][t]); col(j, t, u, q); note(f"col {j + 1} := {u} col {j + 1} - ({q}) col {t + 1}")
        if any(D[i][t] for i in range(t + 1, m)) or any(D[t][t + 1:]): continue
        bad = [i for i in range(t + 1, m) if any(div(x, D[t][t])[0] * x - div(x, D[t][t])[1] * D[t][t] for x in D[i][t + 1:])]
        if bad: row(t, bad[0], 1, -1); note(f"row {t + 1} += row {bad[0] + 1}"); continue
        if fix(D[t][t]) < 0: row(t, t, -1, 0); note(f"row {t + 1} := -1 row {t + 1}")
        t += 1
    return S, D, T
def mul(A, B): return [[sum((a * b for a, b in zip(r, c)), start=r[0] * 0) for c in zip(*B)] for r in A]
def det(M): return M[0][0] if len(M) == 1 else sum(((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M))), start=M[0][0] * 0)
def subsets(N, k): return [[]] if k == 0 else [s + [x] for x in range(N) for s in subsets(x, k - 1)]
def minors(M, k): return [det([[M[r][c] for c in cs] for r in rs]) for rs in subsets(len(M), k) for cs in subsets(len(M[0]), k)]
def gcd(a, b, ring):
    while b: u, q = ring[1](a, b); a, b = b, u * a - q * b
    return a
def gcdl(L, ring): return L[0] if len(L) == 1 else gcd(L[0], gcdl(L[1:], ring), ring)
def prim(f): g = abs(gcdl(f.c, ZR)) * (1 if f.c[-1] > 0 else -1); return P([x // g for x in f.c])   # content out, lc > 0
def gk(M, k, ring, norm): return norm(gcdl(minors(M, k), ring))
N = [[1, 0, 2], [0, 2, 2], [2, 2, 0]]                        # supercell edges, as columns, in unit-cell steps
print(f"supercell N = {N}, det {det(N)}: {abs(det(N))} unit cells")
log = []; S, D, T = smith(N, ZR, log)
print("\n".join("Z  " + w for w in log))
d = [D[k][k] for k in range(3)]
print(f"S = {S}, det {det(S)}; T = {T}, det {det(T)}; S N T = {mul(mul(S, N), T)}")
g = [gk(N, k, ZR, abs) for k in (1, 2, 3)]
print(f"road 2, gcd of k-by-k minors: g = {g}; d = {[g[0], g[1] // g[0], g[2] // g[1]]}")
adj = [[(-1) ** (i + j) * det([r[:i] + r[i + 1:] for k, r in enumerate(N) if k != j]) for j in range(3)] for i in range(3)]
inL = lambda v: all(sum(a * x for a, x in zip(r, v)) % 12 == 0 for r in adj)   # v in the lattice of N?
order = lambda v: next(k for k in range(1, 13) if inL([k * x for x in v]))
box = [order((a, b, c)) for a in range(12) for b in range(12) for c in range(12)]
tally = lambda L: {k: L.count(k) for k in sorted(set(L))}
hist = {k: c // 144 for k, c in tally(box).items()}            # each class meets the box 12^3 / 12 = 144 times
def tuples(ds): return [[]] if not ds else [[a] + t for a in range(ds[0]) for t in tuples(ds[1:])]
def ghist(ds): return tally([next(k for k in range(1, 13) if all(k * a % e == 0 for a, e in zip(t, ds))) for t in tuples(ds)])
print(f"road 3, orders of the 12 classes by brute force: {hist}; Z/2 + Z/6 predicts {ghist([2, 6])}; Z/12 has {ghist([12])}")
print(f"orders of e1, e2, e3: {order((1, 0, 0))}, {order((0, 1, 0))}, {order((0, 0, 1))}")
A = [[2, 0, 0], [0, 2, 1], [0, 0, 3]]; B = [[2, 1, 0], [0, 2, 1], [0, 0, 3]]
sub = lambda M, L: [[M[i][j] - L * (i == j) for j in range(3)] for i in range(3)]
rank = lambda M: max(k for k in range(4) if k == 0 or any(minors(M, k)))
xI = lambda M: [[X * int(i == j) - P([M[i][j]]) for j in range(3)] for i in range(3)]
res = {}
for name, M in (("A", A), ("B", B)):
    log = []; D2 = smith(xI(M), QX, log)[1]
    if name == "A": print("\n".join("Q[x] " + w for w in log))
    f = [prim(D2[k][k]) for k in range(3)]
    g2 = [gk(xI(M), k, QX, prim) for k in (1, 2, 3)]
    lam = [3 - rank(sub(M, L)) for L in (2, 3)]                # kernel size = factors divisible by x - L
    C, at = [[0] * 3 for _ in range(3)], 0
    for h in [h for h in f if len(h.c) > 1]:
        n = len(h.c) - 1
        for i in range(n): C[at + i][at + n - 1] = -h.c[i]; C[at + i][at + i - 1] += int(i > 0)
        at += n
    res[name] = (f, g2, lam, C)
    print(f"{name} = {M}: invariant factors {f}, product {f[0] * f[1] * f[2]}; gcd of k-by-k minors of x I - {name}: {g2}")
    print(f"{name}: kernel sizes of {name} - 2I, {name} - 3I: {lam}; rational canonical form C = {C}")
mA, mB = mul(sub(A, 2), sub(A, 3)), mul(sub(B, 2), sub(B, 3))
print(f"minimal polynomial test (M - 2I)(M - 3I): A gives {mA}; B gives {mB}; (B - 2I)^2 (B - 3I) = {mul(sub(B, 2), mB)}")
PA, PB = [[0, 1, 2], [1, 1, 3], [0, 1, 3]], [[0, 0, 1], [0, 1, 5], [1, 3, 9]]   # columns: e2, w, Aw and e3, Be3, B^2 e3
print(f"P_A = {PA}, det {det(PA)}; A P_A = {mul(A, PA)} = P_A C_A = {mul(PA, res['A'][3])}")
print(f"P_B = {PB}, det {det(PB)}; B P_B = {mul(B, PB)} = P_B C_B = {mul(PB, res['B'][3])}")
B5 = mul(mul(mul(mul(B, B), B), B), B)
print(f"B^5 row 1 = {B5[0]}: middle entry 5 x 2^4 = {5 * 2 ** 4}; A^5 row 1 = {mul(mul(mul(mul(A, A), A), A), A)[0]}")
print(f"mistake 1, Smith over Q: N has rank {rank(N)}, diagonal {[1] * rank(N)}, quotient Q^3 / Q^{rank(N)} = {'0' if rank(N) == 3 else f'Q^{3 - rank(N)}'}; the 12 cells' Z/2 + Z/6 is lost")
print(f"mistake 2, det 12 read as Z/12: needs an order-12 class, brute force finds largest order {max(hist)}")
print(f"mistake 3, same char poly read as similar: A, B both {res['A'][1][2]}, kernel sizes {res['A'][2][0]} and {res['B'][2][0]}")
box3 = smith([[2, 0, 0], [0, 2, 0], [0, 0, 3]], ZR)[1]
print(f"mistake 4, chain dropped: 2 x 2 x 3 box reads (2, 2, 3), N reads (1, 2, 6); Smith gives {[box3[k][k] for k in range(3)]} and {d}")
assert mul(mul(S, N), T) == D and abs(det(S)) == 1 == abs(det(T))                   # substitution
assert g == [d[0], d[0] * d[1], d[0] * d[1] * d[2]]                               # road 1 = road 2
assert hist == ghist(d[1:]) != ghist([12])                                       # road 3, brute force
assert rank(N) == len([x for x in d if x])                                       # rank over Q by minors = nonzero Smith entries
assert res["A"][0] == [P([1]), X - P([2]), (X - P([2])) * (X - P([3]))] and res["B"][0][1] == P([1]) and d == [1, 2, 6]
for f, g2, lam, C in res.values():
    assert g2 == [f[0], prim(f[0] * f[1]), prim(f[0] * f[1] * f[2])]           # minors meet the moves
    assert lam == [sum(1 for h in f if sum(c * L ** k for k, c in enumerate(h.c)) == 0) for L in (2, 3)]   # roots
assert mul(A, PA) == mul(PA, res["A"][3]) and mul(B, PB) == mul(PB, res["B"][3]) and det(PA) * det(PB) != 0
assert [box3[k][k] for k in range(3)] == d and mA == [[0] * 3] * 3 != mB and mul(sub(B, 2), mB) == [[0] * 3] * 3
print("ALL CHECKS PASS")
