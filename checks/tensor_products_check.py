# Tensor products -- the check behind the card.  Nothing is imported.  V holds
# week counts (2 weeks), W holds shopping lists (3 goods), and a tensor in
# V (x) W is a 2-by-3 table: how many of each good were bought each week.
def tensor(v, w):                          # v (x) w: every entry of v times every entry of w
    return [[a * b for b in w] for a in v]

def rank(rows):                            # road one: count pivots, whole numbers only
    rows, r = [list(x) for x in rows], 0
    for c in range(len(rows[0])):
        p = next((i for i in range(r, len(rows)) if rows[i][c]), None)
        if p is None: continue
        rows[r], rows[p] = rows[p], rows[r]
        for i in range(len(rows)):
            if i != r: rows[i] = [rows[i][k] * rows[r][c] - rows[r][k] * rows[i][c] for k in range(len(rows[0]))]
        r += 1
    return r

def minors(t):                             # road two: every 2-by-2 cross-difference
    return [t[0][j] * t[1][k] - t[0][k] * t[1][j] for j in range(3) for k in range(j + 1, 3)]

def kron(a, b):                            # the Kronecker product, block by block
    return [[x * y for x in ra for y in rb] for ra in a for rb in b]
def mat(a, v): return [sum(x * y for x, y in zip(r, v)) for r in a]
def flat(t): return [x for r in t for x in r]

e, f = [[1, 0], [0, 1]], [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
v, w, P = [1, 2], [3, 0, 1], [[3, 2, 4], [3, 2, 5]]       # P: each week's prices, in dollars
T = tensor(v, w)
S = [[x + y for x, y in zip(r, q)] for r, q in zip(tensor(e[0], f[0]), tensor(e[1], f[1]))]
basis = [flat(tensor(a, b)) for a in e for b in f]
g = range(-3, 4)
found = lambda t: [(a, b, c, d, h) for a in g for b in g for c in g for d in g for h in g if tensor([a, b], [c, d, h]) == t]
tables = [[[n // 3 ** (3 * i + j) % 3 for j in range(3)] for i in range(2)] for n in range(3 ** 6)]
simple = sum(rank(t) <= 1 for t in tables)
beta = lambda x, y: sum(P[i][j] * x[i] * y[j] for i in range(2) for j in range(3))   # bill of a pair
L = lambda t: sum(P[i][j] * t[i][j] for i in range(2) for j in range(3))           # bill of a table
A, B = [[1, 0], [1, 1]], [[1, 0, 0], [0, 1, 0], [0, 0, 12]]   # running totals; dozens to eggs
K = kron(A, B)
via_k, via_sides = mat(K, flat(T)), flat(tensor(mat(A, v), mat(B, w)))
q = [[0.5 ** 0.5 * x for x in r] for r in e]                 # two qubits: amplitude 1/sqrt 2 twice
print(f"basis tables e_i (x) f_j: {len(basis)}; their rank: {rank(basis)}; 2 x 3 = {2 * 3}")
print(f"(1, 2) (x) (3, 0, 1) = {T}; rank {rank(T)}; minors {minors(T)}")
print(f"e1 (x) f1 + e2 (x) f2 = {S}; rank {rank(S)}; minors {minors(S)}")
print(f"product search, entries -3 to 3: first table {len(found(T))} ways, second {len(found(S))}")
print(f"tables with entries 0, 1, 2: {len(tables)}; simple (rank 0 or 1): {simple}")
print(f"basis bills beta(e_i, f_j): {[[beta(a, b) for b in f] for a in e]}")
print(f"bill from the pair: {beta(v, w)}; from the table: {L(T)} (weeks {L(T[:1] + [[0] * 3])}, {L([[0] * 3] + T[1:])}); second table: {L(S)}")
print(f"A (x) B is {len(K)} x {len(K[0])}; times the flat table: {via_k}")
print(f"(Av) (x) (Bw) = {mat(A, v)} (x) {mat(B, w)} -> {via_sides}")
print(f"qubit pair (e1 (x) e1 + e2 (x) e2)/sqrt 2: product test {q[0][0] * q[1][1] - q[0][1] * q[1][0]:.4f}, rank {rank(e)}")
print(f"mistake 1, dimension as 2 + 3: {2 + 3}, not {len(basis)}")
print(f"mistake 2, (e1 + e2) (x) (f1 + f2) = {tensor([1, 1], [1, 1, 0])}, rank {rank(tensor([1, 1], [1, 1, 0]))}")
print(f"mistake 3, B (x) A in place of A (x) B: {mat(kron(B, A), flat(T))}")
assert rank(basis) == len(basis) == 2 * 3                     # dimension mn, two roads
assert rank(T) == 1 and minors(T) == [0, 0, 0] and len(found(T)) > 0
assert rank(S) == 2 and minors(S)[0] != 0 and found(S) == []  # no product in the search
assert simple == sum(all(m == 0 for m in minors(t)) for t in tables)
assert beta(v, w) == L(T) == 41
assert via_k == via_sides == flat([[3, 0, 12], [9, 0, 36]])
print("ALL CHECKS PASS")
