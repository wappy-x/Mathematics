# Merton's portfolio problem -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the optimiser, the integrator and the random
# numbers are written out here.  Every number quoted on the card is printed below.
from math import exp, log, sqrt, pi, cos

r, mu, sigma, gamma, T, W0 = 0.02, 0.06, 0.20, 2.0, 3.0, 100000.0
p = 1.0 - gamma                                    # the power in U(x) = x^p / p

def merton(mu, r, sigma, gamma):                   # road 1: the formula
    return (mu - r) / (gamma * sigma * sigma)

def g(a):                                          # certainty-equivalent growth rate, constant share a
    return r + a * (mu - r) - 0.5 * gamma * sigma * sigma * a * a

def simpson(f, lo, hi, n=4000):
    h = (hi - lo) / n
    s = f(lo) + f(hi)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(lo + i * h)
    return s * h / 3.0

def phi(z): return exp(-0.5 * z * z) / sqrt(2.0 * pi)

def ce_of(wealth_at):                              # certainty equivalent of W_T(z), z a bell-curve draw
    m = simpson(lambda z: wealth_at(z) ** p * phi(z), -10.0, 10.0)
    return m ** (1.0 / p)

def ce_constant(a):                                # road 2: exact law of a continuously rebalanced account
    return ce_of(lambda z: W0 * exp((r + a * (mu - r) - 0.5 * a * a * sigma * sigma) * T + a * sigma * sqrt(T) * z))

def ce_buy_hold(z):                                # 50/50 at the start, never traded again
    return 0.5 * W0 * exp(r * T) + 0.5 * W0 * exp((mu - 0.5 * sigma * sigma) * T + sigma * sqrt(T) * z)

def golden_max(f, lo, hi, tol=1e-9):               # golden-section search for the top of a hill
    k = (sqrt(5.0) - 1.0) / 2.0
    a, b = lo, hi
    while b - a > tol:
        c, d = b - k * (b - a), a + k * (b - a)
        if f(c) > f(d): b = d
        else: a = c
    return 0.5 * (a + b)

