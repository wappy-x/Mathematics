# Mirror descent -- the check behind the card.  Standard library only.
# Weights live on the simplex (non-negative, summing to 1).  Mirror descent with the
# entropy map multiplies each weight by exp(-step * slope), then rescales to sum 1.
# Roads: the closed-form step against a brute-force grid minimisation of
# step*g.x + KL(x||x0); the Bregman divergence from its definition against the KL sum;
# the three-point identity and Pinsker's bound; a constant-slope run against its
# closed form; on a 2,000-asset tracker, entropy against Euclidean steps, the one-step
# inequality, the certificate f >= 0 = f(index weights), and the first K with bound < f(x0).
import math
from operator import mul

def kl(x, y): return sum(a * math.log(a / b) for a, b in zip(x, y) if a > 0)
def h(x): return sum(a * math.log(a) for a in x if a > 0)
def md_step(x, g, a):
    y = [xi * math.exp(-a * gi) for xi, gi in zip(x, g)]
    z = sum(y)
    return [v / z for v in y]
def proj(v):  # nearest point of the simplex: subtract one level tau, clip at 0
    c, tau = 0.0, 0.0
    for j, u in enumerate(sorted(v, reverse=True)):
        c += u
        if u - (c - 1) / (j + 1) > 0: tau = (c - 1) / (j + 1)
    return [max(vi - tau, 0.0) for vi in v]
def show(x): return " ".join(f"{v:.4f}" for v in x)

# 1. one step on three assets: weights 1/3 each, slopes g = (1, 0, 2), step ln 2
x0, g, a = [1 / 3] * 3, [1.0, 0.0, 2.0], math.log(2)
mult = [math.exp(-a * gi) for gi in g]
raw = [xi * m for xi, m in zip(x0, mult)]
x1 = md_step(x0, g, a)
print("multipliers 2^(-g):", show(mult))
print("unnormalised:", show(raw), f"sum {sum(raw):.4f}")
print("mirror step x1:", show(x1))
assert max(abs(p - q) for p, q in zip(x1, [2 / 7, 4 / 7, 1 / 7])) < 1e-12
N, best = 840, (9.0, None)  # brute force: every grid point of the simplex, step 1/840
for i in range(N + 1):
    for j in range(N + 1 - i):
        x = [i / N, j / N, (N - i - j) / N]
        val = a * (x[0] + 2 * x[2]) + kl(x, x0)
        if val < best[0]: best = (val, (i, j, N - i - j))
print(f"grid 1/840: best point {best[1]} / 840, value {best[0]:.6f}; -ln(7/12) = {-math.log(7 / 12):.6f}")
assert best[1] == (240, 480, 120) and abs(best[0] + math.log(7 / 12)) < 1e-12
d10 = kl(x1, x0)
d_def = h(x1) - h(x0) - sum((math.log(q) + 1) * (p - q) for p, q in zip(x1, x0))
l1 = sum(abs(p - q) for p, q in zip(x1, x0))
print(f"D(x1,x0) by KL sum {d10:.6f}, by definition {d_def:.6f}; D(x0,x1) = {kl(x0, x1):.6f}")
print(f"Pinsker: |x1 - x0|_1 = {l1:.6f}, half its square {l1 * l1 / 2:.6f} <= {d10:.6f}")
assert abs(d10 - d_def) < 1e-12 and l1 * l1 / 2 <= d10 and abs(kl(x0, x1) - d10) > 0.01
u = [0.0, 1.0, 0.0]
lhs = kl(u, x0) - kl(u, x1) - d10
rhs = a * sum(gi * (p - q) for gi, p, q in zip(g, x1, u))
print(f"three-point: D(u,x0) {kl(u, x0):.6f} - D(u,x1) {kl(u, x1):.6f} - D(x1,x0) = {lhs:.6f}; a g.(x1-u) = {rhs:.6f}")
assert abs(lhs - rhs) < 1e-12
v = [p - a * gi for p, gi in zip(x0, g)]
xe = proj(v)
tau2 = (v[0] + v[1] - 1) / 2  # by hand: two weights stay positive
print("Euclidean step, same size:", show(xe))
assert abs(xe[0] - (v[0] - tau2)) < 1e-12 and xe[2] == 0.0

# 2. the slopes held fixed: cost f(x) = x_A + 2 x_C, least value 0 at asset B
x, fs, path = x0, [], [x0]
for k in range(1, 8):
    x = md_step(x, g, a)
    z = 2.0 ** -k + 1 + 4.0 ** -k
    closed = [2.0 ** -k / z, 1 / z, 4.0 ** -k / z]
    assert max(abs(p - q) for p, q in zip(x, closed)) < 1e-12
    fs.append(x[0] + 2 * x[2]); path.append(x)
print("figure, mirror path k = 0..4:", " | ".join(show(q) for q in path[:5]), "; Euclidean step:", show(xe))
print("constant slopes, f(x_k) for k = 1..7:", " ".join(f"{v:.4f}" for v in fs))
def steps_to(x, tol):
    for k in range(1, 200):
        x = md_step(x, g, a)
        if x[0] + 2 * x[2] < tol: return k, x
    return None, x
