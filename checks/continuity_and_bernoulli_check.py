# Continuity and Bernoulli -- the check behind the card.  Standard library only.
# A heating pipe narrows from 22 mm to 15 mm bore through a 20 mm taper; hot water
# flows at 0.25 L/s.  Roads to the throat pressure: (1) continuity + Bernoulli in
# closed form; (2) Newton's law on thin slices, rho v dv/dx integrated along the
# taper by Simpson's rule; (3) one parcel followed in time by RK4, force = mass x
# its own acceleration; (4) the venturi formula run backwards to recover the flow.
from math import pi, cos, sin, sqrt

RHO = 977.764        # kg/m^3, water at 70 C and 1 bar, NIST Chemistry WebBook
MU = 0.000403548     # Pa s, same source
G = 9.80665          # m/s^2, standard gravity, NIST
Q = 0.25e-3          # m^3/s, 0.25 L/s
D1, D2, L = 0.022, 0.015, 0.020      # bores and taper length, m
P1 = 150000.0        # Pa, gauge, in the 22 mm pipe

def area(d): return pi * d * d / 4.0
def smooth(x, L):    # taper bore at x and its slope dD/dx: a cosine blend from D1 to D2
    xi = min(max(x / L, 0.0), 1.0)
    return D1 + (D2 - D1) * (0.5 - 0.5 * cos(pi * xi)), (D2 - D1) * 0.5 * pi / L * sin(pi * xi)
def cone(x, L):
    xi = min(max(x / L, 0.0), 1.0)
    return D1 + (D2 - D1) * xi, (D2 - D1) / L
def speed(x, shape, L): return Q / area(shape(x, L)[0])

# road 1: closed form
A1, A2 = area(D1), area(D2)
v1, v2 = Q / A1, Q / A2
dp = 0.5 * RHO * (v2 * v2 - v1 * v1)
p2 = P1 - dp

# road 2: dp/dx = -rho v dv/dx, with dv/dx = -Q A'(x)/A^2 from the bore's slope
def euler_drop(shape, L, n=2000):
    def f(x):
        d, dd = shape(x, L)
        a, da = area(d), pi * d * dd / 2.0
        v = Q / a
        return RHO * v * (-Q * da / (a * a))
    h = L / n
    s = f(0.0) + f(L) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))
    return s * h / 3.0

# road 3: follow one parcel through the taper in time, adding up rho * a * dx
def parcel(shape, L, dt=1e-5):
    x, t, drop, amax = 0.0, 0.0, 0.0, 0.0
    while x < L:
        k1 = speed(x, shape, L); k2 = speed(x + dt * k1 / 2, shape, L)
        k3 = speed(x + dt * k2 / 2, shape, L); k4 = speed(x + dt * k3, shape, L)
        xn = x + dt * (k1 + 2 * k2 + 2 * k3 + k4) / 6.0
        a = (speed(xn, shape, L) - speed(x, shape, L)) / dt
        drop += RHO * a * (xn - x); amax = max(amax, a)
        x, t = xn, t + dt
    return drop, t, amax

dp_smooth, dp_cone = euler_drop(smooth, L), euler_drop(cone, L)
dp_parcel, t_pass, a_max = parcel(smooth, L)
Dm, dD = (D1 + D2) / 2.0, D2 - D1      # continuity alone: transit time = taper volume / flow
t_vol = pi / 4.0 * (Dm * Dm + dD * dD / 8.0) * L / Q
# road 4: a venturi meter reading dp recovers the flow
Q_back = A2 * sqrt(2.0 * dp / (RHO * (1.0 - (A2 / A1) ** 2)))
re2 = RHO * v2 * D2 / MU

# what breaks
v2_diam = v1 * D1 / D2
dp_diam = 0.5 * RHO * (v2_diam ** 2 - v1 ** 2)
dp_no_half = RHO * (v2 * v2 - v1 * v1)
dp_no_inlet = 0.5 * RHO * v2 * v2
rise_ideal = dp                                   # Bernoulli through a sudden widening back to 22 mm
rise_momentum = RHO * v1 * (v2 - v1)              # momentum balance on the widening
loss_bc = 0.5 * RHO * (v2 - v1) ** 2              # Borda-Carnot loss
dp_rho1000 = 0.5 * 1000.0 * (v2 * v2 - v1 * v1)

# try changing
dp_double = 0.5 * RHO * ((2 * v2) ** 2 - (2 * v1) ** 2)
climb = RHO * G * 2.5
dp_short, t_short, a_short = parcel(smooth, 0.005, dt=2.5e-6)
v10 = Q / area(0.010)
dp_10 = 0.5 * RHO * (v10 * v10 - v1 * v1)
# real copper is sized by its outside: walls 0.9 and 0.7 mm leave bores of 20.2 and 13.6 mm
D1r, D2r = D1 - 2 * 0.0009, D2 - 2 * 0.0007
v1r, v2r = Q / area(D1r), Q / area(D2r)
dp_real = 0.5 * RHO * (v2r * v2r - v1r * v1r)

