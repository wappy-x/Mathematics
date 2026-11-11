# Navier-Stokes and the Reynolds number -- the check behind the card.
# Standard library only. Water at 20 C, 1 m/s, in a 15 mm heating-loop pipe.
from math import pi, sin, cos, exp

RHO, MU = 998.207, 1.00160e-3        # water at 20 C, 1 atm: kg/m^3, Pa s (NIST WebBook)
RHO70, MU70 = 977.765, 0.403548e-3   # water at 70 C, 1 atm
D, U = 0.015, 1.0                    # pipe bore (m), mean speed (m/s)
NU = MU / RHO                        # kinematic viscosity, m^2/s

# ---- road 1: the Reynolds number from its formula, and as the ratio of two term sizes
re = U * D / NU
print(f"water 20 C: rho {RHO:.3f} kg/m^3, mu {MU * 1000:.5f} mPa s; 70 C: rho {RHO70:.3f}, mu {MU70 * 1000:.6f}")
print(f"pipe bore D {D * 1000:.1f} mm, mean speed U {U:.2f} m/s")
inertia = RHO * U * U / D            # size of rho (u.grad)u, N/m^3
viscous = MU * U / D ** 2            # size of mu lap(u), N/m^3
print(f"nu = mu/rho                 {NU * 1e6:.4f} x 1e-6 m^2/s")
print(f"Re = U D / nu               {re:.1f}")
print(f"inertia scale rho U^2/D     {inertia:.1f} N/m^3")
print(f"viscous scale mu U/D^2      {viscous:.4f} N/m^3")
print(f"ratio of the two scales     {inertia / viscous:.1f}")
print(f"pressure scale rho U^2      {RHO * U * U:.1f} Pa")
print(f"time scale D/U              {D / U * 1000:.1f} ms")
print(f"speed at Re 2300            {2300 * NU / D:.4f} m/s")
print(f"Re over the 2300 limit      {re / 2300:.2f} times")
print(f"real 15 mm copper, 13.6 mm bore: Re {U * 0.0136 / NU:.1f}")

# ---- road 2: a parcel through a 22 mm to 15 mm reducer, 20 mm long, steady flow
D_IN, LR = 0.022, 0.020
Q = U * pi * D * D / 4               # flow rate, m^3/s
def diam(x): return D_IN if x < 0 else (D if x > LR else D_IN + (D - D_IN) * x / LR)
def speed(x): return Q / (pi * diam(x) ** 2 / 4)
def rk4(x, dt):                      # follow the parcel: dx/dt = speed(x)
    k1 = speed(x); k2 = speed(x + dt * k1 / 2); k3 = speed(x + dt * k2 / 2); k4 = speed(x + dt * k3)
    return x + dt * (k1 + 2 * k2 + 2 * k3 + k4) / 6
xm = LR / 2
field_acc = speed(xm) * (-2 * speed(xm) / diam(xm)) * (D - D_IN) / LR   # Eulerian u du/dx
h = 1e-6
parcel_acc = (speed(rk4(xm, h)) - speed(rk4(xm, -h))) / (2 * h)          # Lagrangian du/dt
transit_formula = pi / (4 * Q) * LR * (D_IN ** 2 + D_IN * D + D * D) / 3
x, t, dt, dots, t_in, t_out = -0.010, 0.0, 1e-6, [], None, None
while x < 0.030:
    if round(t / dt) % 4000 == 0: dots.append(x)
    xn = rk4(x, dt)
    if x < 0 <= xn: t_in = t + dt * (0 - x) / (xn - x)
    if x < LR <= xn: t_out = t + dt * (LR - x) / (xn - x)
    x, t = xn, t + dt
u_in, u_out = speed(-1.0), speed(1.0)
print(f"reducer {D_IN * 1000:.0f} -> {D * 1000:.0f} mm over {LR * 1000:.0f} mm: in {u_in:.4f} m/s, out {u_out:.4f} m/s, flow {Q * 60000:.2f} L/min")
print(f"mid-reducer accel, field u du/dx    {field_acc:.4f} m/s^2")
print(f"mid-reducer accel, following parcel {parcel_acc:.4f} m/s^2")
print(f"exit accel {u_out * 2 * u_out / D * (D_IN - D) / LR:.2f} m/s^2 = {u_out * 2 * u_out / D * (D_IN - D) / LR / 9.80665:.2f} g")
print(f"transit time: formula {transit_formula * 1000:.4f} ms, tracked {(t_out - t_in) * 1000:.4f} ms")
print(f"mean accel in reducer {(u_out - u_in) / transit_formula:.2f} m/s^2")
print(f"pressure spent, rho (u_out^2 - u_in^2)/2   {RHO * (u_out ** 2 - u_in ** 2) / 2:.1f} Pa")

