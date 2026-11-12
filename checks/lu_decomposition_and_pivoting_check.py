# LU with partial pivoting on a small water network, solved for six demand patterns.
# Standard library only. Every number on the card is printed here.
import math
# Unknowns: heads h1, h2 (m) at junctions J1, J2; flows q1, q2, q3 (L/s) in pipes
# pipe 1 (reservoir to J1), pipe 2 (J1 to J2), pipe 3 (reservoir to J2). Rows: J1, J2, pipes 1 to 3.
H, R1, R2, R3 = 60.0, 0.1, 0.3, 0.4           # reservoir head; pipe resistances, m per L/s (illustrative)
ROWS = ["J1", "J2", "pipe 1", "pipe 2", "pipe 3"]
PATTERNS = [("night", 8.0, 12.0), ("morning", 20.0, 30.0), ("midday", 12.0, 18.0),
            ("evening", 24.0, 36.0), ("weekend", 16.0, 20.0), ("fire at J2", 12.0, 50.0)]

def sci(x): m, e = f"{x:.2e}".split("e"); return f"{m}e{int(e)}"

def network(leak):                            # leak: L/s lost per metre of head at each junction
    return [[-leak, 0.0, 1.0, -1.0, 0.0], [0.0, -leak, 0.0, 1.0, 1.0],
            [1.0, 0.0, R1, 0.0, 0.0], [-1.0, 1.0, 0.0, R2, 0.0], [0.0, 1.0, 0.0, 0.0, R3]]

def rhs(d1, d2): return [d1, d2, H, 0.0, H]

def lu(A, pivot=True):                        # returns packed L and U, row order, growth, flops, swaps
    n = len(A); W = [row[:] for row in A]; perm = list(range(n))
    amax = max(abs(v) for row in A for v in row); big, flops, swaps = amax, 0, 0
    for k in range(n):
        if pivot:
            m = max(range(k, n), key=lambda i: abs(W[i][k]))   # first largest |entry| in column k
            if m != k:
                W[k], W[m] = W[m], W[k]; perm[k], perm[m] = perm[m], perm[k]; swaps += 1
        if W[k][k] == 0.0: return None, perm, k + 1, flops, swaps   # zero pivot: step k+1 fails
        for i in range(k + 1, n):
            W[i][k] /= W[k][k]; flops += 1    # the multiplier, stored where the zero would go
            for j in range(k + 1, n):
                W[i][j] -= W[i][k] * W[k][j]; flops += 2
                big = max(big, abs(W[i][j]))
    return W, perm, big / amax, flops, swaps

def solve(LU, perm, b):                       # forward Ly = Pb, then back Ux = y
    n, flops = len(b), 0; y = [b[p] for p in perm]
    for i in range(n):
        for j in range(i): y[i] -= LU[i][j] * y[j]; flops += 2
    for i in reversed(range(n)):
        for j in range(i + 1, n): y[i] -= LU[i][j] * y[j]; flops += 2
        y[i] /= LU[i][i]; flops += 1
    return y, flops

def nodal(leak, d1, d2):                      # road 2: flows written from heads, 2 by 2 Cramer
    c1, c2, c3 = 1 / R1, 1 / R2, 1 / R3
    a, b_, c, d = c1 + c2 + leak, -c2, -c2, c2 + c3 + leak
    e, f = c1 * H - d1, c3 * H - d2
    h1 = (e * d - b_ * f) / (a * d - b_ * c); h2 = (a * f - c * e) / (a * d - b_ * c)
    return [h1, h2, (H - h1) / R1, (h1 - h2) / R2, (H - h2) / R3]

def loop(d1, d2):                             # road 3, no leak: one loop, head losses balance
    q2 = (R3 * d2 - R1 * d1) / (R1 + R2 + R3); q1, q3 = d1 + q2, d2 - q2
    return [H - R1 * q1, H - R3 * q3, q1, q2, q3]

def det(M):                                   # cofactor expansion, for the determinant check
    if len(M) == 1: return M[0][0]
    return sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M)) if M[0][j] != 0)

