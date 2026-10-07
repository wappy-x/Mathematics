# Overfitting and cross-validation -- the check behind the card; only math is imported.
# A tide gauge reads the harbour level at hours 0 to 9.  The true level is
# sin(pi t / 6) metres; each reading adds gauge noise of SD 0.3 m (SplitMix64
# and Box-Muller, written out) and is rounded to the centimetre.  Polynomials
# of degree 0 to 9 are fitted by least squares and judged by several roads.
import math

N, SIG, SEED, FRESH, RECORDS = 10, 0.3, 20260922, 50000, 10000
M64 = 0xFFFFFFFFFFFFFFFF
TS = [float(t) for t in range(N)]

def splitmix64(s):                          # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
def uniform(s):                             # a draw in (0, 1] from 53 random bits
    s, z = splitmix64(s)
    return s, ((z >> 11) + 1) * 2.0 ** -53
def normal(s):                              # Box-Muller, cosine half only
    s, u1 = uniform(s)
    s, u2 = uniform(s)
    return s, math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
def tide(t): return math.sin(math.pi * t / 6.0)       # the true level, known because we built it
def powers(t, d): return [((t - 4.5) / 4.5) ** j for j in range(d + 1)]   # hours rescaled to [-1, 1]
def solve(a, b):                            # Gaussian elimination with partial pivoting
    p = len(b)
    m = [a[i][:] + [b[i]] for i in range(p)]
    for c in range(p):
        k = max(range(c, p), key=lambda r: abs(m[r][c]))
        m[c], m[k] = m[k], m[c]
        for r in range(c + 1, p):
            f = m[r][c] / m[c][c]
            for j in range(c, p + 1):
                m[r][j] -= f * m[c][j]
    x = [0.0] * p
    for c in range(p - 1, -1, -1):
        x[c] = (m[c][p] - sum(m[c][j] * x[j] for j in range(c + 1, p))) / m[c][c]
    return x
def gram(ts, d):                            # the rows of X, and X'X
    rows = [powers(t, d) for t in ts]
    return rows, [[sum(r[i] * r[j] for r in rows) for j in range(d + 1)] for i in range(d + 1)]
def fit(ts, ys, d):                         # least squares by the normal equations X'X c = X'y
    rows, a = gram(ts, d)
    return solve(a, [sum(r[i] * y for r, y in zip(rows, ys)) for i in range(d + 1)])
def pred(c, t): return sum(cj * x for cj, x in zip(c, powers(t, len(c) - 1)))
def hat(d):                                 # H = X (X'X)^-1 X': readings in, fitted values out
    rows, a = gram(TS, d)
    v = [solve(a, r) for r in rows]
    return [[sum(x * y for x, y in zip(rows[i], v[j])) for j in range(N)] for i in range(N)]
def lagrange(t):                            # degree 9 through all ten readings, no equations solved
    return sum(y * math.prod((t - s) / (ti - s) for s in TS if s != ti) for ti, y in zip(TS, YS))
def loo(ts, ys, d, i):                      # refit without reading i, return its held-out error
    return ys[i] - pred(fit(ts[:i] + ts[i + 1:], ys[:i] + ys[i + 1:], d), ts[i])
def fold(d, k):                             # 5 folds: fold k holds out hours k and k + 5
    c = fit([t for t in TS if t % 5 != k], [y for t, y in zip(TS, YS) if t % 5 != k], d)
    return sum((YS[i] - pred(c, TS[i])) ** 2 for i in (k, k + 5))
def mean_se(xs):                            # an average and its standard error
    m = sum(xs) / len(xs)
    return m, math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))
def f4(v): return f"{v:9.4f}" if v == v else "        -"

state, YS, fresh, recs = SEED, [], [], []
for t in TS:
    state, z = normal(state)
    YS.append(math.floor((tide(t) + SIG * z) * 100 + 0.5) / 100)
for _ in range(FRESH):                      # fresh readings at random hours in [0, 9]
    state, u = uniform(state)
    state, z = normal(state)
    fresh.append((9.0 * u, tide(9.0 * u) + SIG * z))
for _ in range(RECORDS):                    # whole new records at hours 0..9, each with a repeat reading
    one = []
    for t in TS:
        state, z = normal(state)
        state, z2 = normal(state)
        one.append((tide(t) + SIG * z, tide(t) + SIG * z2))
    recs.append(one)

