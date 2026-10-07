# Fourier series of a square wave -- the check behind the card.  Standard library
# only.  Road one: the closed form b_n = 4/(n pi).  Road two: integrals over one
# period by a midpoint rule written here.  Road three: best single sine by search.
import math
PI, M = math.pi, 20000                        # M midpoint cells across one period

def f(x):                                     # the wave: +1 for half a cycle, -1 after
    return 1.0 if x % (2 * PI) < PI else -1.0

def integral(g):                              # midpoint rule from -pi to pi
    h = 2 * PI / M
    return h * sum(g(-PI + (i + 0.5) * h) for i in range(M))

def closed_b(n):                              # road one: 4/(n pi) for odd n, 0 for even
    return 4 / (n * PI) if n % 2 else 0.0

def partial(x, top):                          # S_N: the sine terms up to harmonic top
    return sum(closed_b(n) * math.sin(n * x) for n in range(1, top + 1))

def err(g):                                   # mean-square miss: integral of (f - g)^2
    return integral(lambda x: (f(x) - g(x)) ** 2)

def fmt(xs, d=2):
    return ", ".join(f"{v:.{d}f}" for v in xs)

ss = [[integral(lambda x: math.sin(m * x) * math.sin(n * x)) for n in (1, 2, 3)] for m in (1, 2, 3)]
sc = max(abs(integral(lambda x: math.sin(m * x) * math.cos(n * x))) for m in (1, 2, 3) for n in range(4))
cross = integral(lambda x: math.sin(x) * math.sin(1.5 * x))
cross_closed = math.sin(0.5 * PI) / 0.5 - math.sin(2.5 * PI) / 2.5   # product-to-sum
a = [integral(lambda x: f(x) * math.cos(n * x)) / PI for n in range(6)]
b = [integral(lambda x: f(x) * math.sin(n * x)) / PI for n in range(1, 6)]
lo, hi, r = 0.0, 3.0, (math.sqrt(5) - 1) / 2   # road three: golden-section search
for _ in range(40):
    p, q = hi - r * (hi - lo), lo + r * (hi - lo)
    lo, hi = (lo, q) if err(lambda x: p * math.sin(x)) < err(lambda x: q * math.sin(x)) else (p, hi)
best = (lo + hi) / 2
xs = [(k + 0.5) * PI / 8 for k in range(16)]
off = max(abs(ss[m][n]) for m in range(3) for n in range(3) if m != n)
print(f"a 220 Hz tone: harmonics at {fmt([220 * n for n in (1, 3, 5)], 0)} Hz; one cycle lasts {1000 / 220:.2f} ms")
print(f"integral of sin(nx)^2, n = 1..3: {fmt([ss[n][n] for n in range(3)], 6)}; pi = {PI:.6f}")
print(f"largest |integral of sin(mx) sin(nx)|, m not n: {off:.6f}; of sin(mx) cos(nx): {sc:.6f}")
print(f"frequency 1.5, integral of sin(x) sin(1.5x): {cross:.6f} by midpoint, {cross_closed:.6f} by identity")
print(f"largest |a_n|, n = 0..5, by integral: {max(abs(v) for v in a):.6f}")
print(f"b_1, b_3, b_5 by integral: {fmt(b[0::2], 6)}; largest |b_2|, |b_4|: {max(abs(b[1]), abs(b[3])):.6f}")
print("b_1, b_3, b_5 by 4/(n pi):", fmt([closed_b(n) for n in (1, 3, 5)], 6))
print(f"best single sine by search: b = {best:.6f}; 4/pi = {4 / PI:.6f}")
print("mean-square miss with harmonics up to 1, 3, 5:", fmt([err(lambda x: partial(x, t)) for t in (1, 3, 5)], 6))
print(f"mistake, one sine at the wave's height, b = 1: mean-square miss {err(math.sin):.6f}")
print(f"S_5 at x = pi/2: {partial(PI / 2, 5):.6f}")
print(f"mistake, dividing by 2 pi instead of pi: b_1 = {b[0] / 2:.6f}")
print("chart, x in radians:", fmt(xs))
print("chart, S_1:", fmt(partial(x, 1) for x in xs))
print("chart, S_5:", fmt(partial(x, 5) for x in xs))
assert max(abs(ss[n][n] - PI) for n in range(3)) < 1e-6 and off < 1e-9 and sc < 1e-9
assert max(abs(b[n - 1] - closed_b(n)) for n in range(1, 6)) < 1e-6 and max(abs(v) for v in a) < 1e-9
assert abs(best - 4 / PI) < 1e-5                            # search lands on the projection
assert abs(cross - cross_closed) < 1e-6                      # the cross-talk number, two ways
print("ALL CHECKS PASS")
