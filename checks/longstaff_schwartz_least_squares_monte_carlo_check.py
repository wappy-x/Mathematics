# Longstaff-Schwartz least-squares Monte Carlo -- the check behind the card.  Standard library
# only, and nothing imported that already knows an answer: the random numbers, the regression,
# the integral and the tree are written out here.  Four roads to the American put on Acme: this
# method over 100,000 simulated futures; a 2,000-step tree on the same fifty exercise dates; the
# same tree exercising at every step; and the European put, by integral and off the futures.
from math import exp, log, sqrt, pi, cos
def uniform(s):                                   # 64-bit congruential generator, wrapping
    s[0] = (6364136223846793005 * s[0] + 1442695040888963407) % (1 << 64)
    return (s[0] >> 11) * (1.0 / 9007199254740992.0)
def normal(s):                                    # Box-Muller: two uniforms, one bell draw
    u1 = uniform(s) or 1e-300
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * uniform(s))
def euro_put(S, K, r, q, sig, T, n=40000):        # average the payoff over the bell curve by
    h = 20.0 / n; total = 0.0                     # Simpson's rule: no d1, no d2, no N(x)
    for i in range(n + 1):
        z = -10.0 + i * h; w = 1.0 if i in (0, n) else (4.0 if i % 2 else 2.0)
        bell = exp(-0.5 * z * z) / sqrt(2.0 * pi)                        # bell-curve height at z
        total += w * bell * max(K - S * exp((r - q - 0.5 * sig * sig) * T + sig * sqrt(T) * z), 0.0)
    return exp(-r * T) * total * h / 3.0
def fit(xs, ys, m):     # least squares: the sums of powers that make up the normal equations,
    mom = [0.0] * (2 * m - 1); rhs = [0.0] * (2 * m - 1)   # then Gaussian elimination, pivoted
    for x, y in zip(xs, ys):
        p = 1.0
        for k in range(2 * m - 1): mom[k] += p; rhs[k] += p * y; p *= x
    M = [[mom[i + j] for j in range(m)] + [rhs[i]] for i in range(m)]
    for c in range(m):
        p = max(range(c, m), key=lambda k: abs(M[k][c])); M[c], M[p] = M[p], M[c]
        for k in range(c + 1, m):
            f = M[k][c] / M[c][c]; M[k] = [a - f * bb for a, bb in zip(M[k], M[c])]
    b = [0.0] * m
    for i in range(m - 1, -1, -1): b[i] = (M[i][m] - sum(M[i][j] * b[j] for j in range(i + 1, m))) / M[i][i]
    return b
def curve(b, x, o=0.0):                           # the fitted hold value at x = S / K, by
    for c in reversed(b): o = o * x + c           # Horner: b0 + x(b1 + x(b2 + x b3))
    return o
def make_paths(S0, r, q, sig, T, L, n, seed):      # one future at a time, date by date
    dt = T / L; mu = (r - q - 0.5 * sig * sig) * dt; vol = sig * sqrt(dt); s = [seed]; out = []
    for _ in range(n):
        x = S0; row = [x]; out.append(row)
        for _ in range(L): x *= exp(mu + vol * normal(s)); row.append(x)
    return out
def lsm(P, K, r, T, L, m=3, peek=False, onsight=False, nodisc=False, keep=None):   # walk back
    n = len(P); disc = 1.0 if nodisc else exp(-r * T / L)
    cash = [max(K - p[L], 0.0) for p in P]; stop = [L] * n
    for k in range(L - 1, 0, -1):
        for i in range(n): cash[i] *= disc        # roll every future's money back one date
        idx = [i for i in range(n) if P[i][k] < K]              # in the money: a real choice
        if peek or onsight:                       # the two mistakes that fit nothing
            for i in idx:
                if onsight or K - P[i][k] > cash[i]: cash[i] = K - P[i][k]; stop[i] = k
            continue
        if len(idx) <= m: continue
        b = fit([P[i][k] / K for i in idx], [cash[i] for i in idx], m)
        if keep is not None and k == keep[0]: keep[1] = (b, len(idx))
        for i in idx:
            if K - P[i][k] > curve(b, P[i][k] / K): cash[i] = K - P[i][k]; stop[i] = k
    v = [c * disc for c in cash]; mean = sum(v) / n
    return mean, sqrt(sum((y - mean) * (y - mean) for y in v) / (n - 1) / n), stop
