# Hedging with the smile -- the check behind the card.  Standard library only.
# House FX market: EURUSD spot 1.10, USD rate 5%, EUR rate 3%, one year; ATM 10%,
# 25-delta risk reversal -1%, 25-delta butterfly +0.25%, pillars on spot delta.
# The smile is the vanna-volga curve.  Sticky delta: the quotes stay put when spot
# moves, so the pillars are rebuilt at the new spot.  Normal CDF from its series,
# strikes and vols by bisection, vanna-volga weights by Gaussian elimination.
from math import log, sqrt, exp, pi

S0, RD, RF, T = 1.10, 0.05, 0.03, 1.0
ATM, RR, BF, NOTIONAL = 0.10, -0.01, 0.0025, 10_000_000

def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)            # bell-curve height
def N(x):                                                        # bell-curve area, by series
    if abs(x) > 8: return 0.0 if x < 0 else 1.0
    term = s = x; n = 0
    while abs(term) > 1e-17:
        n += 1; term *= x * x / (2 * n + 1); s += term
    return 0.5 + phi(x) * s
def bisect(f, target, lo, hi):                                   # f increasing
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return 0.5 * (lo + hi)

def d1(s, K, v): return (log(s / K) + (RD - RF + 0.5 * v * v) * T) / (v * sqrt(T))
def call(s, K, v):                                               # Garman-Kohlhagen, USD per EUR
    a = d1(s, K, v); return s * exp(-RF * T) * N(a) - K * exp(-RD * T) * N(a - v * sqrt(T))
def put(s, K, v): return call(s, K, v) - s * exp(-RF * T) + K * exp(-RD * T)
def delta(s, K, v): return exp(-RF * T) * N(d1(s, K, v))         # spot delta of the call
def vega(s, K, v): return s * exp(-RF * T) * phi(d1(s, K, v)) * sqrt(T)
def vanna(s, K, v): a = d1(s, K, v); return -exp(-RF * T) * phi(a) * (a - v * sqrt(T)) / v
def volga(s, K, v): a = d1(s, K, v); return vega(s, K, v) * a * (a - v * sqrt(T)) / v

def pillars(s):                                                  # quotes -> strikes at spot s
    F = s * exp((RD - RF) * T); vols = [ATM + BF - RR / 2, ATM, ATM + BF + RR / 2]
    x = bisect(N, 0.25 * exp(RF * T), -10, 10)                   # N(d1) = 0.25 e^{rf T}
    ks = [F * exp(x * vols[0] * sqrt(T) + 0.5 * vols[0] ** 2 * T), F * exp(0.5 * ATM * ATM * T),
          F * exp(-x * vols[2] * sqrt(T) + 0.5 * vols[2] ** 2 * T)]
    return ks, vols
def gauss(A, b):                                                 # Gaussian elimination, partial pivots
    M = [A[i][:] + [b[i]] for i in range(3)]
    for c in range(3):
        p = max(range(c, 3), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, 3):
            f = M[r][c] / M[c][c]; M[r] = [M[r][j] - f * M[c][j] for j in range(4)]
    x = [0.0] * 3
    for r in (2, 1, 0): x[r] = (M[r][3] - sum(M[r][j] * x[j] for j in range(r + 1, 3))) / M[r][r]
    return x
def vv(s, K):                                                    # vanna-volga call price at spot s
    ks, vols = pillars(s); gs = (vega, vanna, volga)
    x = gauss([[g(s, k, ATM) for k in ks] for g in gs], [g(s, K, ATM) for g in gs])
    return call(s, K, ATM) + sum(xi * (call(s, k, v) - call(s, k, ATM)) for xi, k, v in zip(x, ks, vols))
def smile(s, K): return bisect(lambda v: call(s, K, v), vv(s, K), 0.001, 1.0)
def first_order_slope(s, K):                                     # d(sigma)/d(ln K), quadratic in ln K
    ks, vols = pillars(s); z, L = log(K), [log(k) for k in ks]
    return sum(v * (2 * z - L[j] - L[k]) / ((L[i] - L[j]) * (L[i] - L[k]))
               for v, (i, j, k) in zip(vols, ((0, 1, 2), (1, 0, 2), (2, 0, 1))))

def study(K, sign):                                              # sign +1 call, -1 put
    h, s1 = 1e-4, S0 * 1.01
    v0, v1 = smile(S0, K), smile(s1, K)
    slope = lambda s: (smile(s + h, K) - smile(s - h, K)) / (2 * h)       # rebuild at moved spot
    sk = (smile(S0, K + h) - smile(S0, K - h)) / (2 * h)                   # smile's slope in strike
    road1 = -(K / S0) * sk
    road2, road3 = slope(S0), -first_order_slope(S0, K) / S0              # first-order smile
    bs = delta(S0, K, v0) - (exp(-RF * T) if sign < 0 else 0)
    sa = bs + vega(S0, K, v0) * road2
    pr = lambda s: vv(s, K) - (0 if sign > 0 else s * exp(-RF * T) - K * exp(-RD * T))
    rep = (pr(S0 + h) - pr(S0 - h)) / (2 * h)                              # full reprice, sticky delta
    price = call if sign > 0 else put
    gam = exp(-RF * T) * phi(d1(S0, K, v0)) / (S0 * v0 * sqrt(T))
    return dict(K=K, sk=sk, v0=v0, v1=v1, r1=road1, r2=road2, r3=road3, bs=bs, sa=sa, rep=rep, move=s1 - S0,
                vg=vega(S0, K, v0), dsd=pr(s1) - pr(S0), dss=price(s1, K, v0) - price(S0, K, v0),
                gterm=0.5 * gam * (s1 - S0) ** 2, vterm=vega(s1, K, v0) * (v1 - v0),
                trap=0.5 * (road2 + slope(s1)) * (s1 - S0), dn=pr(S0 * 0.99) - pr(S0), mvd=-0.01 * S0)

