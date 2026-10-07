# Intervals for a proportion: 45 of 100 recovered.  Wald, Wilson and exact intervals,
# each end by two roads; coverage enumerated and simulated (SplitMix64, seed 20260928).
from math import sqrt, log, exp, pi
M64, N, ALPHA = 2**64 - 1, 100, 0.05

def Phi(z):                               # bell area left of z, Taylor series
    term, total, j = z, z, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        j += 1
        term *= -z * z * (2 * j - 1) / (2 * j * (2 * j + 1))
        total += term
    return 0.5 + total / sqrt(2.0 * pi)

def bisect(f, a, b, steps=200):           # a root of f between a and b
    fa = f(a)
    for _ in range(steps):
        m = 0.5 * (a + b)
        if (f(m) > 0) == (fa > 0): a, fa = m, f(m)
        else: b = m
    return 0.5 * (a + b)

Z = bisect(lambda z: Phi(z) - (1 - ALPHA / 2), 0.0, 5.0)
def pmf(n, p):                            # binomial chances by the ratio rule
    law, q = [1.0], 1.0 - p
    for _ in range(n): law[0] *= q
    for k in range(n): law.append(law[k] * (n - k) / (k + 1) * p / q)
    return law

def wald(k, n):                           # the estimate plus or minus z spreads
    h = Z * sqrt(k / n * (1 - k / n) / n)
    return k / n - h, k / n + h

def wilson(k, n):                         # road one: the quadratic's two roots
    ph, s = k / n, Z * Z / n
    c = (ph + s / 2) / (1 + s)
    h = Z * sqrt(ph * (1 - ph) / n + s / (4 * n)) / (1 + s)
    return c - h, c + h

def wilson_bisect(k, n):                  # road two: where distance = z spreads
    ph = k / n
    g = lambda p: n * (ph - p) ** 2 - Z * Z * p * (1 - p)
    lo = 0.0 if k == 0 else bisect(g, 0.0, ph)
    return lo, bisect(g, ph, 1.0)

def exact_tails(k, n):                    # road one: sum the binomial tails
    up = lambda p: sum(pmf(n, p)[k:]) - ALPHA / 2
    dn = lambda p: sum(pmf(n, p)[:k + 1]) - ALPHA / 2
    return (0.0 if k == 0 else bisect(up, 1e-12, 1 - 1e-12),
            1.0 if k == n else bisect(dn, 1e-12, 1 - 1e-12))

def upper_area(k, n, p, m=2000):          # P(K >= k) as an area, Simpson's rule
    lc = sum(log((n - i) / (i + 1)) for i in range(k)) + log(k)
    f = lambda t: exp(lc + (k - 1) * log(t) + (n - k) * log(1 - t)) if t > 0 else 0.0
    h = p / m
    return h / 3 * (f(0) + f(p) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, m)))
def exact_area(k, n):                     # road two: the same ends by integration
    return (bisect(lambda p: upper_area(k, n, p) - ALPHA / 2, 1e-9, 1 - 1e-9, 60),
            bisect(lambda p: 1 - upper_area(k + 1, n, p) - ALPHA / 2, 1e-9, 1 - 1e-9, 60))

EXACT = [exact_tails(k, N) for k in range(N + 1)]
def exact(k, n): return EXACT[k]

def coverage(method, p, n=N):             # enumerate all 101 counts
    return sum(w for k, w in enumerate(pmf(n, p)) if method(k, n)[0] <= p <= method(k, n)[1])

def pair(label, iv): print(f"{label:<34}{iv[0]:>10.6f}{iv[1]:>10.6f}")
def row(label, v, d=6): print(f"{label:<34}{v:>10.{d}f}")

