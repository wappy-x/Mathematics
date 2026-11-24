# Poincare duality and the cap product -- the check behind the card.  Standard library only.
# Homology and cohomology come from integer boundary matrices by a hand-written Smith
# normal form.  The torus's fundamental class is found by trying every sign; capping
# with it turns each measurement into a loop.  RP^n is checked in every dimension to 6.
from itertools import combinations

def snf(M):                          # diagonal of a Smith-style reduction: the nonzero factors
    A, out = [r[:] for r in M if any(r)], []
    while A and any(any(r) for r in A):
        i, j = min(((i, j) for i, r in enumerate(A) for j, x in enumerate(r) if x), key=lambda q: abs(A[q[0]][q[1]]))
        A[0], A[i] = A[i], A[0]
        A = [[r[j]] + r[1:j] + [r[0]] + r[j + 1:] if j else r for r in A]
        for r in A[1:]:              # clear below the smallest entry, then to its right
            q = r[0] // A[0][0]
            r[:] = [x - q * y for x, y in zip(r, A[0])]
        for c in range(1, len(A[0])):
            q = A[0][c] // A[0][0]
            A = [r[:c] + [r[c] - q * r[0]] + r[c + 1:] for r in A]
        if not any(r[0] for r in A[1:]) and not any(A[0][1:]):
            out, A = out + [abs(A[0][0])], [r[1:] for r in A[1:]]
    return out
side = lambda M, n: [[r[j] for r in M] for j in range(n)]          # transpose; n = columns of M
name = lambda free, tors: " + ".join((["Z" if free == 1 else f"Z^{free}"] if free else []) + [f"Z/{t}" for t in tors]) or "0"
def groups(ns, ds):                  # ds[k-1] is d_k: rows n_(k-1), columns n_k
    n, d = len(ns) - 1, [[]] + ds + [[]]
    f = [snf(m) for m in d]                                         # factors of each d_k
    g = [[]] + [snf(side(d[k], ns[k])) for k in range(1, n + 1)] + [[]]   # of each transpose
    H = [name(ns[k] - len(f[k]) - len(f[k + 1]), [x for x in f[k + 1] if x > 1]) for k in range(n + 1)]
    C = [name(ns[k] - len(g[k + 1]) - len(g[k]), [x for x in g[k] if x > 1]) for k in range(n + 1)]
    m2 = [ns[k] - sum(x % 2 for x in f[k]) - sum(x % 2 for x in f[k + 1]) for k in range(n + 1)]
    return H, C, m2, sum((-1) ** k * (ns[k] - len(f[k]) - len(f[k + 1])) for k in range(n + 1))
def closure(tris):                   # joints, struts, panels; vertices in increasing order
    return [sorted({c for t in tris for c in combinations(sorted(t), k)}) for k in (1, 2, 3)]
def bd(K, k):                        # signed boundary d_k of a simplicial complex
    row, M = {s: i for i, s in enumerate(K[k - 1])}, [[0] * len(K[k]) for _ in K[k - 1]]
    for j, s in enumerate(K[k]):
        for i in range(len(s)):
            M[row[s[:i] + s[i + 1:]]][j] = (-1) ** i
    return M
def top_cycles(K, mod2):             # every sign (or every subset) of the panels, in Gray-code order
    cols = [[(i, r[j]) for i, r in enumerate(bd(K, 2)) if r[j]] for j in range(len(K[2]))]
    s, B = [1] * len(cols), [sum(r) % 2 if mod2 else sum(r) for r in bd(K, 2)]
    bad, found, count = sum(map(bool, B)), None, 0
    for step in range(1, 2 ** len(cols) + 1):
        if bad == 0:
            count, found = count + 1, (list(s) if s[0] == 1 else found)
        j = (step & -step).bit_length() - 1
        if j == len(cols):
            return count, found
        s[j] = -s[j]
        for i, v in cols[j]:
            bad -= bool(B[i])
            B[i] = (B[i] + 1) % 2 if mod2 else B[i] + 2 * s[j] * v
            bad += bool(B[i])
def local(K, v):                     # rank of H_2(star of v, its rim): the local group at joint v
    tris = [K[2].index(t) for t in K[2] if v in t]
    return len(tris) - len(snf([[r[t] for t in tris] for r, e in zip(bd(K, 2), K[1]) if v in e]))
sq = lambda i, j: 3 * (i % 3) + j % 3                               # the 3 x 3 torus grid, anticlockwise
grid = [t for i in range(3) for j in range(3) for t in
        [(sq(i, j), sq(i + 1, j), sq(i + 1, j + 1)), (sq(i, j), sq(i + 1, j + 1), sq(i, j + 1))]]
