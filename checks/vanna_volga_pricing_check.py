# Vanna-volga pricing -- the check behind the card.  Standard library only.
# House FX market: EURUSD spot 1.10, USD rate 5%, EUR rate 3%, one year; ATM 10%,
# 25-delta risk reversal -1%, 25-delta butterfly +0.25%.  Target: EUR call at 1.15.
# Normal CDF from its Taylor series; strikes and vols by bisection; weights by
# Gaussian elimination AND by a closed form; prices of risk by Cramer's rule.
from math import log, sqrt, exp, pi

S, RD, RF, T = 1.10, 0.05, 0.03, 1.0
ATM, RR, BF, KT = 0.10, -0.01, 0.0025, 1.15

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

F = S * exp((RD - RF) * T)
def d12(K, v, s=S):
    d1 = (log(s / K) + (RD - RF + 0.5 * v * v) * T) / (v * sqrt(T))
    return d1, d1 - v * sqrt(T)
def call(K, v, s=S):                                             # Garman-Kohlhagen, USD per EUR
    d1, d2 = d12(K, v, s)
    return s * exp(-RF * T) * N(d1) - K * exp(-RD * T) * N(d2)
def vega(K, v):  d1, d2 = d12(K, v); return S * exp(-RF * T) * phi(d1) * sqrt(T)
def vanna(K, v): d1, d2 = d12(K, v); return -exp(-RF * T) * phi(d1) * d2 / v
def volga(K, v): d1, d2 = d12(K, v); return vega(K, v) * d1 * d2 / v
def greeks(K): return [vega(K, ATM), vanna(K, ATM), volga(K, ATM)]

def pillars(atm, rr, bf):                                        # quotes -> three vols, three strikes
    vols = [atm + bf - rr / 2, atm, atm + bf + rr / 2]
    d1 = bisect(N, 0.25 * exp(RF * T), -10, 10)                  # N(d1) = 0.25 e^{rf T}
    ks = [F * exp(d1 * vols[0] * sqrt(T) + 0.5 * vols[0] ** 2 * T), F * exp(0.5 * atm * atm * T),
          F * exp(-d1 * vols[2] * sqrt(T) + 0.5 * vols[2] ** 2 * T)]
    return ks, vols

def gauss(A, b):                                                 # Gaussian elimination, partial pivots
    M = [A[i][:] + [b[i]] for i in range(3)]
    for c in range(3):
        p = max(range(c, 3), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, 3):
            f = M[r][c] / M[c][c]
            M[r] = [M[r][j] - f * M[c][j] for j in range(4)]
    x = [0.0] * 3
    for r in (2, 1, 0): x[r] = (M[r][3] - sum(M[r][j] * x[j] for j in range(r + 1, 3))) / M[r][r]
    return x
def det3(m): return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2]
                     - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
def cramer(A, b): return [det3([[b[r] if j == c else A[r][j] for j in range(3)] for r in range(3)]) / det3(A) for c in range(3)]

def vv(K, ks, vols, at_mkt=False):                               # flat price + market cost of the hedge
    A = [[g(k, v if at_mkt else ATM) for k, v in zip(ks, vols)] for g in (vega, vanna, volga)]
    x = gauss(A, greeks(K))
    gaps = [call(k, v) - call(k, ATM) for k, v in zip(ks, vols)]
    return call(K, ATM) + sum(xi * gi for xi, gi in zip(x, gaps)), x, gaps, A
def lagrange(K, ks):                                             # weights of a quadratic in ln K
    z, L = log(K), [log(k) for k in ks]
    return [(z - L[j]) * (z - L[k]) / ((L[i] - L[j]) * (L[i] - L[k])) for i, j, k in ((0, 1, 2), (1, 0, 2), (2, 0, 1))]
def first_order(K, ks, vols): return sum(w * v for w, v in zip(lagrange(K, ks), vols))
def iv(p, K): return bisect(lambda v: call(K, v), p, 0.001, 1.0)

ks, vols = pillars(ATM, RR, BF)
price, x, gaps, A = vv(KT, ks, vols)
flat = call(KT, ATM); g = greeks(KT)
x_cf = [vega(KT, ATM) / vega(k, ATM) * w for k, w in zip(ks, lagrange(KT, ks))]    # road 2: closed form
y = cramer([[A[r][c] for r in range(3)] for c in range(3)], gaps)               # A^T y = gaps
charges = [gi * yi for gi, yi in zip(g, y)]
n, b = 4000, 10.0                                                # road 3: flat price by Simpson,
a = (log(KT / S) - (RD - RF - 0.5 * ATM * ATM) * T) / (ATM * sqrt(T))   # from the kink upward
f = lambda z: (S * exp((RD - RF - 0.5 * ATM * ATM) * T + ATM * sqrt(T) * z) - KT) * phi(z)
flat_int = exp(-RD * T) * (b - a) / n / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * (b - a) / n) for i in range(n + 1))
h = 1e-4                                                         # Greeks of the target by bumping the price
bump = [(call(KT, ATM + h) - call(KT, ATM - h)) / (2 * h),
        (call(KT, ATM + h, S + h) - call(KT, ATM - h, S + h) - call(KT, ATM + h, S - h) + call(KT, ATM - h, S - h)) / (4 * h * h),
        (call(KT, ATM + h) - 2 * flat + call(KT, ATM - h)) / (h * h)]
