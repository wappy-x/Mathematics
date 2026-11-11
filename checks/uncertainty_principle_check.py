# Uncertainty -- the check behind the card.  Standard library only.
# An electron in a 1 nm box: its position spread and momentum spread, reached
# three ways (formula, position-space sums, momentum-space sums), then the
# commutator pairing, the Gaussian that sits on the floor, and the guitar note.
from math import sin, cos, exp, pi, sqrt

HBAR = 6.62607015e-34 / (2 * pi)       # J s, exact since the 2019 SI (CODATA 2022)
ME   = 9.1093837139e-31                # electron mass, kg (CODATA 2022)
EV   = 1.602176634e-19                 # J per eV, exact
KB   = 1.380649e-23                    # Boltzmann constant, J/K, exact
EPS0 = 8.8541878188e-12                # F/m (CODATA 2022)
C    = 299792458.0                     # m/s, exact
NM, P25 = 1e-9, 1e-25                  # print lengths in nm, momenta in units of 1e-25 kg m/s

def simpson(f, a, b, n):               # Simpson's rule, n even
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

L = 1.0 * NM                           # the box
a = pi / L                             # ground state's wavenumber, rad/m
psi = lambda x: sqrt(2 / L) * sin(a * x)

# ---- road 1: the formulas ----
sx = L * sqrt(1 / 12 - 1 / (2 * pi ** 2))
sp = pi * HBAR / L
floor = HBAR / (2 * sx)

# ---- road 2: sums in position space; the slope by a finite difference ----
n, d = 4000, L * 1e-6
dpsi = lambda x: (psi(x + d) - psi(x - d)) / (2 * d)
norm = simpson(lambda x: psi(x) ** 2, 0, L, n)
xbar = simpson(lambda x: x * psi(x) ** 2, 0, L, n)
sx2  = sqrt(simpson(lambda x: (x - xbar) ** 2 * psi(x) ** 2, 0, L, n))
sp2  = HBAR * sqrt(simpson(lambda x: dpsi(x) ** 2, 0, L, n))          # <p> = 0 for a real psi
pbar = HBAR * simpson(lambda x: psi(x) * dpsi(x), 0, L, n)            # <p> = -i hbar times this
pair = -HBAR * simpson(lambda x: (x - xbar) * psi(x) * dpsi(x), 0, L, n)  # Im <(x - xbar)psi, p psi>

# ---- road 3: momentum space.  phi(k) = integral of psi e^(-ikx); check it, then sum k^2 |phi|^2 ----
def phi2(k):                           # |phi(k)|^2 in closed form; L/2 at k = a
    return L / 2 if abs(k * k - a * a) < 1e-9 * a * a else (2 / L) * a * a * 4 * cos(k * L / 2) ** 2 / (a * a - k * k) ** 2
def phi2_direct(k):                    # the same, by doing the integral numerically
    return simpson(lambda x: psi(x) * cos(k * x), 0, L, n) ** 2 + simpson(lambda x: psi(x) * sin(k * x), 0, L, n) ** 2
assert all(abs(phi2_direct(k) - phi2(k)) < 1e-6 * phi2(k) for k in (0, 2 * a)), "closed-form |phi|^2 against the direct transform"
K = 400 * a
mass = 2 * simpson(lambda k: phi2(k), 0, K, 40000) / (2 * pi)
k2 = 2 * simpson(lambda k: k * k * phi2(k), 0, K, 40000) / (2 * pi) + 4 * a * a / (pi * L * K)
sp3 = HBAR * sqrt(k2)
E, kT = sp ** 2 / (2 * ME) / EV, KB * 300 / EV     # kinetic energy and kT at 300 K, eV

# ---- the Gaussian with the same position spread sits exactly on the floor ----
g = lambda x: (2 * pi * sx * sx) ** -0.25 * exp(-x * x / (4 * sx * sx))
dg = lambda x: (g(x + d) - g(x - d)) / (2 * d)
gx = sqrt(simpson(lambda x: x * x * g(x) ** 2, -12 * sx, 12 * sx, n))
gp = HBAR * sqrt(simpson(lambda x: dg(x) ** 2, -12 * sx, 12 * sx, n))

# ---- other states, product in units of hbar: box level m, and a ring ----
def box_product(m): return m * pi * sqrt(1 / 12 - 1 / (2 * m * m * pi * pi))
ring = lambda x: (cos(2 * pi * x / L) + 1j * sin(2 * pi * x / L)) / sqrt(L)   # one wave round a 1 nm ring
pring = lambda x: -1j * HBAR * (ring(x + d) - ring(x - d)) / (2 * d)         # p acting on it, slope by finite difference
ring_pbar = simpson(lambda x: (ring(x).conjugate() * pring(x)).real, 0, L, n)
ring_sx, ring_sp = L / sqrt(12), sqrt(simpson(lambda x: abs(pring(x) - ring_pbar * ring(x)) ** 2, 0, L, n))

# ---- what breaks ----
wrong_width = HBAR / (2 * L)           # box width used as the spread
wrong_h     = 2 * pi * HBAR / (2 * sx) # h in place of hbar
fermi_v     = pi * HBAR / 1e-15 / ME   # the same box shrunk to 1 fm, speed spread m/s

