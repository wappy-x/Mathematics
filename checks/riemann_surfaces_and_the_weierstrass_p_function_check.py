# Riemann surfaces and the Weierstrass p-function -- the check behind the card.
# Standard library only. The lattice is 1 and i. Three roads to g2 (lattice sum,
# q-series, lemniscate constant by the AGM), two roads to p(z) (q-series, lattice
# sum), then the cubic, j, three points on a line, the nodal cubic, the mistakes.
from cmath import exp
from math import pi, sqrt
from fractions import Fraction as Fr

def f6(x):                       # print a real number, never as -0.000000
    return f"{0.0 if abs(x) < 5e-7 else x:.6f}"

def fc(z):                       # print a complex number as a + bi
    re, im = (0.0 if abs(t) < 5e-7 else t for t in (z.real, z.imag))
    return f"{re:.6f}" if im == 0 else f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def sigma(n, k):                 # sum of the k-th powers of the divisors of n
    return sum(d ** k for d in range(1, n + 1) if n % d == 0)

def g2g3_q(tau, terms=30):       # road 2: Eisenstein q-series, lattice 1 and tau
    q = exp(2j * pi * tau)
    s3 = sum(sigma(n, 3) * q ** n for n in range(1, terms))
    s5 = sum(sigma(n, 5) * q ** n for n in range(1, terms))
    return 60 * pi ** 4 / 45 * (1 + 240 * s3), 140 * 2 * pi ** 6 / 945 * (1 - 504 * s5), s5

def g2_lattice(N):               # road 1: 60 x sum of w^-4 over the box max(m, n) <= N
    s = 0.0                      # one quarter of the lattice; w^-4 is unchanged by w -> iw
    for m in range(1, N + 1):
        for n in range(0, N + 1):
            w = complex(m, n)
            s += (1 / (w * w * w * w)).real
    return 60 * 4 * s

Q = exp(-2 * pi).real            # q for tau = i
def p_q(z, terms=12):            # p(z) and p'(z) by the q-series in u = e^(2 pi i z)
    u = exp(2j * pi * z)
    s, d = 1 / 12 + u / (1 - u) ** 2, u * (1 + u) / (1 - u) ** 3
    for n in range(1, terms):
        a, b = Q ** n * u, Q ** n / u
        s += a / (1 - a) ** 2 + b / (1 - b) ** 2 - 2 * Q ** n / (1 - Q ** n) ** 2
        d += a * (1 + a) / (1 - a) ** 3 - b * (1 + b) / (1 - b) ** 3
    return -4 * pi * pi * s, -4 * pi * pi * 2j * pi * d

def p_lattice(z, N):             # p(z), p'(z) by the defining sum over the box |m|, |n| <= N
    s, d = 1 / z ** 2, -2 / z ** 3
    for m in range(-N, N + 1):
        for n in range(-N, N + 1):
            if m or n:
                w = complex(m, n)
                s += 1 / (z - w) ** 2 - 1 / w ** 2
                d += -2 / (z - w) ** 3
    return s, d

def richardson(f, z):            # the box error falls like 1/N^2: combine N = 30 and 60
    (s1, d1), (s2, d2) = f(z, 30), f(z, 60)
    return (4 * s2 - s1) / 3, (4 * d2 - d1) / 3

print(f"lattice 1 and i: tau = i, q = e^(-2 pi) = {f6(Q)}")
a100, a200 = g2_lattice(100), g2_lattice(200)
road1 = (4 * a200 - a100) / 3
print(f"road 1, lattice sum 60 G4: N = 100 {f6(a100)}, N = 200 {f6(a200)}, extrapolated {f6(road1)}")
g2, g3, s5 = g2g3_q(1j)
g2, g3 = g2.real, g3.real
print(f"road 2, q-series: g2 = {f6(g2)}, g3 = {f6(g3)} (504 x sum sigma5 q^n = {504 * s5.real:.9f}); sigma3(2) = {sigma(2, 3)}")
x, y = 1.0, sqrt(2)
for _ in range(8):
    x, y = (x + y) / 2, sqrt(x * y)
varpi = pi / x
print(f"road 3, lemniscate constant varpi = pi/AGM(1, sqrt 2) = {f6(varpi)}, pi times Gauss's constant {f6(1 / x)}: 4 x varpi^4 = {f6(4 * varpi ** 4)}")
assert abs(road1 - g2) < 1e-4 and abs(4 * varpi ** 4 - g2) < 1e-9 and abs(g3) < 1e-9
j = 1728 * g2 ** 3 / (g2 ** 3 - 27 * g3 ** 2)
print(f"j = 1728 g2^3/(g2^3 - 27 g3^2) = {f6(j)}; lattice scaled by varpi: g2 = {f6(g2 / varpi ** 4)}")
assert abs(j - 1728) < 1e-9 and abs(g2 / varpi ** 4 - 4) < 1e-12
h2, h3, _ = g2g3_q(2j)
j2 = (1728 * h2 ** 3 / (h2 ** 3 - 27 * h3 ** 2)).real
print(f"lattice 1 and 2i: j = {j2:.3f}; 66^3 = {66 ** 3}")
assert abs(j2 - 66 ** 3) < 1e-3
k2, k3, _ = g2g3_q(complex(-0.5, sqrt(3) / 2))
j3 = (1728 * k2 ** 3 / (k2 ** 3 - 27 * k3 ** 2)).real
print(f"lattice 1 and (-1 + i sqrt 3)/2: g2 = {fc(k2)}, g3 = {fc(k3)}, j = {f6(j3)}")
assert abs(k2) < 1e-9 and abs(k3) > 100 and abs(j3) < 1e-9
for name, z, root in [("1/2", 0.5, sqrt(g2) / 2), ("i/2", 0.5j, -sqrt(g2) / 2), ("(1+i)/2", 0.5 + 0.5j, 0.0)]:
    pz, dz = p_q(z)
    print(f"p({name}) = {fc(pz)}, p'({name}) = {fc(dz)}; root of 4x^3 - g2 x: {f6(root)}")
    assert abs(pz - root) < 1e-9 and abs(dz) < 1e-9