iv_vv, iv_1 = iv(price, KT), first_order(KT, ks, vols)
back = [vv(k, ks, vols) for k in ks]                             # each pillar priced by the method itself
ks_f, vols_f = pillars(ATM, -RR, BF)                             # risk reversal read with the wrong sign

P = lambda v: f"{v * 1e4:.2f}"                                   # USD per EUR -> pips
print(f"forward F {F:.6f}   det A {det3(A):.6f}")
for i, nm in enumerate(("25d put ", "ATM     ", "25d call")):
    print(f"pillar {i+1} {nm}  K {ks[i]:.6f}  vol {vols[i]*100:.2f}%  mkt {P(call(ks[i], vols[i]))}  flat {P(call(ks[i], ATM))}  gap {P(gaps[i])}")
for r, nm in enumerate(("vega ", "vanna", "volga")):
    print(f"A {nm} " + " ".join(f"{v:10.6f}" for v in A[r]) + f"   target {g[r]:10.6f}  bumped {bump[r]:10.6f}")
print("weights, Gaussian elimination " + " ".join(f"{v:.6f}" for v in x))
print("weights, closed form          " + " ".join(f"{v:.6f}" for v in x_cf))
print("x_i times gap (pips)          " + " ".join(P(xi * gi) for xi, gi in zip(x, gaps)))
print("price of one unit, y_j        " + " ".join(f"{v:.8f}" for v in y))
print("charge g_j y_j (pips)         " + " ".join(P(c) for c in charges))
print(f"flat price at 10%   {P(flat)} pips   by Simpson {P(flat_int)} pips")
print(f"overlay, weights    {P(price - flat)} pips   by prices of risk {P(sum(charges))} pips")
print(f"vanna-volga price   {P(price)} pips  = USD {price * 1e7:,.2f} on EUR 10 million (flat USD {flat * 1e7:,.2f})")
print(f"implied vol of it   {iv_vv*100:.4f}%   first-order smile {iv_1*100:.4f}%   gap {(iv_vv-iv_1)*1e4:.4f} bp")
print("pillars back, pips            " + " ".join(P(p[0]) for p in back))
print(f"wrong: smile vol + overlay     {P(call(KT, iv_1) + price - flat)}")
print(f"wrong: ATM vega hedge only     {P(flat + vega(KT, ATM) / vega(ks[1], ATM) * gaps[1])}")
print(f"wrong: Greeks at pillar vols   {P(vv(KT, ks, vols, True)[0])}   pillar 1 back {P(vv(ks[0], ks, vols, True)[0])}")
print(f"wrong: risk reversal flipped   {P(vv(KT, ks_f, vols_f)[0])}")
print(f"try: K = 1.20                  {P(vv(1.20, ks, vols)[0] - call(1.20, ATM))} overlay")
print(f"try: K = 1.50                  {P(vv(1.50, ks, vols)[0] - call(1.50, ATM))} overlay on flat {P(call(1.50, ATM))}")
print(f"try: butterfly 0               {P(vv(KT, *pillars(ATM, RR, 0.0))[0] - flat)} overlay")
print(f"try: risk reversal 0           {P(vv(KT, *pillars(ATM, 0.0, BF))[0] - flat)} overlay")
grid = [1.00 + 0.025 * i for i in range(13)]
print("chart strike " + " ".join(f"{k:6.3f}" for k in grid))
print("chart overlay pips " + " ".join(P(vv(k, ks, vols)[0] - call(k, ATM)) for k in grid))
print("chart vv vol % " + " ".join(f"{iv(vv(k, ks, vols)[0], k)*100:.2f}" for k in grid))
print("chart 1st-order % " + " ".join(f"{first_order(k, ks, vols)*100:.2f}" for k in grid))

house = [1.052466, 1.127847, 1.201425]
assert all(abs(k - hk) < 5e-7 for k, hk in zip(ks, house)), "pillar strikes must match the house market"
assert all(abs(u - w) < 1e-10 for u, w in zip(x, x_cf)), "elimination and closed-form weights agree"
assert all(abs(p[0] - call(k, v)) < 1e-12 for p, k, v in zip(back, ks, vols)), "pillars priced back exactly"
assert abs((price - flat) - sum(charges)) < 1e-12, "weights road and prices-of-risk road agree"
assert abs(flat_int - flat) < 1e-9, "Simpson flat price equals the formula"
assert all(abs(u - w) < 1e-5 * max(1, abs(w)) for u, w in zip(bump, g)), "bumped Greeks equal closed forms"
assert abs(iv_vv - iv_1) < 1e-4, "implied vol within one basis point of the first-order smile"
print("ALL CHECKS PASS")
