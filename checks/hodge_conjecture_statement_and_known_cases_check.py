# The Hodge conjecture in degree 2, on a K3 surface -- the check behind the card.
# Standard library only.  The Fermat quartic x^4 + y^4 + z^4 + w^4 = 0 in P^3:
#   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
#   road 2 (cycle side): its 48 lines, which pairs meet (exact 4 x 4 determinants over Z[zeta]),
#                        and the rank of their intersection matrix, by exact integer elimination
#   road 3 (one class two ways): 24 plane sections, four lines each, all give the plane class h
from itertools import permutations, product

def zmul(a, b):                   # Z[t]/(t^4 + 1): t = zeta, a primitive 8th root of unity
    r = [0] * 8
    for i in range(4):
        for j in range(4):
            r[i + j] += a[i] * b[j]
    return tuple(r[k] - r[k + 4] for k in range(4))

ZERO, ONE, ZETA = (0, 0, 0, 0), (1, 0, 0, 0), (0, 1, 0, 0)

def zdet(m):                      # 4 x 4 determinant over Z[zeta], one term per permutation
    total = ZERO
    for p in permutations(range(4)):
        sign = (-1) ** sum(p[i] > p[j] for i in range(4) for j in range(i + 1, 4))
        term = ONE
        for i in range(4):
            term = zmul(term, m[i][p[i]])
        total = tuple(t + sign * x for t, x in zip(total, term))
    return total

def bareiss(m):                   # fraction-free elimination: (rank, signed determinant if square)
    m, prev, r, sign = [row[:] for row in m], 1, 0, 1
    for c in range(len(m[0])):
        p = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if p is None:
            continue
        if p != r:
            m[r], m[p], sign = m[p], m[r], -sign
        for i in range(r + 1, len(m)):
            for j in range(c + 1, len(m[0])):
                m[i][j] = (m[r][c] * m[i][j] - m[i][c] * m[r][j]) // prev
            m[i][c] = 0
        prev, r = m[r][c], r + 1
    full = r == len(m) == len(m[0])
    return r, sign * prev if full else 0

# ---- road 1: Hodge numbers of a smooth quartic surface ----
d = 4
jac = [sum(1 for e in product(range(d - 1), repeat=4) if sum(e) == k) for k in (0, 4, 8)]
h20, h11, h02 = jac[0], jac[1] + 1, jac[2]          # degree 0, 4, 8 of C[x,y,z,w]/(x^3, y^3, z^3, w^3); +1 is h
euler, sig = d ** 3 - 4 * d ** 2 + 6 * d, (4 - d * d) * d // 3
b2 = euler - 2                                       # b0 = b4 = 1, b1 = b3 = 0
print("road 1, the Hodge side of a smooth quartic surface (a K3 surface)")
print(f"monomials with exponents at most 2, of degree 0, 4, 8: {jac[0]}, {jac[1]}, {jac[2]}")
print(f"h^2,0 = {h20}, h^1,1 = {jac[1]} + 1 = {h11}, h^0,2 = {h02}; b2 = {h20 + h11 + h02}")
print(f"Euler number 64 - 64 + 24 = {euler}, so b2 = {b2}; signature (4 - 16) x 4 / 3 = {sig}")
print(f"signature from Hodge numbers 2 + 2 x {h20} - {h11} = {2 + 2 * h20 - h11}; "
      f"positive part b+ = {(b2 + sig) // 2} = 2 h^2,0 + 1")

# ---- road 2: the 48 lines and their intersection matrix ----
roots = [ONE]
for _ in range(7):
    roots.append(zmul(roots[-1], ZETA))
roots = [roots[k] for k in (1, 3, 5, 7)]            # the four a with a^4 = -1
lines, planes = [], []
for (i, j, k, l) in [(0, 1, 2, 3), (0, 2, 1, 3), (0, 3, 1, 2)]:
    for a, b in product(roots, roots):                # the line x_i = a x_j, x_k = b x_l
        f, g = [ZERO] * 4, [ZERO] * 4
        f[i], f[j], g[k], g[l] = ONE, tuple(-x for x in a), ONE, tuple(-x for x in b)
        lines.append((f, g))
