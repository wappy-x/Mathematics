# Cancellation and safe formulas -- the check behind the card.  Standard library only.
# Three jobs: the roots of x^2 - 100000000x + 1, the spread of four weighings,
# and a total of one million 0.1s.  Each unsafe formula is run beside a safe one,
# and both are measured against a road that does not share their arithmetic.
from math import sqrt, log10, cos, sin, isqrt, ulp

def sci(x, p):                        # 7.450580596923828e-9, the same in Rust
    m, e = f"{x:.{p}e}".split("e")
    return f"{m}e{int(e)}"

def naive_roots(a, b, c):             # the school formula, both signs as written
    r = sqrt(b * b - 4 * a * c)
    return (-b + r) / (2 * a), (-b - r) / (2 * a)

def safe_roots(a, b, c):              # add like signs only, then roots multiply to c/a
    r = sqrt(b * b - 4 * a * c)
    q = -(b - r) / 2 if b < 0 else -(b + r) / 2
    return q / a, c / q

def bisect_small(b):                  # road 2: halve [0, 2/b] on f(x) = x(x - b) + 1
    lo, hi = 0.0, 2.0 / b
    for _ in range(200):
        mid = (lo + hi) / 2
        if mid * (mid - b) + 1 > 0: lo = mid
        else: hi = mid
    return (lo + hi) / 2

def digits(x, ref):                   # correct significant digits, capped at 16
    e = abs(x - ref) / ref
    return 16.0 if e < 1e-16 else 0.0 if e >= 1 else min(16.0, -log10(e))

def exact_small(k):                   # road 4: 2/(B + sqrt(B^2 - 4)), B = 10^k, in whole
    B, S = 10 ** k, 10 ** (19 - k)    # numbers; the one rounding is the final division
    return 2 * S / (B * S + isqrt((B * B - 4) * S * S))

a, b, c = 1.0, -1e8, 1.0
D = b * b - 4 * a * c
r = sqrt(D)
nbig, nsmall = naive_roots(a, b, c)
sbig, ssmall = safe_roots(a, b, c)
bis = bisect_small(-b)
series = (1 / -b) * (1 + 1 / (b * b))     # road 3: x = (1/B)(1 + 1/B^2 + ...), B = -b
true_gap = 2 * bis                        # what -b - sqrt(D) should have been
rel = abs(nsmall - bis) / bis
kappa = (abs(b) + r) / true_gap           # condition number, true difference
eps = 2.0 ** -52
wrong_big = c / (-(b + r) / 2)            # safe recipe with the sign flipped
print("quadratic,x^2 - 100000000x + 1")
print(f"discriminant,{D:.1f}")
print(f"sqrt stored,{r:.10f}")
print(f"gap -b - sqrt stored,{sci(-b - r, 15)}")
print(f"gap true,{sci(true_gap, 15)}")
print(f"naive roots,{nbig:.1f},{sci(nsmall, 15)}")
print(f"safe roots,{sbig:.1f},{sci(ssmall, 15)}")
print(f"bisection small root,{sci(bis, 15)}")
print(f"series small root,{sci(series, 15)}")
print(f"naive small root error,{rel * 100:.2f}%")
print(f"kappa,{sci(kappa, 3)}")
print(f"bound kappa*eps/2,{kappa * eps / 2:.2f}")
print(f"wrong sign big root,{wrong_big:.1f}")
assert abs(ssmall - bis) / bis < 4e-16     # safe formula meets bisection
assert abs(series - bis) / bis < 4e-16     # and the series
assert 0.25 < rel < 0.26                  # a quarter of the small root is lost
assert rel <= kappa * eps / 2             # and the loss sits inside the kappa bound
assert abs(sbig * bis - c / a) < 4e-16 and wrong_big == 2.0 ** 27   # big root x bisection
for k in range(1, 10):
    B = 10.0 ** k
    ref = exact_small(k)
    print(f"digits,B=1e{k},{digits(naive_roots(1.0, -B, 1.0)[1], ref):.1f},"
          f"{digits(safe_roots(1.0, -B, 1.0)[1], ref):.1f}")
