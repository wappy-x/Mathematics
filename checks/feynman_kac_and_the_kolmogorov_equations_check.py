# Feynman-Kac on a bet -- the check behind the card.  Standard library only (math).
# A price starts at $100 and wanders as Brownian motion, $20 spread per root-year.
# The bet pays (price - $100) after one year.  Two additions, read as PDE pieces:
# the seller fails at hazard k(x) = 0.001 x per year (a potential), and the bet
# dies if the price touches $90 (an edge, paths stopped).  Roads: closed forms
# (Gaussian tilt; images); the coin-flip tree (the equation stepped); a seeded
# coin-flip walk (the path average); residuals by centred differences.
import math

X0, SIG, T, K, B, BETA = 100.0, 20.0, 1.0, 100.0, 90.0, 0.001

def phi(z): return math.exp(-z * z / 2) / math.sqrt(2 * math.pi)

def ncdf(z):  # N(z) = 1/2 + phi(z) * sum z^(2n+1) / (1*3*...*(2n+1))
    s = t = z; n = 0
    while abs(t) > 1e-17 * abs(s):
        n += 1; t *= z * z / (2 * n + 1); s += t
    return 0.5 + phi(z) * s

def call(x, tau):  # plain expected payoff: the backward equation's solution
    d = (x - K) / (SIG * math.sqrt(tau))
    return (x - K) * ncdf(d) + SIG * math.sqrt(tau) * phi(d)

def hazard(x, tau, beta=BETA):  # potential k(x) = beta x, by the Gaussian tilt
    return math.exp(-beta * x * tau + beta**2 * SIG**2 * tau**3 / 6) * call(x - beta * SIG**2 * tau**2 / 2, tau)

def edge(x, tau): return call(x, tau) - call(2 * B - x, tau)  # images about $90

def corner(x, tau): return (x - B) * tau**-1.5 * math.exp(-(x - B)**2 / (2 * SIG**2 * tau))

def sci(v):
    m, e = f"{v:.2e}".split("e"); return f"{m}e{int(e)}"

def tree(n, pot, edg):  # backward induction: u_i(x) = w(x) * (u(x+d) + u(x-d)) / 2
    h = T / n; d = SIG * math.sqrt(h)
    v = [max(X0 + (2 * j - n) * d - K, 0.0) for j in range(n + 1)]
    for i in range(n - 1, -1, -1):
        nv = []
        for j in range(i + 1):
            x = X0 + (2 * j - i) * d
            w = 0.0 if (edg and x <= B + 1e-9) else (1 - BETA * x * h if pot else 1.0)
            nv.append(w * 0.5 * (v[j] + v[j + 1]))
        v = nv
    return v[0]

MASK = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK; z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

def walk(paths, n, seed):  # the path average, all four bets on the same paths
    rng = SplitMix64(seed); h = T / n; sums = [0.0] * 4; sq = [0.0] * 4
    for _ in range(paths):
        x = 100; w = 1.0; alive = True; bits = 0; left = 0
        for _ in range(n):
            if left == 0: bits = rng.next(); left = 64
            w *= 1 - BETA * x * h
            x += 1 if bits & 1 else -1; bits >>= 1; left -= 1
            if x <= 90: alive = False
        pay = max(x - 100, 0)
        for k, v in enumerate((pay, w * pay, pay if alive else 0, w * pay if alive else 0)):
            sums[k] += v; sq[k] += v * v
    mean = [s / paths for s in sums]
    return mean, [math.sqrt((q / paths - m * m) / paths) for q, m in zip(sq, mean)]

print("Bet: price $100, spread $20 per root-year, pays (price - $100) after 1 year")
print("Hazard k(x) = 0.001 x per year (0.1 per year at $100); knock-out edge at $90")
cf = [call(X0, T), hazard(X0, T), edge(X0, T)]
print(f"closed form, plain (backward equation)   ${cf[0]:.6f}")
print(f"closed form, hazard as potential         ${cf[1]:.6f}")
print(f"closed form, knock-out edge by images    ${cf[2]:.6f}")
sh = BETA * SIG**2 * T**2 / 2; tilt = BETA**2 * SIG**2 * T**3 / 6
print(f"hand: shift ${sh:.6f}, tilt {tilt:.8f}, discount exp(-{BETA*X0*T - tilt:.8f}) = {math.exp(-(BETA*X0*T - tilt)):.6f}")
print(f"hand: plain at $99.80 ${call(X0 - sh, T):.6f}; plain at $80 (mirror) ${call(2*B - X0, T):.6f}")
print("coin-flip tree, step h, plain, hazard, edge, both")
tr = {}
for n in (100, 400, 1600):
    tr[n] = [tree(n, p, e) for p, e in ((0, 0), (1, 0), (0, 1), (1, 1))]
    print(f"  n={n:<5d} h={T/n:.6f}  " + "  ".join(f"{v:.6f}" for v in tr[n]))
