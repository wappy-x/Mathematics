# Taylor's theorem -- the check behind the card.  Nothing is imported.
# Road 1: four Taylor terms for e^0.1 plus the Lagrange remainder, which pins
# e^0.1 inside an interval.  Road 2: e^x found with no series at all, by
# bisection on ln y = x, with ln y built as a Simpson sum of the area under 1/t.

def ln(y, n=2000):                        # area under 1/t from 1 to y, Simpson
    h = (y - 1) / n
    s = 1 + 1 / y + sum((4 if k % 2 else 2) / (1 + k * h) for k in range(1, n))
    return s * h / 3

def exp2(x):                              # road 2: the y whose ln is x
    lo, hi = 0.01, 10.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if ln(mid) < x else (lo, mid)
    return (lo + hi) / 2

def taylor(x, n):                         # road 1: sum of x^k / k!, k = 0..n
    term, total = 1.0, 1.0
    for k in range(1, n + 1):
        term = term * x / k
        total += term
    return total

h = 0.1
p3 = taylor(h, 3)
q = h ** 4 / 24                           # the remainder is e^xi times q
low, high = p3 + q, p3 / (1 - q)          # e^xi >= 1, and e^xi <= e^0.1 solved
e01 = exp2(h)
xi = ln(24 * (e01 - p3) / h ** 4)         # the point Lagrange promises
errs = [exp2(t) - taylor(t, 3) for t in (0.2, 0.1, 0.05)]
p4, r4 = taylor(h, 4), h ** 5 / 120 * high  # next term, e^xi at most high
xs = [-2 + 0.5 * i for i in range(9)]
f = lambda t: abs(t - 0.05)               # a corner inside the interval
d2 = [round((f(t + 0.01) - 2 * f(t) + f(t - 0.01)) / 0.0001, 3) + 0.0 for t in (0.02, 0.08)]
print(f"four terms 1, 0.1, 0.005, {h**3/6:.9f}: P3(0.1) = {p3:.9f}")
print(f"remainder = e^xi x {q:.9f}, so between {q:.9f} and {high - p3:.9f}")
print(f"road 1: e^0.1 in [{low:.9f}, {high:.9f}], ends round to {low:.6f}, {high:.6f}")
print(f"road 2, ln by Simpson then bisection: e^0.1 = {e01:.9f}, rounds to {e01:.6f}")
print(f"true remainder {e01 - p3:.9f}; Lagrange point xi = {xi:.6f}")
print(f"five terms: P4(0.1) = {p4:.9f}, remainder under {r4:.9f}")
print("degree-3 error at h = 0.2, 0.1, 0.05: " + ", ".join(f"{e:.9f}" for e in errs))
print(f"halving h divides it by {errs[0]/errs[1]:.2f}, then {errs[1]/errs[2]:.2f}")
print("chart x: " + ", ".join(f"{t:.1f}" for t in xs))
print("chart e^x: " + ", ".join(f"{exp2(t):.2f}" for t in xs))
print("chart P1: " + ", ".join(f"{taylor(t, 1):.2f}" for t in xs))
print("chart P3: " + ", ".join(f"{taylor(t, 3):.2f}" for t in xs))
nf = sum(h ** k for k in range(4))            # the k! left out
print(f"mistake 1, no factorials: 1 + 0.1 + 0.01 + 0.001 = {nf:.9f}, off by {nf - e01:.9f}")
print(f"mistake 2, e^xi bounded by 1: ceiling {p3 + q:.9f}, below the truth {e01:.9f}")
print(f"mistake 3, four terms, no remainder: {p3:.6f} against {e01:.6f}")
print(f"corner |x - 0.05|: slope at 0 = {(f(1e-6) - f(-1e-6)) / 2e-6:.2f}, P1(0.1) = {f(0) - h:.2f}, f(0.1) = {f(h):.2f}, "
      f"Lagrange needs f'' = {2 * (f(h) - f(0) + h) / h**2:.1f}; f'' at 0.02, 0.08: {d2[0]:.1f}, {d2[1]:.1f}")
assert low <= e01 <= high and p4 < e01 < p4 + r4        # road 1 traps road 2
assert 0 < xi < h                                        # the point lies between 0 and 0.1
assert f"{low:.6f}" == f"{high:.6f}" == f"{e01:.6f}"     # six decimals, both roads
assert all(abs(errs[i] / errs[i + 1] - 16) < 1 for i in range(2))
print("ALL CHECKS PASS")