rp2 = [(0, 1, 2), (0, 2, 3), (0, 3, 4), (0, 4, 5), (0, 1, 5), (1, 2, 4), (2, 3, 5), (1, 3, 4), (2, 4, 5), (1, 3, 5)]
tor, holed, prp = closure(grid), closure(grid[1:]), closure(rp2)
cnt = lambda K: [len(x) for x in K]
print("simplicial: space | V E F | H_0 H_1 H_2 | H^0 H^1 H^2 | Betti mod 2 | +-1 top cycles of 2^F sign choices | nonzero mod-2 ones")
res = {}
for nm, K in [("torus", tor), ("torus, one panel out", holed), ("RP2", prp)]:
    res[nm] = groups(cnt(K), [bd(K, 1), bd(K, 2)]) + (top_cycles(K, False), top_cycles(K, True)[0] - 1)
    H, C, m2, _, (z, _), z2 = res[nm]
    print(f"{nm} | {' '.join(map(str, cnt(K)))} | {', '.join(H)} | {', '.join(C)} | {m2} | {z} | {z2}")
loc = [[local(K, v) for v in range(len(K[0]))] for K in (tor, prp, holed)]
print(f"local group rank at each joint: torus {loc[0]}, RP2 {loc[1]}, one panel out {loc[2]}")
par = lambda t: (-1) ** sum(t[a] > t[b] for a, b in combinations(range(3), 2))
T = lst = [{tuple(sorted(t)): par(t) for t in grid}[s] for s in tor[2]]   # [M]: signs of the anticlockwise listing
print(f"torus: the search's cycle, panel {tor[2][0]} positive, is {res['torus'][4][1][0] * lst[0]} x the anticlockwise listing: {res['torus'][4][1] == [res['torus'][4][1][0] * lst[0] * x for x in lst]}")

E, P = {e: i for i, e in enumerate(tor[1])}, {t: i for i, t in enumerate(tor[2])}
def cap(phi, k):                     # T cap phi: phi on each panel's front k-face, times its back face
    out = [0] * len(tor[2 - k])
    for t, (u, v, w) in zip(T, tor[2]):
        i, x = (P[(u, v, w)], phi[u]) if k == 0 else (E[(v, w)], phi[E[(u, v)]]) if k == 1 else (w, phi[P[(u, v, w)]])
        out[i] += t * x
    return out
