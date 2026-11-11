# Bayesian optimisation of three turbine settings -- the check behind the card.  Standard library only.
# Settings scaled to 0..1: gate opening 0-100 %, blade angle 10-30 degrees, air 0-4 litres a second.
# Roads: (1) Gaussian-process surrogate + expected improvement, 15 trials; (2) every point of the
# 21 x 21 x 21 grid scored on the stand-in rig; (3) EI's formula against a numerical integral, and the
# surrogate's linear solve by Cholesky against plain elimination; (4) random search, 2000 seeded runs.
import math
PEAK, SHOULDER = (0.7, 0.35, 0.6), (0.3, 0.7, 0.3)
M, SF2, ELL, NOISE2 = 85.0, 25.0, 0.2, 0.01         # prior mean %, prior variance, length scale, noise
START = [(0.1, 0.5, 0.9), (0.3, 0.9, 0.3), (0.5, 0.1, 0.5), (0.7, 0.7, 0.1), (0.9, 0.3, 0.7)]
GRID = [(a / 20, b / 20, c / 20) for a in range(21) for b in range(21) for c in range(21)]
def d2(p, q): return sum((a - b) * (a - b) for a, b in zip(p, q))
def rig(x, w2=0.08):                                 # the stand-in test rig: efficiency in percent
    return 80 + 13 * math.exp(-d2(x, PEAK) / w2) + 8 * math.exp(-d2(x, SHOULDER) / 0.18)
def kern(p, q, ell): return SF2 * math.exp(-d2(p, q) / (2 * ell * ell))
def phi(z): return math.exp(-z * z / 2) / math.sqrt(2 * math.pi)
def Phi(z):                                          # normal CDF: series in the middle, continued fraction in the tails
    if abs(z) > 3:
        cf = abs(z)
        for k in range(40, 0, -1): cf = abs(z) + k / cf
        return phi(z) / cf if z < 0 else 1 - phi(z) / cf
    x = z / math.sqrt(2); term = x; s = x
    for n in range(60):
        term = -term * x * x / (n + 1); s += term / (2 * n + 3)
    return 0.5 + s / math.sqrt(math.pi)
def ei(mu, s, best):
    z = (mu - best) / s
    return (mu - best) * Phi(z) + s * phi(z)
def cholesky(K):
    n = len(K); L = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            t = K[i][j] - sum(L[i][k] * L[j][k] for k in range(j))
            L[i][j] = math.sqrt(t) if i == j else t / L[j][j]
    return L
def lower_solve(L, b):
    z = []
    for i in range(len(b)): z.append((b[i] - sum(L[i][k] * z[k] for k in range(i))) / L[i][i])
    return z
def surrogate(X, Y, ell):                            # returns x -> (posterior mean, posterior sd)
    K = [[kern(p, q, ell) + (NOISE2 if i == j else 0) for j, q in enumerate(X)] for i, p in enumerate(X)]
    L = cholesky(K); r = lower_solve(L, [y - M for y in Y])
    def post(x):
        v = lower_solve(L, [kern(x, p, ell) for p in X])
        return M + sum(a * b for a, b in zip(v, r)), math.sqrt(max(SF2 - sum(a * a for a in v), 1e-12))
    return post
def bo(rule="ei", ell=ELL, trials=15, w2=0.08):
    X = list(START); Y = [rig(x, w2) for x in X]; log = []
    while len(X) < trials:
        post, best, top = surrogate(X, Y, ell), max(Y), (-1.0, None)
        for x in GRID:
            mu, s = post(x)
            score = ei(mu, s, best) if rule == "ei" else mu if rule == "mean" else s
            if score > top[0]: top = (score, x)
        X.append(top[1]); Y.append(rig(top[1], w2)); log.append(top[0])
    return X, Y, log
def so_far(Y): return [max(Y[:i + 1]) for i in range(len(Y))]
def fmt(x): return "(" + ", ".join(f"{v:.2f}" for v in x) + ")"
# a hand-sized case: only trial 5 known, a candidate 0.2 away from it
y5, q = rig(START[4]), (0.7, 0.3, 0.7)
mu1, s1 = surrogate([START[4]], [y5], ELL)(q)
rho = math.exp(-d2(START[4], q) / (2 * ELL * ELL)); z1 = (mu1 - y5) / s1
wt = rho * SF2 / (SF2 + NOISE2)
print(f"one trial: y5 {y5:.4f}, correlation {rho:.4f}, weight {wt:.4f}, mean {mu1:.4f}, variance {s1 * s1:.4f}, sd {s1:.4f}")
print(f"one trial: z {z1:.4f} Phi {Phi(z1):.6f} phi {phi(z1):.6f} EI {mu1 - y5:.4f} x Phi + {s1:.4f} x phi = {(mu1 - y5) * Phi(z1):.4f} + {s1 * phi(z1):.4f} = {ei(mu1, s1, y5):.4f}")
mu0, s0 = surrogate([START[4]], [y5], ELL)(START[4])
print(f"at trial 5 itself: mean {mu0:.4f}, sd {s0:.4f}, EI {ei(mu0, s0, y5):.4f}")
assert abs(mu1 - (M + wt * (y5 - M))) < 1e-9          # the bivariate-normal rule
assert abs(s1 * s1 - (SF2 - rho * rho * SF2 * SF2 / (SF2 + NOISE2))) < 1e-9
X, Y, log = bo()
for i, (x, y) in enumerate(zip(X, Y)):
    tag = "start" if i < 5 else f"EI {log[i - 5]:5.3f}"
    print(f"trial {i + 1:2d} {fmt(x)} {tag:8s} -> {y:5.2f}  best {max(Y[:i + 1]):5.2f}")
