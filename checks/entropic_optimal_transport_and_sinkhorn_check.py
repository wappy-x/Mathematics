# Entropic optimal transport and Sinkhorn -- the check behind the card.  Standard library only.
# Minimise transport cost minus eps times entropy over plans P with row sums a and
# column sums b.  Roads: Sinkhorn scaling; a closed form and a golden-section search
# on the 2-by-2 example; the dual value (a lower bound) meeting the primal value; the
# exact transport cost from an LP plan, its dual prices and a running-sum formula;
# the Hilbert-metric rate bound; log-domain Sinkhorn against plain Sinkhorn.
import math

def kernel(C, eps): return [[math.exp(-c / eps) for c in row] for row in C]
def plan(u, K, v): return [[u[i] * K[i][j] * v[j] for j in range(len(v))] for i in range(len(u))]
def rowerr(P, a): return sum(abs(sum(P[i]) - a[i]) for i in range(len(a)))
def cost(C, P): return sum(C[i][j] * P[i][j] for i in range(len(P)) for j in range(len(P[0])))
def ent(p): return -sum(x * math.log(x) for x in p if x > 0)
def H(P): return ent([x for row in P for x in row])
def sinkhorn(a, b, K, iters, tol=0.0):
    v, errs = [1.0] * len(b), []
    for k in range(iters):
        u = [a[i] / sum(K[i][j] * v[j] for j in range(len(b))) for i in range(len(a))]
        v = [b[j] / sum(K[i][j] * u[i] for i in range(len(a))) for j in range(len(b))]
        errs.append(rowerr(plan(u, K, v), a))
        if errs[-1] < tol: break
    return u, v, errs
def dual(a, b, C, u, v, eps):   # q(phi, psi) with phi = eps(log u + 1), psi = eps log v
    phi = [eps * (math.log(x) + 1) for x in u]; psi = [eps * math.log(x) for x in v]
    return (sum(p * x for p, x in zip(phi, a)) + sum(p * x for p, x in zip(psi, b))
            - eps * sum(math.exp((phi[i] + psi[j] - C[i][j]) / eps - 1)
                        for i in range(len(a)) for j in range(len(b))))
def sci(x): return f"{x:.1e}"
f6 = lambda M: "[" + ", ".join("[" + ", ".join(f"{x:.6f}" for x in r) + "]" for r in M) + "]"

# 1. the 2-by-2 example: down days and up days, half each, both years; eps = 1
a2, C2, eps = [0.5, 0.5], [[0.0, 1.0], [1.0, 0.0]], 1.0
K = kernel(C2, eps); u, v, e = sinkhorn(a2, a2, K, 1)
P = plan(u, K, v); val = cost(C2, P) - eps * H(P)
print(f"2x2, eps = 1: K = {f6(K)}; after sweep 1: u = ({u[0]:.6f}, {u[1]:.6f}), v = ({v[0]:.6f}, {v[1]:.6f})")
print(f"  row sums of K v_0 = K (1, 1): {sum(K[0]):.6f}, {sum(K[1]):.6f}")
print(f"  plan {f6(P)}, row error {sci(e[0])}")
print(f"  cost {cost(C2, P):.6f}, entropy {H(P):.6f} nats, value {val:.6f}; dual value {dual(a2, a2, C2, u, v, eps):.6f}")
def val2(t, eps): Q = [[0.5 - t, t], [t, 0.5 - t]]; return cost(C2, Q) - eps * H(Q)
lo, hi, r = 1e-12, 0.5 - 1e-12, (math.sqrt(5) - 1) / 2   # golden-section on the off-diagonal t
for _ in range(200):
    x1, x2 = hi - r * (hi - lo), lo + r * (hi - lo)
    if val2(x1, eps) <= val2(x2, eps): hi = x2
    else: lo = x1
