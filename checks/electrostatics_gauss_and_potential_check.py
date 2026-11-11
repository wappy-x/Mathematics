# Electric fields, Gauss's law and voltage -- the check behind the card.  Standard library only.
# A radio's tuning capacitor: two square plates 10 cm across, 1 mm of air apart, +1 nC and -1 nC.
# Road 1: Gauss's law in closed form.  Road 2: Coulomb's law summed piece by piece over the charge,
# then the field integrated along a path to get the voltage.  A closed-form square-sheet field is a third.
import math

EPS0 = 8.8541878188e-12          # F/m, NIST CODATA 2022
K = 1 / (4 * math.pi * EPS0)     # Coulomb's constant, N m^2/C^2
Q = 1e-9                         # C, charge on each plate (+Q on top, -Q below)
SIDE, GAP = 0.10, 0.001          # m, plate side and gap
R_BALL = 0.01                    # m, radius of the charged sphere
L_COIL = 250e-6                  # H, tuning coil

def simpson(f, lo, hi, n):       # Simpson's rule, n even
    h = (hi - lo) / n
    return h / 3 * (f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n)))

def coulomb_E(q, src, at):       # field vector of a point charge q at src, felt at point at
    d = [at[i] - src[i] for i in range(3)]
    r = math.sqrt(sum(c * c for c in d))
    return [K * q * c / r ** 3 for c in d]

def cube_flux(src, half=0.01, n=60):   # flux out of a 2 cm cube centred at 0, midpoint rule, 6 faces
    total, h = 0.0, 2 * half / n
    for axis in range(3):
        for sign in (1, -1):
            for i in range(n):
                for j in range(n):
                    p = [0.0, 0.0, 0.0]
                    p[axis] = sign * half
                    p[(axis + 1) % 3] = -half + (i + 0.5) * h
                    p[(axis + 2) % 3] = -half + (j + 0.5) * h
                    total += sign * coulomb_E(Q, src, p)[axis] * h * h
    return total

def shell_E(r, R=R_BALL):        # charge Q spread evenly on a sphere: add rings, field along the axis
    def ring(th):                # ring at polar angle th holds Q sin(th)/2 dth
        dz, rho = r - R * math.cos(th), R * math.sin(th)
        return K * (Q * math.sin(th) / 2) * dz / (dz * dz + rho * rho) ** 1.5
    return simpson(ring, 0, math.pi, 2000)

def sheet_E(z, sigma):           # uniform square sheet: Coulomb summed in polar angles about the foot point
    rho = lambda p: (SIDE / 2) / math.cos(p)          # distance to the edge, 0 <= p <= 45 degrees
    # a patch at angle t from the vertical adds K sigma sin(t) dt dp along the axis; 8 equal slices
    return 8 * K * sigma * simpson(lambda p: simpson(math.sin, 0, math.atan2(rho(p), z), 32), 0, math.pi / 4, 32)

def sheet_closed(z, sigma):      # the known closed form for a uniform square sheet, on its axis
    return sigma / (math.pi * EPS0) * math.atan(SIDE ** 2 / (4 * z * math.sqrt(z * z + SIDE ** 2 / 2)))

def plates(gap, q=Q):            # road 2 for the plates: field midway and voltage along the axis
    s = q / SIDE ** 2
    E_mid = 2 * sheet_E(gap / 2, s)
    V = simpson(lambda z: sheet_E(z, s) + sheet_E(gap - z, s), 0, gap, 40)
    return E_mid, V

def line(label, value): print(f"{label:<52}{value}")

# ---- Coulomb and Gauss: the flux through a closed surface counts the charge inside ----
line("k = 1/(4 pi eps0), N m^2/C^2", f"{K / 1e9:.6f} x 10^9")
E1 = K * Q / R_BALL ** 2
line("Coulomb field of 1 nC at 1 cm, V/m", f"{E1:.1f}")
gauss_flux = Q / EPS0
f_in, f_out = cube_flux((0.002, 0.001, -0.003)), cube_flux((0.03, 0.0, 0.0))
line("Gauss: flux = Q/eps0, V m", f"{gauss_flux:.4f}")
line("Coulomb summed over a cube, charge inside, V m", f"{f_in:.4f}")
line("Coulomb summed over a cube, charge outside, V m", f"{abs(f_out):.4f}")
assert abs(f_in / gauss_flux - 1) < 1e-4 and abs(f_out) < 1e-4 * gauss_flux

