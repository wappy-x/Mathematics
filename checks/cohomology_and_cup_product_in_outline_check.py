# Cohomology and the cup product -- the check behind the card.  Standard library only.
# A cochain is a number on each simplex; the coboundary is the boundary matrix turned
# on its side.  The torus and two circles joined to a sphere get the same Betti
# numbers; the cup product, paired with the top 2-cycle, tells them apart.
from itertools import combinations, product
from math import gcd

def rank(M, p=0):                    # exact elimination over Q (p = 0) or over Z mod p
    A, r = [row[:] for row in M], 0
    for c in range(len(A[0]) if A else 0):
        piv = next((i for i in range(r, len(A)) if (A[i][c] % p if p else A[i][c])), None)
        if piv is None:
            continue
        A[r], A[piv] = A[piv], A[r]
        for i in range(r + 1, len(A)):
            new = [A[r][c] * y - A[i][c] * x for x, y in zip(A[r], A[i])]
            g = gcd(*new) if not p else 0
            A[i] = [v % p for v in new] if p else [v // g for v in new] if g else new
        r += 1
    return r

def closure(tris, edges=()):         # every face of every simplex, vertices in increasing order
    K = [set(), set(), set()]
    for s in list(tris) + list(edges):
        s = tuple(sorted(s))
        for k in range(len(s)):
            K[k].update(combinations(s, k + 1))
    return [sorted(x) for x in K]

def bd(K, k):                        # boundary d_k: rows (k-1)-simplices, columns k-simplices
    row = {s: i for i, s in enumerate(K[k - 1])}
    M = [[0] * len(K[k]) for _ in K[k - 1]]
    for j, s in enumerate(K[k]):
        for i in range(len(s)):
            M[row[s[:i] + s[i + 1:]]][j] = (-1) ** i
    return M

side = lambda M, n: [list(c) for c in zip(*M)] if M and M[0] else [[] for _ in range(n)]  # n = columns of M
mul = lambda M, x: [sum(a * b for a, b in zip(row, x)) for row in M]
pair = lambda c, z: sum(a * b for a, b in zip(c, z))            # <cochain, chain>

def counts(K, p=0):                  # Betti numbers from d, and cohomology dims from delta
    n = [len(x) for x in K]
    r1, r2 = rank(bd(K, 1), p), rank(bd(K, 2), p)
    s0, s1 = rank(side(bd(K, 1), n[1]), p), rank(side(bd(K, 2), n[2]), p)
    return [n[0] - r1, n[1] - r1 - r2, n[2] - r2], [n[0] - s0, n[1] - s0 - s1, n[2] - s1]

def cup(K, x, y):                    # (x cup y)[u, v, w] = x[u, v] * y[v, w]
    e = {s: i for i, s in enumerate(K[1])}
    return [x[e[(u, v)]] * y[e[(v, w)]] for u, v, w in K[2]]

def grid(twist, drop=0):             # 3 x 3 squares, two panels each; twist glues one side flipped
    def v(i, j):
        if i == 3:
            i, j = 0, (-j if twist else j)
        return 3 * (i % 3) + j % 3
    tris = [t for i, j in product(range(3), repeat=2)
            for t in [(v(i, j), v(i + 1, j), v(i + 1, j + 1)), (v(i, j), v(i + 1, j + 1), v(i, j + 1))]]
    return tris[drop:]               # each panel listed anticlockwise in the square

sgn = lambda t: (-1) ** sum(t[a] > t[b] for a, b in combinations(range(3), 2))
names = ["torus", "two circles and a sphere", "Klein bottle", "torus, one panel out"]
tor = closure(grid(False))
wed = closure(combinations((0, 5, 6, 7), 3), [(0, 1), (1, 2), (0, 2), (0, 3), (3, 4), (0, 4)])
kle, holed = closure(grid(True)), closure(grid(False, 1))
print("figure, schematic: torus corner (i, j) at (40 + 60i, 230 - 60j); wedge joint 0 at (370,150)")
print("space: V E F | Betti over Q from d | cohomology dims over Q from delta | over Z mod 2")
B = {}
for nm, K in zip(names, [tor, wed, kle, holed]):
    b, h = counts(K)
    B[nm] = (b, h, counts(K, 2)[0])
    print(f"{nm}: {len(K[0])} {len(K[1])} {len(K[2])} | {b} | {h} | {B[nm][2]}")
    assert b == h                                     # cohomology counts the same holes
top = {tuple(sorted(t)): sgn(t) for t in grid(False)}
T = [top[s] for s in tor[2]]                          # the torus's top 2-cycle, signs +1/-1
S = [{(5, 6, 7): 1, (0, 6, 7): -1, (0, 5, 7): 1, (0, 5, 6): -1}[s] for s in wed[2]]
ktop = {tuple(sorted(t)): sgn(t) for t in grid(True)}
kbad = sum(v != 0 for v in mul(bd(kle, 2), [ktop[s] for s in kle[2]]))
nz = lambda v: sum(x != 0 for x in v)                # how many entries are not zero
print(f"top cycle, nonzero boundary entries: torus {nz(mul(bd(tor, 2), T))}, sphere "
      f"{nz(mul(bd(wed, 2), S))}, Klein bottle with the same signs {kbad} of 27")

seam = lambda key: [{2: -1, -2: 1}.get(key(v) - key(u), 0) for u, v in tor[1]]
a, b = seam(lambda s: s // 3), seam(lambda s: s % 3)  # +1 or -1 on edges that wrap over a seam
d0, d1 = side(bd(tor, 1), 27), side(bd(tor, 2), 18)  # delta^0 and delta^1
loops = [[{(0, 3): 1, (3, 6): 1, (0, 6): -1}.get(e, 0) for e in tor[1]],
         [{(0, 1): 1, (1, 2): 1, (0, 2): -1}.get(e, 0) for e in tor[1]]]
print(f"torus: a on {nz(a)} struts, b on {nz(b)}; nonzero entries of delta a {nz(mul(d1, a))}, of delta b {nz(mul(d1, b))}; "
      f"a, b on the two loops {[[pair(c, z) for z in loops] for c in (a, b)]}")
basis = rank([r + [x, y] for r, x, y in zip(d0, a, b)]) - rank(d0)
P = [[pair(cup(tor, x, y), T) for y in (a, b)] for x in (a, b)]
ab = cup(tor, a, b)
print(f"torus: a, b independent mod coboundaries: {basis} of 2; pairing <x cup y, T> = {P}")
hit = [(s, v) for s, v in zip(tor[2], ab) if v]
print(f"torus: a cup b nonzero on {len(hit)} of 18 panels: {" ".join(f"{u}{v}{w} value {x}" for (u, v, w), x in hit)}; rank delta^1 {rank(d1)}, "
      f"with a cup b added {rank([r + [v] for r, v in zip(d1, ab)])}")
bx = [x + (e == (1, 4)) for x, e in zip(b, tor[1])]  # b plus 1 on strut [1,4]: not a cocycle
same, leib, kept, bx0 = 0, 0, 0, pair(cup(tor, a, bx), T)
for f in product((-1, 0, 1), repeat=9):              # every a + delta f, f in {-1, 0, 1}^9
    df = mul(d0, f)
    same += pair(cup(tor, [x + y for x, y in zip(a, df)], b), T) == P[0][1]
    kept += pair(cup(tor, [x + y for x, y in zip(a, df)], bx), T) == bx0
    fb = [f[u] * b[i] for i, (u, v) in enumerate(tor[1])]          # (f cup b)[u, v] = f(u) b[u, v]
    leib += mul(d1, fb) == cup(tor, df, b)
print(f"torus: <(a + delta f) cup b, T> unchanged for {same} of 3^9 = {3 ** 9} choices of f; "
      f"Leibniz rule holds for {leib}")
print(f"torus, b plus 1 on strut [1,4]: delta of it nonzero on {nz(mul(d1, bx))} panels; reading unchanged for {kept} of {3 ** 9}")

c1 = [int(e == (1, 2)) for e in wed[1]]              # one strut on each hoop
c2 = [int(e == (3, 4)) for e in wed[1]]
w0, w1 = side(bd(wed, 1), 12), side(bd(wed, 2), 4)
c1m = [x + y for x, y in zip(c1, mul(w0, [int(v == 5) for v in range(8)]))]
c2m = [x + y for x, y in zip(c2, mul(w0, [int(v == 6) for v in range(8)]))]
W = [[pair(cup(wed, x, y), S) for y in (c1, c2)] for x in (c1, c2)]
cm = cup(wed, c1m, c2m)
print(f"wedge: nonzero entries of delta c1, c2: {nz(mul(w1, c1))}, {nz(mul(w1, c2))}; independent "
      f"{rank([r + [x, y] for r, x, y in zip(w0, c1, c2)]) - rank(w0)} of 2; pairing <x cup y, S> = {W}")
print(f"wedge, shifted copies: c1' cup c2' nonzero on {nz(cm)} of 4 panels, value {cm}; "
      f"<., S> = {pair(cm, S)}; rank delta^1 {rank(w1)}, with it added {rank([r + [v] for r, v in zip(w1, cm)])}")

pm = lambda p, q: [sum(p[i] * q[k - i] for i in range(len(p)) if 0 <= k - i < len(q)) for k in range(len(p) + len(q) - 1)]
print(f"Kunneth over Q: (1 + t)(1 + t) = {pm([1, 1], [1, 1])}; three circles {pm(pm([1, 1], [1, 1]), [1, 1])}")
det = P[0][0] * P[1][1] - P[0][1] * P[1][0]
print(f"duality: torus pairing det {det}; wedge pairing det {W[0][0] * W[1][1] - W[0][1] * W[1][0]}")
print(f"mistake 1, Betti numbers only: torus {B['torus'][0]} = wedge {B['two circles and a sphere'][0]}, chi 0 = 0")
print(f"mistake 2, order of factors: <b cup a, T> = {P[1][0]}, not {P[0][1]}")
print(f"mistake 3, Klein bottle over Q: {B['Klein bottle'][0]}, b0 = 1 but b2 = 0; over Z mod 2 {B['Klein bottle'][2]}")
print(f"mistake 4, a panel out: {B['torus, one panel out'][0]}, b0 = 1 but b2 = 0")

assert B["torus"][0] == B["two circles and a sphere"][0] == [1, 2, 1] == pm([1, 1], [1, 1])
assert not any(mul(bd(tor, 2), T)) and not any(mul(bd(wed, 2), S)) and kbad > 0
assert basis == 2 and [[pair(c, z) for z in loops] for c in (a, b)] == [[1, 0], [0, 1]]
assert abs(det) == 1 and P[0][0] == P[1][1] == 0 and P[0][1] == -P[1][0]
assert rank([r + [v] for r, v in zip(d1, ab)]) == rank(d1) + 1                 # a cup b is no coboundary
assert same == leib == 3 ** 9 and kept == 3 ** 8 and any(mul(d1, bx)) and W == [[0, 0], [0, 0]] and any(cm) and pair(cm, S) == 0
assert rank([r + [v] for r, v in zip(w1, cm)]) == rank(w1)                      # c1' cup c2' is one
assert B["Klein bottle"][0] == [1, 1, 0] and B["Klein bottle"][2] == [1, 2, 1]
assert B["torus, one panel out"][0] == [1, 2, 0]
print("ALL CHECKS PASS")
