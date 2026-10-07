# Stirling's approximation -- the check behind the card, on 20!.  Standard library
# only; log, exp, sqrt and sin are primitives; pi is built from Machin's series.
from math import log, exp, sqrt, sin

def atan_inv(q):                  # arctan(1/q) from its own alternating series
    total, k, term = 0.0, 0, 1.0 / q
    while term > 1e-18:
        total += (-1) ** k * term / (2 * k + 1)
        k, term = k + 1, term / (q * q)
    return total

def sci(x):                       # 2.4329 x 10^18, printed the same in Rust
    m, e = f"{x:.4e}".split("e")
    return f"{m} x 10^{int(e)}"

def ln_fact(n):                   # ln n! as a sum of logs, one per factor
    return sum(log(k) for k in range(2, n + 1))

def d(n):                         # ln n! minus the trapezoid shape
    return ln_fact(n) - (n + 0.5) * log(n) + n

PI = 16 * atan_inv(5) - 4 * atan_inv(239)
n, fact = 20, 1
for k in range(2, n + 1):
    fact *= k                     # road one: the exact integer
lo, hi = n * log(n) - n + 1, (n + 1) * log(n + 1) - n
est = sqrt(2 * PI * n) * (n / exp(1)) ** n
print(f"pi from Machin's series: {PI:.12f}")
print(f"20! exact: {fact}")
print(f"integral bounds on ln 20!: {lo:.6f} < {ln_fact(n):.6f} < {hi:.6f}")
print(f"so 20! lies between {sci(exp(lo))} and {sci(exp(hi))}")
print(f"20/e = {n / exp(1):.6f}; (20/e)^20 = {sci((n / exp(1)) ** n)}; sqrt(40 pi) = {sqrt(2 * PI * n):.6f}")
print(f"Stirling estimate: {sci(est)}; ratio to 20! = {est / fact:.6f}")
print(f"with the 1/(12n) factor: {sci(est * (1 + 1 / (12 * n)))}; ratio = {est * (1 + 1 / (12 * n)) / fact:.8f}")
for m in (1, 2, 6, 10, 15, 20):
    print(f"chart, n = {m}: d(n) = {d(m):.4f}, d(n) - 1/(12n) = {d(m) - 1 / (12 * m):.4f}")
big = 100                        # road two: squeeze the constant C
c_hi, c_lo = d(big), d(big) - 1 / (12 * big)
print(f"C, squeezed at n = 100: between {c_lo:.8f} and {c_hi:.8f}; ln sqrt(2 pi) = {0.5 * log(2 * PI):.8f}")
h = PI / 2 / 200                  # Simpson's rule on sin^20 over 0 to pi/2
simpson = sum((1 if j in (0, 200) else 4 if j % 2 else 2) * sin(j * h) ** 20
              for j in range(201)) * h / 3
reduction = PI / 2
for k in range(20, 0, -2):
    reduction *= (k - 1) / k      # parts: W_k = (k - 1)/k times W_(k-2)
print(f"W_20 by Simpson: {simpson:.10f}; by the parts formula: {reduction:.10f}")
m = 1000                          # road three: Wallis's integrals of sin^k
wallis = 4 * m * log(2) + 4 * ln_fact(m) - 2 * ln_fact(2 * m) - log(2 * m + 1)
w_lo, w_hi = exp(wallis), exp(wallis) * (2 * m + 1) / (2 * m)
print(f"Wallis, m = 1000: {w_lo:.6f} < pi/2 < {w_hi:.6f}; pi/2 = {PI / 2:.6f}")
print(f"mistake 1, drop sqrt(2 pi n): {sci((n / exp(1)) ** n)}, ratio {(n / exp(1)) ** n / fact:.4f}")
print(f"mistake 2, subtract instead of divide: 20! - estimate = {sci(fact - est)}")
print(f"mistake 3, stop at the lower integral: e (20/e)^20 = {sci(exp(lo))}, ratio {exp(lo) / fact:.4f}")
assert lo < log(fact) < hi                          # integrals sandwich the exact product
assert c_lo < 0.5 * log(2 * PI) < c_hi              # squeeze meets Machin's pi
assert w_lo < PI / 2 < w_hi                         # Wallis meets Machin's pi
assert abs(simpson - reduction) < 1e-9              # parts formula meets Simpson
assert est < fact < est * exp(1 / (12 * n))        # the card's 1/(12n) sandwich
print("ALL CHECKS PASS")
