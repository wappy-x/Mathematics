# The Poisson formula -- the check behind the card.  Standard library only.
# A drumhead of radius 1 has rim height h(s) = 20 + 5 cos s (millimetres).
# Road one: the closed form inside, 20 + 5 r cos t.  Road two: the Poisson
# integral itself, a trapezoid sum of kernel times rim height round the rim.
import math

def h(s):                                  # the warped rim
    return 20 + 5 * math.cos(s)

def kernel(r, x):                          # (1 - r^2) / (1 - 2 r cos x + r^2)
    return (1 - r * r) / (1 - 2 * r * math.cos(x) + r * r)

def cauchy_kernel(r, t, s):                # Re((z + a)/(z - a)), z on the rim, a = r e^(it)
    z, a = complex(math.cos(s), math.sin(s)), r * complex(math.cos(t), math.sin(t))
    return ((z + a) / (z - a)).real

def poisson(g, r, t, n=64):                # (1/2 pi) x integral of P(t - s) g(s) ds, n equal steps
    return sum(kernel(r, t - 2 * math.pi * k / n) * g(2 * math.pi * k / n) for k in range(n)) / n

def half_plane(g, x, y, n=400):            # (1/pi) x integral of y g(q) / ((x - q)^2 + y^2) dq,
    return sum(g(x + y * math.tan(-math.pi / 2 + math.pi * (k + 0.5) / n)) for k in range(n)) / n

def sci(v):                                # 1.2e-5 style, the same in both languages
    e = math.floor(math.log10(v)); m = round(v / 10 ** e, 1)
    return f"{m / 10:.1f}e{e + 1}" if m >= 10 else f"{m:.1f}e{e}"

cayley = lambda z: (z - 1j) / (z + 1j)
bump = lambda r, t: 20 + 5 * r * math.cos(t) + (1 - r * r)   # same rim, not harmonic
hq = lambda q: h(math.atan2(cayley(q).imag, cayley(q).real))  # rim data carried to the line
exact = 20 + 5 * 0.5 * math.cos(0)
print("figure, 80 units per 1: centre (150, 120), rim radius 80, a = 1/2 at (190, 120), nearest rim point (230, 120), farthest (70, 120)")
gap = max(abs(kernel(0.5, s) - cauchy_kernel(0.5, 0, s)) for s in (0.1 * k for k in range(63)))
print(f"kernel, real formula against Cauchy's form Re((z + a)/(z - a)) at 63 angles: agree to 12 decimals: {'yes' if gap < 1e-12 else 'no'}")
print("chart, P at r = 1/2, s = 0, pi/6, ..., pi: " + ", ".join(f"{kernel(0.5, k * math.pi / 6):.2f}" for k in range(7)))
print(f"kernel mass, 256 points: r = 0.5 gives {poisson(lambda s: 1, 0.5, 0, 256):.6f}; r = 0.9 gives {poisson(lambda s: 1, 0.9, 0, 256):.6f}")
print(f"centre, r = 0: {poisson(h, 0, 0):.6f}; plain rim average {sum(h(2 * math.pi * k / 64) for k in range(64)) / 64:.6f}")
print(f"r = 1/2, t = 0: closed form {exact:.6f}; kernel sum, 64 points {poisson(h, 0.5, 0):.6f}")
for n in (4, 8, 16, 32):
    print(f"r = 1/2, t = 0, {n} points: error {sci(abs(poisson(h, 0.5, 0, n) - exact))}")
second = 20 + 5 * 0.8 * math.cos(2 * math.pi / 3)
print(f"r = 0.8, t = 2pi/3: closed form {second:.6f}; kernel sum, 256 points {poisson(h, 0.8, 2 * math.pi / 3, 256):.6f}")
w = cayley(3j)
print(f"half plane: Cayley map sends 3i to {w.real:.6f} + {w.imag:.6f}i; half-plane integral at 3i = {half_plane(hq, 0, 3):.6f}")
print(f"mistake 1, dropping the 1/(2 pi): {2 * math.pi * poisson(h, 0.5, 0):.6f}, not 22.500000")
print(f"mistake 2, a pressed drum (bump 1 - r^2, same rim): true height {bump(0.5, 0):.6f}; formula says {poisson(lambda s: bump(1, s), 0.5, 0):.6f}")
print(f"mistake 3, a point off the drum, r = 2, t = 0: kernel sum gives {poisson(h, 2, 0):.6f}")
assert abs(poisson(h, 0.5, 0) - exact) < 1e-12 and abs(poisson(h, 0.8, 2 * math.pi / 3, 256) - second) < 1e-9
assert gap < 1e-12                                                    # Cauchy's form = the real formula
assert all(abs(poisson(lambda s: 1, r, 0, 256) - 1) < 1e-10 for r in (0.5, 0.9))   # total weight 1
assert abs(half_plane(hq, 0, 3) - (20 + 5 * w.real)) < 1e-9          # half plane agrees with the disc
print("ALL CHECKS PASS")
