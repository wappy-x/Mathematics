# Confidence intervals -- the check behind the card.  Standard library only.
# Ten patients' recovery times, in days.  How far can the true mean be from
# their average?  Road 1: the t cutoff by integrating the t density (Simpson).
# Road 2: the same cutoff from the closed-form t area.  Road 3: 20,000 seeded
# simulated wards, counting how often each recipe traps the true mean.
from math import sqrt, pi, exp, log, cos, sin, atan, ceil
from functools import reduce

DAYS = [12, 9, 15, 7, 14, 13, 17, 11, 12, 14]
SIGMA, MU, R, SEED = 3.0, 12.0, 20000, 20260928

def total(xs): return reduce(lambda a, b: a + b, xs, 0.0)   # plain left-to-right float sum

def Phi(z):                                  # bell area left of z, by its Taylor series
    term, total = z, z
    for k in range(1, 200):
        term *= -z * z / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2 * pi)

def simpson(f, a, b, m=4000):                # integral of f from a to b, m even
    h = (b - a) / m
    s = f(a) + f(b) + total((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m))
    return s * h / 3

def gamma_half(k):                           # Gamma(k/2), from Gamma(1/2) = root pi, Gamma(1) = 1
    g = sqrt(pi) if k % 2 else 1.0
    for j in range(2 - k % 2, k, 2):
        g *= j / 2
    return g

def t_area_simpson(x, v):                    # road 1: integrate the t density
    c = gamma_half(v + 1) / (sqrt(v * pi) * gamma_half(v))
    return 0.5 + simpson(lambda u: c * (1 + u * u / v) ** (-(v + 1) / 2), 0.0, x)

