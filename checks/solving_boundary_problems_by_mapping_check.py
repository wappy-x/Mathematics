# Solving by mapping -- the check behind the card.  Standard library only.
# Strip 0 < Im z < pi, walls at 0 and 100 degrees, carried to the upper half plane
# by e^z; the quarter plane carried there by z^2.  Road one: the closed forms
# 100y/pi and (200/pi) arg z.  Road two: the half-plane Poisson integral at the
# mapped point, summed by Simpson's rule.  Road three: the rule
# Laplacian(u of f) = |f'|^2 Laplacian(u), by finite differences.
import math

def ez(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
def U(w): return 100 / math.pi * math.atan2(w.imag, w.real)   # half plane: 0 right, 100 left

def poisson(w, n):                   # (1/pi) * integral over t < 0 of 100 b / ((t - a)^2 + b^2)
    a, b = w.real, w.imag            # with t = -tan p, p from 0 to pi/2; Simpson, n panels
    k = lambda p: b / ((math.sin(p) + a * math.cos(p)) ** 2 + (b * math.cos(p)) ** 2)
    h = math.pi / 2 / n
    s = k(0) + k(math.pi / 2) + sum((4 if j % 2 else 2) * k(j * h) for j in range(1, n))
    return 100 / math.pi * s * h / 3

def lap(v, x, y, h=1e-3):            # five-point Laplacian
    return (v(x + h, y) + v(x - h, y) + v(x, y + h) + v(x, y - h) - 4 * v(x, y)) / h ** 2

def fmt(z): return f"{z.real:.6f} {'-' if z.imag < 0 else '+'} {abs(z.imag):.6f}i"

z0, z1 = complex(1, 1), complex(1, 2)
w0, w1 = ez(z0), z1 * z1
strip = 100 * z0.imag / math.pi
quarter = 200 / math.pi * math.atan2(z1.imag, z1.real)
print(f"figure, 30 px per unit; strip 0 at (90, 170), top wall y = {170 - 30 * math.pi:.2f}, "
      f"z0 at ({90 + 30 * z0.real:.2f}, {170 - 30 * z0.imag:.2f}); half plane 0 at (250, 170), "
      f"e^z0 at ({250 + 30 * w0.real:.2f}, {170 - 30 * w0.imag:.2f}), "
      f"ray end ({250 + 90 * math.cos(1):.2f}, {170 - 90 * math.sin(1):.2f})")
print(f"strip, z0 = {fmt(z0)}: e^z0 = {fmt(w0)}, |e^z0| = {abs(w0):.6f}")
print(f"strip, closed form 100y/pi = {strip:.6f}; half-plane answer at e^z0 = {U(w0):.6f}")
for n in (16, 64, 256):
    p = poisson(w0, n)
    print(f"strip, Poisson integral at e^z0, {n} panels = {p:.9f}, error {abs(p - strip):.9f}")
print(f"strip walls at x = 1: U(e^1) = {U(ez(complex(1, 0))):.6f}; "
      f"U(e^(1 + pi i)) = {U(ez(complex(1, math.pi))):.6f}")
print(f"quarter, z1 = {fmt(z1)}: z1^2 = {fmt(w1)}; closed form (200/pi) arg z1 = {quarter:.6f}")
print(f"quarter, half-plane answer at z1^2 = {U(w1):.6f}; Poisson, 256 panels = {poisson(w1, 256):.6f}")
print(f"quarter walls: U(2^2) = {U(complex(4, 0)):.6f}; U((2i)^2) = {U(complex(-4, 0)):.6f}")
v1 = lambda x, y: (ez(complex(x, y)).real) ** 2          # u = (Re w)^2 has Laplacian 2
v2 = lambda x, y: ((complex(x, y) ** 2).real) ** 2
r1, r2 = 2 * abs(ez(z0)) ** 2, 2 * abs(2 * z1) ** 2        # 2 |f'|^2: f' = e^z, and 2z
print(f"rule, (Re e^z)^2 at z0: finite differences {lap(v1, 1, 1):.6f}; 2|f'|^2 = {r1:.6f}")
print(f"rule, (Re z^2)^2 at z1: finite differences {lap(v2, 1, 2):.6f}; 2|f'|^2 = {r2:.6f}")
print(f"break 1, half-plane formula on the quarter plane: at z1 {U(z1):.6f}; on the wall at 2i {U(2j):.6f}")
print(f"break 2, z^2 folds the half plane's walls: 2^2 = {fmt(complex(2, 0) ** 2)}, "
      f"(-2)^2 = {fmt(complex(-2, 0) ** 2)}")
extra = lambda z: 100 * z.imag / math.pi + ez(z).imag       # also 0 and 100 on the walls
print(f"break 3, 100y/pi + e^x sin y: walls {extra(complex(1, 0)):.6f} and "
      f"{extra(complex(1, math.pi)):.6f}; at z0 {extra(z0):.6f}; at 10 + (pi/2)i {extra(complex(10, math.pi / 2)):.6f}")
print(f"break 4, factor |f'|^2 dropped: Laplacian 2.000000 instead of {r1:.6f}")
assert abs(poisson(w0, 256) - strip) < 1e-6                 # Poisson road = 100y/pi
assert abs(poisson(w1, 256) - quarter) < 1e-6               # Poisson road = (200/pi) arg z
assert abs(lap(v1, 1, 1) - r1) < 1e-4                       # the |f'|^2 rule, e^z
assert abs(lap(v2, 1, 2) - r2) < 1e-4                       # the |f'|^2 rule, z^2
print("ALL CHECKS PASS")
