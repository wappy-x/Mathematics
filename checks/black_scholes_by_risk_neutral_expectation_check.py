# Black-Scholes by expectation -- the check behind the card.  Standard library
# only, and nothing imported that already knows the answer: the bell-curve area
# is built from math.erf, the average over finishing prices is Simpson's rule
# written out in price space, and the random draws are a generator plus a
# Box-Muller pair written here.  Every number quoted on the card is printed.
from math import log, sqrt, exp, erf, pi, cos, sin

S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
D = exp(-R * T)                    # discount factor, e^-rT
A = S * exp(-Q * T)                # prepaid share: one share at T, paid for today
MU_Q = R - Q                       # price growth under the pricing measure
MU_P = 0.06                        # an 8% real-world return, less the 2% dividend
TOP = 600.0                        # far above any finishing price that matters

def bell_area(x):                  # N(x): bell-curve area to the left of x
    return 0.5 * (1.0 + erf(x / sqrt(2.0)))

def d_pair(s, k, r, q, sig, t):    # the two distances, in wiggle units
    vt = sig * sqrt(t)
    d1 = (log(s / k) + (r - q + 0.5 * sig * sig) * t) / vt
    return d1, d1 - vt

def closed_form(s, k, r, q, sig, t):                      # road 1
    d1, d2 = d_pair(s, k, r, q, sig, t)
    return s * exp(-q * t) * bell_area(d1) - k * exp(-r * t) * bell_area(d2)

def density(x, mu=MU_Q):           # chance per dollar of finishing at price x
    centre = log(S) + (mu - 0.5 * SIG * SIG) * T
    spread = SIG * sqrt(T)
    return exp(-0.5 * ((log(x) - centre) / spread) ** 2) / (x * spread * sqrt(2.0 * pi))

def simpson(f, lo, hi, n):         # Simpson's rule, written out
    h = (hi - lo) / n
    total = f(lo) + f(hi)
    for i in range(1, n):
        total += (4 if i % 2 else 2) * f(lo + i * h)
    return total * h / 3.0

def average(payoff, lo, hi, mu=MU_Q, n=20000):            # road 2: average over prices
    return D * simpson(lambda x: payoff(x) * density(x, mu), lo, hi, n)

def draws(n, seed=20260919):       # road 3's random numbers, written here
    state, out = seed, []
    while len(out) < n:
        two = []
        for _ in range(2):
            state = (state * 6364136223846793005 + 1442695040888963407) % (1 << 64)
            two.append(((state >> 11) + 0.5) / float(1 << 53))
        radius = sqrt(-2.0 * log(two[0]))
        out.append(radius * cos(2.0 * pi * two[1]))
        out.append(radius * sin(2.0 * pi * two[1]))
    return out[:n]

def monte_carlo(n):                # road 3: draw finishing prices, average the payoff
    total = total_sq = total_end = 0.0
    for z in draws(n):
        end = S * exp((MU_Q - 0.5 * SIG * SIG) * T + SIG * sqrt(T) * z)
        paid = D * max(end - K, 0.0)
        total += paid
        total_sq += paid * paid
        total_end += D * end
    mean = total / n
    return mean, sqrt(max(total_sq / n - mean * mean, 0.0) / n), total_end / n

d1, d2 = d_pair(S, K, R, Q, SIG, T)
mode = S * exp((MU_Q - 1.5 * SIG * SIG) * T)              # where the weights peak
call = closed_form(S, K, R, Q, SIG, T)
share_term, cash_term = A * bell_area(d1), K * D * bell_area(d2)
call_int = average(lambda x: max(x - K, 0.0), K, TOP)     # the same average, road 2
share_int = average(lambda x: x, K, TOP)                  # share leg, without d1
cash_int = average(lambda x: K, K, TOP)                   # cash leg, without d2
mean_end = average(lambda x: x, 0.01, TOP)                # discounted average finish
put_int = average(lambda x: max(K - x, 0.0), 0.01, K)     # the put, priced on its own
mc, mc_err, mc_end = monte_carlo(200000)
wrong_real = average(lambda x: max(x - K, 0.0), K, TOP, mu=MU_P)
wrong_jensen = D * max(mean_end / D - K, 0.0)             # payoff of the average price
wrong_swap = A * bell_area(d2) - K * D * bell_area(d1)    # the two weights swapped
cut_at_120 = average(lambda x: max(x - K, 0.0), K, 120.0)
mc_small, mc_small_err, _ = monte_carlo(2000)
vol_40 = closed_form(S, K, R, Q, 0.40, T)

