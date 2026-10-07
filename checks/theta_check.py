# Theta -- the check behind the card.  Standard library only, nothing imported
# that already knows the answer: the bell-curve area N(x) is Simpson's rule
# written out, the brute-force price is a second Simpson sum, the tree is a
# loop and the root finder is bisection.  House market throughout.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

def N(x):                                                   # bell-curve area left of x
    if abs(x) > 12.0: return 0.0 if x < 0 else 1.0
    return 0.5 + simpson(phi, 0.0, x, 400)

def d1d2(S, K, r, q, s, T):
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
    return d1, d1 - s * sqrt(T)

def theta_parts(S, K, r, q, s, T, cp):                      # road 1: the closed form, per year
    d1, d2 = d1d2(S, K, r, q, s, T)
    vol = -S * exp(-q * T) * phi(d1) * s / (2.0 * sqrt(T))
    div = q * S * exp(-q * T) * (N(d1) if cp > 0 else -N(-d1))
    rate = -r * K * exp(-r * T) * (N(d2) if cp > 0 else -N(-d2))
    return vol, div, rate

def theta(S, K, r, q, s, T, cp): return sum(theta_parts(S, K, r, q, s, T, cp))

def price_int(S, K, r, q, s, T, cp):
    # road 2's price: average the payoff over the bell curve, split at the kink.
    # No d1, no d2, no N.
    zk = (log(K / S) - (r - q - 0.5 * s * s) * T) / (s * sqrt(T))
    f = lambda z: cp * (S * exp((r - q - 0.5 * s * s) * T + s * sqrt(T) * z) - K) * phi(z)
    a, b = (zk, 10.0) if cp > 0 else (-10.0, zk)
    return exp(-r * T) * simpson(f, a, b, 2000)

def theta_bump(S, K, r, q, s, T, cp, h=1e-4):               # road 2: minus the slope in time left
    return -(price_int(S, K, r, q, s, T + h, cp) - price_int(S, K, r, q, s, T - h, cp)) / (2 * h)

def theta_tree(S, K, r, q, s, T, cp, steps=2000):
    # road 4: Cox-Ross-Rubinstein.  u*d = 1, so the middle node two steps in
    # is today's share price, 2 dt later.  No calculus.
    dt = T / steps
    u = exp(s * sqrt(dt)); d = 1.0 / u
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt)
    v = [max(cp * (S * u ** j * d ** (steps - j) - K), 0.0) for j in range(steps + 1)]
    mid = None
    for n in range(steps, 0, -1):
        v = [disc * (p * v[j + 1] + (1 - p) * v[j]) for j in range(n)]
        if n == 3: mid = v[1]
    return (mid - v[0]) / (2 * dt)

S, K, r, q, s, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
DAY = 1.0 / 365.0
d1, d2 = d1d2(S, K, r, q, s, T)
vc, qc, rc = theta_parts(S, K, r, q, s, T, +1)
vp, qp, rp = theta_parts(S, K, r, q, s, T, -1)
th_c, th_p = vc + qc + rc, vp + qp + rp
call0, put0 = price_int(S, K, r, q, s, T, +1), price_int(S, K, r, q, s, T, -1)
bump_c, bump_p = theta_bump(S, K, r, q, s, T, +1), theta_bump(S, K, r, q, s, T, -1)

# road 3: the Black-Scholes equation, theta = rV - (r-q) S delta - 1/2 s^2 S^2 gamma,
# delta and gamma by nudging the brute-force price, never a Greek formula
hs = 0.01
def pde_theta(cp):
    up, mid, dn = (price_int(x, K, r, q, s, T, cp) for x in (S + hs, S, S - hs))
    delta, gamma = (up - dn) / (2 * hs), (up - 2 * mid + dn) / (hs * hs)
    return r * mid - (r - q) * S * delta - 0.5 * s * s * S * S * gamma, delta, gamma
pde_c, delta, gamma = pde_theta(+1)
pde_p, _, _ = pde_theta(-1)
tree_c, tree_p = theta_tree(S, K, r, q, s, T, +1), theta_tree(S, K, r, q, s, T, -1)
par_lhs, par_rhs = bump_c - bump_p, q * S * exp(-q * T) - r * K * exp(-r * T)
one_day = price_int(S, K, r, q, s, T - DAY, +1) - call0

rent_year = 0.5 * s * s * S * S * gamma                     # the gamma half of the equation
rent_day = rent_year * DAY
be_move = sqrt(2.0 * rent_day / gamma)                      # solve 1/2 gamma m^2 = one day's rent

