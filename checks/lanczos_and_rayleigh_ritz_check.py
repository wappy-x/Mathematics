# Lanczos and Rayleigh-Ritz -- the check behind the card.  Standard library only.
# Road one: diag(1, 2, 3) by hand, by Sturm bisection and by a direct Rayleigh-Ritz.
# Road two: the 1,000-cell bar matrix L = tridiag(-1, 2, -1) against its known
# eigenvalues 4 sin^2(j pi / 2002).  Road three: shift-invert, with and without
# full reorthogonalisation, against the Kaniel-Paige bound and recomputed residuals.
from math import sqrt, sin, cos, pi, log10

M64, state = (1 << 64) - 1, [20261124]
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
def lanczos(op, b, m, full):                 # alphas, betas, Lanczos vectors
    nb = sqrt(dot(b, b)); Q = [[v / nb for v in b]]; al, be = [], []
    for k in range(m):
        w = op(Q[k]); a = dot(w, Q[k]); al.append(a)
        w = [x - a * y - (be[k - 1] * z if k > 0 else 0.0) for x, y, z in zip(w, Q[k], Q[k - 1])]
        if full:                             # full reorthogonalisation
            for v in Q:
                h = dot(w, v); w = [x - h * y for x, y in zip(w, v)]
        be.append(sqrt(dot(w, w)))
        if k < m - 1: Q.append([v / be[k] for v in w])
    return al, be, Q
def below(al, be, x):                        # Sturm count: eigenvalues of T_k below x
    c, d = 0, 1.0
    for i in range(len(al)):
        d = al[i] - x - (be[i - 1] * be[i - 1] / d if i > 0 else 0.0)
        d = d if d != 0.0 else 1e-300; c += d < 0.0
    return c
def ritz(al, be, j, lo, hi):                 # j-th smallest Ritz value, by bisection
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (lo, mid) if below(al, be, mid) > j else (mid, hi)
    return 0.5 * (lo + hi)
def ritzvec(al, be, th):                     # Ritz vector of T_k: two inverse steps
    k, s = len(al), [1.0] * len(al)          # on (th + d) I - T, positive definite
    for _ in range(2):
        c, g = [0.0] * k, [0.0] * k
        for i in range(k):
            m = th * (1 + 1e-13) - al[i] + (be[i - 1] * c[i - 1] if i > 0 else 0.0)
            c[i] = -be[i] / m; g[i] = (s[i] + (be[i - 1] * g[i - 1] if i > 0 else 0.0)) / m
        for i in range(k - 2, -1, -1): g[i] -= c[i] * g[i + 1]
        ns = sqrt(dot(g, g)); s = [v / ns for v in g]
    return s
