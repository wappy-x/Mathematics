# Rainbow options: best-of-two and worst-of-two calls -- the check behind the card.
# Standard library only. The normal CDF is a written-out series, the two-share CDF is
# Simpson's rule, the random numbers are splitmix64 + Box-Muller. Nothing imported knows the answer.
from math import exp, log, sqrt, pi, cos

S1 = S2 = 100.0; K = 100.0; r = 0.05; q = 0.02; sig = 0.20; rho = 0.5; T = 1.0

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                    # 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    s = t = x; k = 1
    while abs(t) > 1e-17 * abs(s):
        t *= x * x / (2 * k + 1); s += t; k += 1
    return 0.5 + phi(x) * s

def M(a, b, c, n=2000):                      # P(X < a, Y < b), X and Y standard normal, correlation c
    lo, hi = -8.0, min(a, 8.0)
    if hi <= lo: return 0.0
    h, w = (hi - lo) / n, sqrt(1.0 - c * c)
    f = lambda x: phi(x) * N((b - c * x) / w)
    tot = f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return tot * h / 3.0

def bs_call(S, K, r, q, s, T):
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - s * sqrt(T))

def stulz(S1, S2, K, r, q1, q2, s1, s2, rho, T, parts=False):
    rt = sqrt(T)
    sx = sqrt(s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2)          # volatility of the ratio S1/S2
    d1p = (log(S1 / K) + (r - q1 + 0.5 * s1 * s1) * T) / (s1 * rt); d1m = d1p - s1 * rt
    d2p = (log(S2 / K) + (r - q2 + 0.5 * s2 * s2) * T) / (s2 * rt); d2m = d2p - s2 * rt
    d12 = (log(S1 / S2) + (q2 - q1 + 0.5 * sx * sx) * T) / (sx * rt)
    d21 = (log(S2 / S1) + (q1 - q2 + 0.5 * sx * sx) * T) / (sx * rt)
    r1, r2 = (s1 - rho * s2) / sx, (s2 - rho * s1) / sx
    A1, A2, D = S1 * exp(-q1 * T), S2 * exp(-q2 * T), K * exp(-r * T)
    mb1, mb2, mcash = M(d1p, d12, r1), M(d2p, d21, r2), M(-d1m, -d2m, rho)
    mw1, mw2, mboth = M(d1p, -d12, -r1), M(d2p, -d21, -r2), M(d1m, d2m, rho)
    best = A1 * mb1 + A2 * mb2 - D * (1.0 - mcash)
    worst = A1 * mw1 + A2 * mw2 - D * mboth
    if parts: return dict(sx=sx, d1p=d1p, d1m=d1m, d12=d12, r1=r1, mb1=mb1, mcash=mcash, mw1=mw1,
                          mboth=mboth, A1=A1, D=D, best=best, worst=worst, wrongcash=A1 * mb1 + A2 * mb2 - D * mcash)
    return best, worst

def grid(rho, n=600):                        # Road 3: Simpson over the two-share bell surface, payoff by payoff
    L, h, c = 8.0, 16.0 / n, sqrt(1.0 - rho * rho)
    wt = [1.0 if i in (0, n) else (4.0 if i % 2 else 2.0) for i in range(n + 1)]
    g = (r - q - 0.5 * sig * sig) * T
    X = [S1 * exp(g + sig * sqrt(T) * (-L + i * h)) for i in range(n + 1)]
    b = w_ = 0.0
    for i in range(n + 1):
        z = -L + i * h; pz = wt[i] * phi(z)
        for j in range(n + 1):
            y = -L + j * h
            x2 = S2 * exp(g + sig * sqrt(T) * (rho * z + c * y))
            k = pz * wt[j] * phi(y)
            hi, lo = (X[i], x2) if X[i] > x2 else (x2, X[i])
            if hi > K: b += k * (hi - K)
            if lo > K: w_ += k * (lo - K)
    f = exp(-r * T) * h * h / 9.0
    return b * f, w_ * f

state = 20260924
def u01():                                   # splitmix64, top 53 bits, never 0
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
def mc(rho, paths=200000):                   # Road 2: simulate both shares, correlated through rho
    g, v, c, df = (r - q - 0.5 * sig * sig) * T, sig * sqrt(T), sqrt(1.0 - rho * rho), exp(-r * T)
    sb = sb2 = sw = sw2 = 0.0
    for _ in range(paths):
        z1 = sqrt(-2.0 * log(u01())) * cos(2.0 * pi * u01())
        z2 = rho * z1 + c * sqrt(-2.0 * log(u01())) * cos(2.0 * pi * u01())
        a, b = S1 * exp(g + v * z1), S2 * exp(g + v * z2)
        pb, pw = df * max(max(a, b) - K, 0.0), df * max(min(a, b) - K, 0.0)
        sb += pb; sb2 += pb * pb; sw += pw; sw2 += pw * pw
    mb, mw = sb / paths, sw / paths
    return mb, sqrt((sb2 / paths - mb * mb) / paths), mw, sqrt((sw2 / paths - mw * mw) / paths)

