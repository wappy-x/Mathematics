# Quadratic programs: minimum-variance weights over five assets, no shorting.
# Standard library only. Roads: the active-set method, every support solved, a 2.5% grid.
NAMES = ["UK shares", "World shares", "Property", "Gilts", "Gold"]
SD = [16.0, 15.0, 18.0, 8.0, 14.0]                     # yearly standard deviation, percent
RHO = {(0, 1): 0.9, (0, 2): 0.7, (1, 2): 0.5, (1, 4): 0.2, (2, 3): 0.3, (2, 4): 0.2, (3, 4): 0.3}
N, ONES = 5, [1.0] * 5

def cov(rho):                                          # Sigma: correlation times both deviations
    return [[SD[i] * SD[j] * (1.0 if i == j else rho.get((min(i, j), max(i, j)), 0.0))
             for j in range(N)] for i in range(N)]

def solve(M, r):                                       # Gaussian elimination, partial pivoting
    m = len(r); a = [M[i][:] + [r[i]] for i in range(m)]
    for c in range(m):
        p = max(range(c, m), key=lambda i: abs(a[i][c])); a[c], a[p] = a[p], a[c]
        for i in range(m):
            if i != c:
                f = a[i][c] / a[c][c]
                for j in range(c, m + 1): a[i][j] -= f * a[c][j]
    return [a[i][m] / a[i][i] for i in range(m)]

def kkt(Q, rows, rhs):                                 # [[Q, A^T], [A, 0]] [x; nu] = [-c; b], c = 0
    m = len(rows)
    M = [Q[i][:] + [rows[r][i] for r in range(m)] for i in range(N)] + [rows[r][:] + [0.0] * m for r in range(m)]
    z = solve(M, [0.0] * N + rhs)
    return z[:N], z[N:]

def var(Q, w): return sum(w[i] * Q[i][j] * w[j] for i in range(N) for j in range(N))
def mvec(Q, w): return [sum(Q[i][j] * w[j] for j in range(N)) for i in range(N)]
def unit(i): return [1.0 if j == i else 0.0 for j in range(N)]
def pct(w): return " ".join(f"{100 * x:7.2f}" for x in w)

def pinned(Q, pins):                                   # least variance with the assets in pins held at 0
    return kkt(Q, [ONES] + [unit(i) for i in pins], [1.0] + [0.0] * len(pins))

def active_set(Q, w, show):                            # start: a feasible w, empty working set
    W, k, path = [], 0, []
    while True:
        path.append(var(Q, w)); assert k < 20, "the method must finish"
        target, mult = pinned(Q, W)
        d = [target[i] - w[i] for i in range(N)]
        if max(abs(x) for x in d) < 1e-12:             # at the target: read the multipliers
            lam = [-mult[1 + t] for t in range(len(W))]
            if show: print(f"k={k}  V {path[-1]:.4f}  check: " + "  ".join(f"lambda {NAMES[i]} {l:.4f}" for i, l in zip(W, lam)))
            if not lam or min(lam) >= 0: return w, path, lam
            W.pop(lam.index(min(lam)))
        else:
            alpha, block = 1.0, None
            for i in range(N):
                if d[i] < -1e-12 and -w[i] / d[i] < alpha: alpha, block = -w[i] / d[i], i
            w = [w[i] + alpha * d[i] for i in range(N)]
            if block is not None: W.append(block)
            for i in W: w[i] = 0.0
            if show: print(f"k={k}  V {path[-1]:.4f}  alpha {alpha:.4f}  " + (f"blocked by {NAMES[block]}" if block is not None else "full step") + f"  w {pct(w)}")
        k += 1

def enumerate_supports(Q):                             # every set of held assets, keep the long-only ones
    best, feasible = None, 0
    for mask in range(1, 2 ** N):
        x, _ = pinned(Q, [i for i in range(N) if not mask >> i & 1])
        if min(x) >= -1e-12:
            feasible += 1
            if best is None or var(Q, x) < var(Q, best): best = x
    return best, feasible

def grid(Q, s=40):                                     # every weight a multiple of 2.5%
    best, count = None, 0
    for a in range(s + 1):
        for b in range(s + 1 - a):
            for c in range(s + 1 - a - b):
                for d in range(s + 1 - a - b - c):
                    w = [a / s, b / s, c / s, d / s, (s - a - b - c - d) / s]; count += 1
                    v = var(Q, w)
                    if best is None or v < best[0]: best = (v, w)
    return best[0], best[1], count

