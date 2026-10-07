# Model risk and parameter stability -- the check behind the card.  Standard
# library only.  Two models are fitted to the same five one-year Acme calls and
# then asked for an up-and-out call.  Nothing imported knows an answer: the
# bell-curve area comes from math.erf, the knocked-out density and both
# integrals are written out here, and the volatility inversion is a bisection.
from math import log, sqrt, exp, erf, pi

def N(x):       return 0.5 * (1.0 + erf(x / sqrt(2.0)))               # bell-curve area left of x
def G(y, m, s): return exp(-0.5 * ((y - m) / s) ** 2) / (s * sqrt(2.0 * pi))

def call(S, K, r, q, sig, T):                                          # plain Black-Scholes call
    v = sig * sqrt(T)
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / v
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - v)

def uoc(S, K, H, r, q, sig, tau):
    # Road 1: up-and-out call under one volatility, in closed form.
    if S >= H: return 0.0
    a, k, nu = log(H / S), log(K / S), r - q - 0.5 * sig * sig
    s, A = sig * sqrt(tau), exp(2.0 * (r - q - 0.5 * sig * sig) * log(H / S) / (sig * sig))
    mass = lambda m: N((a - m) / s) - N((k - m) / s)                   # chance of landing in (K, H)
    share = lambda m: exp(m + 0.5 * s * s) * (N((a - m - s * s) / s) - N((k - m - s * s) / s))
    return exp(-r * tau) * (S * (share(nu * tau) - A * share(2.0 * a + nu * tau))
                            - K * (mass(nu * tau) - A * mass(2.0 * a + nu * tau)))

def killed(y, a, nu, sig, tau):
    # density of the log-move y after tau years, with every path that touched a removed
    if y >= a: return 0.0
    s = sig * sqrt(tau)
    return G(y, nu * tau, s) - exp(2.0 * nu * a / (sig * sig)) * G(y, 2.0 * a + nu * tau, s)

def simpson(f, lo, hi, n):
    h, t = (hi - lo) / n, f(lo) + f(hi)
    for i in range(1, n): t += (4.0 if i % 2 else 2.0) * f(lo + i * h)
    return t * h / 3.0

def two_step(S, K, H, r, q, s1, s2, t1, t2, n=1200):
    # Road 2: half a year of knocked-out density, then road 1 from wherever it lands
    a, nu = log(H / S), r - q - 0.5 * s1 * s1
    f = lambda y: killed(y, a, nu, s1, t1) * uoc(S * exp(y), K, H, r, q, s2, t2)
    return exp(-r * t1) * simpson(f, nu * t1 - 8.0 * s1 * sqrt(t1), a, n)

def nested(S, K, H, r, q, s1, s2, t1, t2, n=600):
    # Road 3: both halves by numerical integration, no closed form anywhere
    a, nu1, nu2 = log(H / S), r - q - 0.5 * s1 * s1, r - q - 0.5 * s2 * s2
    def inner(y):                                     # from the mid-year price, average the payoff
        S1, k2, a2 = S * exp(y), log(K / S) - y, a - y
        hi = min(a2, nu2 * t2 + 8.0 * s2 * sqrt(t2))
        if hi <= k2: return 0.0
        return simpson(lambda z: killed(z, a2, nu2, s2, t2) * (S1 * exp(z) - K), k2, hi, n)
    f = lambda y: killed(y, a, nu1, s1, t1) * inner(y)
    lo = nu1 * t1 - 8.0 * s1 * sqrt(t1)
    return exp(-r * (t1 + t2)) * simpson(f, lo, min(a, lo + 16.0 * s1 * sqrt(t1)), n)

def implied(price, S, K, r, q, T):                                     # bisection, nothing inverted
    lo, hi = 1e-4, 3.0
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        lo, hi = (lo, mid) if call(S, K, r, q, mid, T) > price else (mid, hi)
    return 0.5 * (lo + hi)

# ---- the house market: Acme at 100, strike 100, barrier 120, 5% rates, 2% dividend, one year ----
S, K, H, r, q, T, t1 = 100.0, 100.0, 120.0, 0.05, 0.02, 1.0, 0.5
strikes = [90.0, 95.0, 100.0, 105.0, 110.0]
quotes = [call(S, k, r, q, 0.20, T) for k in strikes]            # the week's five mid prices
sA = implied(quotes[2], S, K, r, q, T)                           # model A: one volatility, fitted
var = sA * sA * T                                                # the year's total variance
s1 = 0.10; s2 = sqrt(2.0 * var - s1 * s1)                        # model B: same total, split 10/26
vanB = [nested(S, k, 1000.0, r, q, s1, s2, t1, t1) for k in strikes]
uocA, uocA_n = uoc(S, K, H, r, q, sA, T), nested(S, K, H, r, q, sA, sA, t1, t1)
uocB, uocB_n = two_step(S, K, H, r, q, s1, s2, t1, t1), nested(S, K, H, r, q, s1, s2, t1, t1)

print(f"Acme S = {S:.0f}, strike K = {K:.0f}, barrier H = {H:.0f}, r = {r:.0%}, q = {q:.0%}, T = {T:.0f} year")
print(f"model A: one volatility {sA * 100:.4f}%   model B: {s1 * 100:.4f}% then {s2 * 100:.4f}%")
print(f"{'strike':>8}{'quoted call':>14}{'model A':>12}{'model B':>12}")
for k, v, b in zip(strikes, quotes, vanB):
    print(f"{k:>8.0f}{v:>14.6f}{call(S, k, r, q, sA, T):>12.6f}{b:>12.6f}")
