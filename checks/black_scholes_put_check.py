# Black-Scholes put -- the check behind the card.  Standard library only.  Nothing
# imported already knows an answer: the bell-curve area, the integrator, the root finder
# and the tree are written out below, and every number quoted on the card is printed here.
from math import log, sqrt, exp, pi
def phi(z):                                    # bell-curve height at z
    return exp(-0.5 * z * z) / sqrt(2.0 * pi)
def simpson(f, a, b, n):                       # area under f from a to b, n panels
    h = (b - a) / n
    total = f(a) + f(b)
    for i in range(1, n):
        total += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return total * h / 3.0
def N(x):                                      # bell-curve area to the left of x
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 256)     # half, plus the slice from 0 to x
def d1d2(S, K, r, q, sigma, T):                # the two distances, in wiggle units
    vt = sigma * sqrt(T)
    d2 = (log(S / K) + (r - q - 0.5 * sigma * sigma) * T) / vt
    return d2 + vt, d2
def put(S, K, r, q, sigma, T):                 # road 1: the formula
    d1, d2 = d1d2(S, K, r, q, sigma, T)
    return K * exp(-r * T) * N(-d2) - S * exp(-q * T) * N(-d1)
def call(S, K, r, q, sigma, T):                # the call, for the parity road
    d1, d2 = d1d2(S, K, r, q, sigma, T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def spot_at(S, r, q, sigma, T, z):             # Acme at expiry, z wiggles out
    return S * exp((r - q - 0.5 * sigma * sigma) * T + sigma * sqrt(T) * z)
def crossing(S, K, r, q, sigma, T):            # bisection: the draw landing on the strike
    lo, hi = -40.0, 40.0
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if spot_at(S, r, q, sigma, T, mid) < K else (lo, mid)
    return 0.5 * (lo + hi)
def by_tail(S, K, r, q, sigma, T, want_put, n=4096):
    # road 2: average the payoff over the one tail where it is positive.  The edge of
    # that tail is the bisection above, not d1 or d2, and nothing bends inside it.
    zk = crossing(S, K, r, q, sigma, T)
    if want_put:
        return exp(-r * T) * simpson(
            lambda z: (K - spot_at(S, r, q, sigma, T, z)) * phi(z), -8.0, zk, n)
    return exp(-r * T) * simpson(
        lambda z: (spot_at(S, r, q, sigma, T, z) - K) * phi(z), zk, 8.0, n)
def by_tree(S, K, r, q, sigma, T, steps=2000):
    # road 4: up or down each step (Cox-Ross-Rubinstein), averaged backwards
    dt = T / steps
    tick = sigma * sqrt(dt)                    # one up-tick, measured in logs
    u = exp(tick); d = 1.0 / u
    p = (exp((r - q) * dt) - d) / (u - d)
    disc = exp(-r * dt)
    v = [max(K - S * exp((2 * j - steps) * tick), 0.0) for j in range(steps + 1)]
    for step in range(steps, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(step)]
    return v[0]

# ---- the house market: Acme at $100, strike $100, one year, r 5%, q 2%, sigma 20% ----
S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1, d2 = d1d2(S, K, r, q, sigma, T)
D, A = exp(-r * T), S * exp(-q * T)            # discount on the strike cash; prepaid share
P, C, P_tree = put(S, K, r, q, sigma, T), call(S, K, r, q, sigma, T), by_tree(S, K, r, q, sigma, T)
P_tail, C_tail = by_tail(S, K, r, q, sigma, T, True), by_tail(S, K, r, q, sigma, T, False)
zk = crossing(S, K, r, q, sigma, T)
def bumped(i, h):                              # move one input up and down, reprice
    lo = [S, K, r, q, sigma, T]; hi = list(lo)
    lo[i] -= h; hi[i] += h
    return (put(*hi) - put(*lo)) / (2.0 * h)
gamma = (put(S + 0.01, K, r, q, sigma, T) - 2.0 * P
         + put(S - 0.01, K, r, q, sigma, T)) / (0.01 * 0.01)
delta, vega, rho, theta = bumped(0, 0.01), bumped(4, 0.0001), bumped(2, 0.0001), -bumped(5, 0.0001)

# ---- what breaks if a piece goes missing ----
signs_lost = K * D * N(d2) - A * N(d1)         # the minus signs inside N dropped
both_md1 = K * D * N(-d1) - A * N(-d1)         # the share's chance on both halves
both_md2 = K * D * N(-d2) - A * N(-d2)         # the cash's chance on both halves
no_disc = K * N(-d2) - A * N(-d1)              # the strike cash left undiscounted
no_div = put(S, K, r, 0.0, sigma, T)           # priced as if Acme paid no dividend

for name, v in [
        ("d2  cash-side distance", d2), ("d1  share-side distance", d1),
        ("-d2 by bisection, no formula", zk),
        ("N(d2)  the call's chance, in cash", N(d2)),
        ("N(d1)  the call's chance, in shares", N(d1)),
        ("N(-d2)  chance below, in cash", N(-d2)),
        ("N(-d1)  chance below, in shares", N(-d1)),
        ("cash half  K e^-rT N(-d2)", K * D * N(-d2)),
        ("share half  S e^-qT N(-d1)", A * N(-d1)),
        ("1 formula", P), ("2 lower-tail integral", P_tail),
        ("3 call, upper-tail integral", C_tail), ("  call by formula", C),
        ("  parity  C - S e^-qT + K e^-rT", C - A + K * D),
        ("  C - P, both by integral", C_tail - P_tail), ("  S e^-qT - K e^-rT", A - K * D),
        ("4 tree, 2000 steps", P_tree), ("ceiling  K e^-rT", K * D),
        ("prepaid share  S e^-qT", A), ("forward  S e^(r-q)T", S * exp((r - q) * T)),
        ("breakeven at expiry  K - P", K - P), ("  breakeven, premium financed", K - P / D),
        ("wrong: minus signs inside N lost", signs_lost),
        ("wrong: N(-d1) on both halves", both_md1),
        ("wrong: N(-d2) on both halves", both_md2),
        ("wrong: strike cash undiscounted", no_disc),
        ("wrong: dividend ignored", no_div)]:
    print(f"{name:<36}{v:>18.12f}")
print()
print("greeks, by bumping one input at a time")
print(f"{'delta':>11}{'gamma':>11}{'vega':>11}{'theta':>11}{'rho':>11}")
print("".join(f"{g:>11.6f}" for g in (delta, gamma, vega, theta, rho)))
print()
print("deep in the money: Acme across, dollars down")
deep = [100.0, 90.0, 80.0, 70.0, 60.0, 50.0, 40.0]
print(f"{'Acme now':>10}" + "".join(f"{s:>9.0f}" for s in deep))
for lab, vals in (("put", [put(s, K, r, q, sigma, T) for s in deep]),
                  ("K - S now", [max(K - s, 0.0) for s in deep]),
                  ("floor", [max(K * D - s * exp(-q * T), 0.0) for s in deep])):
    print(f"{lab:>10}" + "".join(f"{v:>9.2f}" for v in vals))
print()
print("put at Acme 60, where K - S now = 40.00, against the rate")
rates = [0.0, 0.02, 0.05, 0.08, 0.12]
print(f"{'rate':>10}" + "".join(f"{100.0 * x:>8.1f}%" for x in rates))
print(f"{'put':>10}" + "".join(f"{put(60.0, K, x, q, sigma, T):>9.2f}" for x in rates))
print(f"{'floor':>10}" + "".join(f"{K * exp(-x * T) - 60.0 * exp(-q * T):>9.2f}" for x in rates))
print()
spots = [60.0 + 10.0 * i for i in range(9)]
print(f"{'chart, Acme price':<26}" + "".join(f"{s:>8.0f}" for s in spots))
for label, t in (("chart, 12 months left", 1.0), ("chart, 3 months left", 0.25),
                 ("chart, expiry day", 0.0)):
    vals = [put(s, K, r, q, sigma, t) if t > 0 else max(K - s, 0.0) for s in spots]
    print(f"{label:<26}" + "".join(f"{v:>8.2f}" for v in vals))
print(f"{'chart, profit after 6.33':<26}" + "".join(f"{max(K - s, 0.0) - P:>8.2f}" for s in spots))

assert abs(P - 6.330080627550) < 1e-9, "formula vs the shelf's house put"
assert abs(P_tail - P) < 1e-9, "lower-tail integral must land on the formula"
assert abs(zk + d2) < 1e-12, "the bisected crossing must be -d2"
assert abs((C_tail - P_tail) - (A - K * D)) < 1e-9, "parity, both legs integrated"
assert abs((C - A + K * D) - P) < 1e-12, "the put from the call by parity"
assert abs(P_tree - P) < 0.01, "tree road within a cent"
assert abs(delta + exp(-q * T) * N(-d1)) < 1e-6, "bumped delta vs -e^-qT N(-d1)"
assert abs(rho + T * K * D * N(-d2)) < 1e-5, "bumped rho vs -T K e^-rT N(-d2)"
assert N(-d1) < N(-d2), "the share-counted chance below the strike is the smaller one"
assert put(60.0, K, r, q, sigma, T) < 40.0, "the deep put sits below its cash value now"
assert put(60.0, K, r, q, sigma, T) > K * D - 60.0 * exp(-q * T), "but above its floor"
assert put(60.0, K, 0.0, q, sigma, T) > 40.0, "with no interest it sits above that value"
print("ALL CHECKS PASS")