def tree_put(S0, K, r, q, sig, T, n, every, at=-1):   # exercise on rows that are multiples
    dt = T / n; u = exp(sig * sqrt(dt)); d = 1.0 / u  # of `every` (0 = never, 1 = American)
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt)
    px = [S0 * u ** k * d ** (n - k) for k in range(n + 1)]; v = [max(K - x, 0.0) for x in px]; front = 0.0
    for j in range(n - 1, -1, -1):
        can = every > 0 and j > 0 and j % every == 0; row = []
        for k in range(j + 1):
            px[k] *= u; c = disc * (p * v[k + 1] + (1.0 - p) * v[k])
            if can and K - px[k] > c:
                c = K - px[k]; front = max(front, px[k]) if j == at else front
            row.append(c)
        v = row
    return v[0], front
def num(label, v): print(f"  {label:<40}{v:>12.6f}")
S0, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
print("Acme: S = 100, K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year; an American put")
put_eu = euro_put(S0, K, R, Q, SIG, T); num("European put, payoff averaged by Simpson", put_eu)
print("--- eight made-up futures for Acme, exercise at months 4, 8 and 12 ---")
TOY = [[100.0, 106.0, 112.0, 118.0], [100.0, 98.0, 94.0, 91.0], [100.0, 103.0, 99.0, 101.0],
       [100.0, 95.0, 101.0, 97.0], [100.0, 88.0, 90.0, 96.0], [100.0, 100.0, 96.0, 89.0],
       [100.0, 97.0, 93.0, 99.0], [100.0, 109.0, 104.0, 107.0]]
step = exp(-R / 3.0)                              # one four-month discount factor
for k in (1, 2, 3): print(f"  Acme at month {4 * k:>2}      " + "".join(f"{p[k]:>7.0f}" for p in TOY))
cash = [max(K - p[3], 0.0) for p in TOY]
print("  cash at month 12        " + "".join(f"{c:>7.2f}" for c in cash))
for k in (2, 1):
    cash = [c * step for c in cash]
    idx = [i for i in range(8) if TOY[i][k] < K]; xs = [TOY[i][k] / K for i in idx]; ys = [cash[i] for i in idx]
    nn = float(len(idx)); sx = sum(xs); sxx = sum(x * x for x in xs); sy = sum(ys); sxy = sum(x * y for x, y in zip(xs, ys))
    det = nn * sxx - sx * sx                                    # the two-term fit, in closed form
    b0 = (sy * sxx - sx * sxy) / det; b1 = (nn * sxy - sx * sy) / det
    print(f"  month {4 * k}: normal equations [{nn:.0f} {sx:.4f} | {sy:.4f}] [{sx:.4f} {sxx:.4f} | {sxy:.4f}]")
    print(f"  month {4 * k}: fitted hold h(x) = {b0:.4f} {b1:+.4f} x,  x = S / 100")
    for j, i in enumerate(idx):
        h = b0 + b1 * xs[j]; now = K - TOY[i][k]
        print(f"  month {4 * k}  future {i + 1}  Acme {TOY[i][k]:>5.0f}  carried {ys[j]:>7.4f}  hold {h:>7.4f}"
              f"  cash now {now:>5.2f}  -> {'take' if now > h else 'hold'}")
        if now > h: cash[i] = now
toy_hand = sum(c * step for c in cash) / 8.0; toy_run = lsm(TOY, K, R, 1.0, 3, m=2)[0]
toy_euro = sum(max(K - p[3], 0.0) for p in TOY) / 8.0 * exp(-R)
for lb, v in (("eight futures, by hand", toy_hand), ("eight futures, by the routine", toy_run),
              ("eight futures, no early exercise", toy_euro),
              ("eight futures, early-exercise premium", toy_hand - toy_euro)): num(lb, v)
