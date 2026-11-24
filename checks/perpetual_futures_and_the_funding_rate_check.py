# Perpetual futures and the funding rate -- the check behind the card.
# Bitcoin at 60,000 USD; rate differential (dollar rate minus bitcoin yield)
# 5 percent a year; funding intensity 1,095 a year: the whole premium every
# 8 hours.  Nothing imported holds an answer: the integral, the geometric
# series, the clamp and a bisection are written out here.
from math import exp
S, DELTA, KAPPA = 60000.0, 0.05, 1095.0     # spot, rate differential, funding intensity
H = 1.0 / KAPPA                             # one funding period, in years: 8 hours here
PERP_SEEN = 60300.0                         # a perpetual trading rich
def fair(s, delta, kappa):                  # road 1: the fixed point kappa S / (kappa - delta)
    return s * kappa / (kappa - delta)
def blend_of_forwards(s, delta, kappa, n=20000):   # road 2: Simpson's rule
    upper = 60.0 / kappa                                      # weights beyond are below e^-60
    f = lambda u: kappa * exp(-kappa * u) * s * exp(delta * u)  # forward for date u, weighted
    w = upper / n
    total = f(0.0) + f(upper) + sum((4 if i % 2 else 2) * f(i * w) for i in range(1, n))
    return total * w / 3.0
def discrete(s, delta, kappa, m):           # road 3: funding m times per 8 hours, share theta each time
    h = H / m
    theta, g = kappa * h, exp(delta * h)
    return s * theta * g / (1.0 - (1.0 - theta) * g)
def series_by_terms(s, delta, kappa, m):    # road 3, term by term: weights theta (1 - theta)^(n-1)
    h = H / m
    theta, g = kappa * h, exp(delta * h)
    total, n, term = 0.0, 1, theta * g
    while term > 1e-18:
        total += term
        n += 1
        term = theta * (1.0 - theta) ** (n - 1) * g ** n
    return s * total
def clamp(x, lo, hi): return max(lo, min(hi, x))
CAP = 0.003                                 # BTCUSDT's funding cap per 8 hours, dated on the card
def exchange_rate(premium, interest=0.0001, band=0.0005, cap=1.0):   # clamped interest term, then the cap
    return clamp(premium + clamp(interest - premium, -band, band), -cap, cap)
def pinned(s, carry):                       # exchange rule, premium (F - S) / F: bisect for rate = carry
    lo, hi = -0.01, 0.01
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if exchange_rate(mid, cap=CAP) < carry: lo = mid
        else: hi = mid
    return s / (1.0 - 0.5 * (lo + hi))
def row(label, value, d=2): print(f"{label:<50}{value:>16.{d}f}")
F = fair(S, DELTA, KAPPA)
print(f"Bitcoin spot {S:.2f} USD, rate differential {DELTA * 100:.0f}% a year, intensity {KAPPA:.0f} a year")
print("fair perpetual price, three roads")
row("road 1: kappa S / (kappa - delta)", F, 6)
row("road 2: blend of forwards, Simpson", blend_of_forwards(S, DELTA, KAPPA), 6)
for m in (1, 10, 1000):
    row(f"road 3: funding {m} times per 8 hours", discrete(S, DELTA, KAPPA, m), 6)
