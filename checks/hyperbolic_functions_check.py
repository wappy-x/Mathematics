# Hyperbolic functions -- the check behind the card.  exp, log and sqrt are primitives; sinh,
# cosh, their rates and inverses are built here.  A chain hangs as y = 8 cosh(x / 8), hooks 16 m apart.
import math
A, HOOK = 8.0, 8.0                        # chain parameter a, hook's distance from the middle, m

def cosh(t): return (math.exp(t) + math.exp(-t)) / 2      # road one: exp's even half
def sinh(t): return (math.exp(t) - math.exp(-t)) / 2      # and its odd half
def tanh(t): return sinh(t) / cosh(t)
def chain(x): return A * cosh(x / A)
def series(t, parity):                    # road two: e^t's own terms, even or odd powers only
    total, term = 0.0, 1.0
    for n in range(40):
        if n % 2 == parity: total += term
        term *= t / (n + 1)
    return total

def slope(f, t, h): return (f(t + h) - f(t)) / h           # rise over run
def central(f, t): return (f(t + 1e-5) - f(t - 1e-5)) / 2e-5
def bisect(f, target, lo, hi):            # an inverse found by halving a bracket
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return (lo + hi) / 2

print(f"exp halves at t = 1: e^t = {math.exp(1):.6f}, e^-t = {math.exp(-1):.6f}; cosh = {cosh(1):.6f}, sinh = {sinh(1):.6f}, tanh = {tanh(1):.6f}")
for t in (1.0, 3.0, -2.0):
    c, s = series(t, 0), series(t, 1)
    assert max(abs(c - cosh(t)), abs(s - sinh(t))) < 1e-12 * cosh(t)    # series against exp halves
    assert abs(c * c - s * s - 1) < 1e-11                                # the identity, on road two
    print(f"t = {t:.0f}: series cosh = {c:.6f}, sinh = {s:.6f}; cosh^2 = {c * c:.6f}, sinh^2 = {s * s:.6f}, difference = {c * c - s * s:.6f}")
rates = [("sinh at 1", sinh, 1.0, cosh(1)), ("cosh at 1", cosh, 1.0, sinh(1)),
         ("tanh at 1", tanh, 1.0, 1 / cosh(1) ** 2), ("chain at the hook", chain, HOOK, sinh(HOOK / A))]
for name, f, at, rule in rates:
    q = [slope(f, at, h) for h in (0.1, 0.01, 0.001)]
    print(f"rate of {name}: rule {rule:.6f}; quotients h = 0.1, 0.01, 0.001: {q[0]:.6f}, {q[1]:.6f}, {q[2]:.6f}")
n, dx = 100000, 2 * HOOK / 100000
pieces = sum(math.hypot(dx, chain(-HOOK + (k + 1) * dx) - chain(-HOOK + k * dx)) for k in range(n))
length = 2 * A * sinh(HOOK / A)
roads = [(name, central(f, at), rule) for name, f, at, rule in rates] + [("length", pieces, length)]
for name, numeric, rule in roads:
    assert abs(numeric - rule) < 1e-6 * max(1, abs(rule))              # formula against brute force
print(f"chain: bottom {chain(0):.6f} m, hooks {chain(HOOK):.6f} m, sag {chain(HOOK) - chain(0):.6f} m; slope's rate {cosh(1) / A:.6f} = sqrt(1 + slope^2) / 8 = {math.sqrt(1 + sinh(1) ** 2) / A:.6f}")
print(f"chain length: 16 sinh 1 = {length:.6f} m; {n} straight pieces = {pieces:.6f} m")
inverses = [("arcosh 1.25", 1.25, math.log(1.25 + math.sqrt(1.25 ** 2 - 1)), cosh, 0.0, 1 / math.sqrt(1.25 ** 2 - 1)),
            ("arsinh 1.00", 1.0, math.log(1 + math.sqrt(2)), sinh, -5.0, 1 / math.sqrt(2)),
            ("artanh 0.50", 0.5, 0.5 * math.log(1.5 / 0.5), tanh, -5.0, 1 / (1 - 0.25))]
found = []
for name, x, formula, f, lo, rate in inverses:
    b = bisect(f, x, lo, 5.0)
    q = central(lambda u: bisect(f, u, lo, 5.0), x)
    assert max(abs(b - formula), abs(q - rate)) < 1e-6                 # log formula against bisection
    found.append(b)
    print(f"{name}: log formula {formula:.6f}; bisection {b:.6f}; rate rule {rate:.6f}, quotient {q:.6f}")
print(f"chain 2 m above its bottom at x = -{A * found[0]:.6f} and {A * found[0]:.6f} m; slope 1 at x = {A * found[1]:.6f} m")
print(f"mistakes: trig sign on cosh's rate {-sinh(1):.6f}; cosh^2 + sinh^2 at 1 = {cosh(1) ** 2 + sinh(1) ** 2:.6f}; cosh at -{found[0]:.6f} = {cosh(-found[0]):.6f} too")
xs, sag = range(-8, 9, 2), chain(HOOK) - chain(0)
print("chart x m: " + ", ".join(str(x) for x in xs))
print("chart catenary m: " + ", ".join(f"{chain(x) - A:.2f}" for x in xs))
print("chart parabola m: " + ", ".join(f"{sag * (x / 8) ** 2:.2f}" for x in xs) + f"; gap at 6 m {sag * 0.5625 - chain(6) + A:.2f}")
print("ALL CHECKS PASS")
