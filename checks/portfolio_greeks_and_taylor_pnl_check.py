# Portfolio Greeks and a day's explained P&L -- the check behind the card.  Standard library only.
# N(x) is a power series written out here.  Price road 2 averages the payoff over the bell curve
# (Simpson's rule); Greek road 2 bumps the whole book; road 3 walks the day in small re-Greeked steps.
from math import log, sqrt, exp, pi

r, q, S0, SIG0 = 0.05, 0.02, 100.0, 0.20              # house market: rate, dividend yield, Acme, vol

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height

def N(x):                                              # bell-curve area left of x, by series
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total

def d1d2(S, K, sig, T):
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return d1, d1 - sig * sqrt(T)

def option(S, K, sig, T, cp):                          # Black-Scholes, cp = +1 call, -1 put
    d1, d2 = d1d2(S, K, sig, T)
    return cp * (S * exp(-q * T) * N(cp * d1) - K * exp(-r * T) * N(cp * d2))

def option_integral(S, K, sig, T, cp, n=4000):         # road 2: discounted average payoff
    m, v = (r - q - 0.5 * sig * sig) * T, sig * sqrt(T)
    zk = (log(K / S) - m) / v                          # where the payoff's kink sits
    lo, hi = (zk, 10.0) if cp > 0 else (-10.0, zk)
    h = (hi - lo) / n
    f = lambda z: cp * (S * exp(m + v * z) - K) * phi(z)
    s = f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return exp(-r * T) * s * h / 3.0

def unit_greeks(K, sig, T, cp, S):                     # closed forms: delta gamma vega theta vanna volga
    if cp == 0:                                        # a future: its price is F = S e^{(r-q)T}
        F = S * exp((r - q) * T)
        return [F / S, 0.0, 0.0, -(r - q) * F, 0.0, 0.0]
    d1, d2 = d1d2(S, K, sig, T)
    eq, er, rt = exp(-q * T), exp(-r * T), sqrt(T)
    vega = S * eq * phi(d1) * rt
    theta = -S * eq * phi(d1) * sig / (2 * rt) - cp * r * K * er * N(cp * d2) + cp * q * S * eq * N(cp * d1)
    return [cp * eq * N(cp * d1), eq * phi(d1) / (S * sig * rt), vega, theta,
            -eq * phi(d1) * d2 / sig, vega * d1 * d2 / sig]

# the book: label, signed quantity (in shares' worth), strike, years left, +1 call / -1 put / 0 future
BOOK = [("A long call K100 1y", 75000, 100.0, 1.0, 1), ("B short put K90 3m", -130000, 90.0, 0.25, -1),
        ("C long call K110 6m", 50000, 110.0, 0.5, 1), ("D short future 3m", -74200, 0.0, 0.25, 0)]
F0 = S0 * exp((r - q) * 0.25)                          # tonight's futures price

def mark(p, S, sig, t, road=option):                   # one position's value once t years have passed
    _, n, K, T, cp = p
    return n * (S * exp((r - q) * (T - t)) - F0) if cp == 0 else n * road(S, K, sig, T - t, cp)

def book(S, sig, t, road=option): return sum(mark(p, S, sig, t, road) for p in BOOK)

def book_greeks(S, sig, t):                            # road 1: signed sum of closed-form Greeks
    return [sum(p[1] * u for p in BOOK for u in [unit_greeks(p[2], sig, p[3] - t, p[4], S)[i]]) for i in range(6)]

def bumped(f, hs=0.01, hv=1e-4, ht=1e-5, hw=1e-3):              # road 2: nudge the whole book's inputs, reprice
    return [(f(S0 + hs, SIG0, 0) - f(S0 - hs, SIG0, 0)) / (2 * hs),
            (f(S0 + hs, SIG0, 0) - 2 * f(S0, SIG0, 0) + f(S0 - hs, SIG0, 0)) / hs ** 2,
            (f(S0, SIG0 + hv, 0) - f(S0, SIG0 - hv, 0)) / (2 * hv),
            (f(S0, SIG0, ht) - f(S0, SIG0, -ht)) / (2 * ht),
            (f(S0 + hs, SIG0 + hv, 0) - f(S0 + hs, SIG0 - hv, 0) - f(S0 - hs, SIG0 + hv, 0)
             + f(S0 - hs, SIG0 - hv, 0)) / (4 * hs * hv),
            (-f(S0, SIG0 + 2 * hw, 0) + 16 * f(S0, SIG0 + hw, 0) - 30 * f(S0, SIG0, 0)     # volga: five-point,
             + 16 * f(S0, SIG0 - hw, 0) - f(S0, SIG0 - 2 * hw, 0)) / (12 * hw * hw)]          # steadier to round-off

def terms(g, dS, dv, dt):                              # the Taylor pieces, in the card's order
    return [g[0] * dS, 0.5 * g[1] * dS * dS, g[2] * dv, g[3] * dt, g[4] * dS * dv, 0.5 * g[5] * dv * dv]

unit = [unit_greeks(p[2], SIG0, p[3], p[4], S0) for p in BOOK]
posg = [[p[1] * x + 0.0 for x in u] for p, u in zip(BOOK, unit)]
closed, bump = book_greeks(S0, SIG0, 0.0), bumped(book)
print("position             quantity  unit price     delta     gamma      vega     theta     vanna     volga")
for p, u in zip(BOOK, unit):
    price = F0 if p[4] == 0 else option(S0, p[2], SIG0, p[3], p[4])
    print(f"{p[0]:<20}{p[1]:>9}{price:>12.6f}" + "".join(f"{x:>10.6f}" for x in u))
