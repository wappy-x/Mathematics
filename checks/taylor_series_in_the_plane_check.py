# Taylor series in the plane -- the check behind the card.  Standard library
# only.  f(z) = 1/(1 + z^2) is expanded about a = 0 and about a = 2.  The
# coefficients come by two roads: Cauchy's integral as a trapezoid sum round a
# circle, and the recursion read off (1 + z^2) f(z) = 1.  The radius comes by
# two roads: the distance to the poles +i and -i, and the coefficients' decay.
import math

def f(z):
    return 1 / (1 + z * z)

def cauchy(g, a, r, n, m=256):           # road one: mean of g(a + r w) / (r w)^n round the circle
    s = 0
    for k in range(m):
        w = complex(math.cos(2 * math.pi * k / m), math.sin(2 * math.pi * k / m))
        s += g(a + r * w) / (r * w) ** n
    return s / m

def recursion(a, count):                 # road two: (1 + a^2) c_n + 2a c_(n-1) + c_(n-2) = 1 if n = 0
    c = []
    for n in range(count):
        p1 = c[n - 1] if n >= 1 else 0.0
        p2 = c[n - 2] if n >= 2 else 0.0
        c.append(((1.0 if n == 0 else 0.0) - 2 * a * p1 - p2) / (1 + a * a))
    return c

def partial(c, h, count):                # the first `count` terms of the series at z = a + h
    return sum(c[n] * h ** n for n in range(count))

show = lambda xs: "[" + ", ".join(f"{x:.6f}" for x in xs) + "]"

c0, c2 = recursion(0.0, 201), recursion(2.0, 201)
gap0 = max(abs(cauchy(f, 0.0, 0.5, n) - c0[n]) for n in range(7))
gap2 = max(abs(cauchy(f, 2.0, 1.0, n) - c2[n]) for n in range(7))
dist0, dist2 = abs(0 - 1j), abs(2 - 1j)                 # nearest pole, +i or -i
decay = lambda c: 1 / max(abs(c[n]) ** (1 / n) for n in range(180, 201) if c[n] != 0)
rad0, rad2 = decay(c0), decay(c2)
errs = [abs(partial(c2, -0.8, N) - f(1.2)) for N in (5, 10, 20)]
barc = [cauchy(lambda z: z.conjugate(), 0.0, 0.5, n) for n in range(7)]      # z-bar
bar = max(abs(b) for b in barc)
print(f"about 0, c0..c6 by recursion: {show(c0[:7])}")
print(f"about 0, contour sum within 1e-12 of every one: {'yes' if gap0 < 1e-12 else 'no'}")
print(f"about 2, c0..c6 by recursion: {show(c2[:7])}")
print(f"about 2, contour sum within 1e-12 of every one: {'yes' if gap2 < 1e-12 else 'no'}")
print(f"radius about 0: distance to the pole {dist0:.6f}, from the coefficients {rad0:.6f}")
print(f"radius about 2: distance to the pole {dist2:.6f}, from the coefficients {rad2:.6f}")
print(f"about 2 at z = 1.2: terms 0..4 {show([c2[n] * (-0.8) ** n for n in range(5)])}, sum {partial(c2, -0.8, 5):.6f}")
print(f"about 2 at z = 1.2: f = {f(1.2):.6f}, 60 terms = {partial(c2, -0.8, 60):.6f}")
print(f"about 2 at z = 1.2: errors after 5, 10, 20 terms {', '.join(f'{e:.10f}' for e in errs)}; ratio q = {0.8 / dist2:.6f}")
print(f"about 0 at z = 0.5: f = {f(0.5):.6f}, 60 terms = {partial(c0, 0.5, 60):.6f}")
print(f"break 1, z-bar about 0: largest of c0..c6 = {bar:.6f}, series at 0.5 gives {abs(partial(barc, 0.5, 7)):.6f}, z-bar gives {abs((0.5 + 0j).conjugate()):.6f}")
print(f"break 2, about 0 at z = 1.2: powers 0..9 {partial(c0, 1.2, 10):.6f}, powers 0..19 {partial(c0, 1.2, 20):.6f}, f = {f(1.2):.6f}")
print(f"break 3, about 2 at z = -1: 10 terms {partial(c2, -3.0, 10):.6f}, 20 terms {partial(c2, -3.0, 20):.6f}, f = {f(-1.0):.6f}")
s = 45                                                    # figure: 45 units per unit, 0 at (90, 120)
print(f"figure, 0 ({90:.1f}, {120:.1f}); 2 ({90 + 2 * s:.1f}, {120:.1f}); +i ({90:.1f}, {120 - s:.1f}); "
      f"-i ({90:.1f}, {120 + s:.1f}); 1.2 ({90 + 1.2 * s:.1f}, {120:.1f}); radii {s * dist0:.2f}, {s * dist2:.2f}")
assert gap0 < 1e-12 and gap2 < 1e-12                      # two roads to the coefficients
assert abs(partial(c2, -0.8, 60) - 1 / 2.44) < 1e-12 and abs(partial(c0, 0.5, 60) - 0.8) < 1e-12
assert abs(rad0 - dist0) < 0.01 and abs(rad2 - dist2) < 0.01     # two roads to the radius
assert abs(bar) < 1e-12 and abs(partial(c0, 1.2, 20)) > 10        # the breaks really break
print("ALL CHECKS PASS")
