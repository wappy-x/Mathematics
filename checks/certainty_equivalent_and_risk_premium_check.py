# Certainty equivalent and risk premium -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Road 1 is each closed form.  Road 2 solves
# u(c) = E[u(W)] by bisection, using only the utility itself.  Road 3 (the fund) is a Monte Carlo
# with its own random numbers.  The normal average is Simpson's rule written out.
from math import log, exp, sqrt, cos, sin, pi

def u_crra(g):                          # constant relative risk aversion; g = 1 is the logarithm
    return (lambda w: log(w)) if g == 1 else (lambda w: w ** (1 - g) / (1 - g))

def u_cara(a):                          # constant absolute risk aversion, the exponential
    return lambda w: -exp(-a * w)

def eu(u, outs):                        # expected utility of a list of (probability, wealth)
    return sum(p * u(w) for p, w in outs)

def bisect(f, lo, hi, n=200):           # a root of an increasing f between lo and hi
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def ce_bisect(u, outs):                 # road 2: find the sure amount with the same utility
    t = eu(u, outs)
    return bisect(lambda c: u(c) - t, min(w for _, w in outs), max(w for _, w in outs))

def ce_crra(g, outs):                   # road 1: the power mean (the geometric mean at g = 1)
    if g == 1: return exp(sum(p * log(w) for p, w in outs))
    return sum(p * w ** (1 - g) for p, w in outs) ** (1 / (1 - g))

def ce_cara(a, outs):                   # road 1 for the exponential: -(1/a) ln E[e^(-aW)]
    return -log(sum(p * exp(-a * w) for p, w in outs)) / a

def arrow_pratt(outs, A=lambda w: 1 / w):   # half of -u''/u' at the mean (1/w for the log), times the variance
    mn = sum(p * w for p, w in outs)
    return 0.5 * A(mn) * sum(p * (w - mn) ** 2 for p, w in outs)

row = lambda name, v, f=".4f": print(f"{name:<40} {v:>12{f}}")

# ---- the coin flip: all of $100 staked, ends at $150 or $50 ----
coin = [(0.5, 150.0), (0.5, 50.0)]
mean = sum(p * w for p, w in coin)
var = sum(p * (w - mean) ** 2 for p, w in coin)
ce1, ce2 = sqrt(150.0 * 50.0), ce_bisect(u_crra(1), coin)
row("mean wealth", mean); row("variance", var, ".2f")
row("E[ln W]", eu(u_crra(1), coin)); row("ln of the mean", log(mean))
row("CE log, geometric mean", ce1); row("CE log, bisection", ce2)
row("risk premium, log", mean - ce1)
row("Arrow-Pratt premium, log", arrow_pratt(coin), ".2f")
assert abs(ce1 - ce2) < 1e-9
print("\nladder: g, CE power mean, CE bisection, premium")
ladder = []
for g in (0, 0.5, 1, 2, 4, 10):
    a_, b_ = ce_crra(g, coin), ce_bisect(u_crra(g), coin)
    ladder.append(a_)
    print(f"  g = {g:<5} {a_:>12.2f} {b_:>12.2f} {mean - a_:>10.2f}")
    assert abs(a_ - b_) < 1e-8
assert all(x > y for x, y in zip(ladder, ladder[1:]))         # more curvature, lower CE: Jensen
assert abs(ladder[3] - 2 / (1 / 150 + 1 / 50)) < 1e-9          # g = 2 is the harmonic mean, 75
row("CE cara a = 0.01", ce_cara(0.01, coin)); row("CE cara, bisection", ce_bisect(u_cara(0.01), coin))
row("premium cara, wealth 100", mean - ce_cara(0.01, coin))
assert abs(ce_cara(0.01, coin) - ce_bisect(u_cara(0.01), coin)) < 1e-9
row("premium cara, wealth 200", 200 - ce_cara(0.01, [(0.5, 250.0), (0.5, 150.0)]))
row("CE log, wealth 200", sqrt(250.0 * 150.0)); row("premium log, wealth 200", 200 - sqrt(250.0 * 150.0))
row("CE log, 10x scale", sqrt(1500.0 * 500.0), ".2f")
assert abs(ce_bisect(u_crra(1), [(0.5, 1500.0), (0.5, 500.0)]) - 10 * ce1) < 1e-9          # power utility scales
assert abs(ce_bisect(u_cara(0.01), [(0.5, 250.0), (0.5, 150.0)]) - 100 - ce_cara(0.01, coin)) < 1e-9  # CARA shifts

