# Fundamental solution of a rail on a ballast bed: EI w'''' + k w = load.
# Standard library only.  Roads: the closed form G; the probe test
# (LG)(phi) = phi(0); the identity k * (integral of G) = 1; and a rail of
# N grid nodes solved by banded elimination, which never mentions G.
import math

EI = 210e9 * 3055e-8   # N m^2: steel rail, I = 3055 cm^4 (illustrative)
k = 40e6               # N/m per m of rail: the ballast bed (illustrative)
P = 100e3              # N: one wheel (illustrative)
d = 1.8                # m: spacing of the two wheels of a bogie
beta = (k / (4 * EI)) ** 0.25

def G(x):              # sag at x, in m, from a 1 N spike at 0
    y = beta * abs(x)
    return beta / (2 * k) * math.exp(-y) * (math.cos(y) + math.sin(y))

def simpson(f, a, b, n):
    hh = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * hh) for i in range(1, n))
    return s * hh / 3

def rail(EIg, kg, length, h, loads):
    """Rail from -length/2 to length/2, ends pinned (w = w'' = 0).
    A load (x, F) is a spike F/h on one node.  Returns the sag at node x."""
    n = round(length / h) - 1
    A = [[0.0] * n for _ in range(n)]
    b = [0.0] * n
    c = EIg / h ** 4
    for i in range(n):
        for j, v in zip(range(i - 2, i + 3), (1, -4, 6, -4, 1)):
            if 0 <= j < n:
                A[i][j] += c * v
        A[i][i] += kg
    A[0][0] -= c                       # ghost node beyond a pinned end: w = -w(mirror)
    A[n - 1][n - 1] -= c
    for x, F in loads:
        b[round((x + length / 2) / h) - 1] += F / h
    for i in range(n):                 # elimination inside the band, no pivoting
        for r in range(i + 1, min(i + 3, n)):
            m = A[r][i] / A[i][i]
            for j in range(i, min(i + 3, n)):
                A[r][j] -= m * A[i][j]
            b[r] -= m * b[i]
    w = [0.0] * n
    for i in range(n - 1, -1, -1):
        w[i] = (b[i] - sum(A[i][j] * w[j] for j in range(i + 1, min(i + 3, n)))) / A[i][i]
    return lambda x: w[round((x + length / 2) / h) - 1]

mm = 1000
print(f"rail: EI = {EI / 1e6:.4f} MN m^2, bed k = {k / 1e6:.1f} MN/m^2, wheel P = {P / 1e3:.0f} kN")
print(f"beta = (k/(4 EI))^(1/4) = ({k / (4 * EI):.6f})^(1/4) = {beta:.6f} per m; decay length 1/beta = {1 / beta:.4f} m")
print(f"sag under the wheel P beta/(2k) = {P * G(0) * mm:.4f} mm")
print(f"first lift-off at x = 3 pi/(4 beta) = {3 * math.pi / (4 * beta):.4f} m; "
      f"greatest lift {-P * G(math.pi / beta) * mm:.4f} mm at x = pi/beta = {math.pi / beta:.4f} m")
print(f"bending moment under the wheel P/(4 beta) = {P / (4 * beta) / 1e3:.4f} kN m")

# road 2: the probe test, (LG)(phi) = integral of G (EI phi'''' + k phi) = phi(0)
def probe(c, a, scale=1.0):
    def Lphi(x):
        u = (x - c) / a
        e = math.exp(-u * u)
        return EI * (16 * u ** 4 - 48 * u ** 2 + 12) / a ** 4 * e + k * e
    return simpson(lambda x: scale * G(x) * Lphi(x), -12, 12, 4800)
for c in (0.0, 0.5):
    got, want = probe(c, 0.5), math.exp(-(c / 0.5) ** 2)
    print(f"probe width 0.5 m centred at {c:.1f} m: (LG)(phi) = {got:.8f}, phi(0) = {want:.8f}")
    assert abs(got - want) < 1e-7
# road 3: a load spread evenly sags the rail by load/k, so k * (integral of G) = 1
area = k * simpson(G, -20, 20, 8000)
print(f"k * integral of G = {area:.8f}")
assert abs(area - 1) < 1e-8

