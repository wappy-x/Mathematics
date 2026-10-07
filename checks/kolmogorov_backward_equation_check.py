# Kolmogorov backward equation -- the check behind the card.  Standard library only.
# u(tau, x) = expected payoff of a $100-strike call, tau years before it pays, share at $x today,
# share moving as Brownian motion with sigma = $20 per root-year.  Roads: the closed-form solution,
# a Simpson average over the bell curve, the coin-flip tree (the backward equation stepped exactly),
# and seeded Monte Carlo (SplitMix64 + Box-Muller, written out).  Then the generalisation (drift,
# a barrier, the house OU rate on 1,000 steps) and the what-breaks numbers.
import math

MASK = (1 << 64) - 1
X0, K, SIG, T, MU, BAR, SEED = 100.0, 100.0, 20.0, 1.0, 5.0, 80.0, 20260930
KAP, THE, R0, SOU = 0.5, 0.04, 0.06, 0.02        # house OU rate: pull, level, start, noise

def ncdf(x):                                    # bell-curve area left of x, by its Taylor series
    term, tot, n = x, x, 0
    while abs(term) > 1e-18:
        n += 1
        term *= -x * x / (2 * n)
        tot += term / (2 * n + 1)
    return 0.5 + tot / math.sqrt(2 * math.pi)

def pdf(x): return math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)
def call(y): return max(y - K, 0.0)
def square(y): return (y - K) * (y - K)

def bach(x, tau, mu=0.0, sig=SIG):              # road 1: the solution of the backward equation
    if tau == 0: return call(x)
    s = sig * math.sqrt(tau); m = x + mu * tau; d = (m - K) / s
    return (m - K) * ncdf(d) + s * pdf(d)

def simpson(pay, x, tau, mu=0.0, n=20000):      # road 2: average pay(x + mu tau + sig root(tau) z)
    a, b = -10.0, 10.0; h = (b - a) / n; s = SIG * math.sqrt(tau)
    g = lambda z: pay(x + mu * tau + s * z) * pdf(z)
    tot = g(a) + g(b)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * g(a + i * h)
    return tot * h / 3

def tree(x, tau, n, mu=0.0, bar=None):          # road 3: u(t,x) = p u(t+h,x+dl) + (1-p) u(t+h,x-dl)
    h = tau / n; dl = SIG * math.sqrt(h); p = 0.5 + 0.5 * mu * math.sqrt(h) / SIG
    v = [call(x + (2 * j - n) * dl) for j in range(n + 1)]
    for k in range(n, 0, -1):
        v = [p * v[j + 1] + (1 - p) * v[j] for j in range(k)]
        if bar is not None:
            v = [0.0 if x + (2 * j - k + 1) * dl <= bar + 1e-9 else v[j] for j in range(k)]
    return v[0]

class SplitMix64:                               # the wing's generator, written out
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                           # Box-Muller, cosine half only
        u1, u2 = 1.0 - self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def mean_se(xs):
    n = len(xs); m = sum(xs) / n
    return m, math.sqrt(sum((x - m) * (x - m) for x in xs) / (n - 1) / n)

print(f"setup: x {X0:.0f}, K {K:.0f}, sigma {SIG:.0f} dollars per root-year, T {T:.0f} year, seed {SEED}")
u, u_s = bach(X0, T), simpson(call, X0, T)
print(f"1 closed form u(1, 100)       {u:.6f}")
print(f"2 Simpson average             {u_s:.6f}")
errs = []
for n in (100, 400, 1600, 6400):
    t = tree(X0, T, n); errs.append(abs(t - u))
    print(f"3 tree n {n:<5} step {T / n:.6f} y, move {SIG * math.sqrt(T / n):.2f}  {t:.6f}  error {t - u:+.6f}")