rows = [
    ("d1", d1), ("d2", d2),
    ("N(d1)  share-counted chance", bell_area(d1)),
    ("N(d2)  cash-counted chance", bell_area(d2)),
    ("e^-rT  discount factor", D),
    ("e^-qT  dividend drag", exp(-Q * T)),
    ("share leg  S e^-qT N(d1)", share_term),
    ("cash leg   K e^-rT N(d2)", cash_term),
    ("road 1  closed form", call),
    ("road 2  average over prices", call_int),
    ("road 3  200,000 drawn finishes", mc),
    ("        its standard error", mc_err),
    ("share leg by road 2", share_int),
    ("cash leg by road 2", cash_int),
    ("average payoff, not discounted", call / D),
    ("average finish, road 2", mean_end / D),
    ("  forward S e^(r-q)T", S * exp((R - Q) * T)),
    ("  peak of the weights", mode),
    ("  discounted average finish", mean_end), ("  S e^-qT", A),
    ("  discounted finish, road 3", mc_end),
    ("put by road 2", put_int), ("  call minus put", call - put_int),
    ("  S e^-qT - K e^-rT", A - K * D),
    ("wrong: average under 8% drift", wrong_real),
    ("wrong: payoff of the average", wrong_jensen),
    ("wrong: the two weights swapped", wrong_swap),
    ("try: prices cut off at 120", cut_at_120),
    ("try: 2,000 draws", mc_small), ("     its standard error", mc_small_err),
    ("try: sigma = 0.40", vol_40),
]
for name, value in rows:
    print(f"{name:<32} {value:>14.6f}")

bands = [60.0 + 10.0 * i for i in range(11)]
gains = [100.0 + 10.0 * i for i in range(9)]
print()
print("chart, finishing price ($)     " + " ".join(f"{x:6.0f}" for x in bands))
print("chart, chance of a $10 band (%)" + " ".join(f"{1000.0 * density(x):6.2f}" for x in bands))
print("chart, finishing price ($)     " + " ".join(f"{x:6.0f}" for x in gains))
print("chart, $ of the average payoff " + " ".join(f"{10.0 * max(x - K, 0.0) * density(x):6.2f}" for x in gains))
print(f"those nine bands add to        {sum(10.0 * max(x - K, 0.0) * density(x) for x in gains):>14.6f}")
print(f"bars, share leg {share_term:.2f}, cash leg {cash_term:.2f}, call {call:.2f}")

assert abs(call - 9.227005508154) < 1e-9, "closed form vs the shelf's house number"
assert abs(call_int - call) < 1e-8, "average over prices vs the closed form"
assert abs(mc - call) < 3.0 * mc_err, "drawn average within three standard errors"
assert abs(share_int - share_term) < 1e-8, "share leg: no d1 used on the left side"
assert abs(cash_int - cash_term) < 1e-8, "cash leg: no d2 used on the left side"
assert abs(mean_end / D - S * exp((R - Q) * T)) < 1e-8, "average finish is the forward"
assert abs(mean_end - A) < 1e-8, "discounted average finish must be the prepaid share"
assert density(mode) > density(100.0) > density(90.0), "the weights peak below the strike"
assert abs((call - put_int) - (A - K * D)) < 1e-8, "parity, with a separately priced put"
assert bell_area(d1) > bell_area(d2), "the share weight must exceed the cash weight"
print("ALL CHECKS PASS")
