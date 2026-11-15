# Neumann series -- the check behind the card.  Standard library only.
# A sheet with a weak circular reference: three support departments whose
# full costs depend on each other, x = b + Kx, in pounds a month.
# Road 1 repeats K and adds up (the Neumann series).  Road 2 solves
# (I - K)x = b by elimination.  Road 3 is an invariant: every pound of
# direct cost is charged out exactly once.  Then the same series on a blur.
import math

def matvec(A, v):
    return [sum(a * t for a, t in zip(row, v)) for row in A]

def size(v):                                   # worst-case size of a list
    return max(abs(t) for t in v)

def opnorm(A):                                 # largest row sum: the most K can stretch
    return max(sum(abs(a) for a in row) for row in A)

def neumann(A, b, n):                          # b + Ab + ... + A^(n-1) b: n rounds
    s, term = [0.0] * len(b), list(b)
    for _ in range(n):
        s = [t + u for t, u in zip(s, term)]
        term = matvec(A, term)
    return s

def solve(A, b):                               # (I - A)x = b by elimination, row swaps
    n = len(b)
    M = [[(1.0 if i == j else 0.0) - A[i][j] for j in range(n)] + [b[i]] for i in range(n)]
    for c in range(n):
        p = c
        for r in range(c + 1, n):
            if abs(M[r][c]) > abs(M[p][c]):
                p = r
        M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            for k in range(c, n + 1):
                M[r][k] -= f * M[c][k]
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        x[r] = (M[r][n] - sum(M[r][k] * x[k] for k in range(r + 1, n))) / M[r][r]
    return x

def rounds_for(q, nb, tol):                    # first n with q^n / (1 - q) * |b| <= tol
    n = 0
    while q ** n / (1 - q) * nb > tol:
        n += 1
    return n

def f2(v, d=2):
    return ", ".join(f"{t:.{d}f}" for t in v)

def yn(claim):
    return "yes" if claim else "no"

K = [[0.0, 0.10, 0.20], [0.15, 0.0, 0.10], [0.05, 0.10, 0.0]]   # rows: IT, HR, Facilities
b = [40000.0, 20000.0, 30000.0]
q, nb = opnorm(K), size(b)
x = solve(K, b)
print(f"sheet: row sums {f2([sum(r) for r in K])}; q = {q:.2f}; |b| = {nb:.2f}")
print(f"road 2, elimination: IT {x[0]:.2f}, HR {x[1]:.2f}, Facilities {x[2]:.2f}")
Kb = matvec(K, b)
print(f"Kb = {f2(Kb)}; K^2 b = {f2(matvec(K, Kb))}")
errs = [size([s - t for s, t in zip(neumann(K, b, n), x)]) for n in range(13)]
bnds = [q ** n / (1 - q) * nb for n in range(13)]
print(f"S_3 = {f2(neumann(K, b, 3))}; true error {errs[3]:.2f}; bound {bnds[3]:.2f}")
print("chart n = 0..12, log10 true error:", ", ".join(f"{math.log10(e):.2f}" for e in errs))
print("chart n = 0..12, log10 bound:     ", ", ".join(f"{math.log10(e):.2f}" for e in bnds))
first_true = min(n for n in range(13) if errs[n] < 1)
print(f"rounds for 1 pound: promised by the bound {rounds_for(q, nb, 1.0)}; needed in fact {first_true}")
v, ip = [0.0] * 3, [size(x)]                    # a sheet updating its cells in place, top to bottom
for _ in range(12):
    for i in range(3):
        v[i] = b[i] + sum(K[i][j] * v[j] for j in range(3))
    ip.append(size([s - t for s, t in zip(v, x)]))
print(f"in place (Gauss-Seidel): worst error after rounds 1-5 {f2(ip[1:6])}; "
      f"first under 1 pound at round {min(n for n in range(13) if ip[n] < 1)}")
