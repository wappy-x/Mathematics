# Limit superior and inferior -- the check behind the card.  Nothing is imported.
# The reading a_n = (-1)^n + 1/n.  Road one scans a long window for tail sups
# and counts terms past a line; road two is the closed form 1 + 1/(first even
# n from N on).  Then Cauchy-Hadamard for c_n = (2 + (-1)^n)^n, checked against
# the series itself: a grid search for the edge, and a closed-form sum.
M = 4000                                     # the window: places 1 to M
a = [(1 if n % 2 == 0 else -1) + 1 / n for n in range(1, M + 1)]

def tail_sup(N):                             # largest term from place N on, by scanning
    return max(a[N - 1:])

def closed_sup(N):                           # 1 + 1/(first even place from N on)
    return 1 + 1 / (N if N % 2 == 0 else N + 1)

def c(n):                                    # the coefficient (2 + (-1)^n)^n
    return float(3 if n % 2 == 0 else 1) ** n

def series(x, terms=400):
    return sum(c(n) * x ** n for n in range(terms))

def row(vals, d=6):
    return ", ".join(f"{v:.{d}f}" for v in vals)

Ns = [1, 4, 5, 11, 101, 1001]
scan, closed = [tail_sup(N) for N in Ns], [closed_sup(N) for N in Ns]
above = sum(1 for v in a if v > 1.01)
near_top = sum(1 for v in a if v > 0.99)
below = sum(1 for v in a if v < -1.01)
near_floor = sum(1 for v in a if v < -0.99)
b_gap = max((-1) ** n / n for n in range(1001, M + 1)) - min((-1) ** n / n for n in range(1001, M + 1))
roots = [c(n) ** (1 / n) for n in (10, 11, 12, 13)]
edge = max(k for k in range(300, 401) if c(400) * (k / 1000) ** 400 < 1) / 1000
x = 0.3
closed_sum = 1 / (1 - 9 * x * x) + x / (1 - x * x)
print("first six terms:", row(a[:6]))
print("chart, terms n = 1 to 12:", row(a[:12], 2))
print("chart, tail sups N = 1 to 12:", row([tail_sup(N) for N in range(1, 13)], 2) + "; tail inf -1 at every N")
print("tail sups, N = 1, 4, 5, 11, 101, 1001, by scanning:", row(scan))
print("the same, 1 + 1/(first even n from N on):", row(closed))
print(f"terms above 1.01: {above} (n = 2 to 98); above 0.99: {near_top} of {M}")
print(f"terms below -1.01: {below}; below -0.99: {near_floor} (odd n from 101)")
print(f"far along: a_4000 = {a[3999]:.6f}, a_3999 = {a[3998]:.6f}")
print(f"limsup - liminf = 1 - (-1) = 2; for (-1)^n/n, tail gap from 1001 = {b_gap:.6f}")
print("roots |c_n|^(1/n), n = 10 to 13:", row(roots))
print(f"limsup 3, liminf 1, radius 1/3 = {1 / 3:.6f}")
print(f"ratios c_11/c_10 = {c(11) / c(10):.6f}, c_12/c_11 = {c(12) / c(11):.0f}")
print(f"grid search: largest x with term 400 below 1 = {edge:.3f}")
print(f"series at x = 0.3, 400 terms = {series(x):.6f}; 1/(1 - 0.81) + 0.3/(1 - 0.09) = {closed_sum:.6f}")
print(f"at x = 0.34, term 400 = {c(400) * 0.34 ** 400:.1f}")
print(f"mistake 1, radius from liminf 1: at x = 0.5, term 40 = {c(40) * 0.5 ** 40:.0f}")
print(f"mistake 2, sup of the whole list: {max(a):.6f}, not the eventual ceiling 1")
print(f"mistake 3, the midpoint 0 as a limit: a_1000 is {abs(a[999]):.6f} away")
assert all(abs(s - t) < 1e-12 for s, t in zip(scan, closed))   # scan against closed form
assert above == (98 - 2) // 2 + 1 and near_floor == (3999 - 101) // 2 + 1 and below == 0
assert abs(series(x) - closed_sum) < 1e-9                       # series against closed form
assert abs(edge - int(1000 / max(roots)) / 1000) < 1e-12        # grid edge against 1/limsup
assert abs(b_gap - (1 / 1002 + 1 / 1001)) < 1e-12 and max(a[1000:]) - min(a[1000:]) > 1.99
print("ALL CHECKS PASS")