assert digits(safe_roots(1.0, -1e9, 1.0)[1], exact_small(9)) > 15

def add(xs):                          # plain left-to-right float sum (Python's sum()
    t = 0.0                           # compensates since 3.12, so it is not used)
    for x in xs: t += x
    return t

def shortcut(xs):                     # mean of squares minus squared mean
    n = len(xs); m = add(xs) / n
    return add(x * x for x in xs) / n - m * m

def two_pass(xs):                     # find the mean first, then square distances
    n = len(xs); m = add(xs) / n
    return add((x - m) * (x - m) for x in xs) / n

def welford(xs):                      # one pass, running mean and running sum of squares
    n, m, s = 0, 0.0, 0.0
    for x in xs:
        n += 1; d = x - m; m += d / n; s += d * (x - m)
    return s / n

mg = [1_000_000_004, 1_000_000_007, 1_000_000_013, 1_000_000_016]
n = len(mg)
num = n * sum(x * x for x in mg) - sum(mg) ** 2   # exact, whole numbers only
exact = num / (n * n)
xs = [float(x) for x in mg]
m = add(xs) / n
ms = add(x * x for x in xs) / n
print(f"weighings mean,{m:.1f}")
print(f"variance exact,{exact:.4f}")
print(f"variance shortcut,{shortcut(xs):.4f}")
print(f"variance two-pass,{two_pass(xs):.4f}")
print(f"variance welford,{welford(xs):.4f}")
print(f"std dev,{sqrt(exact):.3f}")
print(f"distances from mean,{','.join(f'{abs(x - m):.0f}' for x in xs)}")
print(f"spacing near the squares,{ulp(ms):.0f},largest rounding,{ulp(ms) / 2:.0f}")
kv = (ms + m * m) / exact
print(f"kappa,{sci(kv, 3)},bound kappa*eps/2,{kv * eps / 2:.2f},kappa*4*eps/2,{kv * 4 * eps / 2:.2f}")
for off in (1e7, 1e8, 1e9):
    ys = [off + d for d in (4.0, 7.0, 13.0, 16.0)]
    print(f"shortcut at offset {sci(off, 0)},{shortcut(ys):.4f},two-pass,{two_pass(ys):.4f}")
assert exact == 22.5 and two_pass(xs) == exact
assert welford(xs) == exact
assert abs(shortcut(xs) - exact) > 10
assert abs(shortcut(xs) - exact) / exact <= kv * 4 * eps / 2   # 7 roundings: 4 eps/2

N = 1_000_000
plain, kahan, comp = 0.0, 0.0, 0.0
for _ in range(N):
    plain += 0.1
    y = 0.1 - comp; t = kahan + y
    comp = (t - kahan) - y; kahan = t
TEN = 3602879701896397                # the stored 0.1 is exactly TEN / 2^55
true_num = TEN * N                    # the exact total of the stored 0.1s, over 2^55
S = 2.0 ** 55
err_plain = (int(plain * S) - true_num) / S
err_kahan = (int(kahan * S) - true_num) / S
print(f"sum of {N} x 0.1,plain,{plain:.11f},kahan,{kahan:.11f}")
print(f"exact total,{true_num >> 55} + {sci((true_num % 2**55) / S, 3)},stored 0.1,{TEN} / 2^55")
print(f"error plain,{sci(err_plain, 3)},bound,{sci(N * eps / 2 * N * 0.1, 3)}")
print(f"error kahan,{sci(err_kahan, 3)},bound,{sci(2 * eps / 2 * N * 0.1, 3)}")
assert 1e-6 < abs(err_plain) <= N * eps / 2 * N * 0.1
assert abs(err_kahan) <= 2 ** -37 and abs(err_kahan) < abs(err_plain) / 1e4
x = 1e-8
print(f"1 - cos(1e-8),{sci(1 - cos(x), 3)},2sin^2(x/2),{sci(2 * sin(x / 2) ** 2, 3)}")
assert 1 - cos(x) == 0.0 and abs(2 * sin(x / 2) ** 2 - x * x / 2) < 1e-30
print("ALL CHECKS PASS")
