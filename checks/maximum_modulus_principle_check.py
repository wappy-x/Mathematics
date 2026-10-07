# The maximum modulus principle -- the check behind the card.  Standard library only.
# f(z) = e^z and g(z) = z^2 + 1 on the closed unit disc |z| <= 1.  Road one: closed
# forms (|e^z| = e^x, the triangle inequality, a series).  Road two: a polar grid
# searched point by point, and circle averages by the trapezoid rule.
import math

def cis(t): return complex(math.cos(t), math.sin(t))
def f(z): return math.exp(z.real) * cis(z.imag)          # e^z = e^x (cos y + i sin y)
def g(z): return z * z + 1
def s(z): return (f(z) - 1) / (math.e - 1)                 # a disc map fixing 0, for Schwarz

def ring(h, r, n=720):                   # (|h|, z) at n points round the circle |z| = r
    return [(abs(h(z)), z) for z in (r * cis(2 * math.pi * j / n) for j in range(n))]

def disc(h, R=1.0, nr=50):               # the same on 51 circles filling |z| <= R
    return [p for k in range(nr + 1) for p in ring(h, R * k / nr)]

def mean(h, n, r=1.0):                   # trapezoid average of h round |z| = r
    return sum(h(r * cis(2 * math.pi * j / n)) for j in range(n)) / n

def fmt(z):                              # 'a + bi', six decimals, no minus sign on a zero
    re, im = (0.0 if abs(v) < 5e-7 else v for v in (z.real, z.imag))
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"
top = lambda ps: max(ps, key=lambda p: p[0])
low = lambda ps: min(ps, key=lambda p: p[0])

mf, zf = top(disc(f))
mg, zg = top(disc(g))
nf, znf = low(disc(f))
series = sum(1 / (4 ** k * math.factorial(k) ** 2) for k in range(30))   # mean of e^cos t
avg_abs = mean(lambda z: abs(f(z)), 64).real
print("figure, scale 90 px per unit, 0 at (180, 120); 1 at (270, 120); -1 at (90, 120); i at (180, 30); -i at (180, 210); circle radius 90")
print(f"e^z: closed form e^1 = {math.e:.6f} at 1; grid max {mf:.6f} at {fmt(zf)}")
print(f"z^2 + 1: bound |z|^2 + 1 = 2.000000; grid max {mg:.6f} at {fmt(zg)}; |g(-1)| = {abs(g(-1)):.6f}")
print("chart, r:", " ".join(f"{k / 5:.1f}" for k in range(6)))
print("chart, largest |e^z| on |z| = r:", " ".join(f"{top(ring(f, k / 5))[0]:.2f}" for k in range(6)))
print("chart, largest |z^2 + 1| on |z| = r:", " ".join(f"{top(ring(g, k / 5))[0]:.2f}" for k in range(6)))
print("mean of e^z round |z| = 1, error with 4, 8, 16 points:", " ".join(f"{abs(mean(f, n) - 1):.9f}" for n in (4, 8, 16)))
print(f"f(0) = {fmt(f(0j))}; mean of f round |z| = 1 (64 points) = {fmt(mean(f, 64))}")
print(f"mean of |e^z| round |z| = 1: trapezoid {avg_abs:.6f}; series {series:.6f}; |f(0)| = {abs(f(0j)):.6f}")
print(f"minimum of |e^z|: closed form e^-1 = {math.exp(-1):.6f} at -1; grid min {nf:.6f} at {fmt(znf)}")
d0 = mean(lambda z: s(z) / z, 64, 0.5)
print(f"Schwarz, s(z) = (e^z - 1)/(e - 1): s'(0) as mean of s(z)/z = {d0.real:.6f}; 1/(e - 1) = {1 / (math.e - 1):.6f}")
print(f"Schwarz: |s(0.5)| = {abs(s(0.5 + 0j)):.6f} <= 0.5; |s(-0.5)| = {abs(s(-0.5 + 0j)):.6f} <= 0.5")
print(f"break 1, not holomorphic, 1 - |z|^2: centre {1 - abs(0j) ** 2:.6f}, edge {1 - abs(cis(1.0)) ** 2:.6f}")
m2, z2 = low(disc(g, 2.0))
print(f"break 2, zeros inside, z^2 + 1 on |z| <= 2: inside min {m2:.6f} at {fmt(z2)}; edge min {low(ring(g, 2.0))[0]:.6f}")
print(f"break 3, unbounded, Re z >= 0: |e^(2i)| = {abs(f(2j)):.6f} on the edge; |e^1| = {abs(f(1 + 0j)):.6f} inside")
print(f"break 4, mean of |f| taken for |f(0)|: {avg_abs:.6f}, not {abs(f(0j)):.6f}")
assert abs(mf - math.e) < 1e-12 and abs(zf - 1) < 1e-12        # grid peak = closed form, at z = 1
assert abs(mg - 2.0) < 1e-12 and abs(zg * zg - 1) < 1e-12        # grid peak = triangle bound, at 1 or -1
assert abs(avg_abs - series) < 1e-12 and abs(mean(f, 64) - f(0j)) < 1e-12   # mean of |f|; mean of f = f(0)
assert abs(nf - math.exp(-1)) < 1e-12 and abs(znf + 1) < 1e-12   # minimum version, at z = -1
print("ALL CHECKS PASS")