def t_area_closed(x, v):                     # road 2: the closed form in th = atan(x / root v)
    th = atan(x / sqrt(v))
    c2, term, total = cos(th) ** 2, 1.0, 1.0
    if v % 2 == 0:
        for j in range(1, v // 2):
            term *= c2 * (2 * j - 1) / (2 * j)
            total += term
        return 0.5 + sin(th) * total / 2
    for j in range(1, (v - 1) // 2):
        term *= c2 * (2 * j) / (2 * j + 1)
        total += term
    return 0.5 + (th + (sin(th) * cos(th) * total if v > 1 else 0.0)) / pi

def cutoff(area, p):                         # bisection: the x with area(x) = p
    lo, hi = 0.0, 10.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if area(mid) < p else (lo, mid)
    return (lo + hi) / 2

n = len(DAYS)
xbar = sum(DAYS) / n
ss = total((x - xbar) ** 2 for x in DAYS)
s = sqrt(ss / (n - 1))
se = s / sqrt(n)
ss_int = n * sum(x * x for x in DAYS) - sum(DAYS) ** 2          # one-pass, exact integers
z = cutoff(Phi, 0.975)
phi_simp = 0.5 + simpson(lambda u: exp(-u * u / 2) / sqrt(2 * pi), 0.0, z)
t1 = cutoff(lambda x: t_area_simpson(x, n - 1), 0.975)
t2 = cutoff(lambda x: t_area_closed(x, n - 1), 0.975)
half_t, half_z, half_zs = t2 * se, z * SIGMA / sqrt(n), z * se
inside = sum(xbar - half_t <= x <= xbar + half_t for x in DAYS)
print(f"data: {DAYS}, n {n}, mean {xbar:.4f} days, squares about the mean {ss:.4f}, s {s:.4f}")
print(f"  one-pass check: sum x = {sum(DAYS)}, n*sum(x^2) - (sum x)^2 = {ss_int}; s^2 = {ss_int / (n * (n - 1)):.6f}")
print(f"  standard error s/root n {se:.4f} days")
print(f"z cutoff Phi^(-1)(0.975) {z:.6f}; Simpson area left of it {phi_simp:.10f}")
print(f"t cutoff, 9 degrees of freedom: road 1 (Simpson) {t1:.6f}, road 2 (closed form) {t2:.6f}")
print(f"t interval: {xbar:.2f} +/- {half_t:.4f} = [{xbar - half_t:.4f}, {xbar + half_t:.4f}] days")
print(f"z interval, sigma known {SIGMA:.0f}: {xbar:.2f} +/- {half_z:.4f} = [{xbar - half_z:.4f}, {xbar + half_z:.4f}]")
print(f"mistake, 1.96 with s: {xbar:.2f} +/- {half_zs:.4f}; patients inside the t interval: {inside} of {n}; a new patient's range is root(n + 1) = {sqrt(n + 1):.4f} times as wide")
for lvl in (0.90, 0.99):
    c = cutoff(lambda x: t_area_closed(x, n - 1), (1 + lvl) / 2)
    print(f"level {lvl:.2f}: t cutoff {c:.4f}, half-width {c * se:.4f} days")
c40 = cutoff(lambda x: t_area_closed(x, 39), 0.975)
print(f"40 patients, same s: t cutoff {c40:.4f}, half-width {c40 * s / sqrt(40):.4f} days; sigma {SIGMA:.0f} known, +/-1 day needs (z sigma / 1)^2 = {(z * SIGMA / 1.0) ** 2:.2f}, so {ceil((z * SIGMA / 1.0) ** 2)} patients")
print("coverage of 'mean +/- 1.96 s/root n', exact from the t area, in percent:")
chart = [(k, 100 * (2 * t_area_closed(z, k - 1) - 1)) for k in (2, 3, 4, 5, 6, 8, 10, 15, 20, 30)]
print("  " + ", ".join(f"n={k}: {c:.2f}" for k, c in chart))
exact_zs = 2 * t_area_closed(z, n - 1) - 1
exact_zs_simp = 2 * t_area_simpson(z, n - 1) - 1

MASK, state = (1 << 64) - 1, SEED
def splitmix():                              # SplitMix64, seed 20260928
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & MASK
    return x ^ (x >> 31)

def unif():                                  # strictly inside (0, 1)
    return ((splitmix() >> 11) + 0.5) / 9007199254740992.0

def normals(k):                              # Box-Muller, k even
    out = []
    for _ in range(k // 2):
        r, a = sqrt(-2 * log(unif())), 2 * pi * unif()
        out += [r * cos(a), r * sin(a)]
    return out

def summary(xs):
    m = total(xs) / len(xs)
    return m, sqrt(total((x - m) ** 2 for x in xs) / (len(xs) - 1)) / sqrt(len(xs))

hit_t = hit_zs = hit_z = 0
figure = []
for r in range(R):
    m, e = summary([MU + SIGMA * g for g in normals(n)])
    hit_t += abs(m - MU) <= t2 * e
    hit_zs += abs(m - MU) <= z * e
    hit_z += abs(m - MU) <= half_z
    if r < 20:
        figure.append((m - t2 * e, m + t2 * e))
hit_exp = 0
for r in range(R):                           # skewed recovery times: exponential, mean 12
    m, e = summary([-MU * log(unif()) for _ in range(n)])
    hit_exp += abs(m - MU) <= t2 * e
cov = [h / R for h in (hit_t, hit_zs, hit_z, hit_exp)]
sem = [sqrt(p * (1 - p) / R) for p in cov]
names = ["t interval", "1.96 with s", "z, sigma known", "t, skewed data"]
print(f"simulation: {R} wards of {n}, true mean {MU:.0f}, sigma {SIGMA:.0f}, seed {SEED}")
for nm, p, e in zip(names, cov, sem):
    print(f"  {nm:15s} covers {p:.4f} +/- {e:.4f}")
print(f"  exact for 1.96 with s: closed form {exact_zs:.4f}, Simpson {exact_zs_simp:.4f}")
misses = sum(not (lo <= MU <= hi) for lo, hi in figure)
for i in range(0, 20, 5):
    print(f"figure, wards {i + 1}-{i + 5}: " + "  ".join(f"{lo:.2f} {hi:.2f}" for lo, hi in figure[i:i + 5]))
print(f"figure, misses among the first 20 wards: {misses}")

assert ss_int == 764 and abs(s * s - 764 / 90) < 1e-12           # two-pass s against exact integers
assert abs(phi_simp - 0.975) < 1e-10                             # series cutoff, integrated area
assert abs(t1 - t2) < 1e-7 and abs(exact_zs - exact_zs_simp) < 1e-9   # two roads to the t area
assert abs(cov[0] - 0.95) < 4 * sem[0] and abs(cov[1] - exact_zs) < 4 * sem[1]
assert 0.95 - cov[3] > 4 * sem[3]                                # skew breaks the promise
print("ALL CHECKS PASS")
