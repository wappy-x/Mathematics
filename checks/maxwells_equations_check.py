# Maxwell's equations -- the check behind the card.  Standard library only.
# Two round plates, radius 5 cm, 1 mm apart in air, charged by a steady 10 mA.
# Road 1: the field from Maxwell's term, in closed form.  Road 2: Biot-Savart summed over the
# conduction currents alone (the wires and the plates), with no displacement current anywhere.
# Plus div(curl F) = 0 by differences, and the rim field at 1 GHz by a series and by an integral.
from math import pi, sqrt, sin, cos, sinh, cosh, asinh, exp

EPS0 = 8.8541878188e-12     # F/m, CODATA 2022
MU0 = 1.25663706127e-6      # N/A^2, CODATA 2022
C_EXACT = 299792458.0       # m/s, exact: it defines the metre
a, d, I = 0.05, 0.001, 0.010  # plate radius (m), gap (m), charging current (A)
I_COND_GAP = 0.0             # A: conduction current crossing the bag surface in the gap

def show(label, value, unit, places=2):
    print(f"{label:<42}{value:>12.{places}f} {unit}".rstrip())

def b_maxwell(r, a=a, I=I):  # field round the axis in the gap: enclosed share of the 10 mA
    return MU0 * I * min(r, a) ** 2 / (a * a) / (2 * pi * r)

def b_old_ampere(r):          # Ampere's law without Maxwell's term, bag surface through the gap
    return MU0 * I_COND_GAP / (2 * pi * r)

def b_biot_savart(r, gap):   # road 2: wires plus plates' spreading currents, nothing else
    h = gap / 2
    wires = 2 * MU0 * I / (4 * pi * r) * (1 - h / sqrt(r * r + h * h))
    u0, u1, v0, nu, nv, tot = asinh(-r / h), asinh((a - r) / h), asinh(pi * r / h), 400, 300, 0.0
    du, dv = (u1 - u0) / nu, 2 * v0 / nv
    for i in range(nu):                      # grid packed close to the point, s = r + h sinh(u)
        u = u0 + (i + 0.5) * du
        s, ds = r + h * sinh(u), h * cosh(u) * du
        ks = I * (1 - s * s / (a * a)) / (2 * pi)   # sheet current K(s) times s
        for j in range(nv):
            v = -v0 + (j + 0.5) * dv
            ph, dph = h / r * sinh(v), h / r * cosh(v) * dv
            r2 = r * r + s * s - 2 * r * s * cos(ph) + h * h
            tot += ks * h * cos(ph) / r2 ** 1.5 * ds * dph
    return wires - 2 * MU0 / (4 * pi) * tot  # the two plates pull the same way, against the wires

def j0_series(x):
    term, total, k = 1.0, 1.0, 0
    while abs(term) > 1e-17:
        k += 1
        term *= -(x / 2) ** 2 / (k * k)
        total += term
    return total

def j0_integral(x, n=2000):  # (1/pi) times the integral of cos(x sin t) for t from 0 to pi
    return sum(cos(x * sin((k + 0.5) * pi / n)) for k in range(n)) / n

print("constants: eps0 8.8541878188 pF/m, mu0 1.25663706127 uN/A^2 (CODATA 2022)")
c = 1 / sqrt(MU0 * EPS0)
show("c = 1/sqrt(mu0 eps0)", c, "m/s", 1)
assert abs(c - C_EXACT) / C_EXACT < 1e-9
area = pi * a * a
show("plate area pi a^2", area * 1e4, "cm^2")
show("capacitance eps0 pi a^2 / d", EPS0 * area / d * 1e12, "pF")
q1 = I * 1e-6
E1 = q1 / (EPS0 * area)
show("plate charge after 1 us", q1 * 1e9, "nC")
show("E in the gap after 1 us (Gauss)", E1 / 1e3, "kV/m", 1)
show("voltage after 1 us", E1 * d, "V", 1)
dEdt = I / (EPS0 * area)
show("dE/dt in the gap", dEdt / 1e3 * 1e-6, "kV/m per us", 1)
show("dPhi_E/dt through the gap", dEdt * area * 1e-6, "V m per us", 1)
i_d = EPS0 * dEdt * area
show("displacement current eps0 dPhi_E/dt", i_d * 1e3, "mA", 3)
show("displacement current density", i_d / area, "A/m^2", 3)
show("road 1: B at 8 cm, flat surface (wire)", MU0 * I / (2 * pi * 0.08) * 1e9, "nT")
show("road 1: B at 8 cm, surface through gap", b_maxwell(0.08) * 1e9, "nT")
show("displacement current inside r = 2.5 cm", i_d * (0.025 / a) ** 2 * 1e3, "mA", 3)
show("road 1: B at 2.5 cm, in the gap", b_maxwell(0.025) * 1e9, "nT")
bs = {r: b_biot_savart(r, d) for r in (0.025, 0.05, 0.08)}
for r in (0.025, 0.05, 0.08):
    show(f"road 2: Biot-Savart, r = {r * 100:g} cm", bs[r] * 1e9, "nT")
