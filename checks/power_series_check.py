# Power series -- the check behind the card.  Nothing is imported.
# Road one: partial sums of the two series, and their term-by-term slope.
# Road two, sharing no arithmetic with road one: the closed form 1/(1-x), a
# Simpson sum for the area under 1/(1+t) from 0 to x, which is ln(1+x), and a
# shrinking difference quotient for the slope of 1/(1-x).
def geo(x, N):                          # 1 + x + x^2 + ... + x^N
    return sum(x**n for n in range(N + 1))

def geo_slope(x, N):                    # term by term: 1 + 2x + 3x^2 + ... + N x^(N-1)
    return sum(n * x**(n - 1) for n in range(1, N + 1))

def ln_series(x, N):                    # x - x^2/2 + x^3/3 - ... through the x^N term
    return sum((-1)**(n + 1) * x**n / n for n in range(1, N + 1))

def ln_area(x, m=4000):                 # Simpson's rule: area under 1/(1+t) from 0 to x
    h = x / m
    s = 1 + 1 / (1 + x) + sum((4 if k % 2 else 2) / (1 + k * h) for k in range(1, m))
    return s * h / 3

def row(vals):
    return ", ".join(f"{v:.2f}" for v in vals)

x, N = 0.5, 20
g, closed = geo(x, N), 1 / (1 - x)
s, area = ln_series(x, N), ln_area(x)
h, slope = 1e-5, geo_slope(x, N)
dq = (1 / (1 - x - h) - 1 / (1 - x + h)) / (2 * h)
tail = ((N + 1) * x**N - N * x**(N + 1)) / (1 - x)**2
ln2 = ln_area(1.0)
print(f"radius: coefficient ratio 1 for 1/(1-x); n/(n+1) = {1000 / 1001:.6f} at n = 1000 for ln(1+x)")
print(f"1/(1-x) at {x}, through x^{N}: {g:.9f}; closed form {closed:.9f}; gap {closed - g:.9f}")
print(f"ln(1+x) at {x}, through x^{N}: {s:.9f}; Simpson area {area:.9f}; gap {abs(s - area):.9f}; bound {x**(N + 1) / (N + 1):.9f}")
print(f"slope of 1/(1-x) at {x}, through {N}x^{N - 1}: {slope:.9f}; difference quotient {dq:.6f}; gap {dq - slope:.6f}")
for M in (10, 100, 1000):
    v = ln_series(1.0, M)
    print(f"N = {M}: x = 1 sum {v:.6f}, ln 2 = {ln2:.6f}, gap {abs(v - ln2):.6f} <= 1/(N+1) = {1 / (M + 1):.6f}; x = -1 sum {ln_series(-1.0, M):.6f}")
print(f"1/(1-x) at x = 1: sum through x^99 = {geo(1.0, 99):.0f}; at x = -1 sums run {row(geo(-1.0, k) for k in range(6))}")
print(f"slope series of ln(1+x) at x = 1, 1 - 1 + 1 - ...: sums run {row(sum((-1)**(n + 1) * 1.0**(n - 1) for n in range(1, k + 1)) for k in range(1, 7))}")
print(f"log terms at {x}: {', '.join(f'{(-1)**(n + 1) * x**n / n:.6f}' for n in range(1, 5))}; at x = 2, 1/(1-x) = {1 / (1 - 2):.2f} but terms run {row(2.0**n for n in range(4))}")
print(f"outside, x = 1.1: x^100 term of 1/(1-x) is {1.1**100:.2f}; of ln(1+x) is {-1.1**100 / 100:.2f}")
xs = [(3 * k - 9) / 10 for k in range(9)]
print(f"chart, x: {row(xs)}")
print(f"chart, ln(1+x) by Simpson: {row(ln_area(t) for t in xs)}")
print(f"chart, through x^4: {row(ln_series(t, 4) for t in xs)}")
print(f"chart, through x^10: {row(ln_series(t, 10) for t in xs)}")
assert abs(closed - g) <= x**(N + 1) / (1 - x) + 1e-15      # partial sum against closed form
assert abs(s - area) <= x**(N + 1) / (N + 1) + 1e-12          # term-by-term integral against area
assert abs((dq - slope) - tail) < 1e-8                        # slope gap is the predicted tail
assert all(abs(ln_series(1.0, M) - ln2) <= 1 / (M + 1) for M in (10, 100, 1000))
print("ALL CHECKS PASS")
