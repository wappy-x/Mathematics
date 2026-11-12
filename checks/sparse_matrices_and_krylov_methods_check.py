# Sparse storage and Krylov methods -- the check behind the card.  Standard
# library only.  50,000 road links on a 250-by-200 torus, six neighbours each.
# Steady traffic is a nonsymmetric system A x = s, stored in compressed rows,
# solved by GMRES, and checked by Jacobi, link lists, a known answer and balance.
from math import sqrt, log10

M64, state = (1 << 64) - 1, [20261111]
def nxt():                                   # SplitMix64, written out
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
def unif(): return (nxt() >> 11) / 9007199254740992.0
def sci(v): m, x = f"{v:.3e}".split("e"); return m + "e" + str(int(x))  # as Rust
def dot(u, v):
    acc = 0.0
    for a, b in zip(u, v): acc += a * b
    return acc

R, C = 250, 200; n = R * C
OFF = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, -1), (-1, 1)]  # k ^ 1 reverses k
nb = [[((i // C + dr) % R) * C + (i % C + dc) % C for dr, dc in OFF] for i in range(n)]
t, e, W, s = [0.0] * n, [0.0] * n, [], [0.0] * n
for j in range(n):                           # illustrative traffic numbers
    t[j] = [1.0, 2.0, 5.0, 10.0, 30.0][nxt() % 5]   # minutes to drive link j
    e[j] = 0.3 + 0.2 * unif()                # share of its cars that exit
    g = [0.5 + unif() for _ in range(6)]
    tot = dot(g, [1.0] * 6)                  # a plain left-to-right sum
    W.append([(1.0 - e[j]) * v / tot for v in g])   # share turning onto nb[j][k]
    s[j] = 0.5 + unif()                      # cars a minute from side streets

ptr, col, val = [0], [], []                  # compressed sparse row (CSR)
for i in range(n):
    col.append(i); val.append(1.0 / t[i])
    for k in range(6):
        j = nb[i][k]
        col.append(j); val.append(-W[j][k ^ 1] / t[j])
    ptr.append(len(col))
def csr(x):                                  # y = A x, touching nonzeros only
    y = [0.0] * n
    for i in range(n):
        acc = 0.0
        for p in range(ptr[i], ptr[i + 1]): acc += val[p] * x[col[p]]
        y[i] = acc
    return y
def by_links(x, ex):                         # y = A x again, link by link;
    y = [x[i] / t[i] for i in range(n)]      # ex = False: nobody exits
    for j in range(n):
        for k in range(6):
            w = W[j][k] if ex else W[j][k] / (1.0 - e[j])
            y[nb[j][k]] -= w * (x[j] / t[j])
    return y

def gmres(op, b, tol, kmax):                 # Arnoldi + Givens rotations
    bnorm = sqrt(dot(b, b)); Q = [[v / bnorm for v in b]]
    H, cs, sn, g, hist = [], [], [], [bnorm], [1.0]
    for k in range(kmax):
        w = op(Q[k]); h = []
        for q in Q:                          # modified Gram-Schmidt
            hj = dot(w, q); h.append(hj)
            w = [a - hj * c for a, c in zip(w, q)]
        h.append(sqrt(dot(w, w)))
        for j in range(k):                   # old rotations, then a new one
            a, c = h[j], h[j + 1]
            h[j], h[j + 1] = cs[j] * a + sn[j] * c, -sn[j] * a + cs[j] * c
        r = sqrt(h[k] * h[k] + h[k + 1] * h[k + 1])
        cs.append(h[k] / r); sn.append(h[k + 1] / r)
        Q.append([v / h[k + 1] for v in w]); h[k] = r
        g.append(-sn[k] * g[k]); g[k] = cs[k] * g[k]
        H.append(h); hist.append(abs(g[k + 1]) / bnorm)
        if hist[-1] < tol: break
    m = len(H); y = [0.0] * m
    for i in range(m - 1, -1, -1):           # back-substitute the small system
        acc = g[i]
        for j in range(i + 1, m): acc -= H[j][i] * y[j]
        y[i] = acc / H[i][i]
    u = [0.0] * n
    for j in range(m): u = [a + y[j] * c for a, c in zip(u, Q[j])]
    return u, hist

nnz = len(val); dense, crs = 8 * n * n, 8 * nnz + 4 * nnz + 4 * (n + 1)
print(f"network,links={n:,},nonzeros={nnz:,},share={100 * nnz / n / n:.3f}%")
print(f"storage,dense_entries={n * n:,},dense_bytes={dense:,},csr_bytes={crs:,},triplet_bytes={16 * nnz:,}")
print(f"storage,saving={dense / crs:.1f},product_flops_dense={2 * n * n:,},csr={2 * nnz:,}")
print(f"row0,ptr={ptr[:2]},col={col[:7]}")
print("row0,val=" + ", ".join(f"{v:.4f}" for v in val[:7]))
z = [unif() for _ in range(n)]
gap = max(abs(a - c) for a, c in zip(csr(z), by_links(z, True)))
assert gap < 1e-13; print(f"product,csr_vs_link_lists_max_gap={sci(gap)}")

pre = lambda v: csr([a * c for a, c in zip(t, v)])   # B = A M^-1, M = diag(A)
nb2, Bs = sqrt(dot(s, s)), pre(s)
al = dot(s, Bs) / dot(Bs, Bs)
r1 = sqrt(dot(s, s) - al * dot(s, Bs)) / nb2
u, hist = gmres(pre, s, 1e-10, 60); x = [a * c for a, c in zip(t, u)]   # x = M^-1 u
assert abs(hist[1] - r1) < 1e-12
print(f"step1,norm_s={nb2:.4f},s.Bs={dot(s, Bs):.4f},Bs.Bs={dot(Bs, Bs):.4f},alpha={al:.6f}")
print(f"step1,residual={r1:.6f},gmres={hist[1]:.6f}")
xj, jh = [0.0] * n, []                       # plain Jacobi: x += M^-1 (s - A x)
while True:
    r = [a - c for a, c in zip(s, csr(xj))]
    jh.append(sqrt(dot(r, r)) / nb2)
    if jh[-1] < 1e-10: break
    xj = [a + c * d for a, c, d in zip(xj, t, r)]
inflow = [1.0 - v for v in by_links(t, True)]   # shares turning into each link
n1, ninf = max(1.0 - v for v in e), max(inflow); beta = sqrt(n1 * ninf)
print(f"bound,norm1={n1:.6f},norm_inf={ninf:.6f},beta={beta:.6f},jacobi_factor_per_step_over_20={jh[20] ** 0.05:.4f}")
print("step,gmres,jacobi,bound,gmres/bound")
for k in range(0, len(hist), 4):
    assert hist[k] <= jh[k] * (1 + 1e-9) and jh[k] <= beta ** k * (1 + 1e-9)
    print(f"{k},{sci(hist[k])},{sci(jh[k])},{sci(beta ** k)},{sci(hist[k] / beta ** k)}")
x0, hist0 = gmres(csr, s, 1e-10, 150)        # no preconditioner
tr = [a - c for a, c in zip(s, by_links(x, True))]; true = sqrt(dot(tr, tr)) / nb2
gj, g0 = (max(abs(a - c) / c for a, c in zip(y, x)) for y in (xj, x0))
K = len(hist) - 1; assert true < 2e-10 and gj < 1e-8 and g0 < 1e-8 and len(hist0) > 3 * len(hist)
print(f"solve,steps={K},estimate={sci(hist[-1])},true_residual={sci(true)}")
print(f"solve,jacobi_steps={len(jh) - 1},max_rel_gap={sci(gj)}")
print(f"solve,plain_steps={len(hist0) - 1},at_step_{K}={sci(hist0[K])},max_rel_gap={sci(g0)}")
for st, pc in ((K, 1), (len(hist0) - 1, 0)):
    fl = sum(2 * nnz + pc * n + 4 * n * (k + 1) + 3 * n for k in range(st))
    print(f"cost,steps={st},flops={fl:,},basis_bytes={8 * n * (st + 1):,}")
print(f"cost,dense_lu_flops={2 * n ** 3 // 3:,}")
bm = by_links([1.0] * n, True); um, hm = gmres(pre, bm, 1e-10, 60)   # answer: all ones
xm = [a * c for a, c in zip(t, um)]; rm = [a - c for a, c in zip(bm, by_links(xm, True))]
dm = [v - 1.0 for v in xm]; er, rr = sqrt(dot(dm, dm) / n), sqrt(dot(rm, rm) / dot(bm, bm))   # relative, as lengths
kb = (1 + beta) * max(t) / min(t) / (1 - beta); assert er < 1e-8 and (beta >= 1 or er <= kb * rr)   # kappa_2 bound, Step 5
print(f"manufactured,steps={len(hm) - 1},rel_residual={sci(rr)},rel_error={sci(er)},ratio={er / rr:.1f},kappa2_bound={kb:.1f},error_bound={sci(kb * rr)},bound/true={kb * rr / er:.1f}")
cin, cars, cout = dot(s, [1.0] * n), dot(x, [1.0] * n), dot(e, [a / c for a, c in zip(x, t)])
assert abs(cin - cout) < 1e-9 * cin
print(f"balance,cars_in_per_min={cin:.4f},cars_out_per_min={cout:.4f}")
print(f"answer,cars_on_network={cars:.1f},link0_cars={x[0]:.4f},link0_minutes={t[0]:.0f}")
closed = lambda v: by_links([a * c for a, c in zip(t, v)], False)  # e = 0
_, hc = gmres(closed, s, 1e-10, K); floor = cin / sqrt(n) / nb2   # proven floor
assert floor <= hc[-1] < 1.01 * floor and hc[10] - hc[-1] < 1e-5
print(f"closed,residual_at_step_10={hc[10]:.6f},at_step_{K}={hc[-1]:.6f},floor={floor:.6f}")
print("chart,step," + ",".join(str(k) for k in range(0, 21, 2)))
for name, hs in (("gmres_jacobi", hist), ("jacobi", jh), ("gmres_plain", hist0)):
    print(f"chart,{name}," + ",".join(f"{log10(hs[k]):.2f}" for k in range(0, 21, 2)))
print("ALL CHECKS PASS")