row("road 3, term by term, 10 times per 8 hours", series_by_terms(S, DELTA, KAPPA, 10), 6)
row("an 8-hour forward, S e^(delta h)", S * exp(DELTA * H), 6)
row("multiplier kappa / (kappa - delta)", KAPPA / (KAPPA - DELTA), 9)
row("average life of the blend, 1 / kappa, in hours", 8760.0 / KAPPA, 2)
print()
print("funding at the fair price, per 1 BTC")
basis = F - S
row("basis, perpetual minus spot", basis, 2)
row("funding rate per 8 hours, basis / spot, percent", 100 * basis / S, 6)
row("funding paid per 8 hours, USD", basis * KAPPA * H, 2)
row("funding paid per year, kappa (F - S)", KAPPA * basis, 2)
row("carry on the perpetual per year, delta F", DELTA * F, 2)
print()
print(f"a perpetual trading at {PERP_SEEN:.2f}, notional 1 BTC at the index")
p = (PERP_SEEN - S) / S
row("premium, (F - S) / S, percent", 100 * p, 4)
row("funding per 8 hours, model (whole premium)", p * S, 2)
row("funding per day, three payments", 3 * p * S, 2)
row("that rate, annualised by 1095, percent", 100 * p * 1095, 2)
row("exchange rate after the interest clamp, percent", 100 * exchange_rate(p), 4)
row("exchange rate after the BTCUSDT cap, percent", 100 * exchange_rate(p, cap=CAP), 4)
row("exchange funding per 8 hours, index notional", exchange_rate(p, cap=CAP) * S, 2)
row("exchange funding per 8 hours, mark notional", exchange_rate(p, cap=CAP) * PERP_SEEN, 2)
row("exchange rate at a premium of 0.03 percent", 100 * exchange_rate(0.0003), 4)
row("interest term 0.01% per 8 hours, a year, percent", 0.01 * 1095, 2)
pin = S / (1.0 + 0.0005 - DELTA * H)        # pinned price, rule with kappa 1 per 8 hours, clamp 0.05%
row("exchange rule: pinned perp, closed form", pin, 2)
row("exchange rule: pinned perp, by bisection", pinned(S, DELTA * H), 2)
row("exchange rule: pinned basis, perp minus spot", pin - S, 2)
row("carrying 1 BTC for a day, S (e^(delta/365) - 1)", S * (exp(DELTA / 365) - 1), 2)
print()
print("what breaks")
row("sign flipped, kappa / (kappa + delta)", fair(S, -DELTA, KAPPA), 2)
row("intensity per day (3) read as per year", fair(S, DELTA, 3.0), 2)
row("priced as a one-year forward, S e^delta", S * exp(DELTA), 2)
row("carry ignored, perpetual = spot", fair(S, 0.0, KAPPA), 2)
print()
print("force one: rate differential -> basis, 8-hour funding")
for d in (-0.05, 0.0, 0.05, 0.10):
    print(f"  delta {d * 100:>4.0f}%   basis {fair(S, d, KAPPA) - S:>8.2f}")
print("force two: funding interval in hours -> basis, delta 5%")
chart = []
for hours in (1, 2, 4, 8, 12, 24):
    chart.append(fair(S, DELTA, 8760.0 / hours) - S)
    print(f"  every {hours:>2} hours   basis {chart[-1]:>8.2f}")
row("weekly funding (168 hours), basis", fair(S, DELTA, 8760.0 / 168) - S, 2)
# The asserts: each compares against a value computed another way.
assert abs(blend_of_forwards(S, DELTA, KAPPA) - F) < 1e-6          # road 2 agrees with road 1
assert abs(discrete(S, DELTA, KAPPA, 1000) - F) < 1e-3             # road 3 converges to road 1
assert abs(series_by_terms(S, DELTA, KAPPA, 10) - discrete(S, DELTA, KAPPA, 10)) < 1e-6
assert abs(discrete(S, DELTA, KAPPA, 1) - S * exp(DELTA * H)) < 1e-9  # whole premium = 8-hour forward
assert abs(KAPPA * (F - S) - DELTA * F) < 1e-6                     # funding paid equals carry
assert abs(exchange_rate(p) - 0.0045) < 1e-12                      # 0.5% minus the 0.05% clamp
assert abs(exchange_rate(p, cap=CAP) - 0.003) < 1e-12              # then the BTCUSDT cap binds
assert abs(exchange_rate(0.0003) - 0.0001) < 1e-12                 # inside the band: interest only
assert abs(pinned(S, DELTA * H) - pin) < 1e-6                      # bisection on the rule = closed form
print("ALL CHECKS PASS")
