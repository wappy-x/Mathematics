# Uniform convergence -- the check behind the card.  The example: x^n on
# [0, 1].  math's log, exp and ceil are primitives; every power, sum and
# cutoff below is built here, and each answer is reached two ways.
from math import log, exp, ceil
TOL = 0.001

def power(x, n):                          # x multiplied in n times
    out = 1.0
    for _ in range(n):
        out *= x
    return out

def cutoff(x):                            # road one: count until x^n < TOL
    n, v = 1, x
    while v >= TOL:
        n, v = n + 1, v * x
    return n

def partial(x, N):                        # S_N(x) = (x/2) + ... + (x/2)^N
    return sum(power(x / 2, k) for k in range(1, N + 1))

def tail(N):                              # M_(N+1) + M_(N+2) + ..., M_k = 1/2^k
    return sum(power(0.5, k) for k in range(N + 1, N + 80))

for n in (1, 5, 50):
    print(f"chart n={n}:", " ".join(f"{power(i / 10, n):.2f}" for i in range(11)))
xs = (0.5, 0.9, 0.99, 0.999)
count = [cutoff(x) for x in xs]
logs = [ceil(log(TOL) / log(x)) for x in xs]            # road two
assert count == logs
print("cutoff for 0.001 at x = 0.5, 0.9, 0.99, 0.999, by counting:", count)
print("the same cutoffs, by logarithms:", logs)
for n in (10, 100, 1000):
    w = exp(-log(2) / n)                  # the input whose n-th power is 1/2
    assert abs(power(w, n) - 0.5) < 1e-9
    print(f"witness n={n}: x = {w:.6f}, x^n = {power(w, n):.6f}, limit there 0")
s65, s66 = (max(power(i / 1000, n) for i in range(901)) for n in (65, 66))
print(f"sup on [0, 0.9]: n=65 {s65:.6f}, n=66 {s66:.6f}; first below 0.001: n={cutoff(0.9)}")
g = max(power(i / 100, 1024) for i in range(100))
print(f"n=1024: grid 0, 0.01, ..., 0.99 max error {g:.6f}; witness error {power(exp(-log(2) / 1024), 1024):.6f}")
print(f"cutoff 688 from x=0.99, used at x=0.999: error {power(0.999, 688):.6f}")
N, pts = 10, [i / 100 - 1 for i in range(201)]
errs = [abs(x / (2 - x) - partial(x, N)) for x in pts]
assert abs(max(errs) - tail(N)) < 1e-12                 # grid max against the M tail
print(f"M-test N=10: tail bound {tail(N):.6f}; grid max error {max(errs):.6f}; at x=1 {errs[-1]:.6f}, at x=-1 {errs[0]:.6f}")
j = next(k for k in range(1, 60) if tail(k) < TOL / 3)
d, x0 = 0.0001, 0.5
move_j = sum(k * power(0.5, k) for k in range(1, j + 1)) * d
budget = 2 * tail(j) + move_j
actual = max(abs(x / (2 - x) - x0 / (2 - x0)) for x in (x0 - d, x0 + d))
assert actual < budget
print(f"three thirds at x0=0.5, delta 0.0001: stage {j}, gap {tail(j):.6f}, move of S_{j} within {move_j:.6f}")
print(f"  error budget {budget:.6f} against tolerance 0.001; actual move of S {actual:.6f}")
bad, t = 0.0, power(0.999, 10)
for _ in range(20000):
    t *= 0.999
    bad += t
print(f"x-dependent bound x^k at x=0.999: tail after 10 terms {bad:.2f}")
print("ALL CHECKS PASS")
