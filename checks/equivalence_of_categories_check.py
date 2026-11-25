# Equivalence of categories -- the check behind the card.  Nothing is imported.
# Part 1, real numbers: the derivative from quadratics to straight-line
# polynomials becomes a matrix, checked against central differences, in two
# bases for the target.  Part 2, the two-element field F2 (0 and 1, 1 + 1 = 0),
# where every hom-set is finite: matrices against the linear maps found by
# searching all functions (full and faithful), planes counted two ways (many
# objects, one dimension), and functors that fall short of an equivalence.

def matvec(m, v):                         # matrix times column vector
    return [sum(a * b for a, b in zip(row, v)) for row in m]

def matmul(a, b):                         # matrix product: b acts first
    return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))]
            for i in range(len(a))]

def value(c, t):                          # c[0] + c[1] t + c[2] t^2
    return sum(ck * t ** k for k, ck in enumerate(c))

def slope(c, t):                          # central difference: exact on quadratics
    return (value(c, t + 1) - value(c, t - 1)) // 2

def show(xs):                             # floats with one decimal, as in Rust
    return "[" + ", ".join(f"{x + 0.0:.1f}" for x in xs) + "]"

def yn(claim):
    return "yes" if claim else "no"

def ones(x):
    return bin(x).count("1")

def apply(rows, x):                       # F2 matrix (rows as bit masks) on x
    return sum((ones(r & x) % 2) << i for i, r in enumerate(rows))

def matrices(n, m):                       # every m by n matrix over F2
    return [[(code >> (n * i)) & ((1 << n) - 1) for i in range(m)]
            for code in range(1 << (n * m))]

def f2mul(a, b):                          # F2 product, b acts first
    out = []
    for r in a:
        row = 0
        for k in range(len(b)):
            if r >> k & 1:
                row ^= b[k]
        out.append(row)
    return out

def f2det(rows):                          # 2 by 2 F2 determinant: ad + bc, since 1 + 1 = 0
    return ((rows[0] & 1) & (rows[1] >> 1)) ^ ((rows[0] >> 1) & (rows[1] & 1))

def transpose(rows, n):
    return [sum((r >> j & 1) << i for i, r in enumerate(rows)) for j in range(n)]

def closed(mask):                         # a subset of F2^k: is it a subspace?
    xs = [x for x in range(16) if mask >> x & 1]
    return 0 in xs and all(mask >> (x ^ y) & 1 for x in xs for y in xs)