# ---- the charged sphere: Gauss's law with a sphere as the closed surface ----
for r in (0.02, 0.005):
    gauss = K * Q / r ** 2 if r > R_BALL else 0.0
    line(f"sphere, field at {r * 100:.1f} cm: Gauss | rings, V/m", f"{gauss:.1f} | {abs(shell_E(r)):.1f}")
    assert abs(shell_E(r) - gauss) < 1e-6 * E1
V_ball = K * Q / R_BALL
# voltage = field added along the way out to infinity; u = 1/r makes that run 0 < u < 1/R, dr = du/u^2
n, top = 40, 1 / R_BALL
V_ball_num = sum(shell_E(1 / u) / u ** 2 * top / n for u in ((i + 0.5) * top / n for i in range(n)))
line("sphere potential: kQ/R | ring field integrated, V", f"{V_ball:.2f} | {V_ball_num:.2f}")
assert abs(V_ball_num - V_ball) < 1e-5 * V_ball

# ---- the plates: pillbox gives sigma/eps0, then V = E d ----
sigma = Q / SIDE ** 2
E_gauss = sigma / EPS0
V_gauss = E_gauss * GAP
line("plates: sigma, nC/m^2", f"{sigma * 1e9:.1f}")
line("plates: E = sigma/eps0, V/m", f"{E_gauss:.1f}")
line("plates: V = E d, V", f"{V_gauss:.3f}")
E_num, V_num = plates(GAP)
line("Coulomb over finite plates: E at centre, V/m", f"{E_num:.1f}")
line("Coulomb over finite plates: V along the axis, V", f"{V_num:.3f}")
line("finite plates against Gauss, field shortfall, %", f"{100 * (1 - E_num / E_gauss):.2f}")
assert abs(E_num / E_gauss - 1) < 0.015 and abs(V_num / V_gauss - 1) < 0.015
assert abs(sheet_E(GAP / 2, sigma) - sheet_closed(GAP / 2, sigma)) < 1e-6 * E_gauss
C = Q / V_gauss
line("capacitance C = Q/V = eps0 A/d, pF", f"{C * 1e12:.2f} | {EPS0 * SIDE ** 2 / GAP * 1e12:.2f}")
f_tune = 1 / (2 * math.pi * math.sqrt(L_COIL * C))
line("tunes with 250 uH to, kHz", f"{f_tune / 1e3:.1f}")
line("same 1 nC: plate voltage | sphere voltage, V", f"{V_gauss:.3f} | {V_ball:.2f}")

# ---- what breaks ----
line("mistake 1, one sheet's field sigma/(2 eps0): V", f"{V_gauss / 2:.3f}")
line("mistake 2, point-charge kQ/d^2 across the gap: V", f"{K * Q / GAP ** 2 * GAP:.1f}")
line("mistake 3, kQ/r^2 inside the sphere at 0.5 cm: V/m", f"{K * Q / 0.005 ** 2:.1f}")
line("sign slip, minus dropped: top minus bottom, V", f"{-V_gauss:.3f}")
E50, V50 = plates(0.05)
line("mistake 4, 50 mm gap: Gauss V | finite plates V", f"{E_gauss * 0.05:.1f} | {V50:.1f}")
line("50 mm gap: field at centre, % of Gauss", f"{100 * E50 / E_gauss:.1f}")
assert E50 < 0.7 * E_gauss and abs(sheet_E(0.025, sigma) - sheet_closed(0.025, sigma)) < 1e-6 * E_gauss

# ---- try changing ----
line("try: gap 2 mm, C pF | tuning kHz", f"{EPS0 * SIDE ** 2 / 0.002 * 1e12:.2f} | "
     f"{1 / (2 * math.pi * math.sqrt(L_COIL * EPS0 * SIDE ** 2 / 0.002)) / 1e3:.1f}")
line("try: 3 nC on the plates, V", f"{3 * V_gauss:.3f}")
line("try: sphere radius 2 cm, V", f"{K * Q / 0.02:.2f}")

# ---- figure: sphere at 40 px per cm, arrows 0.8 px per kV/m; plates at 50 px per mm ----
line("figure, px: sphere r | Gauss r | arrows 1 cm, 2 cm",
     f"{R_BALL * 4000:.0f} | {0.02 * 4000:.0f} | {E1 / 1e3 * 0.8:.0f}, {K * Q / 0.02 ** 2 / 1e3 * 0.8:.0f}")
line("figure, plate gap px", f"{GAP * 50000:.0f}")
print("ALL CHECKS PASS")
