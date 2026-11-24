# Jordan form -- the check behind the card.  Nothing is imported.  Ranks of the
# powers of N = A - 2I give the block sizes; the longest Jordan chain gives them again.
# A^10 four ways: A times itself, P J^10 P^-1 with J^10 by blocks, 2^10 I + 10 x 2^9 N, the cultures.
A = [[3, 1, 0], [-1, 1, 0], [0, 0, 2]]
L, n, R = 2, 10, range(3)
I = [[int(i == j) for j in R] for i in R]

def mul(X, Y): return [[sum(X[i][k] * Y[k][j] for k in R) for j in R] for i in R]
def power(X, k): return I if k == 0 else mul(power(X, k - 1), X)   # k multiplies
def apply(X, v): return [sum(X[i][k] * v[k] for k in R) for i in R]
def life(v): return next((k for k in range(4) if not any(apply(power(N, k), v))), 4)   # first k with N^k v = 0
def rank(X):                         # whole-number elimination, no fractions
    M, r = [row[:] for row in X], 0
    for c in R:
        p = next((i for i in range(r, 3) if M[i][c]), None)
        if p is None: continue
        M[r], M[p] = M[p], M[r]
        for i in range(r + 1, 3): M[i] = [M[r][c] * M[i][j] - M[i][c] * M[r][j] for j in R]
        r += 1
    return r

N = [[A[i][j] - L * I[i][j] for j in R] for i in R]
minors = sum(A[i][i] * A[j][j] - A[i][j] * A[j][i] for i in R for j in R if i < j)
det = sum(A[0][j] * (A[1][(j + 1) % 3] * A[2][(j + 2) % 3] - A[1][(j + 2) % 3] * A[2][(j + 1) % 3]) for j in R)
ranks = [rank(power(N, k)) for k in range(4)]
at_least = [ranks[k] - ranks[k + 1] for k in range(3)] + [0]   # blocks of size > k
sizes = [k + 1 for k in (2, 1, 0) for _ in range(at_least[k] - at_least[k + 1])]
top = max(I, key=life)                                   # the basis vector with the longest chain
low, extra = apply(N, top), next((I[i] for i in R if not any(apply(N, I[i]))), [0, 0, 0])
lengths = [life(top)] + [1] * (3 - life(top))            # the other dimensions: lone eigenvectors
P = [[low[i], top[i], extra[i]] for i in R]
Pinv = [[0, -1, 0], [1, 1, 0], [0, 0, 1]]                 # by hand, checked below
J = mul(Pinv, mul(A, P))
road1, road2 = power(A, n), mul(P, mul([[L ** n, n * L ** (n - 1), 0], [0, L ** n, 0], [0, 0, L ** n]], Pinv))
road3 = [[L ** n * I[i][j] + n * L ** (n - 1) * N[i][j] for j in R] for i in R]
feed, main = 1, 0
for _ in range(n): main, feed = 2 * main + feed, 2 * feed   # each hour both double; main takes in the feeder's size
print(f"A = {A}; trace {sum(A[i][i] for i in R)}, 2 by 2 minors {minors}, det {det}: (x - 2)^3")
print(f"N = A - 2I = {N}")
print(f"ranks of N^0, N^1, N^2, N^3: {ranks}")
print(f"blocks of size at least 1, 2, 3: {at_least[:3]}; block sizes {sizes}")
print(f"independent eigenvectors: 3 - rank N = {3 - ranks[1]}")
print(f"chain: top {top} -> N top {low} -> 0; extra eigenvector {extra}")
print(f"chain lengths from the vectors: {lengths}")
print(f"P = {P}; P^-1 P = I: {'yes' if mul(Pinv, P) == I else 'no'}")
print(f"J = P^-1 A P = {J}")
print(f"road 1, A times itself {n} times: {road1}")
print(f"road 2, P J^{n} P^-1 with J^{n} from the block formula, same matrix: {'yes' if road2 == road1 else 'no'}")
print(f"road 3, 2^{n} I + {n} x 2^{n - 1} N, same matrix: {'yes' if road3 == road1 else 'no'}")
print(f"top-left: 2^{n} + {n} x 2^{n - 1} = {L ** n} + {n * L ** (n - 1)} = {road1[0][0]}")
print(f"cultures after {n} hours: feeder {feed}, main {main} = {n} batches of {L ** (n - 1)}, total {feed + main}")
print(f"terms of top-left, n = 0 to 6: {[power(A, k)[0][0] for k in range(7)]}")
print(f"mistake 1, each entry to the 10th power: 3^10 = {3 ** n}", f"mistake 2, the diagonal of J only: 2^10 = {L ** n}", sep="\n")
print(f"mistake 3, 2^10 in the extra term: 2^10 + 10 x 2^10 = {L ** n} + {n * L ** n} = {L ** n + n * L ** n}")
print(f"mistake 4, blocks counted as rank N: {ranks[1]} block, not {at_least[0]}")
assert (sum(A[i][i] for i in R), minors, det) == (3 * L, 3 * L * L, L ** 3)  # (x - 2)^3
assert sizes == lengths and mul(A, P) == mul(P, J)       # ranks against the chain
assert J == [[2, 1, 0], [0, 2, 0], [0, 0, 2]] and mul(Pinv, P) == I
assert road1 == road2 == road3 and road1[0][0] == 6144 == feed + main and road1[1][0] == -main   # A^10 four ways
print("ALL CHECKS PASS")
