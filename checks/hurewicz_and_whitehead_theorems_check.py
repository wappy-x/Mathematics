# Hurewicz and Whitehead -- the check behind the card.  Standard library only.  Integer homology by
# Smith normal form, written out here; figure-eight loops as reduced words; Kunneth from the factors.
from itertools import combinations, product

def gcd(a, b):                       # Euclid's algorithm
    return abs(a) if b == 0 else gcd(b, a % b)

def diagonal(M):                     # Smith normal form: the invariant factors
    A, out = [row[:] for row in M], []
    while nz := [(abs(A[i][j]), i, j) for i in range(len(A)) for j in range(len(A[0])) if A[i][j]]:
        _, p, q = min(nz)
        clean = True
        for i in range(len(A)):      # clear column q with row operations
            if i != p and A[i][q]:
                f = A[i][q] // A[p][q]
                A[i] = [x - f * y for x, y in zip(A[i], A[p])]
                clean = clean and A[i][q] == 0
        for j in range(len(A[0])):   # clear row p with column operations
            if j != q and A[p][j]:
                f = A[p][j] // A[p][q]
                for row in A:
                    row[j] -= f * row[q]
                clean = clean and A[p][j] == 0
        if clean:
            out.append(abs(A[p][q]))
            A = [r[:q] + r[q + 1:] for i, r in enumerate(A) if i != p]
    for i in range(len(out)):        # make each factor divide the next
        for j in range(i + 1, len(out)):
            g = gcd(out[i], out[j])
            out[i], out[j] = g, out[i] * out[j] // g
    return out

def homology(cells, d):              # cells[k] = number of k-cells; d[k]: C_k -> C_(k-1)
    fac = {k: diagonal(d[k]) if k in d else [] for k in range(len(cells) + 1)}
    return [(cells[k] - len(fac[k]) - len(fac[k + 1]), [t for t in fac[k + 1] if t > 1]) for k in range(len(cells))]

def zero_dd(d):                      # the boundary of a boundary is zero: d[k-1] d[k] = 0
    return all(sum(d[k - 1][i][m] * d[k][m][j] for m in range(len(d[k]))) == 0
               for k in d if k - 1 in d for i in range(len(d[k - 1])) for j in range(len(d[k][0])))

def show(H):
    return "; ".join(f"H{k}: rank {r}, torsion {t}" for k, (r, t) in enumerate(H))

def sphere(n):
    return [1] + [0] * (n - 1) + [1], {}

def rp(n):                           # one cell per dimension, boundary 1 + (-1)^k
    return [1] * (n + 1), {k: [[1 + (-1) ** k]] for k in range(1, n + 1)}

def times(X, Y):                     # product cells: d(a x b) = da x b + (-1)^|a| a x db
    (cx, dx), (cy, dy) = X, Y
    cells = {}
    for p, q in product(range(len(cx)), range(len(cy))):
        cells.setdefault(p + q, []).extend((p, i, q, j) for i in range(cx[p]) for j in range(cy[q]))
    top = max(cells)
    idx = {k: {c: n for n, c in enumerate(cells.get(k, []))} for k in range(top + 1)}
    d = {}
    for k in range(1, top + 1):
        M = [[0] * len(cells.get(k, [])) for _ in cells.get(k - 1, [])]
        for col, (p, i, q, j) in enumerate(cells.get(k, [])):
            for r in range(cx[p - 1] if p in dx else 0):
                M[idx[k - 1][(p - 1, r, q, j)]][col] += dx[p][r][i]
            for r in range(cy[q - 1] if q in dy else 0):
                M[idx[k - 1][(p, i, q - 1, r)]][col] += (-1) ** p * dy[q][r][j]
        d[k] = M
    return [len(cells.get(k, [])) for k in range(top + 1)], d

def kunneth(HX, HY, tor=True):                 # second road: tensor plus Tor, from the factors
    out = []
    for k in range(len(HX) + len(HY) - 1):
        rank, tors = 0, []
        for i, (r1, t1) in enumerate(HX):
            for j, (r2, t2) in enumerate(HY):
                if i + j == k:
                    rank += r1 * r2
                    tors += t1 * r2 + t2 * r1 + [gcd(a, b) for a in t1 for b in t2]
                if tor and i + j == k - 1:
                    tors += [gcd(a, b) for a in t1 for b in t2]
        out.append((rank, sorted(t for t in tors if t > 1)))
    return out

def reduce(w):                       # free reduction: cancel a A, A a, b B, B b
    out = []
    for x in w:
        if out and out[-1] == x.swapcase():
            out.pop()
        else:
            out.append(x)
    return "".join(out)

def h(w):                            # the Hurewicz map on the figure eight: exponent sums
    return (w.count("a") - w.count("A"), w.count("b") - w.count("B"))

