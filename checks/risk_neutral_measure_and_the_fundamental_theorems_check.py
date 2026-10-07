# The fundamental theorems of asset pricing -- the check behind the card.
# Standard library only, and nothing imported that already knows an answer: the
# bell curve, the integrator, the root finder, the trees and the one-period
# markets are written out here.  House market: Acme at S = 100, strike K = 100,
# r = 5%, dividend yield q = 2%, sigma = 20%, T = 1 year, real drift m = 8%.
from math import exp, log, sqrt, pi

S, K, r, q, sig, T, m = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 0.08
DISC, F = exp(-r * T), S * exp((r - q) * T)      # discount factor, forward price
LO, MID, HI = 80.0, 100.0, 125.0                 # the small market's three ends
CLAIM = (0.0, 10.0, 0.0)                         # pays 10 only if Acme ends at 100

def bell(z): return exp(-0.5 * z * z) / sqrt(2.0 * pi)      # bell-curve height

def simpson(f, a, b, n):                         # area under f, by thin slices
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

def ratio(th, z): return exp(-th * sqrt(T) * z - 0.5 * th * th * T)   # dQ/dP

def average(drift, payoff, th=None, vol=sig, n=20000):
    def g(z):                                    # payoff x weight x bell curve
        price = S * exp((drift - 0.5 * vol * vol) * T + vol * sqrt(T) * z)
        return payoff(price) * (1.0 if th is None else ratio(th, z)) * bell(z)
    return simpson(g, -10.0, 10.0, n)

def bisect(f, lo, hi, steps=80):                 # the root, by halving the bracket
    flo = f(lo)
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if flo * f(mid) <= 0.0: hi = mid
        else: lo, flo = mid, f(mid)
    return 0.5 * (lo + hi)

def tree_pricing(n, drift):                      # road 3: backward, pricing chances
    dt = T / n
    u = exp(sig * sqrt(dt)); d = 1.0 / u
    p, disc = (exp(drift * dt) - d) / (u - d), exp(-r * dt)
    v = [max(S * u ** j * d ** (n - j) - K, 0.0) for j in range(n + 1)]
    for step in range(n, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(step)]
    return v[0]

def tree_reweighted(n, real, pricing):           # road 4: real paths, reweighted
    dt = T / n
    u = exp(sig * sqrt(dt)); d = 1.0 / u
    p = (exp(real * dt) - d) / (u - d)           # the real-world up chance
    pq = (exp(pricing * dt) - d) / (u - d)       # the pricing up chance
    logc, total = n * log(1.0 - p), 0.0          # log chance of n downs, under P
    for j in range(n + 1):
        if j:                                    # step the path count along
            logc += log((n - j + 1) / float(j) * p / (1.0 - p))
        loglr = j * log(pq / p) + (n - j) * log((1.0 - pq) / (1.0 - p))
        total += exp(logc + loglr) * max(S * u ** j * d ** (n - j) - K, 0.0)
    return exp(-r * T) * total

def weights(p2):                                 # three-state weights, middle p2
    p3 = (F - LO - (MID - LO) * p2) / (HI - LO)
    return [1.0 - p2 - p3, p2, p3]

def worth(w, c): return DISC * sum(wi * ci for wi, ci in zip(w, c))  # its price

def cost(a, b): return a * S * exp(-q * T) + b * DISC   # a shares, b cash, at T

def edge(claim, sign):                           # sign +1: cheapest copy above the
    best = None                                  # claim; -1: dearest copy below it
    for i in range(-400, 401):                   # search the share holding directly
        a = i / 100.0
        b = max(sign * (c - a * x) for c, x in zip(claim, (LO, MID, HI)))
        v = sign * cost(a, sign * b)
        if best is None or v < best: best = v
    return sign * best

