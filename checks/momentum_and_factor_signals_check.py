# Momentum 12-1 decile sort, spread and Newey-West error -- the check behind the card.
# Standard library only. The market is invented, so its hidden drifts are known.
from math import sqrt, log, cos, pi
M64 = (1 << 64) - 1
state = 20260928
def unif():                                   # splitmix64 -> a number in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def gauss():                                  # Box-Muller, one draw per pair
    u1, u2 = unif(), unif()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

# ---- the invented market: 300 stocks, 252 months ----
N, TT, SMU = 300, 252, 0.0063
mu = [SMU * gauss() for _ in range(N)]        # each stock's slow drift, per month
b = [gauss() for _ in range(N)]               # each stock's loading on a style tide
eprev, f = [0.0] * N, 0.0
R, DRIFT = [], []                             # returns; the part that is not a fresh shock
for t in range(TT):
    m = 0.005 + 0.045 * gauss()               # the whole market this month
    fold = f
    f = 0.7 * f + sqrt(1 - 0.49) * 0.015 * gauss()
    row, dr = [], []
    for i in range(N):
        mu[i] = 0.97 * mu[i] + sqrt(1 - 0.97 ** 2) * SMU * gauss()
        e = 0.08 * gauss()
        dr.append(mu[i] + b[i] * 0.7 * fold - 0.05 * eprev[i])
        row.append(m + mu[i] + b[i] * f - 0.05 * eprev[i] + e)
        eprev[i] = e
    R.append(row); DRIFT.append(dr)
P = [[100.0] * N]                             # P[k] = prices at the end of month k-1
for row in R:
    P.append([p * (1 + r) for p, r in zip(P[-1], row)])

def cut(s, n, top):                           # road B: find the decile edge by bisection, no sorting
    lo, hi = min(s) - 1.0, max(s) + 1.0
    while True:
        mid = 0.5 * (lo + hi)
        k = sum(1 for v in s if (v >= mid if top else v <= mid))
        if k == n: return {i for i, v in enumerate(s) if (v >= mid if top else v <= mid)}
        if (k > n) == top: lo = mid
        else: hi = mid
def avg(rets, grp): return sum(rets[i] for i in grp) / len(grp)
def sorts(sig, nd=10, check=False):           # road A: sort, cut into nd groups, hold next month
    D, x, xd, bad, xb = [[] for _ in range(nd)], [], [], 0, []
    for t in range(11, TT - 1):               # form at the end of month t, hold month t+1
        s = sig(t); n = N // nd
        order = sorted(range(N), key=lambda i: s[i])
        for d in range(nd): D[d].append(avg(R[t + 1], order[d * n:(d + 1) * n]))
        x.append(D[-1][-1] - D[0][-1])
        xd.append(avg(DRIFT[t + 1], order[-n:]) - avg(DRIFT[t + 1], order[:n]))
        if check:
            hi, lo = cut(s, n, True), cut(s, n, False)
            bad += len(hi ^ set(order[-n:])) + len(lo ^ set(order[:n]))
            xb.append(avg(R[t + 1], sorted(hi)) - avg(R[t + 1], sorted(lo)))
    return D, x, xd, bad, xb
mom = lambda t: [P[t][i] / P[t - 11][i] - 1 for i in range(N)]    # 12-1: months t-11 .. t-1
def mom_compound(t):                          # road 2 for the signal: chain the monthly returns
    out = []
    for i in range(N):
        g = 1.0
        for k in range(t - 11, t): g *= 1 + R[k][i]
        out.append(g - 1)
    return out
sgap = max(abs(a - c) for t in range(11, TT - 1) for a, c in zip(mom(t), mom_compound(t)))

