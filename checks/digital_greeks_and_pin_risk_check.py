# Digital Greeks and pin risk -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area is a series written out,
# the prices by brute force are Simpson's rule, the cut-off is found by bisection.
from math import exp, log, sqrt, pi

S0, K, r, q, sig, T0 = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
DAY = 1.0 / 365.0

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x
def N(x):                                                 # area left of x: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 1.0 if x > 0 else 0.0
    s = t = x; i = 1
    while abs(t) > 1e-16 * abs(s):
        t *= x * x / (2 * i + 1); s += t; i += 1
    return 0.5 + s * phi(x)

def dd(S, sg, T, rr=r):
    v = sg * sqrt(T)
    d1 = (log(S / K) + (rr - q + 0.5 * sg * sg) * T) / v
    return d1, d1 - v, v

def cash_greeks(S, sg, T):       # road 1: N(d2) differentiated by hand
    d1, d2, v = dd(S, sg, T); c = exp(-r * T) * N(d2); g = exp(-r * T) * phi(d2)
    return [c, g / (S * v), -g * d1 / (S * S * v * v), -g * d1 / sg,
            r * c + g * (d1 / (2 * T) - (r - q) / v), -T * c + g * sqrt(T) / sg]

def asset_greeks(S, sg, T):      # road 1: S e^-qT N(d1) differentiated by hand
    d1, d2, v = dd(S, sg, T); a = S * exp(-q * T) * N(d1); h = S * exp(-q * T) * phi(d1)
    return [a, exp(-q * T) * N(d1) + h / (S * v), -h * d2 / (S * S * v * v), -h * d2 / sg,
            q * a - h * ((r - q) / v - d2 / (2 * T)), h * sqrt(T) / sg]

def by_integral(S, sg, T, rr=r, n=4000):   # road 2: average the payoffs over the bell curve; no d1, no d2
    mu, v = (rr - q - 0.5 * sg * sg) * T, sg * sqrt(T)
    lo, hi = -12.0, 12.0
    for _ in range(100):                      # bisection for the cut z* where S_T = K
        mid = 0.5 * (lo + hi)
        if S * exp(mu + v * mid) > K: hi = mid
        else: lo = mid
    h = (12.0 - hi) / n; cs = as_ = 0.0
    for i in range(n + 1):
        w = 1.0 if i in (0, n) else (4.0 if i % 2 else 2.0)
        z = hi + i * h; cs += w * phi(z); as_ += w * S * exp(mu + v * z) * phi(z)
    return exp(-rr * T) * cs * h / 3.0, exp(-rr * T) * as_ * h / 3.0

def bumped(S, sg, T):            # road 2 continued: nudge each input, re-price, take the slope
    p = lambda S_=S, s_=sg, T_=T, r_=r: by_integral(S_, s_, T_, r_)
    out = []
    for j in (0, 1):
        f0, up, dn = p()[j], p(S_=S + 0.1)[j], p(S_=S - 0.1)[j]
        out.append([f0, (p(S_=S + 0.01)[j] - p(S_=S - 0.01)[j]) / 0.02, (up - 2 * f0 + dn) / 0.01,
                    (p(s_=sg + 1e-4)[j] - p(s_=sg - 1e-4)[j]) / 2e-4,
                    -(p(T_=T + 1e-4)[j] - p(T_=T - 1e-4)[j]) / 2e-4,
                    (p(r_=r + 1e-4)[j] - p(r_=r - 1e-4)[j]) / 2e-4])
    return out

def call_greeks(S, sg, T):       # road 3: the ordinary call's own Greeks, from its own formulas
    d1, d2, v = dd(S, sg, T)
    return [S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2), exp(-q * T) * N(d1),
            exp(-q * T) * phi(d1) / (S * v), S * exp(-q * T) * phi(d1) * sqrt(T)]

def root(f, lo, hi):             # bisection: f changes sign between lo and hi
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def out(label, *vals): print(f"{label:<30}" + "".join(f"{x:>12.6f}" for x in vals))

d1, d2, _ = dd(S0, sig, T0)
cg, ag, cl = cash_greeks(S0, sig, T0), asset_greeks(S0, sig, T0), call_greeks(S0, sig, T0)
bc, ba = bumped(S0, sig, T0)
out("d1, d2, N(d1), N(d2)", d1, d2, N(d1), N(d2))
out("phi(d1), phi(d2), e^-qT, e^-rT", phi(d1), phi(d2), exp(-q * T0), exp(-r * T0))
print(f"{'':<30}{'cash,form':>12}{'cash,bump':>12}{'asset,form':>12}{'asset,bump':>12}")
for k, name in enumerate(("price", "delta", "gamma", "vega", "theta", "rho")):
    out(name, cg[k], bc[k], ag[k], ba[k])
