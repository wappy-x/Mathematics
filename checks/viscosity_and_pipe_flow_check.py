# Viscosity and pipe flow -- the check behind the card.  Standard library only.
# A heating loop pushes 12 L/min of 70 C water through 15 mm copper pipe.
# Road 1: the closed form, Poiseuille's law.  Road 2: the boundary value
# problem (1/r)(r u')' = -G/mu, u(R) = 0, solved by finite differences.
# Road 3: energy -- pump power per metre equals the heat made by viscosity.
# Then the Reynolds number says whether the laminar answer applies at all.
from math import pi, log

MU, RHO = 4.03561e-4, 977.786       # water at 70 C, 0.15 MPa: Pa s, kg/m^3 (NIST)
MU20, RHO20 = 1.00158e-3, 998.229   # water at 20 C, 0.15 MPa (NIST)
D = 0.015 - 2 * 0.0007              # bore: 15 mm outside, 0.7 mm wall, in m
R = D / 2
LOOP = 20.0                          # metres of pipe, flow plus return
LPM = 1.0 / 60000.0                  # one litre a minute, in m^3/s
Q = 12 * LPM

def g_lam(q, d=D, mu=MU):            # Poiseuille: pressure drop per metre, Pa/m
    return 128 * mu * q / (pi * d ** 4)

def reynolds(q, d=D, mu=MU, rho=RHO):
    return rho * (q / (pi * d * d / 4)) * d / mu

def g_blasius(q, d=D, mu=MU, rho=RHO):   # smooth pipe, turbulent, Re 4e3 to 1e5
    v = q / (pi * d * d / 4)
    return 0.3164 * reynolds(q, d, mu, rho) ** -0.25 * rho * v * v / (2 * d)

def g_real(q):                       # laminar below Re 2300, Blasius above
    return g_lam(q) if reynolds(q) < 2300 else g_blasius(q)

def fd_profile(g, n):                # road 2: u at r_i = i h, for gradient g
    h = R / n
    a, b, c, f = [0.0] * n, [0.0] * n, [0.0] * n, [-g / MU] * n
    b[0], c[0] = -4 / h ** 2, 4 / h ** 2          # centre: u' = 0, so 2u'' = -g/mu
    for i in range(1, n):
        r = i * h
        a[i] = (r - h / 2) / (r * h * h)
        c[i] = (r + h / 2) / (r * h * h)
        b[i] = -(a[i] + c[i])                      # wall value u_n = 0 drops out
    for i in range(1, n):                          # Thomas algorithm, forward sweep
        w = a[i] / b[i - 1]
        b[i] -= w * c[i - 1]
        f[i] -= w * f[i - 1]
    u = [0.0] * (n + 1)
    for i in range(n - 1, -1, -1):
        u[i] = (f[i] - c[i] * u[i + 1]) / b[i]
    return u, h

def fd_flow_and_heat(g, n):
    u, h = fd_profile(g, n)
    q = sum(pi * h * (i * h * u[i] + (i + 1) * h * u[i + 1]) for i in range(n))
    heat = sum(MU * ((u[i + 1] - u[i]) / h) ** 2 * 2 * pi * (i + 0.5) * h * h for i in range(n))
    return u, q, heat

