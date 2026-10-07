# Iteration and cobweb plots -- the check behind the card.  Nothing is imported.
# Road one feeds each rule its own output, step by step.  Road two reaches each
# end point without that loop: exact fractions and bisection for the square
# root, algebra for the fish stock's resting level, a slope for the spiral.
def orbit(g, x0, n):                     # x0, g(x0), g(g(x0)), ... n steps in all
    xs = [x0]
    for _ in range(n):
        xs.append(g(xs[-1]))
    return xs

def bisect(f, lo, hi):                   # a root of f between lo and hi, 60 halvings
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

def show(xs, d=6):
    return ", ".join(f"{x:.{d}f}" for x in xs)

sq = lambda x: (x + 2 / x) / 2                                  # the square-root rule
fish = lambda r: (lambda x: r * x * (1 - x))                    # the logistic rule
b = orbit(sq, 1.0, 4)
p, q, fracs = 1, 1, []                                          # exact: p/q -> (p*p + 2q*q)/(2pq)
for _ in range(4):
    p, q = p * p + 2 * q * q, 2 * p * q
    fracs.append(f"{p}/{q}")
root = bisect(lambda x: x * x - 2, 1.0, 2.0)
err = [x - root for x in b]
g = fish(2.8)
f = orbit(g, 0.2, 200)
star = 1 - 1 / 2.8                                              # g(x) = x, solved by hand
ratio = (f[81] - star) / (f[80] - star)
slope = (g(star + 1e-6) - g(star - 1e-6)) / 2e-6
c = orbit(fish(3.2), 0.2, 203)
w = orbit(fish(3.9), 0.2, 1999)
bins = len({int(x * 10000) for x in w[1000:]})
print(f"square-root rule from 1 m, x0..x4: {show(b, 10)}")
print(f"the same orbit as exact fractions: {', '.join(fracs)}")
print(f"sqrt(2) by bisection, no use of the rule: {root:.10f}")
print(f"error after steps 1 to 4: {', '.join(f'{e:.2e}' for e in err[1:])}")
print(f"error after step 3 predicted by (error after step 2)^2 / (2 x2): {err[2] ** 2 / (2 * b[2]):.2e}")
print(f"logistic r = 2.8 from 0.2, x0..x8: {show(f[:9])}")
print(f"x200 = {f[200]:.6f}; resting level by algebra, 1 - 1/r = {star:.6f}")
print(f"side of the resting level at steps 0..8: {''.join('+' if x > star else '-' for x in f[:9])}")
print(f"error ratio at step 80: {ratio:.6f}; slope of the curve at the resting level: {slope:.6f}")
print(f"logistic r = 3.2, x200..x203: {show(c[200:])}")
print(f"logistic r = 3.9, x50..x55: {show(w[50:56])}")
print(f"r = 3.9, distinct values to 4 decimals among x1000..x1999: {bins}")
print(f"mistake 1, solving g(x) = 0 at r = 2.8: {abs(bisect(g, -0.5, 0.5)):.6f} and {bisect(g, 0.5, 1.5):.6f}")
print(f"mistake 2, the rule 2/x from 1, x0..x4: {show(orbit(lambda x: 2 / x, 1.0, 4), 1)}")
print(f"mistake 3, g(0.2) squared = {g(0.2) ** 2:.6f}; g(g(0.2)) = {g(g(0.2)):.6f}")
print(f"mistake 4, square-root rule from -1, x4 = {orbit(sq, -1.0, 4)[4]:.10f}")
print(f"figure, square-root cobweb x0..x3 at x px: {show([60 + 200 * (x - 0.8) for x in b[:4]], 1)}")
print(f"figure, logistic cobweb x0..x8 at x px: {show([60 + 180 * x for x in f[:9]], 1)}")
assert abs(b[4] - root) < 1e-11                                 # iteration against bisection
assert abs(b[4] - p / q) < 1e-15                                # iteration against exact fractions
assert abs(f[200] - star) < 1e-12                               # iteration against algebra
assert abs(ratio - slope) < 1e-5                                # spiral rate against the slope
print("ALL CHECKS PASS")
