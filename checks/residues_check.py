# Residues -- the check behind the card.  Python standard library only.
# Three tolls, each reached by a formula and by a loop sum round a circle.
from math import cos, sin, exp, pi, floor, log10

def cexp(z):                        # e^(x+iy) = e^x (cos y + i sin y)
    return exp(z.real) * complex(cos(z.imag), sin(z.imag))

def loop(f, a, r, n):               # (1/2 pi i) x the loop integral, trapezoid, n points
    total = 0
    for k in range(n):
        w = r * complex(cos(2 * pi * k / n), sin(2 * pi * k / n))
        total += f(a + w) * w       # dz = i w dt, and dt = 2 pi / n
    return total / n

def c(z):                           # 'a + bi' with six decimals, no minus zero
    x, y = [0.0 if abs(t) < 5e-7 else t for t in (z.real, z.imag)]
    return f"{x:.6f} {'-' if y < 0 else '+'} {abs(y):.6f}i"

def sci(x):                         # 1.2e-5 style, the same in both languages
    e = floor(log10(x)); m = x / 10 ** e
    if round(m, 1) >= 10: m, e = m / 10, e + 1
    return f"{m:.1f}e{e}"

house = lambda z: 1 / (z * z + 1)
cube = lambda z: cexp(z) / z ** 3
ess = lambda z: z * cexp(1 / z)
twice = lambda z: 1 / (z * z + 1) ** 2
print("figure, 70 units per 1, 0 at (180, 135), i at (180, 65), -i at (180, 205), loop radius 35")
for h in (0.1, 0.01, 0.001):        # road 1a: the limit of (z - i) f(z)
    print(f"1/(z^2+1), limit road, (z - i) f(z) at z = i + {h}: {c(h * house(1j + h))}")
pq = 1 / (2 * 1j)                   # road 1b: p(i)/q'(i) with p = 1, q' = 2z
print(f"1/(z^2+1), p/q' road: 1/(2i) = {c(pq)} at i; 1/(-2i) = {c(1 / (-2j))} at -i")
print("1/(z^2+1), loop road r = 0.5, error: " +
      ", ".join(f"N={n} {sci(abs(loop(house, 1j, 0.5, n) - pq))}" for n in (4, 8, 12)))
res1 = loop(house, 1j, 0.5, 64)
print(f"1/(z^2+1), loop road N=64: {c(res1)}; toll 2 pi i x Res = {c(2j * pi * res1)}")
h = 1e-3                            # road 1: H = e^z, H''(0)/2! by a central difference
res2 = (cexp(h) - 2 * cexp(0) + cexp(-h)).real / h ** 2 / 2
print(f"e^z/z^3, derivative road H''(0)/2!: {res2:.6f}")
print("e^z/z^3, loop road r = 1, error: " +
      ", ".join(f"N={n} {sci(abs(loop(cube, 0, 1, n) - 0.5))}" for n in (4, 8, 12)))
res3 = 1 / 2                        # road 1: z x (1/2!) z^-2 is the only 1/z term
print(f"z e^(1/z), series road: z x 1/(2! z^2) gives {res3:.6f}")
print("z e^(1/z), loop road r = 1, error: " +
      ", ".join(f"N={n} {sci(abs(loop(ess, 0, 1, n) - res3))}" for n in (4, 8, 12)))
print(f"mistake, simple-pole limit on e^z/z^3: z f(z) at z = 0.001 is {(0.001 * cube(0.001)).real:.1f}")
print(f"mistake, dropping the 2!: H''(0) = {2 * res2:.6f}, twice the residue")
print(f"mistake, 1/z coefficient of e^(1/z) alone: {loop(lambda z: cexp(1 / z), 0, 1, 64).real:.6f}")
d4 = (1 / (1j + h + 1j) ** 2 - 1 / (1j - h + 1j) ** 2) / (2 * h)  # H = 1/(z+i)^2, H'(i)
res4 = loop(twice, 1j, 0.5, 64)
print(f"mistake, p/q' at the double pole of 1/(z^2+1)^2: q'(i) = 0; H'(i) = {c(d4)}, loop {c(res4)}")
assert abs(res1 - pq) < 1e-12                          # loop sum against p/q'
assert abs(loop(cube, 0, 1, 24) - res2) < 1e-6         # loop sum against the derivative road
assert abs(loop(ess, 0, 1, 24) - res3) < 1e-12         # loop sum against the series
assert abs(res4 - d4) < 1e-6                           # double pole: loop against H'(i)
print("ALL CHECKS PASS")
