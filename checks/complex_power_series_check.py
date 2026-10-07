# Power series in the plane -- the check behind the card.  Standard library only.
# The speed bump 1/(1 + x^2) and its series 1 - x^2 + x^4 - ..., about 0 and about 1.
# Road one: add the series term by term.  Road two: the closed form, by complex division.
import math

def bump(z): return 1 / (1 + z * z)
def slope(z): return -2 * z / (1 + z * z) ** 2              # quotient rule on 1/(1 + z^2)
def show(w):                                               # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def series0(z, K):                   # about 0: value and termwise slope from the first K terms
    val, der, p = 0j, 0j, 1 + 0j                           # p runs through (-z^2)^k
    for k in range(K):
        val += p
        if k > 0: der += 2 * k * p / z                     # d/dz of (-1)^k z^(2k)
        p *= -z * z
    return val, der
def sums(x, K): return [series0(x, j + 1)[0].real for j in range(K)]

z, x = 0.5 + 0.5j, 0.5
v, d = series0(z, 60)
vx, dx = series0(x, 60)
h = 1e-5
along = [(bump(z + s * h) - bump(z - s * h)) / (2 * s * h) for s in (1, 1j)]   # difference quotients
print(f"about 0: |next term / term| = |z|^2; poles at +i and -i, both at distance {abs(1j - 0):.6f}")
print(f"x = 0.5: 60 terms {vx.real:.6f}, closed form {bump(x):.6f}; slope termwise {dx.real:.6f}, closed form {slope(x):.6f}")
print(f"z = {show(z)}: |z| = {abs(z):.6f}, z^2 = {show(z * z)}, ratio |z|^2 = {abs(z) ** 2:.6f}")
q = 1 + z * z
print(f"z: 1 + z^2 = {show(q)}, |1 + z^2|^2 = {abs(q) ** 2:.6f}, (1 + z^2)^2 = {show(q * q)}, |(1 + z^2)^2|^2 = {abs(q * q) ** 2:.6f}")
print("z: first terms " + ", ".join(show((-z * z) ** k) for k in range(5)))
print(f"z: 60 terms {show(v)}, closed form {show(bump(z))}")
print(f"z: slope termwise {show(d)}, closed form {show(slope(z))}")
print(f"z: difference quotient along 1 {show(along[0])}, along i {show(along[1])}")
print("partial sums at x = 0.5, k = 0..8: " + ", ".join(f"{s:.2f}" for s in sums(0.5, 9)))
print("partial sums at x = 1.2, k = 0..8: " + ", ".join(f"{s:.2f}" for s in sums(1.2, 9)))
far = series0(1.2, 60)[0].real
print(f"x = 1.2: x^2 = {1.2 * 1.2:.6f}, bump {bump(1.2):.6f}; 60 terms give {far / 1e9:.3f} billion")
print("x = 1, on the rim: partial sums " + ", ".join(f"{s:.0f}" for s in sums(1.0, 6)) + f"; bump {bump(1.0):.6f}")
N = 600
a = [0.5, -0.5]                      # about 1, w = x - 1: (2 + 2w + w^2) f = 1, so a recurrence
for n in range(2, N): a.append(-(2 * a[n - 1] + a[n - 2]) / 2)
b = [(-1) ** n * 2 ** (-(n + 1) / 2) * math.sin((n + 1) * math.pi / 4) for n in range(N)]  # partial fractions
R1 = 1 / max(abs(a[n]) ** (1 / n) for n in range(N - 8, N))    # root test, Cauchy-Hadamard
print("about 1: coefficients " + ", ".join(f"{c + 0.0:.4f}" for c in a[:6]) + f"; root test R = {R1:.6f}; |1 - i| = {abs(1 - 1j):.6f}")
s23 = sum(c * 1.3 ** n for n, c in enumerate(a))
s25 = sum(c * 1.5 ** n for n, c in enumerate(a))
print(f"about 1: x = 2.3, {N} terms {s23:.6f}, bump {bump(2.3):.6f}; x = 2.5, {N} terms reach 10^{math.log10(abs(s25)):.1f}")
print(f"mistake, termwise slope without the factor n: {sum((-1) ** k * x ** (2 * k - 1) for k in range(1, 60)):.6f}, not {slope(x):.6f}")
print(f"figure, scale 60 per unit, 0 at (120, 120): z ({120 + 60 * z.real:.1f}, {120 - 60 * z.imag:.1f}), "
      f"+i (120.0, {120 - 60:.1f}), -i (120.0, {120 + 60:.1f}), 1.2 at {120 + 60 * 1.2:.1f}, centre 1 (180.0, 120.0), radius about 1 {60 * abs(1 - 1j):.2f}, x = 2.3 at {120 + 60 * 2.3:.1f}")
assert abs(v - bump(z)) < 1e-12 and abs(d - slope(z)) < 1e-12           # series against closed form
assert all(abs(q - d) < 1e-8 for q in along)                              # every direction, one slope
assert all(abs(p - q) <= 1e-9 * 2 ** (-(n + 1) / 2) for n, (p, q) in enumerate(zip(a, b))) and abs(s23 - bump(2.3)) < 1e-12
assert abs(R1 - abs(1 - 1j)) < 0.01 and abs(far) > 1e6 and abs(s25) > 1e6   # the poles set the radius
print("ALL CHECKS PASS")
