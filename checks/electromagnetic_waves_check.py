# Electromagnetic waves -- the check behind the card.  Standard library only.
# Road 1: the closed form, c = 1/sqrt(mu0 eps0) and wavelength = c/f.
# Road 2: a simulation that knows only the two curl equations (Yee's leapfrog).
# Road 3: the vector identity the derivation rests on, by finite differences.
from math import sqrt, sin, cos, exp, pi, log10

MU0 = 1.25663706127e-6      # N/A^2, vacuum magnetic permeability (CODATA 2022)
EPS0 = 8.8541878188e-12     # F/m, vacuum electric permittivity (CODATA 2022)
C_DEF = 299792458.0         # m/s, exact: it defines the metre
F = 100e6                   # Hz, the station
E0 = 1e-3                   # V/m, field amplitude of a clearly heard station

# ---- Road 1: closed form
c = 1.0 / sqrt(MU0 * EPS0)
lam = c / F
omega, k = 2 * pi * F, 2 * pi / lam
print(f"mu0  = {MU0 * 1e6:.11f} x 10^-6 N/A^2, eps0 = {EPS0 * 1e12:.10f} x 10^-12 F/m")
print(f"mu0 eps0 = {MU0 * EPS0 * 1e17:.4f} x 10^-17 s^2/m^2")
print(f"c = 1/sqrt(mu0 eps0) = {c:.0f} m/s, defined value {C_DEF:.0f} m/s")
assert abs(c - C_DEF) / C_DEF < 1e-9     # consistency of the constants: since 2019 eps0 = 1/(mu0 c^2)
print(f"f = {F / 1e6:.0f} MHz: period {1e9 / F:.0f} ns, wavelength {lam:.4f} m")
print(f"omega = {omega / 1e6:.1f} x 10^6 rad/s, k = {k:.4f} rad/m, omega/k = {omega / k:.0f} m/s")
print(f"quarter-wave whip {lam / 4:.4f} m, half-wave dipole {lam / 2:.4f} m")
print(f"other waves: 50 Hz {c / 50 / 1e3:.0f} km, 2.45 GHz {c / 2.45e9:.4f} m, 3 GHz {c / 3e9:.4f} m;"
      f" light in 1 ns {c * 1e-9:.4f} m")
print(f"E0 = {E0 * 1e3:.3f} mV/m, B0 = E0/c = {E0 / c * 1e12:.3f} pT")
for ns in (0.0, 2.5, 5.0, 7.5, 10.0):
    print(f"crest at t = {ns:4.1f} ns: x = {c * ns * 1e-9:.3f} m")
def f2(v): return f"{v:6.2f}".replace("-0.00", " 0.00")   # no minus sign on a zero
xs = [0.25 * i for i in range(13)]
print("chart, x (m)         " + " ".join(f"{x:6.2f}" for x in xs))
print("chart, E at 0 ns     " + " ".join(f2(1e3 * E0 * cos(k * x)) for x in xs))
print("chart, E at 2.5 ns   " + " ".join(f2(1e3 * E0 * cos(k * x - omega * 2.5e-9)) for x in xs))
for deg in (0, 30, 45, 60, 90):
    g = cos(deg * pi / 180)
    db = f"{20 * log10(g):6.2f} dB" if g > 1e-9 else "   none"
    print(f"antenna tilted {deg:2d} deg: voltage x {g:.3f}, power x {g * g:.3f}, {db}")

# ---- Road 2: step the two curl equations on a line of cells, 60 cells per wavelength
DX, DT = 0.05, 1e-10                      # m, s; c*DT/DX = 0.6, under the stability limit 1
def simulate(steps, source, probes, term=1.0, dx=DX):   # term: size of Maxwell's term, 1 = true
    n = 700                               # 700 cells, 35 m at 5 cm; E at x = i*dx, B halfway between
    E, B = [0.0] * (n + 1), [0.0] * n
    trace = {p: [] for p in probes}
    for s in range(steps):
        for i in range(n):                # Faraday: dB/dt = -dE/dx
            B[i] -= DT * (E[i + 1] - E[i]) / dx
        for i in range(1, n):             # Ampere-Maxwell in vacuum: dE/dt = -(1/(mu0 eps0)) dB/dx
            E[i] -= term * DT / (MU0 * EPS0) * (B[i] - B[i - 1]) / dx
        E[0] = source((s + 1) * DT)       # the transmitter drives the left end
        for p in probes:
            trace[p].append(E[round(p / dx)])
    return E, B, trace

