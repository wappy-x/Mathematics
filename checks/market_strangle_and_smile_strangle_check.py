# The broker butterfly -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area N(x) is Simpson's rule written out,
# roots come from bisection (road 1) and from the secant method (road 2).
from math import log, sqrt, exp, pi

S, RD, RF, T = 1.10, 0.05, 0.03, 1.0            # EURUSD spot, USD rate, EUR rate, years
ATM, RR, BFM = 0.10, -0.01, 0.0025              # broker quotes; BFM is the market-strangle butterfly
F, DD, DF = S * exp((RD - RF) * T), exp(-RD * T), exp(-RF * T)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def N(x):                                                         # bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)
def bisect(g, lo, hi, it=100):                                    # g(lo), g(hi) of opposite sign
    glo = g(lo)
    for _ in range(it):
        mid = 0.5 * (lo + hi); gm = g(mid)
        if (gm > 0.0) == (glo > 0.0): lo, glo = mid, gm
        else: hi = mid
    return 0.5 * (lo + hi)
def secant(g, a, b):
    ga, gb = g(a), g(b)
    for _ in range(30):
        if gb == ga: break
        a, b, ga = b, b - gb * (b - a) / (gb - ga), gb; gb = g(b)
        if abs(b - a) < 1e-13: break
    return b

def d1(K, sig): return (log(S / K) + (RD - RF + 0.5 * sig * sig) * T) / (sig * sqrt(T))
def gk(K, sig, w):                                                # w = +1 EUR call, -1 EUR put
    a = d1(K, sig)
    return w * (S * DF * N(w * a) - K * DD * N(w * (a - sig * sqrt(T))))
def delta(K, sig, w): return w * DF * N(w * d1(K, sig))           # spot delta, premium not adjusted
def vega(K, sig): return S * DF * phi(d1(K, sig)) * sqrt(T)
def by_integral(K, sig, w):                                       # road 2: average the payoff
    def f(z):
        ST = S * exp((RD - RF - 0.5 * sig * sig) * T + sig * sqrt(T) * z)
        return max(w * (ST - K), 0.0) * phi(z)
    return DD * simpson(f, -10.0, 10.0, 40000)

D25 = bisect(lambda x: N(x) - 0.25 / DF, -10.0, 10.0)             # e^{-rf T} N(D25) = 0.25
def k25(sig, w): return F * exp(-w * D25 * sig * sqrt(T) + 0.5 * sig * sig * T)
def k25_search(sig, w): return bisect(lambda k: delta(k, sig, w) - 0.25 * w, 0.5, 2.0)
def smile(atm, rr, b, kfind=k25):                                 # quadratic in ln(K/F) through 3 pillars
    sc, sp = atm + b + 0.5 * rr, atm + b - 0.5 * rr
    xs = [log(kfind(sp, -1) / F), 0.5 * atm * atm * T, log(kfind(sc, 1) / F)]
    ys = [sp, atm, sc]
    def vol(K):
        x, v = log(K / F), 0.0
        for i in range(3):
            l = 1.0
            for j in range(3):
                if j != i: l *= (x - xs[j]) / (xs[i] - xs[j])
            v += l * ys[i]
        return v
    return vol, xs
def market(atm, bfm, kfind=k25, price=gk):                        # the broker's strangle: one vol
    sm = atm + bfm
    kc, kp = kfind(sm, 1), kfind(sm, -1)
    return kc, kp, price(kc, sm, 1) + price(kp, sm, -1)
def gap(atm, rr, bfm, b, kfind=k25, price=gk):                    # smile strangle minus market strangle
    kc, kp, V = market(atm, bfm, kfind, price)
    vol = smile(atm, rr, b, kfind)[0]
    return price(kc, vol(kc), 1) + price(kp, vol(kp), -1) - V
def solve(atm, rr, bfm): return bisect(lambda b: gap(atm, rr, bfm, b), bfm - 0.01, bfm + 0.02)