pdec = [G[4] + (r - q) * S0 * G[1] + 0.5 * sig * sig * S0 * S0 * G[2] - r * G[0] for G in (cg, ag)]
out("PDE balance cash, asset", *pdec)
out("call gamma, call delta", cl[2], cl[1])
out("call + K x cash: price, delta", cl[0] + K * cg[0], cl[1] + K * cg[1])
out("call + K x cash: gamma, vega", cl[2] + K * cg[2], cl[3] + K * cg[3])
out("vega per vol point cash, asset", cg[3] / 100, ag[3] / 100)
xc = root(lambda s: cash_greeks(s, sig, T0)[3], 80.0, 120.0)
xa = root(lambda s: asset_greeks(s, sig, T0)[3], 80.0, 120.0)
out("cash turn: search, formula", xc, K * exp(-(r - q + 0.5 * sig * sig) * T0))
out("asset turn: search, formula", xa, K * exp(-(r - q - 0.5 * sig * sig) * T0))
out("cash delta peak by scan", max((cash_greeks(80 + i / 100, sig, T0)[1], 80 + i / 100) for i in range(4001))[1])
out("cash vega, gamma at 90 and 97", *(cash_greeks(x, sig, T0)[k] for k in (3, 2) for x in (90.0, 97.0)))
print("delta at S = 100 by time left:  delta, stock $ per $1 paid")
times = (("1 year", 1.0), ("3 months", 0.25), ("1 month", 1 / 12), ("1 week", 7 * DAY), ("1 day", DAY), ("1 hour", DAY / 24))
for lab, t in times:
    dl = cash_greeks(S0, sig, t)[1]; out("  " + lab, dl, S0 * dl)
print("bars, stock $ per $1 paid" + "".join(f"{S0 * cash_greeks(S0, sig, t)[1]:>8.2f}" for _, t in times[:5]))
out("1 day: gamma, bump delta, turn", cash_greeks(S0, sig, DAY)[2], bumped(S0, sig, DAY)[0][1],
    K * exp(-(r - q + 0.5 * sig * sig) * DAY))
print("1 day left, delta across the strike")
for s in (98.0, 99.0, 99.5, 100.0, 100.5, 101.0, 102.0):
    out(f"  S = {s:.1f}", cash_greeks(s, sig, DAY)[1], cash_greeks(s, sig, DAY)[0])
# ---- pin risk: short one cash digital, hedged daily in shares, Acme pinned near 100 ----
path = [100.00, 100.60, 99.50, 100.30, 99.90]
print("hedge trace, days left: S, digital, shares held, trade")
for end in (100.20, 99.80):
    prem = cash_greeks(path[0], sig, 5 * DAY)[0]; held = 0.0; bank = prem
    for day, s in enumerate(path):
        new = cash_greeks(s, sig, (5 - day) * DAY)[1]
        bank -= (new - held) * s
        if end == 100.20: out(f"  with {5 - day} left", s, cash_greeks(s, sig, (5 - day) * DAY)[0], new, new - held)
        held = new; bank = bank * exp(r * DAY) + held * s * (exp(q * DAY) - 1.0)
    pay = 1.0 if end > K else 0.0
    out(f"  end {end:.2f}: pays, hedge P&L", pay, bank + held * end - pay)
# ---- charts and what breaks ----
xs = [90.0 + 2 * i for i in range(11)]
print("chart S       " + "".join(f"{x:>8.0f}" for x in xs))
for lab, t in (("Dx100 1y", 1.0), ("Dx100 1m", 1 / 12), ("Dx100 1w", 7 * DAY)):
    print(f"chart {lab:<8}" + "".join(f"{100 * cash_greeks(x, sig, t)[1]:>8.2f}" for x in xs))
vs = [80.0 + 5 * i for i in range(9)]
print("chart S       " + "".join(f"{x:>8.0f}" for x in vs))
print("chart vega 1y " + "".join(f"{cash_greeks(x, sig, T0)[3]:>8.2f}" for x in vs))
g0 = exp(-r * T0) * phi(d2)
out("wrong: no chain rule, delta", g0)
out("wrong: asset delta as a call", exp(-q * T0) * N(d1))
out("wrong: rho, discount frozen", g0 * sqrt(T0) / sig)
out("wrong: 1-year delta at 1 day", cg[1])

assert abs(cg[0] - 0.494581) < 5e-7, "house cash digital"
assert abs(ag[0] - 58.685115) < 5e-7, "house asset digital"
for k in range(6):
    assert abs(cg[k] - bc[k]) < 1e-6 * (1 + abs(cg[k])), f"cash Greek {k}: formula vs bumped integral"
    assert abs(ag[k] - ba[k]) < 1e-6 * (1 + abs(ag[k])), f"asset Greek {k}: formula vs bumped integral"
assert abs(cg[1] - cl[2]) < 1e-12, "at S = K the cash delta equals the call's gamma"
assert abs(cl[3] + K * cg[3] - ag[3]) < 1e-9, "asset vega = call vega + K cash vegas"
assert max(abs(x) for x in pdec) < 1e-9, "theta balances the pricing equation for both digitals"
assert abs(xc - K * exp(-(r - q + 0.5 * sig * sig) * T0)) < 1e-9, "vega turns at d1 = 0"
assert cash_greeks(90.0, sig, T0)[3] > 0 > cg[3], "cash vega changes sign below the strike"
assert cash_greeks(97.0, sig, T0)[2] < 0 < cash_greeks(90.0, sig, T0)[2], "cash gamma changes sign below the strike"
print("ALL CHECKS PASS")
