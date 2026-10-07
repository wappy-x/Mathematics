# Garman-Kohlhagen Greeks -- the check behind the card.  Standard library only.
# EUR call / USD put.  Prices in USD per EUR of notional.  Three roads to every
# Greek: the closed forms, bumps of the closed-form price, bumps of a Simpson
# integral that never uses d1 or d2.  Then the other currency, via the symmetry.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                   # bell-curve area, own series
    if x < 0: return 1.0 - N(-x)
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        n += 1; term *= x * x / (2 * n + 1); total += term
    return 0.5 + phi(x) * total

def d12(S, K, rd, rf, v, T):
    d1 = (log(S / K) + (rd - rf + 0.5 * v * v) * T) / (v * sqrt(T))
    return d1, d1 - v * sqrt(T)

def gk(S, K, rd, rf, v, T, call=True):                      # road 1 price
    d1, d2 = d12(S, K, rd, rf, v, T)
    if call: return S * exp(-rf * T) * N(d1) - K * exp(-rd * T) * N(d2)
    return K * exp(-rd * T) * N(-d2) - S * exp(-rf * T) * N(-d1)

def gk_int(S, K, rd, rf, v, T, call=True, n=4000):          # road 3 price: no d1, no d2
    m, s = (rd - rf - 0.5 * v * v) * T, v * sqrt(T)
    zs = (log(K / S) - m) / s                                # where the payoff hits zero
    a, b = (zs, 12.0) if call else (-12.0, zs)
    h, tot = (b - a) / n, 0.0
    for i in range(n + 1):
        z = a + i * h
        w = 1 if i in (0, n) else (4 if i % 2 else 2)
        tot += w * (S * exp(m + s * z) - K) * phi(z)
    return (1 if call else -1) * exp(-rd * T) * tot * h / 3.0

def formulas(S, K, rd, rf, v, T, call=True):                # road 1 Greeks; w = +1 call, -1 put
    d1, d2 = d12(S, K, rd, rf, v, T)
    ef, ed, w = exp(-rf * T), exp(-rd * T), (1 if call else -1)
    return {"delta": w * ef * N(w * d1), "gamma": ef * phi(d1) / (S * v * sqrt(T)),
            "vega": S * ef * phi(d1) * sqrt(T),
            "theta": -S * ef * phi(d1) * v / (2 * sqrt(T)) + w * (rf * S * ef * N(w * d1) - rd * K * ed * N(w * d2)),
            "rho USD": w * K * T * ed * N(w * d2), "rho EUR": -w * S * T * ef * N(w * d1)}

def bumps(price, S, K, rd, rf, v, T, call=True):            # roads 2 and 3 Greeks
    p = lambda S=S, rd=rd, rf=rf, v=v, T=T: price(S, K, rd, rf, v, T, call)
    hS, e = 1e-4 * S, 1e-4
    return {"delta": (p(S=S + hS) - p(S=S - hS)) / (2 * hS),
            "gamma": (p(S=S + hS) - 2 * p() + p(S=S - hS)) / hS ** 2,
            "vega": (p(v=v + e) - p(v=v - e)) / (2 * e),
            "theta": -(p(T=T + e) - p(T=T - e)) / (2 * e),
            "rho USD": (p(rd=rd + e) - p(rd=rd - e)) / (2 * e),
            "rho EUR": (p(rf=rf + e) - p(rf=rf - e)) / (2 * e)}

