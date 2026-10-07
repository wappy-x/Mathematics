# Vanna and volga on the FX smile -- the check behind the card.  Standard library only.
# House FX market: EURUSD spot 1.10, USD rate 5%, EUR rate 3%, one year; ATM 10.00%,
# 25-delta risk reversal -1.00%, 25-delta butterfly +0.25%.  Greeks per 1.00 of vol.
# Roads: (1) the closed forms; (2) bumping the Garman-Kohlhagen price itself;
# (3) vanna as the vol-slope of delta, volga as the vol-slope of vega; (4) the symmetric-wing algebra.
from math import log, sqrt, exp, pi

S, RD, RF, T = 1.10, 0.05, 0.03, 1.0
ATM, RR, BF = 0.10, -0.01, 0.0025
F = S * exp((RD - RF) * T)

def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)               # bell-curve height
def N(x):                                                           # bell-curve area, by its Taylor series
    if abs(x) > 8: return 0.0 if x < 0 else 1.0
    term = s = x; n = 0
    while abs(term) > 1e-17:
        n += 1; term *= x * x / (2 * n + 1); s += term
    return 0.5 + phi(x) * s
def bisect(f, target, lo, hi):                                      # f increasing
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return 0.5 * (lo + hi)
def z0(v): return 0.0 if abs(v) < 5e-7 else v                       # print a machine zero as 0

def d12(K, v, s=S):
    d1 = (log(s / K) + (RD - RF + 0.5 * v * v) * T) / (v * sqrt(T))
    return d1, d1 - v * sqrt(T)
def call(K, v, s=S):
    d1, d2 = d12(K, v, s); return s * exp(-RF * T) * N(d1) - K * exp(-RD * T) * N(d2)
def put(K, v, s=S):
    d1, d2 = d12(K, v, s); return K * exp(-RD * T) * N(-d2) - s * exp(-RF * T) * N(-d1)
def delta(K, v): return exp(-RF * T) * N(d12(K, v)[0])
def vega(K, v, s=S): return s * exp(-RF * T) * phi(d12(K, v, s)[0]) * sqrt(T)
def vanna(K, v): d1, d2 = d12(K, v); return -exp(-RF * T) * phi(d1) * d2 / v
def volga(K, v): d1, d2 = d12(K, v); return vega(K, v) * d1 * d2 / v
def G(K, v=ATM): return [vega(K, v), vanna(K, v), volga(K, v)]
def comb(a, x, b, y): return [a * p + b * q for p, q in zip(x, y)]

# ---- road 1: the closed forms at strike 1.10, and the pillars rebuilt from the three quotes ----
K0 = 1.10
d1, d2 = d12(K0, ATM)
vp, vc = ATM + BF - RR / 2, ATM + BF + RR / 2
a = -bisect(N, 0.25 * exp(RF * T), -10, 10)                         # e^{-rf T} N(-a) = 0.25
Kp = F * exp(-a * vp * sqrt(T) + 0.5 * vp * vp * T)
Ka = F * exp(0.5 * ATM * ATM * T)
Kc = F * exp(a * vc * sqrt(T) + 0.5 * vc * vc * T)
Kz = F * exp(-0.5 * ATM * ATM * T)                                  # where d2 = 0
# ---- road 2: bump the price.  road 3: slope of delta in vol, slope of vega in spot and in vol ----
h = 1e-4
def mixed(p): return (p(K0, ATM + h, S + h) - p(K0, ATM - h, S + h) - p(K0, ATM + h, S - h) + p(K0, ATM - h, S - h)) / (4 * h * h)
def second(p): return (p(K0, ATM + h) - 2 * p(K0, ATM) + p(K0, ATM - h)) / (h * h)
b_vega = (call(K0, ATM + h) - call(K0, ATM - h)) / (2 * h)
b_vanna, p_vanna, b_volga, p_volga = mixed(call), mixed(put), second(call), second(put)
s_vanna = (delta(K0, ATM + h) - delta(K0, ATM - h)) / (2 * h)
s_vanna2 = (vega(K0, ATM, S + h) - vega(K0, ATM, S - h)) / (2 * h)
s_volga = (vega(K0, ATM + h) - vega(K0, ATM - h)) / (2 * h)
# ---- the three trades, every leg's Greeks at the flat 10% (a put shares its call's three Greeks) ----
straddle = comb(2, G(Ka), 0, G(Ka))
rrisk = comb(1, G(Kc), -1, G(Kp))
strangle = comb(1, G(Kc), 1, G(Kp))
bf_unit = comb(1, strangle, -1, straddle)
w = strangle[0] / straddle[0]                                       # straddles sold per strangle
bf_vn = comb(1, strangle, -w, straddle)
rr_own_vega = vega(Kc, vc) - vega(Kp, vp)
# ---- road 4: symmetric wings at a flat 10% vol, against the formulas the proof derives ----
Ksc, Ksp = F * exp(a * ATM * sqrt(T) + 0.5 * ATM * ATM * T), F * exp(-a * ATM * sqrt(T) + 0.5 * ATM * ATM * T)
sym_rr, sym_str = comb(1, G(Ksc), -1, G(Ksp)), comb(1, G(Ksc), 1, G(Ksp))
sym_bf = comb(1, sym_str, -sym_str[0] / straddle[0], straddle)
Vw = S * exp(-RF * T) * phi(a) * sqrt(T)
f_rr = [0.0, 2 * exp(-RF * T) * phi(a) * a / ATM, 2 * Vw * a * sqrt(T)]
f_bf = [0.0, 0.0, 2 * Vw * a * a / ATM]