# ---- road 3: every term of Navier-Stokes, by finite differences, on an exact solution
def terms(k, keep_viscous=True, n=12):
    def f(x, y, t):                  # Taylor-Green vortex: velocity u, v and pressure p
        e = exp(-2 * NU * k * k * t)
        return (U * sin(k * x) * cos(k * y) * e, -U * cos(k * x) * sin(k * y) * e,
                RHO * U * U / 4 * (cos(2 * k * x) + cos(2 * k * y)) * e * e)
    hx, ht = 1e-4 / k, 1e-3
    big = [0.0] * 5                  # max |time|, |convective|, |pressure|, |viscous|, |residual|
    for i in range(n):
        for j in range(n):
            x, y = i * pi / k / n, j * pi / k / n
            u, v, _ = f(x, y, 0)
            dudt = (f(x, y, ht)[0] - f(x, y, -ht)[0]) / (2 * ht)
            dudx = (f(x + hx, y, 0)[0] - f(x - hx, y, 0)[0]) / (2 * hx)
            dudy = (f(x, y + hx, 0)[0] - f(x, y - hx, 0)[0]) / (2 * hx)
            dpdx = (f(x + hx, y, 0)[2] - f(x - hx, y, 0)[2]) / (2 * hx)
            lap = (f(x + hx, y, 0)[0] + f(x - hx, y, 0)[0] + f(x, y + hx, 0)[0]
                   + f(x, y - hx, 0)[0] - 4 * u) / hx ** 2
            parts = [RHO * dudt, RHO * (u * dudx + v * dudy), -dpdx, MU * lap]
            res = parts[0] + parts[1] - parts[2] - (parts[3] if keep_viscous else 0.0)
            big = [max(b, abs(p)) for b, p in zip(big, parts + [res])]
    return big
K = pi / D                           # one eddy fills the 15 mm bore
tg = terms(K)
tg_drop = terms(K, keep_viscous=False)
names = ["rho du/dt", "rho (u.grad)u", "-dp/dx", "mu lap u", "residual"]
for nm, val in zip(names, tg):
    print(f"eddy term {nm:<15} {val:12.3f} N/m^3")
print(f"residual with viscous term dropped  {tg_drop[4]:.4f} N/m^3")
print(f"convective / viscous, measured {tg[1] / tg[3]:.1f}; Re/(4 pi) {re / (4 * pi):.1f}")
print(f"eddy decay time 1/(2 nu k^2)   {1 / (2 * NU * K * K):.2f} s")

# ---- what breaks
blasius_f = 0.3164 / re ** 0.25
g_turb = blasius_f * RHO * U * U / (2 * D)
g_lam = 32 * MU * U / D ** 2
re_70 = U * D * RHO70 / MU70
g_euler = RHO * speed(0.025) * (speed(0.026) - speed(0.025)) / 0.001   # no viscosity: -dp/dx = rho u du/dx
print(f"wrong: mu for nu, Re = U D / mu    {U * D / MU:.2f}")
print(f"wrong: radius for diameter         {U * D / 2 / NU:.1f}")
print(f"  at 0.2 m/s: radius {0.2 * D / 2 / NU:.1f}, diameter {0.2 * D / NU:.1f}")
print(f"wrong: cold nu in the 70 C loop    {re:.1f}; right {re_70:.1f}")
print(f"wrong: drop viscosity, straight pipe needs {g_euler:.1f} Pa/m; Blasius {g_turb:.1f} Pa/m")
print(f"wrong: laminar 32 mu U/D^2         {g_lam:.1f} Pa/m ({g_turb / g_lam:.2f} times too low)")
print(f"Blasius friction factor f          {blasius_f:.5f}")
print(f"20 m of pipe: turbulent {20 * g_turb / 1000:.2f} kPa, laminar formula {20 * g_lam / 1000:.2f} kPa")
print(f"try: U = 0.15 m/s, Re {0.15 * D / NU:.1f}")
print(f"try: 22 mm pipe, same flow, U {Q / (pi * D_IN ** 2 / 4):.4f} m/s, Re {4 * Q / (pi * D_IN * NU):.1f}")
small = terms(10 * K)
print(f"try: 1.5 mm eddy, convective / viscous {small[1] / small[3]:.1f}")
print("figure, parcel x (mm) every 4 ms: " + " ".join(f"{d * 1000:.1f}" for d in dots))

assert 14900 < re < 15000, "the spec's example: Reynolds about 15000"
assert abs(parcel_acc / field_acc - 1) < 1e-6, "following the parcel must equal u du/dx"
assert abs((t_out - t_in) / transit_formula - 1) < 1e-6, "tracked transit time vs the integral"
assert tg[4] < 1e-4 * tg[3], "the assembled equation must balance on the exact flow"
assert tg_drop[4] > 0.99 * tg[3], "dropping viscosity must leave the viscous term unbalanced"
assert abs(tg[1] / tg[3] / (re / (4 * pi)) - 1) < 1e-4, "measured term ratio vs Re/(4 pi)"
assert re > 2300 and g_turb > 5 * g_lam, "turbulent pipe must cost far more than laminar"
print("ALL CHECKS PASS")
