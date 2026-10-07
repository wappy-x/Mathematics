# FX delta conventions -- the check behind the card.  Standard library only.
# The bell-curve area is its own series, prices come by Simpson's rule, strikes by
# bisection, and the Monte Carlo uses its own xorshift generator.  Nothing imported knows the answer.
from math import exp, log, sqrt, pi, cos
S, K, rd, rf, vol, T = 1.10, 1.10, 0.05, 0.03, 0.10, 1.0      # EURUSD house market: USD 5%, EUR 3%

def n(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def N(x):                                   # 0.5 + n(x) * (x + x^3/3 + x^5/15 + ...)
    if x < -9: return 0.0
    if x > 9: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total) + 1e-300:
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + n(x) * total
def Ninv(p):                                 # Newton on the series N
    x = 0.0
    for _ in range(60): x -= (N(x) - p) / n(x)
    return x
def d12(s, k, t, v):
    d1 = (log(s / k) + (rd - rf + 0.5 * v * v) * t) / (v * sqrt(t))
    return d1, d1 - v * sqrt(t)
def deltas(s, k, t, v, phi=1):               # spot, forward, premium-adjusted spot and forward
    d1, d2 = d12(s, k, t, v); f = s * exp((rd - rf) * t)
    return (phi * exp(-rf * t) * N(phi * d1), phi * N(phi * d1),
            phi * exp(-rd * t) * k / s * N(phi * d2), phi * k / f * N(phi * d2))
def gk(s, k, t, v, phi=1):
    d1, d2 = d12(s, k, t, v)
    return phi * (s * exp(-rf * t) * N(phi * d1) - k * exp(-rd * t) * N(phi * d2))
def simpson_price(s, k, t, v, phi=1, m=4000):  # Road 2: average the payoff over the bell curve, no N
    zk = (log(k / s) - (rd - rf - 0.5 * v * v) * t) / (v * sqrt(t))
    a, b = (zk, 9.0) if phi == 1 else (-9.0, zk)
    h = (b - a) / m; tot = 0.0
    for i in range(m + 1):
        z = a + i * h; w = 1 if i in (0, m) else (4 if i % 2 else 2)
        tot += w * max(phi * (s * exp((rd - rf - 0.5 * v * v) * t + v * sqrt(t) * z) - k), 0.0) * n(z)
    return exp(-rd * t) * tot * h / 3
def bumped(k, phi=1, h=1e-5):                # Road 2: bump spot, reprice by Simpson
    up, dn = simpson_price(S + h, k, T, vol, phi), simpson_price(S - h, k, T, vol, phi)
    fwd_contract = (exp(-rf * T) * (S + h) - exp(-rf * T) * (S - h)) / (2 * h)   # one EUR forward
    spot = (up - dn) / (2 * h)
    pa = S * (up / (S + h) - dn / (S - h)) / (2 * h)
    return spot, spot / fwd_contract, pa, pa / fwd_contract