rows = [("forward F", F), ("d1 at 1.10", d1), ("d2 at 1.10", d2), ("phi(d1)", phi(d1)), ("e^-rfT", exp(-RF * T)),
        ("1 vega  closed form", vega(K0, ATM)), ("2 vega  price bump", b_vega),
        ("1 vanna closed form", vanna(K0, ATM)), ("2 vanna call price bump", b_vanna), ("2 vanna put price bump", p_vanna),
        ("3 vanna vol-slope of delta", s_vanna), ("3 vanna spot-slope of vega", s_vanna2),
        ("1 volga closed form", volga(K0, ATM)), ("2 volga call price bump", b_volga), ("2 volga put price bump", p_volga),
        ("3 volga vol-slope of vega", s_volga), ("25d distance a", a),
        ("volga at the forward", volga(F, ATM)), ("straddle vega / S", straddle[0] / S),
        ("straddles per strangle w", w), ("RR vega, legs at own vols", z0(rr_own_vega)),
        ("RR vanna / |BF vanna|", rrisk[1] / abs(bf_vn[1])), ("BF volga / RR volga", bf_vn[2] / rrisk[2]),
        ("wrong: vanna sign dropped", -vanna(K0, ATM)),
        ("wrong: vanna with d1 for d2", -exp(-RF * T) * phi(d1) * d1 / ATM),
        ("wrong: vanna without e^-rfT", -phi(d1) * d2 / ATM),
        ("wrong: volga with d1^2", vega(K0, ATM) * d1 * d1 / ATM),
        ("try: vanna 1.10 at 15% vol", vanna(K0, 0.15)), ("try: volga 1.30 at 10% vol", volga(1.30, ATM))]
for name, v in rows: print(f"{name:<30}{v:>12.6f}")
print()
print(f"{'strike':<22}{'K':>10}{'vega':>11}{'vanna':>11}{'volga':>11}")
for name, K in (("25d put pillar", Kp), ("spot", K0), ("d2 = 0", Kz), ("forward", F),
                ("ATM pillar, d1 = 0", Ka), ("25d call pillar", Kc)):
    print(f"{name:<22}{K:>10.6f}" + "".join(f"{z0(x):>11.6f}" for x in G(K)))
print()
for name, g in (("ATM straddle", straddle), ("risk reversal", rrisk), ("strangle", strangle),
                ("unit butterfly", bf_unit), ("vega-neutral BF", bf_vn),
                ("sym RR", sym_rr), ("sym RR formula", f_rr), ("sym BF", sym_bf), ("sym BF formula", f_bf)):
    print(f"{name:<32}" + "".join(f"{z0(x):>11.6f}" for x in g))
print()
grid = [1.0 + 0.025 * i for i in range(13)]
print("chart, strike " + " ".join(f"{k:5.3f}" for k in grid))
for i, name in ((0, "vega "), (1, "vanna"), (2, "volga")):
    print(f"chart, {name}  " + " ".join(f"{z0(G(k)[i]):5.2f}" for k in grid))
print(f"ATM straddle volga below 1e-12: {'yes' if abs(straddle[2]) < 1e-12 else 'no'}")

assert all(abs(vanna(K0, ATM) - x) < 2e-6 for x in (b_vanna, s_vanna, s_vanna2)), "vanna: formula vs three bumps"
assert all(abs(volga(K0, ATM) - x) < 2e-6 for x in (b_volga, s_volga)), "volga: formula vs two bumps"
assert abs(p_vanna - b_vanna) < 1e-6 and abs(p_volga - b_volga) < 1e-6, "put and call share vanna and volga"
assert abs(Kp - 1.052466) < 5e-7 and abs(Ka - 1.127847) < 5e-7 and abs(Kc - 1.201425) < 5e-7, "house pillars"
assert all(abs(x - y) < 1e-9 for x, y in zip(sym_rr[1:] + sym_bf[1:], f_rr[1:] + f_bf[1:])), "symmetric algebra"
assert abs(straddle[2]) < 1e-12 and abs(straddle[1] - straddle[0] / S) < 1e-12, "straddle: no volga, vanna = vega/S"
print("ALL CHECKS PASS")
