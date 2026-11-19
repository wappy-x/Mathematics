# Big O and twiddle -- the check behind the card.  Standard library only:
# math supplies log and nothing else.  Every number on the card is printed.
# Roads: the harmonic sum H(x), added term by term, against log x + gamma and
# the proved bound 1/(2x); Euler's constant gamma, quoted from a table, against
# a rebuild that cancels the 1/(2x) term; the divisor sum D(x) by a sieve and by
# Dirichlet's floor count; the prime count pi(x) by Eratosthenes against x/log x
# and the explicit bounds of Rosser and Schoenfeld (1962), at every x to X.
from math import log

X = 10**6
GAMMA = 0.5772156649015329               # Euler's constant, quoted from OEIS A001620

def ff(v, d):
    return f"{v:.{d}f}"

# ---- road 1: H(n) added term by term, compensated so no digits are lost ----
h = comp = 0.0
H, bound_ok, real_ok, below = {}, True, True, (0.0, 0)
for n in range(1, X + 1):
    y = 1.0 / n - comp
    t = h + y
    comp = (t - h) - y
    h = t
    err = h - log(n) - GAMMA             # the error term after log n + gamma
    bound_ok = bound_ok and 0.0 < err < 0.5 / n
    if n > 1:                            # real x just below n: the sum is still H(n - 1)
        v = err * n - 1                  # (H - log x - gamma) * x as x rises to n
        real_ok = real_ok and -1 < v < -0.5
        below = min(below, (v, n))
    if n in (10, 1000, 2000, X) or n & (n - 1) == 0:
        H[n] = h
gap = lambda n: H[n] - log(n)
print("harmonic sum H(x) = 1 + 1/2 + ... + 1/x; log is the natural log; gamma =", ff(GAMMA, 10))
print(f"x = {X}: H(x) = {ff(H[X], 10)}, log x = {ff(log(X), 10)}, log x + gamma = {ff(log(X) + GAMMA, 10)}")
print(f"claim ladder at x = 10, 1000, {X}:")
xs = (10, 1000, X)
print("  H/log x:", ", ".join(ff(H[x] / log(x), 6) for x in xs))
print("  H - log x:", ", ".join(ff(gap(x), 9) for x in xs))
# the leftover is a difference of two numbers near 14: only 8 significant digits survive it
print("  H - log x - gamma:", ", ".join(ff(gap(x) - GAMMA, 7 + len(str(x))) for x in xs))
print("  (H - log x - gamma) * x:", ", ".join(ff((gap(x) - GAMMA) * x, 8) for x in xs), "; proved bound 0.5")
print(f"0 < H(n) - log n - gamma < 1/(2n) for every n from 1 to {X}: {'yes' if bound_ok else 'no'}")
print(f"real x just below each whole number 2 to {X}: -1 < (H - log x - gamma) * x < -1/2: "
      f"{'yes' if real_ok else 'no'}; lowest {ff(below[0], 4)}, just below x = {below[1]}")
pts = [2**k for k in range(11)]
print(f"figure, n, H - log n, gamma + 1/(2n); gamma line {ff(GAMMA, 4)}:",
      " | ".join(f"{n} {ff(gap(n), 4)} {ff(GAMMA + 0.5 / n, 4)}" for n in pts))
rebuilt = 2 * gap(2000) - gap(1000)      # a(n) = gamma + 1/(2n) + ..., so the 1/(2n) cancels
print(f"gamma rebuilt as 2 a(2000) - a(1000) = {ff(rebuilt, 10)}; a(1000) alone {ff(gap(1000), 10)}")

# ---- road 2: the divisor sum, by a sieve and by Dirichlet's floor count ----
tau = [0] * (X + 1)
for d in range(1, X + 1):
    for m in range(d, X + 1, d):
        tau[m] += 1
D, run, sandwich = sum(tau), 0, True
for x in range(1, X + 1):
    run += tau[x]
    sandwich = sandwich and x * log(x) - x < run <= x * log(x) + x
