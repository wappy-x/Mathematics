# Backward SDEs in outline -- the check behind the card.  Only math is imported.
# A one-year call on a share at 100, strike 100, volatility 0.20, real drift 0.08.
# Cash lent earns r = 2%; cash borrowed costs R = 6%.  Roads to the hedger's price:
# the Black-Scholes closed form; a Simpson average under Q (the change of measure);
# seeded draws under the real-world P, reweighted by the density; replication backward
# on a tree; the semilinear PDE (nonlinear Feynman-Kac) solved backward on a grid.
import math

S0, K, K2, SIG, T, MU = 100.0, 100.0, 110.0, 0.20, 1.0, 0.08
LEND, BORROW, N = 0.02, 0.06, 50
THETA = (MU - LEND) / SIG                     # market price of risk


def ncdf(x):                                  # Marsaglia: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    s, t, k = x, x, 1
    while abs(t) > 1e-17:
        t *= x * x / (2 * k + 1)
        s += t
        k += 1
    return 0.5 + s * math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)


def bs(rate, k):                              # Black-Scholes call, one year, at one rate
    d1 = (math.log(S0 / k) + (rate + 0.5 * SIG * SIG) * T) / (SIG * math.sqrt(T))
    return S0 * ncdf(d1) - k * math.exp(-rate * T) * ncdf(d1 - SIG * math.sqrt(T))


def pay(kind, s):                             # 0 call, 1 short call, 2 call spread 100/110, 3 short 110 call
    c1, c2 = max(s - K, 0.0), max(s - K2, 0.0)
    return [c1, -c1, c1 - c2, -c2][kind]


def tree(kind, n, lend, borrow):              # replicate backward: shares and cash, two states, two unknowns
    h = T / n
    a = SIG * math.sqrt(h)
    y = [pay(kind, S0 * math.exp(a * (2 * j - n))) for j in range(n + 1)]
    lends = borrows = 0
    for m in range(n - 1, -1, -1):
        for j in range(m + 1):
            s = S0 * math.exp(a * (2 * j - m))
            su, sd = s * math.exp(a), s * math.exp(-a)
            delta = (y[j + 1] - y[j]) / (su - sd)      # shares held: the hedge
            cash = y[j + 1] - delta * su               # cash at the next date, same in both states
            lends, borrows = lends + (cash > 0), borrows + (cash < 0)   # nodes with no cash count as neither
            y[j] = delta * s + cash * math.exp(-(lend if cash >= 0 else borrow) * h)
    return y[0], lends, borrows


def pde(kind, lend, borrow, m=200, dx=0.01, steps=1000):   # u_t + s^2 sig^2 u_ss/2 + rho(s u_s - u) = 0
    dt, v = T / steps, [pay(kind, S0 * math.exp((i - m) * dx)) for i in range(2 * m + 1)]
    for _ in range(steps):
        w = v[:]
        for i in range(1, 2 * m):
            ux = (v[i + 1] - v[i - 1]) / (2 * dx)
            uxx = (v[i + 1] - 2 * v[i] + v[i - 1]) / (dx * dx)
            rho = lend if v[i] - ux >= 0 else borrow    # cash = u - s u_s; its sign picks the rate
            w[i] = v[i] + dt * (0.5 * SIG * SIG * uxx + (rho - 0.5 * SIG * SIG) * ux - rho * v[i])
        w[0] = w[1] - (w[2] - w[1]) * math.exp(-dx)     # straight line in s at both ends
        w[2 * m] = w[2 * m - 1] + (w[2 * m - 1] - w[2 * m - 2]) * math.exp(dx)
        v = w
    return v[m]


class Rng:                                    # SplitMix64, then Box-Muller
    def __init__(self, seed):
        self.state, self.spare = seed, None

    def uniform(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) % 2**64
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
        return (((z ^ (z >> 31)) >> 11) + 1) / 9007199254740992.0

    def normal(self):
        if self.spare is not None:
            z, self.spare = self.spare, None
            return z
        r, a = math.sqrt(-2 * math.log(self.uniform())), 2 * math.pi * self.uniform()
        self.spare = r * math.sin(a)
        return r * math.cos(a)


