# Prospect theory in outline -- the check behind the card.  Standard library only.
# Parameters are Tversky and Kahneman's 1992 median estimates.  The normal CDF, its
# inverse, Simpson's rule and the root finder are written out; nothing imported knows the answer.
from math import exp, sqrt, pi

A, LAM, GP, GM = 0.88, 2.25, 0.61, 0.69     # curvature, loss multiplier, gain and loss weighting

def v(x, lam=LAM):                           # value of a change of x dollars
    return x ** A if x >= 0 else -lam * (-x) ** A

def w(p, g):                                 # decision weight of a chance p
    if p <= 0.0: return 0.0
    if p >= 1.0: return 1.0
    return p ** g / (p ** g + (1 - p) ** g) ** (1 / g)

def cpt(tickets, lam=LAM, gp=GP, gm=GM):     # road 2: rank the tickets, weight cumulative chances
    gains = sorted((t for t in tickets if t[0] > 0), key=lambda t: -t[0])
    losses = sorted((t for t in tickets if t[0] < 0), key=lambda t: t[0])
    total = 0.0
    for side, g in ((gains, gp), (losses, gm)):
        cum = 0.0                            # chance of doing at least this well (gains) or this badly
        for x, p in side:
            total += (w(cum + p, g) - w(cum, g)) * v(x, lam)
            cum += p
    return total

def tickets(x, p, n=20):                     # the prospect "x with chance p, else 0" as n equal tickets
    k = round(p * n)
    return [(x, 1 / n)] * k + [(0.0, 1 / n)] * (n - k)

def phi(z): return exp(-0.5 * z * z) / sqrt(2 * pi)
def Phi(z):                                  # normal CDF by Marsaglia's all-positive series
    if z < -9: return 0.0
    if z > 9: return 1.0
    s, term, n = z, z, 1
    while abs(term) > 1e-17 * abs(s) + 1e-300:
        term *= z * z / (2 * n + 1); s += term; n += 1
    return 0.5 + phi(z) * s
def bisect(f, lo, hi, it=100):               # root of an increasing f between lo and hi
    for _ in range(it):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def simpson(f, a, b, n=4000):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

# ---- the four classic menus (Kahneman and Tversky 1979, problems 3, 4, 3', 4') ----
menus = [("sure +3000", 3000, 1.0), ("80% of +4000", 4000, 0.8), ("20% of +4000", 4000, 0.2),
         ("25% of +3000", 3000, 0.25), ("sure -3000", -3000, 1.0), ("80% of -4000", -4000, 0.8),
         ("20% of -4000", -4000, 0.2), ("25% of -3000", -3000, 0.25)]
road1, road2 = {}, {}
for name, x, p in menus:
    road1[name] = w(p, GP if x > 0 else GM) * v(x)          # road 1: the binary formula
    road2[name] = cpt(tickets(x, p))                         # road 2: twenty ranked tickets
print("inputs: A 0.88, lambda 2.25, gamma 0.61, delta 0.69; fund $10000, mean 8% (+$800), spread 15% ($1500); deposit 4% (+$400)")
print("1979 majorities (percent, N = 95): problem 3 80, problem 4 65, problem 3' 92, problem 4' 58")
print(f"{'menu':<22}{'formula':>14}{'20 tickets':>14}")
for name, _, _ in menus:
    print(f"{name:<22}{road1[name]:>14.6f}{road2[name]:>14.6f}")
ratio = 0.75 ** A                                            # v(3000)/v(4000) = (3/4)^A
brk = [("expected dollars, 80% of +4000", .8 * 4000), ("v(3000)", v(3000)), ("v(4000)", v(4000)), ("(3/4)^0.88", ratio),
       ("w+(0.20)", w(.2, GP)), ("w+(0.25)", w(.25, GP)), ("w-(0.20)", w(.2, GM)), ("w-(0.25)", w(.25, GM)),
       ("w+(0.80)", w(.8, GP)), ("w+(0.20)/w+(0.25)", w(.2, GP) / w(.25, GP)),
       ("w-(0.80)", w(.8, GM)), ("w-(0.20)/w-(0.25)", w(.2, GM) / w(.25, GM)),
       ("w+(0.50)", w(.5, GP)), ("w-(0.50)", w(.5, GM))]
