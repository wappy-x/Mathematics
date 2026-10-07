# MCMC check: a seedling's start height a and weekly growth b, posterior sampled three ways.
# Roads: 1 the exact normal posterior by formula; 2 an exact grid, chains pushed with no randomness;
# 3 seeded simulation (SplitMix64, Box-Muller), every simulated number with a batch-means standard error.
from math import exp, sqrt, log, cos, sin, pi
M64 = (1 << 64) - 1
class Rng:
    def __init__(s, seed): s.s = seed
    def u(s):
        s.s = (s.s + 0x9E3779B97F4A7C15) & M64
        z = s.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def n(s):
        u1 = s.u(); u2 = s.u()
        return sqrt(-2.0 * log(1.0 - u1)) * cos(2.0 * pi * u2)
X = [1.0, 2.0, 3.0, 4.0, 5.0]; Y = [2.1, 2.9, 4.2, 4.8, 6.0]; SIG = 0.5   # weeks, heights (cm), noise sd
n = 5.0; SX = sum(X); SXX = sum(x * x for x in X); SY = sum(Y); SXY = sum(x * y for x, y in zip(X, Y))
def logf(a, b): return -sum((y - a - b * x) ** 2 for x, y in zip(X, Y)) / (2 * SIG * SIG)
def Phi(z):                                   # normal CDF by Simpson's rule on the bell curve
    m = 400; h = abs(z) / m
    s = sum((1 if i in (0, m) else (4 if i % 2 else 2)) * exp(-0.5 * (i * h) ** 2) for i in range(m + 1))
    v = 0.5 + s * h / 3 / sqrt(2 * pi)
    return v if z >= 0 else 1 - v
def out(k, *v, d=4): print(f"{k:<38}" + "".join(f" {x:.{d}f}" for x in v))
# ---- road 1: formula ----
D = n * SXX - SX * SX
bh = (n * SXY - SX * SY) / D; ah = (SY - bh * SX) / n
vA = SIG ** 2 * SXX / D; vB = SIG ** 2 * n / D; cAB = -SIG ** 2 * SX / D
rho = cAB / sqrt(vA * vB); r2 = rho * rho; tau = (1 + r2) / (1 - r2)
pB1 = 1 - Phi((1 - bh) / sqrt(vB))
out("sums w, w^2, h, wh; D", SX, SXX, SY, SXY, D); out("var a, var b, cov(a,b)", vA, vB, cAB)
out("Gibbs conditional sd, a|b and b|a", SIG / sqrt(n), SIG / sqrt(SXX))
for k, v in [("formula mean a", ah), ("formula mean b", bh), ("formula sd a", sqrt(vA)), ("formula sd b", sqrt(vB)),
             ("formula corr(a,b)", rho), ("formula P(b>1)", pB1), ("Gibbs lag-1 autocorr rho^2", r2), ("Gibbs tau = N/ESS", tau)]: out(k, v)
# ---- road 2: exact grid ----
NA, NB = 141, 121; GA = [-2.0 + 0.05 * i for i in range(NA)]; GB = [-0.5 + 0.025 * j for j in range(NB)]
LW = [[logf(GA[i], GB[j]) for j in range(NB)] for i in range(NA)]; W = [[exp(v) for v in r] for r in LW]
T = sum(map(sum, W)); W = [[w / T for w in r] for r in W]
gb = sum(W[i][j] * GB[j] for i in range(NA) for j in range(NB)); ga = sum(W[i][j] * GA[i] for i in range(NA) for j in range(NB))
gp = sum(W[i][j] * (1.0 if j > 60 else 0.5 if j == 60 else 0.0) for i in range(NA) for j in range(NB))
out("grid mean a", ga); out("grid mean b", gb); out("grid P(b>1)", gp)
nb = [(di, dj) for di in range(-2, 3) for dj in range(-2, 3) if (di, dj) != (0, 0)]   # Metropolis on the grid, 24 neighbours
def mv(i, j, k, l): return 0.0 if not (0 <= k < NA and 0 <= l < NB) else min(1.0, exp(LW[k][l] - LW[i][j])) / 24
imb = max(abs(W[i][j] * mv(i, j, i + di, j + dj) - W[i + di][j + dj] * mv(i + di, j + dj, i, j))
          for i in range(NA) for j in range(NB) for di, dj in nb if 0 <= i + di < NA and 0 <= j + dj < NB)
new = [[W[i][j] * (1 - sum(mv(i, j, i + di, j + dj) for di, dj in nb)) for j in range(NB)] for i in range(NA)]
for i in range(NA):
    for j in range(NB):
        for di, dj in nb:
            if 0 <= i + di < NA and 0 <= j + dj < NB: new[i + di][j + dj] += W[i][j] * mv(i, j, i + di, j + dj)
