# Solving a 1-into-5 payer swaption backwards: vol from price, strike from price, strike from delta.
from math import exp, log, sqrt, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)           # bell-curve height
def N(x):                                                     # bell-curve area left of x, Simpson's rule from 0 to x
    if abs(x) > 12: return 0.0 if x < 0 else 1.0
    n, h = 400, x / 400
    s = phi(0.0) + phi(x) + sum((4 if i % 2 else 2) * phi(i * h) for i in range(1, n))
    return 0.5 + s * h / 3

r, T, L = 0.036, 1.0, 10_000_000                              # flat 3.6% curve (continuous), expiry 1 year, $10m notional
D = lambda t: exp(-r * t)
A = sum(D(t) for t in (2, 3, 4, 5, 6))                        # annuity: 1 paid at each of the five fixed dates
F = (D(1) - D(6)) / A                                         # forward swap rate
K = F                                                         # at the money

def black(sig, k=K, a=A, t=T):                                # payer swaption per unit notional, lognormal
    if sig <= 0: return a * max(F - k, 0.0)
    w = sig * sqrt(t); d1 = log(F / k) / w + 0.5 * w
    return a * (F * N(d1) - k * N(d1 - w))
def bach(sn, k=K):                                            # payer swaption per unit notional, normal
    w = sn * sqrt(T); d = (F - k) / w
    return A * ((F - k) * N(d) + w * phi(d))
def bisect(g, lo, hi):                                        # g(lo) and g(hi) of opposite signs
    glo = g(lo)
    for _ in range(100):
        mid = 0.5 * (lo + hi); gm = g(mid)
        if (gm < 0) == (glo < 0): lo, glo = mid, gm
        else: hi = mid
    return 0.5 * (lo + hi)
def newton(g, dg, x, lo, hi):                                 # Newton inside a bracket; a step that leaves it becomes the midpoint
    for _ in range(60):
        gx = g(x)
        if gx == 0: return x
        if (gx > 0) == (g(hi) > 0): hi = x
        else: lo = x
        x_new = x - gx / dg(x)
        x = x_new if lo < x_new < hi else 0.5 * (lo + hi)
    return x
def vega(s, k=K): return A * F * phi(log(F / k) / (s * sqrt(T)) + 0.5 * s * sqrt(T)) * sqrt(T)
def Ninv(p): return bisect(lambda x: N(x) - p, -10.0, 10.0)
def integral_price(rate_at, z_k, k, n=2000):                  # Simpson over z from the strike's z to 10: A * E[rate - k]
    h = (10.0 - z_k) / n; s = 0.0
    for i in range(n + 1):
        z = z_k + i * h; c = 1 if i in (0, n) else (4 if i % 2 else 2)
        s += c * phi(z) * (rate_at(z) - k)
    return A * s * h / 3
def lognormal_rate(sig): return lambda z: F * exp(-0.5 * sig * sig * T + sig * sqrt(T) * z)
def z_logn(sig, k): return (log(k / F) + 0.5 * sig * sig * T) / (sig * sqrt(T))
def normal_rate(sn): return lambda z: F + sn * sqrt(T) * z

sig0 = 0.30
P = black(sig0)                                               # the quote: 1.9% of notional
# ---- implied lognormal vol, three roads ----
guess = sqrt(2 * pi / T) * P / (A * F)                        # Brenner-Subrahmanyam first guess
v_bis = bisect(lambda s: black(s) - P, 1e-9, 5.0)
v_newt = newton(lambda s: black(s) - P, vega, guess, 1e-9, 5.0)
v_atm = 2 / sqrt(T) * Ninv((P / (A * F) + 1) / 2)             # exact at the money
P_int = integral_price(lognormal_rate(v_bis), z_logn(v_bis, K), K)
# ---- implied normal vol ----
hi = 1e-4
while bach(hi) < P: hi *= 2                                   # no ceiling: grow the bracket until it holds the quote
n_bis = bisect(lambda s: bach(s) - P, 1e-12, hi)
n_atm = P * sqrt(2 * pi) / (A * sqrt(T))                      # exact at the money
n_hagan = v_bis * F * (1 - v_bis ** 2 * T / 24)               # Hagan's expansion, leading terms
Pn_int = integral_price(normal_rate(n_bis), 0.0, K)
K2 = F + 0.01; P2 = black(sig0, K2)                           # one percent out of the money
n2_bis = bisect(lambda s: bach(s, K2) - P2, 1e-12, 0.1)
n2_hagan = sig0 * (F - K2) / log(F / K2) * (1 - sig0 ** 2 * T / 24)
v2_newt = newton(lambda s: black(s, K2) - P2, lambda s: vega(s, K2), 0.05, 1e-9, 5.0)
wild_low = 0.05 - (black(0.05, K2) - P2) / vega(0.05, K2)     # one Newton step with no bracket, from 5%
wild_high = 2.0 - (black(2.0, K2) - P2) / vega(2.0, K2)       # and from 200%
# ---- existence and its edges ----
ceiling = A * F
big_quote = 1.1 * ceiling
black_at_500 = black(5.0); v_fooled = bisect(lambda s: black(s) - big_quote, 1e-9, 5.0)
hi = 1e-4
while bach(hi) < big_quote: hi *= 2
n_big = bisect(lambda s: bach(s) - big_quote, 1e-12, hi)
# ---- strike from a target premium: 1.00% of notional ----
target = 0.01
k_bis = bisect(lambda k: black(sig0, k) - target, 1e-6, 0.5)
dPdK = lambda k: -A * N(log(F / k) / (sig0 * sqrt(T)) - 0.5 * sig0 * sqrt(T))
k_newt = newton(lambda k: black(sig0, k) - target, dPdK, F, 1e-6, 0.5)
Pk_int = integral_price(lognormal_rate(sig0), z_logn(sig0, k_bis), k_bis)
# ---- strike from delta: a 25-delta payer ----
w = sig0 * sqrt(T)
k_delta = F * exp(-w * Ninv(0.25) + 0.5 * w * w)
k_delta_bis = bisect(lambda k: N(log(F / k) / w + 0.5 * w) - 0.25, 1e-4, 0.5)
# ---- what breaks ----
v_no_annuity = bisect(lambda s: black(s, K, 1.0) - P, 1e-9, 5.0)
v_six_years = bisect(lambda s: black(s, K, A, 6.0) - P, 1e-9, 5.0)
# ---- try changing ----
P_vol20 = black(0.20)
v_quote25 = bisect(lambda s: black(s) - 0.025, 1e-9, 5.0)
k_half = bisect(lambda k: black(sig0, k) - 0.005, 1e-6, 0.5)