D, x, xd, bad, xb = sorts(mom, check=True)
T = len(x); xbar = sum(x) / T
def gam(j): return sum((x[k] - xbar) * (x[k - j] - xbar) for k in range(j, T)) / T
def nw(L): return gam(0) + 2 * sum((1 - j / (L + 1)) * gam(j) for j in range(1, L + 1))
L = 4; assert L == int(4 * (T / 100) ** (2 / 9))   # Newey-West 1994 lag rule, T = 240
dev = [v - xbar for v in x]                   # road 2 for Newey-West: squared window sums
win = sum(sum(dev[max(0, s):min(T, s + L + 1)]) ** 2 for s in range(-L, T)) / ((L + 1) * T)
reps = []                                      # road 3: moving-block bootstrap, blocks of 12
for _ in range(2000):
    tot = 0.0
    for _ in range(T // 12):
        s0 = int(unif() * (T - 11)); tot += sum(x[s0:s0 + 12])
    reps.append(tot / T)
rbar = sum(reps) / len(reps)
se_boot = sqrt(sum((v - rbar) ** 2 for v in reps) / len(reps))
se_plain, se_nw = sqrt(gam(0) / T), sqrt(nw(L) / T)
noise = [a - c for a, c in zip(x, xd)]
nbar = sum(noise) / T
se_noise = sqrt(sum((v - nbar) ** 2 for v in noise) / T / T)

A = lambda v: 1200 * v                         # monthly decimal -> percent a year (x 12)
spread = lambda sig, nd=10: A(sum(sorts(sig, nd)[1]) / T)
ts = sum(sum((1 if P[t][i] > P[t - 11][i] else -1) * R[t + 1][i] for i in range(N)) / N
         for t in range(11, TT - 1)) / T
rows = [("example: signal 61/50 - 1", 61 / 50 - 1), ("example: skipped month 58/61 - 1", 58 / 61 - 1),
        ("signal roads, largest gap", sgap), ("decile roads, stocks disagreeing", bad),
        ("holding months T", T), ("spread, percent a month", 100 * xbar), ("spread, percent a year", A(xbar)),
        ("spread road B, percent a year", A(sum(xb) / T)), ("drift-part spread, percent a year", A(sum(xd) / T)),
        ("sd of monthly spread, percent", 100 * sqrt(gam(0)))]
rows += [(f"autocorrelation lag {j}", gam(j) / gam(0)) for j in range(1, L + 1)]
rows += [("plain SE, percent a month", 100 * se_plain), ("plain t", xbar / se_plain),
         ("NW long-run var / plain var", nw(L) / gam(0)), ("NW SE (L=4), percent a month", 100 * se_nw),
         ("NW SE by window sums", 100 * sqrt(win / T)), ("NW SE by block bootstrap", 100 * se_boot),
         ("NW t (L=4)", xbar / se_nw), ("NW t (L=12)", xbar / sqrt(nw(12) / T)),
         ("wrong: no skip (12-0), percent a year", spread(lambda t: [P[t + 1][i] / P[t - 11][i] - 1 for i in range(N)])),
         ("wrong: peeks at holding month", spread(lambda t: [P[t + 2][i] / P[t - 10][i] - 1 for i in range(N)])),
         ("try: last month only (1-0)", spread(lambda t: [P[t + 1][i] / P[t][i] - 1 for i in range(N)])),
         ("try: quintiles, top minus bottom", spread(mom, 5)), ("try: time-series momentum", A(ts))]
for name, v in rows:
    print(f"{name:<38} {v:>12.6f}")
print("decile, percent a year: " + ", ".join(f"{A(sum(d) / T):.2f}" for d in D))
print("cumulative spread by year, percent: " + ", ".join(f"{100 * sum(x[:12 * y]):.2f}" for y in range(21)))

assert sgap < 1e-9                             # price ratio == chained monthly returns
assert bad == 0 and abs(A(sum(xb) / T) - A(xbar)) < 1e-9   # bisection cut == sorted cut
assert abs(sqrt(win / T) - se_nw) < 1e-12 * se_nw + 1e-15       # autocovariances == window sums
assert abs(se_boot / se_nw - 1) < 0.25         # resampling agrees with the formula
assert abs(xbar - sum(xd) / T) < 2 * se_noise  # the sort found the hidden drift