ks, vols = pillars(S0)
c, p = study(ks[2], +1), study(ks[0], -1)
s1 = S0 * 1.01
k1 = bisect(lambda k: -delta(s1, k, smile(s1, k)), -0.25, 1.10, 1.40)  # new 25-delta strike
print(f"forward {S0 * exp((RD - RF) * T):.6f}   pillars " + " ".join(f"{k:.6f}" for k in ks))
for nm, r in (("call", c), ("put ", p)):
    print(f"{nm} strike                 {r['K']:.6f}   vol {r['v0']*100:.4f}%")
    print(f"{nm} BS spot delta          {r['bs']:+.6f}")
    print(f"{nm} vega, per 1.00 of vol  {r['vg']:.6f}")
    print(f"{nm} dvol/dK, smile slope   {r['sk']:+.6f}")
    print(f"{nm} dvol/dS, strike slope  {r['r1']:+.6f}")
    print(f"{nm} dvol/dS, rebuilt smile {r['r2']:+.6f}")
    print(f"{nm} dvol/dS, first order   {r['r3']:+.6f}")
    print(f"{nm} vega x dvol/dS         {r['sa']-r['bs']:+.6f}")
    print(f"{nm} smile delta, formula   {r['sa']:+.6f}")
    print(f"{nm} smile delta, reprice   {r['rep']:+.6f}")
    print(f"{nm} vol after 1% move      {r['v1']*100:.4f}%   sticky strike {r['v0']*100:.4f}%")
    print(f"{nm} vol change, points     slope x move {r['r2']*r['move']*100:+.4f}   actual {(r['v1']-r['v0'])*100:+.4f}")
    print(f"{nm} value change, USD      sticky delta {r['dsd']*NOTIONAL:,.2f}   sticky strike {r['dss']*NOTIONAL:,.2f}")
    print(f"{nm} left after hedge, USD  BS {(r['dsd']-r['bs']*r['move'])*NOTIONAL:,.2f}   smile {(r['dsd']-r['sa']*r['move'])*NOTIONAL:,.2f}")
    print(f"{nm} half gamma x move^2    {r['gterm']*NOTIONAL:,.2f}   vega x vol change {r['vterm']*NOTIONAL:,.2f}")
    print(f"{nm} 1% down, left, USD     BS {(r['dn']-r['bs']*r['mvd'])*NOTIONAL:,.2f}   smile {(r['dn']-r['sa']*r['mvd'])*NOTIONAL:,.2f}")
    print(f"{nm} hedge gap, EUR         {(r['sa']-r['bs'])*NOTIONAL:,.0f}   % of notional {(r['sa']-r['bs'])*100:.2f}   x move, USD {(r['sa']-r['bs'])*r['move']*NOTIONAL:,.2f}")
print(f"25-delta strike at 1.111    {k1:.6f}   vol {smile(s1, k1)*100:.4f}%   ratio {k1/ks[2]:.6f}")
print(f"wrong: sign of strike slope {c['bs'] - c['vg']*c['r2']:+.6f}")
print(f"wrong: slope in vol points  {c['bs'] + c['vg']*c['r2']*100:+.6f}")
grid = [1.00 + 0.025 * i for i in range(13)]
print("chart strike      " + " ".join(f"{k:6.3f}" for k in grid))
print("chart vol % 1.100 " + " ".join(f"{smile(S0, k)*100:6.2f}" for k in grid))
print("chart vol % 1.111 " + " ".join(f"{smile(s1, k)*100:6.2f}" for k in grid))
corr = [vega(S0, k, smile(S0, k)) * (smile(S0 + 1e-4, k) - smile(S0 - 1e-4, k)) / 2e-4 for k in grid]
print("chart correction %" + " ".join(f"{x*100:6.2f}" for x in corr))

assert abs(c['bs'] - 0.25) < 1e-12, "call pillar sits at 25 delta"
assert abs(p['bs'] + 0.25) < 1e-12, "put pillar sits at -25 delta"
for r in (c, p):
    assert abs(r['r1'] - r['r2']) < 1e-7, "strike slope and rebuilt smile agree (sticky delta = sticky moneyness)"
    assert abs(r['sa'] - r['rep']) < 1e-6, "formula and full reprice agree"
    assert abs(r['r3'] - r['r2']) < 0.1 * abs(r['r2']), "first-order smile within 10% of the exact slope"
    assert abs(r['trap'] / (r['v1'] - r['v0']) - 1) < 0.03, "vol change = average slope x move"
    assert abs(r['dss'] - r['bs'] * r['move'] - r['gterm']) < 0.03 * r['gterm'], "sticky-strike residual is gamma"
    assert abs(r['dsd'] - r['dss'] - r['vterm']) < 0.03 * abs(r['vterm']), "the smile adds vega x vol change"
assert abs(k1 / ks[2] - 1.01) < 1e-9, "25-delta strike rides with spot"
assert abs(smile(s1, k1) - vols[2]) < 1e-9, "25-delta vol unchanged"
print("ALL CHECKS PASS")
