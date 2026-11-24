# Darboux's theorem -- the check behind the card.  Standard library only.
# A derivative takes every value between two of its values.  Three examples:
# x^2 on [-0.5, 1.5] with target slope 0.5, found three ways; the sign
# function, which jumps and skips 0.5; and x^2 sin(1/x), whose derivative has
# no limit at 0 yet hits 0.5 between any two of its swings, found two ways.
import math
def bisect(fn, lo, hi):                     # halve a bracket where fn changes sign
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if (fn(lo) < 0) == (fn(mid) < 0) else (lo, mid)
    return (lo + hi) / 2
def extreme(fn, lo, hi, sign):              # sign 1 lowest point, -1 highest
    for _ in range(200):
        a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, b) if sign * fn(a) < sign * fn(b) else (a, hi)
    return (lo + hi) / 2
def slope(f, x, h=1e-5): return (f(x + h) - f(x - h)) / (2 * h)
f = lambda x: x * x
y = 0.5
g = lambda x: f(x) - y * x                  # the proof's tilted function
r1 = y / 2                                  # road 1: f'(c) = 2c = 0.5
r2 = extreme(g, -0.5, 1.5, 1)               # road 2: lowest point of g, no slope used
r3 = bisect(lambda x: slope(f, x) - y, -0.5, 1.5)  # road 3: own slope, then bisection
top = max([-0.5 + k / 1000 for k in range(2001)], key=g)
print(f"x^2 on [-0.5, 1.5]: f'(-0.5) = {slope(f, -0.5):.4f}, f'(1.5) = {slope(f, 1.5):.4f}, target {y}")
print(f"road 1, formula 2c = {y}: c = {r1:.6f}")
print(f"road 2, lowest point of g = x^2 - {y}x, no slope used: c = {r2:.6f}, g(c) = {g(r2):.4f}")
print(f"road 3, bisection on difference-quotient slope minus {y}: c = {r3:.6f}")
print(f"g' at the ends {slope(g, -0.5):+.4f} and {slope(g, 1.5):+.4f}; g at the ends {g(-0.5):.4f} and {g(1.5):.4f}; one step in, g(-0.4) = {g(-0.4):.4f} and g(1.4) = {g(1.4):.4f}")
print("chart, g at x = -0.5, -0.25, ..., 1.5:", [round(g(-0.5 + k / 4), 4) for k in range(9)])
sgn = lambda x: (x > 0) - (x < 0)
taken = sorted({sgn(-1 + k / 1000) for k in range(2001)})
print(f"|x|: one-sided slopes at 0, step 0.001: {(abs(-0.001) - 0) / -0.001:+.4f} and {(abs(0.001) - 0) / 0.001:+.4f}")
print(f"sign function on a 2001-point grid of [-1, 1] takes only {taken}; 0.5 is skipped")
w = lambda x: x * x * math.sin(1 / x) if x != 0 else 0.0
dw = lambda x: 2 * x * math.sin(1 / x) - math.cos(1 / x)
q = [w(h) / h for h in (0.1, 0.01, 0.001)]
print("x^2 sin(1/x): (f(h) - f(0))/h at h = 0.1, 0.01, 0.001:", ", ".join(f"{v:.6f}" for v in q))
print("f' at x = 1/(n pi), n = 1 to 8:", ", ".join(f"{dw(1 / (n * math.pi)):+.4f}" for n in range(1, 9)))
pairs = []
for n in (20, 200, 2000):
    a, b = 1 / ((n + 1) * math.pi), 1 / (n * math.pi)   # f' = +1 at a, -1 at b
    cb = bisect(lambda x: dw(x) - y, a, b)
    ce = extreme(lambda x: w(x) - y * x, a, b, -1)      # proof road: highest point
    pairs.append((cb, ce))
    print(f"n = {n}: between {a:.9f} and {b:.9f}, f' = {y} at {cb:.9f} (bisection), {ce:.9f} (highest point)")
b0, s = 1 / (20 * math.pi), 1 / (20 * math.pi) / 10**5   # f'(0) = 0, f'(b0) = -1, f' breaks at 0
ct = max([s * k for k in range(10**5 + 1)], key=lambda x: w(x) + 0.5 * x)  # grid: highest point of f + 0.5x
c0, ce0 = bisect(lambda x: dw(x) + 0.5, ct - s, ct + s), extreme(lambda x: w(x) + 0.5 * x, ct - s, ct + s, -1)
print(f"whole stretch [0, {b0:.9f}]: f' = {dw(b0):+.4f} at the end, f' = -0.5 at {c0:.9f} (bisection), {ce0:.9f} (highest point)")
print(f"mistake 1, highest point of g: x = {top:.4f}, where f' = {slope(f, top):.4f}, not {y}")
print(f"mistake 2, mean value theorem: average slope {(f(1.5) - f(-0.5)) / 2:.4f}, at x = {(f(1.5) - f(-0.5)) / 4:.4f}")
assert abs(r1 - r2) < 1e-6 and abs(r1 - r3) < 1e-6           # three roads, one point
assert all(abs(cb - ce) < 1e-6 * cb for cb, ce in pairs)      # formula vs proof road
assert all(abs(dw(cb) - y) < 1e-9 for cb, _ in pairs)          # it really hits 0.5
assert taken == [-1, 0, 1] and abs(q[2]) < 0.001 and abs(top - 1.5) < 1e-9
assert 0 < ct < b0 and abs(dw(c0) + 0.5) < 1e-9 and abs(c0 - ce0) < 1e-6 * c0  # Darboux on [0, b0]
print("ALL CHECKS PASS")