ku, _ = steps_to(x0, 0.01)
xc = [0.998, 0.001, 0.001]
kc, _ = steps_to(xc, 0.01)
print(f"steps to f < 0.01: from equal weights {ku} (D(u,x0) = {kl(u, x0):.4f}),"
      f" from (0.998, 0.001, 0.001) {kc} (D = {kl(u, xc):.4f})")
xz = [0.5, 0.0, 0.5]
for _ in range(20): xz = md_step(xz, g, a)
print(f"start (0.5, 0, 0.5), 20 steps: x = {show(xz)}, f = {xz[0] + 2 * xz[2]:.4f}; least value 0")
assert ku == 7 and kc > ku and xz[1] == 0.0 and xz[0] + 2 * xz[2] > 0.99

# 3. the tracker: n = 2,000 assets, m = 250 days of returns (percent), SplitMix64 seed 2024
M64 = (1 << 64) - 1
state = 2024
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
n, m, K = 2000, 250, 400
beta = [0.5 + unif() for _ in range(n)]
R = []
for t in range(m):
    mt = 2 * unif() - 1
    R.append([b * mt + 4 * unif() - 2 for b in beta])
cols = list(zip(*R))
zw = sum(1 / (i + 1) for i in range(n))
w = [1 / (i + 1) / zw for i in range(n)]
index = [sum(map(mul, r, w)) for r in R]
def fg(x):  # mean absolute daily miss, and a subgradient
    e = [sum(map(mul, r, x)) - it for r, it in zip(R, index)]
    s = [(v > 0) - (v < 0) for v in e]
    return sum(map(abs, e)) / m, [sum(map(mul, c, s)) / m for c in cols]
col_abs = [sum(map(abs, c)) / m for c in cols]
G_inf, G_2, Rad = max(col_abs), math.sqrt(sum(v * v for v in col_abs)), math.sqrt(1 - 1 / n)
a_m, a_e = math.sqrt(2 * math.log(n)) / (G_inf * math.sqrt(K)), Rad / (G_2 * math.sqrt(K))
bound_m, bound_e = G_inf * math.sqrt(2 * math.log(n) / K), Rad * G_2 / math.sqrt(K)
print(f"tracker: G_inf = {G_inf:.4f}, G_2 = {G_2:.4f}, R = {Rad:.4f}; steps: entropy {a_m:.5f}, Euclidean {a_e:.6f}")
print(f"certificate: f >= 0 everywhere and f(index weights) = {fg(w)[0]:.6f}, so f* = 0")
xm, xe = [1 / n] * n, [1 / n] * n
bm, be, hist, bad = math.inf, math.inf, [], 0
for k in range(K + 1):
    fm, gm = fg(xm)
    fe, ge = fg(xe)
    bm, be = min(bm, fm), min(be, fe)
    if k % 25 == 0: hist.append((k, bm, be))
    if k == K: break
    xn = md_step(xm, gm, a_m)  # one-step inequality of the proof, with u = index weights
    if a_m * fm > kl(w, xm) - kl(w, xn) + a_m ** 2 * max(map(abs, gm)) ** 2 / 2 + 1e-12: bad += 1
    xm, xe = xn, proj([p - a_e * q for p, q in zip(xe, ge)])
for k, p, q in hist:
    if k in (0, 50, 100, 200, 400): print(f"k = {k:3d}: best miss entropy {p:.6f}, Euclidean {q:.6f}")
print("chart, log10 best miss, entropy:", " ".join(f"{math.log10(p):.2f}" for _, p, _ in hist))
print("chart, log10 best miss, Euclidean:", " ".join(f"{math.log10(q):.2f}" for _, _, q in hist))
print(f"bounds after {K} steps: entropy {bound_m:.4f}, Euclidean {bound_e:.4f}; one-step inequality broken {bad} times")
f0, c_m, c_e = hist[0][1], math.sqrt(2 * math.log(n)), math.sqrt(n - 1)  # f0: the miss at equal weights
km, ke = (next(k for k in range(1, 10 ** 6) if b * math.sqrt(K / k) < f0) for b in (bound_m, bound_e))
print(f"first budget K whose bound is below the starting miss {f0:.6f}: entropy {km}, Euclidean {ke}, ratio {ke / km:.1f}")
assert K < km < ke and km == int(2 * math.log(n) * (G_inf / f0) ** 2) + 1 and ke == int((Rad * G_2 / f0) ** 2) + 1
print(f"after {K} steps, weight on asset 1: entropy {xm[0]:.4f}, Euclidean {xe[0]:.4f}, index {w[0]:.4f}")
assert fg(w)[0] < 1e-12 and bad == 0 and bm < be and min(xm) > 0
print(f"worst-case constants for n = 2000: entropy sqrt(2 ln n) = {c_m:.4f}, Euclidean sqrt(n - 1) = {c_e:.4f},"
      f" ratio {c_e / c_m:.2f}, steps ratio {(c_e / c_m) ** 2:.1f}")
assert abs(c_m - 3.90) < 0.005
print("ALL CHECKS PASS")