# ---- the premium against the stake: exact 100 - sqrt(100^2 - x^2), Arrow-Pratt x^2/200 ----
xs = range(0, 100, 10)
exact = [100 - ce_bisect(u_crra(1), [(0.5, 100.0 + x), (0.5, 100.0 - x)]) if x else 0.0 for x in xs]
print("\nstake x   " + "".join(f"{x:>7}" for x in xs))
print("exact     " + "".join(f"{v:>7.2f}" for v in exact))
print("A-P x^2/200" + "".join(f"{arrow_pratt([(0.5, 100.0 + x), (0.5, 100.0 - x)]):>7.2f}" for x in xs)[1:])
small, ap5 = 100 - ce_bisect(u_crra(1), [(0.5, 105.0), (0.5, 95.0)]), arrow_pratt([(0.5, 105.0), (0.5, 95.0)])
row("stake 5: exact", small); row("stake 5: Arrow-Pratt", ap5)
assert abs(small / ap5 - 1) < 0.01                      # the approximation is exact in the limit

ws = range(50, 160, 10)
print("\nchart W   " + "".join(f"{w:>6}" for w in ws))
print("ln W      " + "".join(f"{log(w):>6.2f}" for w in ws))
print("chord     " + "".join(f"{log(50) + (w - 50) / 100 * (log(150) - log(50)):>6.2f}" for w in ws))

# ---- insurance: wealth $100, a 10% chance of losing $60 ----
risk = [(0.9, 100.0), (0.1, 40.0)]
ce_i, ce_ib = 100 * 0.4 ** 0.1, ce_bisect(u_crra(1), risk)
el = 0.1 * 60
row("insurance CE, closed form", ce_i); row("insurance CE, bisection", ce_ib)
row("most the owner pays, 100 - CE", 100 - ce_i); row("expected loss", el, ".2f")
row("risk premium, insurance", 100 - ce_i - el)
row("Arrow-Pratt, insurance", arrow_pratt(risk))
assert abs(ce_i - ce_ib) < 1e-9
assert log(100 - 8.0) > eu(u_crra(1), risk)                      # insuring at $8.00 beats keeping the risk
row("buy at 8.00: E[ln], insured", log(92.0)); row("E[ln], uninsured", eu(u_crra(1), risk))

# ---- the house fund: gross return lognormal, mean 1.08, spread 0.15; deposit 1.04 ----
m, sd, dep = 1.08, 0.15, 1.04
s2 = log(1 + (sd / m) ** 2); mu = log(m) - s2 / 2
def simpson(f, a=-10.0, b=10.0, n=4000):
    h = (b - a) / n
    tot = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return tot * h / 3
dens = lambda z: exp(-z * z / 2) / sqrt(2 * pi)
R = lambda z: exp(mu + sqrt(s2) * z)
assert abs(simpson(lambda z: R(z) * dens(z)) - m) < 1e-9                  # the fund's mean is 1.08
assert abs(sqrt(simpson(lambda z: (R(z) - m) ** 2 * dens(z))) - sd) < 1e-9 # and its spread 0.15
def ce_fund(g):                          # road 2: Simpson for E[u(R)], then bisection
    t = simpson(lambda z: u_crra(g)(R(z)) * dens(z))
    return bisect(lambda c: u_crra(g)(c) - t, 0.5, 2.0)
row("fund s^2", s2, ".6f"); row("fund mu", mu, ".6f")
ce_f1, ce_f2 = exp(mu), ce_fund(1)
row("fund CE log, closed form", ce_f1); row("fund CE log, Simpson", ce_f2)
seed = 20260928
def rnd():                               # 64-bit linear congruential generator, top 53 bits
    global seed
    seed = (6364136223846793005 * seed + 1442695040888963407) % 2 ** 64
    return ((seed >> 11) + 0.5) / 2 ** 53
acc, n_mc = 0.0, 200000
for _ in range(n_mc // 2):
    r_, t_ = sqrt(-2 * log(rnd())), 2 * pi * rnd()
    acc += log(R(r_ * cos(t_))) + log(R(r_ * sin(t_)))
row("fund CE log, Monte Carlo", exp(acc / n_mc))
assert abs(ce_f1 - ce_f2) < 1e-9
assert abs(ce_f1 - exp(acc / n_mc)) < 1e-3
row("fund premium log, in points", 100 * (m - ce_f1))
row("Arrow-Pratt, fund, in points", 100 * 0.5 * sd ** 2 / m)
g_star = 1 - 2 * (log(dep) - mu) / s2
g_bis = bisect(lambda g: dep - ce_fund(g), 1.5, 8.0, 60)
row("gamma where fund = deposit, closed", g_star); row("gamma where fund = deposit, bisection", g_bis)
assert abs(g_star - g_bis) < 1e-6
row("fund CE g = 2, in percent", 100 * (ce_fund(2) - 1)); row("fund CE g = 6, in percent", 100 * (ce_fund(6) - 1))
