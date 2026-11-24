# VIX futures and options on the house flat 20% surface, 6 months out, VIX lognormal at 80% vol.
# Roads: 1 closed forms (lognormal moments, Black-76), 2 Simpson integrals over the normal density,
# 3 Monte Carlo with a home-made generator. The implied vol of VIX is solved back by bisection.
from math import exp, log, sqrt, pi, cos

R, T, TAU, OMEGA = 0.05, 0.5, 30 / 365, 0.80   # rate, years to VIX expiry, VIX window, vol of VIX
D = exp(-R * T)                                 # discount factor to the expiry

def ncdf(x):                                    # normal CDF by Marsaglia's series, no library
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, n = x, x, 1
    while abs(t) > 1e-17 * abs(s):
        n += 2; t *= x * x / n; s += t
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * pi)

def npdf(z): return exp(-0.5 * z * z) / sqrt(2 * pi)

def black76(F, K, vol, call=True, rate=R):      # Black-76 on a forward or future
    sd = vol * sqrt(T); d1 = (log(F / K) + 0.5 * sd * sd) / sd; d2 = d1 - sd
    if call: return exp(-rate * T) * (F * ncdf(d1) - K * ncdf(d2))
    return exp(-rate * T) * (K * ncdf(-d2) - F * ncdf(-d1))

def simpson(f, a, b, n):
    h, inner = (b - a) / n, 0.0
    for i in range(1, n): inner += (4 if i % 2 else 2) * f(a + i * h)
    return h / 3 * (f(a) + f(b) + inner)

# Forward variance for the 30 days after the expiry, from two variance-swap strikes (flat 20%)
K1, K2 = 0.04, 0.04                              # variance strikes to T and to T + 30 days
xi = (K2 * (T + TAU) - K1 * T) / TAU
cap = 100 * sqrt(xi)                             # the ceiling, in VIX points

def vix_at(z, om=OMEGA):                         # VIX at expiry: VIX^2 lognormal with mean cap^2
    s = 2 * om * sqrt(T)
    return sqrt(cap * cap * exp(s * z - 0.5 * s * s))

def fut_closed(om): return cap * exp(-om * om * T / 2)
def fut_simpson(om): return simpson(lambda z: vix_at(z, om) * npdf(z), -12.0, 12.0, 4000)

state = 0x9E3779B97F4A7C15                       # splitmix64, then Box-Muller: no library random
def u01():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0

