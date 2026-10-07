# Kyle's lambda and the square-root law -- the check behind the card.  Standard library only.
# A stock at $100 that trades 1,000,000 shares a day; a sale of 100,000 shares (10% of the day).
# Nothing imported knows the answer: the random numbers, the root finder and the fits are written here.
from math import sqrt, log, cos, pi

p0, sv, su = 100.0, 1.20, 200_000.0        # prior price $; sd of value $; sd of noise flow, shares
Q, Vd, sd, Y = 100_000.0, 1_000_000.0, 0.01, 1.0   # sale, daily volume, daily volatility, fitted constant

# ---- road 1: the closed form ----
lam = sv / (2.0 * su)                        # dollars per share, per share of net flow
beta = su / sv                               # shares the insider trades per dollar of mispricing
v_ins = p0 - Q / beta                        # the value at which the insider sells exactly 100,000
x_ins = beta * (v_ins - p0)
p_after = p0 + lam * x_ins                   # price if the noise traders happen to net to zero

# ---- road 2: the two best responses as an equation, solved by bisection ----
def dealer_slope(l):                         # insider answers l with 1/(2l); dealer regresses value on flow
    b = 1.0 / (2.0 * l)
    return b * sv * sv / (b * b * sv * sv + su * su)
lo, hi = 1e-9, 1e-3                          # g(l) = dealer_slope(l) - l changes sign on [lo, hi]
for _ in range(200):
    mid = 0.5 * (lo + hi)
    if dealer_slope(mid) - mid > 0: lo = mid
    else: hi = mid
lam_bis = 0.5 * (lo + hi)

# ---- road 3: the insider's best order by brute force, with lambda held fixed ----
best_x, best_pay = 0.0, -1e18
for k in range(-400, 401):                   # orders from -200,000 to +200,000 in 500-share steps
    x = 500.0 * k
    pay = x * (v_ins - p0 - lam * x)         # expected profit: noise averages to zero
    if pay > best_pay: best_x, best_pay = x, pay

# ---- road 4: simulate 200,000 auctions and let the dealer fit a line ----
state = 20260928
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    z ^= z >> 31
    return ((z >> 11) + 0.5) / 9007199254740992.0
def normal():
    return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
n = 200_000
sy = syy = sv_y = s_ins = s_noise = s_deal = s_res = 0.0
for _ in range(n):
    w = sv * normal()                        # value minus prior price
    u = su * normal()                        # noise traders' net order
    x = beta * w
    y = x + u
    price_move = lam * y
    sy += y; syy += y * y; sv_y += w * y
    s_ins += x * (w - price_move); s_noise += u * (w - price_move); s_deal += y * (price_move - w)
    s_res += (w - price_move) ** 2
lam_mc = (sv_y / n) / (syy / n - (sy / n) ** 2)

# ---- the square-root law, and a latent order book that produces it ----
I_sqrt = Y * sd * sqrt(Q / Vd)               # fraction of the price
L = 2.0 * Q / (I_sqrt * p0) ** 2             # shares per dollar per dollar, so the book walk agrees
def walk(q, depth_at):                       # sell q shares into a book, one-cent levels; return price fall
    k, left = 0, q
    while left > 1e-9:
        k += 1
        left -= depth_at(k)
    return 0.01 * k
vshape = lambda k: L * (0.01 * k) * 0.01     # depth grows with distance from the price
flat = lambda k: 0.01 / lam                  # Kyle's dealer: the same depth at every cent
sizes = [10_000.0, 20_000.0, 50_000.0, 100_000.0, 200_000.0, 400_000.0]
def fit_exponent(depth_at):                  # least-squares slope of log(price fall) on log(size)
    xs = [log(q) for q in sizes]; ys = [log(walk(q, depth_at)) for q in sizes]
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    return sum((a - mx) * (b - my) for a, b in zip(xs, ys)) / sum((a - mx) ** 2 for a in xs)
exp_v, exp_f = fit_exponent(vshape), fit_exponent(flat)

