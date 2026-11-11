# Schrodinger's equation and the particle in a box -- the check behind the card.
# Standard library only.  An electron in a box 1 nm wide, walls it cannot cross,
# set beside a guitar string.  Three roads to the energy levels: the closed
# form, a shooting solve of the equation itself (RK4 plus bisection), and a
# finite well whose walls are raised until it becomes the box.
import math

H = 6.62607015e-34          # Planck constant, J s (exact in SI)
HBAR = H / (2 * math.pi)    # reduced Planck constant, J s
ME = 9.1093837139e-31       # electron mass, kg (CODATA 2022)
EV = 1.602176634e-19        # one electronvolt, J (exact in SI)
C = 299792458.0             # speed of light, m/s (exact in SI)
L = 1e-9                    # box width, m
K = 2 * ME * EV * (1e-9) ** 2 / HBAR ** 2   # phi'' = -K E phi, x in nm, E in eV

def level(n, width=L):      # road 1: E_n = n^2 h^2 / (8 m L^2), in eV
    return n * n * H * H / (8 * ME * width * width) / EV

def shoot(E, steps=2000, w=1.0):  # phi(0)=0, phi'(0)=1, RK4 across w nm; returns phi(w)
    dx, y, v = w / steps, 0.0, 1.0
    for _ in range(steps):
        k1y, k1v = v, -K * E * y
        k2y, k2v = v + dx / 2 * k1v, -K * E * (y + dx / 2 * k1y)
        k3y, k3v = v + dx / 2 * k2v, -K * E * (y + dx / 2 * k2y)
        k4y, k4v = v + dx * k3v, -K * E * (y + dx * k3y)
        y += dx / 6 * (k1y + 2 * k2y + 2 * k3y + k4y)
        v += dx / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)
    return y

def bisect(f, a, b, iters=60):
    fa = f(a)
    for _ in range(iters):
        m = (a + b) / 2
        if (f(m) < 0) == (fa < 0): a, fa = m, f(m)
        else: b = m
    return (a + b) / 2

def shot_levels(count):     # road 2: scan E for sign changes of phi(1 nm), then bisect
    found, E, prev = [], 0.02, shoot(0.02)
    while len(found) < count:
        nxt = shoot(E + 0.02)
        if (prev < 0) != (nxt < 0): found.append(bisect(shoot, E, E + 0.02))
        E, prev = E + 0.02, nxt
    return found

def finite_well(V0, a=1.0): # road 3: even ground state of a well a nm wide, V0 eV deep
    z0 = a / 2 * math.sqrt(K * V0)
    z = bisect(lambda z: z * math.tan(z) - math.sqrt(z0 * z0 - z * z), 1e-9, min(z0, math.pi / 2) - 1e-12)
    return 4 * z * z / (K * a * a)