S = cov(RHO)
print("covariance, percent squared: UK, World, Property, Gilts, Gold")
for row in S: print("  " + " ".join(f"{x:6.1f}" for x in row))
wu, nu = pinned(S, [])
print(f"shorts allowed, one KKT solve: w {pct(wu)}  V {var(S, wu):.4f}  sd {var(S, wu) ** 0.5:.4f}  nu {nu[0]:.4f}")
print(f"equal weights: V {var(S, [0.2] * N):.4f}  sd {var(S, [0.2] * N) ** 0.5:.4f}")
w, path, lam = active_set(S, [0.2] * N, True)
V = var(S, w); m = mvec(S, w)
print(f"answer w {pct(w)}  V {V:.4f}  sd {V ** 0.5:.4f}")
print("answer on 1,000,000 pounds: " + "  ".join(f"{round(1e6 * x):,}" for x in w))
print("cov with portfolio (Sigma w): " + " ".join(f"{x:.4f}" for x in m) + f"  lambda Property {m[2] - V:.4f}")
h = [0.0, 0.0, 0.0, 0.0, 0.0]; det = 64 * 196 - 33.6 ** 2
g, o = 196 - 33.6, 64 - 33.6                           # rows of the 2-by-2 inverse, times det, summed
print(f"by hand on UK, Gilts, Gold: det {det:.2f}  gilts {g:.1f}  gold {o:.1f}  1/256 {1 / 256:.8f}  {g + o:.1f}/det {(g + o) / det:.8f}")
Vh = 1 / (1 / 256 + (g + o) / det); h[0], h[3], h[4] = Vh / 256, Vh * g / det, Vh * o / det
mh = mvec(S, h)
print(f"  V {Vh:.4f}  w {pct(h)}  World row {mh[1]:.4f}  lambda World {mh[1] - Vh:.4f}")
we, feas = enumerate_supports(S)
print(f"enumeration: 31 supports, {feas} long-only, best V {var(S, we):.4f}  w {pct(we)}")
gv, gw, cnt = grid(S)
print(f"grid: {cnt} portfolios, best V {gv:.4f}  w {pct(gw)}")
wf, _ = kkt(S, [ONES, unit(2)], [1.0, 0.01])
print(f"force 1% into Property: V {var(S, wf):.4f}  rise {var(S, wf) - V:.4f}  2*lambda*0.01 {2 * lam[0] * 0.01:.4f}")
clip = [max(x, 0.0) for x in wu]; clip = [x / sum(clip) for x in clip]
print(f"wrong, clip and rescale: w {pct(clip)}  V {var(S, clip):.4f}")
print(f"wrong, drop the shorted, re-solve: V {Vh:.4f}  sd {Vh ** 0.5:.4f}")
P = cov({**RHO, (1, 2): -0.2})
wp, _, _ = active_set(P, [0.2] * N, False); wpe, _ = enumerate_supports(P); gpv, _, _ = grid(P)
print(f"patched World-Property -0.2: active set V {var(P, wp):.4f}  w {pct(wp)}")
print(f"  enumeration V {var(P, wpe):.4f}  w {pct(wpe)}  grid V {gpv:.4f}")
T = cov({**RHO, (3, 4): 0.6}); wt, _, _ = active_set(T, [0.2] * N, False)
print(f"try, Gilts-Gold correlation 0.6: w {pct(wt)}  V {var(T, wt):.4f}")
f = [2 / 3 if i == 2 else 1.0 for i in range(N)]       # Property's deviation 18 -> 12
T = [[S[i][j] * f[i] * f[j] for j in range(N)] for i in range(N)]; wt, _, _ = active_set(T, [0.2] * N, False)
print(f"try, Property deviation 12: w {pct(wt)}  V {var(T, wt):.4f}")
print("chart, pass k        " + " ".join(f"{k:7d}" for k in range(len(path))))
print("chart, variance      " + " ".join(f"{v:7.2f}" for v in path))

assert max(abs(m[i] - V) for i in range(N) if w[i] > 0) < 1e-9, "held assets: equal covariance with the portfolio"
assert abs((m[2] - V) - lam[0]) < 1e-9 and lam[0] > 0, "Property's multiplier, two ways, and its sign"
assert min(w) >= 0 and abs(sum(w) - 1) < 1e-12, "long-only and fully invested"
assert abs(var(S, we) - V) < 1e-9 and max(abs(a - b) for a, b in zip(w, we)) < 1e-9, "enumeration agrees"
assert V <= gv < V + 0.05, "grid never beats the answer and gets close"
assert min(wu) < 0 and var(S, wu) < V, "shorts allowed: lower but infeasible"
assert min(wf) >= 0 and abs((var(S, wf) - V) - 2 * lam[0] * 0.01) < 0.015, "multiplier predicts the rise"
assert abs(Vh - var(S, pinned(S, [1, 2])[0])) < 1e-9, "hand algebra agrees with elimination"
assert mh[1] - Vh < -1, "World's multiplier is negative where the shorted assets were dropped"
assert var(P, wp) > gpv + 1, "non-convex: the KKT point is beaten by the grid"
print("ALL CHECKS PASS")
