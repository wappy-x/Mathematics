# Value at risk from the profit-and-loss distribution -- the check behind the card.
# Standard library only.  Every number quoted on the card is printed here.
# Roads to the 99% one-day VaR of the house book (P&L normal, mean 0, sd $180,000):
#  (1) the formula -mu + z sigma, with z found by bisection on a normal CDF built from its series;
#  (2) the definition: bisection on the tail area, the tail area found by Simpson's rule on the density;
#  (3) 1,000,000 simulated days from our own random numbers, loss quantile by sorting.
from math import sqrt, exp, log, cos, pi

def N(x):                                   # normal CDF from the Taylor series of the error function
    t = x / sqrt(2.0); term = t; s = t; n = 0
    while abs(term) > 1e-17 * max(1.0, abs(s)):
        n += 1; term *= -t * t / n; s += term / (2 * n + 1)
    return 0.5 + s / sqrt(pi)

def bisect(f, lo, hi):                      # f(lo) < 0 < f(hi), f increasing
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def z_of(alpha): return bisect(lambda x: N(x) - alpha, -10.0, 10.0)

def var_formula(mu, sigma, alpha): return -mu + z_of(alpha) * sigma

def tail_area(ell, mu, sigma, n=4000):      # P(loss > ell) = P(P&L < -ell), Simpson on the P&L density
    a, b = mu - 12.0 * sigma, -ell
    h = (b - a) / n
    f = lambda x: exp(-0.5 * ((x - mu) / sigma) ** 2) / (sigma * sqrt(2.0 * pi))
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

def var_by_tail(mu, sigma, alpha):
    return bisect(lambda ell: (1.0 - alpha) - tail_area(ell, mu, sigma), -mu - 8 * sigma, -mu + 8 * sigma)

class Rng:                                  # 64-bit linear congruential generator, Box-Muller normals
    def __init__(self, seed): self.x = seed
    def u(self):
        self.x = (6364136223846793005 * self.x + 1442695040888963407) % 2**64
        return ((self.x >> 11) + 0.5) / 2.0**53
    def normal(self): return sqrt(-2.0 * log(self.u())) * cos(2.0 * pi * self.u())

def var_sorted(losses, alpha):              # smallest loss level whose share of days at or below it is >= alpha
    s = sorted(losses); k = int(alpha * len(s) - 1e-6) + 1                # k = alpha n rounded up
    return s[k - 1]

# ---- the house book: $10m shares, $5m bonds, 1,000 Acme calls; one-day P&L normal ----
MU, SIG, A = 0.0, 180000.0, 0.99
z99 = z_of(A)
v1 = var_formula(MU, SIG, A)
v2 = var_by_tail(MU, SIG, A)
rng = Rng(20260928)
days = [-(MU + SIG * rng.normal()) for _ in range(1000000)]     # losses = minus the P&L
v3 = var_sorted(days, A)
dens = exp(-0.5 * z99 * z99) / sqrt(2 * pi) / SIG                # density of the loss at the VaR
se3 = sqrt(A * (1 - A) / len(days)) / dens                       # standard error of a sample quantile
exceed = sum(1 for x in days if x > v1) / len(days)

# ---- ten days: add ten simulated days, against the square-root-of-time rule ----
ten = [-sum(SIG * rng.normal() for _ in range(10)) for _ in range(200000)]
v10_sim, v10_rule = var_sorted(ten, A), v1 * sqrt(10.0)

# ---- a lumpy position: lose $1,000,000 with chance 0.5%, else nothing ----
def var_lumpy(alpha): return 0.0 if alpha <= 0.995 + 1e-12 else 1000000.0
lumpy = [1000000.0 if rng.u() < 0.005 else 0.0 for _ in range(200000)]

rows = [
    ("z, 99%", z99), ("  N(z)", N(z99)),
    ("1 VaR 99% 1-day, formula", v1), ("2 VaR 99% 1-day, tail integral", v2),
    ("3 VaR 99% 1-day, 1e6 sim days", v3), ("  standard error of road 3", se3),
    ("  share of sim days past VaR", exceed), ("  tail area at road-1 VaR", tail_area(v1, MU, SIG)),
    ("  road 1 minus road 3", v1 - v3), ("1% quantile of the P&L", MU - z99 * SIG),
    ("sqrt(10)", sqrt(10.0)), ("sqrt(20)", sqrt(20.0)),
    ("VaR 99% / VaR 95%", v1 / var_formula(MU, SIG, 0.95)),
    ("VaR 99.9% / VaR 99%", var_formula(MU, SIG, 0.999) / v1),
    ("VaR 99% 10-day, sqrt rule", v10_rule), ("VaR 99% 10-day, 2e5 sim paths", v10_sim),
    ("mean loss beyond 99% VaR", SIG * exp(-0.5 * z99 * z99) / sqrt(2 * pi) / (1 - A)),
    ("exceedances per 250 days", 250 * (1 - A)),
    ("lumpy: VaR 99%", var_lumpy(0.99)), ("  sim 99%", var_sorted(lumpy, 0.99)),
    ("lumpy: VaR 99.6%", var_lumpy(0.996)), ("  sim 99.6%", var_sorted(lumpy, 0.996)),
    ("wrong: 95% z used", var_formula(MU, SIG, 0.95)),
    ("wrong: 10-day scaled by 10", 10 * v1),
    ("wrong: annual sd, 1-day z", v1 * sqrt(252.0)),
    ("try: mean +5000 a day", var_formula(5000.0, SIG, A)),
    ("try: sd 90000", var_formula(MU, 90000.0, A)),
    ("try: 99.9% 1-day", var_formula(MU, SIG, 0.999)),
]
for name, v in rows:
    print(f"{name:<32} {v:>16.6f}")

print()
print("VaR by confidence, 1 day")
for a in (0.90, 0.95, 0.975, 0.99, 0.995, 0.999):
    print(f"  {100 * a:5.1f}%  z {z_of(a):.6f}   VaR {var_formula(MU, SIG, a):12.2f}")
print("VaR 99% by horizon, sqrt rule")
for h in (1, 5, 10, 20):
    print(f"  {h:>3} days   VaR {v1 * sqrt(h):12.2f}")
print("chart, P&L ($000)    " + " ".join(f"{x:6d}" for x in range(-600, 601, 100)))
print("chart, days/1000/$10k" + " ".join(
    f"{1000 * 1e4 * exp(-0.5 * (1000 * x / SIG) ** 2) / (SIG * sqrt(2 * pi)):6.2f}" for x in range(-600, 601, 100)))

assert abs(z99 - 2.3263478740) < 1e-9, "z against the printed normal table"
assert abs(v2 - v1) < 1e-4, "tail-integral road vs formula road"
assert abs(v3 - v1) < 4 * se3, "simulated quantile within four standard errors"
assert abs(v10_sim - v10_rule) < 0.01 * v10_rule, "ten summed days vs the square-root rule"
assert abs(var_formula(5000.0, SIG, A) - var_by_tail(5000.0, SIG, A)) < 1e-4, "nonzero mean: formula vs tail integral"
assert all(var_sorted(lumpy, a) == var_lumpy(a) for a in (0.99, 0.996)), "lumpy: both sides of the jump"
print("ALL CHECKS PASS")