S, K, rd, rf, v, T, NOT = 1.10, 1.10, 0.05, 0.03, 0.10, 1.0, 10_000_000
d1, d2 = d12(S, K, rd, rf, v, T)
C, P = gk(S, K, rd, rf, v, T), gk(S, K, rd, rf, v, T, False)
g1, g2, g3 = formulas(S, K, rd, rf, v, T), bumps(gk, S, K, rd, rf, v, T), bumps(gk_int, S, K, rd, rf, v, T)
print(f"d1 {d1:.6f}  d2 {d2:.6f}  N(d1) {N(d1):.6f}  N(d2) {N(d2):.6f}  phi(d1) {phi(d1):.6f}")
print(f"e^-rfT {exp(-rf * T):.6f}  e^-rdT {exp(-rd * T):.6f}  forward {S * exp((rd - rf) * T):.6f}")
print(f"call {C:.6f}  put {P:.6f}  call by integral {gk_int(S, K, rd, rf, v, T):.6f}")
print(f"{'Greek':<9}{'1 formula':>12}{'2 bump formula':>16}{'3 bump integral':>17}")
for k in g1: print(f"{k:<9}{g1[k]:>12.6f}{g2[k]:>16.6f}{g3[k]:>17.6f}")
# the PDE ties theta to the others: theta = rd C - (rd - rf) S delta - 0.5 v^2 S^2 gamma
th_pde = rd * C - (rd - rf) * S * g3["delta"] - 0.5 * v * v * S * S * g3["gamma"]
print(f"theta decay term {-S * exp(-rf * T) * phi(d1) * v / (2 * sqrt(T)):.6f}")
print(f"theta from the PDE, road-3 delta and gamma {th_pde:.6f}")
print(f"rho USD + rho EUR {g1['rho USD'] + g1['rho EUR']:.6f}   -T x call {-T * C:.6f}")
print("desk units on EUR 10m notional")
print(f"  premium                      USD {C * NOT:>12,.0f}")
print(f"  delta hedge, sell            EUR {g1['delta'] * NOT:>12,.0f}")
print(f"  gamma, delta change per 1% spot move {g1['gamma'] * S * 0.01:.6f} = EUR {g1['gamma'] * S * 0.01 * NOT:,.0f}")
print(f"  vega per vol point {g1['vega'] / 100:.6f} USD per EUR = USD {g1['vega'] / 100 * NOT:,.0f}")
print(f"  theta per day {g1['theta'] / 365:.8f} USD per EUR = USD {g1['theta'] / 365 * NOT:,.0f}")
print(f"  rho USD per bp USD {g1['rho USD'] * 1e-4 * NOT:,.2f}   rho EUR per bp USD {g1['rho EUR'] * 1e-4 * NOT:,.2f}")
# the other currency: the same contract is a USD put / EUR call for a EUR-based holder,
# spot 1/S EUR per USD, strike 1/K, domestic rate rf, foreign rate rd, on K USD per EUR notional
x, k = 1 / S, 1 / K
h1, h3 = formulas(x, k, rf, rd, v, T, False), bumps(gk_int, x, k, rf, rd, v, T, False)
print("seen from EUR, per EUR of notional, in EUR   [USD figure / spot]  [EUR-side bumps]")
print(f"  premium       {gk(x, k, rf, rd, v, T, False) * K:.6f}   [{C / S:.6f}]  [{gk_int(x, k, rf, rd, v, T, False) * K:.6f}]")
print(f"  vega          {h1['vega'] * K:.6f}   [{g1['vega'] / S:.6f}]  [{h3['vega'] * K:.6f}]")
print(f"  theta         {h1['theta'] * K:.6f}   [{g1['theta'] / S:.6f}]  [{h3['theta'] * K:.6f}]")
print(f"  rho EUR rate  {h1['rho USD'] * K:.6f}   [{g1['rho EUR'] / S:.6f}]  [{h3['rho USD'] * K:.6f}]")
print(f"  rho USD rate  {h1['rho EUR'] * K:.6f}   [{g1['rho USD'] / S:.6f}]  [{h3['rho EUR'] * K:.6f}]")
pa = -h1["delta"] * K / S                                    # EUR sold per EUR of notional
print(f"  EUR-side hedge, sell EUR per EUR {pa:.6f}   [delta - C/S {g1['delta'] - C / S:.6f}]  = EUR {pa * NOT:,.0f}")
print("what breaks")
print(f"  delta without e^-rfT (N(d1))        {N(d1):.6f}  EUR {N(d1) * NOT:,.0f}")
print(f"  vega per unit read as per point     USD {g1['vega'] * NOT:,.0f}")
print(f"  both rates up 1bp, only rho USD     USD {g1['rho USD'] * 1e-4 * NOT:,.2f}  true USD {(g2['rho USD'] + g2['rho EUR']) * 1e-4 * NOT:,.2f}")
print(f"  gamma with phi(d2)                  {exp(-rf * T) * phi(d2) / (S * v * sqrt(T)):.6f}")
print(f"  theta without the EUR carry term    {g1['theta'] - rf * S * exp(-rf * T) * N(d1):.6f}")
print("chart: spot delta across spot")
spots = [1.00 + 0.02 * i for i in range(11)]
print("  spot     " + " ".join(f"{s:.2f}" for s in spots))
for lab, t in (("12 months", 1.0), ("1 month  ", 1 / 12)):
    print(f"  {lab} " + " ".join(f"{formulas(s, K, rd, rf, v, t)['delta']:.2f}" for s in spots))
print("bars: vega per vol point on EUR 10m, USD, 12 months")
for s in (1.00, 1.05, 1.10, 1.15, 1.20):
    print(f"  spot {s:.2f}  USD {formulas(s, K, rd, rf, v, T)['vega'] / 100 * NOT:>7,.0f}")
print("bars: rho per bp on EUR 10m, USD, by maturity, spot and strike 1.10")
for t in (0.25, 1.0, 2.0, 5.0):
    f = formulas(S, K, rd, rf, v, t)
    print(f"  {t:>4.2f} yr  USD rate {f['rho USD'] * 1e-4 * NOT:>8,.0f}   EUR rate {f['rho EUR'] * 1e-4 * NOT:>8,.0f}")

for sp, tt in ((S, T), (1.12, 0.25)):                       # the house case and a 3-month one
    fa, fb = formulas(sp, K, rd, rf, v, tt), bumps(gk_int, sp, K, rd, rf, v, tt)
    for key in fa: assert abs(fa[key] - fb[key]) < 1e-5 * max(1, abs(fa[key])), key + ": formula vs integral road"
assert abs(C - 0.053556) < 5e-7, "house premium from the shelf"
assert abs(th_pde - g1["theta"]) < 1e-6, "theta: closed form vs PDE built from road 3"
assert abs(h1["vega"] * K - g3["vega"] / S) < 1e-6, "vega: EUR-side formula vs USD-side integral bump"
assert abs(pa - (g3["delta"] - C / S)) < 1e-6, "EUR-side hedge vs delta minus premium"
for j, u in (("vega", "vega"), ("theta", "theta"), ("rho USD", "rho EUR"), ("rho EUR", "rho USD")):
    assert abs(h1[j] * K - g1[u] / S) < 1e-9 and abs(h3[j] * K - g1[u] / S) < 1e-6, j + ": EUR side vs USD figure / spot"
assert abs(gk_int(x, k, rf, rd, v, T, False) * K - C / S) < 1e-6, "EUR premium: EUR-side integral vs C / S"
assert abs(g2["rho USD"] + g2["rho EUR"] + T * C) < 1e-6, "parallel rate shift = -T x price"
print("ALL CHECKS PASS")
