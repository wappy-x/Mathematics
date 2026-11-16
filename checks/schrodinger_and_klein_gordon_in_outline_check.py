# Schrodinger and Klein-Gordon: a free electron packet, 1 nm wide, moving at 1e6 m/s.
# Roads: the closed-form Gaussian; its width and total chance measured by Simpson's rule;
# the equation's residual by centred differences; a sum of plane waves; the energy method;
# Klein-Gordon's dispersion relation by formula and by centred differences.
from math import pi, sqrt, exp
from cmath import exp as cexp, sqrt as csqrt
HBAR = 0.6582119569                    # reduced Planck constant, eV fs
MC2 = 510998.95069                     # electron rest energy, eV
MPC2 = 938272089.43                    # proton rest energy, eV
C = 299.792458                         # speed of light, nm/fs
D = HBAR * C * C / (2 * MC2)           # hbar / 2m, nm^2/fs
S0, V0 = 1.0, 1.0                      # starting width, nm; group velocity, nm/fs (1e6 m/s)
K0 = V0 / (2 * D)                      # wavenumber, rad/nm
TAU = S0 * S0 / D                      # spreading time, fs
def packet(x, t, d, k0=K0, s0=S0):     # Gaussian start; d = iD gives Schrodinger, d = D gives heat
    z = 1 + d * t / (s0 * s0)
    return (2 * pi * s0 * s0) ** -0.25 / csqrt(z) * cexp((-x * x / (4 * s0 * s0) + 1j * k0 * x - d * k0 * k0 * t) / z)
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def moments(f, centre, half):          # total of |f|^2, its mean and its width (standard deviation)
    w = lambda x: abs(f(x)) ** 2
    n0 = simpson(w, centre - half, centre + half)
    m1 = simpson(lambda x: x * w(x), centre - half, centre + half) / n0
    m2 = simpson(lambda x: (x - m1) ** 2 * w(x), centre - half, centre + half) / n0
    return n0, m1, sqrt(m2)
width = lambda t, s0=S0, d=D: s0 * sqrt(1 + (d * t / (s0 * s0)) ** 2)
print(f"constants: hbar = {HBAR:.10f} eV fs, m c^2 = {MC2:.5f} eV, c = {C:.6f} nm/fs")
print(f"D = hbar/2m = {D:.7f} nm^2/fs = {D * 1e-3:.7e} m^2/s")
print(f"packet: width {S0:.1f} nm, speed {V0:.1f} nm/fs, k0 = {K0:.5f} rad/nm, wavelength {2 * pi / K0:.6f} nm, "
      f"energy {0.5 * MC2 * (V0 / C) ** 2:.5f} eV")
print(f"tau = width^2/D = {TAU:.4f} fs; velocity spread D/width = {D / S0 * 1e3:.4f} km/s")
print("t fs | Schrodinger width nm: formula, measured | total chance | centre nm | heat width nm | heat size | wave width nm")
rows = {}
for t in sorted([10.0 * j for j in range(11)] + [TAU, 1000.0]):
    span = 12 * S0 * (1 + t / TAU)
    ns, ms, ws = moments(lambda x: packet(x, t, 1j * D), V0 * t, span)
    nh, _, wh = moments(lambda x: packet(x, t, D, 0.0), 0.0, span)
    _, _, ww = moments(lambda x: packet(x - C * t, 0, D), C * t, 12 * S0)
    rows[t] = (ws, ns, wh, nh)
    print(f"{t:8.3f} | {width(t):9.4f} {ws:9.4f} | {ns:.9f} | {ms:8.3f} | {wh:7.4f} | {nh:.4f} | {ww:.4f}")
    assert abs(ws - width(t)) < 1e-6 * width(t) and abs(ns - 1) < 1e-9, "width and total chance must match"
    assert abs(wh - S0 * sqrt(1 + t / TAU)) < 1e-6 * wh and abs(nh - (1 + t / TAU) ** -0.5) < 1e-8, "heat"
