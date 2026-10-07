# The vanna-volga smile -- the check behind the card.  Standard library only.
# House FX market: EURUSD spot 1.10 dollars per euro, USD rate 5%, EUR rate 3%, one year;
# ATM 10.00%, 25-delta risk reversal -1.00%, 25-delta butterfly +0.25%.
# Nothing imported knows the answer: N(x) is summed from a series, roots are found by halving.
from math import log, sqrt, exp, pi

def N(x):                                   # bell-curve area left of x: erf from its all-positive series
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    z = abs(x) / sqrt(2.0); term = s = z; n = 0
    while term > 1e-17 * s:
        n += 1; term *= 2.0 * z * z / (2 * n + 1); s += term
    e = 2.0 / sqrt(pi) * exp(-z * z) * s
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def halve(f, lo, hi):                       # f increasing, f(lo) < 0 < f(hi)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

S, rd, rf = 1.10, 0.05, 0.03
def market(T, atm, rr, bf):                 # quotes -> forward, pillar strikes (each at its own vol), pillar vols
    F = S * exp((rd - rf) * T)
    vs = [atm + bf - rr / 2, atm, atm + bf + rr / 2]
    a = halve(lambda d: exp(-rf * T) * N(d) - 0.25, -8.0, 8.0)   # spot delta 0.25 -> the call's d1
    Ks = [F * exp(a * vs[0] * sqrt(T) + vs[0] ** 2 * T / 2), F * exp(vs[1] ** 2 * T / 2),
          F * exp(-a * vs[2] * sqrt(T) + vs[2] ** 2 * T / 2)]
    return F, T, Ks, vs
def d12(m, K, v):
    F, T = m[0], m[1]; d1 = (log(F / K) + 0.5 * v * v * T) / (v * sqrt(T)); return d1, d1 - v * sqrt(T)
def call(m, K, v):
    d1, d2 = d12(m, K, v); return S * exp(-rf * m[1]) * N(d1) - K * exp(-rd * m[1]) * N(d2)
def vega(m, K, v): return S * exp(-rf * m[1]) * phi(d12(m, K, v)[0]) * sqrt(m[1])
def vanna(m, K, v): d1, d2 = d12(m, K, v); return -exp(-rf * m[1]) * phi(d1) * d2 / v
def volga(m, K, v): d1, d2 = d12(m, K, v); return vega(m, K, v) * d1 * d2 / v

def ys(m, x):                               # the log-strike weights y1, y2, y3
    K1, K2, K3 = m[2]
    return [log(K2 / x) * log(K3 / x) / (log(K2 / K1) * log(K3 / K1)),
            log(x / K1) * log(K3 / x) / (log(K2 / K1) * log(K3 / K2)),
            log(x / K1) * log(x / K2) / (log(K3 / K1) * log(K3 / K2))]
def first(m, x): return sum(y * v for y, v in zip(ys(m, x), m[3]))
def second(m, x, keep_D2=True):             # Road 1: Castagna-Mercurio second order -> (vol or None, discriminant)
    y, s2 = ys(m, x), m[3][1]
    D1 = first(m, x) - s2
    D2 = sum(y[i] * d12(m, m[2][i], s2)[0] * d12(m, m[2][i], s2)[1] * (m[3][i] - s2) ** 2 for i in (0, 2))
    D2 = D2 if keep_D2 else 0.0
    ab = d12(m, x, s2)[0] * d12(m, x, s2)[1]
    if abs(ab) < 1e-9: return s2 + D1 + D2 / (2 * s2), 1.0      # the 0/0 point: take the limit
    disc = s2 * s2 + ab * (2 * s2 * D1 + D2)
    return (s2 + (-s2 + sqrt(disc)) / ab if disc >= 0 else None), disc

def det3(A): return (A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1]) - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
                     + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]))
