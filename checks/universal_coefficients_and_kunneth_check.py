# Universal coefficients and Kunneth on the projective plane RP2 and on RP2 x RP2.
# Road 1: the formulas, from integer homology through tensor, Tor and Ext of cyclic groups.
# Road 2: direct computation on the chain complexes (Smith form over Z, elimination mod p),
# on two models of RP2 (one cell per dimension, and 10 triangles) and on the product complex.
from itertools import combinations
from math import gcd

def normal(ds):  # orders of cyclic pieces -> invariant factors, each dividing the next
    ds = sorted(ds)
    for i in range(len(ds)):
        for j in range(i + 1, len(ds)):
            g = gcd(ds[i], ds[j]); ds[i], ds[j] = g, ds[i] * ds[j] // g
    return [x for x in ds if x > 1]

def smith(m):  # nonzero diagonal of the Smith form, by whole-number row and column moves
    a, ds = [r[:] for r in m], []
    while True:
        nz = [(abs(x), i, j) for i, r in enumerate(a) for j, x in enumerate(r) if x]
        if not nz: return len(ds), normal(ds)
        _, i, j = min(nz); p, clean = a[i][j], True
        for k in range(len(a)):
            if k != i and a[k][j]:
                q = a[k][j] // p; a[k] = [x - q * y for x, y in zip(a[k], a[i])]; clean &= a[k][j] == 0
        for k in range(len(a[0])):
            if k != j and a[i][k]:
                q = a[i][k] // p
                for r in a: r[k] -= q * r[j]
                clean &= a[i][k] == 0
        if clean: ds.append(abs(p)); a = [r[:j] + r[j + 1:] for k, r in enumerate(a) if k != i]

def rank_p(m, p):  # rank over the integers mod a prime p
    a, rk = [[x % p for x in r] for r in m], 0
    for c in range(len(a[0]) if a else 0):
        piv = next((i for i in range(rk, len(a)) if a[i][c]), None)
        if piv is None: continue
        a[rk], a[piv] = a[piv], a[rk]; inv = pow(a[rk][c], p - 2, p); a[rk] = [x * inv % p for x in a[rk]]
        for i in range(len(a)):
            if i != rk and a[i][c]: a[i] = [(x - a[i][c] * y) % p for x, y in zip(a[i], a[rk])]
        rk += 1
    return rk

T = lambda m: [list(c) for c in zip(*m)]
def homology(n, d):  # H_k = (rank, torsion) from the Smith forms of d_k and d_(k+1)
    s = {k: smith(m) for k, m in d.items()}; r = lambda k: s[k][0] if k in s else 0
    return [(n[k] - r(k) - r(k + 1), s[k + 1][1] if k + 1 in s else []) for k in range(len(n))]
def cohomology(n, d):  # H^k from the coboundaries delta^k = d_(k+1) transposed
    s = {k: smith(T(m)) for k, m in d.items()}; r = lambda k: s[k][0] if k in s else 0
    return [(n[k] - r(k + 1) - r(k), s[k][1] if k in s else []) for k in range(len(n))]
def betti_p(n, d, p):
    r = lambda k: rank_p(d[k], p) if k in d else 0
    return [n[k] - r(k) - r(k + 1) for k in range(len(n))]

# road 1: a group is a list of cyclic orders, 0 for a copy of Z
grp = lambda h: [0] * h[0] + h[1]
canon = lambda g: (g.count(0), normal([x for x in g if x > 1]))
tensor = lambda g, h: [gcd(a, b) for a in g for b in h if gcd(a, b) != 1]
tor = lambda g, h: [gcd(a, b) for a in g for b in h if a and b and gcd(a, b) > 1]
uct_p = lambda H, p: [len(tensor(grp(H[k]), [p])) + (len(tor(grp(H[k - 1]), [p])) if k else 0) for k in range(len(H))]
uct_co = lambda H: [canon([0] * H[k][0] + (H[k - 1][1] if k else [])) for k in range(len(H))]
def kunneth(HX, HY, tor_on=True):
    out = []
    for n in range(len(HX) + len(HY) - 1):
        g = [x for i in range(len(HX)) for j in range(len(HY)) if i + j == n for x in tensor(grp(HX[i]), grp(HY[j]))]
        g += [x for i in range(len(HX)) for j in range(len(HY)) if i + j == n - 1 and tor_on for x in tor(grp(HX[i]), grp(HY[j]))]
        out.append(canon(g))
    return out

def simplicial(tris):
    f = [sorted({(v,) for t in tris for v in t}), sorted({e for t in tris for e in combinations(t, 2)}), sorted(tris)]
    ix, d = [{s: i for i, s in enumerate(x)} for x in f], {}
    for k in (1, 2):
        d[k] = [[0] * len(f[k]) for _ in f[k - 1]]
        for c, s in enumerate(f[k]):
            for i in range(k + 1): d[k][ix[k - 1][s[:i] + s[i + 1:]]][c] = (-1) ** i
    return [len(x) for x in f], d

def product(X, Y):  # cells e x f; d(e x f) = de x f + (-1)^dim(e) e x df
    (nx, dx), (ny, dy) = X, Y
    cells = [[(k, i, n - k, j) for k in range(len(nx)) if 0 <= n - k < len(ny) for i in range(nx[k]) for j in range(ny[n - k])]
             for n in range(len(nx) + len(ny) - 1)]
    ix, d = [{c: t for t, c in enumerate(cs)} for cs in cells], {}
    for n in range(1, len(cells)):
        d[n] = [[0] * len(cells[n]) for _ in cells[n - 1]]
        for t, (k, i, l, j) in enumerate(cells[n]):
            for i2 in range(nx[k - 1] if k else 0): d[n][ix[n - 1][(k - 1, i2, l, j)]][t] += dx[k][i2][i]
            for j2 in range(ny[l - 1] if l else 0): d[n][ix[n - 1][(k, i, l - 1, j2)]][t] += (-1) ** k * dy[l][j2][j]
    return [len(c) for c in cells], d, cells

