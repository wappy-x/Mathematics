# Option price bounds -- the check behind the card.  Standard library only.  Nothing imported
# that already knows an answer: the bell-curve area is built from math.erf, the second road to
# a model price is Simpson's rule written out, and each arbitrage is checked by adding its legs
# up at every expiry price from 0 to 300 in 50-cent steps, then against a closed form.
from math import log, sqrt, exp, erf, pi

def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))       # bell-curve area left of x
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x

def bounds(S, K, r, q, T):
    share = S * exp(-q * T)            # cost today of exactly one share at T
    cash = K * exp(-r * T)             # cost today of exactly K dollars at T
    return max(share - cash, 0.0), share, max(cash - share, 0.0), cash

def bs(S, K, r, q, sigma, T):          # a MODEL price: here only something to fence in
    vt = sigma * sqrt(T)
    d1 = (log(S / K) + (r - q + 0.5 * sigma * sigma) * T) / vt
    return (S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - vt),
            K * exp(-r * T) * N(vt - d1) - S * exp(-q * T) * N(-d1))

def by_integral(S, K, r, q, sigma, T, payoff, n=40000):
    # second road to a model price: average the payoff over the bell curve (Simpson)
    a, h = -10.0, 20.0 / n
    f = lambda z: payoff(S * exp((r - q - 0.5 * sigma * sigma) * T + sigma * sqrt(T) * z)) * phi(z)
    tot = f(a) + f(-a)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * tot * h / 3.0

def trade(kind, S, K, r, q, T, v):
    # cash today, the legs added up at expiry, and the closed form that sum must equal
    share, cash = S * exp(-q * T), K * exp(-r * T)
    if kind == "call under floor":     # buy the call, short e^-qT shares, lend K e^-rT
        return -v + share - cash, lambda ST: max(ST - K, 0.0) - ST + K, lambda ST: max(K - ST, 0.0)
    if kind == "call over ceiling":    # sell the call, buy e^-qT shares
        return v - share, lambda ST: ST - max(ST - K, 0.0), lambda ST: min(ST, K)
    if kind == "put over ceiling":     # sell the put, lend K e^-rT
        return v - cash, lambda ST: K - max(K - ST, 0.0), lambda ST: min(ST, K)
    return -v - share + cash, lambda ST: max(K - ST, 0.0) + ST - K, lambda ST: max(ST - K, 0.0)

S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
K2 = 130.0                                    # a strike where the put floor bites
scan = [0.5 * i for i in range(601)]          # every expiry price from 0 to 300
cf, cc, pf, pc = bounds(S, K, r, q, T)
share, cash = cc, pc
F = S * exp((r - q) * T)
C0 = bs(S, K, r, q, sigma, T)[0]
C0i = by_integral(S, K, r, q, sigma, T, lambda ST: max(ST - K, 0.0))
P0i = by_integral(S, K, r, q, sigma, T, lambda ST: max(K - ST, 0.0))
pf2 = bounds(S, K2, r, q, T)[2]

rows, shapes_ok = [], True
for kind, tail, kk, quote in (("call under floor", " 2.896925", K, 2.50),
                              ("call over ceiling", " 98.019867", K, 99.00),
                              ("put over ceiling", " 95.122942", K, 96.00),
                              ("put under floor", " 25.639958, K = 130", K2, 25.00)):
    today, legs, shape = trade(kind, S, kk, r, q, T, quote)
    shapes_ok = shapes_ok and all(abs(legs(ST) - shape(ST)) < 1e-12 for ST in scan)
    rows.append((kind + tail, quote, today, legs, min(legs(ST) for ST in scan)))
inside_today = trade("call under floor", S, K, r, q, T, C0)[0]   # the recipe on a fair price

# a road with no model in it: any rule that discounts the average payoff, with the
# share averaging to the forward, lands inside the same fences.  Three odd spreads:
third = (F - 8.0 - 47.5) / 0.3
dist_rows, dist_ok = [], True
for name, pts in ((f"coin {70.0:.6f} or {2 * F - 70.0:.6f}", ((70.0, 0.5), (2 * F - 70.0, 0.5))),
                  (f"three points 40, 95, {third:.6f}", ((40.0, 0.2), (95.0, 0.5), (third, 0.3))),
                  (f"coin {0.0:.6f} or {2 * F:.6f}", ((0.0, 0.5), (2 * F, 0.5)))):
    mean = sum(x * p for x, p in pts)
    Cd = exp(-r * T) * sum(max(x - K, 0.0) * p for x, p in pts)
    Pd = exp(-r * T) * sum(max(K - x, 0.0) * p for x, p in pts)
    ok = abs(mean - F) < 1e-9 and cf <= Cd <= cc and pf <= Pd <= pc
    dist_ok = dist_ok and ok
    dist_rows.append((name, mean, Cd, Pd, "yes" if ok else "no"))

C_lo, P_lo = bs(S, K, r, q, 1e-4, T)          # a model squeezed against the floors
C_hi, P_hi = bs(S, K, r, q, 50.0, T)          # and against the ceilings
cf_nodisc = max(share - K, 0.0)               # the strike left undiscounted
cf_nodrag = max(S - cash, 0.0)                # the share left without its dividend drag
C_5 = bs(S, K, r, q, 0.05, T)[0]              # a fair price sitting under that false floor
false_today = -C_5 + S - cash                 # shorting one whole share, not e^-qT of one
false_110 = max(110.0 - K, 0.0) - exp(q * T) * 110.0 + K
P130i = by_integral(S, K2, r, q, sigma, T, lambda ST: max(K2 - ST, 0.0))
cf_q3 = bounds(S, K, r, 0.03, T)[0]