def vv_price(m, x):                         # Road 2: the full vanna-volga price, weights by a 3x3 solve
    s2, Ks, vs = m[3][1], m[2], m[3]
    A = [[g(m, K, s2) for K in Ks] for g in (vega, vanna, volga)]
    b = [g(m, x, s2) for g in (vega, vanna, volga)]
    w = [det3([[b[r] if j == c else A[r][j] for j in range(3)] for r in range(3)]) / det3(A) for c in range(3)]
    return call(m, x, s2) + sum(w[i] * (call(m, Ks[i], vs[i]) - call(m, Ks[i], s2)) for i in range(3)), w
def implied(m, x, p): return halve(lambda v: call(m, x, v) - p, 1e-4, 1.0)
def density(m, x, h=1e-3):                  # e^{rd T} d2C/dK2 along the curve: must never be negative
    C = lambda k: call(m, k, second(m, k)[0])
    return exp(rd * m[1]) * (C(x - h) - 2 * C(x) + C(x + h)) / (h * h)

H = market(1.0, 0.10, -0.01, 0.0025)
F, T, Ks, vs = H
def row(name, *v): print(f"{name:<38}" + "".join(f" {u:>12.6f}" for u in v))
row("forward F", F)
for i, lab in enumerate(("25d put", "ATM", "25d call")):
    row(f"pillar {lab}: strike, vol read back", Ks[i], second(H, Ks[i])[0])
x = 1.15
y = ys(H, x); s2 = vs[1]
row("ln(K2/K1), ln(K3/K2), ln(K3/K1)", log(Ks[1] / Ks[0]), log(Ks[2] / Ks[1]), log(Ks[2] / Ks[0]))
row("K=1.15  ln(K/K1), ln(K/K2), ln(K/K3)", *[log(x / K) for K in Ks])
for i in range(3): row(f"K=1.15  weight y{i+1}", y[i])
row("K=1.15  first order  sum y_i sigma_i", first(H, x))
row("K=1.15  D1", first(H, x) - s2)
row("d1 d2 at K1 and at K3, ATM vol", *[d12(H, Ks[i], s2)[0] * d12(H, Ks[i], s2)[1] for i in (0, 2)])
row("K=1.15  D2, in millionths", 1e6 * sum(y[i] * d12(H, Ks[i], s2)[0] * d12(H, Ks[i], s2)[1] * (vs[i] - s2) ** 2 for i in (0, 2)))
row("K=1.15  d1 d2 at the ATM vol", d12(H, x, s2)[0] * d12(H, x, s2)[1])
row("K=1.15  discriminant, its square root", second(H, x)[1], sqrt(second(H, x)[1]))
row("K=1.15  1 second order", second(H, x)[0])
p115, w = vv_price(H, x)
row("K=1.15  2 full VV price", p115); row("K=1.15  2 full VV, implied vol", implied(H, x, p115))
cm = [vega(H, x, s2) / vega(H, Ks[i], s2) * y[i] for i in range(3)]
for i in range(3): row(f"K=1.15  weight x{i+1}: 3x3 solve", w[i]); row(f"K=1.15  weight x{i+1}: nu(K)/nu(K{i+1}) y{i+1}", cm[i])
x = 1.40
p140 = vv_price(H, x)[0]
row("K=1.40  first order", first(H, x)); row("K=1.40  1 second order", second(H, x)[0])
row("K=1.40  2 full VV, implied vol", implied(H, x, p140))
row("K=1.40  call on the VV curve", call(H, x, second(H, x)[0])); row("K=1.40  call, flat 9.75% past K3", call(H, x, vs[2]))
kmin = halve(lambda k: second(H, k + 1e-6)[0] - second(H, k - 1e-6)[0], 1.13, 1.35)
row("curve's lowest point, strike", kmin); row("curve's lowest point, vol", second(H, kmin)[0])
row("K=0.80  first order", first(H, 0.80)); row("K=0.80  second order", second(H, 0.80)[0])
row("wrong: pillars all at 10%, K=1.15", second((F, T, market(1.0, 0.10, 0.0, 0.0)[2], vs), 1.15)[0])
row("wrong: drop D2, K=1.40", second(H, 1.40, False)[0])
row("house density, lowest on 0.80..1.60", min(density(H, 0.80 + 0.01 * i) for i in range(81)))
St = market(1.0, 0.10, -0.03, 0.0025)       # a steep skew: risk reversal -3%
kb = halve(lambda k: -second(St, k)[1], 1.21, 1.40)
row("steep skew: vols K1, K3; strike K3", St[3][0], St[3][2], St[2][2]); row("steep skew: vol at K=1.25", second(St, 1.25)[0]); row("steep skew: density at K=1.25", density(St, 1.25))
row("steep skew: vol at end - 0.002", second(St, kb - 0.002)[0]); row("steep skew: density at end - 0.002", density(St, kb - 0.002))
row("steep skew: curve ends at strike", kb)
M6 = market(0.5, 0.12, -0.01, 0.01)         # a 6-month market: ATM 12%, RR -1%, BF +1%
tv = lambda m, k: second(m, m[0] * exp(k))[0] ** 2 * m[1] * 100
for k in (0.0, 0.3): row(f"total var x100, k={k:.1f}: 1y", tv(H, k)); row(f"total var x100, k={k:.1f}: 6m", tv(M6, k))
print(f"{'chart, strike':<27}" + "".join(f"{0.95 + 0.05 * i:6.2f}" for i in range(11)))
grid = [0.95 + 0.05 * i for i in range(11)]
print(f"{'chart, VV curve %':<27}" + "".join(f"{100 * second(H, k)[0]:6.2f}" for k in grid))
print(f"{'chart, first order %':<27}" + "".join(f"{100 * first(H, k):6.2f}" for k in grid))
print(f"{'chart, flat past pillars %':<27}" + "".join(f"{100 * (vs[0] if k < Ks[0] else vs[2] if k > Ks[2] else second(H, k)[0]):6.2f}" for k in grid))
print(f"{'chart, k':<27}" + "".join(f"{-0.3 + 0.1 * i:6.2f}" for i in range(8)))
print(f"{'chart, 1y total var x100':<27}" + "".join(f"{tv(H, -0.3 + 0.1 * i):6.2f}" for i in range(8)))
print(f"{'chart, 6m total var x100':<27}" + "".join(f"{tv(M6, -0.3 + 0.1 * i):6.2f}" for i in range(8)))

