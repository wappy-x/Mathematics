# Intrinsic and time value -- the check behind the card.  Standard library only.
# Nothing imported that already knows an option price: the bell-curve area comes
# from math.erf, and the average over the bell curve is Simpson's rule written
# out.  Acme stays at 100 throughout; the strike moves.  Five roads to the same
# numbers: the two Black-Scholes formulas, a brute-force average that never
# mentions d1 or d2, the put-call-parity identity, an exact zero-volatility
# ledger, and a model-free call-spread bound across 401 strikes.
from math import log, sqrt, exp, erf, pi

S, R, Q, SIG, T = 100.0, 0.05, 0.02, 0.20, 1.0            # the house market

def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))       # bell-curve area left of x
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x

def ds(k, s, r, q, sig, t):
    vt = sig * sqrt(t)                                    # one wiggle unit for the life
    d1 = (log(s / k) + (r - q + 0.5 * sig * sig) * t) / vt
    return d1, d1 - vt

def call(k, s=S, r=R, q=Q, sig=SIG, t=T):                 # road 1a: the call formula
    d1, d2 = ds(k, s, r, q, sig, t)
    return s * exp(-q * t) * N(d1) - k * exp(-r * t) * N(d2)

def put(k, s=S, r=R, q=Q, sig=SIG, t=T):                  # road 1b: the put formula
    d1, d2 = ds(k, s, r, q, sig, t)
    return k * exp(-r * t) * N(-d2) - s * exp(-q * t) * N(-d1)

def ic(k, s=S): return max(s - k, 0.0)                    # exercising the call now
def ip(k, s=S): return max(k - s, 0.0)                    # exercising the put now

def carry(k, s=S, r=R, q=Q, t=T):       # interest kept on K, less dividends missed on S
    return k * (1.0 - exp(-r * t)) - s * (1.0 - exp(-q * t))

def average(k, payoff, s=S, r=R, q=Q, sig=SIG, t=T, n=40000):
    a, b = -10.0, 10.0                  # road 2: Simpson's rule over the bell curve,
    h = (b - a) / n                     # borrowing nothing from the two formulas
    def f(z):
        st = s * exp((r - q - 0.5 * sig * sig) * t + sig * sqrt(t) * z)
        return payoff(st, k) * phi(z)
    tot = f(a) + f(b)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * t) * tot * h / 3.0

cpay = lambda st, k: max(st - k, 0.0)
ppay = lambda st, k: max(k - st, 0.0)
def row(name, v): print(f"{name:<40}{v:>13.6f}")
def yn(claim):    return "yes" if claim else "no"

fwd = S * exp((R - Q) * T)                                # the house forward
c100, p100 = call(100.0), put(100.0)
c130, p130 = call(130.0), put(130.0)
kd, sd = 130.0 * exp(-R * T), S * exp(-Q * T)
car130, tvp130 = carry(130.0), p130 - ip(130.0)
zpay = 130.0 - fwd                     # road 4: sigma = 0, so Acme lands on the forward
zpx = exp(-R * T) * zpay               # and the put's price is one discount, by hand
c60, tvc60 = call(60.0), call(60.0) - ic(60.0)

grid = [50.0 + 0.25 * i for i in range(401)]              # road 5: the peak, on a grid
cs, ps = [call(k) for k in grid], [put(k) for k in grid]
tvc = [cs[i] - ic(grid[i]) for i in range(401)]
tvp = [ps[i] - ip(grid[i]) for i in range(401)]
peak_c = grid[max(range(401), key=lambda i: tvc[i])]
peak_p = grid[max(range(401), key=lambda i: tvp[i])]
i100 = grid.index(100.0)
hump = (all(tvc[i] < tvc[i + 1] for i in range(i100)) and
        all(tvp[i] < tvp[i + 1] for i in range(i100)) and
        all(tvc[i] > tvc[i + 1] for i in range(i100, 400)) and
        all(tvp[i] > tvp[i + 1] for i in range(i100, 400)))
step = exp(-R * T) * 0.25              # a call spread can never be worth more than this
spread = all(-1e-12 <= cs[i] - cs[i + 1] <= step + 1e-12 for i in range(400))

STRIKES = (60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0, 140.0)
table = [(k, call(k), ic(k), call(k) - ic(k), put(k), ip(k), put(k) - ip(k)) for k in STRIKES]

