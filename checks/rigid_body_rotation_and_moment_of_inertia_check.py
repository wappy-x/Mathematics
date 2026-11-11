# Rotation and moment of inertia -- the check behind the card.  Standard library only.
# A 12 kg solid disc flywheel, 0.15 m radius, spun to 3000 rpm.  Roads to each answer:
# the closed form, a ring-by-ring sum, a brute-force box sum, and RK4 simulations.
from math import pi, sqrt, sin, log, exp

m, R, h = 12.0, 0.15, 0.0216            # mass kg, radius m, thickness m
rpm = 3000.0
w = rpm * 2 * pi / 60                   # angular speed, rad/s
g = 9.80665                             # standard gravity, m/s^2 (NIST)
d = 0.12                                # pivot pin, m from the centre
rho = m / (pi * R * R * h)              # uniform density, kg/m^3

I = 0.5 * m * R * R                     # road 1: the closed form
I_rings = 0.0                           # road 2: thin rings, midpoint rule
n = 1000
for k in range(n):
    r = (k + 0.5) * R / n
    I_rings += r * r * rho * h * 2 * pi * r * (R / n)

def box_sum(n):                         # road 3: boxes over x, y and z
    s, nz = 2 * R / n, 4
    dm = rho * s * s * (h / nz)
    M = Ic = Ip = Qx = 0.0
    for i in range(n):
        x = -R + (i + 0.5) * s
        for j in range(n):
            y = -R + (j + 0.5) * s
            if x * x + y * y <= R * R:
                for _ in range(nz):
                    M += dm; Qx += x * dm
                    Ic += (x * x + y * y) * dm
                    Ip += ((x - d) * (x - d) + y * y) * dm
    return M, Ic, Ip, Qx

L = I * w
E = 0.5 * I * w * w
Ip = I + m * d * d                      # parallel-axis theorem

def spin(tau0, w0, dt=0.001):           # RK4 on dw/dt = tau/I, work dW/dt = tau*w
    f = lambda om: tau0 * (1 - om / w0) / I
    t, om, W, pts = 0.0, 0.0, 0.0, []
    while True:
        if abs(t - round(t)) < 1e-9: pts.append(om * 60 / (2 * pi))
        k1 = f(om); k2 = f(om + dt / 2 * k1); k3 = f(om + dt / 2 * k2); k4 = f(om + dt * k3)
        new = om + dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        dW = dt / 6 * (I * k1 * om + 2 * I * k2 * (om + dt / 2 * k1)
                       + 2 * I * k3 * (om + dt / 2 * k2) + I * k4 * (om + dt * k3))
        if new >= w:                    # hit 3000 rpm inside this step: take that part
            frac = (w - om) / (new - om)
            return t + frac * dt, W + frac * dW, pts
        t, om, W = t + dt, new, W + dW

def swing(theta0_deg, dt=1e-4):        # RK4 pendulum about the pin; returns the period
    k = m * g * d / Ip
    th, om, t = theta0_deg * pi / 180, 0.0, 0.0
    while True:
        a1, v1 = -k * sin(th), om
        a2, v2 = -k * sin(th + dt / 2 * v1), om + dt / 2 * a1
        a3, v3 = -k * sin(th + dt / 2 * v2), om + dt / 2 * a2
        a4, v4 = -k * sin(th + dt * v3), om + dt * a3
        nth = th + dt / 6 * (v1 + 2 * v2 + 2 * v3 + v4)
        if nth <= 0:                    # first pass through the bottom: a quarter swing
            return 4 * (t + dt * th / (th - nth))
        om += dt / 6 * (a1 + 2 * a2 + 2 * a3 + a4); th = nth; t += dt

def clutch(tf, dt=1e-4):                # flywheel grabs an identical still disc
    w1, w2, t, heat = w, 0.0, 0.0, 0.0
    while True:
        step = min(dt, (w1 - w2) / (2 * tf / I))
        slip0 = w1 - w2
        w1 -= tf / I * step; w2 += tf / I * step
        heat += tf * (slip0 + (w1 - w2)) / 2 * step; t += step
        if w1 - w2 <= 1e-12: return t, w1, w2, heat

print(f"flywheel: m {m:.0f} kg, R {R:.3f} m, thickness {h:.4f} m, density {rho:.0f} kg/m^3, {rpm:.0f} rpm = {w:.3f} rad/s")
print(f"I closed form 1/2 m R^2        {I:.6f} kg m^2")
print(f"I 1000 thin rings              {I_rings:.6f} kg m^2")
for nb in (30, 60, 150, 300):
    M, Ic_b, Ip_b, Qx = box_sum(nb)
    print(f"I boxes of side {2000 * R / nb:4.1f} mm        {Ic_b:.6f} kg m^2 (mass {M:.4f} kg)")
