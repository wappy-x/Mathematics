# Generalised eigenvectors -- the check behind the card.  Nothing is imported.  Road one: sizes of ker (A - lambda I)^k
# by elimination, in A's axes and in others.  Road two: multiplicities from traces.  Road three: Bezout projectors.  Road four: A^10 two ways.
A, n, v = [[2, 1, 0], [0, 2, 0], [0, 0, 3]], 3, (1, 1, 1)
I, Z = [[int(i == j) for j in range(n)] for i in range(n)], [[0] * n for _ in range(n)]
S, Si = [[1, 1, 1], [0, 1, 1], [1, 1, 2]], [[1, -1, 0], [1, 1, -1], [-1, 0, 1]]   # other axes, and their inverse
def mul(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(n)) for j in range(n)] for i in range(n)]
def add(X, Y, c=1): return [[X[i][j] + c * Y[i][j] for j in range(n)] for i in range(n)]
def act(X, v): return tuple(sum(X[i][k] * v[k] for k in range(n)) for i in range(n))
def shift(lam): return add(A, I, -lam)                       # A - lambda I
def mpow(X, k): return I if k == 0 else mul(mpow(X, k - 1), X)
def rank(X):                                # elimination that stays in whole numbers
    rows, r = [row[:] for row in X], 0
    for c in range(n):
        p = next((i for i in range(r, n) if rows[i][c]), None)
        if p is None: continue
        rows[r], rows[p] = rows[p], rows[r]
        for i in range(r + 1, n):
            rows[i] = [rows[r][c] * x - rows[i][c] * y for x, y in zip(rows[i], rows[r])]
        r += 1
    return r
def divide(c, r):                           # synthetic division by (t - r)
    q = [c[0]]
    for x in c[1:]: q.append(x + r * q[-1])
    return q[:-1], q[-1]
def mult(c, r):                             # how many times (t - r) divides
    m, (q, rem) = 0, divide(c, r)
    while rem == 0: m, c = m + 1, q; q, rem = divide(c, r)
    return m
def vec(v): return "(" + ", ".join(str(x) for x in v) + ")"
coef, M = [1], Z                            # det(tI - A) from traces of powers
for k in range(1, n + 1):
    M = add(mul(A, M), I, coef[-1])
    coef.append(-sum(mul(A, M)[i][i] for i in range(n)) // k)
roots = [r for r in range(-12, 13) if divide(coef, r)[1] == 0]
dims = {lam: [n - rank(mpow(shift(lam), k)) for k in (1, 2, 3)] for lam in roots}
P2, P3 = mul(add(I, A, -1), shift(3)), mpow(shift(2), 2)    # (1 - t)(t - 3) and (t - 2)^2
pA = [[sum(c * mpow(A, n - i)[r][s] for i, c in enumerate(coef)) for s in range(n)] for r in range(n)]
u, w, slow = act(P2, v), act(P3, v), act(mpow(A, 10), v)
fast = tuple(2**10 * a + 10 * 2**9 * b + 3**10 * c for a, b, c in zip(u, act(shift(2), u), w))
print(f"A = {A}; characteristic polynomial coefficients {coef}")
for lam in roots:
    print(f"eigenvalue {lam}: multiplicity {mult(coef, lam)}; dim ker (A - {lam}I)^k, k = 1, 2, 3: {dims[lam]}")
print(f"A - 2I sends (0, 1, 0) to {vec(act(shift(2), (0, 1, 0)))}, which it sends to {vec(act(shift(2), (1, 0, 0)))}")
print(f"A sends (1, 0, 0) to {vec(act(A, (1, 0, 0)))} and (0, 1, 0) to {vec(act(A, (0, 1, 0)))}")
print(f"A - 2I = {shift(2)}; (A - 2I)^2 = {P3}; A - 3I = {shift(3)}")
print(f"(1 - t)(t - 3) + (t - 2)^2 at t = 0..5: {[(1 - t) * (t - 3) + (t - 2)**2 for t in range(6)]}")
print(f"P2 = (I - A)(A - 3I) = {P2}")
print(f"P2 + P3 = {add(P2, P3)}; P2 P3 = {mul(P2, P3)}")
print(f"Cayley-Hamilton, p(A) = {pA}")
print(f"(1, 1, 1) = {vec(u)} + {vec(w)}; piece sizes {rank(P2)} + {rank(P3)} = {rank(P2) + rank(P3)}")
print(f"A^10 (1, 1, 1), ten multiplications: {vec(slow)}; by the pieces: {vec(fast)}")
print(f"mistake, eigenvectors only: {dims[2][0]} + {dims[3][0]} = {dims[2][0] + dims[3][0]} directions for {n}; whole chain added: {sum(dims[2][:2]) + dims[3][0]}")
print(f"mistake, powers as if diagonal: {vec(act(mpow([[2, 0, 0], [0, 2, 0], [0, 0, 3]], 10), v))}, missing 10 x 2^9 = {10 * 2**9}")
print(f"mistake, projector without the Bezout factor: {vec(act(shift(3), v))}, not {vec(u)}")
assert [dims[lam][-1] for lam in roots] == [mult(coef, lam) for lam in roots] == [2, 1]
assert add(P2, P3) == I and mul(P2, P3) == Z and pA == Z and rank(P2) == dims[2][-1]
assert all(act(P3, act(A, e)) == (0, 0, 0) for e in [(1, 0, 0), (0, 1, 0)])  # A keeps the plane
assert mul(S, Si) == I and all(n - rank(mul(mul(S, mpow(shift(l), k)), Si)) == dims[l][k - 1] for l in roots for k in (1, 2, 3))  # other axes
assert slow == fast and dims[2][0] < dims[2][1] == dims[2][2]
print("ALL CHECKS PASS")