F1, F2 = fut_closed(OMEGA), fut_simpson(OMEGA)
EV2 = simpson(lambda z: vix_at(z) ** 2 * npdf(z), -12.0, 12.0, 4000)
NMC = 200000; sx = sxx = sc = scc = 0.0
for i in range(NMC // 2):
    a, b = u01(), u01()
    for z in (sqrt(-2 * log(a)) * cos(2 * pi * b), sqrt(-2 * log(a)) * cos(2 * pi * b + pi / 2)):
        x = vix_at(z); c = D * max(x - F1, 0.0)
        sx += x; sxx += x * x; sc += c; scc += c * c
F3, F3se = sx / NMC, sqrt((sxx / NMC - (sx / NMC) ** 2) / NMC)
C1 = black76(F1, F1, OMEGA)
def kink(K, om=OMEGA):                           # the z at which the VIX lands exactly on K
    s = 2 * om * sqrt(T); return (2 * log(K / cap) + 0.5 * s * s) / s
C2 = D * simpson(lambda z: (vix_at(z) - F1) * npdf(z), kink(F1), 12.0, 4000)
C3, C3se = sc / NMC, sqrt((scc / NMC - (sc / NMC) ** 2) / NMC)
P1 = black76(F1, F1, OMEGA, call=False)

def implied(price, F, K):                        # bisection: Black-76 price rises with vol
    lo, hi = 0.01, 5.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if black76(F, K, mid) < price: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
iv = implied(round(C1, 4), F1, F1)
om_gap = sqrt(2 * log(cap / F2) / T)             # the vol of VIX the futures gap implies

print(f"forward variance, T to T+30d      {xi:.6f}")
print(f"ceiling 100 sqrt(xi)              {cap:.4f}")
print(f"average VIX^2 (Simpson)           {EV2:.4f}")
print(f"omega^2 T / 2                     {OMEGA * OMEGA * T / 2:.6f}")
print(f"exp(-omega^2 T / 2)               {exp(-OMEGA * OMEGA * T / 2):.6f}")
print(f"future 1 closed form              {F1:.4f}")
print(f"future 2 Simpson                  {F2:.4f}")
print(f"future 3 Monte Carlo              {F3:.4f}  (se {F3se:.4f}, {NMC} draws)")
print(f"gap below the ceiling             {cap - F1:.4f}")
sd = OMEGA * sqrt(T)
print(f"d1, d2                            {sd / 2:.6f}  {-sd / 2:.6f}")
print(f"N(d1), N(d2)                      {ncdf(sd / 2):.6f}  {ncdf(-sd / 2):.6f}")
print(f"discount factor D                 {D:.6f}")
print(f"ATM call 1 Black-76               {C1:.4f}")
print(f"ATM call 2 Simpson                {C2:.4f}")
print(f"ATM call 3 Monte Carlo            {C3:.4f}  (se {C3se:.4f})")
print(f"ATM put, Black-76                 {P1:.4f}")
print(f"implied vol of VIX from {round(C1, 4):.4f}    {iv:.4f}")
print(f"vol of VIX from the futures gap   {om_gap:.6f}")
print(f"vega of the ATM call, per point   {(black76(F1, F1, OMEGA + 0.005) - black76(F1, F1, OMEGA - 0.005)):.4f}")
print()
print("strike   call     put      call-put  D(F-K)")
for K in (15.0, 20.0, 25.0):
    c, p = black76(F1, K, OMEGA), black76(F1, K, OMEGA, call=False)
    print(f"{K:5.1f} {c:8.4f} {p:8.4f} {c - p:9.4f} {D * (F1 - K):8.4f}")
print()
print("omega  future   gap    eighth-rule gap")
grid = [0.4, 0.6, 0.8, 1.0, 1.2]
for om in grid:
    s2 = 4 * om * om * T
    print(f"{om:4.1f} {fut_closed(om):8.4f} {cap - fut_closed(om):6.4f} {cap ** 4 * (exp(s2) - 1) / (8 * cap ** 3):9.4f}")
print()
print("chart, months " + " ".join(f"{m:6d}" for m in range(7)))
print("chart, future " + " ".join(f"{cap * exp(-OMEGA ** 2 * m / 12 / 2):6.2f}" for m in range(7)))
print()
eighth = cap - cap ** 4 * (exp(4 * OMEGA * OMEGA * T) - 1) / (8 * cap ** 3)
print(f"wrong: future at the ceiling          {cap:.4f}")
print(f"wrong: eighth-rule future             {eighth:.4f}")
print(f"wrong: Black-76 on spot VIX 20        {black76(cap, F1, OMEGA):.4f}")
print(f"wrong: rate inside d1, as for a stock {F1 * ncdf((R * T + 0.5 * sd * sd) / sd) - F1 * D * ncdf((R * T - 0.5 * sd * sd) / sd):.4f}")
print(f"try: omega 1.0, ATM call              {black76(fut_closed(1.0), fut_closed(1.0), 1.0):.4f}")
print(f"try: one-year expiry, future          {cap * exp(-OMEGA * OMEGA * 1.0 / 2):.4f}")
cap2 = 100 * sqrt((0.041 * (T + TAU) - K1 * T) / TAU)   # 30 days later now struck at 0.041
print(f"try: K2 = 0.041, ceiling and future   {cap2:.4f}  {cap2 * exp(-OMEGA * OMEGA * T / 2):.4f}")

assert abs(F1 - F2) < 1e-9, "Simpson future must equal the lognormal closed form"
assert abs(F1 - F3) < 4 * F3se, "Monte Carlo future within four standard errors"
assert abs(EV2 - cap * cap) < 1e-8, "VIX^2 must average to the forward variance"
assert abs(C1 - C2) < 1e-6, "Simpson call must equal Black-76"
assert abs(C1 - C3) < 4 * C3se, "Monte Carlo call within four standard errors"
assert abs(iv - OMEGA) < 1e-4, "bisection must recover the 80% vol of VIX"
assert abs(om_gap - OMEGA) < 1e-8, "the futures gap must imply the same vol of VIX"
assert all(fut_simpson(om) < cap for om in grid), "Jensen: every future below the ceiling"
P2 = D * simpson(lambda z: (20.0 - vix_at(z)) * npdf(z), -12.0, kink(20.0), 4000)
assert abs((black76(F1, 20.0, OMEGA) - P2) - D * (F2 - 20.0)) < 1e-6, "parity: Black-76 call minus Simpson put"
assert abs(P1 - D * simpson(lambda z: (F1 - vix_at(z)) * npdf(z), -12.0, kink(F1), 4000)) < 1e-6, "Simpson put must equal the Black-76 put"
print("ALL CHECKS PASS")