# ---- road one: diag(1, 2, 3), start (1, 1, 1)/sqrt(3) ----
D = lambda x: [1.0 * x[0], 2.0 * x[1], 3.0 * x[2]]
al, be, Q = lanczos(D, [1.0, 1.0, 1.0], 3, False)
print(f"small,alpha={al[0]:.4f},{al[1]:.4f},{al[2]:.4f},beta={be[0]:.4f},{be[1]:.4f},beta3={sci(be[2])}")
t2 = [ritz(al[:2], be, j, 0.0, 4.0) for j in (0, 1)]
q1 = [1 / sqrt(3.0)] * 3; Aq = D(q1)           # direct Rayleigh-Ritz on span{b, Ab}
v = [x - dot(Aq, q1) * y for x, y in zip(Aq, q1)]; q2 = [x / sqrt(dot(v, v)) for x in v]
h11, h12, h22 = dot(q1, D(q1)), dot(q1, D(q2)), dot(q2, D(q2)); disc = sqrt((h11 - h22) ** 2 + 4 * h12 * h12)
direct = [0.5 * (h11 + h22 - disc), 0.5 * (h11 + h22 + disc)]
assert abs(be[0] - sqrt(2 / 3)) < 1e-15 and abs(be[1] - sqrt(1 / 3)) < 1e-15 and abs(be[2]) < 1e-14
assert all(abs(a - c) < 1e-14 and abs(a - d) < 1e-14 for a, c, d in zip(t2, direct, (2 - be[0], 2 + be[0])))
t3 = [ritz(al, be, j, 0.0, 4.0) for j in range(3)]
assert all(abs(a - c) < 1e-14 for a, c in zip(t3, (1.0, 2.0, 3.0))) and 1.0 <= t2[0] <= 2.0 <= t2[1] <= 3.0
print(f"small,T2_ritz={t2[0]:.4f},{t2[1]:.4f},direct={direct[0]:.4f},{direct[1]:.4f}")
print(f"small,T3_ritz={t3[0]:.6f},{t3[1]:.6f},{t3[2]:.6f}")
# ---- road two: the bar, n = 1,000 cells, plain Lanczos ----
n = 1000
def L(x): return [2.0 * x[i] - (x[i - 1] if i > 0 else 0.0) - (x[i + 1] if i < n - 1 else 0.0) for i in range(n)]
lam = [4.0 * sin(j * pi / 2002.0) ** 2 for j in range(1, n + 1)]   # exact eigenvalues
top, bot = 2.0 + 2.0 * cos(pi / 1001.0), lam[0]
b = [unif() - 0.5 for _ in range(n)]
print(f"bar,lambda_max={top:.12f},spec_form={4 - 2 * (1 - cos(pi / 1001)):.12f},second={lam[-2]:.12f}")
print(f"bar,lambda_min={bot:.15f},kappa={top / bot:.1f}")
def tan2f(v): c2 = dot(b, v) ** 2 / dot(v, v); return (dot(b, b) - c2) / c2   # tan^2 of start angle
tan2 = tan2f([sin(j * 1000 * pi / 1001) for j in range(1, n + 1)])  # top eigenvector
gam = (top - lam[-2]) / (lam[-2] - bot)
al, be, _ = lanczos(L, b, 800, False)
print(f"bar,tan2_theta0={tan2:.2f},gamma={sci(gam)}")
print("k,top_ritz,top_error,bottom_error,kaniel_paige_bound,bound/true")
prev, ks, chart = 0.0, [10, 25, 50, 100, 200, 300, 400, 500, 600, 700, 800], []
for k in ks:
    a = al[:k]; th, tl = ritz(a, be, k - 1, 0.0, 4.5), ritz(a, be, 0, 0.0, 4.5)
    T0, T1, x = 1.0, 1.0 + 2 * gam, 1.0 + 2 * gam            # Chebyshev T_{k-1}(x)
    for _ in range(k - 2): T0, T1 = T1, 2 * x * T1 - T0
    bound = (top - bot) * tan2 / (T1 * T1)
    assert prev - 1e-13 <= th <= top + 1e-13 and top - th <= bound and tl >= bot - 1e-13 and top - th < {50: 2e-3, 800: 1e-6}.get(k, 1.0)
    prev = th; chart.append(log10(top - th))
    if k == 50: th50, tl50 = th, tl
    print(f"{k},{th:.10f},{sci(top - th)},{sci(tl - bot)},{sci(bound)},{sci(bound / (top - th))}")
print("chart,k," + ",".join(str(k) for k in ks))
print("chart,log10_top_error," + ",".join(f"{v:.2f}" for v in chart))
# ---- road three: shift-invert, solve with L by the Thomas algorithm ----
def solve(d):
    cp, dp = [0.0] * n, [0.0] * n
    cp[0], dp[0] = -0.5, d[0] / 2.0
    for i in range(1, n):
        m = 2.0 + cp[i - 1]; cp[i] = -1.0 / m; dp[i] = (d[i] + dp[i - 1]) / m
    x = [0.0] * n; x[-1] = dp[-1]
    for i in range(n - 2, -1, -1): x[i] = dp[i] - cp[i] * x[i + 1]
    return x
