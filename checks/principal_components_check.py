# Principal components -- the check behind the card.  Only math is imported.
# 500 simulated trading days of yield-curve changes at 10 tenors (3m 6m 1y 2y
# 3y 5y 7y 10y 20y 30y), in basis points (bp, hundredths of a percent), built
# from three hidden shapes plus noise.  PCA must find the shapes.  Seed 2026.
import math

D, N, REPS, M64 = 10, 500, 200, (1 << 64) - 1
LEVEL = [1.0] * D                                          # every tenor moves 1
SLOPE = [2.0 * j - 9 for j in range(D)]                    # -9, -7, ..., 9
CURVE = [((2.0 * j - 9) * (2.0 * j - 9) - 33) / 8 for j in range(D)]  # 6, 2, -1, -3, -4, ...
SHAPES, SDS, NOISE = [LEVEL, SLOPE, CURVE], [3.0, 0.2, 0.15], 0.5

class Rng:                                                 # SplitMix64
    def __init__(self, seed): self.s = seed
    def unif(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
    def normal(self):                                      # Box-Muller, cosine half
        u1 = self.unif(); u2 = self.unif()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def add(xs):                                               # plain left-to-right sum
    s = 0.0
    for x in xs: s += x
    return s
def dot(a, b): return add(x * y for x, y in zip(a, b))
def unit(v): n = math.sqrt(dot(v, v)); return [x / n for x in v]
def trace(m): return add(m[i][i] for i in range(D))
def row(label, vals, f="{:8.2f}"): print(f"{label:<30}" + "".join(f.format(x) for x in vals))
def fix_sign(v): return v if v[D - 1] >= 0 else [-x for x in v]   # 30y entry positive

def one_day(rng):                                          # three shape shocks, then noise
    f = [rng.normal() * sd for sd in SDS]
    return [f[0] * LEVEL[j] + f[1] * SLOPE[j] + f[2] * CURVE[j] + NOISE * rng.normal() for j in range(D)]
def simulate(rng, n): return [one_day(rng) for _ in range(n)]

def covariance(days, centre=True):                         # divide by n - 1
    n = len(days); mean = [0.0] * D
    for x in days:
        for j in range(D): mean[j] += x[j] / n
    c, off = [[0.0] * D for _ in range(D)], (mean if centre else [0.0] * D)
    for x in days:
        y = [x[j] - off[j] for j in range(D)]
        for i in range(D):
            for j in range(D): c[i][j] += y[i] * y[j]
    return mean, [[v / (n - 1) for v in r] for r in c]

def jacobi(m):                                             # road 1: rotate until diagonal
    a = [r[:] for r in m]; v = [[float(i == j) for j in range(D)] for i in range(D)]
    for _ in range(60):
        if add(a[i][j] * a[i][j] for i in range(D) for j in range(D) if i != j) < 1e-24: break
        for p in range(D):
            for q in range(p + 1, D):
                if a[p][q] == 0.0: continue
                th = (a[q][q] - a[p][p]) / (2.0 * a[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1.0))
                c = 1.0 / math.sqrt(t * t + 1.0); s = t * c
                for k in range(D): a[k][p], a[k][q] = c * a[k][p] - s * a[k][q], s * a[k][p] + c * a[k][q]
                for k in range(D): a[p][k], a[q][k] = c * a[p][k] - s * a[q][k], s * a[p][k] + c * a[q][k]
                for k in range(D): v[k][p], v[k][q] = c * v[k][p] - s * v[k][q], s * v[k][p] + c * v[k][q]
    order = sorted(range(D), key=lambda k: -a[k][k])
    return [a[k][k] for k in order], [fix_sign([v[i][k] for i in range(D)]) for k in order]

def power_top(m, k):                                       # road 2: multiply and deflate
    a = [r[:] for r in m]; out = []
    for _ in range(k):
        v = [j + 1.0 for j in range(D)]
        for _ in range(1000):
            w = [dot(r, v) for r in a]; nw = math.sqrt(dot(w, w)); v = [x / nw for x in w]
        lam = dot(v, [dot(r, v) for r in a]); out.append((lam, fix_sign(v)))
        a = [[a[i][j] - lam * v[i] * v[j] for j in range(D)] for i in range(D)]
    return out

# ---- exact: the model's own covariance, and its eigenvalues by hand ----
sigma = [[NOISE * NOISE * (i == j) + add(sd * sd * b[i] * b[j] for sd, b in zip(SDS, SHAPES))
          for j in range(D)] for i in range(D)]
exact = [sd * sd * dot(b, b) + NOISE * NOISE for sd, b in zip(SDS, SHAPES)] + [NOISE * NOISE]
lam_sigma = jacobi(sigma)[0]; row("exact, eigenvalues (bp^2)", exact, "{:8.4f}")
row("jacobi on the model, top four", lam_sigma[:4], "{:8.4f}")
row("exact, shares 1-3 and top two %", [100 * e / trace(sigma) for e in exact[:3]] + [100 * (exact[0] + exact[1]) / trace(sigma)])
row("exact, length^2 and shape part", [dot(b, b) for b in SHAPES] + [sd * sd * dot(b, b) for sd, b in zip(SDS, SHAPES)])
print(f"exact, total variance (trace)  {trace(sigma):.4f}"); assert max(abs(lam_sigma[k] - exact[k]) for k in range(4)) < 1e-9
# ---- simulated: 200 samples of 500 days; the first is the card's sample ----
rng = Rng(2026); lam1s, top2s = [], []
for rep in range(REPS):
    days = simulate(rng, N); mean, S = covariance(days); lam, vec = jacobi(S)
    lam1s.append(lam[0]); top2s.append((lam[0] + lam[1]) / trace(S))
    if rep == 0: days0, mean0, S0, lam0, vec0 = days, mean, S, lam, vec
    if rep == 1: vec1 = vec
row("sample, variance by tenor", [S0[j][j] for j in range(D)])
row("sample, eigenvalues 1-10", lam0, "{:8.3f}")
tot = trace(S0); row("sample, share % (chart)", [100 * l / tot for l in lam0])
row("sample, cumulative %", [100 * add(lam0[:k + 1]) / tot for k in range(D)])
print(f"sample, trace {tot:.4f} = eigenvalue sum {add(lam0):.4f}")
assert abs(tot - add(lam0)) < 1e-9
se = [e * math.sqrt(2.0 / (N - 1)) for e in exact[:3]]; row("sample vs exact, formula SE", se, "{:8.3f}")
row("sample vs exact, gap in SEs", [(lam0[k] - exact[k]) / se[k] for k in range(3)])
for k in range(3): assert abs(lam0[k] - exact[k]) < 4 * se[k]
m1 = add(lam1s) / REPS; sd1 = math.sqrt(add((x - m1) * (x - m1) for x in lam1s) / (REPS - 1))
m2 = add(top2s) / REPS; sd2 = math.sqrt(add((x - m2) * (x - m2) for x in top2s) / (REPS - 1))
print(f"replicates, lambda1 mean {m1:.3f}  sd {sd1:.3f}  formula SE {se[0]:.3f}")
print(f"replicates, top-two share mean {100 * m2:.3f}%  sd {100 * sd2:.3f}%")
assert abs(sd1 / se[0] - 1) < 0.15
# ---- the directions: loadings, bp moves, and agreement with the hidden shapes ----
for k in range(3): row(f"loadings, PC{k + 1}", vec0[k], "{:8.3f}")
for k in range(3): row(f"chart, PC{k + 1} one-SD day (bp)", [math.sqrt(lam0[k]) * x for x in vec0[k]])
row("cosine with hidden shape 1-3", cos := [abs(dot(vec0[k], unit(SHAPES[k]))) for k in range(3)], "{:8.4f}")
assert min(cos) > 0.98
pw = power_top(S0, 2)
print(f"power iteration, top two {pw[0][0]:.6f} {pw[1][0]:.6f}")
gap = max(abs(pw[k][1][j] - vec0[k][j]) for k in range(2) for j in range(D))
print(f"power vs jacobi, largest loading gap below 1e-9: {'yes' if gap < 1e-9 else 'no'}")
assert max(abs(pw[k][0] - lam0[k]) for k in range(2)) < 1e-8
assert gap < 1e-9
# ---- reduce 10 numbers a day to 2 scores, and rebuild ----
ys = [[x[j] - mean0[j] for j in range(D)] for x in days0]
z = [[dot(vec0[k], y) for k in range(2)] for y in ys]
var1 = add(s[0] * s[0] for s in z) / (N - 1); cov12 = add(s[0] * s[1] for s in z) / (N - 1)
print(f"scores, variance of PC1 scores {var1:.6f}; PC1-PC2 covariance {abs(cov12):.6f}")
assert abs(var1 - lam0[0]) < 1e-8
err = add((y[j] - s[0] * vec0[0][j] - s[1] * vec0[1][j]) ** 2 for y, s in zip(ys, z) for j in range(D)) / (N - 1)
print(f"reduce, rebuild error per day {err:.6f} vs eigenvalues 3-10 {add(lam0[2:]):.6f}")
assert abs(err - add(lam0[2:])) < 1e-8
row("day 1, actual change (bp)", days0[0])
print(f"day 1, scores PC1 {z[0][0]:.2f}  PC2 {z[0][1]:.2f}")
row("day 1, rebuilt from 2 scores", [mean0[j] + z[0][0] * vec0[0][j] + z[0][1] * vec0[1][j] for j in range(D)])
best = max(dot(u, [dot(r, u) for r in S0]) for u in (unit([rng.normal() for _ in range(D)]) for _ in range(2000)))
print(f"random directions, best of 2000 {best:.3f} vs lambda1 {lam0[0]:.3f}")
assert best <= lam0[0]
# ---- what breaks ----
pct = [x[:D - 1] + [x[D - 1] / 100] for x in days0]; Sp = covariance(pct)[1]; lp, vp = jacobi(Sp)
print(f"breaks, 30y in percent: top-two share {100 * (lp[0] + lp[1]) / trace(Sp):.2f}%, PC1 30y loading {vp[0][D - 1]:.4f}")
level, lev = [400.0 + 5 * s for s in SLOPE], []
for x in days0: level = [level[j] + x[j] for j in range(D)]; lev.append(level)
avg, Mu = covariance(lev, centre=False); lu, vu = jacobi(Mu)
print(f"breaks, levels uncentred: PC1 share {100 * lu[0] / trace(Mu):.3f}%, cosine with average curve {abs(dot(vu[0], unit(avg))):.4f}")
row("breaks, sample 1 vs 2: cosine PC1-5", [abs(dot(vec0[k], vec1[k])) for k in range(5)], "{:8.4f}")
print("ALL CHECKS PASS")
