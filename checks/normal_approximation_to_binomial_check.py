# Normal approximation to the binomial -- the check behind the card.
# Only math.sqrt, math.exp and math.pi are imported.  100 fair flips: the
# chance of 60 or more heads.  Three roads: exact counting (Pascal's triangle
# in whole numbers), the bell curve with and without the half-step, and a
# seeded simulation (SplitMix64).  The bell's area Phi is built twice.
from math import sqrt, exp, pi
M64 = 2**64 - 1

def phi(z):                              # bell-curve height
    return exp(-0.5 * z * z) / sqrt(2.0 * pi)

def Phi_series(z):                       # area left of z, Taylor series term by term
    term, total, n = z, z, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 1
        term *= -z * z * (2 * n - 1) / (2 * n * (2 * n + 1))
        total += term
    return 0.5 + total / sqrt(2.0 * pi)

def Phi_simpson(z, m=2000):              # area left of z, Simpson's rule from 0 to z
    h = z / m
    s = phi(0.0) + phi(z) + sum((4 if i % 2 else 2) * phi(i * h) for i in range(1, m))
    return 0.5 + s * h / 3.0

def pascal_row(n):                       # C(n, 0..n) by additions only
    row = [1]
    for _ in range(n):
        row = [a + b for a, b in zip([0] + row, row + [0])]
    return row

def pmf(n, p):                           # binomial chances by the ratio P(k+1)/P(k)
    law = [(1.0 - p) ** n]
    for k in range(n):
        law.append(law[-1] * (n - k) / (k + 1) * p / (1.0 - p))
    return law

def normal_tail(n, p, j, shift):         # P(X >= j) read off the bell, cut at j - shift
    mu, sd = n * p, sqrt(n * p * (1.0 - p))
    return 1.0 - Phi_series((j - shift - mu) / sd)

state = 20260928                         # SplitMix64 with a stated seed
def next64():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

def row(label, v, d=6):
    print(f"{label:<40}{v:>12.{d}f}")

N, J = 100, 60
row("mean n p", N * 0.5, 1)
row("spread sqrt(n p (1-p))", sqrt(N * 0.25), 1)
row("np(1-p), the safety number", N * 0.25, 1)
ways = pascal_row(N)
exact = sum(ways[J:]) / 2**N
print(f"strings with 60+ heads: {sum(ways[J:])} of 2^100")
row("1 exact, counted", exact)
exact_f = sum(pmf(N, 0.5)[J:])
row("  exact, ratio rule", exact_f)
row("z at 59.5", (59.5 - 50) / 5)
row("  Phi(1.9) by series", Phi_series(1.9))
row("  Phi(1.9) by Simpson", Phi_simpson(1.9))
cc, raw, wrong = (normal_tail(N, 0.5, J, s) for s in (0.5, 0.0, -0.5))
row("2 bell, half-step (cut 59.5)", cc)
row("  bell, no half-step (cut 60)", raw)
row("  bell, wrong way (cut 60.5)", wrong)
row("  bell, variance n p (no 1-p)", 1.0 - Phi_series((59.5 - 50) / sqrt(50)))
row("error with half-step", cc - exact)
row("error without half-step", raw - exact)
runs, hits = 200000, 0
for _ in range(runs):                    # one run = 100 flips = 64 + 36 random bits
    heads = bin(next64()).count("1") + bin(next64() >> 28).count("1")
    hits += heads >= J
sim = hits / runs
se = sqrt(sim * (1.0 - sim) / runs)
row(f"3 simulated, {runs} runs", sim)
row("  standard error", se)
row("  (simulated - exact) / se", (sim - exact) / se, 2)
p60 = ways[60] / 2**N
row("P(X = 60) exact", p60)
row("  bell height at 60 / spread", phi(2.0) / 5)
row("  bell area 59.5 to 60.5", Phi_series(2.1) - Phi_series(1.9))
print("growing n, P(X >= 0.6 n):  n  exact  half-step  none  half-step/exact")
for n in (10, 30, 100, 400):
    j = 6 * n // 10
    e = sum(pmf(n, 0.5)[j:])
    h = normal_tail(n, 0.5, j, 0.5)
    print(f"  {n:4d}  {e:.6f}  {h:.6f}  {normal_tail(n, 0.5, j, 0.0):.6f}  {h / e:.3f}")
sk = pmf(100, 0.02)
sk_exact, sk_cc = sum(sk[5:]), normal_tail(100, 0.02, 5, 0.5)
row("bent p=0.02: np(1-p)", 100 * 0.02 * 0.98, 2)
row("  P(X >= 5) exact", sk_exact)
row("  P(X >= 5) bell, half-step", sk_cc)
row("  P(X = 0) exact", sk[0])
row("  bell below -0.5 (impossible counts)", Phi_series((-0.5 - 2) / sqrt(1.96)))
law = pmf(N, 0.5)
print("chart, k      " + " ".join(f"{k:6d}" for k in range(40, 65)))
print("chart, exact  " + " ".join(f"{law[k]:.4f}" for k in range(40, 65)))
print("chart, bell   " + " ".join(f"{phi((k - 50) / 5) / 5:.4f}" for k in range(40, 65)))
print("figure, bar tops y (k=55..65) " + " ".join(f"{210 - 3000 * law[k]:.1f}" for k in range(55, 66)))
print("figure, curve y (x=54.5..65.5) " + " ".join(f"{210 - 3000 * phi((54.5 + i / 2 - 50) / 5) / 5:.1f}" for i in range(23)))
print("figure, cut line x at 59.5", 15 + (59.5 - 54.5) * 30)

assert sum(ways) == 2**N, "Pascal row must hold every string once"
assert abs(exact - exact_f) < 1e-12, "whole-number count vs ratio-rule floats"
assert abs(Phi_series(1.9) - Phi_simpson(1.9)) < 1e-10, "two independent bell areas"
assert abs(cc - exact) < 0.0005, "half-step bell within 0.0005 of the count"
assert abs(raw - exact) > 5 * abs(cc - exact), "half-step must beat the plain cut"
assert abs(sim - exact) < 4 * se, "simulation within four standard errors"
assert abs(sim - raw) > 4 * se, "simulation rules out the uncorrected bell"
assert abs(sk_cc - sk_exact) / sk_exact > 0.2, "bent coin: bell off by over 20%"
print("ALL CHECKS PASS")