f = lambda x: f"{x:.4f}"
bs_r, bs_R, bs_mid = bs(LEND, K), bs(BORROW, K), bs(0.5 * (LEND + BORROW), K)
d1 = (math.log(S0 / K) + (MU + 0.5 * SIG * SIG) * T) / SIG
real = math.exp((MU - LEND) * T) * S0 * ncdf(d1) - K * math.exp(-LEND * T) * ncdf(d1 - SIG)
print("closed form: call at r", f(bs_r), "at R", f(bs_R), "at 4%", f(bs_mid), "| no change of measure", f(real))
zs = [-8 + 16 * i / 4000 for i in range(4001)]                 # Simpson over the bell curve, under Q
g = [max(S0 * math.exp((LEND - 0.5 * SIG * SIG) * T + SIG * z) - K, 0.0) * math.exp(-0.5 * z * z) for z in zs]
simpson = sum(gi * (1 if i in (0, 4000) else 4 if i % 2 else 2) for i, gi in enumerate(g)) * (16 / 4000) / 3
simpson *= math.exp(-LEND * T) / math.sqrt(2 * math.pi)
print("linear BSDE, Y_0 = E^Q[e^(-rT) xi] by Simpson:", f(simpson))
rng, n, s1, s2, p1 = Rng(20261123), 200000, 0.0, 0.0, 0.0
for _ in range(n):
    w = rng.normal()                                           # W_T under P, T = 1
    x = math.exp(-LEND * T) * max(S0 * math.exp((MU - 0.5 * SIG * SIG) * T + SIG * w) - K, 0.0)
    y = x * math.exp(-THETA * w - 0.5 * THETA * THETA * T)       # reweight by the density dQ/dP
    s1, s2, p1 = s1 + y, s2 + y * y, p1 + x
mc, se = s1 / n, math.sqrt((s2 / n - (s1 / n) ** 2) / n)
print("draws under P, theta", f(THETA), "reweighted:", f(mc), "+-", f(se), "| not reweighted:", f(p1 / n))
h = T / N
u, dd = math.exp(SIG * math.sqrt(h)), math.exp(-SIG * math.sqrt(h))
s = S0 * u                                                     # hand step: node at step 49, price 100u
su, sd = s * u, s * dd
delta = (max(su - K, 0) - max(sd - K, 0)) / (su - sd)
cash = max(su - K, 0) - delta * su
print("hand step: u", f(u), "s", f(s), "su", f(su), "sd", f(sd), "payoffs", f(max(su - K, 0)), f(max(sd - K, 0)))
print("  delta", f(delta), "cash", f(cash), "borrow today", f(cash * math.exp(-BORROW * h)),
      "Y", f(delta * s + cash * math.exp(-BORROW * h)), "| at r", f(delta * s + cash * math.exp(-LEND * h)))
q = (math.exp(BORROW * h) - dd) / (u - dd)
print("  same Y as a reweighted average: q", f(q), "Y", f(math.exp(-BORROW * h) * q * max(su - K, 0)))
t_lin, _, _ = tree(0, N, LEND, LEND)
t_sell, lends, borrows = tree(0, N, LEND, BORROW)
t_buy, blends, bborrows = tree(1, N, LEND, BORROW)
print("tree 50 steps: linear at r", f(t_lin), "| seller two rates", f(t_sell), "lending nodes", lends, "borrowing", borrows)
print("  buyer two rates (hedges the short call)", f(-t_buy), "lending nodes", blends, "borrowing", bborrows)
print("  seller minus buyer", f(t_sell + t_buy), "| linear at 4%", f(tree(0, N, 0.04, 0.04)[0]))
big = [tree(k, 1000, LEND, BORROW)[0] for k in (0, 2, 3)]
grid = [pde(0, LEND, BORROW), pde(0, LEND, LEND), pde(2, LEND, BORROW)]
print("tree 1000 steps, two rates: call", f(big[0]), "spread", f(big[1]))
print("PDE grid: call two rates", f(grid[0]), "call linear at r", f(grid[1]), "spread two rates", f(grid[2]))
sp_r, sp_R = bs(LEND, K) - bs(LEND, K2), bs(BORROW, K) - bs(BORROW, K2)
print("spread linear at r", f(sp_r), "at R", f(sp_R), "| parts priced apart", f(big[0] + big[2]))
rates = [0.02 + 0.01 * i for i in range(9)]
print("chart, borrow %     ", " ".join(f"{100 * x:.0f}" for x in rates))
print("chart, tree seller  ", " ".join(f"{tree(0, N, LEND, x)[0]:.2f}" for x in rates))
print("chart, closed form R", " ".join(f"{bs(x, K):.2f}" for x in rates))
assert abs(bs_r - 8.916) < 5e-4 and abs(simpson - bs_r) < 1e-4       # change of measure = closed form
assert abs(mc - bs_r) < 4 * se and abs(p1 / n - real) < 0.2         # density reweighting finds Q's price
assert abs(t_lin - bs_r) < 0.05 and abs(big[0] - bs_R) < 0.005     # tree converges to both closed forms
assert lends == 0 and bborrows == 0 and abs(-t_buy - t_lin) < 1e-9  # seller always borrows, buyer always lends
assert abs(grid[0] - bs_R) < 0.01 and abs(grid[1] - bs_r) < 0.01   # nonlinear Feynman-Kac: PDE = BSDE
assert abs(grid[2] - big[1]) < 0.01 and big[1] > max(sp_r, sp_R) + 0.01  # comparison: above both linear prices
assert t_sell > t_lin + 2 and big[0] + big[2] > big[1] + 0.01        # nonlinear: the parts do not add
print("ALL CHECKS PASS")
