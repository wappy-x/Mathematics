# Bachelier -- the check behind the card.  Standard library only.  A one-year
# option on a forward interest rate quoted at 0.50 percent, struck at 0.75
# percent, with 60 basis points of normal volatility.  Rates are held in decimals
# and printed in basis points; one basis point is 0.0001.  Nothing imported knows
# the answer: the bell curve's area, the integrator, the coin-flip walk and the
# root finder are written out below.
from math import exp, log, sqrt, pi
BP = 10000.0                                      # decimals to basis points
def phi(z):    return exp(-0.5 * z * z) / sqrt(2.0 * pi)    # bell-curve height at z

def simpson(f, a, b, n):                          # the integrator, written out
    h = (b - a) / n
    total = f(a) + f(b)
    for i in range(1, n):
        total += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return total * h / 3.0

def N(x):                                         # the bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 4000)

def bach(F, K, r, sN, T, put=False):              # the formula on the card
    s, D = sN * sqrt(T), exp(-r * T)
    d = (F - K) / s
    return D * ((K - F) * N(-d) + s * phi(d)) if put else D * ((F - K) * N(d) + s * phi(d))

def by_integral(F, K, r, sN, T, put=False):       # road two: average the payoff
    s, D = sN * sqrt(T), exp(-r * T)
    d = (F - K) / s                               # the kink sits at an endpoint
    if put: return D * simpson(lambda z: max(K - F - s * z, 0.0) * phi(z), -8.0, -d, 4096)
    return D * simpson(lambda z: max(F - K + s * z, 0.0) * phi(z), -d, 8.0, 4096)

def by_walk(F, K, r, sN, T, steps):               # road three: coin flips only
    step = sN * sqrt(T / steps)                   # the same absolute move every time
    v = [max(F + step * (2 * j - steps) - K, 0.0) for j in range(steps + 1)]
    for level in range(steps, 0, -1):
        v = [0.5 * (v[j] + v[j + 1]) for j in range(level)]
    return exp(-r * T) * v[0]

def b76(F, K, r, sLN, T):                         # the lognormal cousin, for contrast
    v = sLN * sqrt(T)                             # a logarithm needs F and K above zero
    d1 = (log(F / K) + 0.5 * v * v) / v
    return exp(-r * T) * (F * N(d1) - K * N(d1 - v))

def implied_vol(price, F, K, r, T, put=False):    # bracket by doubling, then halve
    if price < exp(-r * T) * max(K - F if put else F - K, 0.0): return -1.0, 0
    lo, hi, doubles = 1.0e-12, 1.0e-4, 0
    while bach(F, K, r, hi, T, put) < price and doubles < 40: hi, doubles = hi * 2.0, doubles + 1
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if bach(F, K, r, mid, T, put) < price: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi), doubles

def show(rows):
    for label, value in rows: print(f"{label:<44}{value:>13.6f}")
def grid(label, values, places): print(f"{label:<36}" + "".join(f"{v:>8.{places}f}" for v in values))

F, K, r, sN, T = 0.0050, 0.0075, 0.0050, 0.0060, 1.0
D, s, m = exp(-r * T), sN * sqrt(T), F - K
d, bump = m / s, 1.0e-8
call, put = bach(F, K, r, sN, T), bach(F, K, r, sN, T, True)
call_int, put_int = by_integral(F, K, r, sN, T), by_integral(F, K, r, sN, T, True)
call_walk, swapped = by_walk(F, K, r, sN, T, 2000), bach(K, F, r, sN, T)
delta_c, delta_p = D * N(d), -D * N(-d)
delta_cb = (bach(F + bump, K, r, sN, T) - bach(F - bump, K, r, sN, T)) / (2.0 * bump)
delta_pb = (bach(F + bump, K, r, sN, T, True) - bach(F - bump, K, r, sN, T, True)) / (2.0 * bump)
gamma, vega = D * phi(d) / s, D * sqrt(T) * phi(d)
theta_c, theta_p = r * call - D * sN * phi(d) / (2.0 * sqrt(T)), r * put - D * sN * phi(d) / (2.0 * sqrt(T))
iv, doubles, put_floor = *implied_vol(call, F, K, r, T), D * (K - F)
under = implied_vol(put_floor - 0.0001, F, K, r, T, True)[0]
atm, atm_int = bach(F, F, r, sN, T), by_integral(F, F, r, sN, T)
zero_floor, zero_int = bach(-0.0025, 0.0, r, sN, T, True), by_integral(-0.0025, 0.0, r, sN, T, True)
show([("forward rate F, basis points", F * BP), ("strike K, basis points", K * BP),
      ("normal volatility, bp per root year", sN * BP), ("discount factor D = e^-rT", D),
      ("head start m = F - K, basis points", m * BP), ("one standard deviation s, bp", s * BP),
      ("d = m / s", d), ("N(d), the chance of exercise", N(d)),
      ("phi(d), the bell curve's height at d", phi(d)), ("head start term m N(d), bp", m * N(d) * BP),
      ("wander term s phi(d), basis points", s * phi(d) * BP),
      ("sum inside the brackets, basis points", (m * N(d) + s * phi(d)) * BP),
      ("1 call by the formula, basis points", call * BP), ("2 call by the Simpson integral, bp", call_int * BP),
      ("3 call by a 2000-step coin-flip walk, bp", call_walk * BP),
      ("4 put by the Simpson integral, bp", put_int * BP)])