row("z, the 0.975 point of the bell", Z)
row("  Phi(z), series", Phi(Z))
row("p-hat, 45 of 100", 45 / N)
row("  p-hat (1 - p-hat) / n", 0.45 * 0.55 / N)
row("  estimated spread", sqrt(0.45 * 0.55 / N))
row("  Wald margin, z x spread", Z * sqrt(0.45 * 0.55 / N))
row(f"  z^2 / n, z^2 = {Z * Z:.4f}", Z * Z / N)
w45, wb45, e45, a45 = wilson(45, N), wilson_bisect(45, N), exact_tails(45, N), exact_area(45, N)
row("  Wilson centre", (w45[0] + w45[1]) / 2)
row("  Wilson half-width", (w45[1] - w45[0]) / 2)
pair("Wald 45/100", wald(45, N))
pair("Wilson 45/100, formula", w45)
pair("Wilson 45/100, bisection", wb45)
pair("exact 45/100, tail sums", e45)
pair("exact 45/100, Simpson area", a45)
pair("placebo 35/100, Wald", wald(35, N))
pair("placebo 35/100, Wilson", wilson(35, N))
pair("placebo 35/100, exact", EXACT[35])
pair("rash 0/100, Wald", wald(0, N))
pair("rash 0/100, Wilson, formula", wilson(0, N))
pair("rash 0/100, Wilson, bisection", wilson_bisect(0, N))
pair("rash 0/100, exact, tail sums", EXACT[0])
row("rash 0/100, 1 - 0.025^(1/100)", 1 - exp(log(ALPHA / 2) / N))
pair("rash 1/100, Wald", wald(1, N))
print("coverage, n = 100:   p     Wald  Wilson   exact")
GRID = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10, 0.20, 0.30, 0.40, 0.45, 0.50]
METHODS = (wald, wilson, exact)
cov = [[coverage(m, p) for m in METHODS] for p in GRID]
for p, c in zip(GRID, cov): print(f"{'':<16}{p:>9.2f}{c[0]:>9.4f}{c[1]:>8.4f}{c[2]:>8.4f}")
for i, name in enumerate(("Wald", "Wilson", "exact")): print(f"chart, {name:<11}" + " ".join(f"{c[i]:.2f}" for c in cov))
mirror = [coverage(m, 0.98) for m in METHODS]
print(f"{'mirror, p = 0.98':<25}{mirror[0]:>9.4f}{mirror[1]:>8.4f}{mirror[2]:>8.4f}")
fine = [i / 1000 for i in range(1, 1000)]
lows = [min((coverage(m, p), p) for p in fine) for m in METHODS]
for name, (c, p) in zip(("Wald", "Wilson", "exact"), lows):
    print(f"lowest coverage, {name:<17}{c:>10.4f} at p = {p:.3f}")
low_w = min((coverage(wilson, i / 100000), i / 100000) for i in range(1, 1000))
print(f"{'lowest coverage, Wilson, p < 0.01':<34}{low_w[0]:>10.4f} at p = {low_w[1]:.5f}")
state = 20260928                          # SplitMix64, the same stream as the Rust
def next64():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & M64
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & M64
    return x ^ (x >> 31)
RUNS, P0, hits = 20000, 0.02, [0, 0, 0]
for _ in range(RUNS):                     # one run = one trial of 100 patients
    k = sum((next64() >> 11) / 2**53 < P0 for _ in range(N))
    for i, m in enumerate(METHODS):
        lo, hi = m(k, N)
        hits[i] += lo <= P0 <= hi
sims = [h / RUNS for h in hits]
for name, s, c in zip(("Wald", "Wilson", "exact"), sims, cov[1]):
    se = sqrt(s * (1 - s) / RUNS)
    print(f"simulated, p = 0.02, {name:<7}{s:>10.4f}  se {se:.4f}  (sim - enumerated)/se {(s - c) / se:>5.2f}")
paired = sum(w for j, w in enumerate(pmf(50, 0.45)) if wilson(2 * j, N)[0] <= 0.45 <= wilson(2 * j, N)[1])
row("patients in identical pairs, Wilson", paired, 4)
PS = [0.005 * i for i in range(13)]       # the score picture for 0 of 100
print("chart, p          " + " ".join(f"{p:.3f}" for p in PS))
print("chart, Wilson     " + " ".join(f"{Z * sqrt(p * (1 - p) / N):.3f}" for p in PS))

assert abs(Z - 1.95996398) < 1e-7                                            # printed tables
assert max(abs(x - y) for x, y in zip(w45 + wilson(0, N), wb45 + wilson_bisect(0, N))) < 1e-9
assert max(abs(x - y) for x, y in zip(e45, a45)) < 1e-6                      # sums vs area
assert abs(EXACT[0][1] - (1 - (ALPHA / 2) ** (1 / N))) < 1e-9                # closed form
assert lows[2][0] >= 1 - ALPHA and lows[0][0] < 0.7                          # guarantee, failure
assert max(abs(a - b) for a, b in zip(mirror, cov[1])) < 1e-9                 # p and 1 - p
assert all(abs(s - c) < 4 * sqrt(c * (1 - c) / RUNS) for s, c in zip(sims, cov[1]))
assert low_w[0] < 1 - ALPHA                                                   # Wilson is approximate
assert abs(wald(45, N)[1] - bisect(lambda p: N * (0.45 - p) ** 2 - Z * Z * 0.45 * 0.55, 0.45, 1.0)) < 1e-9
print("ALL CHECKS PASS")
