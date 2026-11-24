# Leland's volatility -- the check behind the card.  Python standard library only.
# House call: Acme $100, strike $100, 1 year, rates 5%, dividends 2%, volatility 20%.
# A round trip (buy, then sell back) costs K_RT = 0.2% of the value traded; one trade costs half.
# Road 1: Leland's closed form.  Road 2: E|Z| by Simpson's rule, and the day's cost over the
# day's gamma rent.  Road 3: hedge 10,000 simulated years and count the money.
# Inverse: the hedging interval for a target mark, in closed form and by bisection.
# The bell-curve area uses math.erf; the random numbers are splitmix64 and Box-Muller.
from math import erf, exp, log, sqrt, pi, cos

S0, K, T, R, Q, SIG, K_RT, DAY = 100.0, 100.0, 1.0, 0.05, 0.02, 0.20, 0.002, 1.0 / 252

def ncdf(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def call(s, k, t, r, q, v):                       # Black-Scholes price and delta
    if t <= 0.0: return max(s - k, 0.0), (1.0 if s > k else 0.0)
    d1 = (log(s / k) + (r - q + 0.5 * v * v) * t) / (v * sqrt(t))
    d2 = d1 - v * sqrt(t)
    return s * exp(-q * t) * ncdf(d1) - k * exp(-r * t) * ncdf(d2), exp(-q * t) * ncdf(d1)
def price(v): return call(S0, K, T, R, Q, v)[0]
def leland(dt): return sqrt(2.0 / pi) * K_RT / (SIG * sqrt(dt))
def marks(dt): le = leland(dt); return SIG * sqrt(1.0 + le), SIG * sqrt(max(1.0 - le, 0.0))

# ---- road 1: the closed form ----
le = leland(DAY); vs, vl = marks(DAY); mid, cs, cl = price(SIG), price(vs), price(vl)
print(f"Leland number, daily: sqrt(2/pi) x {K_RT} / ({SIG} x sqrt(1/252)) = {le:.5f}")
print(f"short mark: 20% x sqrt(1 + Le) = {100 * vs:.4f}%, price {cs:.4f}")
print(f"long mark:  20% x sqrt(1 - Le) = {100 * vl:.4f}%, price {cl:.4f}")
print(f"mid price at 20%: {mid:.4f}; markup {cs - mid:.4f}, markdown {mid - cl:.4f}, gap {cs - cl:.4f}")
print(f"volatility gap: up {100 * (vs - SIG):.4f} points, down {100 * (SIG - vl):.4f} points")

# ---- road 2: E|Z| by Simpson, and one day's cost against one day's gamma rent ----
n, h = 20000, 10.0 / 20000
ez = 2.0 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * (i * h) * exp(-0.5 * (i * h) ** 2)
               for i in range(n + 1)) * h / 3.0 / sqrt(2.0 * pi)
g = (call(S0 + 0.01, K, T, R, Q, SIG)[1] - call(S0 - 0.01, K, T, R, Q, SIG)[1]) / 0.02
move = ez * SIG * S0 * sqrt(DAY)                   # expected size of a day's move, dollars
cost = 0.5 * K_RT * S0 * g * move                  # one-way cost x shares traded x price
rent = 0.5 * g * S0 * S0 * SIG * SIG * DAY         # the gamma rent theta pays per day
vega = (price(SIG + 0.0001) - price(SIG - 0.0001)) / 0.0002 / 100.0
print(f"E|Z| by Simpson: {ez:.6f}; sqrt(2/pi) = {sqrt(2 / pi):.6f}")
print(f"gamma {g:.6f}; typical daily move ${SIG * S0 * sqrt(DAY):.4f}, average size ${move:.5f}; "
      f"shares traded {g * move:.6f}")
print(f"expected cost per day ${cost:.6f}; gamma rent per day ${rent:.6f}; ratio {cost / rent:.5f}")
print(f"vega per point {vega:.6f}; vega x (21.2289 - 20) = {vega * 100 * (vs - SIG):.4f}")
assert abs(ez - sqrt(2.0 / pi)) < 1e-9, "Simpson against the closed form of E|Z|"
d1 = (log(S0 / K) + (R - Q + 0.5 * SIG * SIG) * T) / (SIG * sqrt(T))
assert abs(g - exp(-Q * T - 0.5 * d1 * d1) / sqrt(2.0 * pi) / (S0 * SIG * sqrt(T))) < 1e-7, "gamma, closed form"
assert abs(cost / rent - le) < 1e-6, "the day's cost over the day's rent is the Leland number"
assert abs(vega * 100 * (vs - SIG) / (cs - mid) - 1.0) < 0.01, "markup is about vega x vol gap"
assert (round(le, 5), round(100 * vs, 2), round(100 * vl, 2)) == (0.12666, 21.23, 18.69)
assert (round(cs, 3), round(cl, 3), round(mid, 3)) == (9.693, 8.731, 9.227)

# ---- road 3: hedge simulated years.  Shares follow the risk-neutral drift r - q. ----
state = 0x2545F4914F6CDD1D
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def stats(xs):
    m = sum(xs) / len(xs); sd = sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))
    return m, sd, sd / sqrt(len(xs))