class Rng:                                         # xorshift64* uniforms, Box-Muller normals
    def __init__(self, seed): self.s = seed
    def uniform(self):
        s = self.s
        s ^= s >> 12; s ^= (s << 25) & 0xFFFFFFFFFFFFFFFF; s ^= s >> 27
        self.s = s
        return (((s * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) / 9007199254740992.0
    def normal(self):
        u1, u2 = self.uniform(), self.uniform()
        return sqrt(-2.0 * log(1.0 - u1)) * cos(2.0 * pi * u2)

def monte_carlo(shares, paths=20000, steps=156):   # road 3: weekly rebalancing, simulated
    dt = T / steps
    bank = exp(r * dt) - 1.0
    rng = Rng(20260928)
    sums = [0.0] * (len(shares) + 1)
    for _ in range(paths):
        w = [W0] * len(shares)
        fund, cash = 0.5 * W0, 0.5 * W0            # the buy-and-hold account
        for _ in range(steps):
            ret = exp((mu - 0.5 * sigma * sigma) * dt + sigma * sqrt(dt) * rng.normal()) - 1.0
            for i, a in enumerate(shares):
                w[i] *= 1.0 + a * ret + (1.0 - a) * bank
            fund *= 1.0 + ret; cash *= 1.0 + bank
        for i in range(len(shares)): sums[i] += w[i] ** p
        sums[-1] += (fund + cash) ** p
    return [(s / paths) ** (1.0 / p) for s in sums]

pi_star = merton(mu, r, sigma, gamma)
g_star = r + (mu - r) ** 2 / (2.0 * gamma * sigma * sigma)
ce_star = W0 * exp(g_star * T)                    # from the value function V(0, W0)
pi_golden = golden_max(ce_constant, -1.0, 3.0)
print(f"{'1 formula: share in the fund':<44}{pi_star:>14.6f}")
print(f"{'2 golden search on exact certainty equiv.':<44}{pi_golden:>14.6f}")
print(f"{'hand: gamma sigma^2':<44}{gamma * sigma * sigma:>14.6f}")
print(f"{'hand: premium (mu-r)^2 / (2 gamma sigma^2)':<44}{g_star - r:>14.6f}")
print(f"{'best certainty-equivalent rate g*':<44}{g_star:>14.6f}")
print(f"{'hand: e^(g* T)':<44}{exp(g_star * T):>14.6f}")
print(f"{'account drift r + pi*(mu - r)':<44}{r + pi_star * (mu - r):>14.6f}")
print(f"{'account volatility pi* sigma':<44}{pi_star * sigma:>14.6f}")
print(f"{'certainty equivalent, value function':<44}{ce_star:>14.2f}")
print(f"{'certainty equivalent, Simpson integral':<44}{ce_constant(pi_star):>14.2f}")
print(f"{'  gain over all in the bank':<44}{ce_star - W0 * exp(r * T):>14.2f}")
ce_bh = ce_of(ce_buy_hold)
print(f"{'certainty equivalent, buy and hold 50/50':<44}{ce_bh:>14.2f}")
print(f"{'  shortfall of buy and hold':<44}{ce_star - ce_bh:>14.2f}")
grid = [0.0, 0.25, 0.5, 0.75, 1.0]
mc = monte_carlo(grid)
print("3 Monte Carlo, 20000 paths, weekly rebalancing, 3 years")
for a, c in zip(grid, mc):
    print(f"  share {a:4.2f}   simulated CE {c:10.2f}   exact CE {ce_constant(a):10.2f}")
print(f"  buy and hold 50/50  simulated CE {mc[-1]:10.2f}")
# 4: the HJB equation, derivatives by finite differences, best share by brute-force grid
def V(t, w): return w ** p / p * exp(p * g_star * (T - t))
hjb = []
for t, w in ((0.0, 50000.0), (1.5, 100000.0), (2.9, 200000.0)):
    h, e = 1e-3 * w, 1e-4
    vt = (V(t + e, w) - V(t - e, w)) / (2 * e)
    vw = (V(t, w + h) - V(t, w - h)) / (2 * h)
    vww = (V(t, w + h) - 2 * V(t, w) + V(t, w - h)) / (h * h)
    gen = lambda a: vt + (r + a * (mu - r)) * w * vw + 0.5 * a * a * sigma * sigma * w * w * vww
    best = max((i / 1000.0 for i in range(-1000, 3001)), key=gen)
    hjb.append((t, w, best, gen(best) / abs(vt)))
    print(f"4 HJB at t={t:3.1f}, w={w:9.0f}: best share {best:5.3f}, residual per million {1e6 * gen(best) / abs(vt):6.3f}")
print("chart: certainty-equivalent wealth after 3 years, $ thousands")
chart = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
print("  share " + " ".join(f"{a:7.2f}" for a in chart))
print("  CE    " + " ".join(f"{W0 * exp(g(a) * T) / 1000:7.2f}" for a in chart))
print("bars: Merton share (percent) as one input moves, others as in the example")
for lab, v in (("gamma 1", merton(mu, r, sigma, 1)), ("gamma 2", pi_star), ("gamma 4", merton(mu, r, sigma, 4)),
               ("sigma 15%", merton(mu, r, 0.15, gamma)), ("sigma 30%", merton(mu, r, 0.30, gamma)),
               ("excess 2%", merton(0.04, r, sigma, gamma)), ("excess 6%", merton(0.08, r, sigma, gamma))):
    print(f"  {lab:<10}{100 * v:8.2f}")
print(f"{'wrong: sigma for variance':<44}{(mu - r) / (gamma * sigma):>14.6f}")
print(f"{'wrong: total return for excess':<44}{mu / (gamma * sigma * sigma):>14.6f}")
print(f"{'wrong: aversion dropped (gamma = 1)':<44}{merton(mu, r, sigma, 1):>14.6f}")
print(f"{'try: sigma = 0.10':<44}{merton(mu, r, 0.10, gamma):>14.6f}")
print(f"{'try: mu = 0.10':<44}{merton(0.10, r, sigma, gamma):>14.6f}")
print("story: one year, quarterly rebalancing to 50%, bank 2% a year")
fund, cash = 0.5 * W0, 0.5 * W0
print(f"  start           fund {fund:9.2f}  bank {cash:9.2f}  wealth {W0:9.2f}")
for q, ret in enumerate((0.10, -0.15, 0.05, 0.02), 1):
    fund *= 1.0 + ret; cash *= exp(r / 4.0)
    w = fund + cash
    trade = 0.5 * w - fund
    print(f"  Q{q} fund {100 * ret:+4.0f}%  fund {fund:9.2f}  bank {cash:9.2f}  wealth {w:9.2f}  trade {trade:+9.2f}")
    fund, cash = 0.5 * w, 0.5 * w
assert abs(pi_golden - pi_star) < 1e-6, "numerical optimum vs the formula"
assert abs(ce_constant(pi_star) - ce_star) < 1e-4, "integral vs value function"
assert max(zip(mc, grid))[1] == 0.5 and abs(mc[2] - ce_star) / ce_star < 0.005, "simulation picks 50%"
assert all(abs(b - pi_star) < 1e-3 and abs(res) < 1e-4 for _, _, b, res in hjb), "HJB: same best share everywhere"
print("ALL CHECKS PASS")