L, N, SEED = 50, 100000, 20260919
print(f"--- {N} simulated futures, {L} exercise dates, three-term fit, in the money only ---")
P = make_paths(S0, R, Q, SIG, T, L, N, SEED)
eu = [exp(-R * T) * max(K - p[L], 0.0) for p in P]; eu_mc = sum(eu) / N
eu_se = sqrt(sum((x - eu_mc) * (x - eu_mc) for x in eu) / (N - 1) / N); keep = [25, None]
price, se, stop = lsm(P, K, R, T, L, m=3, keep=keep)
b25, n25 = keep[1]; early = [s for s in stop if s < L]
berm, front_berm = tree_put(S0, K, R, Q, SIG, T, 2000, 2000 // L, at=1000)
amer, front_amer = tree_put(S0, K, R, Q, SIG, T, 2000, 1, at=1000)
front_fit = max(i for i in range(7200, 10001)     # the highest price where cash now wins,
                if K - i / 100.0 > curve(b25, i / 100.0 / K)) / 100.0   # stepped in whole cents
print(f"  {'European put off the same futures':<40}{eu_mc:>12.6f}  +/- {eu_se:.6f}")
print(f"  {'LSM American put':<40}{price:>12.6f}  +/- {se:.6f}")
for lb, v in (("tree, the same fifty dates, 2,000 steps", berm), ("tree, exercise at every step", amer),
              ("LSM minus the same-schedule tree", price - berm)): num(lb, v)
print(f"  {'exercised early: share, mean date':<40}{len(early) / N:>12.6f}    {sum(early) / len(early) / L:.6f} years")
print(f"  six-month fit, {n25} futures in money   h(x) = {b25[0]:.4f} {b25[1]:+.4f} x {b25[2]:+.4f} x^2")
print(f"  {'take the cash below: fit, two trees':<40}{front_fit:>12.2f}    {front_berm:.2f}    {front_amer:.2f}")
print("--- the same futures, with fewer or more terms in the fit ---")
terms = {3: price}
for m, lb in ((1, "1 term, a flat number"), (2, "2 terms, a line"), (3, "3 terms, a parabola"), (4, "4 terms, a cubic")):
    if m not in terms: terms[m] = lsm(P, K, R, T, L, m=m)[0]
    num(lb, terms[m])
print("--- what breaks ---")
for lb, v in (("peeking at each future's own outcome", lsm(P, K, R, T, L, peek=True)[0]),
              ("exercising the moment it pays", lsm(P, K, R, T, L, onsight=True)[0]),
              ("no discounting between dates", lsm(P, K, R, T, L, m=3, nodisc=True)[0]),
              ("fitted hold at 70, cash now 30.00", curve(b25, 0.70))): num(lb, v)
print("--- the curve at six months, as drawn on the card ---")
grid = [75.0 + 5.0 * i for i in range(7)]
print("  Acme price                              " + "".join(f"{g:>8.0f}" for g in grid))
print("  fitted hold value                       " + "".join(f"{curve(b25, g / K):>8.2f}" for g in grid))
print("  cash now, max(100 - S, 0)               " + "".join(f"{max(K - g, 0.0):>8.2f}" for g in grid))
assert abs(toy_hand - toy_run) < 1e-12 and toy_hand > toy_euro,     "the hand road vs the routine"
assert abs(put_eu - 6.330080627550) < 1e-6 and abs(eu_mc - put_eu) < 3.0 * eu_se, "the house put"
assert price < berm and berm - price < 0.10,   "LSM sits just below the same-schedule tree"
assert put_eu < price < amer and berm < amer,  "European < LSM < Bermudan tree < American"
assert abs(front_fit - front_berm) < 2.0 and terms[1] < terms[2] < terms[3], "boundary, then terms"
print("ALL CHECKS PASS")