D, P = 2, 2  # the disc's rim runs D times round the loop; P is the prime for counting mod P
yn = lambda b: "yes" if b else "no"
fmt = lambda H, s="H": "; ".join(f"{s}{k}: rank {r}, torsion {t}" for k, (r, t) in enumerate(H))
cell = ([1, 1, 1], {1: [[0]], 2: [[D]]})
tris = [tuple(sorted(t)) for t in [(0, 1, 2), (0, 2, 3), (0, 3, 4), (0, 4, 5), (0, 5, 1), (1, 2, 4), (2, 3, 5), (3, 4, 1), (4, 5, 2), (5, 1, 3)]]
simp = simplicial(tris)
H = homology(*cell)
print(f"RP2, one cell each, rim a^{D}: cells {cell[0]}; d1 = {cell[1][1]}; d2 = {cell[1][2]}")
print(f"integer homology: {fmt(H)}")
print(f"RP2 as {simp[0][0]} vertices, {simp[0][1]} edges, {simp[0][2]} triangles: same groups: {yn(homology(*simp) == H)}")
assert D != 2 or homology(*simp) == H
for p in sorted({2, 3, P}):
    tp = [len(tensor(grp(h), [p])) for h in H]
    print(f"mod {p}: formula {uct_p(H, p)} (tensor part {tp}); ranks mod {p}: cells {betti_p(*cell, p)}, triangles {betti_p(*simp, p)}")
    assert uct_p(H, p) == betti_p(*cell, p) and (D != 2 or uct_p(H, p) == betti_p(*simp, p))
print(f"cohomology, formula Hom + Ext: {fmt(uct_co(H), 'H^')}")
print(f"cohomology, transposed matrices, cells: {fmt(cohomology(*cell), 'H^')}; triangles agree: {yn(cohomology(*simp) == uct_co(H))}")
assert uct_co(H) == cohomology(*cell) and (D != 2 or uct_co(H) == cohomology(*simp))
n2, d2, cells = product(cell, cell)
dd = all(all(x == 0 for r in [[sum(a * b for a, b in zip(row, col)) for col in T(d2[k + 1])] for row in d2[k]] for x in r) for k in range(1, 4))
HP = homology(n2, d2)
print(f"RP2 x RP2: cells per dimension {n2}; d d = 0: {yn(dd)}")
print(f"product complex, Smith form: {fmt(HP)}")
print(f"Kunneth formula:             {fmt(kunneth(H, H))}")
assert dd and HP == kunneth(H, H)
name = lambda c: f"e{c[0]} x e{c[2]}"
bd = lambda k, t: ", ".join(f"{r[t]} on {name(cells[k - 1][i])}" for i, r in enumerate(d2[k]) if r[t])
print("; ".join(f"d{k} of {name(cells[k][t])}: {bd(k, t)}" for k in (3, 4) for t in range(len(cells[k]))))
for p in sorted({2, 3, P}):
    print(f"RP2 x RP2 mod {p}: ranks {betti_p(n2, d2, p)}; from integer groups {uct_p(HP, p)}")
    assert betti_p(n2, d2, p) == uct_p(HP, p)
print(f"RP2 x RP2 over Q: {[r for r, _ in HP]}; chi {sum((-1) ** k * c for k, c in enumerate(n2))} = {cell[0][0] - cell[0][1] + cell[0][2]} squared")
ok1 = sum(sum(n * x % m == 0 for x in range(m)) == gcd(m, n) == m // len({n * x % m for x in range(m)})
          for m in range(1, 13) for n in range(1, 13))
print(f"brute force: Tor(Z/m, Z/n) and Z/m (x) Z/n both have gcd(m, n) elements for {ok1} of 144 pairs m, n = 1..12")
ok2 = sum(homology(*product(([1, 1], {1: [[m]]}), ([1, 1], {1: [[n]]}))[:2]) == kunneth([(0, normal([m])), (0, [])], [(0, normal([n])), (0, [])])
          for m in range(1, 7) for n in range(1, 7))
print(f"Kunneth on pieces Z -m-> Z times Z -n-> Z: formula = Smith form for {ok2} of 36 pairs m, n = 1..6")
assert ok1 == 144 and ok2 == 36
naive = [len(tensor(grp(h), [2])) for h in H]
print(f"mistake 1, mod 2 without Tor: {naive}, alternating sum {naive[0] - naive[1] + naive[2]}, but chi = {cell[0][0] - cell[0][1] + cell[0][2]}")
print(f"mistake 2, cohomology copied from homology: {fmt(H, 'H^')}")
nt = kunneth(H, H, False)
print(f"mistake 3, Kunneth without Tor: H3 rank {nt[3][0]}, torsion {nt[3][1]}; then mod 2 {uct_p(nt, 2)}, not {betti_p(n2, d2, 2)}")
h1, h0 = sum(2 * x % 4 == 0 for x in range(4)), 4 // len({2 * x % 4 for x in range(4)})
f1, k1 = len(tensor([h1], [2])) + len(tor([h0], [2])), sum(2 * x % gcd(4, 2) == 0 for x in range(gcd(4, 2))).bit_length() - 1
print(f"mistake 4, Z/4 -2-> Z/4, chain groups not free: H1, H0 have {h1}, {h0} elements; mod 2 in degree 1 the formula says {f1}, the complex gives {k1}")
assert naive != uct_p(H, 2) and nt != HP
print("ALL CHECKS PASS")
