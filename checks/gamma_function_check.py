# The gamma function -- the check behind the card.  Standard library only.
# Road one: Euler's integral, summed by trapezoids after t = e^u, moved left by the recurrence.
# Road two: Gauss's product n! n^z / (z(z+1)...(z+n)), which uses no integral.
# The ball volumes are checked against slicing the ball, which never mentions gamma.
import math

def e(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))   # e^z
def show(w):                                   # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def integral(z, lo=-130.0, hi=5.0, n=27000):   # t^(z-1) e^(-t) dt becomes e^(zu - e^u) du
    h, z = (hi - lo) / n, complex(z)
    f = lambda u: e(z * u - math.exp(u))
    return h * (sum(f(lo + j * h) for j in range(1, n)) + (f(lo) + f(hi)) / 2)
def gamma(z):                                  # road one: recurrence into Re z >= 1, then the integral
    z, den = complex(z), 1
    while z.real < 1: den, z = den * z, z + 1
    return integral(z) / den
def gauss(z, n):                               # n^z / z, times k/(z + k) for k = 1 to n
    p = e(z * math.log(n)) / z
    for k in range(1, n + 1): p *= k / (z + k)
    return p
def product(z):                                # road two, errors in 1/n and 1/n^2 cancelled
    z = complex(z)
    return (8 * gauss(z, 80000) - 6 * gauss(z, 40000) + gauss(z, 20000)) / 3
def slices(n, m=20000):                        # V_n = V_(n-1) times the integral of cos^n from -pi/2 to pi/2
    v, h = 1.0, math.pi / m
    for d in range(1, n + 1): v *= h * sum(math.cos(-math.pi / 2 + j * h) ** d for j in range(1, m))
    return v

fact = [math.prod(range(1, k + 1)) for k in range(6)]
sp, zc = math.sqrt(math.pi), 0.75 + 0.5j
print("Gamma(1) to Gamma(5) by the integral: " + ", ".join(f"{integral(k).real:.6f}" for k in range(1, 6)) + f"; 0! to 4!: {fact[:5]}")
print(f"Gamma(5): product {product(5).real:.6f}; 4! = {fact[4]}; mistake, read as 5! = {fact[5]}")
print(f"Gamma(1/2): integral {integral(0.5).real:.6f}; product {product(0.5).real:.6f}; sqrt(pi) {sp:.6f}")
print(f"Gamma(3/2) = {integral(1.5).real:.6f}; Gamma(5/2) = {integral(2.5).real:.6f}; 3 sqrt(pi)/4 = {3 * sp / 4:.6f}")
print(f"Gamma(-1/2): recurrence {gamma(-0.5).real:.6f}; product {product(-0.5).real:.6f}; -2 sqrt(pi) {-2 * sp:.6f}")
print(f"z = 0.75 + 0.5i: integral {show(integral(zc))}; product {show(product(zc))}")
print(f"  Gamma(z + 1) {show(integral(zc + 1))}; z Gamma(z) {show(zc * integral(zc))}")
assert abs(integral(5) - fact[4]) < 1e-9 and abs(integral(0.5) - sp) < 1e-9 and abs(product(-0.5) + 2 * sp) < 1e-7
assert abs(product(5) - 24) < 1e-6 and abs(product(zc) - integral(zc)) < 1e-7 and abs(integral(zc + 1) - zc * integral(zc)) < 1e-9
res = [(1e-6 * gamma(-k + 1e-6)).real for k in range(4)]
print("near the poles, eps Gamma(-n + eps), eps = 1e-6, n = 0 to 3: " + ", ".join(f"{r:.6f}" for r in res))
print("  (-1)^n / n!: " + ", ".join(f"{(-1) ** k / fact[k]:.6f}" for k in range(4)))
q, r = integral(0.25).real, integral(0.75).real
print(f"reflection a = 1/4: Gamma(1/4) Gamma(3/4) = {q:.6f} x {r:.6f} = {q * r:.6f}; pi/sin(pi/4) = {math.pi / math.sin(math.pi / 4):.6f}")
print(f"reflection z = -1/2: Gamma(-1/2) Gamma(3/2) = {(gamma(-0.5) * integral(1.5)).real:.6f}; pi/sin(-pi/2) = {math.pi / math.sin(-math.pi / 2):.6f}")
assert all(abs(res[k] - (-1) ** k / fact[k]) < 1e-5 for k in range(4)) and abs(q * r - math.pi * math.sqrt(2)) < 1e-9
ball = [math.pi ** (n / 2) / gamma(n / 2 + 1).real for n in range(1, 11)]
cut = [slices(n) for n in range(1, 11)]
print(f"football, n = 3: pi^(3/2)/Gamma(5/2) = {ball[2]:.6f}; slicing {cut[2]:.6f}; 4 pi/3 = {4 * math.pi / 3:.6f}")
print("ball volumes n = 1 to 10, by gamma:   " + ", ".join(f"{v:.2f}" for v in ball))
print("ball volumes n = 1 to 10, by slicing: " + ", ".join(f"{v:.2f}" for v in cut))
assert all(abs(a - b) < 1e-7 for a, b in zip(ball, cut)) and abs(ball[2] - 4 * math.pi / 3) < 1e-9
print(f"mistake, shift dropped: pi^(3/2)/Gamma(3/2) = {math.pi ** 1.5 / integral(1.5).real:.6f}, not {ball[2]:.6f}")
print("mistake, the integral at -1/2 cut off at t = 1e-2, 1e-4, 1e-6: " + ", ".join(f"{integral(-0.5, math.log(10.0 ** -k)).real:.1f}" for k in (2, 4, 6)))
print(f"mistake, recurrence alone: (1 + sin(2 pi z)/2) Gamma(z) at z = 1/4 is {1.5 * q:.6f}, not {q:.6f}")
print("figure, 0 at (230, 120), 40 per 1: poles at x = " + ", ".join(f"{230 - 40 * k}" for k in range(6))
      + f"; 1/2 at ({230 + 20}, 120); -1/2 at ({230 - 20}, 120); 0.75 + 0.5i at ({230 + 40 * 0.75:.0f}, {120 - 40 * 0.5:.0f})")
print("ALL CHECKS PASS")