print(f"I about pin, boxes 1 mm        {Ip_b:.6f} kg m^2; I + m d^2 = {Ip:.6f}")
print(f"first moment about centre      {Qx:.6f} kg m")
print(f"L = I w {L:.3f} kg m^2/s;  E = I w^2/2 {E:.1f} J = {E / 3600:.3f} Wh")
t5 = L / 5.0
print(f"5 N m constant: alpha {5.0 / I:.3f} rad/s^2, t = L/tau {t5:.3f} s, turns {0.5 * w * t5 / (2 * pi):.1f}, work {5.0 * 0.5 * w * t5:.1f} J")
ts, Ws, pc = spin(5.0, float('inf'))
w0 = 4000 * 2 * pi / 60
tc = I * w0 / 10.0
t_exact = -tc * log(1 - w / w0)
tm, Wm, pm = spin(10.0, w0)
print(f"RK4 constant: t {ts:.3f} s, work {Ws:.1f} J")
print(f"real motor (10 N m stall, 4000 rpm free): time constant {tc:.3f} s, t {t_exact:.3f} s, RK4 t {tm:.3f} s, work {Wm:.1f} J")
print(f"real motor: average torque L/t {L / t_exact:.2f} N m; above 5 N m until {tc * log(2):.2f} s, below after")
for s in (0.0, 2.0, 4.0, 6.0, t_exact):
    om = w0 * (1 - exp(-s / tc))
    print(f"story t {s:.2f} s: {om * 60 / (2 * pi):6.0f} rpm, torque {10.0 * (1 - om / w0):5.2f} N m, L {I * om:6.2f} kg m^2/s")
cap = lambda p: [min(rpm, x) for x in p] + [rpm] * (11 - len(p))
print("chart, t s         " + " ".join(f"{s:5d}" for s in range(11)))
print("chart, 5 N m rpm   " + " ".join(f"{x:5.0f}" for x in cap(pc)))
print("chart, motor rpm   " + " ".join(f"{x:5.0f}" for x in cap(pm)))
T0 = 2 * pi * sqrt(Ip / (m * g * d))
T5, T60 = swing(5.0), swing(60.0)
Ic_60 = m * g * d * (T60 / (2 * pi)) ** 2 - m * d * d
print(f"swing on pin: formula {T0:.4f} s, RK4 5 deg {T5:.4f} s, RK4 60 deg {T60:.4f} s")
print(f"I from a 60 deg swing {Ic_60:.4f} kg m^2 ({100 * (Ic_60 / I - 1):.1f}% high)")
tl, w1, w2, heat = clutch(20.0)
print(f"clutch 20 N m: locks {tl:.4f} s at {w1 * 60 / (2 * pi):.1f} rpm, heat {heat:.1f} J")
# what breaks
print(f"break, rpm used as rad/s: E {0.5 * I * rpm * rpm:.0f} J")
print(f"break, all mass at rim m R^2: I {m * R * R:.3f}, t {m * R * R * w / 5.0:.2f} s, E {0.5 * m * R * R * w * w:.0f} J")
print(f"break, diameter for radius: I {0.5 * m * (2 * R) ** 2:.3f} kg m^2")
print(f"break, swing period with I not I_P: {2 * pi * sqrt(I / (m * g * d)):.4f} s")
print(f"break, clutch by energy: {rpm / sqrt(2):.1f} rpm")
t40, _, _, heat40 = clutch(40.0)
print(f"try, 6000 rpm: L {2 * L:.3f} kg m^2/s, E {0.5 * I * (2 * w) ** 2:.1f} J; clutch 40 N m: locks {t40:.4f} s, heat {heat40:.1f} J")
print("figure, scale 2000 per m, centre (380,330), rim r 300, ring r 180 width 20, pin (620,330)")

assert abs(I_rings - I) < 1e-6                           # ring sum agrees with 1/2 m R^2
assert abs(Ic_b - I) / I < 2e-3                          # box sum at 1 mm agrees
assert abs(Ip_b - (Ic_b + M * d * d)) < 1e-9 * Ip        # shift of axes, box by box
assert abs(Ip_b - Ip) / Ip < 2e-3
assert abs(ts - t5) < 1e-6 and abs(Ws - E) < 1e-6 * E    # tau = dL/dt; work = energy
assert abs(tm - t_exact) < 1e-4 and abs(Wm - E) < 1e-6 * E
assert abs(T5 - T0) / T0 < 1e-3 and T60 > 1.05 * T0      # small swing obeys formula; big does not
assert abs(w1 - w / 2) < 1e-6 and abs(heat - E / 2) < 1e-6 * E   # L kept, half the energy lost
print("ALL CHECKS PASS")
