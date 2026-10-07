# Normal quantiles: the 99 percent daily loss level of $1,000,000 in one share.
# Roads: bisection, Newton polish from a rational start, a Simpson check, a seeded simulation.
from math import exp, log, sqrt, pi, cos

MU, SIGMA, W, P = 0.0004, 0.012, 1_000_000.0, 0.01  # daily mean, daily spread, dollars held, tail chance
TABLE_Z = -2.3263478740408408                        # printed tables' value of the 1% point

def phi(z):                                          # standard normal density
    return exp(-z * z / 2) / sqrt(2 * pi)

def Phi(z):                                          # area left of z: 1/2 + phi(z)(z + z^3/3 + z^5/15 + ...)
    term, total, n = z, z, 1
    while abs(term) > 1e-17 * abs(total):
        term *= z * z / (2 * n + 1)
        total += term
        n += 1
    return 0.5 + phi(z) * total

def Phi_simpson(z, n=2000):                          # second road to the area, for z < 0: 1/2 minus the strip z..0
    h = -z / n
    s = phi(z) + phi(0.0) + sum((4 if k % 2 else 2) * phi(z + k * h) for k in range(1, n))
    return 0.5 - s * h / 3

def bisection(p, lo=-6.0, hi=6.0, steps=60):         # keep the half of the bracket where the root lives
    for _ in range(steps):
        mid = (lo + hi) / 2
        if Phi(mid) < p:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2

def newton_step(p, z):                               # slide down the tangent: Phi' = phi
    return z - (Phi(z) - p) / phi(z)

def hastings(p):                                     # Abramowitz and Stegun 26.2.23, lower tail p <= 1/2
    t = sqrt(-2 * log(p))
    num = 2.515517 + 0.802853 * t + 0.010328 * t * t
    den = 1 + 1.432788 * t + 0.189269 * t * t + 0.001308 * t * t * t
    return -(t - num / den), t, num, den

M64 = (1 << 64) - 1
state = 20260928                                     # SplitMix64 seed
def uniform():                                       # strictly between 0 and 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & M64
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & M64
    return (((x ^ (x >> 31)) >> 11) + 0.5) / 2.0 ** 53

def show(label, v, fmt="{:.6f}"):
    print(f"{label:<40} {fmt.format(v + 0.0):>14}")

# ---- the 1% point of the standard normal, three computed roads ----
z_bis = bisection(P)
z_h, t, num, den = hastings(P)
z_n1 = newton_step(P, z_h)
z_n2 = newton_step(P, z_n1)
show("hand: -2 ln p", -2 * log(P))
show("hand: t = sqrt(-2 ln p)", t)
show("hand: numerator", num)
show("hand: denominator", den)
show("hand: numerator / denominator", num / den)
show("1 rational approximation z", z_h)
show("  Phi(rational z)", Phi(z_h), "{:.8f}")
show("2 rational + one Newton step", z_n1, "{:.10f}")
show("  rational + two Newton steps", z_n2, "{:.10f}")
show("3 bisection, 60 halvings", z_bis, "{:.10f}")
show("  Phi(bisection) by series", Phi(z_bis), "{:.12f}")
show("  Phi(bisection) by Simpson", Phi_simpson(z_bis), "{:.12f}")
show("  density phi at the 1% point", phi(z_bis))
show("  1/phi: z moves per unit of p", 1 / phi(z_bis), "{:.4f}")
show("  1/phi at the median", 1 / phi(0.0), "{:.4f}")
show("  rational error", z_h - z_bis, "{:.10f}")
show("  one-Newton-step error", z_n1 - z_bis, "{:.10f}")
z_11 = bisection(0.011)
show("  z at p = 0.011, shift from 1%", z_11 - z_bis)
show("  that shift in dollars", W * SIGMA * (z_11 - z_bis), "{:.2f}")

# ---- stretch and shift to the share, then to dollars ----
x_p = MU + SIGMA * z_bis
loss = -W * x_p
show("return at the 1% point", x_p)
show("99% daily loss level ($)", loss, "{:.2f}")
show("expected breach days in 252", 252 * P, "{:.2f}")

# ---- 4 simulation: 200,000 days by Box-Muller ----
N = 200_000
zs = []
for _ in range(N):
    u1, u2 = uniform(), uniform()
    zs.append(sqrt(-2 * log(u1)) * cos(2 * pi * u2))
zs.sort()
z_sim = zs[N // 100 - 1]
se_q = sqrt(P * (1 - P) / N) / phi(z_bis)
breaches = sum(1 for z in zs if MU + SIGMA * z < x_p)
frac = breaches / N
se_f = sqrt(P * (1 - P) / N)
show("4 simulated 1% point of z", z_sim)
show("  its standard error", se_q)
show("  simulated loss level ($)", -W * (MU + SIGMA * z_sim), "{:.2f}")
show("  days below the formula level", breaches, "{:.0f}")
show("  fraction below it", frac)
show("  its standard error", se_f)

# ---- what breaks ----
show("wrong: z read as percent, no sigma ($)", -W * TABLE_Z / 100, "{:.2f}")
z_two = bisection(0.005)
show("wrong: two-sided z at p = 0.005", z_two)
show("wrong: two-sided loss level ($)", -W * (MU + SIGMA * z_two), "{:.2f}")
show("wrong: rational, unpolished ($)", -W * (MU + SIGMA * z_h), "{:.2f}")
z_bad = newton_step(P, -5.0)
show("wrong: Newton from z = -5, one step", z_bad, "{:.1f}")
show("  density there (next divisor)", phi(z_bad), "{:.1f}")

# ---- confidence ladder and the quantile curve, for the charts ----
print("level     z          loss ($)")
ladder = []
for c in (0.90, 0.95, 0.975, 0.99, 0.995, 0.999):
    zc = bisection(1 - c)
    ladder.append(-W * (MU + SIGMA * zc) / 1000)
    print(f"{c:<8} {zc:>9.6f} {-W * (MU + SIGMA * zc):>12.2f}")
print("chart, loss ($ thousands) " + " ".join(f"{v:.2f}" for v in ladder))
ps = (0.001, 0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 0.999)
print("chart, z at p " + " ".join(f"{round(bisection(p), 2) + 0.0:.2f}" for p in ps))

# ---- try changing ----
show("try: sigma = 0.024 ($)", -W * (MU + 0.024 * z_bis), "{:.2f}")
show("try: 10 days, sigma*sqrt(10) ($)", -W * (10 * MU + SIGMA * sqrt(10) * z_bis), "{:.2f}")
show("try: mean 0 ($)", -W * SIGMA * z_bis, "{:.2f}")

assert abs(z_bis - TABLE_Z) < 1e-9, "bisection must match the printed tables"
assert abs(z_n2 - z_bis) < 1e-12, "Newton from the rational start must meet bisection"
assert abs(Phi_simpson(z_bis) - P) < 1e-10, "Simpson's area at the answer must be 1%"
assert abs(z_h - z_bis) < 4.5e-4, "rational approximation within its stated error"
assert abs(z_sim - z_bis) < 4 * se_q, "simulated quantile within 4 standard errors"
assert abs(frac - P) < 4 * se_f, "breach fraction within 4 standard errors of 1%"
assert z_bad > 100, "unguarded Newton from the far tail must overshoot"
print("ALL CHECKS PASS")