rows = [
    ("kyle: lambda, $ per million shares of flow", lam * 1e6),
    ("kyle: lambda by bisection", lam_bis * 1e6),
    ("kyle: lambda from 200,000 auctions", lam_mc * 1e6),
    ("kyle: depth 1/lambda, shares per $1", 1.0 / lam),
    ("kyle: beta, shares per $ of mispricing", beta),
    ("kyle: value that makes insider sell 100k", v_ins),
    ("kyle: best order, brute force", best_x),
    ("kyle: price after the sale, noise = 0", p_after),
    ("kyle: move in percent", 100.0 * (p_after - p0) / p0),
    ("kyle: sd of value before, $", sv),
    ("kyle: sd of value after, formula", sv / sqrt(2.0)),
    ("kyle: sd of value after, simulated", sqrt(s_res / n)),
    ("kyle: insider profit per auction, formula", sv * su / 2.0),
    ("kyle: insider profit, simulated", s_ins / n),
    ("kyle: noise traders' result, simulated", s_noise / n),
    ("kyle: dealer result, simulated", s_deal / n),
    ("kyle: insider profit on this sale", x_ins * (v_ins - p0 - lam * x_ins)),
    ("sqrt: impact of 10% of volume, percent", 100.0 * I_sqrt),
    ("sqrt: in dollars per share", I_sqrt * p0),
    ("sqrt: book walk, dollars per share", walk(Q, vshape)),
    ("sqrt: book slope L, shares per $ per $", L),
    ("fit: exponent, V-shaped book", exp_v),
    ("fit: exponent, Kyle's flat book", exp_f),
    ("wrong: no factor 2, move in percent", -100.0 * (sv / su) * Q / p0),
    ("wrong: participation in percent, not fraction", 100.0 * sd * sqrt(10.0)),
    ("wrong: annual vol 16% for daily", 100.0 * 0.16 * sqrt(0.1)),
    ("try: noise sd doubled, kyle move %", -100.0 * sv / (4.0 * su) * Q / p0),
    ("try: value sd doubled, kyle move %", -100.0 * 2.0 * sv / (2.0 * su) * Q / p0),
    ("try: 40% of volume, sqrt percent", 100.0 * sd * sqrt(0.4)),
    ("try: Y = 0.5, sqrt percent", 100.0 * 0.5 * sd * sqrt(0.1)),
]
for name, v in rows:
    print(f"{name:<46} {v:>16.4f}")
print()
print("chart: percent of daily volume      1      2      5     10     20     40")
parts = [0.01, 0.02, 0.05, 0.10, 0.20, 0.40]
print("chart: sqrt law, % move        " + "".join(f"{100 * sd * sqrt(p):7.3f}" for p in parts))
print("chart: kyle line, % move       " + "".join(f"{100 * lam * p * Vd / p0:7.3f}" for p in parts))
print("chart: sqrt book walk, $       " + "".join(f"{walk(p * Vd, vshape):7.2f}" for p in parts))

assert abs(lam_bis - lam) < 1e-12 * lam * 1e3, "bisection must land on sigma_v / (2 sigma_u)"
assert abs(lam_mc - lam) < 0.02 * lam,          "the dealer's fitted slope on simulated auctions"
assert abs(best_x - x_ins) < 1e-6,               "brute-force best order equals beta times mispricing"
assert abs(s_ins / n - sv * su / 2.0) < 0.03 * sv * su / 2.0, "simulated insider profit vs formula"
assert abs(sqrt(s_res / n) - sv / sqrt(2.0)) < 0.01 * sv, "half the value variance is left after the auction"
assert abs(s_noise / n + sv * su / 2.0) < 0.03 * sv * su / 2.0, "the crowd loses what the insider gains"
assert abs(s_deal / n) < 0.03 * sv * su / 2.0,  "the dealer breaks even"
assert abs(walk(Q, vshape) - I_sqrt * p0) <= 0.01, "book walk within one cent of the square-root formula"
assert abs(exp_v - 0.5) < 0.05,                 "fitted exponent of the V-shaped book is one half"
assert abs(exp_f - 1.0) < 0.02,                 "fitted exponent of the flat book is one"
print("ALL CHECKS PASS")