def peak_time(y):                         # time of the largest sample, refined by a parabola
    m = max(range(len(y)), key=lambda i: y[i])
    a, b, d = y[m - 1], y[m], y[m + 1]
    return (m + 1 + 0.5 * (a - d) / (a - 2 * b + d)) * DT

pulse = lambda t: E0 * exp(-((t - 8e-9) / 2e-9) ** 2)
probes = (3.0, 6.0, 9.0)
def pulse_speed(steps, term=1.0, dx=DX):  # time the pulse's peak from 3 m to 9 m
    tr = simulate(steps, pulse, probes, term, dx)[2]
    return (9.0 - 3.0) / (peak_time(tr[9.0]) - peak_time(tr[3.0])), tr
v, tr = pulse_speed(450)
print(f"simulated pulse speed, 3 m to 9 m: {v:.0f} m/s ({v / c:.4f} of c)")
assert abs(v / c - 1) < 5e-3
for p in probes:
    print(f"pulse peak at {p:.0f} m: {max(tr[p]) * 1e3:.3f} mV/m")
    assert abs(max(tr[p]) - E0) < 0.01 * E0

ramp = lambda t: 0.5 * (1 - cos(pi * t / 20e-9)) if t < 20e-9 else 1.0
def wavelength(f):                        # drive at f; zero crossings from 1 m to 11 m
    E, B, _ = simulate(600, lambda t: E0 * sin(2 * pi * f * t) * ramp(t), ())
    zs = [(i + E[i] / (E[i] - E[i + 1])) * DX for i in range(20, 220) if E[i] * E[i + 1] < 0]
    return 2 * (zs[-1] - zs[0]) / (len(zs) - 1), len(zs), E, B
lam_sim, nz, E, B = wavelength(F)
print(f"simulated wavelength, 1 m to 11 m: {lam_sim:.4f} m ({nz} zero crossings)")
assert abs(lam_sim / lam - 1) < 5e-3
ratio = max(abs(e) for e in E[20:220]) / (c * max(abs(b) for b in B[20:220]))
print(f"simulated E/(cB) = {ratio:.3f}")
assert abs(ratio - 1) < 1e-2

# ---- Road 3: curl of curl of a field with zero divergence equals minus its Laplacian
def field(x, y, z): return (z * z * sin(y), x ** 3 * cos(z), y * exp(x))
H = 1e-3
def partial(fn, j, a, pt):                # d(component j)/d(coordinate a), central difference
    up, dn = list(pt), list(pt)
    up[a] += H; dn[a] -= H
    return (fn(*up)[j] - fn(*dn)[j]) / (2 * H)
def curl(fn):
    return lambda *pt: (partial(fn, 2, 1, pt) - partial(fn, 1, 2, pt),
                        partial(fn, 0, 2, pt) - partial(fn, 2, 0, pt),
                        partial(fn, 1, 0, pt) - partial(fn, 0, 1, pt))
x, y, z = 0.3, 0.7, 1.1
num = curl(curl(field))(x, y, z)
exact = ((z * z - 2) * sin(y), (x ** 3 - 6 * x) * cos(z), -y * exp(x))   # -Laplacian, by hand
print("curl curl F, differences: " + " ".join(f"{a:.5f}" for a in num))
print("minus Laplacian, by hand: " + " ".join(f"{a:.5f}" for a in exact))
assert max(abs(a - b) for a, b in zip(num, exact)) < 1e-5

# ---- What breaks
print(f"wrong: omega in place of f: wavelength {c / omega:.4f} m, whip {c / omega / 4:.4f} m")
print(f"wrong: no square root: speed {1 / (MU0 * EPS0) / 1e16:.3f} x 10^16 m/s")
print(f"outside the model: in polyethylene (permittivity 2.25 eps0): wavelength {lam / sqrt(2.25):.4f} m")
vq = pulse_speed(800, term=0.25)[0]       # Maxwell's term at a quarter of its size
print(f"Maxwell's term at a quarter: pulse speed {vq:.0f} m/s ({vq / c:.4f} of c)")
assert abs(vq / (c / 2) - 1) < 1e-2       # a quarter of the term halves the speed
lam88 = wavelength(88e6)[0]
print(f"try: F = 88 MHz: wavelength {c / 88e6:.4f} m, whip {c / 88e6 / 4:.4f} m, simulated {lam88:.4f} m")
v20 = pulse_speed(450, dx=0.2)[0]
print(f"try: 20 cm cells, {lam / 0.2:.0f} per wavelength: pulse speed {v20 / c:.4f} of c")
print(f"try: 0.2 ns step: light crosses {c * 2e-10 / DX:.2f} cells per step, over the limit 1")
print("ALL CHECKS PASS")