def matvec(A, x): return [sum(a * v for a, v in zip(row, x)) for row in A]
def inf(v): return max(abs(t) for t in v)
def err(x, y): return max(abs(a - b) for a, b in zip(x, y))

A = network(0.0); n = len(A)
LU, perm, growth, f_lu, swaps = lu(A)
print("row order after pivoting   " + ", ".join(ROWS[p] for p in perm) + f"   swaps {swaps}")
for i in range(n):
    L = [LU[i][j] if j < i else (1.0 if j == i else 0.0) for j in range(n)]
    U = [LU[i][j] if j >= i else 0.0 for j in range(n)]
    print(f"L{i + 1} " + "".join(f"{v + 0.0:6.2f}" for v in L) + "    U" + f"{i + 1} " + "".join(f"{v + 0.0:6.2f}" for v in U))
dU = math.prod(LU[k][k] for k in range(n))
print(f"det A = (-1)^{swaps} x product of pivots = {(-1) ** swaps * dU:.4f}   cofactor {det(A):.4f}   growth {growth:.2f}")
assert abs((-1) ** swaps * dU - det(A)) < 1e-12, "PA = LU determinant against cofactor expansion"
PA = [A[p] for p in perm]
LUprod = [[sum((LU[i][k] if k < i else 1.0 if k == i else 0.0) * (LU[k][j] if k <= j else 0.0) for k in range(n)) for j in range(n)] for i in range(n)]
assert err(sum(PA, []), sum(LUprod, [])) < 1e-15, "L times U must rebuild PA"
assert lu([[1.0, 2.0], [-3.0, 4.0]])[1] == [1, 0], "pivot by size: the -3 below the 1 is chosen"

print(f"{'pattern':<11}{'d1':>5}{'d2':>5}{'h1 m':>8}{'h2 m':>8}{'q1':>7}{'q2':>7}{'q3':>7}   vs nodal   vs loop")
f_solve = 0
for name, d1, d2 in PATTERNS:
    x, f_solve = solve(LU, perm, rhs(d1, d2))
    e2, e3 = err(x, nodal(0.0, d1, d2)), err(x, loop(d1, d2))
    print(f"{name:<11}{d1:5.0f}{d2:5.0f}{x[0]:8.2f}{x[1]:8.2f}{x[2]:7.2f}{x[3]:7.2f}{x[4]:7.2f}   {sci(e2)}  {sci(e3)}")
    assert e2 < 1e-12 and e3 < 1e-12, "LU against the nodal and loop roads"
    assert inf([bi - ai for bi, ai in zip(rhs(d1, d2), matvec(A, x))]) < 1e-12, "residual"

xm = solve(LU, perm, rhs(20.0, 30.0))[0]
print("morning y = Ux: " + " ".join(f"{sum(LU[i][j] * xm[j] for j in range(i, n)):.2f}" for i in range(n)))
E = lambda n: (4 * n**3 + 9 * n**2 - 7 * n) // 6          # whole solve, from the operation-counts card
F = lambda n: (4 * n**3 - 3 * n**2 - n) // 6              # factor only
S = lambda n: 2 * n * n - n                               # one forward and back substitution
assert (f_lu, f_solve) == (F(n), S(n)), "counted flops against the formulas"
print(f"flops n = 5: factor {f_lu} (formula {F(5)}), each solve {f_solve} (formula {S(5)}); six patterns: reuse {F(5) + 6 * S(5)}, refactor {6 * E(5)}")
N = 500; inv = F(N) + N * S(N)
print(f"flops n = 500: factor {F(N):,}, each solve {S(N):,}; six patterns: reuse {F(N) + 6 * S(N):,}, refactor {6 * E(N):,}, ratio {6 * E(N) / (F(N) + 6 * S(N)):.2f}")
print(f"flops n = 500: inverse first {inv:,}, {inv / F(N):.2f} times the factorisation; one more pattern costs {S(N) / F(N) * 100:.2f}% of it")

Ainv = [solve(LU, perm, [1.0 if i == j else 0.0 for i in range(n)])[0] for j in range(n)]
kappa = inf([sum(abs(v) for v in row) for row in A]) * max(sum(abs(Ainv[j][i]) for j in range(n)) for i in range(n))
print(f"kappa_inf(A) = {kappa:.2f}")

