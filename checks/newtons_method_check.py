# Newton's method, the check behind the card.  Standard library only, no square root called.
# Solve x*x = 2 from the bracket [1, 2], stop on a residual, check two other ways, break it.
def sci(v):                                   # 2.5e-1, the form Rust prints
    m, e = f"{v:.1e}".split("e")
    return f"{m}e{int(e)}"
def bisect(f, a, b):                          # road two: signs only, no slopes
    k, k10 = 0, 0
    while a < (a + b) / 2 < b:                # halve until the floats run out
        c = (a + b) / 2
        a, b = (c, b) if (f(c) < 0) == (f(a) < 0) else (a, c)
        k += 1
        k10 = k10 or (k if b - a < 1e-10 else 0)
    return (a + b) / 2, k10

def newton(f, df, a, b, x, tol=1e-10):        # a step leaving the bracket bisects
    path, kinds = [x], ""
    while abs(f(x)) >= tol and len(path) < 60:
        t = x - f(x) / df(x) if df(x) != 0 else a - 1
        kinds += "N" if a < t < b else "B"
        x = t if a < t < b else (a + b) / 2
        a, b = (x, b) if (f(x) < 0) == (f(a) < 0) else (a, x)
        path.append(x)
    return path, kinds
def decimals(x, r):                           # decimal places that agree
    k = 0
    while int(x * 10 ** (k + 1)) == int(r * 10 ** (k + 1)): k += 1
    return k

f, df = (lambda x: x * x - 2), (lambda x: 2 * x)
print(f"bracket [1, 2]: f(1) = {f(1.0):.1f}, f(2) = {f(2.0):.1f}; the signs differ")
r, k10 = bisect(f, 1.0, 2.0)
path, kinds = newton(f, df, 1.0, 2.0, 1.0)
p, q = 1, 1                                   # road three: exact fractions p/q
for n, x in enumerate(path):
    print(f"step {n}  x = {x:.15f} = {p}/{q}  residual {sci(f(x))}  error {sci(x - r)}  decimals {decimals(x, r)}")
    assert abs(x - p / q) < 1e-15
    p, q = p * p + 2 * q * q, 2 * p * q
x4 = path[-1]
print(f"stopped after {len(path) - 1} Newton steps ({kinds}): residual below 1e-10; bound |f|/2 = {sci(abs(f(x4)) / 2)}")
print(f"bisection, signs only: {r:.15f}; {k10} halvings to a bracket under 1e-10 wide")
ratios = [(path[n + 1] - r) / (path[n] - r) ** 2 for n in range(3)]
print("error ratio e(n+1)/e(n)^2:", " ".join(f"{v:.4f}" for v in ratios),
      "; 1/(2 x_n):", " ".join(f"{1 / (2 * path[n]):.4f}" for n in range(3)), f"; limit 1/(2r) = {1 / (2 * r):.4f}")
X, Y = (lambda x: 40 + 200 * (x - 0.8)), (lambda y: 150 - 50 * y)
print(f"figure, start ({X(1):.1f}, {Y(-1):.1f}), x1 ({X(1.5):.1f}, {Y(0):.1f}), "
      f"curve above x1 ({X(1.5):.1f}, {Y(0.25):.1f}), x2 ({X(path[2]):.1f}, {Y(0):.1f})")
print(f"fail 1, start at 0: slope f'(0) = {df(0.0):.1f}, the tangent never meets the axis")
g, dg = (lambda x: x ** 3 - 2 * x + 2), (lambda x: 3 * x * x - 2)
cyc = [0.0]
for _ in range(4): cyc.append(cyc[-1] - g(cyc[-1]) / dg(cyc[-1]))
print("fail 2, x^3 - 2x + 2 from 0, no bracket:", " -> ".join(f"{v:.0f}" for v in cyc))
gpath, gk = newton(g, dg, -2.0, 0.0, 0.0); groot = bisect(g, -2.0, 0.0)[0]
print(f"same cubic guarded on [-2, 0]: {len(gpath) - 1} steps ({gk}), x = {gpath[-1]:.12f}, bisection {groot:.12f}")
spath, _ = newton(lambda x: 1e-12 * f(x), lambda x: 2e-12 * x, 1.0, 2.0, 1.0)
print(f"fail 3, f scaled by 1e-12: stops after {len(spath) - 1} steps at x = {spath[-1]:.3f}, "
      f"error {abs(spath[-1] - r):.3f}; bound |f|/m = {1e-12 * abs(f(1.0)) / 2e-12:.3f}")
assert abs(x4 - r) <= abs(f(x4)) / 2 < 1e-10          # Newton, bisection, residual bound
assert all(abs(ratios[n] - 1 / (2 * path[n])) < 1e-6 for n in range(3))
assert cyc == [0, 1, 0, 1, 0] and abs(gpath[-1] - groot) < 1e-10
print("ALL CHECKS PASS")