s30 = neumann(K, b, 30)
print(f"road 1, 30 rounds: {f2(s30)}; gap to road 2 below 1e-6: {yn(size([s - t for s, t in zip(s30, x)]) < 1e-6)}")
charged = sum((1 - sum(K[i][j] for i in range(3))) * x[j] for j in range(3))
print(f"road 3, charged out to the earning departments: {charged:.2f} of {sum(b):.2f}")
print(f"residual |x - b - Kx| below 1e-9: {yn(size([x[i] - b[i] - t for i, t in enumerate(matvec(K, x))]) < 1e-9)}")
print(f"size of the answer {size(x):.2f}; inverse bound |b| / (1 - q) = {nb / (1 - q):.2f}")
K2 = [[0.0, 2.0], [0.1, 0.0]]                   # norm 2, yet K2 squared = 0.2 I
y2, s2 = solve(K2, [1.0, 1.0]), neumann(K2, [1.0, 1.0], 60)
print(f"norm above 1, series still converges: q = {opnorm(K2):.2f}; 60 rounds {f2(s2, 4)}; elimination {f2(y2, 4)}")
L = [[0.0, 1.25], [0.9, 0.0]]                   # A = 100 + 1.25 B, B = 0.9 A
print(f"mistake 1, loop gain {L[0][1] * L[1][0]:.3f}: A after 10 rounds {neumann(L, [100.0, 0.0], 10)[0]:.2f}, "
      f"after 20 {neumann(L, [100.0, 0.0], 20)[0]:.2f}; elimination gives A = {solve(L, [100.0, 0.0])[0]:.2f}")
one, n = [[0.9]], 1                              # x = 100 + 0.9x, truth 1000
while 100 * 0.9 ** (n - 1) >= 1:                 # stop once a round changes x by under 1 pound
    n += 1
err9 = 1000 - neumann(one, [100.0], n)[0]
print(f"mistake 2, q = 0.9, stop when the change is under 1 pound: round {n}, true error {err9:.2f}")
print(f"mistake 3, bound without 1/(1 - q): {0.9 ** n * 100:.2f}, below the true error {err9:.2f}")
print(f"mistake 4, q = 0.99, the sheet's 100-round cap: {neumann([[0.99]], [100.0], 100)[0]:.2f} of 10000.00")
xd = solve([[2 * a for a in r] for r in K], b)
print(f"try: shares doubled, q = {2 * q:.2f}; rounds for 1 pound by the bound {rounds_for(2 * q, nb, 1.0)}; IT {xd[0]:.2f}")
exact, mids = 1 / math.cos(1), []              # blur: x(s) = 1 + 4 * integral of G(s, t) x(t) dt
for N in (3, 9, 27, 81, 243):
    s = [(i + 0.5) / N for i in range(N)]
    A = [[4.0 * min(u, v) * (1 - max(u, v)) / N for v in s] for u in s]
    ser, el = neumann(A, [1.0] * N, 40)[N // 2], solve(A, [1.0] * N)[N // 2]
    mids.append(ser)
    print(f"blur N = {N:3d}: q_N = {opnorm(A):.6f}; rounds for 1e-6 {rounds_for(opnorm(A), 1.0, 1e-6)}; "
          f"x(1/2) {ser:.8f}; minus 1/cos 1 = {ser - exact:.8f}; series = elimination: {yn(abs(ser - el) < 1e-9)}")
print(f"library: 1/cos 1 = {exact:.8f}")
print(f"limits: q = 4 x 1/8 = {4 / 8:.6f}; c = 8 gives 8 / pi^2 = {8 / (math.pi * math.pi):.4f}, below 1")
s81 = [(i + 0.5) / 81 for i in range(81)]
A8 = [[8.0 * min(u, v) * (1 - max(u, v)) / 81 for v in s81] for u in s81]
print(f"try: c = 8, N = 81: q_N = {opnorm(A8):.4f}; x(1/2) after 300 rounds "
      f"{neumann(A8, [1.0] * 81, 300)[40]:.6f}; elimination {solve(A8, [1.0] * 81)[40]:.6f}")
assert size([s - t for s, t in zip(s30, x)]) < 1e-6           # road 1 meets road 2
assert abs(charged - sum(b)) < 1e-6                           # road 3: 90000 charged out
assert all(errs[n] <= bnds[n] for n in range(13))             # the bound holds every round
assert all(ip[n] <= bnds[n] for n in range(13))               # and for the in-place sheet
assert size([s - t for s, t in zip(v, x)]) < 1e-6             # which settles on road 2 too
assert size([s - t for s, t in zip(s2, y2)]) < 1e-9           # series meets elimination
assert opnorm(K2) > 1                                         # though the norm test fails
assert abs(neumann(L, [100.0, 0.0], 20)[0]) > 1000 and abs(solve(L, [100.0, 0.0])[0] + 800) < 1e-9
assert n == math.ceil(1 + math.log(0.01) / math.log(0.9))     # stop round, closed form
assert abs(err9 - 1000 * 0.9 ** n) < 1e-9                     # true error 1000 x 0.9^n
assert abs(mids[-1] - exact) < 3e-5                           # grid meets 1/cos 1
assert all(8 < (mids[i] - exact) / (mids[i + 1] - exact) < 10 for i in range(4))  # error / 9 per step
print("ALL CHECKS PASS")
