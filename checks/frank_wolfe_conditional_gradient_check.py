# Frank-Wolfe (conditional gradient) on the weight simplex -- the check behind the card.
# Standard library only.  Minimise f(w) over weights w >= 0 that sum to 1.
# Part 1: three assets, f(w) = |w - t|^2 with t = (0.7, 0.4, -0.1), start (1, 0, 0).
# Part 2: a 2,000-asset index tracker fitted to 250 simulated daily returns (percent).
import math
from operator import mul

def corner(g): return min(range(len(g)), key=lambda i: g[i])     # the oracle: best corner
def fw_gap(g, w, s): return sum(map(mul, g, w)) - g[s]           # g . (w - e_s)
def fmt(v): return " ".join(f"{x:.4f}" for x in v)

# ---- Part 1: the three-asset example, three roads to one answer ----
t = [0.7, 0.4, -0.1]
def f3(w): return sum((a - b) ** 2 for a, b in zip(w, t))
def g3(w): return [2 * (a - b) for a, b in zip(w, t)]
def line3(w, d): return -sum((a - b) * c for a, b, c in zip(w, t, d)) / sum(c * c for c in d)

w = [1.0, 0.0, 0.0]; g = g3(w); s = corner(g)
d = [(i == s) - w[i] for i in range(3)]; gam = min(1.0, max(0.0, line3(w, d)))
w1 = [a + gam * c for a, c in zip(w, d)]; s1 = corner(g3(w1))
print(f"toy: f(w0) = {f3(w):.4f}, gradient = {fmt(g)}, corner = e{s + 1}, gap = {fw_gap(g, w, s):.4f}")
print(f"toy: step = {gam:.4f}, w1 = {fmt(w1)}, f(w1) = {f3(w1):.4f}, gradient = {fmt(g3(w1))}, "
      f"gap = {fw_gap(g3(w1), w1, s1):.4f}")

def project(v):                                   # projection onto the simplex: sort, shift, clip
    u = sorted(v, reverse=True); run = 0.0; tau = 0.0
    for j, x in enumerate(u):
        run += x
        if x - (run - 1) / (j + 1) > 0: tau = (run - 1) / (j + 1)
    return [max(x - tau, 0.0) for x in v]
pg = project([a - 0.5 * b for a, b in zip(w, g)])  # one projected-gradient step, step 1/L = 1/2
best = min((f3([i / 100, j / 100, (100 - i - j) / 100]), i, j)
           for i in range(101) for j in range(101 - i))
print(f"toy: projection of t = {fmt(project(t))}, projected-gradient step = {fmt(pg)}")
print(f"toy: grid of 5151 points, best = ({best[1] / 100:.2f}, {best[2] / 100:.2f}, "
      f"{(100 - best[1] - best[2]) / 100:.2f}), f = {best[0]:.4f}, f(w0) - f* = {f3(w) - best[0]:.4f}")
C3 = max(2 * sum(((i == k) - (j == k)) ** 2 for k in range(3)) for i in range(3) for j in range(3))
print(f"toy: curvature constant C = 2 * max |e_i - e_j|^2 = {C3:.4f}, bound 2C/(1+2) = {2 * C3 / 3:.4f}")
assert max(abs(a - b) for a, b in zip(w1, project(t))) < 1e-12   # Frank-Wolfe = projection
assert max(abs(a - b) for a, b in zip(w1, pg)) < 1e-12           # = projected gradient
assert abs(best[0] - f3(w1)) < 1e-12                             # = the grid's best
assert fw_gap(g3(w1), w1, s1) < 1e-12 < fw_gap(g, w, s)          # the gap certifies it
assert abs(fw_gap(g, w, s) + (f3([a + 1e-6 * c for a, c in zip(w, d)]) - f3([a - 1e-6 * c for a, c in zip(w, d)])) / 2e-6) < 1e-8

# ---- what breaks, on the same three assets ----
def run3(w, step, away, kmax, tol=1e-6):
    path = [w[:]]
    for k in range(kmax):
        g = g3(w); s = corner(g); gw = sum(map(mul, g, w))
        if gw - g[s] <= tol: return k, w, path, gw - g[s]
        on = [i for i in range(3) if w[i] > 0]; a = max(on, key=lambda i: g[i])
        drop = away and len(on) > 1 and g[a] - gw > gw - g[s]   # away beats toward
        if drop: d = [w[i] - (i == a) for i in range(3)]; top = w[a] / (1 - w[a])
        else: d = [(i == s) - w[i] for i in range(3)]; top = 1.0
        gam = step if step else min(top, max(0.0, line3(w, d)))
        w = [x + gam * c for x, c in zip(w, d)]
        if drop and gam == top: w[a] = 0.0        # the away corner leaves the support
        path.append(w[:])
    return kmax, w, path, fw_gap(g3(w), w, corner(g3(w)))
