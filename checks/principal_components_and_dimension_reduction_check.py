# Principal components and dimension reduction -- the check behind the card.  Only math is imported.
# 20,000 synthetic shop orders, 12 numbers each in mixed units, made by a stated rule from three
# hidden traits (basket size, loyalty, browsing) plus noise; 15% are trade buyers.  Seed 2026.
import math

N, D, P_TRADE, SHIFT, M64 = 20000, 12, 0.15, [2.5, 1.5, 0.0], (1 << 64) - 1
# name, unit, base value, loadings on (size, loyalty, browsing), noise sd
FEATS = [("basket value", "GBP", 60, [25, 5, 4], 12), ("items", "count", 6, [1.8, .3, .5], 1),
         ("distinct products", "count", 4, [1.3, .2, .6], .8), ("parcel weight", "kg", 5, [1.6, 0, .2], 1),
         ("shipping charged", "GBP", 4.5, [1, -.8, 0], 1), ("discount", "GBP", 6, [2.5, 2, 1], 2.5),
         ("orders past year", "count", 8, [.5, 4, 0], 2), ("days since last", "days", 50, [0, -15, 0], 12),
         ("minutes on site", "min", 14, [2, -1, 5], 3), ("pages viewed", "count", 18, [3, -1, 7], 4),
         ("share on sale", "%", 25, [0, 3, 7], 6), ("delivery distance", "km", 30, [0, 0, 0], 12)]

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

def add(xs):                                               # plain left-to-right sum, as in Rust
    s = 0.0
    for x in xs: s += x
    return s
def dot(a, b): return add(x * y for x, y in zip(a, b))
def line(label, vals, f="{:8.4f}"): print(f"{label:<32}" + "".join(f.format(x) for x in vals))

def covariance(rows):                                      # centre each column, divide by n - 1
    n = len(rows); m = [add(r[j] for r in rows) / n for j in range(D)]
    c = [[r[j] - m[j] for r in rows] for j in range(D)]
    return [[dot(c[i], c[j]) / (n - 1) for j in range(D)] for i in range(D)], m

def jacobi_eig(a):                                         # rotate pairs until the matrix is diagonal
    a = [r[:] for r in a]; v = [[float(i == j) for j in range(D)] for i in range(D)]
    for _ in range(60):
        if add(a[i][j] ** 2 for i in range(D) for j in range(D) if i != j) < 1e-24: break
        for p in range(D):
            for q in range(p + 1, D):
                if a[p][q] == 0.0: continue
                th = (a[q][q] - a[p][p]) / (2.0 * a[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1.0))
                c = 1.0 / math.sqrt(t * t + 1.0); s = t * c
                for m in (a, v):
                    for k in range(D): x, y = m[k][p], m[k][q]; m[k][p] = c * x - s * y; m[k][q] = s * x + c * y
                for k in range(D): x, y = a[p][k], a[q][k]; a[p][k] = c * x - s * y; a[q][k] = s * x + c * y
    pairs = [(a[i][i], [v[k][i] for k in range(D)]) for i in range(D)]
    out = []
    while pairs:                                           # largest eigenvalue first, by selection
        b = max(range(len(pairs)), key=lambda i: pairs[i][0]); lam, u = pairs.pop(b)
        big = max(range(D), key=lambda k: abs(u[k]))       # sign: largest loading positive
        out.append((lam, u if u[big] > 0 else [-x for x in u]))
    return out

def svd_values(cols):                                      # one-sided Jacobi on the data table itself
    cols = [c[:] for c in cols]
    for _ in range(30):
        worst = 0.0
        for p in range(D):
            for q in range(p + 1, D):
                al, be, ga = dot(cols[p], cols[p]), dot(cols[q], cols[q]), dot(cols[p], cols[q])
                worst = max(worst, abs(ga) / math.sqrt(al * be))
                ze = (be - al) / (2.0 * ga)
                t = (1.0 if ze >= 0 else -1.0) / (abs(ze) + math.sqrt(ze * ze + 1.0))
                c = 1.0 / math.sqrt(t * t + 1.0); s = t * c
                x, y = cols[p], cols[q]
                cols[p] = [c * a - s * b for a, b in zip(x, y)]; cols[q] = [s * a + c * b for a, b in zip(x, y)]
        if worst < 1e-13: break
    sv = [dot(c, c) for c in cols]                          # squared singular values
    return [sv.pop(max(range(len(sv)), key=lambda i: sv[i])) for _ in range(D)]   # largest first

# ---- the data: 20,000 orders ----
rng = Rng(2026); X, trade = [], []
for _ in range(N):
    t = 1.0 if rng.unif() < P_TRADE else 0.0
    h = [rng.normal() + SHIFT[k] * t for k in range(3)]
    X.append([f[2] + dot(f[3], h) + f[4] * rng.normal() for f in FEATS]); trade.append(t)
below = add(1.0 for r in X for x in r if x < 0) / (N * D) * 100
print(f"orders {N}, trade buyers {int(add(trade))}, values below zero per 100: {below:.2f}")
C, mean = covariance(X); sd = [math.sqrt(C[j][j]) for j in range(D)]
Z = [[(r[j] - mean[j]) / sd[j] for j in range(D)] for r in X]          # standardise every column
R, _ = covariance(Z)
eig = jacobi_eig(R); lam = [e[0] for e in eig]; U = [e[1] for e in eig]
z1 = Z[0]
print(f"{'feature':<18}{'unit':>6}{'mean':>8}{'sd':>8}{'order 1':>9}{'z':>7}{'PC1':>7}{'PC2':>7}{'PC3':>7}{'PC4':>7}")
for j, f in enumerate(FEATS):
    print(f"{f[0]:<18}{f[1]:>6}{mean[j]:8.2f}{sd[j]:8.2f}{X[0][j]:9.2f}{z1[j]:7.2f}" + "".join(f"{U[k][j]:7.2f}" for k in range(4)))

