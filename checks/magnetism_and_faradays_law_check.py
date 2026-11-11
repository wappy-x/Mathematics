# Magnetic fields and Faraday's law -- the check behind the card.  Standard library only.
# A 1000-turn coil, 25 cm long, 5 cm across, carrying 3 A, switched off in 10 ms.
from math import pi, sqrt, log, exp

MU0 = 1.25663706127e-6        # magnetic constant, N/A^2 (NIST CODATA 2022)
QE = 1.602176634e-19          # electron charge, C (exact)
ME = 9.1093837139e-31         # electron mass, kg (NIST CODATA 2022)
N, ELL, R_IN, I0 = 1000, 0.25, 0.025, 3.0     # turns, length m, radius m, current A
R_COIL, V_SUP, V_D, DT = 4.0, 12.0, 0.7, 0.010  # ohm, V, diode drop V, switch-off time s

def ideal_B(N, ell, I):    return MU0 * N / ell * I                 # Ampere's loop: B = mu0 n I
def ideal_L(N, ell, r):    return MU0 * N * N * pi * r * r / ell    # L = mu0 N^2 A / ell
def loop_Bz(r, z, I):      return MU0 * I * r * r / (2.0 * (r * r + z * z) ** 1.5)  # one turn, on its axis

def coil_Bz(z, N=N, ell=ELL, r=R_IN, I=I0):
    # Road 2 for B: Biot-Savart, every one of the N turns added one by one
    return sum(loop_Bz(r, z - (-ell / 2 + (i + 0.5) * ell / N), I) for i in range(N))

def sheet_Bz(z, N=N, ell=ELL, r=R_IN, I=I0):
    # the same sum done as an integral, in closed form: mu0 n I (cos a1 + cos a2) / 2
    a, b = ell / 2 - z, ell / 2 + z
    return MU0 * N / ell * I * (a / sqrt(a * a + r * r) + b / sqrt(b * b + r * r)) / 2

def KE(k):    # complete elliptic integrals K(k), E(k) by the arithmetic-geometric mean
    a, b, c, s, p = 1.0, sqrt(1 - k * k), k, k * k / 2, 1.0
    while abs(c) > 1e-15:
        a, b, c = (a + b) / 2, sqrt(a * b), (a - b) / 2
        p *= 2; s += p * c * c / 2
    return pi / (2 * a), pi / (2 * a) * (1 - s)

def nagaoka(ell, r):   # finite-length factor for a current sheet: L = K_N * ideal L
    k, kp = 2 * r / sqrt(4 * r * r + ell * ell), ell / sqrt(4 * r * r + ell * ell)
    K, E = KE(k)
    return 4 / (3 * pi * kp) * (kp * kp / (k * k) * (K - E) + E - k)

def mutual(u, r):      # Maxwell: two coaxial turns of radius r, a distance u apart
    k = sqrt(4 * r * r / (4 * r * r + u * u)); K, E = KE(k)
    return MU0 * r * ((2 / k - k) * K - 2 / k * E)

def L_by_pairs(N, ell, r, m=4000):
    # Road 3 for L: add the flux every slice of winding sends through every other slice.
    # L = (N/ell)^2 * 2 * integral_0^ell (ell - u) M(u) du, with u = ell s^2 to tame the log at u = 0
    tot = 0.0
    for i in range(m):
        s = (i + 0.5) / m; u = ell * s * s
        tot += (ell - u) * mutual(u, r) * 2 * ell * s / m
    return 2 * tot * (N / ell) ** 2

def rk4(f, y, h):
    k1 = f(y); k2 = f([a + h / 2 * b for a, b in zip(y, k1)])
    k3 = f([a + h / 2 * b for a, b in zip(y, k2)]); k4 = f([a + h * b for a, b in zip(y, k3)])
    return [a + h / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(y, k1, k2, k3, k4)]

A = pi * R_IN ** 2
B = ideal_B(N, ELL, I0); L = ideal_L(N, ELL, R_IN)
loop_len = 0.075; turns_in = N / ELL * loop_len               # Ampere rectangle 75 mm long
B_amp = MU0 * turns_in * I0 / loop_len
Bc_sum, Bc_sheet = coil_Bz(0.0), sheet_Bz(0.0)
Be_sum, Be_sheet = coil_Bz(ELL / 2), sheet_Bz(ELL / 2)
phi = B * A; link = N * phi
KN = nagaoka(ELL, R_IN); L_fin = KN * L; L_pairs = L_by_pairs(N, ELL, R_IN)
emf = L * I0 / DT; emf_far = N * A * (B - 0.0) / DT           # L dI/dt, and N dPhi/dt from the field
steps = 1000; h = DT / steps                                   # energy the 2.96 V delivers while I ramps 3 -> 0
W_out = sum(emf * I0 * (1 - (k + 0.5) / steps) * h for k in range(steps))
W_L = 0.5 * L * I0 ** 2; W_field = B * B / (2 * MU0) * A * ELL
tau = L / R_COIL; t_off = tau * log(1 + R_COIL * I0 / V_D)    # diode route: L dI/dt = -(R I + V_D)
y, t, hs = [I0], 0.0, 1e-6
while True:
    y2 = rk4(lambda v: [-(R_COIL * v[0] + V_D) / L], y, hs)
    if y2[0] <= 0: t += hs * y[0] / (y[0] - y2[0]); break
    y, t = y2, t + hs
t_off_sim = t
v_e = sqrt(2 * QE * 100.0 / ME); rad = ME * v_e / (QE * B); per = 2 * pi * ME / (QE * B)
st = [0.0, 0.0, v_e, 0.0]; xmax = 0.0                          # electron in the coil: F = q v x B, B along z
for _ in range(4000):
    st = rk4(lambda s: [s[2], s[3], -QE / ME * s[3] * B, QE / ME * s[2] * B], st, per / 4000)
    xmax = max(xmax, sqrt(st[0] ** 2 + st[1] ** 2))
