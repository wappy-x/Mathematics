# Risk reversal and butterfly -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area N(x) is Simpson's rule
# written out, the root finder is bisection, the integral road is Simpson again.
from math import log, sqrt, exp, pi

S, RD, RF, T = 1.10, 0.05, 0.03, 1.0            # EURUSD spot, USD rate, EUR rate, years
ATM, RR, BF = 0.10, -0.01, 0.0025               # the three broker quotes
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
def bisect(g, lo, hi):                                            # g(lo), g(hi) of opposite sign
    glo = g(lo)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (g(mid) > 0.0) == (glo > 0.0): lo, glo = mid, g(mid)
        else: hi = mid
    return 0.5 * (lo + hi)

def d1(s, K, sig): return (log(s / K) + (RD - RF + 0.5 * sig * sig) * T) / (sig * sqrt(T))
def gk(K, sig, w, s=S):                                           # w = +1 EUR call, -1 EUR put
    a = d1(s, K, sig)
    return w * (s * DF * N(w * a) - K * DD * N(w * (a - sig * sqrt(T))))
def delta(K, sig, w): return w * DF * N(w * d1(S, K, sig))        # spot delta, premium not adjusted
def vega(K, sig): return S * DF * phi(d1(S, K, sig)) * sqrt(T)
def by_integral(K, sig, w):                                       # road 2: average the payoff
    def f(z):
        ST = S * exp((RD - RF - 0.5 * sig * sig) * T + sig * sqrt(T) * z)
        return max(w * (ST - K), 0.0) * phi(z)
    return DD * simpson(f, -10.0, 10.0, 40000)

def wing_vols(atm, rr, bf): return atm + bf + 0.5 * rr, atm + bf - 0.5 * rr   # call, put
def strike_closed(sig, w):                                        # K from |delta| = 0.25
    a = w * bisect(lambda x: N(x) - 0.25 / DF, -10.0, 10.0)
    return F * exp(-a * sig * sqrt(T) + 0.5 * sig * sig * T)
def trades(atm, rr, bf):                                          # RR and BF prices, per EUR
    sc, sp = wing_vols(atm, rr, bf)
    kc, kp, ka = strike_closed(sc, 1), strike_closed(sp, -1), F * exp(0.5 * atm * atm * T)
    c, p = gk(kc, sc, 1), gk(kp, sp, -1)
    return c - p, (c + p) - (gk(ka, atm, 1) + gk(ka, atm, -1)), c + p

sc, sp = wing_vols(ATM, RR, BF)
Kc, Kp, Ka = strike_closed(sc, 1), strike_closed(sp, -1), F * exp(0.5 * ATM * ATM * T)
Kc2 = bisect(lambda k: delta(k, sc, 1) - 0.25, 0.5, 2.0)          # road 2 for strikes
Kp2 = bisect(lambda k: delta(k, sp, -1) + 0.25, 0.5, 2.0)
Ka2 = bisect(lambda k: delta(k, ATM, 1) + delta(k, ATM, -1), 0.5, 2.0)
c25, p25, ca, pa = gk(Kc, sc, 1), gk(Kp, sp, -1), gk(Ka, ATM, 1), gk(Ka, ATM, -1)
rr_px, bf_px = c25 - p25, (c25 + p25) - (ca + pa)
ic, ip, ica, ipa = by_integral(Kc, sc, 1), by_integral(Kp, sp, -1), by_integral(Ka, ATM, 1), by_integral(Ka, ATM, -1)
rr_int, bf_int = ic - ip, (ic + ip) - (ica + ipa)
# road 3: back out each leg's vol from the integral prices, then rebuild the quotes
iv = lambda K, px, w: bisect(lambda v: gk(K, v, w) - px, 0.001, 1.0)
vc, vp, va = iv(Kc, ic, 1), iv(Kp, ip, -1), iv(Ka, ica, 1)
# what the tilt costs: same strikes, everything at the ATM vol
rr_flat = gk(Kc, ATM, 1) - gk(Kp, ATM, -1)
strangle_flat = gk(Kc, ATM, 1) + gk(Kp, ATM, -1)
rr_vega_est = vega(Kc, sc) * (sc - ATM) - vega(Kp, sp) * (sp - ATM)     # first order: vega x RR
st_vega_est = vega(Kc, sc) * (sc - ATM) + vega(Kp, sp) * (sp - ATM)     # first order: 2 vega x BF
h = 1e-4
rr_delta_bump = ((gk(Kc, sc, 1, S + h) - gk(Kp, sp, -1, S + h)) - (gk(Kc, sc, 1, S - h) - gk(Kp, sp, -1, S - h))) / (2 * h)
# what breaks
flip = trades(ATM, -RR, BF)                 # read RR as put minus call
nobf = trades(ATM, RR, 0.0)                 # dropped the butterfly
full = trades(ATM, 2 * RR, BF)              # put the whole RR on each wing
tries = [("try: RR -0.50", trades(ATM, 0.5 * RR, BF)[0]), ("try: BF +0.50", trades(ATM, RR, 2 * BF)[1]),
         ("try: ATM 15.00, strangle", trades(0.15, RR, BF)[2])]