orders = [math.log((tr[100][k] - tr[400][k]) / (tr[400][k] - tr[1600][k])) / math.log(4) for k in range(4)]
print("observed order " + "  ".join(f"{p:.3f}" for p in orders))
both = (4 * tr[1600][3] - tr[400][3]) / 3
print(f"both pieces, tree extrapolated to h -> 0  ${both:.6f}")
mean, se = walk(160000, 400, 20261115)
print("coin-flip walk, 160000 paths x 400 steps, seed 20261115: estimate (standard error) vs tree n=400")
for k, name in enumerate(("plain ", "hazard", "edge  ", "both  ")):
    print(f"  {name} {mean[k]:.4f} ({se[k]:.4f})  tree {tr[400][k]:.4f}")
    assert abs(mean[k] - tr[400][k]) < 4 * se[k]
for k in range(3):
    assert abs(tr[1600][k] - cf[k]) < 0.005 and 0.8 < orders[k] < 1.2
def resid(f, x, tau, dx, beta):  # u_tau - 1/2 sigma^2 u_xx + beta x u, centred
    ut = (f(x, tau + dx * 1e-3) - f(x, tau - dx * 1e-3)) / (2 * dx * 1e-3)
    uxx = (f(x + dx, tau) - 2 * f(x, tau) + f(x - dx, tau)) / dx**2
    return ut - 0.5 * SIG**2 * uxx + beta * x * f(x, tau)
for name, f, b in (("hazard", hazard, BETA), ("edge  ", edge, 0.0), ("corner", corner, 0.0)):
    r = [resid(f, 100.0, T, dx, b) for dx in (0.5, 0.25)]
    print(f"residual of {name} at ($100, 1 yr), dx $0.50 and $0.25: {sci(r[0])}  {sci(r[1])}")
    assert 3.5 < r[0] / r[1] < 4.5  # truncation error, falling as dx^2
print(f"edge value at $90 for 1 yr: {edge(B, T):.6f}")
print("what breaks")
frozen = cf[0] * math.exp(-BETA * X0 * T)
print(f"  hazard frozen at today's 0.1 per year    ${frozen:.6f}")
print(f"  potential sign flipped (+k u)           ${hazard(X0, T, -BETA):.6f}")
print(f"  edge as a bouncing wall, not a stop     ${call(X0, T) + call(2*B - X0, T):.6f}")
print(f"  no edge at all                          ${cf[0]:.6f}")
v1 = corner(X0, T)
print(f"  corner solution v at ($100, 1 yr) {v1:.6f}; edge price + v ${cf[2] + v1:.6f}")
print(f"  v at $100 with 0.001 yr left {corner(X0, 1e-3):.6f}; v at $90.20 with 0.0001 yr left {corner(B + 0.2, 1e-4):.1f}")
assert frozen > cf[1] + 0.05 and cf[2] < cf[0]
print("far-edge term in the uniqueness proof, R x 2 phi(z)/z with z = (R - 100)/20")
for R in (150.0, 200.0, 250.0):
    z = (R - X0) / SIG; print(f"  R ${R:.0f}: {sci(R * 2 * phi(z) / z)}")
print("chart: price, plain, hazard, edge (1 year to go)")
for x in range(90, 135, 5):
    print(f"  {x}  {call(x, T):.2f}  {hazard(x, T):.2f}  {edge(x, T):.2f}")
print(f"try: hazard slope 0.002 -> ${hazard(X0, T, 0.002):.6f}; edge at $80 -> ${call(X0, T) - call(60.0, T):.6f}")
kap = 1.11e-4
print(f"copper rod: kappa {sci(kap)} m^2/s, path spread after 10 s {100*math.sqrt(2*kap*10):.2f} cm")
print("ALL CHECKS PASS")
