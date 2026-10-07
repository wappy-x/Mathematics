# Cash-or-nothing digital -- the check behind the card.  Nothing is imported
# that already knows the answer: the bell-curve area and both payoff integrals
# are Simpson's rule written out, the random numbers come from the whole-number
# recurrence below, turned into bell-curve draws by Box-Muller.
from math import cos, exp, log, pi, sin, sqrt

S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0   # the house market
MU = 0.08                              # a real-world growth rate, for the mistake row
SEED, PATHS, MOD = 20260919, 200000, 1 << 32
HOUSE_CALL = 9.227005508154            # the Black-Scholes call card's price

def simpson(f, a, b, n):               # the integrator, written out here
    h = (b - a) / n
    total = f(a) + f(b)
    for i in range(1, n):
        total += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return total * h / 3.0

def phi(x):                            # bell-curve height at x
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def n_cdf(x):                          # bell-curve area to the left of x
    if x < -12.0:
        return 0.0
    if x > 12.0:
        return 1.0
    return 0.5 + simpson(phi, 0.0, x, 4000)

def d1d2(s, k, r, q, sig, t):
    d2 = (log(s / k) + (r - q - 0.5 * sig * sig) * t) / (sig * sqrt(t))
    return d2 + sig * sqrt(t), d2

def digital(s, k, r, q, sig, t):       # road 1: the formula, e^-rT N(d2)
    return exp(-r * t) * n_cdf(d1d2(s, k, r, q, sig, t)[1])

def by_density(s, k, r, q, sig, t, above):   # road 2: sum the price density past K
    m, v = log(s) + (r - q - 0.5 * sig * sig) * t, sig * sqrt(t)
    dens = lambda x: phi((log(x) - m) / v) / (x * v)   # chance per dollar at price x
    lo, hi = (k, exp(m + 12.0 * v)) if above else (exp(m - 12.0 * v), k)
    return exp(-r * t) * simpson(dens, lo, hi, 20000)