rows = [("forward F", F), ("vol 25d call  %", 100 * sc), ("vol ATM       %", 100 * ATM), ("vol 25d put   %", 100 * sp),
        ("K 25d put, closed form", Kp), ("K 25d put, delta bisection", Kp2), ("K ATM, F e^(s^2 T/2)", Ka),
        ("K ATM, zero-delta straddle", Ka2), ("K 25d call, closed form", Kc), ("K 25d call, delta bisection", Kc2),
        ("25d call at 9.75", c25), ("25d put at 10.75", p25), ("ATM call at 10.00", ca), ("ATM put at 10.00", pa),
        ("RR trade, formula", rr_px), ("RR trade, integral", rr_int), ("BF trade, formula", bf_px), ("BF trade, integral", bf_int),
        ("RR trade on EUR 10m, USD", 1e7 * rr_px), ("BF trade on EUR 10m, USD", 1e7 * bf_px),
        ("back-out vol call  %", 100 * vc), ("back-out vol ATM   %", 100 * va), ("back-out vol put   %", 100 * vp),
        ("back-out RR  %", 100 * (vc - vp)), ("back-out BF  %", 100 * (0.5 * (vc + vp) - va)),
        ("RR trade, all at 10%", rr_flat), ("skew cost, exact", rr_px - rr_flat), ("skew cost, vega estimate", rr_vega_est),
        ("strangle at own vols", c25 + p25), ("strangle, all at 10%", strangle_flat), ("straddle at 10%", ca + pa),
        ("wing premium, exact", c25 + p25 - strangle_flat), ("wing premium, vega estimate", st_vega_est),
        ("delta: 25d call", delta(Kc, sc, 1)), ("delta: 25d put", delta(Kp, sp, -1)), ("delta: ATM straddle", delta(Ka, ATM, 1) + delta(Ka, ATM, -1)),
        ("delta: RR trade", delta(Kc, sc, 1) - delta(Kp, sp, -1)), ("delta: RR trade, bump", rr_delta_bump),
        ("vega/pt: 25d call", vega(Kc, sc) / 100), ("vega/pt: 25d put", vega(Kp, sp) / 100), ("vega/pt: ATM straddle", 2 * vega(Ka, ATM) / 100),
        ("vega/pt: BF trade", (vega(Kc, sc) + vega(Kp, sp) - 2 * vega(Ka, ATM)) / 100),
        ("wrong: RR sign flipped, RR", flip[0]), ("wrong: BF dropped, strangle", nobf[2]), ("wrong: full RR each wing, RR", full[0]),
        ("wrong: one vol, BF", strangle_flat - (ca + pa))] + tries
for name, v in rows: print(f"{name:<30} {v:>14.6f}")
xs = [1.0 + 0.025 * i for i in range(13)]
pay_rr = [max(x - Kc, 0.0) - max(Kp - x, 0.0) for x in xs]
pay_bf = [max(x - Kc, 0.0) + max(Kp - x, 0.0) - abs(x - Ka) for x in xs]
print("chart, EURUSD at expiry " + " ".join(f"{x:.3f}" for x in xs))
print("chart, RR payoff, pips  " + " ".join(f"{1e4 * v:.2f}" for v in pay_rr))
print("chart, BF payoff, pips  " + " ".join(f"{1e4 * v:.2f}" for v in pay_bf))

assert abs(Kp - 1.052466) < 5e-7, "25d put strike vs the strike-from-delta card"
assert abs(Kc - 1.201425) < 5e-7, "25d call strike vs the strike-from-delta card"
assert abs(Kc - Kc2) < 1e-9 and abs(Kp - Kp2) < 1e-9 and abs(Ka - Ka2) < 1e-9, "closed-form strikes vs bisection on delta"
assert abs(rr_px - rr_int) < 1e-8 and abs(bf_px - bf_int) < 1e-8, "formula vs brute-force average"
assert abs((vc - vp) - RR) < 1e-8 and abs(0.5 * (vc + vp) - va - BF) < 1e-8, "quotes rebuilt from backed-out vols"
assert abs(rr_delta_bump - 0.50) < 1e-6, "a 25-delta RR carries half a euro of delta"
assert abs(rr_vega_est / (rr_px - rr_flat) - 1.0) < 0.02, "first-order vega estimate of the skew cost"
assert abs(st_vega_est / (c25 + p25 - strangle_flat) - 1.0) < 0.05, "first-order vega estimate of the wing premium"
print("ALL CHECKS PASS")
