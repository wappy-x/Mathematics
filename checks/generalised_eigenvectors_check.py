# Generalised eigenvectors -- the check behind the card.  Nothing is imported.  A: one minute of a van's (position, speed, shown position).
# Road one: sizes of ker (A - lambda I)^k by elimination, in A's axes and others.  Two: multiplicities from traces.  Three: Bezout projectors.  Four: A^10 two ways.
A, n, v = [[1, 1, 0], [0, 1, 0], [1, 0, 0]], 3, (3, 1, 0)
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
P1, P0 = mul(add(add(I, I), A, -1), A), mpow(shift(1), 2)   # (2 - t) t and (t - 1)^2
pA = [[sum(c * mpow(A, n - i)[r][s] for i, c in enumerate(coef)) for s in range(n)] for r in range(n)]
u, w, slow = act(P1, v), act(P0, v), act(mpow(A, 10), v)
fast = tuple(1**10 * a + 10 * 1**9 * b + 0**10 * c for a, b, c in zip(u, act(shift(1), u), w))
print(f"A = {A}; characteristic polynomial coefficients {coef}")
for lam in roots:
    print(f"eigenvalue {lam}: multiplicity {mult(coef, lam)}; dim ker (A - {lam}I)^k, k = 1, 2, 3: {dims[lam]}")
print(f"A - I sends (1, 1, 0) to {vec(act(shift(1), (1, 1, 0)))}, which it sends to {vec(act(shift(1), (1, 0, 1)))}")
print(f"A sends (1, 0, 1) to {vec(act(A, (1, 0, 1)))} and (1, 1, 0) to {vec(act(A, (1, 1, 0)))}")
print(f"A - I = {shift(1)}; (A - I)^2 = {P0}; (A - I)^3 = {mpow(shift(1), 3)}")
print(f"(2 - t) t + (t - 1)^2 at t = 0..5: {[(2 - t) * t + (t - 1)**2 for t in range(6)]}")
print(f"P1 = (2I - A) A = {P1}")
print(f"P1 + P0 = {add(P1, P0)}; P1 P0 = {mul(P1, P0)}")
print(f"Cayley-Hamilton, p(A) = {pA}")
print(f"(3, 1, 0) = {vec(u)} + {vec(w)}; piece sizes {rank(P1)} + {rank(P0)} = {rank(P1) + rank(P0)}")
print(f"A^10 (3, 1, 0), ten multiplications: {vec(slow)}; by the pieces: {vec(fast)}")
print(f"mistake, eigenvectors only: {dims[1][0]} + {dims[0][0]} = {dims[1][0] + dims[0][0]} directions for {n}; whole chain added: {sum(dims[1][:2]) + dims[0][0]}")
print(f"mistake, powers as if diagonal: {vec(u)}, missing 10 x {vec(act(shift(1), u))}")
print(f"mistake, projector without the Bezout factor: {vec(act(A, v))}, not {vec(u)}")
assert [dims[lam][-1] for lam in roots] == [mult(coef, lam) for lam in roots] == [1, 2]
assert add(P1, P0) == I and mul(P1, P0) == Z and pA == Z and rank(P1) == dims[1][-1]
assert all(act(P0, act(A, e)) == (0, 0, 0) for e in [(1, 0, 1), (1, 1, 0)])  # A keeps the plane
assert mul(S, Si) == I and all(n - rank(mul(mul(S, mpow(shift(l), k)), Si)) == dims[l][k - 1] for l in roots for k in (1, 2, 3))  # other axes
assert slow == fast and dims[1][0] < dims[1][1] == dims[1][2]
print("ALL CHECKS PASS")