# sign flips: a deep put, a call on a high-yield share, and the put's zero strike
deep_put, deep_put_b = theta(S, 130.0, r, q, s, T, -1), theta_bump(S, 130.0, r, q, s, T, -1)
hy_call, hy_call_b = theta(S, 80.0, r, 0.08, s, T, +1), theta_bump(S, 80.0, r, 0.08, s, T, +1)
lo, hi = 100.0, 130.0                                       # put theta < 0 at 100, > 0 at 130
for _ in range(60):
    mid_k = 0.5 * (lo + hi)
    lo, hi = (mid_k, hi) if theta(S, mid_k, r, q, s, T, -1) < 0 else (lo, mid_k)
k_zero = 0.5 * (lo + hi)

rows = [
    ("d1, d2", d1, d2), ("N(d1), N(d2)", N(d1), N(d2)), ("phi(d1)", phi(d1)),
    ("e^-qT, e^-rT", exp(-q * T), exp(-r * T)), ("call price, put price", call0, put0),
    ("call terms: vol, dividend, rate", vc, qc, rc), ("put terms: vol, dividend, rate", vp, qp, rp),
    ("1 call theta, formula", th_c), ("2 call theta, bump in T", bump_c),
    ("3 call theta, BS equation", pde_c), ("4 call theta, tree", tree_c),
    ("1 put theta, formula", th_p), ("2 put theta, bump in T", bump_p),
    ("3 put theta, BS equation", pde_p), ("4 put theta, tree", tree_p),
    ("5 theta_C - theta_P, bumps", par_lhs), ("  q S e^-qT - r K e^-rT", par_rhs),
    ("call theta per day, /365", th_c * DAY), ("call, repriced 1 day on", one_day),
    ("put theta per day, /365", th_p * DAY), ("call theta per day, /252", th_c / 252.0),
    ("delta, gamma", delta, gamma), ("rV, (r-q) S delta", r * call0, (r - q) * S * delta),
    ("rent: per year, per day", rent_year, rent_day), ("breakeven daily move", be_move),
    ("put K=130 theta: formula, bump", deep_put, deep_put_b), ("put K=130 theta per day", deep_put * DAY),
    ("call K=80 q=8%: formula, bump", hy_call, hy_call_b), ("put theta = 0 at strike", k_zero),
    ("wrong: dV/dT sign", -th_c), ("wrong: no 2 in 2 sqrt(T)", th_c + vc),
    ("wrong: dividend term dropped", th_c - qc),
]
for name, *vals in rows:
    print(f"{name:<32}" + "".join(f"{v:>12.6f}" for v in vals))
print("chart, strike       " + "".join(f"{k:>9.0f}" for k in range(70, 131, 10)))
print("chart, call theta   " + "".join(f"{theta(S, k, r, q, s, T, +1):>9.2f}" for k in range(70, 131, 10)))
print("chart, put theta    " + "".join(f"{theta(S, k, r, q, s, T, -1):>9.2f}" for k in range(70, 131, 10)))
for label, t in (("12 months", 1.0), ("6 months", 0.5), ("3 months", 0.25), ("1 month", 1 / 12), ("1 week", 7 / 365), ("1 day", 1 / 365)):
    print(f"cents a day, {label:<9} call{theta(S, K, r, q, s, t, +1) * DAY * 100:>8.2f}   put K=130{theta(S, 130.0, r, q, s, t, -1) * DAY * 100:>8.2f}")

assert abs(th_c - (-5.089319)) < 1e-6, "call theta vs the house number"
assert abs(th_p - (-2.293569)) < 1e-6, "put theta vs the house number"
assert abs(bump_c - th_c) < 1e-6 and abs(bump_p - th_p) < 1e-6, "formula vs brute-force bump"
assert abs(pde_c - th_c) < 1e-4 and abs(pde_p - th_p) < 1e-4, "formula vs the equation"
assert abs(tree_c - th_c) < 0.01 and abs(tree_p - th_p) < 0.01, "formula vs the tree"
assert abs(par_lhs - par_rhs) < 1e-6, "theta parity, brute-force side"
assert deep_put_b > 0 and hy_call_b > 0, "brute force agrees: both gain with time"
assert abs(deep_put_b - deep_put) < 1e-6 and abs(hy_call_b - hy_call) < 1e-6, "sign cases, two roads"
assert abs(theta_bump(S, k_zero, r, q, s, T, -1)) < 1e-5, "bisected strike is a zero of the bump"
assert abs(rent_year + vc) < 1e-4, "bumped-gamma rent equals the formula's volatility term"
print("ALL CHECKS PASS")
