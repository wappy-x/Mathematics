# The shooting method -- the check behind the card.  Standard library only;
# math.exp is the one primitive.  Cable on a spring bed: y'' = y, x in m, y in cm,
# y(0) = 1, y(1) = 2.  Self-heating slab: y'' = -e^y, y(0) = y(1) = 0, scaled.
import math
def shoot(f, y0, s, n=64):              # RK4 on y' = v, v' = f(y), from x = 0 to 1
    h, y, v = 1 / n, y0, s
    for _ in range(n):
        k1 = (v, f(y)); k2 = (v + h/2*k1[1], f(y + h/2*k1[0]))
        k3 = (v + h/2*k2[1], f(y + h/2*k2[0])); k4 = (v + h*k3[1], f(y + h*k3[0]))
        y += h/6*(k1[0] + 2*k2[0] + 2*k3[0] + k4[0]); v += h/6*(k1[1] + 2*k2[1] + 2*k3[1] + k4[1])
    return y                            # the landing height y(1)
def secant(g, s0, s1, tol=1e-10):       # re-aim along the line through the last two shots
    g0, g1, rows = g(s0), g(s1), []
    while abs(g1) > tol:
        s0, s1 = s1, s1 - g1 * (s1 - s0) / (g1 - g0); g0, g1 = g1, g(s1); rows.append((s1, g1))
    return s1, rows
def bisect(F, lo, hi):                  # halve a bracket where F changes sign
    for _ in range(100):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if F(lo) * F(mid) > 0 else (lo, mid)
    return lo
cosh = lambda z: (math.exp(z) + math.exp(-z)) / 2
sinh = lambda z: (math.exp(z) - math.exp(-z)) / 2
ch, sh = cosh(1), sinh(1)
tanh = lambda z: (1 - math.exp(-2 * z)) / (1 + math.exp(-2 * z))
cable = lambda n: (lambda s: shoot(lambda y: y, 1.0, s, n) - 2)
g = cable(64); a, b = g(0) + 2, g(1) + 2
print(f"cable, shots s = 0 and 1 land at {a:.6f} and {b:.6f}, misses {a-2:.6f} and {b-2:.6f}")
s_cab = 0 - (a - 2) * (1 - 0) / (b - a)          # road 1: one secant step from two shots
exact = (2 - ch) / sh                            # road 2: the closed form
print(f"cable, secant through the two shots: s = {s_cab:.8f}, third shot lands at {g(s_cab)+2:.8f}")
print(f"cable, closed form (2 - cosh 1)/sinh 1 = {exact:.8f}; miss rises sinh 1 = {sh:.6f} per unit of s")
assert abs(s_cab - exact) < 1e-8
errs = [abs(secant(cable(n), 0, 1)[0] - exact) for n in (4, 8, 16)]
print(f"cable, slope error with 4, 8, 16 steps: {errs[0]:.2e} {errs[1]:.2e} {errs[2]:.2e}; ratios {errs[0]/errs[1]:.2f} {errs[1]/errs[2]:.2f}")
assert all(14 < errs[i] / errs[i + 1] < 18 for i in range(2))
for s, name in ((0, "s = 0"), (1, "s = 1"), (exact, "s = 0.3888")):
    pts = [(40 + 240 * x, 200 - 100 * (cosh(x) + s * sinh(x) - 0.9)) for x in (k / 8 for k in range(9))]
    print(f"figure, {name}:", " ".join(f"{p:.1f},{q:.1f}" for p, q in pts))
heat = lambda s: shoot(lambda y: -math.exp(y), 0.0, s, 256)
th = [bisect(lambda t: t - math.sqrt(2) * cosh(t / 4), lo, hi) for lo, hi in ((0, 4), (4, 20))]
slopes = [t * tanh(t / 4) for t in th]           # road 2: y'(0) = theta tanh(theta/4)
print(f"slab, theta by bisection {th[0]:.6f} and {th[1]:.6f}; exact slopes {slopes[0]:.6f} and {slopes[1]:.6f}")
low, rows = secant(heat, 0, 1)
for k, (s, m) in enumerate(rows, 1):
    print(f"slab, correction {k}: s = {s:.10f}, miss = {m:+.2e}")
high, rows2 = secant(heat, 10, 12)
print(f"slab, from shots 10 and 12: s = {high:.6f} after {len(rows2)} corrections")
assert abs(low - slopes[0]) < 1e-8 and abs(high - slopes[1]) < 1e-7
print("chart, s:", " ".join(str(s) for s in range(0, 15, 2)))
print("chart, miss:", " ".join(f"{heat(s):.2f}" for s in range(0, 15, 2)))
flat = secant(lambda s: shoot(lambda y: y, 0.0, s) - 2, 0, 1)[0]
res = [shoot(lambda y: -math.pi**2 * y, 0.0, s) - 1 for s in (0, 1)]
hot = max(shoot(lambda y: -4 * math.exp(y), 0.0, s / 10) for s in range(301))
print(f"mistake, left height dropped: s = {flat:.6f}, not {exact:.6f}")
print(f"mistake, y'' = -pi^2 y from y(0) = 0 aiming at 1: misses {res[0]:.6f} and {res[1]:.6f} at s = 0 and 1")
print(f"mistake, slab heating 4 times as fast: best landing for s from 0 to 30 is {hot:.4f}, never 0")
assert abs(flat - 2 / sh) < 1e-8 and all(abs(r + 1) < 1e-6 for r in res) and hot < 0
print("ALL CHECKS PASS")