P = stulz(S1, S2, K, r, q, q, sig, sig, rho, T, parts=True)
best, worst = P["best"], P["worst"]
C = bs_call(S1, K, r, q, sig, T)
gb, gw = grid(rho)
mb, seb, mw, sew = mc(rho)
sx0 = sqrt(2.0) * sig * sqrt(1.0 - rho)
margrabe = S1 * exp(-q * T) * (N(0.5 * sx0) - N(-0.5 * sx0))
bestK0 = stulz(S1, S2, 1e-9, r, q, q, sig, sig, rho, T)[0]
e = 1e-4
def bw(**kw):
    a = dict(S1=S1, S2=S2, K=K, r=r, q1=q, q2=q, s1=sig, s2=sig, rho=rho, T=T); a.update(kw)
    return stulz(**a)
up, dn = bw(S1=S1 + 0.01), bw(S1=S1 - 0.01)
dlt = [(up[i] - dn[i]) / 0.02 for i in (0, 1)]
vup, vdn = bw(s1=sig + e), bw(s1=sig - e)
cup, cdn = bw(rho=rho + e), bw(rho=rho - e)
rows = [("sigma_X, vol of S1/S2", P["sx"]), ("d1+ = d2+", P["d1p"]), ("d1- = d2-", P["d1m"]),
        ("d12 = d21", P["d12"]), ("rho1 = rho2", P["r1"]), ("M(d1+, d12; rho1)", P["mb1"]),
        ("M(-d1-, -d2-; rho)  neither ends above K", P["mcash"]), ("M(d1+, -d12; -rho1)", P["mw1"]),
        ("M(d1-, d2-; rho)  both end above K", P["mboth"]), ("S e^-qT", P["A1"]), ("K e^-rT", P["D"]),
        ("best: share terms", best + P["D"] * (1 - P["mcash"])), ("best: cash term", P["D"] * (1 - P["mcash"])),
        ("worst: share terms", worst + P["D"] * P["mboth"]), ("worst: cash term", P["D"] * P["mboth"]),
        ("1 best-of, Stulz formula", best), ("1 worst-of, Stulz formula", worst),
        ("2 best-of, simulation", mb), ("  standard error", seb), ("2 worst-of, simulation", mw), ("  standard error", sew),
        ("3 best-of, Simpson grid", gb), ("3 worst-of, Simpson grid", gw),
        ("vanilla call on one share", C), ("4 best + worst", best + worst), ("  two vanilla calls", 2 * C),
        ("5 best-of, K -> 0", bestK0), ("  S e^-qT + Margrabe", S2 * exp(-q * T) + margrabe), ("  Margrabe exchange", margrabe),
        ("delta S1, best-of, bump", dlt[0]), ("  e^-qT M(d1+, d12; rho1)", exp(-q * T) * P["mb1"]),
        ("delta S1, worst-of, bump", dlt[1]), ("  e^-qT M(d1+, -d12; -rho1)", exp(-q * T) * P["mw1"]),
        ("vega S1 per vol point, best", (vup[0] - vdn[0]) / (2 * e) / 100), ("vega S1 per vol point, worst", (vup[1] - vdn[1]) / (2 * e) / 100),
        ("per 0.01 of rho, best", (cup[0] - cdn[0]) / (2 * e) / 100), ("per 0.01 of rho, worst", (cup[1] - cdn[1]) / (2 * e) / 100),
        ("wrong: 1 - M dropped from cash", P["wrongcash"]),
        ("try: sigma2 = 0.40, best", bw(s2=0.40)[0]), ("try: sigma2 = 0.40, worst", bw(s2=0.40)[1]),
        ("try: K = 120, best", bw(K=120.0)[0]), ("try: K = 120, worst", bw(K=120.0)[1])]
for name, v in rows: print(f"{name:<40} {v:>12.6f}")
sweep = [-0.9, -0.5, 0.0, 0.5, 0.9, 1.0]
line = [grid(c) for c in sweep]
print("chart, rho       " + " ".join(f"{c:6.2f}" for c in sweep))
print("chart, best-of   " + " ".join(f"{x[0]:6.2f}" for x in line))
print("chart, worst-of  " + " ".join(f"{x[1]:6.2f}" for x in line))
print("formula, best    " + " ".join(f"{bw(rho=c)[0]:6.2f}" for c in sweep[:-1]))
print("formula, worst   " + " ".join(f"{bw(rho=c)[1]:6.2f}" for c in sweep[:-1]))
xs = [80.0 + 5.0 * i for i in range(11)]
print("payoff, S1 at T  " + " ".join(f"{x:6.0f}" for x in xs))
print("payoff, best     " + " ".join(f"{max(max(x, 110.0) - K, 0.0):6.2f}" for x in xs))
print("payoff, worst    " + " ".join(f"{max(min(x, 110.0) - K, 0.0):6.2f}" for x in xs))

assert abs(gb - best) < 2e-3 and abs(gw - worst) < 2e-3, "grid road must land on the formula"
assert abs(mb - best) < 3 * seb and abs(mw - worst) < 3 * sew, "simulation within three standard errors"
assert abs(best + worst - 2 * bs_call(S1, K, r, q, sig, T)) < 1e-6, "best + worst = two vanilla calls"
assert abs(bestK0 - (S2 * exp(-q * T) + margrabe)) < 1e-6, "best-of at zero strike = share + exchange option"
assert abs(dlt[0] - exp(-q * T) * P["mb1"]) < 1e-5, "bumped delta vs its formula"
assert abs(line[-1][0] - C) < 2e-3 and abs(line[-1][1] - C) < 2e-3, "at rho = 1 both collapse to the vanilla"
print("ALL CHECKS PASS")
