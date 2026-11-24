# Impedance matching and the Smith chart -- the check behind the card.  Standard library only.
# A 75-ohm antenna onto 50-ohm coax at 100 MHz by a quarter-wave section, then a
# 25 + j25 ohm load matched by one short-circuited stub.  Roads: closed forms; a walk
# round the Smith chart (rotate, then bisect); and a ladder of tiny coils and capacitors.
from math import pi, sqrt, tan, atan, atan2, cos, sin, acos, log10, degrees

C0, VF, F0, Z0 = 299792458.0, 0.66, 100e6, 50.0    # m/s (CODATA, exact), velocity factor, Hz, ohm
LAM = VF * C0 / F0                                  # wavelength in the cable, m

def zin(zl, zc, turns):                             # line of zc ohms, length in wavelengths
    t = tan(2 * pi * turns)
    return zc * (zl + 1j * zc * t) / (zc + 1j * zl * t)

def gam(z, z0=Z0):                                  # reflection coefficient
    return (z - z0) / (z + z0)

def vswr(g):
    return (1 + abs(g)) / (1 - abs(g))

def ladder(zl, zc, metres, f, n=4000):              # road 3: n T-cells of L' dx and C' dx
    v = VF * C0; dx = metres / n; w = 2 * pi * f
    xl, bc = w * (zc / v) * dx, w * dx / (zc * v)   # L' = zc/v, C' = 1/(zc v)
    z = zl
    for _ in range(n):
        z = z + 0.5j * xl
        z = 1 / (1 / z + 1j * bc) + 0.5j * xl
    return z

def root(fn, lo, hi):                               # bisection, fn changes sign on [lo, hi]
    for _ in range(100):
        mid = (lo + hi) / 2
        if (fn(lo) < 0) == (fn(mid) < 0): lo = mid
        else: hi = mid
    return (lo + hi) / 2

def stub_match(zl, f_ratio, d, s):                  # line d, shorted stub s (wavelengths at F0)
    y = 1 / zin(zl, Z0, d * f_ratio) + 1 / zin(0, Z0, s * f_ratio)
    return gam(1 / y)

# ---- part 1: quarter-wave transformer, 75 ohm antenna to 50 ohm coax ----
ZA = 75.0
Z1 = sqrt(Z0 * ZA)
q_len = LAM / 4
z_q = zin(ZA, Z1, 0.25)
z_q_lad = ladder(ZA, Z1, q_len, F0)
g_raw = gam(ZA)
# ---- part 2: single shorted stub for 25 + j25 ohm ----
ZL = 25 + 25j
gL, yL = gam(ZL), Z0 / ZL
rl, xl = ZL.real, ZL.imag                           # road 1: tan(beta d), then cot(beta l)
disc = sqrt(rl * ((Z0 - rl) ** 2 + xl ** 2) / Z0)
sols = []
for t in ((xl + disc) / (rl - Z0), (xl - disc) / (rl - Z0)):
    bd = atan(t) % pi
    b = (1 / zin(ZL, Z0, bd / (2 * pi))).imag * Z0
    sols.append((bd / (2 * pi), (atan(1 / b) % pi) / (2 * pi), b))   # -j cot(bl) = -j b
sols.sort()
# road 2: walk round the chart.  Moving d wavelengths to the generator turns Gamma by -4 pi d.
turn = lambda g, d: g * complex(cos(4 * pi * d), -sin(4 * pi * d))
gy = lambda g: ((1 - g) / (1 + g))                  # normalised admittance read off Gamma
d_walk = root(lambda d: gy(turn(gL, d)).real - 1, 0.25, 0.45)
b_walk = gy(turn(gL, d_walk)).imag
s_walk = root(lambda s: gy(turn(-1 + 0j, s)).imag + b_walk, 0.01, 0.24)   # short is Gamma = -1
g_lad = gam(1 / (1 / ladder(ZL, Z0, d_walk * LAM, F0) + 1 / ladder(0, Z0, s_walk * LAM, F0)))
dB, sB = sols[1][0], sols[1][1]
# ---- bandwidth: |Gamma| <= 0.1 (return loss 20 dB) ----
GM = 0.1
bw_formula = 2 - 4 / pi * acos(GM / sqrt(1 - GM ** 2) * 2 * sqrt(Z0 * ZA) / abs(ZA - Z0))
qw = lambda r: abs(gam(zin(ZA, Z1, 0.25 * r))) - GM
bw_sweep = root(qw, 1.0, 1.99) - root(qw, 0.01, 1.0)
sw = lambda d, s: (lambda r: abs(stub_match(ZL, r, d, s)) - GM)
bwB = root(sw(dB, sB), 1.0, 1.3) - root(sw(dB, sB), 0.7, 1.0)
bwA = root(sw(0, sols[0][1]), 1.0, 1.3) - root(sw(0, sols[0][1]), 0.7, 1.0)