t = (lo + hi) / 2; closed = 0.5 / (1 + math.exp(1 / eps))
print(f"  search: off-diagonal {t:.6f}; closed form 0.5/(1 + e^(1/eps)) = {closed:.6f}; value {val2(t, eps):.6f}")
cr = lambda Q: Q[0][0] * Q[1][1] / (Q[0][1] * Q[1][0])
print(f"  cross-ratio P00 P11/(P01 P10): Sinkhorn {cr(P):.6f}, search {cr([[0.5 - t, t], [t, 0.5 - t]]):.5f}, e^2 = {math.exp(2):.6f}")
assert abs(t - P[0][1]) < 1e-7 and abs(closed - P[0][1]) < 1e-12 and abs(cr(P) - math.exp(2)) < 1e-9
assert abs(dual(a2, a2, C2, u, v, eps) - val) < 1e-12 and val < val2(0.0, eps)
print(f"  exact plan [[0.5, 0], [0, 0.5]]: cost 0, value {-math.log(2):.6f}; bias bound eps*min(H(a), H(b)) = {ent(a2):.6f}")
for ep in [1.0, 0.5, 0.25, 0.1]:
    K = kernel(C2, ep); u, v, e = sinkhorn(a2, a2, K, 1); c = cost(C2, plan(u, K, v))
    print(f"  eps = {ep:<4g}: cost {c:.6f}, 1/(1 + e^(1/eps)) = {1 / (1 + math.exp(1 / ep)):.6f}, bound {ep * ent(a2):.6f}")
    assert abs(c - 1 / (1 + math.exp(1 / ep))) < 1e-12 and c <= ep * ent(a2)

# 2. the tracker's returns in three bins (down, flat, up), last year a, this year b
a, b = [0.3, 0.4, 0.3], [0.2, 0.3, 0.5]
print("returns: last year days", " ".join(f"{250 * x:.0f}" for x in a), "of 250; this year",
      " ".join(f"{250 * x:.0f}" for x in b))
C = [[float(abs(i - j)) for j in range(3)] for i in range(3)]   # percentage points apart
P0 = [[0.2, 0.1, 0.0], [0.0, 0.2, 0.2], [0.0, 0.0, 0.3]]       # move up one bin at a time
phi, psi = [0.0, -1.0, -2.0], [0.0, 1.0, 2.0]                   # LP dual prices
ok = all(phi[i] + psi[j] <= C[i][j] for i in range(3) for j in range(3))
lpdual = sum(p * x for p, x in zip(phi, a)) + sum(p * x for p, x in zip(psi, b))
runs = sum(abs(sum(a[:k + 1]) - sum(b[:k + 1])) for k in range(2))
print(f"3 bins: exact plan {f6(P0)} costs {cost(C, P0):.6f}; dual prices give {lpdual:.6f} "
      f"(fair: {'yes' if ok else 'no'}); running sums {runs:.6f}")
assert ok and abs(cost(C, P0) - lpdual) < 1e-12 and abs(runs - lpdual) < 1e-12
assert rowerr(P0, a) < 1e-12 and rowerr([list(c) for c in zip(*P0)], b) < 1e-12
Hmin = min(ent(a), ent(b))
print(f"  H(a) = {ent(a):.6f}, H(b) = {ent(b):.6f} nats")
print("  eps    sweeps  cost      bias bound  |dual gap|")
for ep in [1.0, 0.5, 0.2, 0.1, 0.05]:
    K = kernel(C, ep); u, v, e = sinkhorn(a, b, K, 100000, 1e-12); P = plan(u, K, v)
    gap = cost(C, P) - ep * H(P) - dual(a, b, C, u, v, ep)
    print(f"  {ep:<5g}  {len(e):>6}  {cost(C, P):.6f}  {ep * Hmin:.6f}    {sci(abs(gap))}")
    assert -1e-9 < cost(C, P) - 0.3 <= ep * Hmin and abs(gap) < 1e-8