rows = [("largest gap, model B against the quotes", f"{max(abs(b - v) for b, v in zip(vanB, quotes)):.6f}"),
        ("fitting score of both models, squared dollars", f"{sum((b - v) ** 2 for b, v in zip(vanB, quotes)):.6f}"),
        ("up-and-out call, model A, closed form", f"{uocA:.6f}"),
        ("  the same, both halves integrated", f"{uocA_n:.6f}"),
        ("up-and-out call, model B, two steps", f"{uocB:.6f}"),
        ("  the same, both halves integrated", f"{uocB_n:.6f}"),
        ("model A minus model B", f"{uocA - uocB:.6f}"),
        ("that gap as a percent of model B", f"{100.0 * (uocA - uocB) / uocB:.2f}"),
        ("barrier moved out to 1000, model A", f"{uoc(S, K, 1000.0, r, q, sA, T):.6f}"),
        ("  the plain one-year call at strike 100", f"{quotes[2]:.6f}")]
for name, v in rows: print(f"{name:<46}{v:>10}")

print("exact-fit family: first-half vol, second-half vol, one-year call, up-and-out call")
fam_x, fam = [10.0 + 2.0 * i for i in range(9)], []
for p in fam_x:
    x = p / 100.0
    y = sqrt(2.0 * var - x * x)
    fam.append(two_step(S, K, H, r, q, x, y, t1, t1))
    print(f"{p:>13.4f}{y * 100:>10.4f}{call(S, K, r, q, sqrt(0.5 * (x * x + y * y)), T):>12.6f}{fam[-1]:>12.6f}")
print(f"{'family spread, cheapest to dearest':<46}{fam[0]:.6f} to {fam[-1]:.6f}")
print(f"{'that spread as a percent of the cheapest':<46}{100.0 * (fam[-1] - fam[0]) / fam[0]:>10.2f}")
print(f"{'chart, first-half vol %':<28}" + "".join(f"{p:>7.0f}" for p in fam_x))
print(f"{'chart, up-and-out call':<28}" + "".join(f"{u:>7.2f}" for u in fam))

# ---- the week: the five one-year quotes never move, one six-month quote climbs ----
six, days = [7.68, 7.96, 8.23, 8.51, 8.73], []
sixA = call(S, K, r, q, sA, t1)
print("day  six-month quote  first-half vol  second-half vol   model A   model B  model A's miss")
for i, price in enumerate(six):
    iv = implied(price, S, K, r, q, t1)
    disc = 2.0 * var - iv * iv
    if disc > 0.0:
        days.append((iv, sqrt(disc), two_step(S, K, H, r, q, iv, sqrt(disc), t1, t1)))
        print(f"{i + 1:>3}{price:>17.2f}{iv * 100:>16.2f}{days[-1][1] * 100:>17.2f}"
              f"{uocA:>10.6f}{days[-1][2]:>10.6f}{sixA - price:>16.2f}")
    else:
        print(f"{i + 1:>3}{price:>17.2f}{iv * 100:>16.2f}{'none':>17}{uocA:>10.6f}{'none':>10}{sixA - price:>16.2f}")
print(f"{'model A own six-month call, unchanged all week':<46}{sixA:>10.6f}")
print(f"{'six-month volatility the week may not pass':<46}{sA * sqrt(2.0) * 100:>10.4f}")
print("second-half volatility the quotes leave, percent")
for i, (iv, fwd, u) in enumerate(days):
    print(f"  day {i + 1}  " + "█" * int(round(fwd * 100)) + f"  {fwd * 100:.2f}")
print("  day 5  no fit")

iv1, fwd1, u1 = days[0]
bad = 2.0 * sA - iv1                                             # volatilities subtracted, not variances
print(f"{'wrong: flat 20% barrier price on day 1':<46}{uocA:.6f} not {u1:.6f}")
print(f"{'wrong: subtracting volatilities, second half':<46}{bad * 100:>10.4f}")
print(f"{'  the one-year call it then gives at 100':<46}"
      f"{call(S, K, r, q, sqrt(0.5 * (iv1 * iv1 + bad * bad)), T):.6f} not {quotes[2]:.6f}")
print(f"{'wrong: midpoint quoted with no reserve':<46}{0.5 * (uocA + uocB):>10.6f}")

assert abs(quotes[2] - 9.227005508154) < 1e-9,            "the house market's one-year call"
assert abs(sA - 0.20) < 1e-9,                             "bisection recovers the quoted 20 percent"
assert max(abs(b - v) for b, v in zip(vanB, quotes)) < 1e-8, "model B reprices all five quotes"
assert abs(uocA - uocA_n) < 1e-6,                         "model A: closed form against integration"
assert abs(uocB - uocB_n) < 1e-6,                         "model B: two steps against integration"
assert abs(uoc(S, K, 1000.0, r, q, sA, T) - quotes[2]) < 1e-9, "a far barrier is no barrier"
assert all(fam[i + 1] > fam[i] for i in range(len(fam) - 1)), "front-loaded variance is worth more"
assert len(days) == 4,                                    "four of the five days admit a split"
assert implied(six[4], S, K, r, q, t1) > sA * sqrt(2.0),   "day 5 breaks the calendar bound"
assert abs(call(S, K, r, q, iv1, t1) - six[0]) < 1e-9,    "the inverted volatility reprices day 1"
print("ALL CHECKS PASS")
