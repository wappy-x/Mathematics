# Dini's theorem -- the check behind the card.  The example: x^n, the value
# today of $1 paid n years out at a yearly discount factor x.  math's log, exp
# and ceil are primitives; every power, gap and cutoff is built here, and
# the one cutoff for all of [0, 0.9] is reached three ways.
from math import log, exp, ceil
EPS = 0.1
def power(x, n):                          # x multiplied in n times
    out = 1.0
    for _ in range(n):
        out *= x
    return out
def cutoff(x):                            # road one: count until x^n < EPS
    n, v = 1, x
    while v >= EPS:
        n, v = n + 1, v * x
    return n
def bump(x, n):                           # x^n - x^(2n): settles to 0, not monotone
    return power(x, n) - power(x, 2 * n)
def root_poly(t, n):                      # p_0 = 0, p_(k+1) = p_k + (t - p_k^2) / 2
    p = 0.0
    for _ in range(n):
        p += (t - p * p) / 2
    return p

grid = [i / 10000 for i in range(9001)]   # 0, 0.0001, ..., 0.9
for lab, g in (("0.9^n", lambda n: power(0.9, n)), ("[0, 1), gap at x = 1 - 1e-9", lambda n: power(1 - 1e-9, n)),
               ("x^n - x^(2n), gap where x^n = 1/2", lambda n: bump(exp(-log(2) / n), n))):
    print(f"chart {lab}, n = 2, 4, ..., 24:", " ".join(f"{g(n):.2f}" for n in range(2, 25, 2)))
xs = (0.5, 0.8, 0.9, 0.99, 0.999)
count = [cutoff(x) for x in xs]
logs = [ceil(log(EPS) / log(x)) for x in xs]              # road two
print("cutoff for gap 0.1 at x = 0.5, 0.8, 0.9, 0.99, 0.999, by counting:", count)
print("the same cutoffs, by logarithms:", logs)
print("yearly rate for each x, 1/x - 1:", " ".join(f"{100 * (1 / x - 1):.1f}%" for x in xs))
w21, w22 = (max(power(x, n) for x in grid) for n in (21, 22))
print(f"[0, 0.9] worst gap on a 9001-point grid: n=21 {w21:.6f}, n=22 {w22:.6f}")
print(f"formula 0.9^n: n=21 {power(0.9, 21):.6f}, n=22 {power(0.9, 22):.6f}")
top = max(cutoff(x) for x in grid)                         # road three
first = min(x for x in grid if cutoff(x) == top)
print(f"largest pointwise cutoff over the grid: {top}, first needed at x = {first:.4f}")
u21, u22 = exp(log(EPS) / 21), exp(log(EPS) / 22)        # U_n = [0, 0.1^(1/n))
print(f"cover sets U_n = [0, 0.1^(1/n)): U_21 ends at {u21:.6f}, U_22 ends at {u22:.6f}")
wit, near = exp(log(0.5) / 22), [power(x, 22) for x in (0.99, 0.999, 0.9999)]
print(f"[0, 1) at n=22: gaps at x = 0.99, 0.999, 0.9999: {near[0]:.6f} {near[1]:.6f} {near[2]:.6f}")
print(f"  x = {wit:.6f} still has gap {power(wit, 22):.6f}; worst gap 1, never reached")
bg = [max(bump(i / 10000, n) for i in range(10001)) for n in (1, 22)]
peak = [bump(exp(-log(2) / n), n) for n in (1, 22, 1000)]  # where x^n = 1/2
print(f"x^n - x^(2n): grid worst gap n=1 {bg[0]:.6f}, n=22 {bg[1]:.6f}; at x^n = 1/2, n=1, 22, 1000: "
      + " ".join(f"{p:.6f}" for p in peak))
print(f"  at x=0.99: n=1 {bump(0.99, 1):.6f}, n=50 {bump(0.99, 50):.6f}, n=500 {bump(0.99, 500):.6f}")
print(f"step 1 on (0, 1/n), else 0: at n=22 the gap at x = 1/44 is {1.0 if 0 < 1 / 44 < 1 / 22 else 0.0:.0f}")
rg = [max(s - root_poly(s * s, k) for s in (i / 10000 for i in range(10001))) for k in (10, 100)]  # t = s^2
print(f"square-root polynomials, t = (i/10000)^2: worst gap k=10 {rg[0]:.6f}, k=100 {rg[1]:.6f}; "
      f"bound 2/(k+2): {2 / 12:.6f}, {2 / 102:.6f}")
assert count == logs                                       # counting against logarithms
assert abs(w22 - power(0.9, 22)) < 1e-12 and w21 > EPS > w22   # grid against formula
assert top == count[2] and u21 < first <= 0.9 < u22        # grid cutoffs against the cover
assert all(abs(p - 0.25) < 1e-9 for p in peak) and all(abs(b - 0.25) < 1e-6 for b in bg)
assert rg[0] <= 2 / 12 and rg[1] <= 2 / 102                # proved bound holds on the grid
print("ALL CHECKS PASS")
