# American Monte Carlo for exposure -- the check behind the card.  Standard library only.  The Acme
# call Northwind sold to the bank, then a down-and-out call.  Nothing imported knows an answer: the
# random numbers, normal curve, least-squares fit, Black-Scholes and the barrier grid are written out.
from math import exp, log, sqrt, pi, cos
def uniform(s):                                   # 64-bit congruential generator, wrapping
    s[0] = (6364136223846793005 * s[0] + 1442695040888963407) % (1 << 64)
    return (s[0] >> 11) * (1.0 / 9007199254740992.0)
def normal(s):                                    # Box-Muller: two uniforms, one bell draw
    u1 = uniform(s) or 1e-300
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * uniform(s))
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def N(x):                                         # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total
def fit(xs, ys, m):     # least squares, as on the Longstaff-Schwartz card: normal equations,
    mom = [0.0] * (2 * m - 1); rhs = [0.0] * (2 * m - 1)   # then pivoted elimination
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
def curve(b, x, o=0.0):                           # b0 + b1 x + b2 x^2 + ..., by Horner
    for c in reversed(b): o = o * x + c
    return o
S0, K, R, Q, SIG, T, B, L = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 90.0, 12   # house market; barrier $90
DT = T / L; MU = (R - Q - 0.5 * SIG * SIG) * DT; VOL = SIG * sqrt(DT)
def call(s, tau):                                 # Black-Scholes value, tau years left
    if tau <= 0.0: return max(s - K, 0.0)
    v = SIG * sqrt(tau); d1 = (log(s / K) + (R - Q + 0.5 * SIG * SIG) * tau) / v
    return s * exp(-Q * tau) * N(d1) - K * exp(-R * tau) * N(d1 - v)
seed = [20261123]; NP = 50000                     # 50,000 paths to fit on, 50,000 fresh ones to use
def path():
    x = S0; row = [x]
    for _ in range(L): x *= exp(MU + VOL * normal(seed)); row.append(x)
    return row
