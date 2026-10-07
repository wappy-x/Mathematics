# The Riemann mapping theorem and Schwarz-Christoffel -- the check behind the card.  Standard
# library only.  The half strip S: |Re z| < pi/2, Im z > 0.  Road one: sin z in closed form,
# then a Cayley map onto the disc.  Road two: the Schwarz-Christoffel integral of
# 1/sqrt(1 - t^2), summed by Simpson's rule, which must hit the same corners and undo sin.
import math

def sin(z):                              # sin(x + iy) = sin x cosh y + i cos x sinh y
    x, ch, sh = z.real, (math.exp(z.imag) + math.exp(-z.imag)) / 2, (math.exp(z.imag) - math.exp(-z.imag)) / 2
    return complex(math.sin(x) * ch, math.cos(x) * sh)
def root(w):                             # principal square root, from |w| and atan2
    t = math.atan2(w.imag, w.real) / 2
    return math.sqrt(abs(w)) * complex(math.cos(t), math.sin(t))
def simpson(g, n=2000):                  # integral of g over [0, 1], n even
    return (g(0) + g(1) + sum((4 if k % 2 else 2) * g(k / n) for k in range(1, n))) / (3 * n)
def sc(w):                               # Schwarz-Christoffel: 1/sqrt(1 - t^2) from 0 to w, straight path
    return simpson(lambda s: w / root(1 - (s * w) ** 2))
def cayley(w): return (w - 1j) / (w + 1j)            # upper half plane onto disc, i to 0
def F(z): return 1j * cayley(sin(z))                 # the normalised Riemann map of S
def blaschke(a, u): return (u - a) / (1 - a.conjugate() * u)
def fmt(z):                              # 'a + bi', six decimals, no minus sign on a zero
    re, im = (0.0 if abs(v) < 5e-7 else v for v in (z.real, z.imag))
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"
def d(f, z, h=1e-5): return (f(z + h) - f(z - h)) / (2 * h)
hp, q = math.pi / 2, 30
corner = simpson(lambda u: 2 / math.sqrt(2 - u * u))   # t = 1 - u^2 removes the corner blow-up
z0 = sc(1j)                                            # road two finds the point sent to the centre
w1 = 1 + 2j                                            # a second map of S, sending sin^-1(w1) to 0
G = lambda z: (sin(z) - w1) / (sin(z) - w1.conjugate())
a = 1j * cayley(w1)                                    # = F(z1), where sin z1 = w1
tests = [0.3 + 0.2j, -1.2 + 2.5j, 0.9 + 0.05j, 0.0 + 4.0j, 1.5 + 0.7j]
rot = G(tests[0]) / blaschke(a, F(tests[0]))
miss = max(abs(G(z) - rot * blaschke(a, F(z))) for z in tests)
edge = [complex(-hp + k * math.pi / 200, 0) for k in range(1, 200)] + [complex(s * hp, k / 20) for s in (-1, 1) for k in range(1, 100)]
ring = max(abs(abs(F(z)) - 1) for z in edge) + max(abs(abs(blaschke(a, complex(math.cos(k / 9), math.sin(k / 9)))) - 1) for k in range(57))
print(f"figure, {q} px per unit, 0 at (60, 210) and (180, 210); corners at ({60 - q * hp:.2f}, 210) ({60 + q * hp:.2f}, 210); "
      f"z0 at (60, {210 - q * z0.imag:.2f}); -1, 1, i at ({180 - q:.0f}, 210) ({180 + q:.0f}, 210) (180, {210 - q:.0f}); disc centre (300, 130), radius 50")
print(f"road one, corners: sin(-pi/2) = {fmt(sin(complex(-hp, 0)))}; sin(pi/2) = {fmt(sin(complex(hp, 0)))}")
print(f"road one, edges: sin(pi/2 + 1i) = {fmt(sin(complex(hp, 1)))}; sin(0.5) = {fmt(sin(0.5 + 0j))}; inside sin(0.5 + 0.5i) = {fmt(sin(0.5 + 0.5j))}")
print("road two, corner error |f(1) - pi/2| with 4, 8, 16 steps:", " ".join(f"{abs(simpson(lambda u: 2 / math.sqrt(2 - u * u), n) - hp):.9f}" for n in (4, 8, 16)))
print(f"road two, f(1) = {corner:.6f}; f(-1) = {-corner:.6f}; pi/2 = {hp:.6f}")
print(f"road two, f(i) = {fmt(z0)}; log(1 + sqrt 2) = {math.log(1 + math.sqrt(2)):.6f}")
print(f"road two, f(1 + i) = {fmt(sc(1 + 1j))}; road one, sin of that = {fmt(sin(sc(1 + 1j)))}")
print(f"Riemann map F = i(sin z - i)/(sin z + i): F(z0) = {fmt(F(z0))}; F'(z0) = {fmt(d(F, z0))}; sqrt(2)/2 = {math.sqrt(2) / 2:.6f}")
print(f"by hand: stretch of sin at z0 = {fmt(d(sin, z0))}; of the Cayley step at i = {fmt(d(cayley, 1j))}")
print(f"edges to the circle: ||F| - 1| and ||phi_a| - 1| below 1e-12 on 397 edge and 57 circle points: {'yes' if ring < 1e-12 else 'no'}; |F(0.5 + 0.5i)| = {abs(F(0.5 + 0.5j)):.6f}")
print(f"second map G, w1 = 1 + 2i: a = {fmt(a)}; rotation angle {math.atan2(rot.imag, rot.real):.6f}, |rotation| = {abs(rot):.6f}")
print(f"G equals rotation x Blaschke(a) after F at 5 points, gap below 1e-12: {'yes' if miss < 1e-12 else 'no'}")
print("break 1, the plane as a disc of radius R = 10, 100, 1000: stretch at 0 of z/R =", " ".join(f"{d(lambda z: z / R, 0j).real:.6f}" for R in (10, 100, 1000)))
print(f"break 2, strip twice as wide: sin(2.5 + 1i) = {fmt(sin(2.5 + 1j))}, below the real axis")
print(f"break 3, no rotation: (sin z - i)/(sin z + i) has derivative {fmt(d(lambda z: cayley(sin(z)), z0))} at z0")
print(f"break 4, exponent +1/2 for -1/2: corner at {simpson(lambda u: 2 * u * u * math.sqrt(2 - u * u)):.6f}, not {hp:.6f}")
assert abs(corner - hp) < 1e-9                                  # Simpson's corner = pi/2
assert abs(sin(sc(1 + 1j)) - (1 + 1j)) < 1e-9                   # the SC integral undoes sin
assert abs(F(z0)) < 1e-9 and abs(d(F, z0) - math.sqrt(2) / 2) < 1e-7   # SC's point is the centre; stretch
assert miss < 1e-12 and ring < 1e-12 and abs(abs(rot) - 1) < 1e-12   # every other map is a turn x Blaschke
print("ALL CHECKS PASS")