g = SplitMix64(SEED); M = 200000
zs = [g.normal() for _ in range(M)]
mc, se = mean_se([call(X0 + SIG * math.sqrt(T) * z) for z in zs])
print(f"4 Monte Carlo {M} paths   {mc:.6f}  SE {se:.6f}  gap {(mc - u) / se:+.2f} SE")
print(f"hand: phi(0) {pdf(0):.6f}, N(0.5) {ncdf(0.5):.6f}, phi(0.5) {pdf(0.5):.6f}, half sigma^2 {0.5 * SIG * SIG:.0f}")
print(f"hand x 110: 10 N(0.5) {10 * ncdf(0.5):.6f} + 20 phi(0.5) {20 * pdf(0.5):.6f} = {bach(110.0, T):.6f}")
e1, e2 = 1e-4, 1e-2
u_tau = (bach(X0, T + e1) - bach(X0, T - e1)) / (2 * e1)
u_xx = (bach(X0 + e2, T) - 2 * u + bach(X0 - e2, T)) / (e2 * e2)
print(f"equation at (1, 100): u_tau {u_tau:.6f}, half sigma^2 u_xx {0.5 * SIG * SIG * u_xx:.6f}")
sq, sq_mc = simpson(square, X0, T), mean_se([square(X0 + SIG * math.sqrt(T) * z) for z in zs])
print(f"squared payoff: hand sigma^2 tau {SIG * SIG * T:.6f}, Simpson {sq:.6f}, MC {sq_mc[0]:.6f} SE {sq_mc[1]:.6f}")
ud, ud_s, ud_t = bach(X0, T, MU), simpson(call, X0, T, MU), tree(X0, T, 6400, MU)
print(f"drift 5: formula {ud:.6f}, Simpson {ud_s:.6f}, tree n 6400 {ud_t:.6f}")
ub = u - bach(2 * BAR - X0, T)
ub1, ub2 = tree(X0, T, 1600, bar=BAR), tree(X0, T, 6400, bar=BAR)
print(f"barrier 80: value from 60 {bach(2 * BAR - X0, T):.6f}, reflection {ub:.6f}, tree n 1600 {ub1:.6f}, tree n 6400 {ub2:.6f}")
print(f"breaks: ordinary chain rule {call(X0):.6f} (drift 5: {call(X0 + MU * T):.6f})")
print(f"breaks: generator without the half {bach(X0, T, sig=SIG * math.sqrt(2)):.6f}")
print(f"breaks: drift sign flipped {bach(X0, T, -MU):.6f} (right {ud:.6f})")
print(f"breaks: barrier ignored {u:.6f} (right {ub:.6f})")

def ou2(tau, x):                                # OU: u = E[r_T^2] solves the general backward equation
    m = THE + (x - THE) * math.exp(-KAP * tau)
    return m * m + SOU * SOU * (1 - math.exp(-2 * KAP * tau)) / (2 * KAP)
a, b = 1e-4, 1e-3
lhs = (ou2(T + a, R0) - ou2(T - a, R0)) / (2 * a)
rhs = (KAP * (THE - R0) * (ou2(T, R0 + b) - ou2(T, R0 - b)) / (2 * b)
       + 0.5 * SOU * SOU * (ou2(T, R0 + b) - 2 * ou2(T, R0) + ou2(T, R0 - b)) / (b * b))
print(f"OU: kappa {KAP}, theta {THE}, r0 {R0}, sigma {SOU}; equation at (1, 0.06): u_tau {lhs:.9f}, L u {rhs:.9f}")
g = SplitMix64(SEED + 1); P, NS = 4000, 1000; hh = T / NS; fin = []
for _ in range(P):
    r = R0
    for _ in range(NS): r += KAP * (THE - r) * hh + SOU * math.sqrt(hh) * g.normal()
    fin.append(r)
m1, m2 = mean_se(fin), mean_se([r * r for r in fin])
e_r = THE + (R0 - THE) * math.exp(-KAP * T)
print(f"OU 1,000 steps, {P} paths: E[r_1] formula {e_r:.6f}, MC {m1[0]:.6f} SE {m1[1]:.6f}")
print(f"OU E[r_1^2] formula {ou2(T, R0):.7f}, MC {m2[0]:.7f} SE {m2[1]:.7f}")
for x in range(70, 131, 5):
    print(f"chart, x {x}: tau 1 {bach(float(x), 1.0):.2f}, tau 0.25 {bach(float(x), 0.25):.2f}, payoff {call(float(x)):.2f}")

assert abs(u - u_s) < 1e-9 and abs(sq - SIG * SIG * T) < 1e-6        # formula and square vs Simpson
assert errs[3] < 0.002 and errs[1] < errs[0] / 3 and errs[3] < errs[2] / 3  # tree converges, error ~ step
assert abs(mc - u) < 4 * se and abs(sq_mc[0] - SIG * SIG * T) < 4 * sq_mc[1]
assert abs(u_tau - 0.5 * SIG * SIG * u_xx) < 1e-5 and abs(lhs - rhs) < 1e-9  # the formulas solve the PDEs
assert abs(ud - ud_s) < 1e-9 and abs(ud_t - ud) < 0.005 and abs(ub2 - ub) < 0.005
assert abs(m1[0] - e_r) < 4 * m1[1] and abs(m2[0] - ou2(T, R0)) < 4 * m2[1]
print("all checks passed")