rows = [("D(1)", D(1)), ("D(6)", D(6)), ("annuity A", A), ("forward swap rate F", F), ("ceiling A*F", ceiling),
        ("quote P at 30%", P), ("  in dollars on $10m", P * L), ("P/(A*F)", P / (A * F)),
        ("N inverse of (1 + P/(A*F))/2", Ninv((P / (A * F) + 1) / 2)), ("vega at 30%", vega(sig0)),
        ("1 lognormal vol, bisection", v_bis), ("2 lognormal vol, guarded Newton", v_newt),
        ("3 lognormal vol, closed form at the money", v_atm), ("  first guess, Brenner-Subrahmanyam", guess),
        ("4 reprice by integral at vol 1", P_int),
        ("5 normal vol, bisection", n_bis), ("6 normal vol, closed form", n_atm),
        ("  Hagan expansion", n_hagan), ("  Hagan gap, basis points", 1e4 * (n_hagan - n_atm)), ("7 reprice by integral at vol 5", Pn_int),
        ("K2 = F + 1%", K2), ("  quote at K2", P2), ("  normal vol at K2, bisection", n2_bis),
        ("  normal vol at K2, Hagan", n2_hagan), ("  Hagan gap at K2, basis points", 1e4 * (n2_hagan - n2_bis)), ("  lognormal vol at K2, guarded Newton from 5%", v2_newt),
        ("quote 110% of ceiling", big_quote), ("  Black price at 500% vol", black_at_500), ("  bisection on (0, 500%) returns anyway", v_fooled),
        ("  normal vol for that quote", n_big),
        ("8 strike for 1.00%, bisection", k_bis), ("9 strike for 1.00%, Newton", k_newt),
        ("  reprice by integral at that strike", Pk_int),
        ("ATM delta N(d1)", N(0.5 * w)), ("N inverse of 0.25", Ninv(0.25)),
        ("10 strike for 25 delta, closed form", k_delta), ("11 strike for 25 delta, bisection", k_delta_bis),
        ("wrong: annuity left out", v_no_annuity), ("wrong: T = 6, the swap's end", v_six_years),
        ("wrong: normal vol / F, the first guess", n_bis / F),
        ("wrong: unguarded Newton step from 5%", wild_low), ("wrong: unguarded Newton step from 200%", wild_high),
        ("try: premium at 20% vol", P_vol20), ("try: vol for a 2.50% quote", v_quote25),
        ("try: strike for 0.50%", k_half)]
for name, v in rows:
    print(f"{name:<46} {v:>16.9f}")
print()
vols = [0.2 * i for i in range(11)]
print(f"{'chart, vol %':<16}" + " ".join(f"{100 * s:6.0f}" for s in vols))
print(f"{'chart, premium %':<16}" + " ".join(f"{100 * black(s):6.2f}" for s in vols))
strikes = [0.02 + 0.005 * i for i in range(9)]
print(f"{'chart, strike %':<16}" + " ".join(f"{100 * k:6.2f}" for k in strikes))
print(f"{'chart, premium %':<16}" + " ".join(f"{100 * black(sig0, k):6.2f}" for k in strikes))
print(f"chart lines, %: quote {100 * P:.2f}, ceiling {100 * ceiling:.2f}, target {100 * target:.2f}")

assert abs(F - (exp(r) - 1)) < 1e-15,            "flat curve: forward swap rate is one year of compounding, e^r - 1"
assert abs(v_bis - sig0) < 1e-10,                "bisection must return the 30% that made the quote"
assert abs(v_atm - v_newt) < 1e-9,               "closed form at the money vs guarded Newton"
assert abs(P_int - P) < 1e-9,                    "integral reprice at the solved vol vs the quote"
assert abs(n_bis - n_atm) < 1e-12 and abs(Pn_int - P) < 1e-9, "normal vol: bisection vs closed form, and integral reprice"
assert abs(n_hagan - n_atm) < 1e-6 and abs(n2_hagan - n2_bis) < 1e-6, "Hagan within 0.01 basis points, both strikes"
assert abs(v2_newt - sig0) < 1e-10,              "guarded Newton from a bad start still lands on 30%"
assert black_at_500 < big_quote,                 "no lognormal vol reaches a quote above the ceiling"
assert abs(k_bis - k_newt) < 1e-12 and abs(Pk_int - target) < 1e-9, "strike from premium: two roads and a reprice"
assert abs(k_delta - k_delta_bis) < 1e-10,       "strike from delta: closed form vs bisection"
print("ALL CHECKS PASS")
