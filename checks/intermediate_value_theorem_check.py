# Intermediate value theorem -- the check behind the card.  Nothing is imported.
# f(x) = x*x - 2 on [1, 2]: f(1) < 0 < f(2), so a root exists.  Road 1 halves
# the bracket in exact whole numbers (x = k / 2^n); road 2 scans a grid; road 3
# averages x and 2/x again and again.  Then three functions that break the theorem.
def f(x): return x * x - 2

def bisect(g, lo, hi, steps):            # keep the half whose ends still straddle 0
    for _ in range(steps):
        m = (lo + hi) / 2
        if g(m) < 0: lo = m
        else: hi = m
    return lo, hi

print(f"f(1) = {f(1.0):.2f}, f(2) = {f(2.0):.2f}: the signs differ")
print("chart, f(x) at x = 1.0, 1.1, ..., 2.0:", " ".join(f"{f((10 + i) / 10):.2f}" for i in range(11)))
lo, hi, den, bad = 1, 2, 1, 0           # the bracket is [lo/den, hi/den], exactly
for n in range(1, 13):
    lo, hi, den = 2 * lo, 2 * hi, 2 * den
    m = lo + 1                           # the midpoint, in the finer units
    bad += m * m == 2 * den * den        # a midpoint that squares to exactly 2?
    if m * m < 2 * den * den: lo = m     # f(m) < 0, decided in whole numbers
    else: hi = m
    if n <= 4:
        print(f"halving {n}: m = {m / den:.8f}, f(m) = {f(m / den):.8f}, keep [{lo / den:.8f}, {hi / den:.8f}]")
print(f"road 1, halving 12: [{lo}/{den}, {hi}/{den}] = [{lo / den:.12f}, {hi / den:.12f}]")
print(f"midpoint {(lo + hi) / (2 * den):.13f}, root within 1/{2 * den} = {1 / (2 * den):.13f}")
k = den                                  # road 2: walk the grid k/4096 up from 1
while (k + 1) * (k + 1) < 2 * den * den: k += 1
print(f"road 2, grid scan: largest k with k*k < 2*{den}*{den} is {k}")
b50 = bisect(f, 1.0, 2.0, 50)[0]
x, heron = 1.5, []                      # road 3: average x and 2/x, from 1.5
for _ in range(4):
    x = (x + 2 / x) / 2
    heron.append(x)
print(f"50 halvings in floats: {b50:.15f}")
print("road 3, averaging from 1.5:", " ".join(f"{v:.15f}" for v in heron))
worst = max(abs(f(b50 + d) - f(b50)) for d in [0.00025 * (i - 500) / 500 for i in range(1001)])
print(f"tolerance game at the root: inputs within 0.00025 move f by at most {worst:.6f} < 0.001")
print(f"midpoints squaring to exactly 2 in 12 halvings: {bad}")
def jump(x): return -1.0 if x < 1.5 else 1.0
jl, jh = bisect(jump, 1.0, 2.0, 40)
print(f"jump: ends {jump(1.0):.0f}, {jump(2.0):.0f}; bisection closes on {jh:.10f}, where it is {jump(jh):.0f}")
def h(x): return x * x * x - x
roots = [x / 4 for x in range(-8, 9) if h(x / 4) == 0]
print(f"x^3 - x on [-2, 2]: ends {h(-2):.0f}, {h(2):.0f}; grid roots {roots}; first midpoint {(-2 + 2) / 2:.1f}")
rises = all(f((11 + i) / 10) > f((10 + i) / 10) for i in range(10))
print("f rises at every step of the grid:", "yes" if rises else "no")
assert (lo, hi) == (k, k + 1)                           # halving meets the grid scan
assert abs(b50 - heron[-1]) < 1e-15                    # halving meets averaging
assert roots == [-1.0, 0.0, 1.0]                        # the factors x, x - 1, x + 1
assert worst <= 4 * 0.00025                             # |f(x) - f(c)| <= 4|x - c|
print("ALL CHECKS PASS")
