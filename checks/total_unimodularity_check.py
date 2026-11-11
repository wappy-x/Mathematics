# Total unimodularity -- the check behind the card. Standard library only.
# Six acts, six slots. The LP relaxation (fractions allowed), solved by exact-fraction
# simplex, comes out whole. Roads: simplex; all 720 whole plans; the dual prices as
# a certificate; and the determinants of the constraint matrix itself.
from fractions import Fraction as F
from itertools import combinations, permutations, product

ACTS = ["Headliner", "Rock band", "DJ", "Folk trio", "Brass band", "Singer"]
SLOTS = ["Fri main", "Sat main", "Sun main", "Fri late tent", "Sat tent", "Sun tent"]
VALUE = [[48, 60, 30, 20, 25, 22], [40, 45, 28, 22, 30, 26], [30, 35, 15, 38, 24, 18],
         [18, 20, 26, 12, 22, 24], [15, 18, 25, 10, 20, 21], [20, 22, 24, 14, 21, 25]]
FEE = [40, 25, 15, 8, 6, 7]                     # booking fees, pounds thousand
N = 6

def assignment_matrix(n):                       # n act rows, then n slot rows
    return ([[int(k // n == i) for k in range(n * n)] for i in range(n)] +
            [[int(k % n == j) for k in range(n * n)] for j in range(n)])

def det(M):                                     # fraction-free elimination
    M, sign, prev = [r[:] for r in M], 1, 1
    for k in range(len(M) - 1):
        p = next((i for i in range(k, len(M)) if M[i][k]), None)
        if p is None:
            return 0
        if p != k:
            M[k], M[p], sign = M[p], M[k], -sign
        for i in range(k + 1, len(M)):
            for j in range(k + 1, len(M)):
                M[i][j] = (M[i][j] * M[k][k] - M[i][k] * M[k][j]) // prev
        prev = M[k][k]
    return sign * M[-1][-1]

def simplex(A, b, c):
    """max c.x with A x <= b, x >= 0, b >= 0; tableau in exact fractions, Bland's rule."""
    m, n = len(A), len(A[0])
    full = [A[i] + [int(i == r) for r in range(m)] for i in range(m)]   # [A | I]
    T = [[F(v) for v in full[i]] + [F(b[i])] for i in range(m)]
    z = [F(-v) for v in c] + [F(0)] * (m + 1)
    basis, pivots, whole, unit = [n + i for i in range(m)], 0, True, True
    while True:
        e = next((j for j in range(n + m) if z[j] < 0), None)
        if e is None:
            break
        r = min((i for i in range(m) if T[i][e] > 0), key=lambda i: (T[i][-1] / T[i][e], basis[i]))
        T[r] = [v / T[r][e] for v in T[r]]
        for row in [t for i, t in enumerate(T) if i != r] + [z]:
            f = row[e]
            row[:] = [a - f * p for a, p in zip(row, T[r])]
        basis[r], pivots = e, pivots + 1
        whole &= all(t[-1].denominator == 1 for t in T)
        unit &= abs(det([[full[i][j] for j in basis] for i in range(m)])) == 1
    x = [F(0)] * (n + m)
    for i, j in enumerate(basis): x[j] = T[i][-1]
    return x[:n], z[-1], z[n:n + m], pivots, whole, unit

def show(q): return str(q) if q.denominator == 1 else f"{q} = {float(q):g}"

print("slots:", ", ".join(SLOTS))
for i in range(N):
    print(f"{ACTS[i]:<11} fee {FEE[i]:>2}, values", *VALUE[i])
A = assignment_matrix(N)
c = [VALUE[k // N][k % N] for k in range(N * N)]
x, val, y, piv, whole, unit = simplex(A, [1] * 2 * N, c)
print(f"LP relaxation by simplex: {piv} pivots from the empty plan, value {show(val)}")
print("every corner on the way whole:", "yes" if whole else "no",
      "| every basis determinant +1 or -1:", "yes" if unit else "no")
plan = [(k // N, k % N) for k in range(N * N) if x[k]]
for i, j in plan:
    print(f"  {ACTS[i]:<11} -> {SLOTS[j]:<14} x = {x[i * N + j]}  value {VALUE[i][j]}")
totals = sorted((sum(VALUE[i][p[i]] for i in range(N)), p) for p in permutations(range(N)))
print(f"all {len(totals)} whole plans: best {totals[-1][0]}, runner-up {totals[-2][0]}, worst {totals[0][0]}")
u, v = y[:N], y[N:]
print("dual prices, acts: ", *u, "| slots:", *v, "| total", sum(y))
dual_ok = all(u[i] + v[j] >= VALUE[i][j] for i in range(N) for j in range(N)) and min(y) >= 0
print("every act price + slot price >= that pair's value:", "yes" if dual_ok else "no")
print("price checks:", "; ".join(f"{ACTS[i]} + {SLOTS[j]} {u[i]} + {v[j]} >= {VALUE[i][j]}" for i, j in [(0, 1), (1, 1)]))
assert all(q in (0, 1) for q in x) and len(plan) == N            # the LP answer is whole
assert val == totals[-1][0] == sum(y) and dual_ok and totals[-2][0] < val
assert whole and unit and totals[-1][1] == tuple(j for _, j in plan)

# ---- the matrix itself ----
cols_ok = all(sorted(i for i in range(2 * N) if A[i][k]) in ([k // N, N + k % N],) for k in range(N * N))
print(f"table A: {len(A)} rows x {len(A[0])} columns, plus {len(A)} slack columns;",
      "each column has one 1 in an act row and one in a slot row:", "yes" if cols_ok else "no")
A3, count = assignment_matrix(3), {}
for s in range(1, 7):
    for R in combinations(range(6), s):
        for C in combinations(range(9), s):
            d = det([[A3[i][j] for j in C] for i in R])
            count[d] = count.get(d, 0) + 1
print(f"3 acts x 3 slots: {sum(count.values())} square submatrices; determinants",
      ", ".join(f"{d}: {count[d]}" for d in sorted(count)))
assert cols_ok and set(count) == {-1, 0, 1} and sum(count.values()) == 5004

# ---- what breaks ----
TRI = [[1, 0, 1], [1, 1, 0], [0, 1, 1]]         # duets: rows Folk, Brass, Singer
xt, vt, _, _, _, _ = simplex(TRI, [1, 1, 1], [1, 1, 1])
best_t = max(sum(s) for s in product((0, 1), repeat=3) if all(sum(map(int.__mul__, r, s)) <= 1 for r in TRI))
cram = [det([[1 if j == k else r[j] for j in range(3)] for r in TRI]) for k in range(3)]   # B_k: column k -> b
print(f"duet triangle: determinant {det(TRI)}, Cramer det(B_k) {' '.join(map(str, cram))}, LP x = {' '.join(map(str, xt))}, value {show(vt)}, best whole {best_t}")
assert det(TRI) == 2 and vt == F(3, 2) and best_t == 1 and xt == [F(d, det(TRI)) for d in cram]

def budget_case(B):
    xb, vb, _, _, _, _ = simplex(A + [[FEE[k // N] for k in range(N * N)]], [1] * 2 * N + [B], c)
    best = [0, 0]
    def search(i, used, spent, got):
        if i == N:
            best[0], best[1] = max(best[0], got), best[1] + 1
            return
        search(i + 1, used, spent, got)
        for j in range(N):
            if j not in used and spent + FEE[i] <= B:
                search(i + 1, used | {j}, spent + FEE[i], got + VALUE[i][j])
    search(0, frozenset(), 0, 0)
    return xb, vb, best

xb, vb, (bw, nplans) = budget_case(80)
frac = [f"{ACTS[k // N]}/{SLOTS[k % N]} {q}" for k, q in enumerate(xb) if q.denominator > 1]
print(f"budget 80: LP value {show(vb)}; fractional: {'; '.join(frac)}")
rnd = [k for k, q in enumerate(xb) if q > F(1, 2)]
r_val, r_fee = sum(c[k] for k in rnd), sum(FEE[k // N] for k in rnd)
print(f"budget 80: best whole {bw} over {nplans} plans within budget; LP rounded to nearest {r_val} (fees {r_fee})")
assert frac and r_val < bw < vb and r_fee <= 80 and vb == F(1449, 8)

# ---- try changing ----
c2 = c[:]; c2[4 * N + 2] = 15                    # Brass on Sun main worth 15, not 25
x2, v2, _, _, _, _ = simplex(A, [1] * 2 * N, c2)
x3, v3, _ = budget_case(101)
x4, v4, _, _, _, _ = simplex(A, [1] * N + [1, 2] + [1] * 4, c)   # Sat main takes a double bill
c5 = c[:]; c5[5 * N + 4] = 23                   # Singer on Sat tent worth 23: a tie
x5, v5, _, _, _, _ = simplex(A, [1] * 2 * N, c5)
ties = [p for p in permutations(range(N)) if sum(c5[i * N + p[i]] for i in range(N)) == v5]
mid = [F(sum(p[k // N] == k % N for p in ties), len(ties)) for k in range(N * N)]   # halfway point
mval, room = sum(a * m for a, m in zip(c5, mid)), max(sum(a * m for a, m in zip(r, mid)) for r in A)
for name, xx, vv in [("Brass/Sun main 15", x2, v2), ("budget 101", x3, v3),
                     ("Sat main double bill", x4, v4), ("Singer/Sat tent 23", x5, v5)]:
    print(f"try {name}: LP value {show(vv)}, whole: {'yes' if all(q in (0, 1) for q in xx) else 'no'}")
print(f"try Singer/Sat tent 23: {len(ties)} whole plans tie at {v5}; halfway between them: {mid.count(F(1, 2))} x values at 1/2, value {mval}, fullest row {room}")
assert all(q in (0, 1) for q in x2 + x4 + x5) and v3 == val and len(ties) == 2 and mval == v5 and F(1, 2) in mid and room == 1
print("ALL CHECKS PASS")