print("house market: Acme S = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year")
row("1 call at K = 100, formula", c100)
row("  call at K = 100, by average", average(100.0, cpay))
row("  call intrinsic  max(S-K,0)", ic(100.0))
row("  call time value", c100 - ic(100.0))
row("  put at K = 100, formula", p100)
row("  put at K = 100, by average", average(100.0, ppay))
row("  put intrinsic  max(K-S,0)", ip(100.0))
row("  put time value", p100 - ip(100.0))
print("the 130-put: the right to sell one share for 130 in a year")
row("2 put at K = 130, formula", p130)
row("  put at K = 130, by average", average(130.0, ppay))
row("  intrinsic  max(130-100,0)", ip(130.0))
row("  time value", tvp130)
row("  K e^-rT, the strike due in a year", kd)
row("  S e^-qT, the share to deliver", sd)
row("  partner call at K = 130", c130)
row("  carry  K(1-e^-rT) - S(1-e^-qT)", car130)
row("  time value again, call - carry", c130 - car130)
row("  floor, -carry", -car130)
print("3 zero volatility: nothing random at all, sigma = 0")
row("  Acme at expiry, 100 e^(r-q)T", fwd)
row("  the 130-put pays then", zpay)
row("  its price today, e^-rT x that", zpx)
row("  time value, against 30 of intrinsic", zpx - ip(130.0))
row("  minus the carry", -car130)
print("4 the split across strikes, Acme at 100")
print(f"{'K':>5}{'call':>9}{'intr':>7}{'time val':>10}{'put':>9}{'intr':>7}{'time val':>10}")
for k, c, i_c, t_c, p, i_p, t_p in table:
    print(f"{k:>5.0f}{c:>9.2f}{i_c:>7.2f}{t_c:>10.2f}{p:>9.2f}{i_p:>7.2f}{t_p:>10.2f}")
print(f"5 time value peaks at K = {peak_c:.2f} for the call and {peak_p:.2f} for the put")
print(f"  rises to K = 100 at every step, falls after it, both: {yn(hump)}")
print(f"  call spread bound holds at all 400 steps: {yn(spread)}")
print("6 walking Acme instead of the strike, K = 100")
row("  call time value, S = 180, q = 2%", call(100.0, s=180.0) - ic(100.0, 180.0))
row("  call time value, S = 100, q = -10%", call(100.0, q=-0.10) - ic(100.0))
row("  call time value, S = 180, q = -10%", call(100.0, s=180.0, q=-0.10) - ic(100.0, 180.0))
print("7 what breaks")
row("  no floor: 130-call 'time value'", c130 - (S - 130.0))
row("  put intrinsic on the 60-call", c60 - ip(60.0))
row("  discounted intrinsic on the 60-call", exp(-R * T) * (S - 60.0))
row("  its leftover 'time value'", c60 - exp(-R * T) * (S - 60.0))
print("8 try changing")
row("  sigma = 40%: house call time value", call(100.0, sig=0.40))
row("  sigma = 40%: 130-put time value", put(130.0, sig=0.40) - 30.0)
row("  T = 4 years: 130-put time value", put(130.0, t=4.0) - 30.0)

assert abs(c100 - 9.227005508154) < 1e-9, "house call, against the shelf's number"
assert abs(p100 - 6.330080627550) < 1e-9, "house put, against the shelf's number"
assert abs(average(100.0, cpay) - c100) < 1e-7 and abs(average(100.0, ppay) - p100) < 1e-7
assert abs(average(130.0, ppay) - p130) < 1e-7, "the 130-put by average vs by formula"
assert abs(tvp130 - (c130 - car130)) < 1e-9, "subtraction vs the parity identity"
assert -car130 < tvp130 < 0.0, "the 130-put's time value: negative, above its floor"
assert abs((zpx - ip(130.0)) + car130) < 1e-9, "zero volatility: time value is minus the carry"
assert abs(zpx - (kd - sd)) < 1e-9, "the zero-volatility price is K e^-rT - S e^-qT"
assert peak_c == 100.0 and peak_p == 100.0 and hump, "both humps peak at the strike"
assert spread, "no call spread on the grid is worth more than its discounted width"
assert abs(call(100.0, s=180.0, q=-0.10) - ic(100.0, 180.0) - 23.808566) < 5e-6
assert call(100.0, s=180.0, q=-0.10) - 80.0 > call(100.0, q=-0.10), "q < 0 breaks the spot peak"
assert call(100.0, s=180.0) - 80.0 < c100, "with q = 2% the spot peak survives"
assert abs(tvc60 - (put(60.0) + carry(60.0))) < 1e-9 and 0.0 < tvc60 < c100
print("ALL CHECKS PASS")
