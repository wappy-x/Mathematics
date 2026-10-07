# Currency digitals -- the check behind the card.  Standard library only.
# House FX market: EURUSD S = 1.10 dollars per euro, USD rate 5%, EUR rate 3%,
# vol 10%, one year.  The bell-curve area N(x) is built by Simpson slices,
# the random numbers by a 64-bit mixer, the root finder by halving.
from math import log, sqrt, exp, cos, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4.0 if i % 2 else 2.0) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0
def N(x): return 0.0 if x < -12 else 1.0 if x > 12 else 0.5 + simpson(phi, 0.0, x)

S, rd, rf, sig, T, K = 1.10, 0.05, 0.03, 0.10, 1.0, 1.10
def d12(s, k, dom, fgn, v):
    d1 = (log(s / k) + (dom - fgn + 0.5 * v * v) * T) / (v * sqrt(T))
    return d1, d1 - v * sqrt(T)
def call(s, k, dom, fgn, v):                                # Garman-Kohlhagen, domestic per foreign
    d1, d2 = d12(s, k, dom, fgn, v); return s * exp(-fgn * T) * N(d1) - k * exp(-dom * T) * N(d2)
def put(s, k, dom, fgn, v):
    d1, d2 = d12(s, k, dom, fgn, v); return k * exp(-dom * T) * N(-d2) - s * exp(-fgn * T) * N(-d1)
def usd_dig(s, k, v): return exp(-rd * T) * N(d12(s, k, rd, rf, v)[1])   # pays 1 USD if S_T > k
def eur_dig(s, k, v): return exp(-rf * T) * N(d12(s, k, rd, rf, v)[0])   # pays 1 EUR, valued in EUR
def vega(s, k, v): return s * exp(-rf * T) * phi(d12(s, k, rd, rf, v)[0]) * sqrt(T)

d1, d2 = d12(S, K, rd, rf, sig)
D, E = usd_dig(S, K, sig), eur_dig(S, K, sig)
h = 1e-5                                                   # road 2: tight call spreads
D_spread = (call(S, K - h, rd, rf, sig) - call(S, K + h, rd, rf, sig)) / (2 * h)
P_spread = (put(S, K + h, rd, rf, sig) - put(S, K - h, rd, rf, sig)) / (2 * h)
E_ident = (call(S, K, rd, rf, sig) + K * D) / S            # asset-or-nothing = call + K digitals
X, k = 1.0 / S, 1.0 / K                                    # road 4: the inverted quote, euros domestic
E_inv_formula = exp(-rf * T) * N(-d12(X, k, rf, rd, sig)[1])
E_inv_spread = (put(X, k + h, rf, rd, sig) - put(X, k - h, rf, rd, sig)) / (2 * h)

state = 20260927                                           # road 3: Monte Carlo, own generator
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
M, hitD, hitE, hitE2 = 200000, 0.0, 0.0, 0.0
for _ in range(M):
    z = sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
    ST = S * exp((rd - rf - 0.5 * sig * sig) * T + sig * sqrt(T) * z)
    if ST > K: hitD += 1.0; hitE += ST; hitE2 += ST * ST
D_mc, E_mc = exp(-rd * T) * hitD / M, exp(-rd * T) * hitE / M / S
se = exp(-rd * T) * sqrt(hitD / M * (1 - hitD / M) / M)
seE = exp(-rd * T) / S * sqrt((hitE2 / M - (hitE / M) ** 2) / M)

def lo(a, b, f):                                           # halving root finder
    for _ in range(200):
        m = 0.5 * (a + b); a, b = (m, b) if f(m) < 0 else (a, m)
    return 0.5 * (a + b)
F = S * exp((rd - rf) * T)
dc = lo(-5, 5, lambda x: exp(-rf * T) * N(x) - 0.25)      # 25-delta call: e^-rfT N(d1) = 0.25
# 25-delta put: e^-rfT N(-d1) = 0.25, so its d1 is -dc; strike K = F e^(-d1 v + v^2/2) at the pillar's own vol
Ks = [F * exp(dc * 0.1075 + 0.5 * 0.1075 * 0.1075), F * exp(0.5 * 0.10 * 0.10), F * exp(-dc * 0.0975 + 0.5 * 0.0975 * 0.0975)]
vs = [0.1075, 0.10, 0.0975]
def smile(x):                                              # Castagna-Mercurio, second order
    K1, K2, K3 = Ks
    y = [log(K2 / x) * log(K3 / x) / (log(K2 / K1) * log(K3 / K1)),
         log(x / K1) * log(K3 / x) / (log(K2 / K1) * log(K3 / K2)),
         log(x / K1) * log(x / K2) / (log(K3 / K1) * log(K3 / K2))]
    D1 = sum(a * b for a, b in zip(y, vs)) - vs[1]
    D2 = sum(y[i] * d12(S, Ks[i], rd, rf, vs[1])[0] * d12(S, Ks[i], rd, rf, vs[1])[1] * (vs[i] - vs[1]) * (vs[i] - vs[1]) for i in range(3))
    a, b = d12(S, x, rd, rf, vs[1]); ab = a * b
    return vs[1] + (-vs[1] + sqrt(vs[1] * vs[1] + ab * (2 * vs[1] * D1 + D2))) / ab
def slope(x, e=1e-5): return (smile(x + e) - smile(x - e)) / (2 * e)
def smile_dig(x): return usd_dig(S, x, smile(x)) - vega(S, x, smile(x)) * slope(x)
def smile_spread(x): return (call(S, x - h, rd, rf, smile(x - h)) - call(S, x + h, rd, rf, smile(x + h))) / (2 * h)
K3 = Ks[2]; v3 = smile(K3)
flat3, term3 = usd_dig(S, K3, v3), -vega(S, K3, v3) * slope(K3)