assert all(abs(K - k0) < 5e-7 for K, k0 in zip(Ks, (1.052466, 1.127847, 1.201425))), "house pillar strikes"
assert all(abs(second(H, Ks[i])[0] - vs[i]) < 1e-12 for i in range(3)), "the curve passes through its three quotes"
assert abs(second(H, 1.15)[0] - implied(H, 1.15, p115)) < 1e-6, "road 1 (closed form) meets road 2 (full VV price)"
assert all(abs(w - c) < 1e-9 for w, c in zip(vv_price(H, 1.15)[1], cm)), "3x3 weights equal the closed-form weights"
assert 0.0975 < second(H, 1.15)[0] < 0.10, "1.15 lands between the ATM and 25d call vols"
assert second(H, 1.40)[0] > vs[1] and call(H, 1.40, second(H, 1.40)[0]) > 1.5 * call(H, 1.40, vs[2]), "the wing turns up"
assert min(density(H, 0.80 + 0.01 * i) for i in range(81)) > 0, "the house curve passes the butterfly test"
assert density(St, kb - 0.002) < 0 and second(St, kb + 0.001)[0] is None, "steep skew: negative density, then no vol"
assert tv(M6, 0.0) < tv(H, 0.0), "at the money the 6m total variance sits below the 1y"
assert tv(M6, 0.3) > tv(H, 0.3), "in the wing it crosses above: calendar arbitrage"
print("ALL CHECKS PASS")
