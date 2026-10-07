# Contour integrals -- the check behind the card.  Standard library only.
# The track is the circle z(t) = r e^(it), t from 0 to 2 pi, run anticlockwise.
# Road one: the values worked by hand on the card (z^n dz gives 2 pi i only at n = -1).
# Road two: the sum of f(z_k) times each stride z_(k+1) - z_k, the definition itself,
# and a trapezoid sum of f(z(t)) z'(t) dt over the parameter t, with z'(t) = i z(t).
import math

def point(t, r=1.0):
    return complex(r * math.cos(t), r * math.sin(t))

def strides(f, n):                            # sum of f(z_k) (z_(k+1) - z_k), one lap
    zs = [point(2 * math.pi * k / n) for k in range(n + 1)]
    return sum(f(zs[k]) * (zs[k + 1] - zs[k]) for k in range(n))

def trap(f, t0=0.0, t1=2 * math.pi, r=1.0, n=512):   # trapezoid on f(z(t)) z'(t)
    h = (t1 - t0) / n
    g = [f(point(t0 + k * h, r)) * 1j * point(t0 + k * h, r) for k in range(n + 1)]
    return h * (sum(g) - (g[0] + g[-1]) / 2)

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

bar, ident, inv = lambda z: z.conjugate(), lambda z: z, lambda z: 1 / z
h = lambda z: math.e ** z.real * point(z.imag) / z ** 2          # e^z / z^2
hand = 2j * math.pi                                              # road one, by hand
series = sum(hand / math.factorial(n) for n in range(12) if n - 2 == -1)
R = 400 / (2 * math.pi)                                          # a 400 m lap, in metres
bar1, z1, inv1, h1 = trap(bar), trap(ident), trap(inv), trap(h)
cw, twice = trap(inv, 2 * math.pi, 0.0), trap(inv, 0.0, 4 * math.pi, n=1024)
upper, lower = trap(inv, 0.0, math.pi), trap(inv, math.pi, 2 * math.pi)
L = sum(abs(point(2 * math.pi * (k + 1) / 65536) - point(2 * math.pi * k / 65536)) for k in range(65536))
M = max(abs(h(point(2 * math.pi * k / 3600))) for k in range(3600))
print(f"a 400 m lap has radius {R:.6f} m; in units of the radius, length L = {L:.6f}")
print(f"z-bar dz, one lap: trapezoid {show(bar1)}; by hand 2 pi i = {show(hand)}")
print(f"z dz, one lap: trapezoid {show(z1)}; by hand 0")
print(f"dz/z, one lap: trapezoid {show(inv1)}; by hand 2 pi i")
print(f"dz/z, clockwise {show(cw)}; two laps {show(twice)}")
print(f"dz/z, upper half 1 to -1 {show(upper)}; lower half -1 to 1 {show(lower)}; joined {show(upper + lower)}")
errs = []
for n in (8, 64, 512):
    s = strides(bar, n)
    errs.append(abs(s - hand))
    print(f"z-bar dz by {n} strides: {show(s)}, off by {errs[-1]:.6f}")
print(f"in metres: z-bar dz = {show(trap(bar, r=R))} (2 pi R^2 = {2 * math.pi * R * R:.6f}); dz/z = {show(trap(inv, r=R))}")
print(f"e^z dz/z^2, one lap: trapezoid {show(h1)}; by the series {show(series)}; size {abs(h1):.6f}")
print(f"ML bound: M = {M:.6f} (at z = 1), L = {L:.6f}, M x L = {M * L:.6f} >= {abs(h1):.6f}")
print(f"mistake, dt for dz on z-bar: {show(sum(bar(point(2 * math.pi * k / 512)) for k in range(512)) * 2 * math.pi / 512)}")
print(f"mistake, M read at z = -1 only: {abs(h(-1 + 0j)):.6f} x {L:.6f} = {abs(h(-1 + 0j)) * L:.6f} < {abs(h1):.6f}")
fz, fs, fd = point(math.pi / 4), point(math.pi / 4) * (1 + 0.4j), point(3 * math.pi / 4)
print(f"figure, z ({180 + 80 * fz.real:.2f}, {120 - 80 * fz.imag:.2f}), z-bar ({180 + 80 * fz.real:.2f}, "
      f"{120 + 80 * fz.imag:.2f}), stride tip ({180 + 80 * fs.real:.2f}, {120 - 80 * fs.imag:.2f}), "
      f"arrowhead at ({180 + 80 * fd.real:.2f}, {120 - 80 * fd.imag:.2f})")
assert abs(bar1 - hand) < 1e-12 and abs(z1) < 1e-12 and abs(inv1 - hand) < 1e-12
assert errs[0] > errs[1] > errs[2] and abs(errs[2] - 2 * math.pi ** 2 / 512) < 1e-4
assert abs(h1 - series) < 1e-12 and abs(M - math.e) < 1e-9 and abs(h1) <= M * L
assert abs(cw + inv1) < 1e-12 and abs(upper + lower - hand) < 1e-12 and abs(twice - 2 * hand) < 1e-12
print("ALL CHECKS PASS")