rows = [
    ("cable wavelength at 100 MHz, m", LAM), ("quarter-wave section Z1, ohm", Z1),
    ("quarter-wave length, m", q_len), ("antenna on bare coax |Gamma|", abs(g_raw)),
    ("antenna on bare coax VSWR", vswr(g_raw)), ("  return loss, dB", -20 * log10(abs(g_raw))),
    ("1 formula: Zin real, ohm", z_q.real), ("1 formula: Zin imag, ohm", z_q.imag),
    ("3 ladder: Zin real, ohm", z_q_lad.real), ("3 ladder: Zin imag, ohm", z_q_lad.imag),
    ("load 25+j25: Gamma real", gL.real), ("load 25+j25: Gamma imag", gL.imag),
    ("  |Gamma|", abs(gL)), ("  angle, deg", degrees(atan2(gL.imag, gL.real))),
    ("  VSWR", vswr(gL)), ("  return loss, dB", -20 * log10(abs(gL))),
    ("  power reflected, %", 100 * abs(gL) ** 2), ("  admittance y real", yL.real),
    ("  admittance y imag", yL.imag),
    ("1 sol A: d, wavelengths", sols[0][0]), ("1 sol A: line b at d", sols[0][2]),
    ("1 sol A: stub, wavelengths", sols[0][1]), ("1 sol A: stub, m", sols[0][1] * LAM),
    ("1 sol B: d, wavelengths", dB), ("1 sol B: d, m", dB * LAM),
    ("1 sol B: line b at d", sols[1][2]), ("1 sol B: stub, wavelengths", sB),
    ("1 sol B: stub, m", sB * LAM), ("2 chart walk: d, wavelengths", d_walk),
    ("2 chart walk: turn, deg", 720 * d_walk), ("2 chart walk: b at d", b_walk),
    ("2 chart walk: stub, wavelengths", s_walk), ("3 ladder: |Gamma| after match", abs(g_lad)),
    ("bandwidth QW formula, % of 100 MHz", 100 * bw_formula),
    ("bandwidth QW sweep, % of 100 MHz", 100 * bw_sweep),
    ("bandwidth stub B, % of 100 MHz", 100 * bwB), ("bandwidth stub A, % of 100 MHz", 100 * bwA),
    ("outside: QW at 200 MHz |Gamma|", abs(gam(zin(ZA, Z1, 0.5)))),
    ("wrong: mean 62.5 ohm section |Gamma|", abs(gam(zin(ZA, 62.5, 0.25)))),
    ("wrong: free-space quarter, cut m", C0 / F0 / 4),
    ("wrong: free-space quarter |Gamma|", abs(gam(zin(ZA, Z1, 0.25 / VF)))),
    ("wrong: QW sqrt(50x25) on 25+j25 |Gamma|", abs(gam(zin(ZL, sqrt(Z0 * 25), 0.25)))),
    ("  its Zin real, ohm", zin(ZL, sqrt(Z0 * 25), 0.25).real), ("  its Zin imag, ohm", zin(ZL, sqrt(Z0 * 25), 0.25).imag),
    ("wrong: open stub for short |Gamma|", abs(gam(1 / (1 / zin(ZL, Z0, dB) + 1j * tan(2 * pi * sB) / Z0)))),
    ("wrong: walk toward load |Gamma|", abs(stub_match(ZL, 1.0, 0.5 - dB, sB))),
    ("try: 100 ohm load, Z1 ohm", sqrt(Z0 * 100)), ("try: foam VF 0.85, quarter m", 0.85 * C0 / F0 / 4),
    ("try: 300 ohm load, QW bandwidth %", 100 * (2 - 4 / pi * acos(GM / sqrt(1 - GM ** 2) * 2 * sqrt(Z0 * 300) / 250))),
]
for name, v in rows:
    print(f"{name:<40} {round(v, 9) + 0.0:>10.4f}")
fs = [50 + 10 * k for k in range(11)]
print("chart, MHz         " + " ".join(f"{f:>5d}" for f in fs))
print("chart, QW |Gamma|  " + " ".join(f"{abs(gam(zin(ZA, Z1, 0.25 * f / 100))):>5.3f}" for f in fs))
print("chart, stub B      " + " ".join(f"{abs(stub_match(ZL, f / 100, dB, sB)):>5.3f}" for f in fs))
P = lambda g: f"({210 + 180 * g.real:.1f}, {210 - 180 * g.imag:.1f})"
print(f"figure, L {P(gL)} B {P(turn(gL, dB))} Q {P(g_raw)} S {P(abs(gL) + 0j)} rG {180 * abs(gL):.1f}")

assert abs(z_q - Z0) < 1e-9,                          "quarter-wave formula: Zin = Z0 at a quarter wave"
assert abs(z_q_lad - Z0) < 1e-3,                       "coil-and-capacitor ladder agrees with the formula"
assert abs(d_walk - dB) < 1e-9 and abs(s_walk - sB) < 1e-9, "chart walk agrees with the tan/cot formulas"
assert abs(g_lad) < 1e-4,                              "ladder model of the stub design reflects nothing"
assert abs(bw_sweep - bw_formula) < 1e-9,              "bandwidth sweep agrees with the closed form"
assert abs(vswr(gL) - (1 + sqrt(5)) ** 2 / 4) < 1e-9,  "hand value: VSWR = golden ratio squared"
print("ALL CHECKS PASS")
