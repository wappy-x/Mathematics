# Bermudan swaption by regression -- the check behind the card.  Standard library only.  One-factor market
# model, six annual forwards, simulated under the year-6 bond.  Road 1: Longstaff-Schwartz lower bound.
# Road 2: Andersen-Broadie dual upper bound.  Road 3: a recombining tree.  Random numbers, N(x): our own.
from math import exp, log, sqrt, cos, pi

L0, SIG, K, M = 0.05, 0.20, 0.05, 6        # flat 5% forwards, 20% vol, 5% strike, swap ends year 6
N_TRAIN, N_EVAL, N_OUT, N_IN = 100000, 400000, 500, 400
MASK, seed = (1 << 64) - 1, 20260928
def u64():                                  # splitmix64 random bits
    global seed
    seed = (seed + 0x9E3779B97F4A7C15) & MASK
    z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def normal():                               # Box-Muller: two uniforms in, one standard normal out
    u1 = ((u64() >> 11) + 1) * 2.0 ** -53;  return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * ((u64() >> 11) * 2.0 ** -53))

def step(L, t, z, sig=SIG):                 # year t -> t+1 under the year-6 bond, predictor-corrector drift
    new, s_old, s_new = L[:], 0.0, 0.0
    for i in range(M - 1, t, -1):           # the last forward has no drift; each earlier one feels those after it
        new[i] = L[i] * exp(-sig * sig * 0.5 * (s_old + s_new) - 0.5 * sig * sig + sig * z)
        s_old += L[i] / (1.0 + L[i]); s_new += new[i] / (1.0 + new[i])
    return new
def exercise(L, e, k=K):                    # swap entered at year e: spread x (points), deflated value h, P(e,6)
    P, A = 1.0, 0.0
    for j in range(e, M):
        P = P / (1.0 + L[j]); A += P
    return 100.0 * ((1.0 - P) / A - k), max(1.0 - P - k * A, 0.0) / P, P

def cont(b, x): return b[0] + b[1] * x + b[2] * x * x
def fit(pts):                               # least squares on 1, x, x^2: normal equations, Gauss-Jordan
    G = [[0.0] * 4 for _ in range(3)]
    for x, y in pts:
        v = (1.0, x, x * x)
        for r in range(3):
            for c in range(3): G[r][c] += v[r] * v[c]
            G[r][3] += v[r] * y
    for c in range(3):
        for r in range(3):
            if r != c:
                f = G[r][c] / G[c][c]
                for k in range(4): G[r][k] -= f * G[c][k]
    return [G[r][3] / G[r][r] for r in range(3)]
def mean_se(v):
    s = q = 0.0
    for a in v: s += a; q += a * a
    m = s / len(v);  return m, sqrt((q / len(v) - m * m) / (len(v) - 1))

# ---- train: simulate curves, regress backwards from year 4 to year 1, freeze the rule ----
train = []
for _ in range(N_TRAIN):
    L, row = [L0] * M, [(0.0, 0.0, 1.0)]
    for t in range(5):
        L = step(L, t, normal()); row.append(exercise(L, t + 1))
    train.append(row)
cash, beta, greedy = [r[5][1] for r in train], [None] * 6, []
for e in range(4, 0, -1):
    beta[e] = fit([(train[k][e][0], cash[k]) for k in range(N_TRAIN) if train[k][e][1] > 0.0])
    for k in range(N_TRAIN):
        if train[k][e][1] > 0.0 and train[k][e][1] >= cont(beta[e], train[k][e][0]): cash[k] = train[k][e][1]
for r in train: greedy.append(next((r[e][1] for e in range(1, 6) if r[e][1] > 0.0), 0.0))
def stop(e, x, h): return h > 0.0 and (e == 5 or h >= cont(beta[e], x))
def run_policy(L, t):                       # from year t on (no decision at t itself): deflated payoff, year
    while t < 5:
        L = step(L, t, normal()); t += 1
        x, h, _ = exercise(L, t)
        if stop(t, x, h): return h, t
    return 0.0, 0

# ---- road 1: the frozen rule on fresh curves gives a lower bound ----
pay, years = [], [0] * 6
for _ in range(N_EVAL):
    h, y = run_policy([L0] * M, 0); pay.append(h); years[y] += 1
lo, lo_se = mean_se(pay)
# ---- road 2: Andersen-Broadie.  Inner simulations give hold values C; they build a martingale ----
gap, fore = [], []
for _ in range(N_OUT):
    L, Ls, xs, hs, C = [L0] * M, [None] * 6, [0.0] * 6, [0.0] * 6, [0.0] * 6
    for t in range(1, 6):
        L = step(L, t - 1, normal()); Ls[t] = L; xs[t], hs[t], _ = exercise(L, t)
    for t in range(1, 5):
        acc = 0.0
        for _ in range(N_IN): acc += run_policy(Ls[t], t)[0]
        C[t] = acc / N_IN
    val = [hs[t] if stop(t, xs[t], hs[t]) else C[t] for t in range(6)]   # the rule's value on this path
    mart, best = val[1], hs[1] - val[1]     # the martingale starts at the rule's year-1 value
    for t in range(2, 6):
        mart += val[t] - C[t - 1]
        best = max(best, hs[t] - mart)
    gap.append(best); fore.append(max(hs[1:]))