# 3. the linear rate at eps = 1: Hilbert distance of v_k to its limit, against the bound
K = kernel(C, 1.0); vs = sinkhorn(a, b, K, 200)[1]
dH = lambda x, y: math.log(max(p / q for p, q in zip(x, y))) - math.log(min(p / q for p, q in zip(x, y)))
theta = max(C[i][l] + C[j][k] - C[i][k] - C[j][l] for i in range(3) for j in range(3) for k in range(3) for l in range(3))
kap = math.tanh(theta / 4); kap2 = kap * kap; v, d = [1.0] * 3, []
for k in range(7):
    d.append(dH(v, vs))
    u = [a[i] / sum(K[i][j] * v[j] for j in range(3)) for i in range(3)]
    v = [b[j] / sum(K[i][j] * u[i] for i in range(3)) for j in range(3)]
ratios = [d[k + 1] / d[k] for k in range(6)]
print(f"rate, eps = 1: swap saving {theta:.0f}, bound tanh(1)^2 = {kap2:.6f}; ratios", " ".join(f"{x:.4f}" for x in ratios))
assert all(x <= kap2 for x in ratios) and abs(ratios[-1] - ratios[-2]) < 0.01
for ep in [1.0, 0.5, 0.2]:
    e = sinkhorn(a, b, kernel(C, ep), 12)[2]
    print(f"chart, eps = {ep:g}: log10 row error after sweeps 1..12:", " ".join(f"{math.log10(x):.2f}" for x in e))

# 4. a row scaling is a KL projection: Pythagoras D(R||Q) = D(R||P) + D(P||Q) for R with row sums a
D = lambda X, Y: sum(x * math.log(x / y) for rx, ry in zip(X, Y) for x, y in zip(rx, ry) if x > 0)
Q = [[x / 3 for x in row] for row in kernel(C, 0.5)]
Pr = [[Q[i][j] * a[i] / sum(Q[i]) for j in range(3)] for i in range(3)]
R = [[0.1, 0.1, 0.1], [0.1, 0.2, 0.1], [0.0, 0.1, 0.2]]
print(f"KL projection: D(R||Q) = {D(R, Q):.6f}, D(R||P) + D(P||Q) = {D(R, Pr) + D(Pr, Q):.6f}")
assert abs(D(R, Q) - D(R, Pr) - D(Pr, Q)) < 1e-12

# 5. what breaks
e = sinkhorn(a, [0.2, 0.3, 0.6], kernel(C, 0.5), 1000)[2]
print(f"unequal totals (b sums to 1.1): row error after 1000 sweeps {e[-1]:.6f}")
K = kernel(C, 0.001); e = sinkhorn(a, b, K, 1000)[2]
print(f"eps = 0.001, plain kernel: K[0][1] = {K[0][1]:.1f}, row error after 1000 sweeps {e[-1]:.6f}")
assert abs(e[-1] - 0.4) < 1e-12
def lse(xs): m = max(xs); return m + math.log(sum(math.exp(x - m) for x in xs))
def logsink(a, b, C, ep, tol):
    f, g = [0.0] * 3, [0.0] * 3
    for k in range(1, 100000):
        f = [ep * math.log(a[i]) - ep * lse([(g[j] - C[i][j]) / ep for j in range(3)]) for i in range(3)]
        g = [ep * math.log(b[j]) - ep * lse([(f[i] - C[i][j]) / ep for i in range(3)]) for j in range(3)]
        P = [[math.exp((f[i] + g[j] - C[i][j]) / ep) for j in range(3)] for i in range(3)]
        if rowerr(P, a) < tol: return k, P
for ep in [0.5, 0.01, 0.001]:
    k, P = logsink(a, b, C, ep, 1e-12)
    print(f"log-domain, eps = {ep:g}: {k} sweeps, cost {cost(C, P):.6f}, plan {f6(P)}")
    assert rowerr([list(c) for c in zip(*P)], b) < 1e-12 and (ep > 0.01 or abs(cost(C, P) - lpdual) < 1e-8)
K = kernel(C, 0.5); u, v, e = sinkhorn(a, b, K, 100000, 1e-12); Pl = plan(u, K, v)
k, P = logsink(a, b, C, 0.5, 1e-12)
assert max(abs(P[i][j] - Pl[i][j]) for i in range(3) for j in range(3)) < 1e-12
print("ALL CHECKS PASS")
