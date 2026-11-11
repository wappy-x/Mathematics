# ADMM on a split lasso: copy an index with few of five assets.  Standard library only.
# Minimise f(x) + g(z) = 1/2 |Ax - b|^2 + lam*|z|_1 subject to x = z.  Returns in percent a month.
from itertools import product
from math import sqrt, log10

A = [[2, 3, -1, 1, 2], [-1, 1, 2, 0, -2], [3, 2, -2, 2, 1], [1, -2, 1, -1, 3],
     [-2, -1, 3, 1, -1], [0, 2, 0, -2, 1], [2, 0, -1, 3, 0], [1, 1, 1, 0, 2]]  # 8 months x 5 assets
b = [1.8, 0.1, 1.6, 0.3, -0.6, 0.5, 0.9, 1.1]          # the index, same 8 months
LAM, RHO, EPS, N = 2.0, 3.0, 5e-7, 5
AtA = [[float(sum(r[i] * r[j] for r in A)) for j in range(N)] for i in range(N)]
Atb = [sum(r[i] * bb for r, bb in zip(A, b)) for i in range(N)]

def solve(M, v):                        # Gauss-Jordan elimination with row swaps
    k = len(v); M = [list(M[i]) + [v[i]] for i in range(k)]
    for c in range(k):
        p = max(range(c, k), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(k):
            if r != c:
                f = M[r][c] / M[c][c]
                M[r] = [a - f * bb for a, bb in zip(M[r], M[c])]
    return [M[i][k] / M[i][i] for i in range(k)]
def norm(v): return sqrt(sum(t * t for t in v))
def soft(v, t): return 0.0 if abs(v) <= t else (v - t if v > 0 else v + t)
def grad(x): return [sum(AtA[i][j] * x[j] for j in range(N)) - Atb[i] for i in range(N)]
def cost(x): return 0.5 * sum((sum(a * t for a, t in zip(r, x)) - bb) ** 2 for r, bb in zip(A, b)) + LAM * sum(map(abs, x))
def show(v): return " ".join(f"{t:9.6f}" for t in v)

def admm(rho, rounds=1000, eps=EPS, shrink=None, dual=True):
    M = [[AtA[i][j] + (rho if i == j else 0.0) for j in range(N)] for i in range(N)]
    x, z, u, hist = [0.0] * N, [0.0] * N, [0.0] * N, []
    for k in range(1, rounds + 1):
        x = solve(M, [Atb[i] + rho * (z[i] - u[i]) for i in range(N)])   # fit half
        z_old, z = z, [soft(x[i] + u[i], shrink or LAM / rho) for i in range(N)]  # penalty half
        if dual: u = [u[i] + x[i] - z[i] for i in range(N)]               # reconcile
        r, s = norm([x[i] - z[i] for i in range(N)]), rho * norm([z[i] - z_old[i] for i in range(N)])
        hist.append((k, x, z, u, r, s))
        if r < eps and s < eps: break
    return hist

# Road 1: ADMM from x = z = u = 0
hist = admm(RHO); K, x, z, u, r, s = hist[-1]
# Road 2: every sign pattern (+, -, 0 for each asset); keep the one that passes the lasso's test
found = []
for sg in product((1, -1, 0), repeat=N):
    S = [i for i in range(N) if sg[i]]
    w = [0.0] * N
    for i, t in zip(S, solve([[AtA[i][j] for j in S] for i in S], [Atb[i] - LAM * sg[i] for i in S]) if S else []): w[i] = t
    g = grad(w)
    if all(w[i] * sg[i] > 0 for i in S) and all(abs(g[i]) <= LAM + 1e-12 for i in range(N) if not sg[i]): found.append(w)
assert len(found) == 1; xs = found[0]
# Road 3: the certificate.  -grad f(z) must equal lam*sign on holdings and lie in [-lam, lam] elsewhere
gz = grad(z); ystar = [-t for t in grad(xs)]
assert all(abs(gz[i] + LAM * (1 if z[i] > 0 else -1)) < 1e-5 for i in range(N) if z[i] != 0)
assert all(abs(gz[i]) < LAM for i in range(N) if z[i] == 0)
assert max(abs(z[i] - xs[i]) for i in range(N)) < 1e-6 and K == 60
# Road 4: the convergence proof's yardstick V falls every round by at least rho(|r|^2 + |dz|^2)
V = lambda zz, uu: sum((RHO * uu[i] - ystar[i]) ** 2 for i in range(N)) / RHO + RHO * sum((zz[i] - xs[i]) ** 2 for i in range(N))
prev, worst = ([0.0] * N, [0.0] * N), float("inf")
for k, xk, zk, uk, rk, sk in hist:
    drop = V(*prev) - V(zk, uk); need = RHO * rk * rk + sk * sk / RHO
    assert drop >= need - 1e-12; worst = min(worst, drop / need) if need > 1e-20 else worst; prev = (zk, uk)

print("A^T A rows:"); [print("  ", show(row)) for row in AtA]
print("A^T b      ", show(Atb))
print("round 1 x  ", show(hist[0][1]), f" shrink lam/rho = {LAM / RHO:.4f}"); print("round 60 x ", " ".join(f"{t:.9f}" for t in x))
print("rounds, k: z_UK z_US z_prop |r| |s|")
for k, xk, zk, uk, rk, sk in hist:
    if k in (1, 2, 3, 5, 10, 20, 40, 59, 60):
        print(f"  {k:3d} {zk[0]:.6f} {zk[1]:.6f} {zk[4]:.6f} {rk:.9f} {sk:.9f}")
print("ADMM z     ", show(z)); print("enumerated ", show(xs))
print("-grad f(z) ", " ".join(f"{-t:.5f}" for t in gz), "  (lam = 2)")
print(f"lasso cost at z {cost(z):.6f}, at enumerated {cost(xs):.6f} = fit {cost(xs) - LAM * sum(map(abs, xs)):.6f} + penalty {LAM * sum(map(abs, xs)):.6f}")
print("least squares", show(solve(AtA, Atb)))
fit = [sum(a * t for a, t in zip(row, xs)) for row in A]
print("copy's returns", " ".join(f"{t:.4f}" for t in fit), f" rms gap {sqrt(sum((f - bb) ** 2 for f, bb in zip(fit, b)) / 8):.4f}")
print(f"per 1000000 pounds: UK shares {xs[0]*1e6:.0f}, US shares {xs[1]*1e6:.0f}, property {xs[4]*1e6:.0f}, cash {(1-sum(xs))*1e6:.0f}")
print(f"V falls every round; smallest drop / proof's floor = {worst:.4f}")
print("chart, k: log10|r|, log10|s|, log10|z - z*|")
for k, xk, zk, uk, rk, sk in hist:
    if k % 5 == 0:
        print(f"  {k:3d} {log10(rk):7.3f} {log10(sk):7.3f} {log10(norm([zk[i] - xs[i] for i in range(N)])):7.3f}")
print("rounds to stop at rho 0.5, 1, 3, 10, 30, 100:", " ".join(str(admm(rho)[-1][0]) for rho in (0.5, 1.0, 3.0, 10.0, 30.0, 100.0)))
# What breaks
nd = admm(RHO, rounds=2000, dual=False)[-1]
print(f"no dual update, after {nd[0]} rounds: x {show(nd[1])}, z {show(nd[2])}, |x - z| {nd[4]:.6f}")
assert nd[4] > 0.01
ws = admm(RHO, shrink=LAM)[-1]
print(f"shrink by lam not lam/rho: z {show(ws[2])}, the lasso at weight rho*lam = {RHO * LAM:.1f}")
assert abs(ws[2][1] - xs[1]) > 0.05
# Three blocks: minimise 0 subject to B1 v1 + B2 v2 + B3 v3 = 0, sweeping one block at a time
B = [[1, 1, 1], [1, 1, 2], [1, 2, 2]]; v, y = [1.0, 1.0, 1.0], [0.0, 0.0, 0.0]
print(f"three blocks, round   0: |v| = {norm(v):.4f}")
for k in range(1, 201):
    for j in range(3):
        rest = [sum(B[i][m] * v[m] for m in range(3) if m != j) + y[i] for i in range(3)]
        v[j] = -sum(B[i][j] * rest[i] for i in range(3)) / sum(B[i][j] ** 2 for i in range(3))
    y = [y[i] + sum(B[i][m] * v[m] for m in range(3)) for i in range(3)]
    if k in (1, 50, 100, 200): print(f"three blocks, round {k:3d}: |v| = {norm(v):.4f}")
assert norm(v) > 10
for lam in (1.0, 4.0):
    LAM = lam; print(f"try lam {lam}: z {show(admm(RHO)[-1][2])}")
print("ALL CHECKS PASS")