best5 = max(Y[:5]); mu6, s6 = surrogate(X[:5], Y[:5], ELL)(X[5]); z6 = (mu6 - best5) / s6
print(f"pick 6: mean {mu6:.4f} sd {s6:.4f} z {z6:.4f} Phi {Phi(z6):.6f} phi {phi(z6):.6f} EI {(mu6 - best5) * Phi(z6):.4f} + {s6 * phi(z6):.4f} = {ei(mu6, s6, best5):.4f}")
# road 3a: EI's formula against Simpson's rule on the improvement integral
n = 4000; h = 10 * s6 / n
simp = sum((1 if j in (0, n) else 4 if j % 2 else 2) * j * h * phi((best5 + j * h - mu6) / s6) / s6 for j in range(n + 1)) * h / 3
print(f"road 3, EI formula {ei(mu6, s6, best5):.6f}  Simpson {simp:.6f}")
assert abs(ei(mu6, s6, best5) - simp) < 1e-6
# road 3b: the same mean by plain Gaussian elimination on the full system
A = [[kern(p, q, ELL) + (NOISE2 if i == j else 0) for j, q in enumerate(X[:5])] + [Y[i] - M] for i, p in enumerate(X[:5])]
for c in range(5):
    for r in range(c + 1, 5):
        g = A[r][c] / A[c][c]; A[r] = [a - g * b for a, b in zip(A[r], A[c])]
alpha = [0.0] * 5
for r in range(4, -1, -1): alpha[r] = (A[r][5] - sum(A[r][k] * alpha[k] for k in range(r + 1, 5))) / A[r][r]
mu_elim = M + sum(kern(X[5], p, ELL) * a for p, a in zip(X[:5], alpha))
print(f"road 3, mean at pick 6 by elimination {mu_elim:.6f}")
assert abs(mu_elim - mu6) < 1e-9
# road 2: score every grid point on the rig
gbest = max(GRID, key=rig)
print(f"road 2, all {len(GRID)} grid points: best {fmt(gbest)} -> {rig(gbest):.2f}; BO best {max(Y):.2f}")
assert max(Y) >= rig(gbest) - 1e-9                # BO reached the grid's best point
assert best5 < rig(gbest) - 5                      # and the start alone did not
tp, hs = list(gbest), 0.05                         # the rig's true peak: compass search from the grid's best
while hs > 1e-9:
    nb = max(([v + s * hs * (k == i) for k, v in enumerate(tp)] for i in range(3) for s in (1.0, -1.0)), key=rig)
    tp, hs = (nb, hs) if rig(nb) > rig(tp) else (tp, hs / 2)
print(f"road 2, between grid points: compass search from the grid's best reaches {rig(tp):.2f} at ({tp[0]:.3f}, {tp[1]:.3f}, {tp[2]:.3f})")
assert rig(tp) > rig(gbest) + 0.05                 # so the grid search certifies the grid's best, not the box's
b = X[Y.index(max(Y))]
print(f"best settings: gate {100 * b[0]:.0f} %, blade {10 + 20 * b[1]:.1f} degrees, air {4 * b[2]:.2f} L/s")
print(f"cost at GBP 20000 a trial: 15 trials {15 * 20000}, every grid point {len(GRID) * 20000}")
# road 4: random search, 2000 runs of 15 trials, SplitMix64 from seed 2026
MASK = (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, (z ^ (z >> 31)) >> 11
RUNS, state, avg, hits = 2000, 2026, [0.0] * 15, 0
for run in range(RUNS):
    ys = []
    for t in range(15):
        x = []
        for _ in range(3): state, u = splitmix(state); x.append(u / 2 ** 53)
        ys.append(rig(x))
    sf = so_far(ys); avg = [a + b / RUNS for a, b in zip(avg, sf)]; hits += sf[-1] >= 93
cells = [((a + .5) / 40, (b + .5) / 40, (c + .5) / 40) for a in range(40) for b in range(40) for c in range(40)]
frac = sum(rig(x) >= 93 for x in cells) / len(cells); p15 = 1 - (1 - frac) ** 15
print(f"random: share of the box at 93 or more {frac:.5f}; runs reaching 93: {hits / RUNS:.4f}, predicted {p15:.4f}")
assert abs(hits / RUNS - p15) < 3 * math.sqrt(p15 * (1 - p15) / RUNS) + 0.005
print("chart, BO best so far     " + " ".join(f"{v:.2f}" for v in so_far(Y)))
print("chart, random, average    " + " ".join(f"{v:.2f}" for v in avg))
Xm, Ym, _ = bo(rule="mean")
print("chart, highest mean only  " + " ".join(f"{v:.2f}" for v in so_far(Ym)) + f"; trial 6 at {fmt(Xm[5])}")
assert max(Ym) < max(Y) - 5                        # exploiting alone stalls on the start
assert avg[-1] < max(Y) - 3                        # random search trails on average
_, Ys, _ = bo(rule="sd")
_, Yr, _ = bo(ell=0.05)
_, Yn, _ = bo(w2=0.02)
print(f"wrong: most uncertain point only   {max(Ys):.2f}")
print(f"wrong: length scale 0.05           {max(Yr):.2f}")
print(f"broken: peak narrower, width 0.1   {max(Yn):.2f}, grid best {max(rig(x, 0.02) for x in GRID):.2f}")
for ell in (0.1, 0.3):
    Xt, Yt, _ = bo(ell=ell)
    print(f"try: length scale {ell}  best {max(Yt):.2f} at {fmt(Xt[Yt.index(max(Yt))])}, trial {Yt.index(max(Yt)) + 1}")
print("ALL CHECKS PASS")
