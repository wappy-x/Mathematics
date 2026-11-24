# The Dirichlet problem by Brownian motion -- the check behind the card.  Standard library only.
# A unit disc plate, rim held at 1 on the upper half and 0 on the lower half.  u(x) = chance a
# Brownian path from x leaves through the upper half.  Four roads to u(0, 0.5): the closed form,
# the Poisson integral by Simpson's rule, walk-on-spheres, and time-stepped Brownian motion.
import math

M64 = (1 << 64) - 1

class SplitMix64:  # seeded random numbers, written out so Rust can repeat them exactly
    def __init__(self, seed):
        self.s = seed
    def unif(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53

def exact(x, y):  # Road 1: closed form for the half-hot rim
    return 0.5 + math.atan(2 * y / (1 - x * x - y * y)) / math.pi

def kernel(x, y, s):  # Poisson kernel: weight of rim angle s seen from (x, y)
    return (1 - x * x - y * y) / ((math.cos(s) - x) ** 2 + (math.sin(s) - y) ** 2)

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))) * h / 3

def wos(x0, y0, eps, n, rng, dist, read):  # walk-on-spheres in the plane
    tot = sq = 0.0
    jumps = 0
    for _ in range(n):
        x, y = x0, y0
        while True:
            d = dist(x, y)
            if d < eps:
                break
            a = 2 * math.pi * rng.unif()
            x += d * math.cos(a)
            y += d * math.sin(a)
            jumps += 1
        v = read(x, y)
        tot += v
        sq += v * v
    m = tot / n
    return m, math.sqrt((sq / n - m * m) / n), jumps / n

disc = lambda x, y: 1 - math.hypot(x, y)
top = lambda x, y: 1.0 if y > 0 else 0.0
x0, y0 = 0.0, 0.5
u = exact(x0, y0)
print("example: unit disc, rim 1 on top half, 0 on bottom half, start (0, 0.5)")
print(f"centre u(0,0) = {exact(0, 0):.6f}")
print(f"road 1 closed form 1/2 + atan(1/0.75)/pi = {u:.6f}")
r1 = 2 / math.pi * math.atan((1 + y0) / (1 - y0))
print(f"road 1b on the axis (2/pi) atan(3) = {r1:.6f}")
g = 2 * y0 / (1 - y0 * y0)
print(f"by hand: 1 - r^2 = {1 - y0 * y0:.6f}, 2y/(1 - r^2) = {g:.6f}, atan = {math.atan(g):.6f}, "
      f"/pi = {math.atan(g) / math.pi:.6f}, atan(3) = {math.atan(3):.6f}")
pint = simpson(lambda s: kernel(x0, y0, s), 0, math.pi) / (2 * math.pi)
print(f"road 2 Poisson integral over top half = {pint:.6f}")
print(f"kernel weights: top (0,1) {kernel(x0, y0, math.pi / 2):.6f}, bottom (0,-1) "
      f"{kernel(x0, y0, -math.pi / 2):.6f}, sides (1,0) {kernel(x0, y0, 0):.6f}")
assert abs(pint - u) < 1e-9
assert abs(r1 - u) < 1e-12
off = simpson(lambda s: kernel(0.6, 0.3, s), 0, math.pi) / (2 * math.pi)
print(f"off the axis (0.6, 0.3): closed form {exact(0.6, 0.3):.6f}, Poisson {off:.6f}")
assert abs(off - exact(0.6, 0.3)) < 1e-9
rng = SplitMix64(20261123)
m, se, j = wos(x0, y0, 1e-4, 100000, rng, disc, top)
print(f"road 3 walk-on-spheres, 100000 walks, eps 1e-4: {m:.6f} +- {se:.6f}, mean jumps {j:.2f}")
assert abs(m - u) < 4 * se
up = tsum = 0.0
h, n = 1e-3, 10000
for _ in range(n):
    x, y, t = x0, y0, 0.0
    while x * x + y * y < 1:
        g = math.sqrt(-2 * h * math.log(1 - rng.unif()))
        a = 2 * math.pi * rng.unif()
        x += g * math.cos(a)
        y += g * math.sin(a)
        t += h
    up += 1.0 if y > 0 else 0.0
    tsum += t
