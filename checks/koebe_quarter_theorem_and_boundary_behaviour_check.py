# Koebe's quarter theorem -- the check behind the card.  Standard library only.  The Koebe
# function k(z) = z/(1 - z)^2 is tested twice over: coefficients by closed form and by an
# average round a circle, areas by the area formula and by a polygon (shoelace) sum, the
# nearest missed point by formula and by a search, boundary values by formula and directly.
import cmath, math
def k(z): return z / (1 - z) ** 2
def coeffs(f, n, r=0.5, m=256):             # a_j = average of f(r e^it) e^(-ijt), over r^j
    ts = [2 * math.pi * s / m for s in range(m)]
    return [sum(f(r * cmath.exp(1j * t)) * cmath.exp(-1j * j * t) for t in ts) / m / r ** j
            for j in range(1, n + 1)]
def area(g, r, m=4000):                     # shoelace sum round the image of |zeta| = r
    w = [g(r * cmath.exp(2j * math.pi * s / m)) for s in range(m)]
    return sum((w[s - 1].conjugate() * w[s]).imag for s in range(m)) / 2
def nearest(f, r=0.999, m=7200):            # smallest |f| on the circle |z| = r
    return min(abs(f(r * cmath.exp(2j * math.pi * s / m))) for s in range(m))
def fx(x): return f"{0.0 if abs(x) < 5e-7 else x:.6f}"
def fz(z): return f"{fx(z.real)} {'-' if z.imag < -5e-7 else '+'} {fx(abs(z.imag))}i"
def koebe_miss(f, w): return lambda z: w * f(z) / (w - f(z))   # in S again if f never hits w
a = coeffs(k, 5)
def g(zeta): s = cmath.sqrt(k(zeta ** -2)); return 1 / s if (s * zeta).real > 0 else -1 / s  # 1/h(1/zeta), h(z) = sqrt(k(z^2)), Re h(z)/z > 0
b1 = sum(g(2 * cmath.exp(2j * math.pi * s / 256)) * cmath.exp(2j * math.pi * s / 256)
         for s in range(256)) / 256 * 2       # the 1/zeta coefficient, averaged on |zeta| = 2
radii = [2.0, 1.1, 1.01]
shoe = [area(g, r) for r in radii]
form = [math.pi * (r * r - r ** -2) for r in radii]
near_k, near_h, near_2 = nearest(k), nearest(lambda z: z / (1 - z)), nearest(lambda z: k(z) - k(0.5))
dk, mv = 1.5 / 0.5 ** 3, coeffs(lambda z: k((z + 0.5) / (1 + 0.5 * z)), 1)[0]   # k'(0.5) = (1 + z)/(1 - z)^3; k after phi_-0.5
f2 = [coeffs(koebe_miss(k, -0.25), 2)[1], coeffs(koebe_miss(lambda z: z / (1 - z), -0.5), 2)[1]]
thetas = [math.pi, math.pi / 2, -math.pi / 2, math.pi / 3, -math.pi / 3]
direct = [k(cmath.exp(1j * t)) for t in thetas]
closed = [-1 / (4 * math.sin(t / 2) ** 2) for t in thetas]
e10 = lambda z: (cmath.exp(10 * z) - 1) / 10
q, ox = 70, 330
print(f"figure, {q} px per unit; disc centre (100, 140), radius {q}; image origin ({ox}, 140); "
      f"tip ({ox - q / 4}, 140); quarter disc radius {q / 4}; k(0.5) at ({ox + q * k(0.5):.1f}, 140); "
      f"k(0.5i) at ({ox + q * k(0.5j).real:.1f}, {140 - q * k(0.5j).imag:.1f}); k(i) at ({ox + q * k(1j).real:.1f}, 140)")
print("coefficients a_1..a_5 by circle average:", " ".join(fx(c.real) for c in a))
print(f"k(0.5) = {fx(k(0.5))}; k(-0.5) = {fx(k(-0.5))}; k(-0.9) = {fx(k(-0.9))}; k(-0.99) = {fx(k(-0.99))}")
print(f"area theorem for g(zeta) = 1/h(1/zeta) = zeta - 1/zeta: b_1 = {fx(b1.real)}, sum n|b_n|^2 = {fx(abs(b1) ** 2)}")
for r, s, f in zip(radii, shoe, form):
    print(f"area missed inside g(|zeta| = {r:g}): shoelace {s:.6f}; pi(r^2 - r^-2) {f:.6f}")
print(f"nearest image point on |z| = 0.999: k {near_k:.9f}; z/(1 - z) {near_h:.6f}")
print(f"round k(0.5): |k'(0.5)| = {dk:.6f}; 1 - 0.5^2 = {1 - 0.5 ** 2:.6f}; derivative of k(phi_-0.5) at 0 = {abs(mv):.6f}; radius {abs(mv) / 4:.6f}; search {near_2:.6f}")
print(f"omitted-value map: k misses -0.25, new a_2 = {fx(f2[0].real)} (2 + 1/w = {fx(2 - 4)}); "
      f"z/(1 - z) misses -0.5, new a_2 = {fx(f2[1].real)} (1 + 1/w = {fx(1 - 2)})")
print("rim, theta = pi, pi/2, -pi/2, pi/3, -pi/3: k =", "; ".join(fz(w) for w in direct))
print("rim, closed form -1/(4 sin^2(theta/2)):", " ".join(fx(c) for c in closed))
print(f"two sides of the slit: k(0.99i) = {fz(k(0.99j))}; k(-0.99i) = {fz(k(-0.99j))}")
print(f"break 1, (e^(10z) - 1)/10: a_2 = {fx(coeffs(e10, 2)[1].real)}; misses -0.1; "
      f"f(0) = {fz(e10(0))}, f(0.2 pi i) = {fz(e10(0.2j * math.pi))}")
print(f"break 2, k/10: nearest missed point {nearest(lambda z: k(z) / 10):.6f}")
print(f"break 3, bound |a_2| <= 1 would promise radius {1 / (1 + 1):.6f}; k misses -0.25")
assert all(abs(c - j) < 1e-9 for j, c in zip(range(1, 6), a))        # average = closed form n
assert all(abs(s - f) < 1e-5 * f for s, f in zip(shoe, form))       # shoelace = area theorem
assert abs(near_k - 0.999 / 1.999 ** 2) < 1e-12 and near_k > 0.2499  # search = formula, >= 1/4
assert abs(abs(mv) - dk * 0.75) < 1e-9 and abs(near_2 - abs(mv) / 4) < 1e-6   # chain rule; radius = search
assert abs(b1 + a[1] / 2) < 1e-9                                     # b_1 = -a_2/2, as in Step 2
assert abs(f2[0] + 2) < 1e-9 and abs(f2[1] + 1) < 1e-9               # new a_2 = a_2 + 1/w
assert all(abs(d - c) < 1e-9 for d, c in zip(direct, closed))        # rim = slit, two-to-one
print("ALL CHECKS PASS")