train = [path() for _ in range(NP)]; use = [path() for _ in range(NP)]
def alive(p, j): return all(p[i] > B for i in range(1, j + 1))   # barrier checked on month-ends
def q95(v): w = sorted(v); return w[-(-95 * len(w) // 100) - 1]  # the ceil(0.95 n)-th smallest
def mean(v): return sum(v) / len(v)
def amc(j, m=3, barrier=False, disc=True, val=None):   # fit on train, revalue every path in use;
    tau = T - j * DT; pts = [p for p in train if not barrier or alive(p, j)]   # val: fit exact values
    pay = lambda p: max(p[L] - K, 0.0) * (1.0 if not barrier or alive(p, L) else 0.0)
    b = fit([p[j] / K for p in pts], [val(p[j]) if val else pay(p) * (exp(-R * tau) if disc else 1.0) for p in pts], m)
    return b, [max(curve(b, p[j] / K), 0.0) if (not barrier or alive(p, j)) else 0.0 for p in use]
C0 = call(S0, T); z95 = 1.6448536269514722         # the 95% normal quantile
print("Acme call bought from Northwind: 12 month-ends, fit on 1, x, x^2 with x = S/K")
print(f"{'month':>5}{'EE closed':>10}{'EE exact':>9}{'EE AMC':>8}{'PFE95 exact':>12}{'PFE95 AMC':>10}{'RMS miss':>9}")
van = []
for j in range(1, L + 1):
    u = j * DT; ex = [call(p[j], T - u) for p in use]
    if j < L: b, est = amc(j); ide = amc(j, len(b), val=lambda s: call(s, T - u))[1]   # best fit
    else: est = ide = ex                          # at expiry the value is the payoff: nothing to fit
    rms = sqrt(mean([(a - c) * (a - c) for a, c in zip(est, ex)]))
    van.append((u, C0 * exp(R * u), mean(ex), mean(est), q95(ex), q95(est), rms, mean(ide), q95(ide)))
    print(f"{j:5d}" + "".join(f"{x:{w}.4f}" for x, w in zip(van[-1][1:], (10, 9, 8, 12, 10, 9))))
ex6 = [call(p[6], 0.5) for p in use]; b6 = amc(6)[0]; s95 = S0 * exp(MU * 6 + SIG * sqrt(0.5) * z95)
b6i = amc(6, val=lambda s: call(s, 0.5))[0]       # the best parabola: fitted to exact values
pts6 = [p[6] / K for p in train]; y6 = [max(p[L] - K, 0.0) * exp(-R * 0.5) for p in train]
for name, x in [("call today C0", C0), ("six months: b0", b6[0]), ("  b1", b6[1]), ("  b2", b6[2]),
                ("  fit at S = 100", curve(b6, 1.0)), ("  Black-Scholes at S = 100", call(100.0, 0.5)),
                ("  Acme at its 95th percentile", s95), ("  fit there", curve(b6, s95 / K)),
                ("  Black-Scholes there", call(s95, 0.5)),
                ("  in-sample mean of fit", mean([curve(b6, x) for x in pts6])), ("  in-sample mean of Y", mean(y6)),
                ("  fitting paths' price, Y e^(-r/2)", mean(y6) * exp(-R * 0.5)), ("  fresh paths' price", mean(ex6) * exp(-R * 0.5))]:
    print(f"{name:<34}{x:10.4f}")
grid = [70.0 + 10.0 * i for i in range(8)]
print("six months, S:      " + "".join(f"{g:7.0f}" for g in grid))
print("  fitted value:     " + "".join(f"{curve(b6, g / K):7.2f}" for g in grid))
print("  Black-Scholes:    " + "".join(f"{call(g, 0.5):7.2f}" for g in grid))
print("six months, by basis   EE      PFE95   RMS miss")
basis = {}
for m, name in ((1, "1"), (2, "1, x"), (3, "1, x, x^2"), (4, "1, x, x^2, x^3")):
    e = amc(6, m)[1]; basis[m] = sqrt(mean([(a - c) * (a - c) for a, c in zip(e, ex6)]))
    print(f"  {name:<18}{mean(e):8.4f}{q95(e):9.4f}{basis[m]:9.4f}")
peek = [max(p[L] - K, 0.0) * exp(-R * 0.5) for p in use]          # the path's own future, discounted
nod = amc(6, disc=False)[1]
for name, x in [("mistake: own future, PFE95", q95(peek)), ("mistake: own future, EE", mean(peek)),
                ("mistake: no discounting, EE", mean(nod))]:
    print(f"{name:<34}{x:10.4f}")
print(f"nested simulation instead, 1000 inner paths per path per date: {NP * (L - 1) * 1000} inner paths")
# Road 2 for the barrier: march the value back month by month on a grid of log prices.
G, NZ = 1200, 200
def grid(bb):                                     # value of the down-and-out at barrier bb, month by month
    lo = log(bb); hg = (log(5.0 * S0) - lo) / (G - 1)
    def look(v, s, tau):                          # value on the grid; far above, the barrier is moot
        y = (log(s) - lo) / hg                    # the first node sits on the barrier itself:
        if y < -1e-9: return 0.0                  # only a price clearly below it is knocked out
        y = max(y, 0.0)
        if y >= G - 1: return s * exp(-Q * tau) - K * exp(-R * tau)
        i = int(y); f = y - i
        return v[i] * (1.0 - f) + v[i + 1] * f
    def back(v, s, tau):                          # e^(-r dt) times the average of next month's value
        za = max((log(bb / s) - MU) / VOL, -8.0)
        if za >= 8.0: return 0.0
        h = (8.0 - za) / NZ; tot = 0.0
        for i in range(NZ + 1):
            z = za + i * h; w = 1.0 if i in (0, NZ) else (4.0 if i % 2 else 2.0)
            tot += w * phi(z) * look(v, s * exp(MU + VOL * z), tau)
        return exp(-R * DT) * tot * h / 3.0
    vg = [[0.0] * G for _ in range(L + 1)]
    vg[L] = [max(exp(lo + i * hg) - K, 0.0) for i in range(G)]
    for j in range(L - 1, 0, -1): vg[j] = [back(vg[j + 1], exp(lo + i * hg), T - (j + 1) * DT) for i in range(G)]
    return (lambda j, s: look(vg[j], s, T - j * DT)), back(vg[1], S0, T - DT)
vlook, bar0 = grid(B); bar_lo = grid(50.0)[1]
dpay = [exp(-R * T) * max(p[L] - K, 0.0) * alive(p, L) for p in use]
bmc = mean(dpay); bse = sqrt(mean([(x - bmc) * (x - bmc) for x in dpay]) / (NP - 1))
print(f"down-and-out call, barrier {B:.0f} on month-ends: price by grid {bar0:.4f}, by paths {bmc:.4f} +/- {bse:.4f}")
print(f"  grid with the barrier moved to $50: {bar_lo:.4f}, Black-Scholes {C0:.4f}")
print(f"{'month':>5}{'alive':>7}{'EE grid':>9}{'EE AMC':>8}{'disc EE':>8}{'PFE95 grid':>11}{'PFE95 AMC':>10}{'RMS miss':>9}")
bar = []
for j in range(1, L + 1):
    u = j * DT; al = [alive(p, j) for p in use]
    ex = [vlook(j, p[j]) if a else 0.0 for p, a in zip(use, al)]
    est, ide = (amc(j, barrier=True)[1], amc(j, barrier=True, val=lambda s: vlook(j, s))[1]) if j < L else (ex, ex)
    rms = sqrt(sum((a - c) * (a - c) for a, c, f in zip(est, ex, al) if f) / sum(al))
    bar.append((sum(al) / NP, mean(ex), mean(est), mean(ex) * exp(-R * u), q95(ex), q95(est), rms, mean(ide)))
    print(f"{j:5d}" + "".join(f"{x:{w}.4f}" for x, w in zip(bar[-1], (7, 9, 8, 8, 11, 10, 9))))
for j, (u, cl, e, a, pe, pa, rms, ai, pai) in enumerate(van[:-1]):   # against the best fit: only luck
    assert abs(a - ai) < 0.25, "regression EE near the best parabola's: the payoff's luck averages out"
    assert abs(e - cl) < 0.20, "exact revaluation EE near the closed form C0 e^(ru)"
    assert abs(pa - pai) < 0.8, "regression PFE near the best parabola's"
assert abs(call(s95, 0.5) - 28.2603) < 1e-3 and abs(curve(b6, s95 / K) - curve(b6i, s95 / K)) < 0.8, "six-month PFE"
assert abs(mean([curve(b6, x) for x in pts6]) - mean(y6)) < 1e-9, "a fit with a constant matches the mean"
assert basis[1] > basis[2] > basis[3] > basis[4] and van[5][6] < 1.0, "more terms, smaller miss"
assert q95(peek) > van[5][4] + 5.0, "a path's own future overstates PFE"
assert abs(bar_lo - C0) < 2e-3, "the grid with no barrier in reach is Black-Scholes"
assert abs(bar0 - bmc) < 3.0 * bse and bar0 < C0 - 0.5, "grid barrier price agrees with the paths"
for t in bar[:-1]:
    assert abs(t[3] - bar0) < 0.25, "discounted barrier EE stays at today's price"
    assert abs(t[2] - t[7]) < 0.25, "regression barrier EE near the best fit to the grid's values"
print("ALL CHECKS PASS")