# ---- the guitar: E2 and F2, and the shortest note that tells them apart ----
fE, fF = 440 * 2 ** (-29 / 12), 440 * 2 ** (-28 / 12)
sf_need = (fF - fE) / 2; st_need = 1 / (4 * pi * sf_need)
burst = lambda t: exp(-t * t / (4 * st_need ** 2)) * cos(2 * pi * fE * t)
dt = 12 * st_need / 1200; ts = [-6 * st_need + i * dt for i in range(1201)]
def power(f):                          # |X(f)|^2 by a direct sum over the burst
    re = sum(burst(t) * cos(2 * pi * f * t) for t in ts) * dt
    im = sum(burst(t) * sin(2 * pi * f * t) for t in ts) * dt
    return re * re + im * im
sb = 1 / (4 * pi * st_need); fs = [fE - 6 * sb + i * 12 * sb / 240 for i in range(241)]   # +-6 of the burst's own spread
P = [power(f) for f in fs]; fmean = sum(f * p for f, p in zip(fs, P)) / sum(P)
sf_meas = sqrt(sum((f - fmean) ** 2 * p for f, p in zip(fs, P)) / sum(P))

# ---- hydrogen: minimise hbar^2/(2 m r^2) - e^2/(4 pi eps0 r) ----
r0 = 4 * pi * EPS0 * HBAR ** 2 / (ME * EV ** 2)
EH = HBAR ** 2 / (2 * ME * r0 ** 2) / EV - EV / (4 * pi * EPS0 * r0)

rows = [
    ("hbar, 1e-34 J s", HBAR / 1e-34), ("electron mass, 1e-31 kg", ME / 1e-31),
    ("1/12 - 1/(2 pi^2)", 1 / 12 - 1 / (2 * pi ** 2)), ("a = pi/L, 1/nm", a * NM),
    ("1 position spread sx, formula, nm", sx / NM), ("2 position spread sx, sums, nm", sx2 / NM),
    ("  norm of psi, sums", norm),
    ("1 momentum spread sp, formula, 1e-25 kg m/s", sp / P25),
    ("2 momentum spread sp, slope sums, 1e-25", sp2 / P25),
    ("3 momentum spread sp, from phi(k), 1e-25", sp3 / P25),
    ("  norm of phi, sums", mass),
    ("  |phi(0)|^2 closed form, nm", phi2(0) / NM), ("  |phi(0)|^2 direct integral, nm", phi2_direct(0) / NM),
    ("  |phi(2a)|^2 closed form, nm", phi2(2 * a) / NM), ("  |phi(2a)|^2 direct integral, nm", phi2_direct(2 * a) / NM),
    ("Im pairing / hbar", pair / HBAR), ("product sx sp / hbar", sx * sp / HBAR),
    ("floor hbar/(2 sx), 1e-25", floor / P25),
    ("sp over floor", sp / floor),
    ("speed spread sp/m, km/s", sp / ME / 1e3),
    ("kinetic energy <p^2>/2m, eV", E),
    ("kT at 300 K, eV", kT), ("energy over kT", E / kT),
    ("Gaussian sx, nm", gx / NM),
    ("Gaussian sp, 1e-25", gp / P25),
    ("Gaussian product / hbar", gx * gp / HBAR),
    ("box level 2 product / hbar", box_product(2)), ("box level 3 product / hbar", box_product(3)),
    ("ring sx, nm", ring_sx / NM),
    ("ring product / hbar", ring_sx * ring_sp / HBAR),
    ("wrong: width as spread, 1e-25", wrong_width / P25),
    ("wrong: h for hbar, 1e-25", wrong_h / P25),
    ("wrong: mean for spread, energy eV", pbar ** 2 / (2 * ME) / EV),
    ("wrong: 1 fm box, speed over c", fermi_v / C),
    ("guitar E2, Hz", fE), ("guitar F2, Hz", fF),
    ("half the gap, Hz", sf_need),
    ("time spread needed st, ms", st_need * 1e3), ("  burst length, about 4 st, ms", 4 * st_need * 1e3),
    ("burst spread sf, measured, Hz", sf_meas),
    ("st sf, against 1/(4 pi)", st_need * sf_meas), ("1/(4 pi)", 1 / (4 * pi)),
    ("hydrogen radius, nm", r0 / NM), ("hydrogen energy, eV", EH),
]
for name, v in rows:
    print(f"{name:<44}{v:12.6f}")

print("chart, k in 1/nm      " + " ".join(f"{k:5d}" for k in range(-12, 13, 2)))
for w in (1.0, 0.5):
    a = pi / (w * NM); L = w * NM      # phi2 reads a and L
    print(f"chart, L = {w:.1f} nm, nm " + " ".join(f"{phi2(k / NM) / (2 * pi) / NM:5.3f}" for k in range(-12, 13, 2)))

assert abs(sx2 - sx) < 1e-6 * sx,      "position spread: sums against formula"
assert abs(sp2 - sp) < 1e-5 * sp,      "momentum spread: slope sums against formula"
assert abs(sp3 - sp) < 1e-4 * sp,      "momentum spread: momentum space against formula"
assert abs(pair / HBAR - 0.5) < 1e-6,  "commutator fixes Im pairing at hbar/2"
assert sx * sp >= HBAR / 2,            "the box obeys the bound"
assert ring_sx * ring_sp < 1e-6 * HBAR, "the ring escapes the line's floor: one definite momentum"
assert abs(gx * gp / HBAR - 0.5) < 1e-6, "the Gaussian sits on the floor"
assert abs(st_need * sf_meas - 1 / (4 * pi)) < 1e-4, "time-frequency floor, measured"
assert abs(sf_meas - sf_need) < 1e-4 * sf_need, "burst spread: measured against target"
assert abs(EH + 13.6057) < 1e-3,       "hydrogen ground energy"
print("ALL CHECKS PASS")
