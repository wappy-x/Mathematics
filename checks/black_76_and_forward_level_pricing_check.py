# Black-76 -- the check behind the card.  Standard library only, and nothing
# imported that already holds the answer: the integrator, the tree and the root
# finder are written out here.  Acme's one-year forward stands at 103.045453,
# the strike at 100.00, the bank rate at 5 percent, the forward's volatility at
# 20 percent.  Four roads reach one premium; every Greek meets a bumped price.
from math import erf, exp, log, pi, sqrt

S, Q = 100.0, 0.02                 # spot and dividend yield: for the cross-check only
K, R, SIGMA, T = 100.0, 0.05, 0.20, 1.0
F, D = S * exp((R - Q) * T), exp(-R * T)   # the forward by cash and carry, one discount
H, HG = 1e-4, 1e-2                 # bump sizes for slopes, and for curvature

def cdf(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))     # bell-curve area left of x
def pdf(x):   return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def distances(f, k, sigma, t):     # the two distances from forward to strike
    a = sigma * sqrt(t); d1 = (log(f / k) + 0.5 * sigma * sigma * t) / a
    return d1, d1 - a

def black76(f, k, r, sigma, t, call=True):                # road 1: the formula
    d1, d2 = distances(f, k, sigma, t)
    disc = exp(-r * t)
    if call: return disc * (f * cdf(d1) - k * cdf(d2))
    return disc * (k * cdf(-d2) - f * cdf(-d1))

def simpson(g, a, b, n):           # the integrator, written out
    h = (b - a) / n; total = g(a) + g(b)
    for i in range(1, n): total += (4.0 if i % 2 else 2.0) * g(a + i * h)
    return total * h / 3.0

def by_integral(f, k, r, sigma, t, call=True, n=40000):
    # Road 2: average the payoff over the driftless forward by brute force.
    # No d1, no d2 -- nothing borrowed from the formula.
    def g(z):
        ft = f * exp(-0.5 * sigma * sigma * t + sigma * sqrt(t) * z)
        return (max(ft - k, 0.0) if call else max(k - ft, 0.0)) * pdf(z)
    return exp(-r * t) * simpson(g, -10.0, 10.0, n)

def by_tree(f, k, r, sigma, t, steps=2000):
    # Road 3: a coin-flip tree on the forward itself.  A forward drifts nowhere,
    # so the up-chance is fixed by the average staying put, and one discount lands
    # at the end rather than one at every step.
    dt = t / steps
    up = exp(sigma * sqrt(dt)); down = 1.0 / up; p = (1.0 - down) / (up - down)
    v = [max(f * up ** j * down ** (steps - j) - k, 0.0) for j in range(steps + 1)]
    for step in range(steps, 0, -1):
        v = [p * v[j + 1] + (1.0 - p) * v[j] for j in range(step)]
    return exp(-r * t) * v[0]

def black_scholes(s, k, r, q, sigma, t):                  # road 4: the spot formula
    a = sigma * sqrt(t); d1 = (log(s / k) + (r - q + 0.5 * sigma * sigma) * t) / a
    return s * exp(-q * t) * cdf(d1) - k * exp(-r * t) * cdf(d1 - a)

def implied_vol(price, f, k, r, t):                       # the root finder, written out
    lo, hi = 1e-6, 5.0
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if black76(f, k, r, mid, t) < price else (lo, mid)
    return 0.5 * (lo + hi)

def bumped(f, r, sg, t): return black76(f, K, r, sg, t)   # the call, one input moved
def spot(s): return black_scholes(s, K, R, Q, SIGMA, T)   # the spot call, Acme's price moved

d1, d2 = distances(F, K, SIGMA, T)
C, P = black76(F, K, R, SIGMA, T), black76(F, K, R, SIGMA, T, False)
C_int, P_int = by_integral(F, K, R, SIGMA, T), by_integral(F, K, R, SIGMA, T, False)
C_tree, C_bs = by_tree(F, K, R, SIGMA, T), black_scholes(S, K, R, Q, SIGMA, T)
delta_f, delta_s = D * cdf(d1), exp(-Q * T) * cdf(d1)     # per forward dollar, per spot dollar
chain = delta_f * exp((R - Q) * T)                        # the two joined by dF/dS
gamma, vega = D * pdf(d1) / (F * SIGMA * sqrt(T)), D * F * pdf(d1) * sqrt(T)
theta = R * C - D * F * pdf(d1) * SIGMA / (2.0 * sqrt(T))
rho_f, rho_s = -T * C, T * K * D * cdf(d2)                # rate moved with F held, with S held
b_delta = (bumped(F + H, R, SIGMA, T) - bumped(F - H, R, SIGMA, T)) / (2.0 * H)
b_delta_s = (spot(S + H) - spot(S - H)) / (2.0 * H)       # the spot slope, its own road
b_gamma = (bumped(F + HG, R, SIGMA, T) - 2.0 * C + bumped(F - HG, R, SIGMA, T)) / (HG * HG)
b_vega = (bumped(F, R, SIGMA + H, T) - bumped(F, R, SIGMA - H, T)) / (2.0 * H)
b_theta = -(bumped(F, R, SIGMA, T + H) - bumped(F, R, SIGMA, T - H)) / (2.0 * H)
b_rho_f = (bumped(F, R + H, SIGMA, T) - bumped(F, R - H, SIGMA, T)) / (2.0 * H)
b_rho_s = (bumped(S * exp((R + H - Q) * T), R + H, SIGMA, T)
           - bumped(S * exp((R - H - Q) * T), R - H, SIGMA, T)) / (2.0 * H)