print(f"at 1 ps: t/tau = {1000 / TAU:.4f}, velocity spread x time = {D / S0 * 1000:.4f} nm")
dens = lambda y, t: abs(packet(y + V0 * t, t, 1j * D)) ** 2
for t in (0.0, 20.0, 50.0):
    print(f"profile at {t:4.1f} fs, chance per nm at x - v0 t = -12..12 nm: "
          + ", ".join(f"{dens(y, t):.3f}" for y in range(-12, 13, 2)))
xr, tr = V0 * 50 + 1.0, 50.0
res = []
for h in (0.01, 0.005):
    pt = (packet(xr, tr + h, 1j * D) - packet(xr, tr - h, 1j * D)) / (2 * h)
    pxx = (packet(xr + h, tr, 1j * D) - 2 * packet(xr, tr, 1j * D) + packet(xr - h, tr, 1j * D)) / (h * h)
    res.append(abs(pt - 1j * D * pxx) / abs(pt))
print(f"residual |psi_t - i D psi_xx| / |psi_t| at steps 0.01, 0.005: {res[0]:.3e}, {res[1]:.3e}, ratio {res[0] / res[1]:.2f}")
assert 3.5 < res[0] / res[1] < 4.5 and res[1] < 1e-3, "the residual is step error, falling as h^2"
def plane_waves(x, t, n):               # (1/2pi) * integral of phi(k) e^{i(kx - D k^2 t)} dk
    amp = (2 * pi * S0 * S0) ** -0.25 * sqrt(4 * pi) * S0 / (2 * pi)
    f = lambda k: amp * exp(-(S0 * (k - K0)) ** 2) * cexp(1j * (k * x - D * k * k * t))
    return simpson(f, K0 - 7 / S0, K0 + 7 / S0, n)
for t, n in ((50.0, 4000), (1000.0, 80000)):
    x = V0 * t + width(t)
    a, b = packet(x, t, 1j * D), plane_waves(x, t, n)
    print(f"psi at centre + width, {t:.0f} fs: closed form {a.real:+.6f} {a.imag:+.6f}i, plane waves {b.real:+.6f} {b.imag:+.6f}i")
    assert abs(a - b) < 1e-6 * abs(a), "plane-wave sum must equal the closed form"
print(f"plane-wave sum cut at k0 +/- 7/width: first omitted weight exp(-49) = {exp(-49):.1e} of the peak")
dt = 0.01
rate = lambda t: (moments(lambda x: packet(x, t + dt, D, 0.0), 0, 30)[0] - moments(lambda x: packet(x, t - dt, D, 0.0), 0, 30)[0]) / (2 * dt)
ux2 = simpson(lambda x: abs((packet(x + 1e-4, TAU, D, 0.0) - packet(x - 1e-4, TAU, D, 0.0)) / 2e-4) ** 2, -30, 30)
srate = (moments(lambda x: packet(x, 50 + dt, 1j * D), 50 + dt, 40)[0] - moments(lambda x: packet(x, 50 - dt, 1j * D), 50 - dt, 40)[0]) / (2 * dt)
print(f"heat size rate at tau: {rate(TAU):.6f} /fs measured, {-2 * D * ux2:.6f} /fs from -2D * integral |u_x|^2, "
      f"{-0.5 / TAU * 2 ** -1.5:.6f} /fs exact")
print(f"Schrodinger total-chance rate at 50 fs: {'below' if abs(srate) < 1e-9 else 'above'} 1e-9 /fs")
assert abs(rate(TAU) + 2 * D * ux2) < 1e-5 * abs(rate(TAU)) and abs(srate) < 1e-9, "energy method"
print(f"mode at k0 after 1 fs: heat keeps {exp(-D * K0 * K0):.5f} of it, Schrodinger keeps {abs(cexp(-1j * D * K0 * K0)):.5f}")
WM = MC2 / HBAR                         # rest frequency m c^2 / hbar, rad/fs
excess = lambda k: (C * k) ** 2 / (sqrt((C * k) ** 2 + WM * WM) + WM)   # omega - omega_m, stable form
print(f"Klein-Gordon rest frequency m c^2/hbar = {WM:.2f} rad/fs = {WM * 1e15:.6e} rad/s")
ex, es = excess(K0), D * K0 * K0
print(f"at k0: omega - rest = {ex:.7f} rad/fs (Klein-Gordon), D k0^2 = {es:.7f} rad/fs (Schrodinger), "
      f"gap {(es - ex) / es * 1e6:.3f} ppm, (v/c)^2/4 = {(V0 / C) ** 2 / 4 * 1e6:.3f} ppm")