g, g_se = mean_se(gap)
# ---- road 3: a recombining tree on the single shock, drifts frozen at today's curve ----
def tree(sig=SIG, shift=0.0, k=K, bermudan=True, m=200):
    f, mu, p6 = [L0 + shift] * M, [], 1.0
    for i in range(M):
        s = 0.0
        for j in range(i + 1, M): s += f[j] / (1.0 + f[j])
        mu.append(-sig * sig * s); p6 = p6 / (1.0 + f[i])
    V = [0.0] * (5 * m + 1)
    for e in range(5, 0, -1):
        for j in range(e * m + 1 if bermudan or e == 1 else 0):
            w = (2 * j - e * m) / sqrt(m)
            V[j] = max(V[j], exercise([f[i] * exp((mu[i] - 0.5 * sig * sig) * e + sig * w) for i in range(M)], e, k)[1])
        for n in range(e * m, (e - 1) * m, -1): V = [0.5 * (V[j] + V[j + 1]) for j in range(n)]
    return 100.0 * p6 * V[0]
def ncdf(x, n=4000):                        # N(x): one half, plus Simpson's rule on the bell curve from 0 to x
    h, s = x / n, 0.0
    for i in range(n + 1): s += (1 if i in (0, n) else 4 if i % 2 else 2) * exp(-0.5 * (i * h) * (i * h))
    return 0.5 + s * h / 3.0 / sqrt(2.0 * pi)
P06, A0 = (1.0 + L0) ** -6.0, 0.0
for i in range(2, M + 1): A0 += (1.0 + L0) ** -float(i)
eu_black = 100.0 * A0 * (L0 * ncdf(0.5 * SIG) - K * ncdf(-0.5 * SIG))
eu_mc, eu_se = mean_se([100.0 * P06 * r[1][1] for r in train])
tb, te, D = tree(), tree(bermudan=False), 100.0 * P06
rows = [("P(0,6)  year-6 bond today", P06), ("A(0)  annuity, years 2 to 6", A0), ("N(d1), d1 = 0.1", ncdf(0.5 * SIG)), ("N(d2), d2 = -0.1", ncdf(-0.5 * SIG)),
        ("european, Black formula", eu_black), ("european, simulation", eu_mc), ("  standard error", eu_se),
        ("european, tree", te), ("1 lower bound, fresh paths", D * lo), ("  standard error", D * lo_se),
        ("  duality gap", D * g), ("  standard error", D * g_se), ("2 dual upper bound", D * (lo + g)),
        ("  standard error", D * sqrt(lo_se * lo_se + g_se * g_se)), ("3 bermudan, tree", tb),
        ("extra dates worth, tree", tb - te), ("wrong: exercise when first in the money", D * mean_se(greedy)[0]),
        ("wrong: no martingale, perfect foresight", D * mean_se(fore)[0]),
        ("delta, bermudan per 1bp up", tree(shift=0.0001) - tb), ("delta, european per 1bp up", tree(shift=0.0001, bermudan=False) - te),
        ("vega, bermudan per vol point", tree(sig=0.21) - tb), ("vega, european per vol point", tree(sig=0.21, bermudan=False) - te),
        ("try: vol 10%, tree bermudan", tree(sig=0.10)), ("try: strike 6%, tree bermudan", tree(k=0.06))]
print("percent of notional unless marked")
for name, v in rows: print(f"{name:<42} {v:>12.6f}")
print(f"dollars per 1,000,000: lower {1e4 * D * lo:.2f}  upper {1e4 * D * (lo + g):.2f}  tree {1e4 * tb:.2f}")
print("coefficients by year (1, x, x^2):")
for e in range(1, 5): print(f"  year {e}  " + "  ".join(f"{b:>11.6f}" for b in beta[e]))
print("exercised in year 1..5, never: " + " ".join(f"{years[y]}" for y in (1, 2, 3, 4, 5, 0)))
grid = [exercise([L0] + [0.05 + 0.005 * i] * 5, 1) for i in range(7)]
print("chart, year-1 swap rate %     " + " ".join(f"{5.0 + 0.5 * i:6.2f}" for i in range(7)))
print("chart, take now %             " + " ".join(f"{100.0 * p * h:6.2f}" for x, h, p in grid))
print("chart, hold (fitted) %        " + " ".join(f"{100.0 * p * cont(beta[1], x):6.2f}" for x, h, p in grid))
assert abs(eu_mc - eu_black) < 3.0 * eu_se, "simulated european vs Black formula"
assert abs(te - eu_black) < 0.01, "tree european vs Black formula"
assert abs(tb - D * (lo + g)) < 3.0 * D * lo_se + 0.01, "tree bermudan vs the simulated bracket"
assert 0.0 <= D * g < 0.01, "duality gap nonnegative and under 0.01% of the loan"
assert mean_se(greedy)[0] < lo, "the fitted rule beats exercising at first chance"
print("ALL CHECKS PASS")