rows = [("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("forward F", F),
    ("USD digital 1 formula", D), ("USD digital 2 call spread", D_spread), ("USD digital 3 Monte Carlo", D_mc),
    ("  Monte Carlo std error", se), ("USD digital put, put spread", P_spread), ("  call + put", D + P_spread), ("  e^-rdT", exp(-rd * T)), ("  e^-rfT", exp(-rf * T)),
    ("EUR digital 1 formula", E), ("EUR digital 2 (call + K D)/S", E_ident), ("EUR digital 3 Monte Carlo", E_mc),
    ("EUR digital 4 inverted formula", E_inv_formula), ("EUR digital 5 inverted put spread", E_inv_spread),
    ("EUR digital in USD, S x E", S * E)]
for w in (0.02, 0.01, 0.001):
    rows.append((f"one-sided spread width {w}", (call(S, K - w, rd, rf, sig) - call(S, K, rd, rf, sig)) / w))
bump = 1e-5
dlt, dlt_bump = exp(-rd * T) * phi(d2) / (S * sig * sqrt(T)), (usd_dig(S + bump, K, sig) - usd_dig(S - bump, K, sig)) / (2 * bump)
vg, vg_bump = -exp(-rd * T) * phi(d2) * d1 / sig / 100, (usd_dig(S, K, sig + bump) - usd_dig(S, K, sig - bump)) / (2 * bump) / 100
rows += [("USD delta, formula", dlt), ("USD vega per vol pt, formula", vg),
    ("EUR delta, formula", exp(-rf * T) * phi(d1) / (S * sig * sqrt(T))),
    ("EUR vega per vol pt, formula", -exp(-rf * T) * phi(d1) * d2 / sig / 100),
    ("USD vega sign flip spot", K * exp(-(rd - rf + 0.5 * sig * sig) * T)),
    ("EUR vega sign flip spot", K * exp(-(rd - rf - 0.5 * sig * sig) * T)),
    ("pillar 25d put strike", Ks[0]), ("pillar ATM strike", Ks[1]), ("pillar 25d call strike", K3),
    ("smile vol at 1.10", smile(K)), ("USD digital 1.10 flat, own vol", usd_dig(S, K, smile(K))),
    ("  skew term at 1.10", smile_dig(K) - usd_dig(S, K, smile(K))), ("USD digital 1.10 smile", smile_dig(K)),
    ("smile vol at 25d call", v3), ("smile slope per unit strike", slope(K3)), ("vega at 25d call", vega(S, K3, v3)),
    ("USD digital 25d flat", flat3), ("  skew term -vega x slope", term3), ("USD digital 25d smile", flat3 + term3),
    ("USD digital 25d smile spread", smile_spread(K3)), ("  skew term / flat price", term3 / flat3),
    ("EUR digital 25d flat", eur_dig(S, K3, v3)), ("EUR digital 25d smile", eur_dig(S, K3, v3) - K3 / S * vega(S, K3, v3) * slope(K3)),
    ("wrong: USD digital with N(d1)", exp(-rd * T) * N(d1)), ("wrong: USD digital, rates swapped", exp(-rf * T) * N(d12(S, K, rf, rd, sig)[1])),
    ("wrong: skew term added with + sign", flat3 - term3), ("wrong: 25d digital at ATM vol", usd_dig(S, K3, 0.10))]
for name, v in rows: print(f"{name:<36} {v:>12.6f}")
print("chart K 1.02..1.24, smile vol % " + " ".join(f"{100 * smile(x):6.2f}" for x in [1.02 + 0.02 * i for i in range(12)]))
print("chart K, flat digital at own vol " + " ".join(f"{usd_dig(S, x, smile(x)):6.2f}" for x in [1.02 + 0.02 * i for i in range(12)]))
print("chart K, digital on the smile    " + " ".join(f"{smile_dig(x):6.2f}" for x in [1.02 + 0.02 * i for i in range(12)]))
print("chart S 1.00..1.20, USD digital  " + " ".join(f"{usd_dig(x, K, sig):6.2f}" for x in [1.00 + 0.02 * i for i in range(11)]))
print("chart S, EUR digital in EUR      " + " ".join(f"{eur_dig(x, K, sig):6.2f}" for x in [1.00 + 0.02 * i for i in range(11)]))

assert abs(D - 0.532325) < 5e-7 and abs(E - 0.581012) < 5e-7, "formula vs the card's worked numbers"
assert abs(D_spread - D) < 1e-6,                    "call spread replicates the USD digital"
assert abs(D_mc - D) < 4 * se,                       "Monte Carlo within four standard errors"
assert abs(D + P_spread - exp(-rd * T)) < 1e-6,      "digital call + put = a discounted dollar"
assert abs(E_inv_spread - E) < 1e-6,                 "inverted-quote put spread = EUR digital"
assert abs(E_ident - E) < 1e-9,                      "asset-or-nothing identity"
assert abs(E_inv_formula - E) < 1e-9 and abs(E_mc - E) < 4 * seE, "inverted formula and EUR Monte Carlo"
assert abs(dlt_bump - dlt) < 1e-6 and abs(vg_bump - vg) < 1e-8, "delta and vega: formula vs bump"
assert abs(smile_spread(K3) - (flat3 + term3)) < 1e-6, "skew term vs call spread along the smile"
assert abs(v3 - 0.0975) < 1e-12 and abs(K3 - 1.201425) < 5e-7, "smile passes through its pillar"
print("ALL CHECKS PASS")