mstat = max(abs(new[i][j] - W[i][j]) for i in range(NA) for j in range(NB))
print(f"{'grid Metropolis balance, max gap':<38} {'below 1e-15' if imb < 1e-15 else imb}")
print(f"{'grid Metropolis one step, max change':<38} {'below 1e-15' if mstat < 1e-15 else mstat}")
colA = [sum(W[i][j] for i in range(NA)) for j in range(NB)]; rowB = [sum(W[i]) for i in range(NA)]
def sweep(mu):                                # Gibbs on the grid: redraw a given b, then b given a
    cm = [sum(mu[i][j] for i in range(NA)) for j in range(NB)]
    mu = [[cm[j] * W[i][j] / colA[j] for j in range(NB)] for i in range(NA)]
    rm = [sum(r) for r in mu]
    return [[rm[i] * W[i][j] / rowB[i] for j in range(NB)] for i in range(NA)]
g1 = sweep(W); gstat = max(abs(g1[i][j] - W[i][j]) for i in range(NA) for j in range(NB))
print(f"{'grid Gibbs sweep, max change':<38} {'below 1e-15' if gstat < 1e-15 else gstat}")
mu = [[1.0 if (i, j) == (0, 20) else 0.0 for j in range(NB)] for i in range(NA)]   # start at b = 0
Eb = {}; TV = {}
for s in range(41):
    Eb[s] = sum(mu[i][j] * GB[j] for i in range(NA) for j in range(NB))
    TV[s] = 0.5 * sum(abs(mu[i][j] - W[i][j]) for i in range(NA) for j in range(NB)); mu = sweep(mu)
for s in (1, 5, 10, 20, 40): out(f"sweep {s}: E[b] grid, formula; TV", Eb[s], bh * (1 - r2 ** s), TV[s])
wr = sum(W[i][j] for i in range(NA) for j in range(NB) if GB[j] > 0) / sum(W[i][j] / GB[j] for i in range(NA) for j in range(NB) if GB[j] > 0)
out("grid mean b, no Hastings factor", wr)
# ---- road 3: simulation ----
def bm(xs, k=100):                            # batch-means standard error and effective sample size
    L = len(xs) // k; m = sum(xs) / len(xs); v = sum((x - m) ** 2 for x in xs) / len(xs)
    bs = [sum(xs[q * L:(q + 1) * L]) / L for q in range(k)]
    se = sqrt(sum((c - m) ** 2 for c in bs) / (k - 1) / k); return m, se, v / se ** 2
def bse(f, *xs, k=100):                       # standard error of any statistic f from its spread over the k batches
    L = len(xs[0]) // k; s = [f(*(x[q * L:(q + 1) * L] for x in xs)) for q in range(k)]; m = sum(s) / k
    return sqrt(sum((c - m) ** 2 for c in s) / (k - 1) / k)
def corr(A, B):
    ma, mb = sum(A) / len(A), sum(B) / len(B); return sum((x - ma) * (y - mb) for x, y in zip(A, B)) / sqrt(sum((x - ma) ** 2 for x in A) * sum((y - mb) ** 2 for y in B))
def lag1(B): mb = sum(B) / len(B); return sum((B[t] - mb) * (B[t + 1] - mb) for t in range(len(B) - 1)) / sum((y - mb) ** 2 for y in B)
def gibbs(r, b):
    a = (SY - b * SX) / n + r.n() * SIG / sqrt(n)
    return a, (SXY - a * SX) / SXX + r.n() * SIG / sqrt(SXX)
def metro(r, a, b, sa, sb, only_a=False, mult=False, hastings=True):
    a2 = a + sa * r.n(); b2 = b if only_a else (b * exp(sb * r.n()) if mult else b + sb * r.n())
    lr = logf(a2, b2) - logf(a, b) + (log(b2 / b) if mult and hastings else 0.0)
    return (a2, b2, 1) if log(1.0 - r.u()) < lr else (a, b, 0)
N, BURN = 100000, 1000
def run(kind, seed, a=1.0, b=1.0, **kw):
    r = Rng(seed); A, B, K = [], [], []
    for t in range(BURN + N):
        if kind == "g": a, b = gibbs(r, b); k = 1
        else: a, b, k = metro(r, a, b, **kw)
        if t >= BURN: A.append(a); B.append(b); K.append(k)
    return A, B, K