def simpson(f, a, b, n=1000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

E = [level(n) for n in range(1, 6)]
S = shot_levels(5)
print("constants: h 6.62607015 x 10^-34 J s, hbar %.9f x 10^-34 J s, m_e %.10f x 10^-31 kg"
      % (HBAR * 1e34, ME * 1e31))
print("box width L = 1.000 nm; K = 2 m_e (1 eV)(1 nm)^2 / hbar^2 = %.4f" % K)
print("n   E_n formula   E_n shooting   E_n/E_1   E_n/h")
for n in range(5):
    print("%d   %8.4f eV   %9.4f eV   %7.2f   %6.1f THz" % (n + 1, E[n], S[n], E[n] / E[0], E[n] * EV / H / 1e12))
print("hand route: h^2 = %.4f x 10^-67 J^2 s^2, 8 m_e L^2 = %.4f x 10^-48 kg m^2, h c = %.4f x 10^-25 J m"
      % (H * H * 1e67, 8 * ME * L * L * 1e48, H * C * 1e25))
print("E_1 = %.4f x 10^-20 J = %.5f eV" % (E[0] * EV * 1e20, E[0]))
gaps = [E[i + 1] - E[i] for i in range(3)]
print("gaps E2-E1, E3-E2, E4-E3: %.3f, %.3f, %.3f eV, ratio %.0f : %.0f : %.0f"
      % (*gaps, *(g / E[0] for g in gaps)))
lam = H * C / (gaps[0] * EV)
print("photon from level 2 to level 1: %.4f eV, wavelength %.0f nm" % (gaps[0], lam * 1e9))
A = math.sqrt(2 / L)
print("normaliser sqrt(2/L) = %.0f per root metre = %.4f per root nm" % (A, math.sqrt(2.0)))
phi = lambda n: (lambda x: math.sqrt(2.0) * math.sin(n * math.pi * x))   # x in nm
norm = simpson(lambda x: phi(1)(x) ** 2, 0, 1)
o12 = simpson(lambda x: phi(1)(x) * phi(2)(x), 0, 1)
o13 = simpson(lambda x: phi(1)(x) * phi(3)(x), 0, 1)
print("Simpson: total probability n=1 %.6f; overlap(1,2) %.6f; overlap(1,3) %.6f" % (norm, abs(o12), abs(o13)))
mid = [simpson(lambda x: phi(n)(x) ** 2, 1 / 3, 2 / 3) for n in (1, 2)]
f1 = 1 / 3 + math.sqrt(3) / (2 * math.pi)
f2 = 1 / 3 - math.sqrt(3) / (4 * math.pi)
print("P(middle third): n=1 %.4f (formula %.4f), n=2 %.4f (formula %.4f), classical 0.3333"
      % (mid[0], f1, mid[1], f2))
Ls, f1s = 0.65, 110.0
print("guitar A string: %.2f m, wave speed %.0f m/s, harmonics %s Hz"
      % (Ls, 2 * Ls * f1s, " ".join("%.0f" % (n * f1s) for n in range(1, 6))))
print("chart, string ratio: %s; electron ratio: %s" % (" ".join("%.0f" % (n * f1s / f1s) for n in range(1, 6)),
      " ".join("%.0f" % (e / E[0]) for e in E)))
print("box width scan: L 0.5, 1, 2 nm -> E_1 %.4f, %.4f, %.4f eV"
      % (level(1, 0.5e-9), level(1, 1e-9), level(1, 2e-9)))
fw = [finite_well(V) for V in (1.0, 10.0, 100.0)]
print("finite well 1 nm wide, ground level: depth 1 eV %.4f, 10 eV %.4f, 100 eV %.4f eV"
      % tuple(fw))
print("mistake, h in place of hbar: E_1 = %.2f eV" % (level(1) * 4 * math.pi ** 2))
print("mistake, levels in step like a string: E_3 = %.3f eV (right %.3f eV)" % (3 * E[0], E[2]))
print("mistake, normaliser sqrt(1/L): total probability %.4f" % (norm / 2))
print("mistake, infinite walls for a 1 eV well: %.4f eV against %.4f eV, %.0f%% high"
      % (E[0], fw[0], 100 * (E[0] / fw[0] - 1)))
print("figure, walls x_px 60 360, 300 px per nm, 70 px per eV, levels y_px %.2f %.2f %.2f, amplitude 25 px"
      % tuple(275 - 70 * e for e in E[:3]))
starved = [bisect(lambda e: shoot(e, 20), lo, hi) for lo, hi in ((0.3, 0.45), (9.0, 10.0))]
print("try: steps=20, level 1 %.4f eV, level 5 %.4f eV; well 1000 eV deep, ground level %.4f eV"
      % (*starved, finite_well(1000.0)))

assert all(abs(S[i] - E[i]) / E[i] < 1e-6 for i in range(5))     # shooting meets formula
assert abs(math.pi ** 2 / K - E[0]) / E[0] < 1e-12                # hbar form meets h form
assert fw[0] < fw[1] < fw[2] < E[0] and (E[0] - fw[2]) / E[0] < 0.25  # walls raised -> box
assert abs(norm - 1) < 1e-9 and abs(o12) < 1e-9 and abs(o13) < 1e-9
assert abs(mid[0] - f1) < 1e-9 and abs(mid[1] - f2) < 1e-9
assert abs(lam - H * C / ((S[1] - S[0]) * EV)) / lam < 1e-6       # wavelength, by the shooting road
assert abs(bisect(lambda e: shoot(e, w=2.0), 0.05, 0.15) / level(1, 2e-9) - 1) < 1e-6  # 1/L^2: shoot a 2 nm box
print("ALL CHECKS PASS")