def trial(leak, pivot, d=(20.0, 30.0)):       # error and backward error for the morning pattern
    A = network(leak); b = rhs(*d); LU, perm, g, _, _ = lu(A, pivot)
    if LU is None: return None
    x = solve(LU, perm, b)[0]; r = [bi - ai for bi, ai in zip(b, matvec(A, x))]
    eta = inf(r) / (inf([sum(abs(v) for v in row) for row in A]) * inf(x))
    return x, err(x, nodal(leak, *d)), g, eta
_, _, step, _, _ = lu(A, False)
print(f"no pivoting, no leak: zero pivot at step {step}")
for piv in (False, True):
    x, e, g, eta = trial(1e-14, piv)
    print(f"leak 1e-14, pivoting {'on ' if piv else 'off'}: q1 {x[2]:.6f}  vs nodal {sci(e)}  growth {sci(g)}  backward error {sci(eta)}")
    assert (e < 1e-12) == piv, "pivoting fixes it"
    if not piv:
        print(f"  relative error {sci(e / inf(x))} <= kappa x backward error {sci(kappa * eta)}, ratio {kappa * eta / (e / inf(x)):.1f}")
        assert e / inf(x) <= kappa * eta, "forward error bounded by kappa times backward error"
gam = 3 * n * 2.0 ** -53 / (1 - 3 * n * 2.0 ** -53); eta_on = trial(1e-14, True)[3]; g_off = trial(1e-14, False)[2]
print(f"bound gamma_15 x n^2 x g: pivoting on {sci(gam * n * n)}, {gam * n * n / eta_on:.0f} times the backward error; off {sci(gam * n * n * g_off)}")
assert eta_on <= gam * n * n, "backward error within the theorem's bound"
x_noP = solve(LU, list(range(n)), rhs(20.0, 30.0))[0]
print(f"wrong: b not reordered: h1 {x_noP[0]:.2f}  h2 {x_noP[1]:.2f}  q1 {x_noP[2]:.2f}  q2 {x_noP[3]:.2f}  q3 {x_noP[4]:.2f}")

ks = list(range(1, 16))
row_off = [math.log10(max(trial(1.0 / 10.0 ** k, False)[1], 1e-16)) for k in ks]
row_on = [math.log10(max(trial(1.0 / 10.0 ** k, True)[1], 1e-16)) for k in ks]
print("chart, -log10 leak     " + " ".join(f"{k:5d}" for k in ks))
print("chart, log10 gap, off  " + " ".join(f"{v:5.1f}" for v in row_off))
print("chart, log10 gap, on   " + " ".join(f"{v:5.1f}" for v in row_on))
assert row_off[-1] > -1 and max(row_on) < -12, "unpivoted error grows as the leak shrinks; pivoted does not"

def wilkinson(nw):                            # 1 on the diagonal, -1 below it, 1 down the last column
    Wk = [[1.0 if i == j or j == nw - 1 else (-1.0 if i > j else 0.0) for j in range(nw)] for i in range(nw)]
    xt = [((7 * i) % 11) / 10 - 0.5 for i in range(nw)]
    LUw, pw, gw, _, sw = lu(Wk); return sw, gw, err(solve(LUw, pw, matvec(Wk, xt))[0], xt)
sw, gw, ew = wilkinson(60)
print(f"Wilkinson n = 60: swaps {sw}, growth {sci(gw)} = 2^59 {sci(2.0 ** 59)}, error {ew:.2f}")
assert gw == 2.0 ** 59 and ew > 0.1, "growth 2^(n-1) defeats partial pivoting"
print(f"try: leak 1e-8, pivoting off: error {sci(trial(1e-8, False)[1])}; Wilkinson n = 40: growth {sci(wilkinson(40)[1])}, error {sci(wilkinson(40)[2])}")
print(f"try: n = 2,000: factor {F(2000):,}, each solve {S(2000):,}, solves per factorisation {F(2000) // S(2000):,}")
print("ALL CHECKS PASS")