for name, (A, B, K) in [("Gibbs", run("g", 7)), ("Metropolis", run("m", 11, sa=0.3, sb=0.09))]:
    ma, sea, _ = bm(A); mb, seb, essb = bm(B); p1, sep, _ = bm([1.0 if x > 1 else 0.0 for x in B])
    c, l1, ac, nt = corr(A, B), lag1(B), sum(K) / N, N / essb; sc, sl, sac = bse(corr, A, B), bse(lag1, B), bse(lambda x: sum(x) / len(x), K)
    snt = nt * sqrt(2 / 99)                   # N / ESS is read off 100 batch averages: relative SE sqrt(2/99)
    for k, v in [("mean a, SE", (ma, sea)), ("mean b, SE", (mb, seb)), ("P(b>1), SE", (p1, sep)), ("corr(a,b), SE", (c, sc)), ("acceptance rate, SE", (ac, sac)),
                 ("lag-1 autocorr of b, SE", (l1, sl)), ("N / ESS, SE", (nt, snt)), ("naive SE of b, sd/sqrt(N)", (sqrt(sum((y - mb) ** 2 for y in B) / N / N),))]:
        out(f"{name} {k}", *v)
    out(f"{name} ESS of b", essb, d=0)
    assert abs(c - rho) < 4 * sc
    if name == "Gibbs":
        assert abs(mb - bh) < 4 * seb and abs(ma - ah) < 4 * sea and abs(p1 - pB1) < 4 * sep
        assert abs(l1 - r2) < 4 * sl and abs(nt - tau) < 4 * snt
    else: assert abs(mb - bh) < 4 * seb and abs(p1 - pB1) < 4 * sep
r = Rng(5); b10 = []                         # 4,000 fresh chains from b = 0, ten sweeps each
for c in range(4000):
    b = 0.0
    for s in range(10): a, b = gibbs(r, b)
    b10.append(b)
m10 = sum(b10) / 4000; se10 = sqrt(sum((x - m10) ** 2 for x in b10) / 3999 / 4000); out("sweep 10: E[b] from 4000 chains, SE", m10, se10)
for name, kw in [("no Hastings factor", dict(mult=True, hastings=False)), ("with Hastings factor", dict(mult=True))]:
    _, B, _ = run("m", 13, sa=0.3, sb=0.1, **kw); mb, seb, _ = bm(B); out(f"{name}: mean b, SE", mb, seb)
    assert abs(mb - (wr if "no" in name else bh)) < 4 * seb
A, B, _ = run("m", 17, b=0.5, sa=0.3, sb=0.0, only_a=True); ma, sea, _ = bm(A); out("a-only from b=0.5: mean a, SE; exact", ma, sea, (SY - 0.5 * SX) / n)
r = Rng(3); b = 0.0; tr = [b]                 # one sample path for the burn-in chart
for s in range(30): a, b = gibbs(r, b); tr.append(b)
print("trace b, sweeps 0,2,..,30:", ", ".join(f"{tr[s]:.2f}" for s in range(0, 31, 2)))
print("E[b],  sweeps 0,2,..,30:", ", ".join(f"{bh * (1 - r2 ** s):.2f}" for s in range(0, 31, 2)))
r = Rng(2); b = 0.6; pts = []                 # figure: a Gibbs staircase over the 95% ellipse
for s in range(4): a, b2 = gibbs(r, b); pts += [(a, b), (a, b2)]; b = b2
px = lambda a, b: (40 + 100 * (a + 0.4), 220 - 200 * (b - 0.45))
L11 = sqrt(vA); L21 = cAB / L11; L22 = sqrt(vB - L21 * L21); R = sqrt(-2 * log(0.05))
ell = [px(ah + R * L11 * cos(2 * pi * k / 24), bh + R * (L21 * cos(2 * pi * k / 24) + L22 * sin(2 * pi * k / 24))) for k in range(24)]
print("figure, ellipse:", " ".join(f"{x:.1f},{y:.1f}" for x, y in ell)); print("figure, centre: %.1f,%.1f" % px(ah, bh))
print("figure, ticks: a=0,1,2 at x=%.0f,%.0f,%.0f; b=0.6,1.0,1.4 at y=%.0f,%.0f,%.0f" % (px(0, 0)[0], px(1, 0)[0], px(2, 0)[0], px(0, 0.6)[1], px(0, 1.0)[1], px(0, 1.4)[1]))
print("figure, staircase from b=0.6:", " ".join(f"{x:.1f},{y:.1f}" for x, y in [px(*p) for p in pts]))
def rho2(xs): return sum(xs) ** 2 / (len(xs) * sum(x * x for x in xs))   # squared corr(a,b) from the weeks alone
c0 = rho2([x - 3 for x in X]); out("try: centred weeks, rho^2 and tau", c0, (1 + c0) / (1 - c0)); r7 = rho2([1.0 * k for k in range(1, 8)])
out("try: 7 weeks, rho^2 and tau", r7, (1 + r7) / (1 - r7))
assert abs(gb - bh) < 1e-6; assert abs(ga - ah) < 1e-6; assert abs(gp - pB1) < 5e-4
assert imb < 1e-15; assert mstat < 1e-15; assert gstat < 1e-15
assert abs(Eb[10] - bh * (1 - r2 ** 10)) < 1e-3; assert TV[40] < 0.01 < TV[10]
assert abs(m10 - bh * (1 - r2 ** 10)) < 4 * se10; assert abs(ma - (SY - 0.5 * SX) / n) < 4 * sea
print("all asserts passed")
