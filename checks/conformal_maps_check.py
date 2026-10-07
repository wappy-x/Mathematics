# Conformal maps -- the check behind the card.  Standard library only; the
# complex log is built here from ln|z| and atan2.  Two roads each time: the
# derivative formula against measured chords, and the chart-makers' Mercator
# formula against the globe pushed through stereographic projection and the log.
from math import atan2, log, sqrt, sin, cos, tan, pi, radians, degrees, exp

def c(z): return f"{z.real:.6f} {'-' if z.imag < 0 else '+'} {abs(z.imag):.6f}i"
def turn(u, v): return degrees(atan2((u.conjugate() * v).imag, (u.conjugate() * v).real))
def clog(z): return complex(log(abs(z)), atan2(z.imag, z.real))
def f(z): return z * z
def root(w, z=1.0):                          # local inverse of z^2: Newton's method from 1
    for _ in range(60): z = z - (z * z - w) / (2 * z)
    return z
def globe(p, l): return (cos(p) * cos(l), cos(p) * sin(l), sin(p))
def stereo(P): return complex(P[0], P[1]) / (1 + P[2])   # from the south pole onto the equator's plane
def merc(p, l): return -1j * clog(stereo(globe(p, l)))    # road 2: the log of the stereographic globe

a = 1 + 1j
fa = 2 * a                                                # road 1: f'(z) = 2z
q = [(f(a + h) - f(a)) / h for h in (1e-7, 1e-7j, 1e-7 * (1 + 1j))]
print(f"f'(1 + i) = {c(fa)}; scale |f'| = {abs(fa):.6f}; turn arg f' = {turn(1, fa):.6f} degrees")
print("measured (f(a+h) - f(a))/h, h east, north, north-east: " + "; ".join(c(x) for x in q))
chords = [turn(f(a + s) - f(a), f(a + s * (1 + 1j)) - f(a)) for s in (0.1, 0.01, 0.001)]
print("image chords of directions 1 and 1 + i, steps 0.1, 0.01, 0.001: " + ", ".join(f"{x:.6f}" for x in chords))
rays = [turn(1, f(0.1 * complex(cos(t), sin(t)))) for t in (0, pi / 4)]
print(f"at 0, where f' = 0: rays at 0 and 45 degrees land at {rays[0]:.6f} and {rays[1]:.6f} degrees")
print(f"z-bar: directions at 0 and 45 degrees land at 0 and {turn(1, (1 + 1j).conjugate()):.6f} degrees")
g, h = root(2j), 1e-7 * (1 + 2j)
dg = (root(2j + h) - g) / h
print(f"local inverse: g(2i) = {c(g)}; 1/f'(g(2i)) = {c(1 / (2 * g))}; measured slope = {c(dg)}")
print(f"not one-to-one: (1 + i)^2 = {c(f(1 + 1j))} and (-1 - i)^2 = {c(f(-1 - 1j))}")
phi, lam, d = radians(72), radians(-40), 1e-6
z = stereo(globe(phi, lam))
r, w, y_formula = abs(z), merc(phi, lam), log(tan(pi / 4 + phi / 2))   # road 1: Mercator's formula
print(f"latitude 72, longitude -40: stereographic radius r = {r:.6f}; log z = {c(clog(z))}")
print(f"Mercator by formula: x = {lam:.6f}, y = {y_formula:.6f}; by -i log z: {c(w)}")
east = abs(merc(phi, lam + d / cos(phi)) - w) / d         # a ground step d due east, measured on the map
chain = (1 + r * r) / 2 / r                                # stereographic stretch times |(log z)'| = 1/r
print(f"stretch at 72 degrees: 1/cos = {1 / cos(phi):.6f}; chain (1+r^2)/(2r) = {chain:.6f}; "
      f"measured = {east:.6f}; area x {1 / cos(phi) ** 2:.6f}")
ne = merc(phi + d / sqrt(8), lam + d / sqrt(8) / cos(phi)) - merc(phi - d / sqrt(8), lam - d / sqrt(8) / cos(phi))
equator = abs(merc(0, lam + d) - merc(0, lam)) / d
print(f"a 45-degree bearing on the globe draws at {turn(ne, 1j):.6f} degrees; stretch at the equator {equator:.6f}")
arrows = [(40 + 60 * p.real, 200 - 60 * p.imag) for p in (a, a + 0.5, a + 0.5 * (1 + 1j))]
arrows += [(200 + 40 * p.real, 220 - 40 * p.imag) for p in (f(a), f(a) + fa * 0.5, f(a) + fa * 0.5 * (1 + 1j))]
print("figure, tangent arrows svg: " + " ".join(f"{x:.1f},{y:.1f}" for x, y in arrows))
spiral = [(95 + 80 * exp(-t) * cos(t), 120 - 80 * exp(-t) * sin(t)) for t in [k * pi / 8 for k in range(9)]]
print("figure, spiral e^((-1+i)t) svg: " + " ".join(f"{x:.1f},{y:.1f}" for x, y in spiral))
print(f"figure, Mercator line (1+i)t svg: 215.0,200.0 to {215 + 40 * pi:.1f},{200 - 40 * pi:.1f}")
assert all(abs(x - fa) < 1e-6 for x in q) and abs(chords[2] - 45) < 0.02 < abs(chords[0] - 45)
assert abs(dg - 1 / (2 * g)) < 1e-6 and abs(g - (1 + 1j)) < 1e-12 and abs(rays[1] - 90) < 1e-9
assert abs(w.imag - y_formula) < 1e-12 and abs(w.real - lam) < 1e-12 and abs(chain - 1 / cos(phi)) < 1e-12
assert abs(east - 1 / cos(phi)) < 1e-5 and abs(turn(ne, 1j) - 45) < 1e-6 and abs(equator - 1) < 1e-5
print("ALL CHECKS PASS")