def by_simulation(n, seed):            # road 3: Monte Carlo, count the finishes above K
    state, hits, drift, v = seed, 0, (R - Q - 0.5 * SIG * SIG) * T, SIG * sqrt(T)
    for _ in range(n // 2):
        state = (1664525 * state + 1013904223) % MOD
        u = (state + 0.5) / MOD
        state = (1664525 * state + 1013904223) % MOD
        w = (state + 0.5) / MOD
        rad, ang = sqrt(-2.0 * log(u)), 2.0 * pi * w
        for z in (rad * cos(ang), rad * sin(ang)):
            hits += S * exp(drift + v * z) > K
    p = hits / n
    return hits, exp(-R * T) * p, exp(-R * T) * sqrt(p * (1.0 - p) / n)

def call(s, k, r, q, sig, t):          # the Black-Scholes call, for the cross-checks
    d1, d2 = d1d2(s, k, r, q, sig, t)
    return s * exp(-q * t) * n_cdf(d1) - k * exp(-r * t) * n_cdf(d2)

d1, d2 = d1d2(S, K, R, Q, SIG, T)
disc, cash = exp(-R * T), digital(S, K, R, Q, SIG, T)
put = disc * n_cdf(-d2)
cash_int, put_int = by_density(S, K, R, Q, SIG, T, True), by_density(S, K, R, Q, SIG, T, False)
hits, mc, se = by_simulation(PATHS, SEED)
hits_small, mc_small, se_small = by_simulation(2000, SEED)
spread = (call(S, K - 0.01, R, Q, SIG, T) - call(S, K + 0.01, R, Q, SIG, T)) / 0.02
asset = S * exp(-Q * T) * n_cdf(d1)
pdf = disc * phi(d2)                   # e^-rT times the bell height at d2, used by every Greek
greeks = [                              # name, closed form, bump of the formula
    ("delta", pdf / (S * SIG * sqrt(T)),
     (digital(S + 0.01, K, R, Q, SIG, T) - digital(S - 0.01, K, R, Q, SIG, T)) / 0.02),
    ("gamma", -pdf * d1 / (S * S * SIG * SIG * T),
     (digital(S + 0.01, K, R, Q, SIG, T) - 2 * cash + digital(S - 0.01, K, R, Q, SIG, T)) / 1e-4),
    ("vega, per 1.00 of vol", -pdf * d1 / SIG,
     (digital(S, K, R, Q, SIG + 1e-4, T) - digital(S, K, R, Q, SIG - 1e-4, T)) / 2e-4),
    ("theta, per year", R * cash - pdf * ((R - Q - 0.5 * SIG * SIG) * T - log(S / K)) / (2 * SIG * T ** 1.5),
     -(digital(S, K, R, Q, SIG, T + 1e-4) - digital(S, K, R, Q, SIG, T - 1e-4)) / 2e-4),
    ("rho, per 1.00 of rate", -T * cash + pdf * sqrt(T) / SIG,
     (digital(S, K, R + 1e-4, Q, SIG, T) - digital(S, K, R - 1e-4, Q, SIG, T)) / 2e-4),
]
rows = [
    ("drift  r - q - sigma^2/2", R - Q - 0.5 * SIG * SIG), ("spread  sigma sqrt(T)", SIG * sqrt(T)),
    ("d1", d1), ("d2", d2), ("median finish S e^((r-q-sigma^2/2)T)", S * exp((R - Q - 0.5 * SIG * SIG) * T)),
    ("N(d2)  chance of finishing above K", n_cdf(d2)), ("N(-d2)  chance of finishing below K", n_cdf(-d2)),
    ("real-world chance above K, growth 8%", n_cdf(d2 + (MU - R) * sqrt(T) / SIG)), ("discount factor e^-rT", disc),
    ("1 formula  e^-rT N(d2)", cash), ("2 Simpson over the price density", cash_int),
    ("3 Monte Carlo, 200000 paths", mc), ("  standard error", se), ("  paths finishing above K", hits),
    ("4 call spread, strikes 99.99 and 100.01", spread),
    ("put, formula  e^-rT N(-d2)", put), ("put, Simpson over the price density", put_int),
    ("  call + put", cash + put_int), ("  e^-rT", disc),
    ("cash half of the call, 100 x digital", K * cash), ("asset digital  S e^-qT N(d1)", asset),
    ("  asset - 100 x cash", asset - K * cash), ("  house call", HOUSE_CALL),
    ("wrong: no discount", n_cdf(d2)), ("wrong: N(d1) for N(d2)", disc * n_cdf(d1)),
    ("wrong: real-world chance, discounted", disc * n_cdf(d2 + (MU - R) * sqrt(T) / SIG)),
    ("wrong: forgot the 2% dividend", digital(S, K, R, 0.0, SIG, T)),
    ("wrong: put as 1 - call", 1.0 - cash),
    ("try: sigma = 0.40", digital(S, K, R, Q, 0.40, T)), ("try: K = 110", digital(S, 110.0, R, Q, SIG, T)),
    ("try: T = 0.01", digital(S, K, R, Q, SIG, 0.01)), ("try: pays $1000", 1000.0 * cash),
    ("try: Monte Carlo, 2000 paths", mc_small), ("  its standard error", se_small),
]
for name, v in rows:
    print(f"{name:<40} {v:>12.6f}" if isinstance(v, float) else f"{name:<40} {v:>12d}")
print()
print(f"{'greek':<24}{'formula':>12}{'bump':>12}")
for name, f, b in greeks:
    print(f"{name:<24}{f:>12.6f}{b:>12.6f}")
print()
spots = [80.0 + 5.0 * i for i in range(9)]
print("chart, Acme price     " + " ".join(f"{s:6.0f}" for s in spots))
print("chart, pays at expiry " + " ".join(f"{float(s > K):6.2f}" for s in spots))
for label, t in (("chart, 12 months left", 1.0), ("chart, 1 month left ", 1.0 / 12.0)):
    print(label + " " + " ".join(f"{digital(s, K, R, Q, SIG, t):6.2f}" for s in spots))

assert abs(cash_int - cash) < 1e-8,             "density integral must land on the formula"
assert abs(mc - cash) < 3 * se,                 "simulation within three standard errors"
assert abs(cash + put_int - disc) < 1e-8,       "call + independent put = one discounted dollar"
assert abs(put - put_int) < 1e-8,               "put formula lands on its density sum"
assert abs(spread - cash) < 1e-7,               "tight call spread lands on the digital"
assert abs(asset - K * cash - HOUSE_CALL) < 1e-9, "the two digitals rebuild the house call"
assert all(abs(f - b) < 1e-5 for _, f, b in greeks), "every Greek matches its bump"
print("ALL CHECKS PASS")