p = up / n
sp = math.sqrt(p * (1 - p) / n)
print(f"road 4 time steps of 0.001, 10000 paths: {p:.6f} +- {sp:.6f}, steps per path {tsum / n / h:.1f}")
assert abs(p - u) < 4 * sp
print(f"mean exit time: Dynkin (1 - 0.25)/2 = {(1 - x0 * x0 - y0 * y0) / 2:.6f}, time steps {tsum / n:.6f}")
ring = sum(exact(0.3 * math.cos(2 * math.pi * k / 3600), y0 + 0.3 * math.sin(2 * math.pi * k / 3600))
           for k in range(3600)) / 3600
print(f"mean value: average of u on circle radius 0.3 round (0,0.5) = {ring:.6f}")
assert abs(ring - u) < 1e-9
dh = 1e-3
lap = (exact(dh, y0) + exact(-dh, y0) + exact(0, y0 + dh) + exact(0, y0 - dh) - 4 * u) / dh ** 2
print(f"Laplacian by differences at (0,0.5) = {lap:.6f}")
assert abs(lap) < 1e-4
print("what breaks:")
print(f"  rim treated as uniform: {simpson(lambda s: 1.0, 0, math.pi) / (2 * math.pi):.6f}")
print(f"  nearest rim point (0,1) read off: {top(0, 1):.6f}")
mb, sb, jb = wos(x0, y0, 0.3, 100000, rng, disc, top)
print(f"  walk-on-spheres with eps 0.3: {mb:.6f} +- {sb:.6f}, mean jumps {jb:.2f}")
assert mb - u > 5 * sb
print("hole of radius delta at the centre, held at 1; outer rim 0; start at distance 0.5:")
for e in (0.1, 0.01, 1e-3, 1e-6):
    print(f"  delta = {e:g}: u = ln 0.5 / ln delta = {math.log(0.5) / math.log(e):.6f}")
ma, sa, ja = wos(x0, y0, 1e-4, 20000, rng, lambda x, y: min(math.hypot(x, y) - 0.1, disc(x, y)),
                 lambda x, y: 1.0 if math.hypot(x, y) < 0.55 else 0.0)
print(f"  delta = 0.1 by walk-on-spheres, 20000 walks: {ma:.6f} +- {sa:.6f}")
assert abs(ma - math.log(0.5) / math.log(0.1)) < 4 * sa
print("chart: u up the vertical diameter, exact and walk-on-spheres (20000 walks each)")
for k in range(-3, 4):
    yk = 0.3 * k
    mk, sk, _ = wos(0.0, yk, 1e-4, 20000, rng, disc, top)
    print(f"  y = {yk:+.1f}: exact {exact(0, yk):.6f}, walks {mk:.6f} +- {sk:.6f}")
    assert abs(mk - exact(0, yk)) < 4 * sk + 1e-12
b3 = (1 - y0 ** 2) / (2 * y0) * (1 / (1 - y0) - 1 / math.sqrt(1 + y0 ** 2))
i3 = (1 - y0 ** 2) / 2 * simpson(lambda c: (1 - 2 * y0 * c + y0 ** 2) ** -1.5, 0, 1)
hit = 0.0
for _ in range(20000):
    x, y, z = 0.0, 0.0, y0
    while (d := 1 - math.sqrt(x * x + y * y + z * z)) >= 1e-4:
        c = 2 * rng.unif() - 1
        a = 2 * math.pi * rng.unif()
        w = math.sqrt(1 - c * c)
        x, y, z = x + d * w * math.cos(a), y + d * w * math.sin(a), z + d * c
    hit += 1.0 if z > 0 else 0.0
q = hit / 20000
sq3 = math.sqrt(q * (1 - q) / 20000)
print(f"ball in 3D, top half held at 1, start (0,0,0.5): formula {b3:.6f}, integral {i3:.6f}, "
      f"walks {q:.6f} +- {sq3:.6f}")
assert abs(b3 - i3) < 1e-9
assert abs(q - b3) < 4 * sq3
print("ALL CHECKS PASS")