payoff_call, spot_at_T = lambda x: max(x - K, 0.0), lambda x: x
theta = (m + q - r) / sig                        # the price of risk
shift = bisect(lambda th: average(m, spot_at_T, th, sig, 2000) - F, 0.0, 1.0)
C_q, C_p = DISC * average(r - q, payoff_call), DISC * average(m, payoff_call, theta)
tree_q, tree_p = tree_pricing(2000, r - q), tree_reweighted(2000, m, r - q)
wrong_real = DISC * average(m, payoff_call)                      # real odds, bank rate
wrong_disc = exp(-(m + q) * T) * average(r - q, payoff_call)     # discounted at 10%
wrong_noq = DISC * average(r, payoff_call)                       # dividend forgotten
vol15, vol25 = (DISC * average(r - q, payoff_call, None, v) for v in (0.15, 0.25))
pi_up = (F - LO) / (HI - LO)                     # two states, 80 or 125: unique
tick_w, a2 = DISC * 10.0 * pi_up, 10.0 / (HI - LO)
tick_c = cost(a2, -a2 * LO)                      # the same claim, built from shares
p2max = (HI - F) / (HI - MID)                    # three states: the family's edge
band = [worth(weights(p), CLAIM) for p in (0.2, 0.5, 0.8, p2max)]
hi_edge, lo_edge = edge(CLAIM, 1), edge(CLAIM, -1)
zero = weights(0.0)                              # the middle state weighted nothing
rows = [("real-world price drift m", m), ("pricing drift r - q", r - q),
        ("price of risk theta = (m + q - r)/sigma", theta),
        ("  theta again, by solving for the shift", shift), ("forward F = S e^(r-q)T", F),
        ("E^P[S_T], the real drift", average(m, spot_at_T)),
        ("E^Q[S_T], the pricing drift", average(r - q, spot_at_T)),
        ("  E^P[S_T x dQ/dP], reweighted", average(m, spot_at_T, theta)),
        ("dQ/dP at z = +1 and z = -1", ratio(theta, 1.0), ratio(theta, -1.0)),
        ("1 call by Q-average", C_q), ("2 call by P-average x dQ/dP", C_p),
        ("3 call by tree, 2000 steps, Q-chances", tree_q),
        ("4 call by tree, P-paths reweighted", tree_p),
        ("wrong: real odds, bank discount", wrong_real),
        ("wrong: Q-average discounted at m + q", wrong_disc),
        ("wrong: pricing drift r, dividend gone", wrong_noq),
        ("call if sigma were 0.15 or 0.25", vol15, vol25), (),
        ("two states 80/125: weights", 1.0 - pi_up, pi_up),
        ("  claim pays 10 at 125: weights, copy", tick_w, tick_c),
        ("  that copy: shares at T, cash at T", a2, -a2 * LO), (),
        ("three states: weights at middle 0.20", *weights(0.2)),
        ("  at middle 0.50", *weights(0.5)), ("  at middle 0.80", *weights(0.8)),
        ("  at the family's edge", *weights(p2max)),
        ("nudge (5,-9,4) on the share and the claim", *[sum(x * y for x, y in zip((5.0, -9.0, 4.0), v)) for v in ((LO, MID, HI), CLAIM)]),
        ("claim (0,10,0) at middle 0.20/0.50/0.80", *band[:3]),
        ("  at the edge, and cheapest copy above", band[3], hi_edge),
        ("  dearest copy below: hold nothing", lo_edge),
        ("one share at T, under those three",
         *[worth(weights(p), (LO, MID, HI)) for p in (0.2, 0.5, 0.8)]),
        ("zero on the middle state: weights", *zero),
        ("  that claim's price, and its payout", worth(zero, CLAIM), max(CLAIM)), ()]
for line in rows:
    print("" if not line else f"{line[0]:<40}" + "".join(f"{v:>14.6f}" for v in line[1:]))
mids = [70.0 + 10.0 * i for i in range(8)]
def pct(drift, c):                               # chance of landing in a $10 band
    zs = [(log(x / S) - (drift - 0.5 * sig * sig) * T) / (sig * sqrt(T)) for x in (c - 5.0, c + 5.0)]
    return 100.0 * simpson(bell, zs[0], zs[1], 400)
print(f"{'bars, claim price ($)':<34}" + "".join(f"{v:>8.2f}" for v in band))
print(f"{'chart, band centre ($)':<34}" + "".join(f"{c:>8.0f}" for c in mids))
for lab, dr in (("chart, chance under P (%)", m), ("chart, chance under Q (%)", r - q)):
    print(f"{lab:<34}" + "".join(f"{pct(dr, c):>8.2f}" for c in mids))
assert abs(C_q - 9.227005508154) < 1e-9, "Q-average must land on the shelf's call price"
assert abs(C_p - C_q) < 1e-7, "reweighted real-world average must give the same price"
assert abs(shift - theta) < 1e-6, "the solved drift shift must be the price of risk"
assert abs(tree_q - C_q) < 0.005 and abs(tree_p - tree_q) < 1e-8, "both tree roads"
assert abs(tick_w - tick_c) < 1e-9, "unique weights: average equals the copy's cost"
assert abs(hi_edge - band[3]) < 1e-9 and abs(lo_edge) < 1e-12, "the band's two edges"
assert wrong_real > C_q > wrong_disc, "real odds too dear, over-discounting too cheap"
assert min(zero) == 0.0 and min(weights(0.2)) > 0.0, "the edge is not a pricing measure"
assert all(min(weights(p)) > 0 and abs(worth(weights(p), (LO, MID, HI)) - S * exp(-q * T)) < 1e-12 for p in (0.05, 0.2, 0.5, 0.8, 0.87)), "every family member reprices the share"
print("ALL CHECKS PASS")