rad_sim = xmax / 2
short_ideal, short_true = ideal_B(N, 0.05, I0), sheet_Bz(0.0, ell=0.05)
rows = [
    ("turns per metre n, 1/m", N / ELL), ("cross-section A, cm^2", A * 1e4),
    ("1 B = mu0 n I, mT", B * 1e3), ("2 Ampere loop: turns inside", turns_in),
    ("  current inside, A", turns_in * I0), ("  B from the loop, mT", B_amp * 1e3),
    ("3 Biot-Savart centre, 1000 turns, mT", Bc_sum * 1e3), ("  closed form, centre, mT", Bc_sheet * 1e3),
    ("  centre / ideal", Bc_sheet / B), ("  Biot-Savart at an end, mT", Be_sum * 1e3), ("  end / ideal", Be_sheet / B),
    ("flux per turn, uWb", phi * 1e6), ("flux linkage N Phi, mWb", link * 1e3),
    ("L ideal = mu0 N^2 A / ell, mH", L * 1e3), ("  N Phi / I, mH", link / I0 * 1e3),
    ("Nagaoka factor", KN), ("L finite, Nagaoka, mH", L_fin * 1e3), ("L finite, turn pairs, mH", L_pairs * 1e3),
    ("dI/dt during the ramp, A/s", I0 / DT), ("emf L I / dt, 10 ms, V", emf), ("  N A dB/dt, V", emf_far), ("  with finite L, V", L_fin * I0 / DT),
    ("  switch, end of ramp: V_sup + emf, V", V_SUP + emf), ("emf, off in 1 ms, V", L * I0 / 1e-3), ("emf, off in 10 us, V", L * I0 / 1e-5),
    ("coil volume, cm^3", A * ELL * 1e6), ("energy 1/2 L I^2, J", W_L), ("energy B^2/2mu0 x volume, J", W_field), ("energy emf x I summed, J", W_out),
    ("diode: tau = L/R, ms", tau * 1e3), ("  current gone, formula, ms", t_off * 1e3),
    ("  current gone, RK4, ms", t_off_sim * 1e3), ("  switch sees V_sup + V_D, V", V_SUP + V_D),
    ("electron 100 V: speed, km/s", v_e / 1e3), ("  circle radius m v/(q B), mm", rad * 1e3),
    ("  radius by RK4, mm", rad_sim * 1e3), ("  one lap, ns", per * 1e9),
    ("wrong: N for n, mT", ideal_B(N, 1.0, I0) * 1e3), ("wrong: N not N^2, uH", L / N * 1e6),
    ("  its emf, mV", L / N * I0 / DT * 1e3), ("wrong: diameter as radius, mH", ideal_L(N, ELL, 2 * R_IN) * 1e3),
    ("  its emf, V", ideal_L(N, ELL, 2 * R_IN) * I0 / DT),
    ("short 5 cm coil: mu0 n I, mT", short_ideal * 1e3), ("  true centre, mT", short_true * 1e3), ("  formula / true", short_ideal / short_true),
]
for name, v in rows:
    print(f"{name:<38} {v:>14.6f}")
zs = [(25 * i - 200) / 1000 for i in range(17)]
print("chart, z mm      " + " ".join(f"{25 * i - 200:6d}" for i in range(17)))
print("chart, B mT      " + " ".join(f"{coil_Bz(z) * 1e3:6.2f}" for z in zs))
ts = [0.001 * i for i in range(11)]
print("chart, t ms      " + " ".join(f"{t * 1e3:6.0f}" for t in ts))
print("chart, ramp A    " + " ".join(f"{I0 * (1 - t / DT):6.2f}" for t in ts))
print("chart, diode A   " + " ".join(f"{max((I0 + V_D / R_COIL) * exp(-t / tau) - V_D / R_COIL, 0.0):6.2f}" for t in ts))
px = lambda mm: 60 + 1.6 * mm                                  # figure: 1.6 px per mm
print(f"figure, 1.6 px/mm, 25 marks of 40 turns, coil x {px(0):.0f}-{px(250):.0f}, wires y {110 - 1.6 * 25:.0f} and {110 + 1.6 * 25:.0f}, "
      f"loop x {px(87.5):.0f}-{px(162.5):.0f} y 20-110")

assert abs(B_amp - B) / B < 1e-12                              # Ampere loop agrees with B = mu0 n I
assert abs(Bc_sum - Bc_sheet) / Bc_sheet < 1e-5                # 1000 turns one by one vs the integral
assert abs(Be_sum - Be_sheet) / Be_sheet < 1e-3
assert 0.97 < Bc_sum / B < 0.99 and 0.49 < Be_sum / B < 0.51   # long coil: 2% short at centre, half at the ends
assert abs(link / I0 - L) / L < 1e-12                          # flux linkage / current = mu0 N^2 A / ell
assert abs(L_pairs - L_fin) / L_fin < 1e-5                     # turn-pair double integral vs Nagaoka
assert abs(emf_far - emf) / emf < 1e-12                        # N dPhi/dt = L dI/dt
assert abs(W_field - W_L) / W_L < 1e-12 and abs(W_out - W_L) / W_L < 1e-9   # three energies agree
assert abs(t_off_sim - t_off) < 2e-6                           # RK4 diode decay vs closed form
assert abs(rad_sim - rad) / rad < 1e-4                         # simulated electron circle vs m v / (q B)
print("ALL CHECKS PASS")
