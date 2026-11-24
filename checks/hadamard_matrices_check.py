# Hadamard matrices -- the check behind the card.  Nothing is imported.  Sylvester's tables are
# Kronecker products of H2; the determinant is found by expansion, as a Gram-Schmidt volume and by
# brute force over every 4 by 4 table of +-1; the weighing plan is solved two ways; H8 becomes Fano.
def kron(a, b): return [[x * y for x in ra for y in rb] for ra in a for rb in b]
def gram(m): return [[sum(x * y for x, y in zip(p, q)) for q in m] for p in m]
def is_nI(m): return gram(m) == [[len(m) * (i == j) for j in range(len(m))] for i in range(len(m))]
def f4(xs): return ", ".join(f"{x:.4f}" for x in xs)
def det(m):                                    # Laplace expansion along the first row, exact
    return m[0][0] if len(m) == 1 else sum((-1) ** j * m[0][j] * det([r[:j] + r[j + 1:] for r in m[1:]]) for j in range(len(m)) if m[0][j])
def leftovers(m):                              # Gram-Schmidt: lengths of what is left of each row
    qs, out = [], []
    for u in m:
        for q in qs: u = [a - sum(x * z for x, z in zip(u, q)) * b for a, b in zip(u, q)]
        out.append(sum(a * a for a in u) ** 0.5); qs.append([a / out[-1] for a in u])
    return out
def solve(m, y):                               # Gauss-Jordan elimination (H4 needs no row swaps)
    n = len(m); a = [[float(x) for x in r] + [float(t)] for r, t in zip(m, y)]
    for i in range(n):
        for r in [r for r in range(n) if r != i]: a[r] = [x - a[r][i] / a[i][i] * z for x, z in zip(a[r], a[i])]
    return [a[i][n] / a[i][i] for i in range(n)]
def tables(n): return [[[1 - 2 * (c >> (n * i + j) & 1) for j in range(n)] for i in range(n)] for c in range(2 ** (n * n))]
def pairs(bl): return sorted({sum(x in B and y in B for B in bl) for x in range(1, 8) for y in range(x + 1, 8)})
def perms(xs): return [[x] + p for i, x in enumerate(xs) for p in perms(xs[:i] + xs[i + 1:])] if xs else [[]]
H2 = [[1, 1], [1, -1]]; H4 = kron(H2, H2); H8 = kron(H2, H4); H16 = kron(H2, H8)
print(f"H4 = H2 (x) H2 = {H4}\nH H^T = n I: " + ", ".join(f"n = {len(h)} {'yes' if is_nI(h) else 'NO'}" for h in (H2, H4, H8, H16)))
abcd = [sum(H8[1][c] == s and H8[2][c] == t for c in range(8)) for s, t in ((1, 1), (1, -1), (-1, 1), (-1, -1))]
print(f"H8 rows 2, 3: columns (+,+) (+,-) (-,+) (-,-) = {abcd}, each n/4 = {8 // 4}")
cand = [v for v in ([1] + [1 - 2 * (c >> j & 1) for j in range(5)] for c in range(32)) if sum(v) == 0]
ok = lambda s: all(sum(x * y for x, y in zip(cand[i], cand[j])) == 0 for i in range(10) for j in range(i) if s >> i & s >> j & 1)
best = 1 + max(bin(s).count("1") for s in range(2 ** len(cand)) if ok(s))
print(f"n = 6: {len(cand)} balanced rows, at most {best} mutually perpendicular rows, 6 needed")
all4 = [abs(det(t)) for t in tables(4)]; big = max(all4)
print(f"det H4 = {det(H4)}; det(H4 H4^T) = {det(gram(H4))} = 16^2; bound 4^(4/2) = {4 ** 2}")
print(f"all {len(all4)} 4 by 4 tables of +-1: largest |det| {big}, reached by {all4.count(big)}")
M = [[1, 1, 1, 1], [1, 1, 1, -1], [1, 1, -1, 1], [1, -1, 1, 1]]; lh, lm = leftovers(H4), leftovers(M)
pr = lambda xs: xs[0] * xs[1] * xs[2] * xs[3]
print(f"Gram-Schmidt leftovers: H4 {f4(lh)}, product {pr(lh):.4f}; M {f4(lm)}, product {pr(lm):.4f}; |det M| = {abs(det(M))}")
w = [120, 75, 210, 45]; y = [sum(h * x for h, x in zip(row, w)) for row in H4]
byT = [sum(H4[k][i] * y[k] for k in range(4)) / 4 for i in range(4)]; byG = solve(H4, y)
print(f"parcels {w} g; readings H4 w = {y} g\nrecovered: H4^T y / 4 = {f4(byT)}; elimination {f4(byG)}")
var = sum(solve(H4, [k == j for k in range(4)])[0] ** 2 for j in range(4))   # row 1 of H4^-1, squared
print(f"variance factor per parcel {var:.4f}: scale error 0.4 g becomes {0.4 * var ** 0.5:.4f} g")
core = [r[1:] for r in H8[1:]]
blocks = [tuple(j + 1 for j in range(7) if r[j] == 1) for r in core]; lam = pairs(blocks)
print(f"H8 core, +1 places: blocks {blocks}; every pair together {lam} times")
FANO = [(1, 2, 4), (2, 3, 5), (3, 4, 6), (4, 5, 7), (5, 6, 1), (6, 7, 2), (7, 1, 3)]; fs = {tuple(sorted(L)) for L in FANO}
pi = next(p for p in perms(list(range(1, 8))) if {tuple(sorted(p[x - 1] for x in B)) for B in blocks} == fs)
print("relabel " + " ".join(f"{x}->{pi[x - 1]}" for x in range(1, 8)) + ": the blocks become the 7 Fano lines")
back = [[1] * 8] + [[1] + [1 if x in L else -1 for x in range(1, 8)] for L in FANO]
print(f"Fano lines -> +1 on the line, -1 off it, border of +1s: H H^T = 8I {'yes' if is_nI(back) else 'NO'}")
all3 = [abs(det(t)) for t in tables(3)]; JH = kron([[1, 1], [1, 1]], H4)
minus = [tuple(j + 1 for j in range(7) if r[j] == -1) for r in core]; lam2 = pairs(minus)
print(f"mistake 1, n = 3: largest |det| of {len(all3)} tables {max(all3)}, bound 3^(3/2) = {3 ** 1.5:.4f}")
print(f"mistake 2, [[H4, H4], [H4, H4]]: det {det(JH)}, H H^T = 8I {'yes' if is_nI(JH) else 'NO'}")
print(f"mistake 3, -1 places: blocks of {len(minus[0])}, every pair together {lam2} times")
assert all(is_nI(h) for h in (H2, H4, H8, H16)) and abcd == [2, 2, 2, 2] and best == 2
assert det(H4) ** 2 == det(gram(H4)) == 4 ** 4 and big == 16 == round(pr(lh)) and abs(pr(lm) - abs(det(M))) < 1e-9
assert [round(x, 9) for x in byT] == [round(x, 9) for x in byG] == w and abs(var - 0.25) < 1e-12
assert lam == [1] and is_nI(back) and max(all3) == 4 and det(JH) == 0 and lam2 == [2]
print("ALL CHECKS PASS")
