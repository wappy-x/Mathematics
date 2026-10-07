# Extreme value theorem -- the check behind the card.  Standard library only.
# The bed: sides x and 1 - x metres, area f(x) = x(1 - x) square metres, x in [0, 1].
# Road 1 hunts the top by brute force on finer and finer grids.  Road 2 completes
# the square, in whole numbers, so no rounding can hide a miss.

def f(x):
    return x * (1 - x)

def best_on_grid(n):                     # first k in 0..n with the largest k(n - k)
    best = 0
    for k in range(n + 1):
        if k * (n - k) > best * (n - best):
            best = k
    return best

print("chart, 2 m of edging, sides x and 1-x, area at x = 0.0, 0.1, ..., 1.0:", " ".join(f"{f(k / 10):.2f}" for k in range(11)))
print("road 1, grids of step 1/N; an odd N never lands on x = 0.5")
gaps = []
for n in (3, 9, 27, 81, 243):
    k = best_on_grid(n)
    area = k * (n - k) / (n * n)
    gap, algebra = 0.25 - area, (1 / (2 * n)) ** 2
    gaps.append((gap, algebra))
    print(f"N = {n:<3}  best x {k / n:.6f}  area {area:.6f}  short of 0.25 by {gap:.6f}  (1/(2N))^2 = {algebra:.6f}")
square = [250000 - (k - 500) ** 2 for k in range(1001)]   # 1/4 - (x - 1/2)^2, times 1000^2
product = [k * (1000 - k) for k in range(1001)]            # x(1 - x), times 1000^2
top, low = max(product), min(product)
print(f"road 2, x(1-x) = 1/4 - (x - 1/2)^2 at all 1001 points k/1000: {'yes' if product == square else 'no'}")
print(f"largest area {top / 1e6:.2f} at x = {product.index(top) / 1000:.1f}; smallest {low / 1e6:.2f} at x = "
      + " and ".join(f"{k / 1000:.0f}" for k in range(1001) if product[k] == low))
h = 0
while f(0.5) - f(0.5 + (h + 1) * 1e-6) < 0.001:            # widest step still inside the tolerance
    h += 1
print(f"tolerance game: area within 0.001 of the top needs x within {h * 1e-6:.4f} of 0.5; sqrt(0.001) = {0.001 ** 0.5:.4f}")
print("open interval, g(x) = x on (0,1): " + ", ".join(f"{c} beaten by {(c + 1) / 2}" for c in (0.9, 0.99, 0.999))
      + "; the top 1 is never an output")
jump = lambda x: x if x < 1 else 0.0
print(f"jump on [0,1], x below 1 and 0 at x = 1: value {jump(0.999)} at x = 0.999, value {jump(1.0):.0f} at x = 1")
print(f"x(1-x) on [0, infinity): top 0.25 kept; f(10) = {f(10):.0f}, f(100) = {f(100):.0f}, no bottom")
assert all(abs(g - a) < 1e-12 for g, a in gaps)             # grid miss equals the algebra's miss
assert product == square                                    # two formulas, one function, exactly
assert product.index(top) == 500 and square[500] == top     # brute-force top sits where the square says
assert abs(h * 1e-6 - 0.001 ** 0.5) < 1e-6                  # scan agrees with sqrt(0.001)
print("ALL CHECKS PASS")