floor_count = sum(X // d for d in range(1, X + 1))
top = max(tau)
print(f"divisor sum D(x) = tau(1) + ... + tau(x) at x = {X}: sieve {D}, floor count {floor_count}")
print(f"  x log x = {ff(X * log(X), 3)}, D - x log x = {ff(D - X * log(X), 2)}, (2 gamma - 1) x = {ff((2 * GAMMA - 1) * X, 2)}")
print(f"  x log x - x < D(x) <= x log x + x at every x from 1 to {X}: {'yes' if sandwich else 'no'}")
print(f"  average D/x = {ff(D / X, 6)}; largest tau {top}, first at {tau.index(top)}; tau(999983) = {tau[999983]}")

# ---- road 3: the prime count by Eratosthenes, against x/log x ----
sieve = bytearray([1]) * (X + 1)
sieve[0] = sieve[1] = 0
for p in range(2, int(X**0.5) + 1):
    if sieve[p]:
        sieve[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
pi, cnt, lo, hi, rs_ok, at = {}, 0, (9.0, 0), (0.0, 0), True, {}
for x in range(2, X + 1):
    cnt += sieve[x]
    L = log(x)
    s = (cnt - x / L) * L * L / x        # the error over x/log^2 x
    if x >= 59:
        lo, hi = min(lo, (s, x)), max(hi, (s, x))
        rs_ok = rs_ok and 0.5 < s < 1.5
    if x in (58, 1000, 10**4, 10**5, X):
        pi[x], at[x] = cnt, s
print("prime count pi(x) by the sieve of Eratosthenes:")
for x in (1000, 10**4, 10**5, X):
    m = x / log(x)
    print(f"  x = {x}: pi {pi[x]}, x/log x {ff(m, 2)}, ratio {ff(pi[x] / m, 4)}, "
          f"gap {ff(pi[x] - m, 2)}, gap/(x/log^2 x) {ff(at[x], 4)}")
print(f"  gap/(x/log^2 x) from x = 59 to {X}: min {ff(lo[0], 4)} at {lo[1]}, max {ff(hi[0], 4)} at {hi[1]}; proved 0.5 to 1.5")

# ---- what breaks, and where it is used ----
print(f"mistake, gamma dropped: (H - log x) * x = {ff(gap(X) * X, 1)} at x = {X}, and growing")
print(f"mistake, log2 in the main term: H(x)/log2 x = {ff(H[X] / (log(X) / log(2)), 4)}, heading to log 2 = {ff(log(2), 4)}")
print(f"mistake, bound used below x = 59: at x = 58, pi = {pi[58]}, gap/(x/log^2 x) = {ff(at[58], 4)}")
qs = lambda n, Hn: 2 * (n + 1) * Hn - 4 * n                     # quicksort's average comparisons
H8 = sum(1 / k for k in range(1, 9))
approx = 2 * X * log(X) - (4 - 2 * GAMMA) * X
print(f"quicksort average 2(n+1)H(n) - 4n: n = 8: {ff(qs(8, H8), 4)}; n = {X}: {ff(qs(X, H[X]), 1)}")
print(f"  2n log n - (4 - 2 gamma) n = {ff(approx, 1)}; difference {ff(qs(X, H[X]) - approx, 3)}; "
      f"2 log n + 2 gamma + 1 = {ff(2 * log(X) + 2 * GAMMA + 1, 3)}")
print(f"near 2^1024: log x = {ff(1024 * log(2), 2)}, so 1 number in {round(1024 * log(2))} is prime, 1 odd number in {round(512 * log(2))}")

assert bound_ok                                              # proved error bound, met by the sum
assert abs(rebuilt - GAMMA) < 1e-7                           # gamma two ways
assert D == floor_count == 13970034 and sandwich             # two counts, inside the proved sandwich
assert [pi[x] for x in (1000, 10**4, 10**5, X)] == [168, 1229, 9592, 78498]   # published counts
assert rs_ok and at[58] < 0.5                                # proved range holds from 59, fails at 58
assert abs((qs(X, H[X]) - approx) - (2 * log(X) + 2 * GAMMA + 1)) < 1e-3
assert real_ok                                               # real x: C = 1 holds, C = 1/2 fails
print("ALL CHECKS PASS")