words = {k: ["".join(t) for t in product("aAbB", repeat=k) if reduce("".join(t)) == "".join(t)] for k in range(5)}
eight = homology([1, 2], {})
print("figure eight, cells [1, 2]:", show(eight))
print("reduced words of length 1 to 4:", [len(words[k]) for k in range(1, 5)])
dead = [w for w in words[4] if h(w) == (0, 0)]
print(f"length-4 loops that h sends to (0, 0): {len(dead)}: {' '.join(dead)}")
print(f"h(ab) = {h('ab')}, h(ba) = {h('ba')}; ab and ba the same loop: {'yes' if reduce('ab' + 'AB') == '' else 'no'}")
short = [w for k in range(3) for w in words[k]]
hom = all(h(reduce(u + v)) == tuple(x + y for x, y in zip(h(u), h(v))) for u in short for v in short)
print(f"h(uv) = h(u) + h(v) on all {len(short) ** 2} pairs up to length 2: {'yes' if hom else 'no'}")
wedge = homology([1, 0, 2], {})
print("S2 v S2, cells [1, 0, 2]:", show(wedge))
tris = [t for s in ((0, 1, 2, 3), (0, 4, 5, 6)) for t in combinations(s, 3)]
edges = sorted({e for t in tris for e in combinations(t, 2)})
bd = lambda faces, cells: [[sum((-1) ** i for i in range(len(c)) if c[:i] + c[i + 1:] == f) for c in cells] for f in faces]
tri = homology([7, len(edges), len(tris)], {1: bd([(v,) for v in range(7)], edges), 2: bd(edges, tris)})
print(f"S2 v S2, two hollow tetrahedra, V E F = 7 {len(edges)} {len(tris)}, chi {7 - len(edges) + len(tris)}:", show(tri))
print(f"pi1 = 1 (no 1-cells), so Hurewicz: pi2(S2 v S2) = H2: rank {wedge[2][0]}")
P, Q = times(rp(2), sphere(3)), times(sphere(2), rp(3))
HP, HQ = homology(*P), homology(*Q)
print(f"RP2 x S3, product cells {P[0]}: {show(HP)}")
print("RP2 x S3, by Kunneth:", show(kunneth(homology(*rp(2)), homology(*sphere(3)))))
print(f"S2 x RP3, product cells {Q[0]}: {show(HQ)}")
print("S2 x RP3, by Kunneth:", show(kunneth(homology(*sphere(2)), homology(*rp(3)))))
cover = homology(*times(sphere(2), sphere(3)))
print("common universal cover S2 x S3:", show(cover))
print(f"pi1 of both: Z/{HP[1][1][0]}; pi2 of both = H2(S2 x S3): rank {cover[2][0]}")
print(f"H5: RP2 x S3 rank {HP[5][0]}, S2 x RP3 rank {HQ[5][0]}: not homotopy equivalent")
dunce = homology([1, 1, 1], {2: [[h("aaA")[0]]]})
print(f"dunce hat, rim aaA, incidence {h('aaA')[0]}: {show(dunce)}; chi {1 - 1 + 1}")
print(f"rim aaA freely reduced: {reduce('aaA')}, so the relation reads a = 1 and pi1 = 1")
print(f"mistake, Hurewicz with pi1 = Z/2: RP2 {show(homology(*rp(2)))}; pi2(RP2) = pi2(S2) = H2(S2): rank {homology(*sphere(2))[2][0]}")
print(f"mistake, Hurewicz with pi1 = Z^2: torus {show(homology([1, 2, 1], {}))}; pi2 = 0 (cover R2)")
print(f"mistake, past the first group: H3(S2): rank {homology([1, 0, 1, 0], {})[3][0]}, but pi3(S2) = Z (Hopf)")
HR, no_tor = homology(*(RR := times(rp(2), rp(2)))), kunneth(homology(*rp(2)), homology(*rp(2)), tor=False)
print(f"mistake, Kunneth without Tor: RP2 x RP2 reads {show(no_tor).split('; ')[3]}; truly {show(HR).split('; ')[3]}")
print(f"mistake, no abelianising: {len(dead)} loops of length 4 are not trivial in pi1 yet read 0 in H1")
assert eight == [(1, []), (2, [])] and len(dead) == 8 and hom
assert [len(words[k]) for k in range(1, 5)] == [4 * 3 ** (k - 1) for k in range(1, 5)]
assert wedge == tri and wedge[2] == (2, [])
assert HP == kunneth(homology(*rp(2)), homology(*sphere(3))) and HQ == kunneth(homology(*sphere(2)), homology(*rp(3)))
assert HR == kunneth(homology(*rp(2)), homology(*rp(2))) and HR[3] == (0, [2]) and zero_dd(RR[1])
assert HP[5] == (0, []) and HQ[5] == (1, []) and cover[2] == (1, [])
assert dunce == [(1, []), (0, []), (0, [])] and reduce("aaA") == "a"
print("ALL CHECKS PASS")
