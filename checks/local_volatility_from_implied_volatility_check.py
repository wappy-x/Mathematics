# Local volatility in implied-vol terms -- the check behind the card.  Standard library only.
# The surface: the one-year SVI curve v(k) of svi-smile-fit, each log-moneyness k keeping its
# implied vol at every expiry, so total variance is w(k, T) = T v(k).  Road 1 is the implied-vol
# formula, (dw/dT) / g.  Road 2 is Dupire's formula on call prices by finite differences: it never
# sees g or an SVI slope.  Road 3 rebuilds short-dated implied vols as harmonic means of local vols.
from math import log, sqrt, exp, pi

P = (0.016719, 0.126769, -0.912282, -0.118207, 0.248954)   # a, b, rho, m, s from svi-smile-fit
S0, R, Q = 100.0, 0.05, 0.02
DAY, WEEK = 1 / 365, 1 / 52

def N(x):                                   # normal CDF from its own series
    if abs(x) > 9.0: return 1.0 if x > 0 else 0.0
    y = abs(x) / sqrt(2.0); term = y; s = y; n = 0
    while term > 1e-17 * s:
        n += 1; term *= 2.0 * y * y / (2 * n + 1); s += term
    e = 2.0 / sqrt(pi) * exp(-y * y) * s
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)
def fwd(T): return S0 * exp((R - Q) * T)
def svi(k, p=P):                            # one-year total variance v, its slope v' and its bend v''
    a, b, rho, m, s = p; rt = sqrt((k - m) ** 2 + s * s)
    return a + b * (rho * (k - m) + rt), b * (rho + (k - m) / rt), b * s * s / rt ** 3
def g_terms(k, T, p=P):                     # the three terms of g, for total variance w = T v
    v0, v1, v2 = svi(k, p); w, w1, w2 = T * v0, T * v1, T * v2
    return (1 - k * w1 / (2 * w)) ** 2, w1 * w1 / 4 * (1 / w + 0.25), w2 / 2
def g(k, T, p=P): t1, t2, t3 = g_terms(k, T, p); return t1 - t2 + t3
def loc(k, T, p=P): return sqrt(svi(k, p)[0] / g(k, T, p))   # road 1: dw/dT at fixed k is v(k)
def imp(k, p=P): return sqrt(svi(k, p)[0])                     # implied vol, the same at every T
def call(K, T, vol):                        # Black-Scholes call, from an implied-vol function vol(K, T)
    f, sd = fwd(T), vol(K, T) * sqrt(T); d1 = (log(f / K) + 0.5 * sd * sd) / sd
    return exp(-R * T) * (f * N(d1) - K * N(d1 - sd))
def dupire(K, T, vol, hk=0.05, ht=1e-4):    # road 2: Dupire on call prices, slopes by differences
    c = lambda x, t: call(x, t, vol); c0 = c(K, T)
    cT = (c(K, T + ht) - c(K, T - ht)) / (2 * ht)
    cK = (c(K + hk, T) - c(K - hk, T)) / (2 * hk)
    cKK = (c(K + hk, T) - 2 * c0 + c(K - hk, T)) / (hk * hk)
    return sqrt((cT + (R - Q) * K * cK + Q * c0) / (0.5 * K * K * cKK))
def svi_vol(K, T): return imp(log(K / fwd(T)))
def skew(f, h=1e-4): return (f(h) - f(-h)) / (2 * h)       # slope in k at the forward, k = 0
def simpson(f, a, b, n=200):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def row(label, xs, fmt): print(f"{label:<42}" + "".join(format(x, fmt).rjust(12) for x in xs))