mu = [1.0 / v for v in lam[:2]]                                      # 1/lambda_1, 1/lambda_2
tan2 = tan2f([sin(j * pi / 1001) for j in range(1, n + 1)])         # bottom eigenvector
gam = (mu[0] - mu[1]) / (mu[1] - 1.0 / top)
print(f"invert,mu1={mu[0]:.6f},mu2={mu[1]:.6f},tan2_theta0={tan2:.2f},gamma={gam:.4f}")
runs = [lanczos(solve, b, 40, f) for f in (False, True)]
print("k,rel_error,bound,bound/true,residual_estimate,residual_recomputed,copies_plain,copies_full,orth_plain,orth_full")
for k in [2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 40]:
    row = []
    for al, be, Q in runs:
        a = al[:k]; th = ritz(a, be, k - 1, 0.0, 2e5)
        cop = k - below(a, be, mu[0] * (1 - 1e-8))
        orth = max(abs(dot(Q[k - 1], Q[i])) for i in range(k - 1))
        row.append((th, cop, orth))
    al, be, Q = runs[1]; th = row[1][0]; s = ritzvec(al[:k], be, th)
    y = [dot(s, [Q[j][i] for j in range(k)]) for i in range(n)]
    r = [p - th * q for p, q in zip(solve(y), y)]; tr, est = sqrt(dot(r, r)), be[k - 1] * abs(s[-1])
    err = (mu[0] - th) / mu[0]
    T0, T1, x = 1.0, 1.0 + 2 * gam, 1.0 + 2 * gam
    for _ in range(k - 2): T0, T1 = T1, 2 * x * T1 - T0
    bnd = (mu[0] - 1.0 / top) * tan2 / (T1 * T1) / mu[0]
    assert abs(row[0][0] - row[1][0]) < 1e-12 * mu[0] and abs(tr - est) < 1e-13 * mu[0] + 1e-6 * est
    assert (err <= bnd or err < 1e-12) and abs(err) < {5: 1e-8, 6: 1e-11}.get(k, 1e-12 if k > 6 else 1.0)  # both sides; the floor
    ratio = f"{bnd / err:.1f}" if err > 1e-12 else "-"
    print(f"{k},{sci(err)},{sci(bnd)},{ratio},{sci(est)},{sci(tr)},{row[0][1]},{row[1][1]},{sci(row[0][2])},{sci(row[1][2])}")
    if k in (8, 10): print(f"paige,k={k},u*mu1/estimate={sci(2.0 ** -53 * mu[0] / est)},orth_plain={sci(row[0][2])}")
assert row[0][1] >= 3 and row[1][1] == 1
print(f"invert,error_floor={sci(err)},kappa_u={sci(top / bot * 2.0 ** -53)}")

# ---- what it is for: the bar's time step and cooling time (alpha illustrative) ----
h, alpha = 1e-3, 1.2e-5                      # 1 mm cells; steel, m^2/s, illustrative
print(f"use,dt_max_s={2 * h * h / (alpha * top):.7f},r_max={2 / top:.7f},cooling_time_s={h * h / (alpha * bot):.1f}")
g, amp = 1.0 - (2.0 / th50) * top, 1.0      # step set from the Ritz value th50 < lambda_max
for _ in range(10000): amp *= abs(g)
assert g < -1.0 and amp > 1.0
print(f"break,ritz50={th50:.7f},r_from_ritz={2 / th50:.7f},g={g:.7f},growth_10000_steps={amp:.1f}")
print(f"break,plain_bottom_ritz50={tl50:.7f},relative_error={(tl50 - bot) / bot:.1f}")
print(f"cost,plain_50_steps={50 * 12 * n:,},invert_6_steps={6 * 15 * n:,},full_reorth_extra_40={sum(4 * n * (k + 1) for k in range(40)):,},dense_tridiagonalise={4 * n ** 3 // 3:,}")
print("ALL CHECKS PASS")