c3 = [1 / 3, 1 / 3, 1 / 3]
kz, wz, pz, _ = run3(c3[:], None, False, 10 ** 6)
ka, wa, pa, _ = run3(c3[:], None, True, 10 ** 6)
kf, wf, _, gf = run3(c3[:], 0.5, False, 200)
print(f"zigzag from the centre: plain {kz} steps to gap <= 1e-6, third weight {wz[2]:.7f}")
print(f"zigzag from the centre: away steps {ka} steps, third weight {wa[2]:.4f}")
print("figure, plain path " + " | ".join(fmt(p) for p in pz[:5]))
print("figure, away path " + " | ".join(fmt(p) for p in pa))
print(f"fixed step 0.5, 200 steps: gap = {gf:.4f}, f - f* = {f3(wf) - f3(w1):.4f}")
gc = [-2 * (a - b) for a, b in zip(c3, c3)]                       # gradient of -|w - c|^2 at c
lowest = min(-sum(((i == j) - c3[j]) ** 2 for j in range(3)) for i in range(3))
print(f"concave cost -|w - c|^2 at the centre: gap = {fw_gap(gc, c3, corner(gc)):.4f}, "
      f"above the minimum by {0.0 - lowest:.4f}")
assert ka < 10 and wa[2] == 0.0
assert kz > 100 * ka; assert gf > 0.1

# ---- Part 2: the 2,000-asset index tracker ----
N, T, SEED = 2000, 250, 2026
M64, state = (1 << 64) - 1, SEED
def uniform():                                    # SplitMix64: a draw in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53
def normal():                                     # Box-Muller, cosine half only
    u = uniform()
    return math.sqrt(-2.0 * math.log(u)) * math.cos(2.0 * math.pi * uniform())

mkt = [normal() for _ in range(T)]                # the market's daily move, percent
cols = []                                         # cols[i] = asset i's 250 daily returns
for i in range(N):
    beta, sig = 0.5 + uniform(), 1.0 + 1.5 * uniform()
    cols.append([beta * m + sig * normal() for m in mkt])
cap = [(i + 1) ** -0.8 for i in range(N)]; tot = sum(cap); cap = [c / tot for c in cap]
b = [0.0] * T                                     # the index: capitalisation-weighted
for i in range(N):
    b = [x + cap[i] * y for x, y in zip(b, cols[i])]
rho2 = max(sum(map(mul, c, c)) for c in cols)
C = 8 * rho2 / T                                  # curvature bound: (2/T)(2 * longest column)^2
res0 = [y - x for x, y in zip(b, cols[0])]
ri = [-x for x in b]                              # the index weights, summed in reverse order
for i in reversed(range(N)):
    ri = [x + cap[i] * y for x, y in zip(ri, cols[i])]
print(f"tracker: {N} assets, {T} days, index top weight {cap[0]:.4f}, curvature bound C = {C:.4f}")
print(f"tracker: start in asset 1 alone, f(w0) = {sum(map(mul, res0, res0)) / T:.4f}; "
      f"index weights give f = {sum(map(mul, ri, ri)) / T:.4f}")
assert sum(map(mul, ri, ri)) / T < 1e-20; assert abs(sum(cap) - 1) < 1e-12 < min(cap)   # f* = 0: the index is on the simplex

def tracker(line, K):
    w = [0.0] * N; w[0] = 1.0; u = res0[:]; rows = []
    for k in range(K + 1):
        h = sum(map(mul, u, u)) / T               # f(w_k) - f*, since f* = 0
        g = [2 / T * sum(map(mul, c, u)) for c in cols]
        s = corner(g); gap = fw_gap(g, w, s)
        rows.append((k, h, gap, sum(x > 0 for x in w)))
        v = [y - x - z for x, y, z in zip(b, cols[s], u)]   # residual change toward corner s
        gam = 2 / (k + 2)
        if line: gam = min(1.0, max(0.0, -sum(map(mul, u, v)) / sum(map(mul, v, v))))
        w = [(1 - gam) * x for x in w]; w[s] += gam
        u = [x + gam * y for x, y in zip(u, v)]
        if not line:                              # the proof's one-step inequality
            assert sum(map(mul, u, u)) / T <= (1 - gam) * h + gam * gam * C / 2 + 1e-12
    return rows
K = 400; op, ls = tracker(False, K), tracker(True, K)
print("    k   f(w_k) - f*        gap   2C/(k+2)  held | line search: f - f*    gap  held")
for k in [0, 1, 2, 5, 10, 20, 50, 100, 200, 300, 400]:
    (_, h, gap, n), (_, h2, gap2, n2) = op[k], ls[k]
    print(f"{k:5d} {h:12.6f} {gap:10.6f} {2 * C / (k + 2):10.4f} {n:5d} | {h2:12.6f} {gap2:9.6f} {n2:4d}")
print("tracking error, percent a day: " + ", ".join(f"k = {k}: {math.sqrt(op[k][1]):.4f} "
      f"and {math.sqrt(ls[k][1]):.4f}" for k in [0, 100, 400]))
for name, rows in [("open loop", op), ("line search", ls)]:
    print(f"figure, {name}, log10 gap at k = 0, 40, ..., 400: "
          + ", ".join(f"{math.log10(rows[k][2]):.2f}" for k in range(0, K + 1, 40)))
print("figure, log10 2C/(k+2) at k = 0, 40, ..., 400: "
      + ", ".join(f"{math.log10(2 * C / (k + 2)):.2f}" for k in range(0, K + 1, 40)))
for rows in (op, ls):
    assert all(h <= gap + 1e-12 for k, h, gap, n in rows)       # the gap bounds the error
    assert all(n <= k + 1 for k, h, gap, n in rows)             # one new asset per step at most
    assert all(h <= 2 * C / (k + 2) for k, h, gap, n in rows[1:])
print("ALL CHECKS PASS")