def monte_carlo(paths=400000):               # Road 3: pathwise averages, xorshift + Box-Muller
    st = 88172645463325252; acc_s = acc_c = 0.0
    def u():
        nonlocal st
        st ^= (st << 13) & 0xFFFFFFFFFFFFFFFF; st ^= st >> 7; st ^= (st << 17) & 0xFFFFFFFFFFFFFFFF
        return ((st >> 11) + 0.5) / 9007199254740992.0
    for _ in range(paths // 2):
        z = sqrt(-2 * log(u())) * cos(2 * pi * u())
        for zz in (z, -z):                   # antithetic pair
            sT = S * exp((rd - rf - 0.5 * vol * vol) * T + vol * sqrt(T) * zz)
            if sT > K: acc_s += sT / S; acc_c += K / S
    ms, mc = exp(-rd * T) * acc_s / paths, exp(-rd * T) * acc_c / paths
    return ms, ms / exp(-rf * T), mc, mc / exp(-rf * T)
def strike_for(target, which, phi=1):        # bisection on strike, any convention
    lo, hi = 0.95, 2.5                        # right of the premium-adjusted peak
    if phi == -1: lo, hi = 0.5, 1.5
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if deltas(S, mid, T, vol, phi)[which] > target: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

names = ("spot delta", "forward delta", "pa spot delta", "pa forward delta")
d1, d2 = d12(S, K, T, vol); F = S * exp((rd - rf) * T); C, P = gk(S, K, T, vol), gk(S, K, T, vol, -1)
print(f"d1 {d1:.6f}   d2 {d2:.6f}   N(d1) {N(d1):.6f}   N(d2) {N(d2):.6f}")
print(f"forward F {F:.6f}   e^-rf T {exp(-rf * T):.6f}   e^-rd T {exp(-rd * T):.6f}")
Cs = simpson_price(S, K, T, vol)
print(f"call C formula {C:.6f}   Simpson {Cs:.6f}   in EUR C/S {C / S:.6f}   put P {P:.6f}")
form, bump, mc = deltas(S, K, T, vol), bumped(K), monte_carlo()
print("call deltas          formula    bump      Monte Carlo")
for i in range(4): print(f"  {names[i]:<18}{form[i]:9.6f}{bump[i]:10.6f}{mc[i]:10.4f}")
pf, pb = deltas(S, K, T, vol, -1), bumped(K, -1)
print("put deltas           formula    bump")
for i in range(4): print(f"  {names[i]:<18}{pf[i]:9.6f}{pb[i]:10.6f}")
print("hedge for a sold EUR 10,000,000 call, EUR to buy")
for i in range(4): print(f"  {names[i]:<18}{1e7 * form[i]:12.0f}")
print(f"  premium received  EUR {1e7 * C / S:.0f} = USD {1e7 * C:.0f}")
print("25-delta call strike  closed form  bisection  pips vs spot  Simpson delta")
ks = [strike_for(0.25, i) for i in range(4)]
closed = [F * exp(-vol * sqrt(T) * Ninv(0.25 / exp(-rf * T)) + 0.5 * vol * vol * T),
          F * exp(-vol * sqrt(T) * Ninv(0.25) + 0.5 * vol * vol * T)]
for i in range(4):
    cf = f"{closed[i]:11.5f}" if i < 2 else f"{'-':>11}"
    print(f"  {names[i]:<18}{cf}{ks[i]:11.5f}{(ks[i] - ks[0]) * 1e4:10.1f}{bumped(ks[i])[i]:12.6f}")
print("25-delta put strike   bisection  pips vs spot")
kp = [strike_for(-0.25, i, -1) for i in range(4)]
for i in range(4): print(f"  {names[i]:<18}{kp[i]:11.5f}{(kp[i] - kp[0]) * 1e4:10.1f}")
lo, hi = 0.0, 5.0                              # peak of pa call delta: vol sqrt(T) N(d2) = n(d2)
for _ in range(200):
    mid = 0.5 * (lo + hi)
    if vol * sqrt(T) * N(mid) - n(mid) < 0: lo = mid
    else: hi = mid
k_peak = F * exp(-mid * vol * sqrt(T) - 0.5 * vol * vol * T)
a, b = 0.5, 1.10                               # golden-section search on the pa spot delta itself
for _ in range(200):
    c1, c2 = b - 0.618034 * (b - a), a + 0.618034 * (b - a)
    if deltas(S, c1, T, vol)[2] < deltas(S, c2, T, vol)[2]: a = c1
    else: b = c2
print(f"pa call delta peak: strike {k_peak:.5f} (equation) {0.5 * (a + b):.5f} (search), delta {deltas(S, k_peak, T, vol)[2]:.6f}")
print("what breaks")
print(f"  forward delta used as spot hedge, extra EUR {1e7 * (form[1] - form[0]):.0f}")
print(f"  e^-rd T in spot delta          {exp(-rd * T) * N(d1):.6f}")
print(f"  premium subtracted in USD      {form[0] - C:.6f}")
print(f"  pa read as spot, 25d call pips {(ks[0] - ks[2]) * 1e4:.1f}")
print("at-the-money-forward strike: spot, forward, pa spot, pa forward")
for lab, t in (("1 month", 1 / 12), ("1 year", 1.0), ("5 years", 5.0)):
    ft = S * exp((rd - rf) * t)
    print(f"  {lab:<8}" + "".join(f"{x:9.4f}" for x in deltas(S, ft, t, vol)))
print(f"try: vol 20%        " + "".join(f"{x:9.4f}" for x in deltas(S, K, T, 0.20)))
grid = [0.80 + 0.05 * i for i in range(13)]
print("chart, strike    " + " ".join(f"{k:5.2f}" for k in grid))
for i, lab in ((0, "chart, spot     "), (1, "chart, forward  "), (2, "chart, pa spot  ")):
    print(lab + " " + " ".join(f"{deltas(S, k, T, vol)[i]:5.2f}" for k in grid))

assert abs(Cs - C) < 1e-10, "formula vs Simpson premium"
assert all(abs(form[i] - bump[i]) < 1e-7 for i in range(4)), "closed forms vs bump-and-reprice"
assert all(abs(form[i] - mc[i]) < 4e-3 for i in range(4)), "closed forms vs Monte Carlo"
assert all(abs(pf[i] - pb[i]) < 1e-7 for i in range(4)), "put deltas vs bump"
assert all(abs(closed[i] - ks[i]) < 1e-9 for i in range(2)), "closed-form strikes vs bisection"
assert all(abs(bumped(ks[i])[i] - 0.25) < 1e-6 for i in range(4)), "each strike really is 25 delta"
assert all(abs(bumped(kp[i], -1)[i] + 0.25) < 1e-6 for i in range(4)), "each put strike really is -25 delta"
assert abs(k_peak - 0.5 * (a + b)) < 1e-6, "peak by equation vs by search"
print("ALL CHECKS PASS")