iv, a_w = implied_vol(C, F, K, R, T), SIGMA * sqrt(T)
d1_w = (log(F / K) + (R + 0.5 * SIGMA * SIGMA) * T) / a_w  # the carry counted twice over
wrong_d = D * (F * cdf(d1_w) - K * cdf(d1_w - a_w))
financed = C / D                                          # the same premium, paid at expiry
spot_used, both_d2 = black76(S, K, R, SIGMA, T), D * (F - K) * cdf(d2)
grid = [80.0 + 5.0 * i for i in range(11)]
settle = [max(g - K, 0.0) for g in grid]
profit = [s - financed for s in settle]

rows = [
    ("log(F / K), the forward's lead over the strike", log(F / K)),
    ("one wiggle unit  sigma root T", SIGMA * sqrt(T)),
    ("d1", d1), ("d2", d2), ("N(d1)", cdf(d1)), ("N(d2)", cdf(d2)), ("phi(d1)", pdf(d1)),
    ("discount  D = e^-rT", D), ("forward half  D F N(d1)", D * F * cdf(d1)),
    ("strike half   D K N(d2)", D * K * cdf(d2)), ("1 Black-76 formula, call", C),
    ("2 payoff integral over the forward", C_int),
    ("3 driftless tree on the forward, 2000 steps", C_tree),
    ("4 Black-Scholes off the spot, yield 2 percent", C_bs),
    ("put, Black-76 formula", P), ("put, payoff integral", P_int),
    ("parity  C - P", C - P), ("parity  D (F - K), also the premium floor", D * (F - K)),
    ("premium ceiling  D F", D * F), ("the same premium paid at expiry  C / D", financed),
    ("implied volatility from the premium, by bisection", iv),
    ("break-even forward at expiry  K + C / D", K + financed),
    ("delta  D N(d1), per dollar of forward", delta_f),
    ("  same, by bumping the forward", b_delta),
    ("stock delta  e^-qT N(d1), per dollar of spot", delta_s),
    ("  same, forward delta times e^(r-q)T", chain), ("  same, by bumping the spot", b_delta_s),
    ("gamma  D phi(d1) / (F sigma root T)", gamma), ("  same, by bumping twice", b_gamma),
    ("vega  D F phi(d1) root T", vega), ("  same, by bumping sigma", b_vega),
    ("theta  r C - D F phi(d1) sigma / (2 root T)", theta),
    ("  same, by shortening the wait", b_theta),
    ("rho, forward held fixed  -T C", rho_f),
    ("  same, by bumping r with F held", b_rho_f),
    ("rho, spot held fixed  T K D N(d2)", rho_s),
    ("  same, by bumping r and letting F move", b_rho_s),
    ("wrong: r put back inside d1 and d2", wrong_d),
    ("wrong: the discount D dropped", financed),
    ("wrong: spot 100.00 used as the forward", spot_used),
    ("wrong: N(d2) on both halves", both_d2),
]
print(f"Acme: spot {S:.2f}, yield {Q:.0%}, bank {R:.0%}, sigma {SIGMA:.0%}, {T:.0f} year;"
      f" forward {F:.6f}, strike {K:.2f}")
for name, value in rows:
    print(f"{name:<50}{value:>14.6f}")
print()
print(f"{'chart, forward on expiry day':<32}" + "".join(f"{g:>7.0f}" for g in grid))
print(f"{'chart, cash settlement':<32}" + "".join(f"{s:>7.2f}" for s in settle))
print(f"{'chart, profit after the premium':<32}" + "".join(f"{p:>7.2f}" for p in profit))

assert abs(C - 9.227005508154) < 1e-9 and abs(P - 6.330080627550) < 1e-9, "the shelf's pair"
assert abs(C_int - C) < 1e-7 and abs(P_int - P) < 1e-7, "brute-force averages vs the formulas"
assert abs(C_tree - C) < 0.01 and abs(C_bs - C) < 1e-12, "the tree, and the spot coordinates"
assert abs((C - P) - D * (F - K)) < 1e-12, "forward-form parity, put built on its own"
assert abs(b_delta - delta_f) < 1e-7 and abs(b_gamma - gamma) < 1e-7, "bumped slope, bumped bend"
assert abs(b_vega - vega) < 1e-5 and abs(b_theta - theta) < 1e-6, "bumped vega, bumped theta"
assert abs(b_rho_f - rho_f) < 1e-7 and abs(b_rho_s - rho_s) < 1e-5, "both rhos, bumped"
assert abs(chain - b_delta_s) < 1e-7 and abs(delta_s - b_delta_s) < 1e-7, "spot delta, bumped"
assert abs((b_rho_s - b_rho_f) - delta_f * T * F) < 1e-4, "the rhos differ by delta times T F"
assert abs(iv - SIGMA) < 1e-9 and D * (F - K) < C < D * F, "the inverse, and the premium band"
print("ALL CHECKS PASS")