for z in (0.25, 0.25 + 0.5j, 0.3 + 0.2j):
    (pz, dz), (pl, dl) = p_q(z), richardson(p_lattice, z)
    print(f"z = {fc(z)}: p = {fc(pz)}, p' = {fc(dz)}")
    print(f"  lattice sum: p = {fc(pl)}, p' = {fc(dl)}")
    rhs = 4 * pz ** 3 - g2 * pz
    print(f"  p'^2 = {fc(dz * dz)}, 4p^3 - g2 p = {fc(rhs)}")
    assert abs(pz - pl) < 1e-5 and abs(dz - dl) < 1e-3 and abs(dz * dz - rhs) < 1e-9 * abs(rhs)
z = 0.01
lau = ((p_q(z)[0] - 1 / z ** 2) / z ** 2).real
print(f"Laurent: (p(0.01) - 1/0.01^2)/0.01^2 = {f6(lau)}; g2/20 = {f6(g2 / 20)}")
assert abs(lau - g2 / 20) < 1e-5
z1, z2 = 0.1 + 0.2j, 0.3 - 0.05j
z3 = -(z1 + z2)
(x1, y1), (x2, y2), (x3, y3) = p_q(z1), p_q(z2), p_q(z3)
m = (y2 - y1) / (x2 - x1)
print(f"z1 + z2 + z3 = 0: P1 = ({fc(x1)}, {fc(y1)}), P2 = ({fc(x2)}, {fc(y2)})")
print(f"  chord slope m = {fc(m)}; third x = m^2/4 - x1 - x2 = {fc(m * m / 4 - x1 - x2)}")
print(f"  p(z3) = {fc(x3)}; height of P3 above the chord = {fc(y3 - (y1 + m * (x3 - x1)))}")
assert abs(m * m / 4 - x1 - x2 - x3) < 1e-9 and abs(y3 - (y1 + m * (x3 - x1))) < 1e-8
G2, G3 = Fr(60, 45), Fr(140 * 2, 945)          # q = 0: the constant terms over pi^4, pi^6
s = Fr(-1, 3)                                  # y^2 = x^3 + x^2 with x = X + s, y = Y/2
c2, c3 = -4 * (3 * s * s + 2 * s), -4 * (s ** 3 + s ** 2)
print(f"q = 0: g2/pi^4 = {G2}, g3/pi^6 = {G3}; g2^3 - 27 g3^2 = {G2 ** 3 - 27 * G3 ** 2}")
print(f"house y^2 = x^3 + x^2 as Y^2 = 4X^3 - g2 X - g3: g2 = {c2}, g3 = {c3}, g2^3 - 27 g3^2 = {c2 ** 3 - 27 * c3 ** 2}")
assert (c2, c3) == (G2, -G3) and c2 ** 3 == 27 * c3 ** 2
print("mistakes, at z = 1/4:")
sq = sum(1 / (0.25 - complex(m, n)) ** 2 for m in range(-100, 101) for n in range(-100, 101)).real
wide = sum(1 / (0.25 - complex(m, n)) ** 2 for m in range(-200, 201) for n in range(-100, 101)).real
pz, dz = (t.real for t in p_q(0.25))
print(f"  no -1/w^2 terms: square box {f6(sq)}, wide box {f6(wide)}; true p = {f6(pz)}")
print(f"  y^2 = x^3 - g2 x without the 4: {f6(pz ** 3 - g2 * pz)}, but p'^2 = {f6(dz * dz)}")
print(f"  G4 = {f6(g2 / 60)} used as g2: 4p^3 - G4 p = {f6(4 * pz ** 3 - g2 / 60 * pz)}")
assert abs(wide - pz) > 1 and abs(pz ** 3 - g2 * pz - dz * dz) > 1000
px = lambda z: f"({160 + round(120 * z.real)}, {340 - round(120 * z.imag)})"
print("figure, 120 px per unit: 0, 1, 1+i, i at", *(px(z) for z in (0, 1, 1 + 1j, 1j)))
print("figure, 1/2, i/2, (1+i)/2, 1/4 at", *(px(z) for z in (0.5, 0.5j, 0.5 + 0.5j, 0.25)))
print("ALL CHECKS PASS")
