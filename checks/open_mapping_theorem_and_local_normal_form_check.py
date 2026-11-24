# Local normal form and the open mapping theorem -- the check behind the card.  Standard library only.
# f(z) = cos z near 0: cos z - 1 starts with -z^2/2, so m = 2 and cos z = 1 - h(z)^2, h(z) = sqrt2 sin(z/2).
# Road one: closed forms through h.  Road two: Newton's method on cos z = w.  Road three: the argument
# principle, a trapezoid sum of f'/(f - w) round a circle, which counts preimages without finding them.
import math

def ccos(z): return complex(math.cos(z.real) * math.cosh(z.imag), -math.sin(z.real) * math.sinh(z.imag))
def csin(z): return complex(math.sin(z.real) * math.cosh(z.imag), math.cos(z.real) * math.sinh(z.imag))
def h(z): return math.sqrt(2) * csin(z / 2)                  # the new coordinate: cos z = 1 - h(z)^2

def contour(F, c, r, n=400):          # (1/2 pi i) times the integral of F(z) dz round |z - c| = r
    es = [complex(math.cos(2 * math.pi * j / n), math.sin(2 * math.pi * j / n)) for j in range(n)]
    return sum(F(c + r * e) * r * e for e in es) / n
def count(w, c=0, r=0.5): return contour(lambda z: -csin(z) / (ccos(z) - w), c, r).real
def newton(w, z):                     # repeated tangent-line steps towards a root of cos z - w
    for _ in range(50): z -= (ccos(z) - w) / (-csin(z))
    return z
def fmt(z):                           # 'a + bi', six decimals, no minus sign on a zero
    re, im = (0.0 if abs(v) < 5e-7 else v for v in (z.real, z.imag))
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

c1, c2 = (contour(lambda z, k=k: (ccos(z) - 1) / z ** (k + 1), 0, 0.5) for k in (1, 2))
dh = contour(lambda z: h(z) / z ** 2, 0, 0.5)               # h'(0) as a Cauchy coefficient
z1, z2 = newton(0.98, 0.3 + 0j), newton(0.98, -0.3 + 0j)
u1, u2 = newton(1 + 0.1j, 0.3 - 0.3j), newton(1 + 0.1j, -0.3 + 0.3j)
ring = [0.5 * complex(math.cos(2 * math.pi * j / 720), math.sin(2 * math.pi * j / 720)) for j in range(720)]
delta, grid, top = 1 - math.cos(0.5), min(abs(ccos(z) - 1) for z in ring), max(abs(ccos(z) - 1) for z in ring)
v = newton(1.05, 0.3j)
a1 = math.cos(1) + 0.01
inv = contour(lambda z: z * -csin(z) / (ccos(z) - a1), 1, 0.3)   # the inverse, as a contour integral
inv0 = contour(lambda z: z * -csin(z) / (ccos(z) - 0.98), 0, 0.5)  # the same integral at 0, where m = 2
k = lambda x: 110 + 150 * x
print(f"figure, left 150 px per unit, 0 at (110, 110), circle radius 75, preimages of 0.98 at x {k(z2.real):.2f} and {k(z1.real):.2f}, "
      f"of 1.05 at y {110 - 150 * v.imag:.2f} and {110 + 150 * v.imag:.2f}; right 600 px per unit, 1 at (330, 110), delta radius {600 * delta:.2f}")
print(f"Taylor coefficients of cos z - 1 at 0: c1 = {fmt(c1)}, c2 = {fmt(c2)}, so m = 2")
print(f"h'(0) by contour = {fmt(dh)}; 1/sqrt2 = {1 / math.sqrt(2):.6f}")
print(f"1 m pendulum, bob 0.02 m up: cos theta = {1 - 0.02 / 1:.2f}; 2 asin(0.1) = {2 * math.asin(0.1):.6f}; "
      f"arccos 0.98 = {math.acos(0.98):.6f} rad = {math.degrees(math.acos(0.98)):.6f} degrees")
print(f"preimages of 0.98 by Newton from 0.3 and -0.3: {fmt(z1)} and {fmt(z2)}")
print(f"h at them: {fmt(h(z1))} and {fmt(h(z2))}; sqrt(1 - 0.98) = {math.sqrt(0.02):.6f}")
print(f"count of preimages of 0.98 in |z| < 0.5: {count(0.98):.6f}; in |z| < 7: {count(0.98, 0, 7):.6f}")
print(f"preimages of 1 + 0.1i: {fmt(u1)} and {fmt(u2)}; count {count(1 + 0.1j):.6f}")
print(f"h at them: {fmt(h(u1))} and {fmt(h(u2))}")
print(f"open disc: delta = 1 - cos 0.5 = {delta:.6f}; min |cos z - 1| on |z| = 0.5 = {grid:.6f}")
print(f"largest |cos z - 1| on |z| = 0.5 = {top:.6f}; cosh 0.5 - 1 = {math.cosh(0.5) - 1:.6f}")
print(f"maximum modulus: |cos 0| = 1; 1.05 is hit at {fmt(v)}; arccosh 1.05 = {math.acosh(1.05):.6f}")
print(f"inverse near a = 1: f'(1) = {-math.sin(1):.6f}; w = {a1:.6f}; count in |z - 1| < 0.3 = {count(a1, 1, 0.3):.6f}")
print(f"inverse by contour = {fmt(inv)}; arccos w = {math.acos(a1):.6f}")
print(f"break 1, m = 1 assumed at 0: the inverse integral for 0.98 gives {fmt(inv0)}, the sum of both preimages; the count says {count(0.98):.0f}")
print(f"break 2, real cos on (-0.5, 0.5): image ({math.cos(0.5):.6f}, 1], not open; real maximum 1 at 0")
print(f"break 3, w = 0.85 outside the delta disc: count {count(0.85):.6f}; its preimages +-{math.acos(0.85):.6f} lie outside")
print(f"break 4, disc sized by |f'(0)| x 0.5 = {abs(-math.sin(0)) * 0.5:.6f}, yet delta = {delta:.6f}")
assert abs(z1 - 2 * math.asin(0.1)) < 1e-12 and abs(z2 + math.acos(0.98)) < 1e-12        # Newton = closed form
assert abs(count(0.98) - 2) < 1e-9 and abs(count(1 + 0.1j) - 2) < 1e-9 and abs(count(0.85)) < 1e-9 and abs(count(0.98, 0, 7) - 6) < 1e-9
assert abs(h(u1) ** 2 - (1 - (1 + 0.1j))) < 1e-12 and abs(u1 + u2) < 1e-12              # h sends preimages to roots
assert abs(grid - delta) < 1e-12 and abs(v.imag - math.acosh(1.05)) < 1e-12           # open disc; modulus beaten
assert abs(c1) < 1e-9 and abs(dh - 1 / math.sqrt(2)) < 1e-9 and abs(top - (math.cosh(0.5) - 1)) < 1e-12 and abs(inv0 - (z1 + z2)) < 1e-9  # m = 2; h'(0); top; sum
assert abs(count(a1, 1, 0.3) - 1) < 1e-9 and abs(inv - math.acos(a1)) < 1e-9 and abs(c2 + 0.5) < 1e-9
print("ALL CHECKS PASS")