def simulate(days, paths):
    dt = days * DAY; steps = round(T / dt); hs, hl = marks(dt)
    bills, sbills, shorts, longs = [], [], [], []
    for _ in range(paths):
        s, t = S0, T
        a, b, c = call(s, K, t, R, Q, SIG)[1], call(s, K, t, R, Q, hs)[1], call(s, K, t, R, Q, hl)[1]
        bill, sbill, cash_s, cash_l = 0.0, 0.0, price(hs) - b * s, -price(hl) + c * s
        for i in range(1, steps + 1):
            u1, u2 = unif(), unif()
            z = sqrt(-2.0 * log(1.0 - u1)) * cos(2.0 * pi * u2)
            s *= exp((R - Q - 0.5 * SIG * SIG) * dt + SIG * sqrt(dt) * z); t = T - i * dt
            cash_s = cash_s * exp(R * dt) + b * s * (exp(Q * dt) - 1.0)
            cash_l = cash_l * exp(R * dt) - c * s * (exp(Q * dt) - 1.0)
            if i == steps: break                    # expiry: the call settles in shares
            a2, b2, c2 = call(s, K, t, R, Q, SIG)[1], call(s, K, t, R, Q, hs)[1], call(s, K, t, R, Q, hl)[1]
            bill += 0.5 * K_RT * abs(a2 - a) * s * exp(-R * i * dt)
            sbill += 0.5 * K_RT * abs(b2 - b) * s * exp(-R * i * dt)
            cash_s -= (b2 - b) * s + 0.5 * K_RT * abs(b2 - b) * s
            cash_l += (c2 - c) * s - 0.5 * K_RT * abs(c2 - c) * s
            a, b, c = a2, b2, c2
        pay = max(s - K, 0.0)
        bills.append(bill); sbills.append(sbill)
        shorts.append((cash_s + b * s - pay) * exp(-R * T))
        longs.append((cash_l - c * s + pay) * exp(-R * T))
    return stats(bills), stats(shorts), stats(longs), stats(sbills)

bill, short, long_, sbill = simulate(1, 10000)
print("10,000 simulated years, hedged daily (mean, spread, standard error):")
print(f"  bill, hedging at 20%:            {bill[0]:.4f} {bill[1]:.4f} {bill[2]:.4f} vs markup {cs - mid:.4f}")
print(f"  bill, hedging at 21.23%:         {sbill[0]:.4f} {sbill[1]:.4f} {sbill[2]:.4f} vs markup {cs - mid:.4f}")
print(f"  seller at 21.23%, hedging there: {short[0]:.4f} {short[1]:.4f} {short[2]:.4f}")
print(f"  buyer at 18.69%, hedging there:  {long_[0]:.4f} {long_[1]:.4f} {long_[2]:.4f}")
assert abs(bill[0] / (cs - mid) - 1.0) < 0.08, "simulated bill against Leland's markup"
assert abs(short[0]) < 4 * short[2] + 0.01, "the seller's markup pays the bill on average"
assert abs(long_[0]) < 4 * long_[2] + 0.01, "the buyer's markdown pays the bill on average"
assert abs(sbill[0] / (cs - mid) - 1.0) < 0.015, "hedging at 21.23%, the seller's own bill is the markup"

print("interval trade-off (days, Le, short mark %, markup, simulated bill, seller spread):")
for d in (1, 2, 3, 6, 12, 21):
    vsd = marks(d * DAY)[0]; bd, sd_, _, _ = simulate(d, 4000)
    print(f"  {d:2d}  {leland(d * DAY):.5f}  {100 * vsd:.4f}  {price(vsd) - mid:.4f}  {bd[0]:.4f}  {sd_[1]:.4f}")

# ---- the inverse: the most frequent hedging that keeps the short mark within 21% ----
target = 0.21; le_t = (target / SIG) ** 2 - 1.0
dt_closed = (sqrt(2.0 / pi) * K_RT / (SIG * le_t)) ** 2
want, lo, hi = price(target) - mid, 0.01 * DAY, 100.0 * DAY
for _ in range(200):                               # bisection on the price markup
    m = 0.5 * (lo + hi)
    lo, hi = (m, hi) if price(marks(m)[0]) - mid > want else (lo, m)
print(f"target 21%: Le = {le_t:.6f}; interval {dt_closed / DAY:.5f} days by formula, "
      f"{lo / DAY:.5f} by bisection on the markup {want:.4f}")
print(f"every 2 days: Le {leland(2 * DAY):.5f}, mark {100 * marks(2 * DAY)[0]:.4f}%")
dt_zero = (sqrt(2.0 / pi) * K_RT / SIG) ** 2
print(f"long mark hits zero at Le = 1: interval {dt_zero / DAY:.6f} days = {dt_zero / DAY * 390:.2f} minutes")
assert abs(dt_closed - lo) < 1e-9, "closed-form interval against bisection"
assert abs(marks(dt_closed)[0] - target) < 1e-12, "the interval reproduces the target"

# ---- what breaks if you drop a piece ----
def mark(le_): return SIG * sqrt(1.0 + le_)
for label, v in (("calendar days, dt = 1/365", mark(sqrt(2 / pi) * K_RT / (SIG * sqrt(1 / 365)))),
                 ("Le on the vol, not the variance", SIG * (1.0 + le)),
                 ("drop sqrt(2/pi)", mark(K_RT / (SIG * sqrt(DAY))))):
    print(f"wrong: {label}: mark {100 * v:.4f}%, price {price(v):.4f}")
print(f"wrong: long call marked up too: buyer pays {cs:.4f}, overpays {cs - cl:.4f}")

print("chart, interval in days -> short and long mark (%):")
for d in (0.25, 0.5, 1, 2, 5, 10, 21):
    u, w = marks(d * DAY); print(f"  {d:5.2f}  {100 * u:.2f}  {100 * w:.2f}")
print("ALL CHECKS PASS")