print(f"  call minus put {(call - put_int) * BP:.6f} bp, D (F - K) {D * m * BP:.6f} bp")
print(f"5 call with F and K swapped {swapped * BP:.6f} bp, breakeven rate {(K + call / D) * BP:.6f} bp")
print(f"6 greeks: gamma per bp {gamma / BP:.6f}, vega per bp of vol {vega:.6f}, both shared")
print(f"  call: delta {delta_c:.6f}, bumped {delta_cb:.6f}, theta per day {theta_c * BP / 365.0:.6f} bp")
print(f"  put:  delta {delta_p:.6f}, bumped {delta_pb:.6f}, theta per day {theta_p * BP / 365.0:.6f} bp")
print(f"7 implied normal vol of the call {iv * BP:.6f} bp, {doubles} doublings then 80 halvings")
print(f"  the put's floor {put_floor * BP:.6f} bp; a quote a basis point under it has no answer")
show([("8 at-the-money call, basis points", atm * BP), ("  the same by the Simpson integral, bp", atm_int * BP),
      ("  chance the rate ends below zero", N(-F / s))])
print(f"9 zero floor on a rate at -25 bp {zero_floor * BP:.6f} bp, by integral {zero_int * BP:.6f} bp")
S0, Kh, rh, q, sig, Th = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
Fh = S0 * exp((rh - q) * Th)                      # the shelf's house market, as a forward
house_b76, sN_match = b76(Fh, Kh, rh, sig, Th), sig * Fh
house_bach, house_iv = bach(Fh, Kh, rh, sN_match, Th), implied_vol(house_b76, Fh, Kh, rh, Th)[0]
atm_b76, atm_bach = b76(Fh, Fh, rh, sig, Th), bach(Fh, Fh, rh, sN_match, Th)
gap, theory = 100.0 * (atm_bach - atm_b76) / atm_b76, 100.0 * sig * sig * Th / 24.0
print(f"10 house market: forward {Fh:.6f}, Black-76 call {house_b76:.6f} dollars")
print(f"   normal vol 20 percent x forward {sN_match:.6f} gives Bachelier {house_bach:.6f}")
print(f"   normal implied vol of the house call {house_iv:.6f} dollars per root year")
print(f"   at the money: Bachelier {atm_bach:.6f}, Black-76 {atm_b76:.6f}, gap {gap:.4f} percent, theory {theory:.4f}")
show([("   ten years: the chance of a negative share", N(-Fh / (sN_match * sqrt(10.0))))])
rates = [-50.0, -25.0, 0.0, 25.0, 50.0, 75.0, 100.0, 125.0, 150.0]
payoff, strikes = [max(x - K * BP, 0.0) for x in rates], [25.0, 50.0, 75.0, 100.0, 125.0, 150.0]
fwds = [-50.0, -25.0, 0.0, 25.0, 50.0, 75.0, 100.0]
grid("chart, rate at expiry in bp", rates, 0)
grid("chart, caplet payoff in bp", payoff, 2)
grid("chart, profit after the premium in bp", [p - call / D * BP for p in payoff], 2)
grid("chart, strike in bp", strikes, 0)
grid("chart, Bachelier call in bp", [bach(F, k / BP, r, sN, T) * BP for k in strikes], 2)
grid("chart, Black-76 at 120 percent in bp", [b76(F, k / BP, r, sN / F, T) * BP for k in strikes], 2)
grid("bars, forward rate in bp", fwds, 0)
grid("bars, zero floor worth in bp", [bach(f / BP, 0.0, r, sN, T, True) * BP for f in fwds], 2)
no_wander, certain, s4 = D * m * N(d), D * (m + s * phi(d)), sN * 4.0
area_in_slot, wrong4 = D * (m * N(d) + s * N(d)), exp(-r * 4.0) * (m * N(m / s4) + s4 * phi(m / s4))
right4, right4_int = bach(F, K, r, sN, 4.0), by_integral(F, K, r, sN, 4.0)
show([("wrong: the wander term dropped, bp", no_wander * BP), ("wrong: N(d) in the wander's slot, bp", area_in_slot * BP),
      ("wrong: exercise treated as certain, bp", certain * BP), ("wrong: sigma_N T, four-year option, bp", wrong4 * BP),
      ("  right, four-year option, bp", right4 * BP),
      ("wrong: 60 bp read as lognormal vol, bp", b76(F, K, r, sN, T) * BP),
      ("try: normal vol 120 bp, basis points", bach(F, K, r, 0.0120, T) * BP),
      ("try: normal vol 30 bp, basis points", bach(F, K, r, 0.0030, T) * BP),
      ("try: strike at 25 bp, basis points", bach(F, 0.0025, r, sN, T) * BP),
      ("try: the walk with 10 steps, bp", by_walk(F, K, r, sN, T, 10) * BP)])
assert abs(call - call_int) < 1e-12, "formula against the brute-force average"
assert abs(call_walk - call) < 5e-7, "coin-flip walk against the formula"
assert abs((call - put_int) - D * m) < 1e-12, "parity, with the put priced on its own"
assert abs(swapped - put_int) < 1e-12, "swapping F and K turns the call into the put"
assert abs(delta_cb - delta_c) < 1e-9 and abs(delta_pb - delta_p) < 1e-9, "bumped deltas against the formulas"
assert abs(right4 - right4_int) < 1e-12, "the four-year price by formula and by integral"
assert abs(iv - sN) < 1e-12, "the root finder recovers the volatility it was given"
assert under < 0.0 and no_wander < 0.0 and put_int > put_floor, "no answer below the floor; no wander term, no premium; a live option beats its floor"
assert abs(atm - atm_int) < 1e-12, "the at-the-money shortcut against the integral"
assert abs(zero_floor - put_int) < 1e-12, "only the gap F - K matters, not the level"
assert abs(house_b76 - 9.227005508154) < 1e-8, "the shelf's house call, in forward form"
assert abs(gap - theory) < 0.02, "the at-the-money gap against sigma^2 T / 24"
print("ALL CHECKS PASS")