def row(name, v): print(f"{name:<48}{v:>12.6f}")
for name, v in (("discount factor  e^-rT", exp(-r * T)), ("dividend drag    e^-qT", exp(-q * T)),
                ("share side  S e^-qT", share), ("cash side   K e^-rT", cash),
                ("forward     S e^(r-q)T", F), ("call floor  max(share - cash, 0)", cf),
                ("call ceiling = the share side", cc), ("put floor   max(cash - share, 0)", pf),
                ("put ceiling = the cash side", pc), ("model call at 20% vol, formula", C0),
                ("model call at 20% vol, Simpson integral", C0i), ("model put at 20% vol, Simpson integral", P0i),
                ("C - P from those two model prices", C0 - P0i)):
    row(name, v)
print("\nthe four trades: cash today, then the legs added up at expiry")
cols = (80.0, 100.0, 120.0, 160.0)
print(f"{'trade':<36}{'quote':>7}{'today':>10}" + "".join(f"{'S_T=' + str(int(c)):>9}" for c in cols) + f"{'worst':>8}")
for name, quote, today, legs, worst in rows:
    print(f"{name:<36}{quote:>7.2f}{today:>10.6f}" + "".join(f"{legs(c):>9.2f}" for c in cols) + f"{worst:>8.2f}")
row("the same recipe on the fair call: cash today", inside_today)
print(f"\nthree spreads of expiry prices averaging to the forward {F:.6f}")
print(f"{'spread of expiry prices':<36}{'mean':>12}{'call':>11}{'put':>11}{'inside':>8}")
for name, mean, Cd, Pd, ok in dist_rows:
    print(f"{name:<36}{mean:>12.6f}{Cd:>11.6f}{Pd:>11.6f}{ok:>8}")
print()
for name, v in (("model call at 0.01% vol, against the floor", C_lo), ("model call at 5000% vol, against the ceiling", C_hi),
                ("model put at 0.01% vol, against the floor", P_lo), ("model put at 5000% vol, against the ceiling", P_hi)):
    row(name, v)
print()
for name, v in (("wrong: strike not discounted, call floor", cf_nodisc), ("wrong: share not dividend-dragged, call floor", cf_nodrag),
                ("  a fair 5%-vol call, under that false floor", C_5), ("  the false trade: cash today", false_today),
                ("  the false trade at expiry, share at 110", false_110), ("wrong: max(., 0) dropped, put floor", cash - share),
                ("wrong: intrinsic K - S as the put floor, K = 130", K2 - S), ("  the K = 130 cash side K e^-rT", K2 * exp(-r * T)),
                ("  the true K = 130 put floor", pf2), ("  the model K = 130 put, under intrinsic", P130i),
                ("call floor if the dividend yield were 3%", cf_q3)):
    row(name, v)
spots = [60.0 + 10.0 * i for i in range(9)]
print(f"\n{'chart, share price S':<30}" + "".join(f"{s:>7.0f}" for s in spots))
for name, f in (("chart, call ceiling", lambda s: bounds(s, K, r, q, T)[1]),
                ("chart, call floor", lambda s: bounds(s, K, r, q, T)[0]),
                ("chart, model call at 20% vol", lambda s: bs(s, K, r, q, sigma, T)[0]),
                ("chart, put ceiling", lambda s: bounds(s, K, r, q, T)[3]),
                ("chart, put floor", lambda s: bounds(s, K, r, q, T)[2]),
                ("chart, model put at 20% vol", lambda s: bs(s, K, r, q, sigma, T)[1])):
    print(f"{name:<30}" + "".join(f"{f(s):>7.2f}" for s in spots))

assert abs(C0 - 9.227005508154) < 1e-9, "the model call lands on the house number"
assert abs(C0i - C0) < 1e-7, "Simpson integral against the formula: two roads to one price"
assert abs(cf - (C0 - P0i)) < 1e-6, "the call floor equals C - P of two separately priced options"
assert shapes_ok, "every trade's legs add up to its closed form at every expiry price"
assert all(t[2] > 0 for t in rows), "each broken quote pays cash today"
assert all(t[4] >= -1e-12 for t in rows), "no trade ever loses at expiry"
assert inside_today < 0, "the same recipe on a fair price costs money to enter"
assert dist_ok, "three model-free spreads land inside the fences"
assert abs(C_lo - cf) < 1e-6 and abs(P_lo - pf) < 1e-6, "a vanishing vol lands the model on both floors"
assert abs(C_hi - cc) < 1e-6 and abs(P_hi - pc) < 1e-6, "a huge vol lands the model on both ceilings"
assert C_5 > cf and C_5 < cf_nodrag, "a fair price can sit under the false floor"
assert false_110 < 0, "the trade the false floor invites loses money at expiry"
assert P130i < K2 - S and P130i > pf2, "a European put may sit under intrinsic, never under its floor"
print("ALL CHECKS PASS")
