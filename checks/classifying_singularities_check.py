# Isolated singularities -- the check behind the card.  Standard library only.
# Three potholes: sin z/z at 0, 1/(z - 2)^2 at 2, e^(1/z) at 0.  Road one reads
# Laurent coefficients off a trapezoid sum round a circle; road two uses known
# series, values near the point, and exact solutions of e^(1/z) = w.
import math

def cexp(z):                                     # e^z from exp, cos and sin
    return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))

def show(z):                                     # 'a + bi' with six decimals
    re, im = (0.0 if abs(t) < 5e-7 else t for t in (z.real, z.imag))
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def coeff(f, a, n, r=1.0, N=64):                 # c_n = (1/2 pi i) loop f (z-a)^(-n-1) dz
    s = 0
    for j in range(N):
        u = r * cexp(2j * math.pi * j / N)
        s += f(a + u) * u ** (-n)
    return s / N

sinc = lambda z: (cexp(1j * z) - cexp(-1j * z)) / (2j * z)
pole = lambda z: 1 / (z - 2) ** 2
ess = lambda z: cexp(1 / z)
fact = [1.0]
for k in range(1, 4): fact.append(fact[-1] * k)
cs = {}
for name, f, a in (("sin z/z at 0", sinc, 0), ("1/(z-2)^2 at 2", pole, 2), ("e^(1/z) at 0", ess, 0)):
    cs[name] = [coeff(f, a, n) for n in (-3, -2, -1, 0)]
    print(f"{name}: c_-3, c_-2, c_-1 = " + ", ".join(show(c) for c in cs[name][:3]))
print("e^(1/z) by its series, 1/k! for k = 3, 2, 1: " + ", ".join(f"{1 / fact[k]:.6f}" for k in (3, 2, 1)))
print("trapezoid error on c_-1 of e^(1/z), N = 4, 8, 16: " + ", ".join(f"{abs(coeff(ess, 0, -1, 1.0, N) - 1):.9f}" for N in (4, 8, 16)))
print(f"sin z/z: c_0 = {show(cs['sin z/z at 0'][3])}; value at 0.1: {sinc(0.1).real:.6f}; at 0.1i: {sinc(0.1j).real:.6f}")
M = max(abs(sinc(0.5 * cexp(2j * math.pi * j / 64))) for j in range(64))
print(f"sin z/z bounded: max modulus on |z| = 0.5 is {M:.6f}; sinh(0.5)/0.5 = {(math.exp(0.5) - math.exp(-0.5)) / 2 / 0.5:.6f}")
print(f"1/(z-2)^2: modulus at distance 0.1: {abs(pole(2.1)):.6f}; at distance 0.05: {abs(pole(2 + 0.05j)):.6f}")
print("order test at z = 2.01, |(z-2)^m f(z)| for m = 1, 2, 3: " + ", ".join(f"{abs(0.01 ** m * pole(2.01)):.6f}" for m in (1, 2, 3)))
print(f"e^(1/z) at z = 1/8: {ess(0.125).real:.6f}; at z = -1/8: {ess(-0.125).real:.6f}; at z = i/(16 pi): {show(ess(1j / (16 * math.pi)))}")
w = complex(2, 3)
L, th = math.log(abs(w)), math.atan2(w.imag, w.real)
zs = [1 / complex(L, th + 2 * math.pi * k) for k in range(5)]
print(f"target w = {show(w)}; ln|w| = {L:.6f}, arg w = {th:.6f}; z_k = 1/(ln|w| + i(arg w + 2 pi k))")
print("|z_k|: " + ", ".join(f"{abs(z):.6f}" for z in zs))
print("largest |e^(1/z_k) - w|: " + f"{max(abs(ess(z) - w) for z in zs):.9f}")
print("figure, 300 units per unit, 0 at (90, 50), z_0 to z_4: " + " ".join(f"({90 + 300 * z.real:.1f}, {50 - 300 * z.imag:.1f})" for z in zs))
print(f"figure, circle through every z_k: centre ({90 + 150 / L:.1f}, 50.0), radius {150 / L:.1f}; ring |z| = 0.1: radius 30.0")
neg = [coeff(pole, 2, n) for n in range(-1, -7, -1)]
nz = [n for n, c in zip(range(-1, -7, -1), neg) if abs(c) > 1e-9]
print(f"mistake, counting terms: 1/(z-2)^2 has {len(nz)} nonzero negative coefficient; most negative power {min(nz)}")
bar = lambda z: z.conjugate() / z
print(f"mistake, no holomorphy: conj(z)/z at 0.001 is {show(bar(0.001))}; at 0.001i is {show(bar(0.001j))}")
p = cs["1/(z-2)^2 at 2"]
assert abs(p[1] - 1) < 1e-12 and abs(p[0]) < 1e-12 and abs(p[2]) < 1e-12 and abs(0.0001 * pole(2.01) - 1) < 1e-9
assert all(abs(cs["e^(1/z) at 0"][3 - k] - 1 / fact[k]) < 1e-12 for k in (1, 2, 3))
assert all(abs(c) < 1e-12 for c in cs["sin z/z at 0"][:3]) and abs(cs["sin z/z at 0"][3] - 1) < 1e-12 and abs(sinc(1e-3) - 1) < 1e-6
assert max(abs(ess(z) - w) for z in zs) < 1e-9 and abs(zs[4]) < 0.05
print("ALL CHECKS PASS")