assert abs(bs[0.025] - b_maxwell(0.025)) / b_maxwell(0.025) < 0.02
assert abs(bs[0.08] - b_maxwell(0.08)) / b_maxwell(0.08) < 0.02
bs_thin = b_biot_savart(0.025, 0.0001)
assert abs(bs_thin - b_maxwell(0.025)) < abs(bs[0.025] - b_maxwell(0.025)) / 5

def F(x, y, z): return (sin(y * z), x * x * z, exp(x) * y)
def curl(x, y, z, e=1e-4):
    def dd(k, axis):
        p = [x, y, z]; m = [x, y, z]; p[axis] += e; m[axis] -= e
        return (F(*p)[k] - F(*m)[k]) / (2 * e)
    return (dd(2, 1) - dd(1, 2), dd(0, 2) - dd(2, 0), dd(1, 0) - dd(0, 1))
e = 1e-3
dc = sum((curl(*[v + e * (ax == k) for ax, v in enumerate((0.3, 0.7, 0.2))])[k]
          - curl(*[v - e * (ax == k) for ax, v in enumerate((0.3, 0.7, 0.2))])[k]) / (2 * e) for k in range(3))
show("div(curl F) at (0.3, 0.7, 0.2), |value|", abs(dc), "", 6)
assert abs(dc) < 1e-5
assert abs(curl(0.3, 0.7, 0.2)[2] - (2 * 0.3 * 0.2 - 0.2 * cos(0.7 * 0.2))) < 1e-6  # against curl by hand

show("wrong: old Ampere, gap surface, 8 cm", b_old_ampere(0.08) * 1e9, "nT")
show("wrong: wire formula inside gap, 2.5 cm", MU0 * I / (2 * pi * 0.025) * 1e9, "nT")
show("wrong: gap formula past the rim, 8 cm", MU0 * I * 0.08 / (2 * pi * a * a) * 1e9, "nT")
x = 2 * pi * 1e9 * a / C_EXACT
show("1 GHz: u = 2 pi f a / c", x, "", 4)
js, ji = j0_series(x), j0_integral(x)
show("rim / centre E at 1 GHz, series", js, "", 4)
show("rim / centre E at 1 GHz, integral", ji, "", 4)
assert abs(js - ji) < 1e-9
show("rim / centre, first correction 1 - u^2/4", 1 - x * x / 4, "", 4)
x6 = 2 * pi * 1e6 * a / C_EXACT
show("1 MHz: rim dip 1 - J0, parts per million", (1 - j0_series(x6)) * 1e6, "ppm", 4)
show("1 MHz: wavelength c / f", C_EXACT / 1e6, "m")
show("try: a = 10 cm, B at 2.5 cm", b_maxwell(0.025, a=0.10) * 1e9, "nT")
show("try: a = 10 cm, B at 8 cm", b_maxwell(0.08, a=0.10) * 1e9, "nT")
show("try: I = 1 A, B at 8 cm", b_maxwell(0.08, I=1.0) * 1e6, "uT", 3)
show("try: 100 MHz, rim / centre", j0_series(2 * pi * 1e8 * a / C_EXACT), "", 5)
show("try: gap 0.1 mm, Biot-Savart at 2.5 cm", bs_thin * 1e9, "nT")
show("try: gap 2 mm, voltage after 1 us", E1 * 0.002, "V", 1)
rs = list(range(11))
print("chart, r (cm)        " + " ".join(f"{r:>6d}" for r in rs))
print("chart, B in gap (nT) " + " ".join(f"{b_maxwell(r / 100 if r else 1e-9) * 1e9:>6.2f}" for r in rs))
print("chart, old Ampere    " + " ".join(f"{b_old_ampere(r / 100 if r else 1e-9) * 1e9:>6.2f}" for r in rs))
print(f"figure, 2 px per mm across: axis x 210, plate edges x {210 - 2000 * a:g} and {210 + 2000 * a:g},"
      f" loop x {210 - 2000 * 0.08:g} and {210 + 2000 * 0.08:g}; 1 mm gap drawn 40 px (schematic)")
print("ALL CHECKS PASS")