om = WM + ex
vg_f, h = C * C * K0 / om, 1e-3
vg_d = (excess(K0 + h) - excess(K0 - h)) / (2 * h)
pc = HBAR * C * K0
vg_r = C * pc / sqrt(pc * pc + MC2 * MC2)
print(f"group velocity, nm/fs: Schrodinger 2 D k0 = {2 * D * K0:.6f}; Klein-Gordon c^2 k/omega = {vg_f:.6f}, "
      f"centred difference {vg_d:.6f}, p c^2/E = {vg_r:.6f}")
print(f"phase velocity, nm/fs: Schrodinger D k0 = {D * K0:.6f}; Klein-Gordon omega/k = {om / K0:.3f}; "
      f"phase x group = {om / K0 * vg_f:.3f} = c^2 = {C * C:.3f}")
assert abs(vg_f - vg_d) < 1e-6 and abs(vg_f - vg_r) < 1e-12 and abs((es - ex) / es - (V0 / C) ** 2 / 4) < 1e-3 * (V0 / C) ** 2
KS = [0.25 * j for j in range(9)]
print("dispersion, scaled K = hbar k/(m c), omega/omega_m:")
print("  Klein-Gordon: " + ", ".join(f"{sqrt(1 + q * q):.3f}" for q in KS))
print("  Schrodinger + rest: " + ", ".join(f"{1 + q * q / 2:.3f}" for q in KS))
print("  light: " + ", ".join(f"{q:.3f}" for q in KS))
T = 200000.0                            # microscope electron, kinetic energy in eV
pcr, pcs = sqrt(T * T + 2 * T * MC2), sqrt(2 * T * MC2)
lr, ls = 2 * pi * HBAR * C / pcr * 1e3, 2 * pi * HBAR * C / pcs * 1e3
print(f"200 keV electron: wavelength {lr:.4f} pm (Klein-Gordon), {ls:.4f} pm (Schrodinger), {(ls / lr - 1) * 100:.1f}% long; "
      f"speed {pcr / (T + MC2):.4f} c against {sqrt(2 * T / MC2):.4f} c")
assert abs(lr - 2.5079) < 1e-3 and ls > lr, "relativistic wavelength"
w1k = rows[1000.0]
print(f"wrong: diffusion's square-root law at 1 ps gives {w1k[2]:.4f} nm, not {w1k[0]:.4f} nm")
print(f"wrong: packet moved at phase velocity: centre at {D * K0 * 1000:.0f} nm after 1 ps, not {V0 * 1000:.0f} nm")
print(f"wrong: Klein-Gordon phase velocity as the speed: {om / K0 * 1e6:.4e} m/s, not {vg_f * 1e6:.0f} m/s")
dp = HBAR * C * C / (2 * MPC2)
print(f"try: width 2 nm: tau {4 / D:.2f} fs, width at 1 ps {width(1000, 2.0):.2f} nm; proton: tau {1 / dp:.0f} fs, "
      f"width at 1 ps {width(1000, 1.0, dp):.6f} nm")
_, _, wback = moments(lambda x: packet(x, -1000.0, 1j * D), -V0 * 1000, 12 * S0 * (1 + 1000 / TAU))
print(f"try: run back to t = -1 ps: width {wback:.4f} nm, so a packet started like that focuses to 1 nm at t = 0")
assert abs(wback - width(1000)) < 1e-6 * wback and w1k[0] > 3 * w1k[2], "reversibility; spreading beats diffusion"
print("ALL CHECKS PASS")