def search(n, m):                         # all functions F2^n -> F2^m, linear ones kept
    N, M = 1 << n, 1 << m
    linear = set()
    for code in range(M ** N):
        f = [(code // M ** x) % M for x in range(N)]
        if all(f[x ^ y] == f[x] ^ f[y] for x in range(N) for y in range(N)):
            linear.add(tuple(f))
    images = {tuple(apply(r, x) for x in range(N)) for r in matrices(n, m)}
    return M ** N, linear, images

p, D, E, Q = [3, 5, 4], [[0, 1, 0], [0, 0, 2]], [[1, 2]], [[1, 1], [1, -1]]
by_matrix = matvec(D, p)
by_values = [slope(p, 0), slope(p, 1) - slope(p, 0)]
ED = matmul(E, D)
det = Q[0][0] * Q[1][1] - Q[0][1] * Q[1][0]
Qinv = [[Q[1][1] / det, -Q[0][1] / det], [-Q[1][0] / det, Q[0][0] / det]]
D2 = matmul(Qinv, D)
new = matvec(D2, p)
back = matvec(Q, new)
print("V = polynomials of degree at most 2, W = degree at most 1, f = d/dt")
print(f"p(t) = 3 + 5t + 4t^2 has coordinates {p} in the basis 1, t, t^2")
print(f"matrix of f in the bases 1, t, t^2 and 1, t: {D}")
print(f"f(p) by the matrix: {by_matrix}")
print(f"f(p) by central differences, no matrix: {by_values}, from slopes {slope(p, 0)} at t = 0 and {slope(p, 1)} at t = 1")
print(f"g = evaluate at t = 2, matrix {E}; matrix of g after f: {ED}")
print(f"g(f(p)) by the product matrix: {matvec(ED, p)[0]}; by central difference at t = 2: ({value(p, 3)} - {value(p, 1)})/2 = {slope(p, 2)}")
print(f"second basis for W: 1 + t and 1 - t; Q = {Q}, det {det}")
print(f"matrix of f in the second basis, Q^-1 D: [{show(D2[0])}, {show(D2[1])}]")
print(f"f(p) in the second basis: {show(new)}; Q turns it back into {show(back)}")
wrong = matvec(Q, by_matrix)
print(f"mistake, {by_matrix} read in the second basis: {wrong[0]} - {-wrong[1]}t, not 5 + 8t")
print("F2: arrows n -> m, matrices against linear maps found among all functions")
print("n m functions linear matrices same")
total, all_same = 0, True
for n in range(3):
    for m in range(3):
        funcs, linear, images = search(n, m)
        same = images == linear and len(images) == len(matrices(n, m)) == 1 << (m * n)
        all_same = all_same and same
        total += len(linear)
        print(f"{n} {m} {funcs} {len(linear)} {len(matrices(n, m))} {yn(same)}")
print(f"arrows among 0, 1, 2: {total}; full and faithful on every pair: {yn(all_same)}")
planes = [s for s in range(256) if ones(s) == 4 and closed(s)]
formula = (8 - 1) * (8 - 2) // ((4 - 1) * (4 - 2))
print(f"planes inside F2^3: by search {len(planes)}, by formula {formula}; objects 2 in the matrix category: 1")
onto = {s: 0 for s in planes}
for rows in matrices(2, 3):
    image = sum(1 << apply(rows, x) for x in range(4))
    if ones(image) == 4:
        onto[image] += 1
invertible = [r for r in matrices(2, 2) if ones(sum(1 << apply(r, x) for x in range(4))) == 4]
print(f"isomorphisms from F2^2 onto each plane: {[onto[s] for s in planes]}; invertible 2 by 2: {len(invertible)}")
lines = [s for s in range(16) if ones(s) == 2 and closed(s)]
even = [1 << k for k in (0, 2, 4)]                                  # points in F2^0, F2^2, F2^4
reached = [s for s in lines if ones(s) in even]
print(f"lines inside F2^2: {len(lines)}, {ones(lines[0])} points each; even counts give {even} points; "
      f"reached by the even-dimension category: {len(reached)}, so not essentially surjective")
print(f"mistake, invertible matrices only: {len(invertible)} of {len(matrices(2, 2))} arrows 2 -> 2, so not full")
pairs = [(a, b) for a in matrices(2, 2) for b in matrices(2, 2)]
keeps = all([apply(f2mul(a, b), x) for x in range(4)] == [apply(a, apply(b, x)) for x in range(4)] for a, b in pairs)
reverses = all(transpose(f2mul(a, b), 2) == f2mul(transpose(b, 2), transpose(a, 2)) for a, b in pairs)
sizes = all(sorted(transpose(r, n) for r in matrices(n, m)) == sorted(matrices(m, n))
            for n in range(3) for m in range(3))
dets = [f2det(r) for r in matrices(2, 2)]                # the determinant: a functor to {0, 1} under times
functor = all(f2det(f2mul(a, b)) == f2det(a) * f2det(b) for a, b in pairs)
print(f"mistake, the determinant as a functor to 0 and 1 under times: keeps all {len(pairs)} products: {yn(functor)}; "
      f"{len(dets)} arrows 2 -> 2 become {len(set(dets))}, {dets.count(1)} with determinant 1, so not faithful")
print(f"product of matrices = maps run in turn, all {len(pairs)} pairs: {yn(keeps)}")
print(f"transpose matches Hom(n, m) with Hom(m, n) on all 9 pairs: {yn(sizes)}; reverses all {len(pairs)} products: {yn(reverses)}")
subsets = [s for s in range(16) if ones(s) == 2]
print(f"finite sets: 2-element subsets of 0, 1, 2, 3: {len(subsets)}; functions 2 -> 3: {len([(a, b) for a in range(3) for b in range(3)])}")
assert by_matrix == by_values == [5, 8]                    # matrix against values
assert matvec(ED, p)[0] == slope(p, 2) == 21               # product matrix = composite
assert back == [float(v) for v in by_matrix] and new == [6.5, -1.5]
assert all_same and total == 31                            # search against 2^(mn)
assert len(planes) == formula == 7 and all(onto[s] == len(invertible) == 6 for s in planes)
assert len(lines) == 3 and not reached and keeps and reverses and sizes
assert functor and len(set(dets)) == 2 and dets.count(1) == len(invertible)   # full but not faithful
print("ALL CHECKS PASS")