F1, Ks = fwd(1.0), (92.0, 120.0)
ks = [log(K / F1) for K in Ks]
a, b, rho, m, s = P
sv = [svi(k) for k in ks]; gt = [g_terms(k, 1.0) for k in ks]
print(f"forward at one year, F = 100 e^0.03       {F1:.6f}")
print("SVI a, b, rho, m, s (svi-smile-fit)       " + " ".join(f"{x:+.6f}" for x in P))
print(f"{'one year, T = 1':<42}{'K = 92':>12}{'K = 120':>12}")
row("log-moneyness k = ln(K/F)", ks, ".6f")
row("k - m", [k - m for k in ks], ".6f")
row("rounded distance sqrt((k-m)^2 + s^2)", [sqrt((k - m) ** 2 + s * s) for k in ks], ".6f")
row("total variance w", [x[0] for x in sv], ".6f")
row("implied vol, %", [100 * imp(k) for k in ks], ".4f")
row("slope w' in k", [x[1] for x in sv], ".6f")
row("bend w'' in k", [x[2] for x in sv], ".6f")
row("time slope dw/dT at fixed k", [x[0] for x in sv], ".6f")
row("g, first term (1 - k w'/2w)^2", [t[0] for t in gt], ".6f")
row("g, second term w'^2/4 (1/w + 1/4)", [t[1] for t in gt], ".6f")
row("g, third term w''/2", [t[2] for t in gt], ".6f")
row("g", [g(k, 1.0) for k in ks], ".6f")
row("local variance (dw/dT) / g", [svi(k)[0] / g(k, 1.0) for k in ks], ".6f")
L1 = [loc(k, 1.0) for k in ks]; L2 = [dupire(K, 1.0, svi_vol) for K in Ks]
row("road 1 local vol, implied-vol formula, %", [100 * x for x in L1], ".4f")
row("road 2 local vol, Dupire on prices, %", [100 * x for x in L2], ".4f")
flat = [dupire(K, 1.0, lambda x, t: 0.2) for K in Ks]
row("flat 20% surface through road 2, %", [100 * x for x in flat], ".4f")
pilot = call(100.0, 1.0, lambda x, t: 0.2)
print(f"{'house call, flat 20%, K = 100':<42}{pilot:>16.12f}")
row("wrong: dw/dT at fixed strike, %", [100 * sqrt((x[0] - (R - Q) * x[1]) / g(k, 1.0)) for k, x in zip(ks, sv)], ".4f")
row("wrong: k measured from spot, %", [100 * loc(log(K / S0), 1.0) for K in Ks], ".4f")
row("wrong: short-dated formula at 1 year, %", [100 * imp(k) / (1 - k * x[1] / (2 * x[0])) for k, x in zip(ks, sv)], ".4f")
s0, sk0 = imp(0.0), svi(0.0)[1] / (2 * imp(0.0))           # implied skew = v'(0) / (2 sigma)
print(f"at the forward k = 0: implied vol %, implied skew     {100 * s0:.4f} {sk0:.6f}")
print(f"limit as T -> 0: twice the implied skew               {2 * sk0:.6f}")
print("expiry            T  local vol at k = 0, %    local skew  local / implied")
ratio = {}
for lab, T in (("1 year", 1.0), ("6 months", 0.5), ("3 months", 0.25), ("1 month", 1 / 12), ("1 week", WEEK), ("1 day", DAY)):
    ls = skew(lambda k: loc(k, T)); ratio[lab] = ls / sk0
    print(f"{lab:<10}{T:9.6f}{100 * loc(0.0, T):16.4f}{ls:18.6f}{ls / sk0:12.2f}")
kd = [log(K / fwd(DAY)) for K in Ks]
hm = [1 / simpson(lambda u: 1 / loc(u * k, DAY), 0.0, 1.0) for k in kd]
row("one day: implied vol, %", [100 * imp(k) for k in kd], ".4f")
row("one day: harmonic mean of local vols, %", [100 * x for x in hm], ".4f")
gmin = min(g(0.01 * i - 1.5, T) for i in range(301) for T in (1.0, 0.5, 0.25, 1 / 12, WEEK, DAY))
print(f"smallest g, k from -1.5 to 1.5, six expiries   {gmin:.6f}")
g34 = [min(g(0.01 * i - 1.5, T) for i in range(301)) for T in (3.0, 4.0)]
print(f"smallest g, same k, at 3 and 4 years           {g34[0]:.6f} {g34[1]:.6f}")
row("one year, K = 60 and 40: implied vol, %", [100 * imp(log(K / F1)) for K in (60.0, 40.0)], ".2f")
row("one year, K = 60 and 40: local vol, %", [100 * loc(log(K / F1), 1.0) for K in (60.0, 40.0)], ".2f")
grid, kg = [80.0 + 5 * i for i in range(9)], [0.025 * (i - 4) for i in range(9)]
print("chart, strike           " + " ".join(f"{K:6.0f}" for K in grid))
print("chart, implied, 1 year  " + " ".join(f"{100 * imp(log(K / F1)):6.2f}" for K in grid))
print("chart, local, 1 year    " + " ".join(f"{100 * loc(log(K / F1), 1.0):6.2f}" for K in grid))
print("chart, k                " + " ".join(f"{k:6.3f}" for k in kg))
print("chart, implied, 1 week  " + " ".join(f"{100 * imp(k):6.2f}" for k in kg))
print("chart, local, 1 week    " + " ".join(f"{100 * loc(k, WEEK):6.2f}" for k in kg))
print("chart, twice-skew line  " + " ".join(f"{100 * (s0 + 2 * sk0 * k):6.2f}" for k in kg))
pb, pr = (a, 0.0, rho, m, s), (a, b, 0.0, m, s)
print(f"try: b = 0, local vol at 92 and 120, %          {100 * loc(ks[0], 1.0, pb):.2f} {100 * loc(ks[1], 1.0, pb):.2f}")
sr = svi(0.0, pr)[1] / (2 * imp(0.0, pr))
print(f"try: rho = 0, local / implied skew, 1 year, 1 day   {skew(lambda k: loc(k, 1.0, pr)) / sr:.2f} {skew(lambda k: loc(k, DAY, pr)) / sr:.2f}")
assert all(abs(x - y) < 1e-5 for x, y in zip(L1, L2)), "road 1 (dw/dT over g) must match road 2 (Dupire on prices)"
assert all(abs(x - 0.2) < 1e-5 for x in flat), "a flat 20% surface must give 20% local vol"
assert abs(ratio["1 day"] - 2) < 0.01, "short-dated local skew is twice the implied skew"
assert ratio["1 year"] < 1.5, "at one year the factor is well short of 2"
assert all(abs(h - imp(k)) < 1e-4 for h, k in zip(hm, kd)), "short-dated implied = harmonic mean of local"
assert gmin > 0, "g positive everywhere: a local vol exists at every point of the grid"
assert g34[1] < 0, "stretched to four years this surface fails the butterfly test"
assert abs(pilot - 9.227005508154) < 1e-9, "the pricer returns the pilot's house call"
print("ALL CHECKS PASS")