# ---- road 1: eigenvalues of the correlation matrix; road 2: SVD of the table; road 3: the model's truth ----
sv = [s / (N - 1) for s in svd_values([[r[j] for r in Z] for j in range(D)])]
p = P_TRADE * (1 - P_TRADE)                                # the model's covariance, exactly
Sz = [[float(i == j) + p * SHIFT[i] * SHIFT[j] for j in range(3)] for i in range(3)]
A = [f[3] for f in FEATS]
S = [[dot(A[i], [dot(Sz[k], A[j]) for k in range(3)]) + (FEATS[i][4] ** 2 if i == j else 0) for j in range(D)] for i in range(D)]
true = [e[0] for e in jacobi_eig([[S[i][j] / math.sqrt(S[i][i] * S[j][j]) for j in range(D)] for i in range(D)])]
def cum(ls): tot = add(ls); return [add(ls[:k + 1]) / tot * 100 for k in range(D)]
for lab, v, f in (("eigenvalues, Jacobi on R", lam, "{:7.3f}"), ("eigenvalues, SVD of the table", sv, "{:7.3f}"),
                  ("eigenvalues, the model's truth", true, "{:7.3f}"), ("kept by first r, data, %", cum(lam), "{:7.2f}"),
                  ("kept by first r, truth, %", cum(true), "{:7.2f}")): line(lab, v, f)
gap = max(abs(a - b) for a, b in zip(cum(lam), cum(true)))
r85 = next(k + 1 for k in range(D) if cum(lam)[k] >= 85.0)
print(f"components needed for 85%: r = {r85}, keeping {cum(lam)[r85 - 1]:.2f}%; largest gap to truth {gap:.2f} points")
print(f"trace of R {add(R[i][i] for i in range(D)):.4f}, eigenvalue sum {add(lam):.4f}")

# ---- road 4: straight from the orders: score variance and the rebuild error ----
scores = [[dot(U[k], z) for k in range(D)] for z in Z]
var1 = add(s[0] ** 2 for s in scores) / (N - 1)
lost = add(add((z[j] - add(s[k] * U[k][j] for k in range(r85))) ** 2 for j in range(D)) for z, s in zip(Z, scores)) / (N - 1)
print(f"variance of the 20,000 PC1 scores {var1:.4f}; rebuild error with r = 4 {lost:.4f}, last eight eigenvalues {add(lam[4:]):.4f}")
print("order 1 PC1 products " + " ".join(f"{U[0][j] * z1[j]:.2f}" for j in range(D)) + f" -> score {scores[0][0]:.4f}")
line("order 1 scores PC1 to PC4", scores[0][:4], "{:8.4f}")
line("order 1 rebuilt from 4, raw units", [mean[j] + sd[j] * add(scores[0][k] * U[k][j] for k in range(4)) for j in range(D)], "{:7.2f}")

# ---- what breaks ----
raw = jacobi_eig(C)
print(f"wrong, raw units: PC1 keeps {cum([e[0] for e in raw])[0]:.2f}%, loading on basket value {raw[0][1][0]:.2f}, on items {raw[0][1][1]:.2f}; "
      f"two keep {cum([e[0] for e in raw])[1]:.2f}%; PC3 loading on distance {raw[2][1][11]:.2f}")
print(f"wrong, order 1 not standardised: PC1 score {dot(U[0], X[0]):.2f}, right {scores[0][0]:.2f}")
print(f"wrong, the 2-D plot read as the 85% summary: it keeps {cum(lam)[1]:.2f}%")
print(f"pure-noise column (distance): PC4 eigenvalue {lam[3]:.4f}, loading {U[3][11]:.4f}, share {lam[3] / D * 100:.2f}%")
# ---- the figure: every 400th order, PC1 across and PC2 up, 18 units per score unit on both axes ----
px = lambda s1: math.floor(160 + 18 * s1 + 0.5); py = lambda s2: math.floor(120 - 18 * s2 + 0.5)
for g, name in ((0.0, "households"), (1.0, "trade buyers")):
    k = add(1.0 for t in trade if t == g); c1, c2 = (add(s[i] for s, t in zip(scores, trade) if t == g) / k for i in (0, 1))
    print(f"figure, centre of the {name:<13} x {px(c1)} y {py(c2)}   (scores PC1 {c1:5.2f}, PC2 {c2:5.2f})")
pts = [(px(scores[i][0]), py(scores[i][1]), int(trade[i])) for i in range(0, N, 400)]
for k in range(0, 50, 10): print("figure, x,y,trade " + " ".join(f"{a},{b},{c}" for a, b, c in pts[k:k + 10]))

assert r85 == 4 and abs(cum(lam)[3] - 85.82) < 0.01,         "four components clear 85 percent"
assert max(abs(a - b) for a, b in zip(lam, sv)) < 1e-9,       "SVD of the table meets the covariance road"
assert gap < 0.5,                                             "sample shares within half a point of the model"
assert abs(var1 - lam[0]) < 1e-9,                             "variance along PC1 is its eigenvalue"
assert abs(lost - add(lam[4:])) < 1e-9,                       "rebuild error is the dropped eigenvalues"
assert abs(add(lam) - D) < 1e-9,                              "eigenvalues share out the 12 units of variance"
assert all(30 <= a <= 350 and 26 <= b <= 214 for a, b, _ in pts), "every plotted order inside the frame"
print("ALL CHECKS PASS")