print(f"setup: {N} readings at hours 0 to 9, gauge noise SD {SIG} m, noise variance {SIG * SIG:.4f}, seed {SEED}")
print("record, hour  " + "".join(f"{t:7.0f}" for t in TS))
print("record, level " + "".join(f"{y:7.2f}" for y in YS))
print("deg     train   5-fold  LOO-refit  LOO-hat   LOO-se  true-int  true-sim   sim-se  optim-sim  2s2p/n   opt-se")
R, fits = {}, {}
for d in range(10):
    c = fits[d] = fit(TS, YS, d)
    H = hat(d)
    train = sum((y - pred(c, t)) ** 2 for t, y in zip(TS, YS)) / N
    k2 = 1800                               # Simpson's rule on the squared gap to the truth
    integ = sum((1 if k in (0, k2) else 4 if k % 2 else 2) * (tide(k * 9 / k2) - pred(c, k * 9 / k2)) ** 2
                for k in range(k2 + 1)) * (9 / k2) / 3 / 9 + SIG * SIG
    sim, sim_se = mean_se([(y - pred(c, t)) ** 2 for t, y in fresh])
    kf = lr = lh = lse = float("nan")
    if d <= 7:                              # 8 readings pin at most 8 coefficients
        kf = sum(fold(d, k) for k in range(5)) / N
    if d <= 8:
        lr, lse = mean_se([loo(TS, YS, d, i) ** 2 for i in range(N)])
        lh = sum(((YS[i] - pred(c, TS[i])) / (1 - H[i][i])) ** 2 for i in range(N)) / N
    gaps = []                               # new reading's error minus training error, same hours
    for one in recs:
        yh = [sum(H[i][j] * one[j][0] for j in range(N)) for i in range(N)]
        gaps.append(sum((one[i][1] - yh[i]) ** 2 - (one[i][0] - yh[i]) ** 2 for i in range(N)) / N)
    gap, gse = mean_se(gaps)
    R[d] = dict(train=train, kf=kf, lr=lr, lh=lh, integ=integ, sim=sim, sim_se=sim_se, gap=gap, gse=gse,
                p=2 * SIG * SIG * (d + 1) / N, trace=sum(H[i][i] for i in range(N)), h=[H[i][i] for i in range(N)])
    print(f"{d:3d} {train:9.4f}{f4(kf)}{f4(lr)}{f4(lh)}{f4(lse)}{integ:9.4f}{sim:10.4f}{sim_se:9.4f}"
          f"{gap:10.4f}{R[d]['p']:9.4f}{gse:9.4f}")

best = {key: min(range(top), key=lambda d: R[d][key]) for key, top in
        (("train", 10), ("kf", 8), ("lr", 9), ("integ", 10))}
print(f"lowest training error: degree {best['train']}; lowest 5-fold: degree {best['kf']}; "
      f"lowest LOO: degree {best['lr']}; lowest true error: degree {best['integ']}")
print(f"degree 9 true error / degree 3 true error: {R[9]['integ'] / R[3]['integ']:.2f}")
print("degree 3, 5-fold held-out squared errors by fold (hours k, k+5): " + " ".join(f"{fold(3, k):.4f}" for k in range(5)))
e0, h0 = YS[0] - pred(fits[3], 0.0), R[3]["h"][0]
print(f"degree 3, hour 0: residual {e0:.4f}, leverage {h0:.4f}, residual/(1 - leverage) {e0 / (1 - h0):.4f}, "
      f"refit without it {loo(TS, YS, 3, 0):.4f}")
for d in (3, 9):
    print(f"degree {d}, leverages: " + " ".join(f"{h:.4f}" for h in R[d]["h"]) + f"; sum {R[d]['trace']:.4f}")
print(f"degree 9 at hour 8.75: normal equations {pred(fits[9], 8.75):.6f}, Lagrange {lagrange(8.75):.6f}, "
      f"truth {tide(8.75):.4f}")
T2, Y2 = TS + TS, YS + YS
leak = [sum(loo(T2, Y2, d, i) ** 2 for i in range(2 * N)) / (2 * N) for d in range(10)]
print("leak, LOO with every reading entered twice, degree 0..9: " + " ".join(f"{v:.4f}" for v in leak))
for name, key in (("training error", "train"), ("true error    ", "integ")):
    print(f"chart, {name} " + " ".join(f"{R[d][key]:.2f}" for d in range(10)))
X, Y = (lambda t: f"{40 + 32 * t:.1f}"), (lambda v: f"{20 + 40 * (1.4 - v):.1f}")
print("figure, readings " + " ".join(f"{X(t)},{Y(y)}" for t, y in zip(TS, YS)))
for name, g in (("truth", tide), ("degree 3", lambda t: pred(fits[3], t)), ("degree 9", lambda t: pred(fits[9], t))):
    print(f"figure, {name} " + " ".join(f"{X(k / 4)},{Y(g(k / 4))}" for k in range(37)))

for d in range(9):                          # the shortcut and the refits are separate roads
    assert abs(R[d]["lr"] - R[d]["lh"]) < 1e-7 * max(1.0, R[d]["lr"]), f"LOO shortcut vs refit, degree {d}"
for d in range(10):
    assert abs(R[d]["integ"] - R[d]["sim"]) < 4 * R[d]["sim_se"], f"Simpson vs fresh readings, degree {d}"
    assert abs(R[d]["gap"] - R[d]["p"]) < 4 * R[d]["gse"], f"simulated optimism vs 2 sigma^2 p / n, degree {d}"
    assert abs(R[d]["trace"] - (d + 1)) < 1e-8, f"sum of leverages vs number of coefficients, degree {d}"
assert abs(pred(fits[9], 8.75) - lagrange(8.75)) < 1e-6, "normal equations vs Lagrange at degree 9"
assert best["lr"] == best["integ"], "leave-one-out picks the degree with the lowest true error"
print("ALL CHECKS PASS")
