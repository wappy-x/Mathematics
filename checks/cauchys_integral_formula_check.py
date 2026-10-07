# Cauchy's integral formula -- the check behind the card.  Standard library
# only; complex numbers are Python's built-in type.  f(z) = e^z on the pizza
# stone's rim |z| = 2, run anticlockwise.  Road one: e^a from exp, cos, sin.
# Road two: the loop integral itself, a trapezoid sum round the circle.
import math

def f(z):                                  # e^z = e^x (cos y + i sin y)
    return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))

def loop(g, c, r, n, turn=1):              # trapezoid sum of g(z) dz round |z - c| = r
    total = 0
    for k in range(n):
        w = complex(math.cos(2 * math.pi * k / n), turn * math.sin(2 * math.pi * k / n))
        total += g(c + r * w) * (turn * 1j * r * w) * (2 * math.pi / n)
    return total

def cif(g, a, n=64, turn=1, div=2j * math.pi):   # (1/2 pi i) x loop of g(z)/(z - a) on |z| = 2
    return loop(lambda z: g(z) / (z - a), 0, 2, n, turn) / div

def average(g, c, r, n=64):                # plain average of g at n points on |z - c| = r
    return sum(g(c + r * complex(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)))
               for k in range(n)) / n

def show(v):                               # a + bi, six decimals, rounding noise shown as 0
    re, im = (0.0 if abs(x) < 5e-7 else x for x in (v.real, v.imag))
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def sci(x):                                # 1.2e-5 style, the same in both languages
    e = math.floor(math.log10(x)); m = round(x / 10 ** e, 1)
    return f"{m / 10:.1f}e{e + 1}" if m >= 10 else f"{m:.1f}e{e}"

print("figure, 40 units per 1: centre (150, 120), rim radius 80, a = 0.5 at (170, 120), a = 4 at (310, 120), small loop radius 20")
for a in (0, 0.5):
    print(f"a = {a}: e^a = {math.exp(a):.6f}; loop sum, 64 points = {show(cif(f, a))}")
for n in (4, 8, 16):
    print(f"a = 0.5, {n} points: error {sci(abs(cif(f, 0.5, n) - math.exp(0.5)))}")
print(f"rim average round 0, radius 2 = {show(average(f, 0, 2))}")
for r in (1.5, 0.5, 0.1):
    print(f"average round 0.5, radius {r} = {show(average(f, 0.5, r))}")
pole = loop(lambda z: f(z) / (z * (z - 3)), 0, 2, 128)
print(f"loop of e^z / (z (z - 3)): by formula 2 pi i x e^0 / (0 - 3) = {show(2j * math.pi / -3)}; loop sum, 128 points = {show(pole)}")
print(f"mistake 1, a = 4 outside the rim: loop gives {show(cif(f, 4))}, not e^4 = {math.exp(4):.6f}")
zbar = cif(lambda z: z.conjugate(), 0.5)
print(f"mistake 2, z-bar in place of e^z at a = 0.5: loop gives {show(zbar)}, not 0.500000")
print(f"mistake 3, loop run clockwise: {show(cif(f, 0.5, turn=-1))}")
print(f"mistake 4, dividing by 2 pi instead of 2 pi i: {show(cif(f, 0.5, div=2 * math.pi))}")
assert abs(cif(f, 0.5) - math.exp(0.5)) < 1e-12 and abs(cif(f, 0) - 1) < 1e-12   # two roads meet
assert all(abs(average(f, 0.5, r) - math.exp(0.5)) < 1e-12 for r in (1.5, 0.5, 0.1))
assert abs(pole - 2j * math.pi / -3) < 1e-12                                       # one simple pole
assert abs(cif(f, 4)) < 1e-12 and abs(zbar) < 1e-12                               # outside, and no holomorphy
print("ALL CHECKS PASS")
