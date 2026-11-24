# Cauchy's theorem for cycles -- the check behind the card.  Standard library only.
# The washer 1 < |z| < 3 holds the cycle C(2) - C(1.5): the circle of radius 2
# anticlockwise, minus the circle of radius 1.5.  Road one integrates along each
# circle.  Road two never integrates: it adds up the turns of the arrow z - a.
# Then Dixon's formula, and a disc with two holes.
import cmath
PI, N, TAU = cmath.pi, 4000, 2j * cmath.pi

def ring(c, r):                       # N + 1 points once round a circle, anticlockwise
    return [c + r * cmath.exp(2j * PI * k / N) for k in range(N + 1)]

def integral(f, cycle):               # cycle: list of (whole-number coefficient, centre, radius)
    return sum(n * sum(f(z) * (z - c) * 2j * PI / N for z in ring(c, r)[:N]) for n, c, r in cycle)

def winding(cycle, a):                # road two: net turns of z - a, added step by step
    return sum(n * sum(cmath.phase((p[k + 1] - a) / (p[k] - a)) for k in range(N))
               for n, c, r in cycle for p in [ring(c, r)]) / (2 * PI)

def cl(x): return 0.0 if abs(x) < 5e-7 else x
def fmt(z): return f"{cl(z.real):.6f} {'-' if cl(z.imag) < 0 else '+'} {abs(cl(z.imag)):.6f}i"
def fig(z): return f"({150 + 40 * z.real:.0f}, {150 - 40 * z.imag:.0f})"

f = lambda z: 1 / z                                             # holomorphic on the washer
outer, inner, sigma = [(1, 0, 2.0)], [(1, 0, 1.5)], [(1, 0, 2.0), (-1, 0, 1.5)]
print(f"figure, 40 px per unit: centre {fig(0j)}, radius 1 {fig(1 + 0j)}, radius 1.5 {fig(1.5 + 0j)}, "
      f"radius 2 {fig(2j)}, radius 3 {fig(3 + 0j)}, point 1.75 {fig(1.75 + 0j)}")
for name, cyc in [("circle radius 2 alone", outer), ("circle radius 1.5 alone", inner), ("cycle C(2) - C(1.5)", sigma)]:
    I, w = integral(f, cyc), winding(cyc, 0)
    print(f"{name}: integral of 1/z = {fmt(I)}; turns round 0 = {cl(w):.6f}")
    assert abs(I / TAU - w) < 1e-9                              # the two roads agree
outside = [0, 0.5, 0.9j, 3.2, -4, 5 + 5j]
ws = [winding(sigma, a) for a in outside]
print(f"cycle's turns round 0, 0.5, 0.9i, 3.2, -4, 5 + 5i, all off the washer: {[round(w) for w in ws]}")
assert all(abs(w) < 1e-9 for w in ws) and abs(integral(f, sigma)) < 1e-12   # homologous to zero, integral 0
for z0 in [1.75, 2.5]:
    val, dix = integral(lambda w: f(w) / (w - z0), sigma) / TAU, integral(lambda w: (f(w) - f(z0)) / (w - z0), sigma)
    print(f"at {z0}: (1/2 pi i) x integral of f(w)/(w - {z0}) = {fmt(val)}; f({z0}) = {f(z0):.6f}; turns x f({z0}) = "
          f"{cl(winding(sigma, z0) * f(z0)):.6f}; Dixon's integral = {fmt(dix)}")
    assert abs(val - round(winding(sigma, z0)) / z0) < 1e-9 and abs(dix) < 1e-9
g = lambda z: 1 / (z - 1.5) + 3 / (z + 1.5)                     # two holes, strengths 1 and 3
big, east, west = [(1, 0, 3.0)], [(1, 1.5, 1.0)], [(1, -1.5, 1.0)]
sig2 = big + [(-1, 1.5, 1.0), (-1, -1.5, 1.0)]
print(f"two holes, integral of g: big circle {fmt(integral(g, big))}; round 1.5 {fmt(integral(g, east))}; "
      f"round -1.5 {fmt(integral(g, west))}")
w1, w2 = winding(sig2, 1.5), winding(sig2, -1.5)
print(f"big circle minus both small circles: integral = {fmt(integral(g, sig2))}; turns round 1.5 and -1.5: {cl(w1):.6f}, {cl(w2):.6f}")
assert abs(integral(g, big) - TAU * 4) < 1e-9 and abs(integral(g, sig2) - TAU * (w1 + 3 * w2)) < 1e-9
val0 = integral(lambda w: g(w) / w, sig2) / TAU
print(f"at 0: (1/2 pi i) x integral of g(w)/w = {fmt(val0)}; by hand -1/1.5 + 3/1.5 = {4 / 3:.6f}")
assert abs(val0 - 4 / 3) < 1e-9
m = [integral(f, outer), integral(f, [(1, 0, 2.0), (1, 0, 1.5)]), integral(g, big + [(-1, 1.5, 1.0)])]
print(f"mistake 1, outer circle alone: {fmt(m[0])}, not 0")
print(f"mistake 2, inner circle added, not subtracted: {fmt(m[1])}, not 0")
print(f"mistake 3, two holes, circle round -1.5 forgotten: {fmt(m[2])}, not 0")
assert abs(m[0] - TAU) < 1e-9 and abs(m[1] - 2 * TAU) < 1e-9 and abs(m[2] - 3 * TAU) < 1e-9
print("ALL CHECKS PASS")