Kmc, Kmp, V = market(ATM, BFM)
Kmc2, Kmp2, V2 = k25_search(ATM + BFM, 1), k25_search(ATM + BFM, -1), market(ATM, BFM, k25_search, by_integral)[2]
g_naive = gap(ATM, RR, BFM, BFM)
b1 = solve(ATM, RR, BFM)                                          # road 1: formula + bisection
b2 = secant(lambda b: gap(ATM, RR, BFM, b, k25_search, by_integral), BFM, BFM + 0.001)   # road 2
slope = (gap(ATM, RR, BFM, BFM + 1e-5) - gap(ATM, RR, BFM, BFM - 1e-5)) / 2e-5
b3 = BFM - g_naive / slope                                        # road 3: one vega step from the naive guess
vol, xs = smile(ATM, RR, b1)
Kc_s, Kp_s = F * exp(xs[2]), F * exp(xs[0])
Kc_fp = bisect(lambda k: delta(k, vol(k), 1) - 0.25, Kmc - 0.05, Kmc + 0.05)   # 25 delta read off the smile
Kp_fp = bisect(lambda k: delta(k, vol(k), -1) + 0.25, Kmp - 0.05, Kmp + 0.05)
Ka = bisect(lambda k: delta(k, vol(k), 1) + delta(k, vol(k), -1), Kmp, Kmc)   # delta-neutral straddle on the smile
nvol, nx = smile(ATM, RR, BFM)
rows = [("forward F", F), ("market vol ATM+BF  %", 100 * (ATM + BFM)),
        ("K market call, closed form", Kmc), ("K market call, delta search", Kmc2),
        ("K market put, closed form", Kmp), ("K market put, delta search", Kmp2),
        ("market call at 10.25", gk(Kmc, ATM + BFM, 1)), ("market put at 10.25", gk(Kmp, ATM + BFM, -1)),
        ("market strangle V, formula", V), ("market strangle V, integral", V2),
        ("delta: market strangle", delta(Kmc, ATM + BFM, 1) + delta(Kmp, ATM + BFM, -1)),
        ("vega/pt: market call", vega(Kmc, ATM + BFM) / 100), ("vega/pt: market put", vega(Kmp, ATM + BFM) / 100),
        ("naive smile vol at K call %", 100 * nvol(Kmc)), ("naive smile vol at K put  %", 100 * nvol(Kmp)),
        ("naive avg vol at market K %", 50 * (nvol(Kmc) + nvol(Kmp))),
        ("naive smile strangle", V + g_naive), ("naive gap, pips", 1e4 * g_naive), ("naive gap on EUR 10m, USD", 1e7 * g_naive),
        ("smile BF, bisection  %", 100 * b1), ("smile BF, secant+integral %", 100 * b2), ("smile BF, one vega step %", 100 * b3),
        ("smile BF - market BF, bp", 1e4 * (b1 - BFM)), ("d gap / d b, pips per bp", slope * 1e-4 * 1e4),
        ("smile vol 25d call  %", 100 * vol(Kc_s)), ("smile vol 25d put   %", 100 * vol(Kp_s)),
        ("K 25d call on smile", Kc_s), ("K 25d call, smile delta search", Kc_fp),
        ("K 25d put on smile", Kp_s), ("K 25d put, smile delta search", Kp_fp),
        ("smile vol at K market call %", 100 * vol(Kmc)), ("smile vol at K market put  %", 100 * vol(Kmp)),
        ("rebuilt RR  %", 100 * (vol(Kc_fp) - vol(Kp_fp))), ("rebuilt ATM %", 100 * vol(Ka)),
        ("naive pillar K put", F * exp(nx[0])), ("naive pillar K call", F * exp(nx[2])),
        ("wrong: V on naive pillar K", gk(F * exp(nx[2]), ATM + BFM, 1) + gk(F * exp(nx[0]), ATM + BFM, -1)),
        ("wrong: V strikes found at ATM", gk(k25(ATM, 1), ATM + BFM, 1) + gk(k25(ATM, -1), ATM + BFM, -1)),
        ("try: RR +1.00, gap bp", 1e4 * (solve(ATM, -RR, BFM) - BFM)), ("try: BF 0.50, gap bp", 1e4 * (solve(ATM, RR, 0.005) - 0.005)),
        ("try: ATM 15.00, gap bp", 1e4 * (solve(0.15, RR, BFM) - BFM))]
for name, v in rows: print(f"{name:<32} {v:>14.6f}")
rrs = [0.0, -0.005, -0.01, -0.02, -0.03, -0.04, -0.05, -0.06]
gaps = [1e4 * (solve(ATM, r, BFM) - BFM) for r in rrs]
print("chart, RR %            " + " ".join(f"{100 * r:.1f}" for r in rrs))
print("chart, BF gap, bp      " + " ".join(f"{x:.2f}" for x in gaps))
bs = [-0.0025 + 0.00125 * i for i in range(9)]
print("chart, smile BF %      " + " ".join(f"{100 * b:.3f}" for b in bs))
gs = [gap(ATM, RR, BFM, b) for b in bs]
print("chart, gap, pips       " + " ".join(f"{1e4 * g:.2f}" for g in gs))
xs = [1.0 + 0.025 * i for i in range(13)]
print("chart, EURUSD expiry   " + " ".join(f"{x:.3f}" for x in xs))
print("chart, strangle, pips  " + " ".join(f"{1e4 * (max(x - Kmc, 0) + max(Kmp - x, 0)):.2f}" for x in xs))
# no root: RR -12%.  The naive smile goes negative; every positive smile overprices the strangle.
RRX = -0.12; lowest_naive = min(smile(ATM, RRX, BFM)[0](k) for k in market(ATM, BFM)[:2])
ok = []
for i in range(1201):
    b = -0.03 + 0.0001 * i
    v2, x2 = smile(ATM, RRX, b)
    if ATM + b - 0.5 * abs(RRX) > 0 and x2[0] < x2[1] < x2[2] and min(v2(Kmc), v2(Kmp)) > 0:
        ok.append(gap(ATM, RRX, BFM, b))
print(f"{'RR -12: naive smile, low vol %':<32} {100 * lowest_naive:>14.6f}")
print(f"{'RR -12: positive smiles tried':<32} {len(ok):>14d}")
print(f"{'RR -12: smallest gap, pips':<32} {1e4 * min(ok):>14.6f}")

assert abs(Kmc - Kmc2) < 1e-9 and abs(Kmp - Kmp2) < 1e-9 and abs(V - V2) < 1e-8, "market strangle: formula vs search + integral"
assert abs(b1 - b2) < 1e-8, "bisection on formula prices vs secant on brute-force prices"
assert abs(b3 / b1 - 1.0) < 1e-3, "one vega step lands within 0.1 percent of the root"
assert abs(solve(ATM, 0.0, BFM) - BFM) < 1e-10, "no tilt: smile BF equals market BF"
assert abs(vol(Kc_fp) - vol(Kp_fp) - RR) < 1e-9 and abs(vol(Ka) - ATM) < 1e-12, "smile still honours ATM and RR"
assert all(x < y for x, y in zip(gaps, gaps[1:])), "the gap grows with the size of the tilt"
assert all(x < y for x, y in zip(gs, gs[1:])) and gs[4] < 0 < gs[5], "g rises on the scan, one sign change"
assert lowest_naive < 0 and min(ok) > 0, "RR -12%: no positive smile reprices the strangle"
print("ALL CHECKS PASS")