cup = lambda x, y: [x[E[(u, v)]] * y[E[(v, w)]] for u, v, w in tor[2]]
pair = lambda c, z: sum(p * q for p, q in zip(c, z))
mul = lambda M, x: [pair(r, x) for r in M]
unit = lambda n, i: [int(j == i) for j in range(n)]
d1, d2 = bd(tor, 1), bd(tor, 2)
ok_pair = all(pair(unit(27, j), cap(unit(27, i), 1)) == pair(cup(unit(27, i), unit(27, j)), T) for i in range(27) for j in range(27))
ok_b1 = all(mul(d1, cap(unit(27, i), 1)) == cap(mul(side(d2, 18), unit(27, i)), 2) for i in range(27))
ok_b0 = all(mul(d2, cap(unit(9, i), 0)) == [-x for x in cap(mul(side(d1, 27), unit(9, i)), 1)] for i in range(9))
print(f"<psi, T cap phi> = <phi cup psi, T> on all 27 x 27 basis pairs: {ok_pair}")
print(f"d(T cap phi) = T cap (delta phi) on all 27 basis 1-cochains: {ok_b1}; d(T cap f) = -T cap (delta f) on all 9 joints: {ok_b0}")
seam = lambda key: [{2: -1, -2: 1}.get(key(v) - key(u), 0) for u, v in tor[1]]
a, b = seam(lambda s: s // 3), seam(lambda s: s % 3)               # +1 or -1 on struts over a seam
loopA = [{(0, 3): 1, (3, 6): 1, (0, 6): -1}.get(e, 0) for e in tor[1]]
loopB = [{(0, 1): 1, (1, 2): 1, (0, 2): -1}.get(e, 0) for e in tor[1]]
Da, Db = cap(a, 1), cap(b, 1)
coord = lambda z: [pair(a, z), pair(b, z)]                          # a, b read 1 on loops A, B
same = lambda z, l, s: len(snf(d2)) == len(snf([r + [x - s * y] for r, x, y in zip(d2, z, l)]))
D = [coord(Da), coord(Db)]
det = D[0][0] * D[1][1] - D[0][1] * D[1][0]
print(f"a, b read on loops A, B: {[coord(loopA), coord(loopB)]}; D(a) = T cap a: {[tor[1][i] for i, x in enumerate(Da) if x]}, values {[x for x in Da if x]}")
print(f"D(a) boundary zero: {not any(mul(d1, Da))}; D(a) reads {D[0]}, D(b) reads {D[1]}; D(a) - loop B a boundary: {same(Da, loopB, 1)}; D(b) + loop A a boundary: {same(Db, loopA, -1)}")
print(f"duality matrix H^1 -> H_1 {D}, det {det}; D(1) = T: {cap([1] * 9, 0) == T}; D(1 on panel {tor[2][0]}) = {cap(unit(18, 0), 2)}")

e2 = {e: i for i, e in enumerate(prp[1])}                           # RP2 mod 2: every 1-cochain
cob = {tuple(pair(r, [x >> i & 1 for i in range(6)]) % 2 for r in side(bd(prp, 1), 15)) for x in range(64)}
cocyc, good = 0, 0
for x in range(2 ** 15):
    c = [x >> i & 1 for i in range(15)]
    if not any((c[e2[(u, v)]] + c[e2[(v, w)]] + c[e2[(u, w)]]) % 2 for u, v, w in prp[2]):
        cocyc += 1
        good += sum(c[e2[(u, v)]] * c[e2[(v, w)]] for u, v, w in prp[2]) % 2 == (tuple(c) not in cob)
print(f"RP2 mod 2, all 2^15 = {2 ** 15} strut measurements: {cocyc} cocycles, {len(cob)} coboundaries; x cup x reads 1 on the whole surface exactly off the coboundaries: {good} of {cocyc}")
print("cellular RP^n: n | H_0..H_n | H^0..H^n | duality over Z | Betti mod 2 | Euler characteristic")
rp = {}
for n in range(1, 7):
    rp[n] = groups([1] * (n + 1), [[[0 if k % 2 else 2]] for k in range(1, n + 1)])
    H, C, m2, chi = rp[n]
    print(f"{n} | {', '.join(H)} | {', '.join(C)} | {'holds' if all(C[k] == H[n - k] for k in range(n + 1)) else 'fails'} | {m2} | {chi}")
ucf = lambda Hs, k: name(int(Hs[k] == "Z"), [2] if k and Hs[k - 1] == "Z/2" else [])   # H^k = free part of H_k + torsion of H_(k-1)
uc = [ucf(rp[3][0], k) for k in range(4)]
print(f"RP3: cohomology from homology by universal coefficients {', '.join(uc)}; cells 1 - 1 + 1 - 1 = 0")
fill = ["Z", "Z/2"] + [ucf(["Z", "Z/2"], k) for k in (1, 0)]      # duality fills in a closed oriented 3-manifold: H_(3-k) = H^k
cofill = [ucf(fill, k) for k in (0, 1)] + [fill[1], fill[0]]        # and H^(3-k) = H_k
print(f"duality fill-in from H_0 = Z, H_1 = Z/2 alone: H_2 = H^1 = {fill[2]}, H_3 = H^0 = {fill[3]}; homology {', '.join(fill)}; cohomology {', '.join(cofill)}; cells agree: {(fill, cofill) == rp[3][:2]}")
print(f"mistake 1, RP2 over Z: H^2 = {rp[2][1][2]} but H_0 = {rp[2][0][0]}")
print(f"mistake 2, one panel out: H^2 = {res['torus, one panel out'][1][2]} but H_0 = {res['torus, one panel out'][0][0]}; +-1 top cycles {res['torus, one panel out'][4][0]}")
print(f"mistake 3, RP3 read forwards: H^1 = {rp[3][1][1]} but H_1 = {rp[3][0][1]}")

assert res["torus"][:2] == (["Z", "Z^2", "Z"], ["Z", "Z^2", "Z"]) and res["torus"][4][0] == 2
assert res["RP2"][:3] == (["Z", "Z/2", "0"], ["Z", "0", "Z/2"], [1, 1, 1]) and res["RP2"][4][0] == 0 and res["RP2"][5] == 1
assert res["torus, one panel out"][4][0] == 0 and loc[0] == [1] * 9 and loc[1] == [1] * 6 and loc[2].count(0) == 3
assert res["torus"][4][1] in (lst, [-x for x in lst])               # search and listing agree
assert ok_pair and ok_b1 and ok_b0 and not any(mul(d1, Da)) and same(Da, loopB, 1) and same(Db, loopA, -1)
assert abs(det) == 1 and [coord(loopA), coord(loopB)] == [[1, 0], [0, 1]]
assert cocyc == 64 and len(cob) == 32 and good == 64
assert rp[3][:2] == (["Z", "Z/2", "0", "Z"], ["Z", "0", "Z/2", "Z"]) and uc == rp[3][1] and (fill, cofill) == rp[3][:2]
assert all((rp[n][1] == rp[n][0][::-1]) == (n % 2 == 1) and rp[n][2] == [1] * (n + 1) and rp[n][3] == (n + 1) % 2 for n in rp)
print("ALL CHECKS PASS")