print("position Greeks, quantity x unit")
for p, g in zip(BOOK, posg):
    print(f"{p[0]:<20}" + "".join(f"{x:>12.2f}" for x in g))
print(f"{'book, summed':<20}" + "".join(f"{x:>12.2f}" for x in closed))
print(f"{'book, by bumping':<20}" + "".join(f"{x:>12.2f}" for x in bump))
print(f"vega per vol point; delta before future {closed[2] / 100:.2f}  {sum(g[0] for g in posg[:3]):.2f}")

dS, dv, dt = 5.0, 0.01, 1.0 / 365.0
tc, tb = terms(closed, dS, dv, dt), terms(bump, dS, dv, dt)
print("the day: Acme +5, vol +1 point, one day: term by summed Greeks, by bumped Greeks")
for nm, a, b in zip(["delta", "gamma", "vega", "theta", "vanna", "volga"], tc, tb):
    print(f"  {nm:<10}{a:>14.2f}{b:>14.2f}")
explained, explained_b = sum(tc), sum(tb)
actual = book(S0 + dS, SIG0 + dv, dt) - book(S0, SIG0, 0)
actual_i = book(S0 + dS, SIG0 + dv, dt, option_integral) - book(S0, SIG0, 0, option_integral)
print(f"explained: summed, bumped               {explained:.2f}  {explained_b:.2f}")
print(f"actual: reprice by formula, by integral {actual:.2f}  {actual_i:.2f}")
print(f"unexplained; explained share of actual  {actual - explained:.2f}  {explained / actual:.4f}")
print("by position: unexplained, explained, actual")
res_pos = []
for p, g in zip(BOOK, posg):
    e, a = sum(terms(g, dS, dv, dt)), mark(p, S0 + dS, SIG0 + dv, dt) - mark(p, S0, SIG0, 0)
    res_pos.append(a - e)
    print(f"  {p[0]:<20}{a - e:>12.2f}{e:>12.2f}{a:>12.2f}")

steps, walked = 20, 0.0                                # road 3: re-take the Greeks at each small step
for j in range(steps):
    k = j / steps
    walked += sum(terms(book_greeks(S0 + k * dS, SIG0 + k * dv, k * dt), dS / steps, dv / steps, dt / steps))
g = lambda k: book(S0 + k * dS, SIG0 + k * dv, k * dt)  # the book along the day's straight path
hk = 0.05
g3 = (g(2 * hk) - 2 * g(hk) + 2 * g(-hk) - g(-2 * hk)) / (2 * hk ** 3)
g4 = (g(2 * hk) - 4 * g(hk) + 6 * g(0) - 4 * g(-hk) + g(-2 * hk)) / hk ** 4
res_half = (g(0.5) - g(0)) - sum(terms(closed, dS / 2, dv / 2, dt / 2))
print(f"walked in 20 re-Greeked steps           {walked:.2f}")
print(f"third-order, fourth-order pieces        {g3 / 6:.2f}  {g4 / 24:.2f}")
print(f"unexplained at half the move; ratio     {res_half:.2f}  {(actual - explained) / res_half:.4f}")
print(f"wrong: future's delta taken as 1        {explained + BOOK[3][1] * (1.0 - unit[3][0]) * dS:.2f}")
print(f"wrong: short put entered as long        {explained - 2 * sum(terms(posg[1], dS, dv, dt)):.2f}")
print(f"wrong: contracts, not shares            {explained / 100:.2f}")
print(f"wrong: delta term only                  {tc[0]:.2f}")
for lab, a, b in (("try: Acme -5, vol +1", -5.0, 0.01), ("try: Acme +5, vol 0", 5.0, 0.0),
                  ("try: Acme +2, vol +1", 2.0, 0.01)):
    print(f"{lab:<24}explained {sum(terms(closed, a, b, dt)):>10.2f}  actual {book(S0 + a, SIG0 + b, dt) - book(S0, SIG0, 0):>10.2f}")
moves = [-10, -7.5, -5, -2.5, 0, 2.5, 5, 7.5, 10]
print("chart, Acme move ($)" + "".join(f"{m:>7}" for m in moves) + "   ($ thousands)")
for lab, fn in (("actual", lambda m: book(S0 + m, SIG0 + dv, dt) - book(S0, SIG0, 0)),
                ("explained", lambda m: sum(terms(closed, m, dv, dt))), ("delta only", lambda m: closed[0] * m)):
    print(f"chart, {lab:<13}" + "".join(f"{fn(m) / 1000:>7.2f}" for m in moves))

scale = [sum(abs(g[i]) for g in posg) for i in range(6)]
assert all(abs(a - b) <= 1e-6 * s for a, b, s in zip(closed, bump, scale)), "summed Greeks != bumped book"
assert abs(explained - explained_b) < 1.0, "explained P&L differs between Greek roads"
assert abs(actual - actual_i) < 0.05, "full reprice differs between price roads"
assert abs(walked - actual_i) < 0.005 * abs(actual_i), "re-Greeked walk does not reach the actual P&L"
assert 6.0 < (actual - explained) / res_half < 10.0, "leftover does not shrink like the cube"
assert abs(option(S0, 100.0, SIG0, 1.0, 1) - 9.227005508154) < 1e-9 and abs(option(S0, 100.0, SIG0, 1.0, -1) - 6.330080627550) < 1e-9, "house prices"
print("ALL CHECKS PASS")