assert all(zmul(zmul(r, r), zmul(r, r)) == (-1, 0, 0, 0) for r in roots)   # a^4 = -1: each line lies on X
n = len(lines)
meet = lambda r, c: zdet(list(lines[r]) + list(lines[c])) == ZERO
G = [[-2 if r == c else int(meet(r, c)) for c in range(n)] for r in range(n)]
rank48, _ = bareiss(G)
print("road 2, the cycle side: the 48 lines on the Fermat quartic")
meets = sorted({sum(row) + 2 for row in G})          # how many other lines each of the 48 meets
print(f"lines: {n}; each meets {', '.join(map(str, meets))} others; self-intersection of a line: {G[0][0]}")
print(f"rank of the 48 x 48 intersection matrix over Q: {rank48}")
basis, minors = [], [1]
for c in range(n):                                    # grow a basis while the Gram determinant stays nonzero
    _, dt = bareiss([[G[a][b] for b in basis + [c]] for a in basis + [c]])
    if dt != 0:
        basis, minors = basis + [c], minors + [dt]
neg = sum(1 for u, v in zip(minors, minors[1:]) if (u > 0) != (v > 0))
print(f"independent lines found: {len(basis)}; Gram determinant of the {len(basis)}: {minors[-1]}")
print(f"signature of the intersection form on them: ({len(basis) - neg}, {neg})")

# ---- road 3: plane sections ----
for q, a in product(range(3), range(4)):              # the planes x_i = a x_j and x_k = a x_l
    planes += [[16 * q + 4 * a + b for b in range(4)], [16 * q + 4 * b + a for b in range(4)]]
rows = [[sum(G[m][c] for m in pl) for c in range(n)] for pl in planes]
h_sq = sum(rows[0][m] for m in planes[0])
print("road 3, the plane class h as four coplanar lines")
print(f"planes holding four lines: {len(planes)}; distinct rows h.L among them: {len(set(map(tuple, rows)))}")
print(f"h.L for every line: {sorted(set(rows[0]))}; h^2 = 4 x (-2) + 2 x 6 = {h_sq}")

# ---- what breaks ----
wrong = [[1 if r == c else G[r][c] for c in range(n)] for r in range(n)]
kd, kp = 125, 5
print(f"mistake 1, a line meets itself once, as in the plane: rank {bareiss(wrong)[0]}, more than b2 = {b2}")
print(f"mistake 2, every rational class in H^2 algebraic: {b2} claimed, rho = {len(basis)} here")
print(f"mistake 3, every (1,1) class algebraic: h^1,1 = {h11} claimed, rho = 1 for a very general quartic (quoted)")
print(f"mistake 4, integer coefficients: degree {kd} threefold, {kp}^3 divides {kd}: {'yes' if kd % kp ** 3 == 0 else 'no'}; "
      f"class l of degree 1, curve degrees multiples of {kp} (quoted); h^2 = {kd} l, so l = h^2/{kd} over Q only")
assert (h20, h11, h02) == (1, 20, 1) and h20 + h11 + h02 == b2       # road 1 against the Euler number
assert 2 + 2 * h20 - h11 == sig and (b2 + sig) // 2 == 2 * h20 + 1    # road 1 against the signature
assert rank48 == len(basis) == h11 == 20                             # road 2 meets road 1: rho = 20
assert meets == [14]                                                 # every line meets the same 14 others
assert minors[-1] == -64 and neg == 19                                # Hodge index: one positive direction
assert len(set(map(tuple, rows))) == 1 and set(rows[0]) == {1} and h_sq == 4
assert bareiss(wrong)[0] > b2                                       # mistake 1: the wrong form is impossible
print("ALL CHECKS PASS")