# ---- road 1: the closed form ----
G1 = g_lam(Q)
V = Q / (pi * R * R)
UMAX = G1 * R * R / (4 * MU)
TAU_W = G1 * R / 2
# ---- road 2: finite differences, solved for 1 Pa/m then scaled (the law is linear) ----
u40, q40, heat40 = fd_flow_and_heat(1.0, 40)
_, q80, _ = fd_flow_and_heat(1.0, 80)
G2 = Q / q40
# ---- road 3: energy.  Pump power per metre G*Q equals viscous heating per metre ----
G3 = Q / heat40                      # G * Q = G^2 * heat40, so G = Q / heat40
RE = reynolds(Q)
GT = g_blasius(Q)
print(f"inputs: 70 C, 0.15 MPa: rho {RHO:.3f} kg/m^3, mu {MU:.9f} Pa s; 20 C: rho {RHO20:.3f}, mu {MU20:.8f}")
print("inputs: walls 0.7 mm (15 mm pipe) and 0.9 mm (22 mm pipe); g 9.80665 m/s^2")
print(f"bore D                         {D * 1000:9.2f} mm")
print(f"flow Q                         {Q * 1e6:9.2f} cm^3/s")
print(f"mean speed V                   {V:9.4f} m/s")
print(f"1 laminar G, Poiseuille        {G1:9.2f} Pa/m")
print(f"2 laminar G, finite diff n=40  {G2:9.2f} Pa/m")
print(f"3 laminar G, energy balance    {G3:9.2f} Pa/m")
print(f"  flow error n=40, n=80        {abs(q40 * G1 - Q) / Q * 100:9.4f} {abs(q80 * G1 - Q) / Q * 100:9.4f} %")
print(f"  centre speed, fd and formula {u40[0] * G1:9.4f} {UMAX:9.4f} m/s")
print(f"  centre speed / mean speed    {UMAX / V:9.4f}")
print(f"  wall shear stress            {TAU_W:9.4f} Pa")
print(f"  laminar f = 64/Re, its G     {64 / RE * RHO * V * V / (2 * D):9.2f} Pa/m")
print(f"Reynolds number Re             {RE:9.0f}")
print(f"turbulent f, Blasius           {0.3164 * RE ** -0.25:9.5f}")
print(f"turbulent G, Blasius           {GT:9.2f} Pa/m")
print(f"turbulent G / laminar G        {GT / G1:9.2f}")
print(f"loop, laminar (wrong here)     {G1 * LOOP / 1000:9.2f} kPa {G1 * LOOP * Q:6.2f} W")
print(f"loop, turbulent                {GT * LOOP / 1000:9.2f} kPa {GT * LOOP * Q:6.2f} W")
print(f"  as head of water             {GT * LOOP / (RHO * 9.80665):9.2f} m")
q_crit = 2300 * MU * pi * D / (4 * RHO)
qs = 0.5 * LPM
print(f"laminar up to Re 2300          {q_crit / LPM:9.3f} L/min")
print(f"0.5 L/min: Re, G               {reynolds(qs):9.0f} {g_lam(qs):9.3f} Pa/m")
print(f"0.5 L/min: centre speed        {g_lam(qs) * R * R / (4 * MU):9.4f} m/s")
print(f"0.5 L/min: entry length 0.05ReD{0.05 * reynolds(qs) * D:9.2f} m")
# ---- what breaks ----
wrong_od = g_blasius(Q, 0.015) * LOOP / 1000
wrong_20 = g_blasius(Q, mu=MU20, rho=RHO20) * LOOP / 1000
print(f"wrong: laminar law at Re {RE:.0f}  {G1 * LOOP / 1000:9.2f} kPa")
print(f"wrong: 15 mm taken as the bore {wrong_od:9.2f} kPa")
print(f"wrong: 20 C water properties   {wrong_20:9.2f} kPa")
# ---- try changing ----
print(f"try: 0.5 L/min at 20 C, G      {g_lam(qs, mu=MU20):9.3f} Pa/m")
print(f"try: 20 C, laminar x, turb x   {MU20 / MU:9.3f} {wrong_20 / (GT * LOOP / 1000):9.3f}")
print(f"try: 22 mm pipe, loop          {g_blasius(Q, 0.022 - 2 * 0.0009) * LOOP / 1000:9.2f} kPa")
print(f"try: 6 L/min, loop             {g_blasius(6 * LPM) * LOOP / 1000:9.2f} kPa")
print(f"  power of flow, ln(G12/G6)/ln 2 {log(GT / g_blasius(6 * LPM)) / log(2):7.2f}")
# ---- chart: pressure per metre against flow ----
xs = [0, 2, 4, 6, 8, 10, 12]
print("chart, flow L/min     " + " ".join(f"{x:6d}" for x in xs))
print("chart, laminar Pa/m   " + " ".join(f"{g_lam(x * LPM):6.0f}" for x in xs))
print("chart, real Pa/m      " + " ".join(f"{g_real(x * LPM):6.0f}" for x in xs))
# ---- figure: 0.5 L/min profile, 20 px per mm across, 2000 px per m/s along ----
um = g_lam(qs) * R * R / (4 * MU)
pts = [(rr, um * (1 - (rr / (R * 1000)) ** 2)) for rr in (0.0, 2.0, 4.0, 6.0, 6.8)]
print("figure, r mm : u m/s  " + " ".join(f"{rr:.1f}:{v:.4f}" for rr, v in pts))
# ---- asserts against independent values ----
assert abs(G2 - G1) / G1 < 2e-3 and abs(G3 - G1) / G1 < 2e-3, "three roads agree"
assert 3.5 < (abs(q40 * G1 - Q)) / abs(q80 * G1 - Q) < 4.5, "error falls 4x: second order"
assert abs(u40[0] * G1 - UMAX) < 1e-9 and abs(u40[0] * pi * R * R / q40 - 2) < 2e-3, "fd centre = 2 x fd mean"
tau_fd = MU * G1 * (4 * u40[39] - u40[38]) / (2 * R / 40)          # fd wall slope (u_40 = 0)
assert abs(tau_fd - TAU_W) / TAU_W < 1e-9, "wall shear: fd against G R / 2"
assert 2300 < RE and 10 < GT / G1 < 20 and reynolds(qs) < 2300, "turbulent at 12 L/min, laminar at 0.5"
assert abs(64 / RE * RHO * V * V / (2 * D) - G1) / G1 < 1e-12, "f = 64/Re gives Poiseuille's G"
print("ALL CHECKS PASS")