# ---- coin flip: lose $100 on tails; what must heads pay? ----
coin = bisect(lambda X: cpt([(X, .5), (-100.0, .5)]), 100.0, 1000.0)
coin_closed = 100 * (LAM * w(.5, GM) / w(.5, GP)) ** (1 / A)
# ---- the saver: $10,000 in a fund, mean +8%, spread 15%, against a sure +$400 deposit ----
def fund_simpson(M, S, lam=LAM, gp=GP, gm=GM):               # road 1: weighted tails, integrated
    top = v(M + 10 * S)
    gain = simpson(lambda y: w(1 - Phi((y ** (1 / A) - M) / S), gp), 0.0, top)
    loss = simpson(lambda y: w(Phi((-y ** (1 / A) - M) / S), gm), 0.0, top)
    return gain - lam * loss
def fund_tickets(M, S, N=20000):                             # road 2: N equally likely quantiles
    return cpt([(M + S * bisect(lambda z: Phi(z) - (k - .5) / N, -10.0, 10.0, 60), 1 / N)
                for k in range(1, N + 1)])
def ce(V): return V ** (1 / A) if V >= 0 else -(-V / LAM) ** (1 / A)   # sure dollars with value V
F1, F2 = fund_simpson(800.0, 1500.0), fund_tickets(800.0, 1500.0)
brk += [("coin: heads needed, bisection", coin), ("coin: heads needed, closed form", coin_closed),
        ("coin: no weighting", 100 * LAM ** (1 / A)), ("coin: straight lines", 100 * LAM),
        ("fund: Simpson on tails", F1), ("fund: 20000 tickets", F2),
        ("fund: chance of a loss", Phi(-800 / 1500)), ("fund: sure-dollar equal", ce(F1)),
        ("deposit: v(400)", v(400)),
        ("wrong: no weights, 80% of +4000", .8 * v(4000)), ("wrong: no weights, 20% of +4000", .2 * v(4000)),
        ("wrong: no weights, 25% of +3000", .25 * v(3000)),
        ("wrong: 16 ticket weights, total", 16 * w(.05, GP)), ("wrong: 16 tickets weighted apart", 16 * w(.05, GP) * v(4000)),
        ("wrong: coin with no loss multiplier", 100 * (w(.5, GM) / w(.5, GP)) ** (1 / A)),
        ("try: fund, multiplier 1", fund_simpson(800.0, 1500.0, lam=1.0) ** (1 / A)),
        ("try: fund against the deposit", ce(fund_simpson(400.0, 1500.0))),
        ("try: fund, spread 10%", ce(fund_simpson(800.0, 1000.0))),
        ("try: fund, no weighting", ce(fund_simpson(800.0, 1500.0, gp=1.0, gm=1.0)))]
for name, val in brk:
    print(f"{name:<36}{val:>14.6f}")
# ---- chart points ----
xs = [-1000 + 250 * i for i in range(9)]
ps = [0, .05, .1, .2, .3, .4, .5, .6, .7, .8, .9, .95, 1]
print("chart x ($)   " + " ".join(f"{x:>8d}" for x in xs))
print("chart v(x)    " + " ".join(f"{v(x):>8.2f}" for x in xs))
print("chart p       " + " ".join(f"{p:>5.2f}" for p in ps))
print("chart w+(p)   " + " ".join(f"{w(p, GP):>5.2f}" for p in ps))
print("chart w-(p)   " + " ".join(f"{w(p, GM):>5.2f}" for p in ps))

R = road1
assert R["sure +3000"] > R["80% of +4000"] and R["20% of +4000"] > R["25% of +3000"], "gain reversal"
assert R["80% of -4000"] > R["sure -3000"] and R["25% of -3000"] > R["20% of -4000"], "loss reflection"
assert all(abs(road1[k] - road2[k]) < 1e-9 for k in road1), "formula vs ranked tickets"
assert w(.8, GP) < ratio < w(.2, GP) / w(.25, GP), "the reversal's bracket condition"
assert abs(coin - coin_closed) < 1e-6, "bisection vs closed-form break-even"
assert abs(F1 - F2) < 0.05, "fund: integral vs quantile tickets"
assert F1 < v(400), "the deposit outscores the fund"
assert .8 * v(4000) > v(3000), "without weights the certainty effect vanishes"
print("ALL CHECKS PASS")