# road 4: a rail of grid nodes; the discrete spike is P/h on one node
print("h (m)   nodes  sag at wheel (mm)  error vs P G(0) (mm)  error ratio")
prev = None
for h in (0.4, 0.2, 0.1, 0.05):
    s = rail(EI, k, 20, h, [(0, P)])(0) * mm
    err = s - P * G(0) * mm
    ratio = f"{prev / err:.4f}" if prev else "-"
    print(f"{h:<7} {round(20 / h) - 1:<6} {s:.6f}           {err:+.6f}             {ratio}")
    prev = err
assert abs(s - P * G(0) * mm) < 2e-3
w20, w40 = rail(EI, k, 20, 0.05, [(0, P)]), rail(EI, k, 40, 0.05, [(0, P)])
print(f"rail 20 m against 40 m, h = 0.05: sag at wheel {w20(0) * mm:.6f} vs {w40(0) * mm:.6f} mm")
xs = [0.5 * i for i in range(11)]
print("x (m)        " + " ".join(f"{x:6.1f}" for x in xs))
print("P G(x) (mm)  " + " ".join(f"{P * G(x) * mm:6.3f}" for x in xs))
print("grid (mm)    " + " ".join(f"{w20(x) * mm:6.3f}" for x in xs))
print("bogie (mm)   " + " ".join(f"{P * (G(x) + G(x - d)) * mm:6.3f}" for x in xs))
for x in xs:
    assert abs(w20(x) - P * G(x)) < 5e-6

# any load: a bogie, two wheels d apart, is G convolved with two spikes
two = P * (G(0) + G(d))
g2 = rail(EI, k, 20, 0.05, [(0, P), (d, P)])
print(f"bogie, wheels {d} m apart: sag under each wheel {two * mm:.4f} mm, grid {g2(0) * mm:.4f} mm")
bd = beta * d
print(f"  beta d = {bd:.4f}, e^(-beta d) = {math.exp(-bd):.4f}, cos + sin = {math.cos(bd) + math.sin(bd):.4f}, "
      f"cos - sin = {math.cos(bd) - math.sin(bd):.4f}")
print(f"  the neighbour adds P G({d}) = {P * G(d) * mm:.4f} mm")
mom = P / (4 * beta) * (1 + math.exp(-beta * d) * (math.cos(beta * d) - math.sin(beta * d)))
print(f"  bending moment under each wheel {mom / 1e3:.4f} kN m")
assert abs(g2(0) - two) < 5e-6

# what breaks
print("mistake 1, no ballast (k = 0): sag at the middle, h = 0.1")
for length in (10, 20, 40):
    s = rail(EI, 0.0, length, 0.1, [(0, P)])(0)
    print(f"  rail {length} m: {s:.4f} m (beam on two supports, no bed: {P * length ** 3 / (48 * EI):.4f} m)")
    assert abs(s / (P * length ** 3 / (48 * EI)) - 1) < 1e-3
print("mistake 2, no bending stiffness (EI = 0): sag at the wheel = P/(k h)")
for h in (0.1, 0.05, 0.025):
    s = rail(0.0, k, 4, h, [(0, P)])(0)
    print(f"  h = {h}: {s * mm:.1f} mm")
    assert abs(s - P / (k * h)) < 1e-12
print(f"mistake 3, no halving, P beta/k: {2 * P * G(0) * mm:.4f} mm; probe gives {probe(0.0, 0.5, 2.0):.6f}")
print(f"mistake 4, two wheels' peaks added: {2 * P * G(0) * mm:.4f} mm, not {two * mm:.4f}")
# try changing: one setting at a time
for name, EIt, kt in (("bed k = 80 MN/m^2", EI, 80e6), ("bed k = 20 MN/m^2", EI, 20e6), ("rail EI doubled", 2 * EI, k)):
    bt = (kt / (4 * EIt)) ** 0.25
    print(f"try {name}: sag {P * bt / (2 * kt) * mm:.4f} mm, decay length {1 / bt:.4f} m")
print(f"try wheels 1.5 m apart: sag under each wheel {P * (G(0) + G(1.5)) * mm:.4f} mm")
print(f"try a probe of width 0.1 m: (LG)(phi) = {probe(0.0, 0.1):.6f}")
print("ALL CHECKS PASS")