rows = [
    ("area 22 mm bore (mm^2)", A1 * 1e6), ("area 15 mm bore (mm^2)", A2 * 1e6),
    ("area ratio A1/A2", A1 / A2), ("v1 in 22 mm (m/s)", v1), ("v2 in 15 mm (m/s)", v2),
    ("mass flow in (kg/s)", RHO * A1 * v1), ("mass flow out (kg/s)", RHO * A2 * v2),
    ("kinetic term 1/2 rho v1^2 (Pa)", 0.5 * RHO * v1 * v1),
    ("kinetic term 1/2 rho v2^2 (Pa)", 0.5 * RHO * v2 * v2),
    ("1 closed form drop (Pa)", dp), ("  throat pressure p2 (Pa)", p2),
    ("2 slices, smooth taper (Pa)", dp_smooth), ("2 slices, straight cone (Pa)", dp_cone),
    ("3 parcel in time (Pa)", dp_parcel), ("  parcel transit time (ms)", t_pass * 1e3),
    ("  taper volume / flow (ms)", t_vol * 1e3),
    ("  parcel peak acceleration (m/s^2)", a_max),
    ("4 flow recovered from drop (L/s)", Q_back * 1e3),
    ("Reynolds number in 15 mm", re2), ("drop in metres of water (m)", dp / (RHO * G)),
    ("wrong: diameter ratio, v2 (m/s)", v2_diam), ("wrong: diameter ratio, drop (Pa)", dp_diam),
    ("wrong: no 1/2 (Pa)", dp_no_half), ("wrong: inlet speed ignored (Pa)", dp_no_inlet),
    ("wrong: rho = 1000 (Pa)", dp_rho1000),
    ("widening: Bernoulli rise (Pa)", rise_ideal), ("widening: momentum rise (Pa)", rise_momentum),
    ("widening: Borda-Carnot loss (Pa)", loss_bc),
    ("try: flow 0.5 L/s, drop (Pa)", dp_double), ("try: climb 2.5 m (Pa)", climb),
    ("try: 5 mm taper, drop (Pa)", dp_short), ("try: 5 mm taper, transit (ms)", t_short * 1e3),
    ("try: 5 mm taper, peak accel (m/s^2)", a_short),
    ("try: 10 mm bore, v (m/s)", v10), ("try: 10 mm bore, drop (Pa)", dp_10),
]
print(f"inputs: water 70 C, rho {RHO:.3f} kg/m^3, mu {MU:.9f} Pa s, g {G:.5f} m/s^2, p1 {P1:.0f} Pa = {P1 / 1e5:.1f} bar")
for name, v in rows:
    print(f"{name:<38} {v:>14.4f}")
print(f"real bores {D1r * 1e3:.1f} and {D2r * 1e3:.1f} mm: v1 {v1r:.3f} m/s, v2 {v2r:.3f} m/s, drop {dp_real:.1f} Pa, {dp_real / dp:.2f} x")

print()
xs = [0.0025 * i for i in range(9)]
print("chart, x along taper (mm)    " + " ".join(f"{x * 1e3:6.1f}" for x in xs))
print("chart, bore (mm)             " + " ".join(f"{smooth(x, L)[0] * 1e3:6.2f}" for x in xs))
print("chart, speed (m/s)           " + " ".join(f"{speed(x, smooth, L):6.3f}" for x in xs))
print("chart, drop below p1 (Pa)    " + " ".join(f"{0.5 * RHO * (speed(x, smooth, L) ** 2 - v1 * v1):6.1f}" for x in xs))
print(f"figure, half-bores {D1 * 500:.1f} and {D2 * 500:.1f} mm, taper {L * 1e3:.1f} mm, arrows {v1:.3f} and {v2:.3f} m/s")

assert abs(t_pass - t_vol) < 2e-5,                 "continuity: transit time = volume / flow"
assert abs(dp_smooth - dp) < 1e-6,                 "slice road vs closed form"
assert abs(dp_cone - dp) < 1e-6,                   "a different taper shape, same drop"
assert abs(dp_parcel - dp) < 0.5,                  "parcel road within 0.5 Pa"
assert abs(Q_back - Q) < 1e-12,                    "venturi run backwards gives the flow"
assert abs((rise_ideal - loss_bc) - rise_momentum) < 1e-9, "momentum rise = Bernoulli rise - loss"
assert abs(dp_short - dp) < 0.5,                   "taper length does not change the drop"
print("ALL CHECKS PASS")
