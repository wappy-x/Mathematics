# Final value and bandwidth -- the check behind the card.  Standard library only.
# A car on cruise control, throttle u (0 to 1) in, road speed v (m/s) out:
#   m dv/dt = F u - b v,  so  G(s) = K / (tau s + 1),  K = F/b,  tau = m/b.
# Steady gain by four roads: G(0); s Y(s) as s shrinks; an RK4 run; the impulse
# response's area.  Bandwidth by three: 1/tau; bisection on |G(jw)|; a simulated wiggle.
import math

m, b, F, u0 = 1500.0, 60.0, 1500.0, 0.8           # kg, N s/m, N per unit throttle, step
K, tau, tau_a = F / b, m / b, 2.0                   # m/s per unit, s, actuator lag in s

def G(s, lags=(tau,)):                              # the transfer function, complex s
    out = complex(K)
    for T in lags:
        out /= T * s + 1
    return out

def rk4(f, x, t_end, dt, u):                        # RK4 on a list state, input u(t)
    t, xs = 0.0, [(0.0, x[0])]
    while t < t_end - 1e-9:
        k1 = f(x, u(t)); x2 = [a + dt / 2 * k for a, k in zip(x, k1)]
        k2 = f(x2, u(t + dt / 2)); x3 = [a + dt / 2 * k for a, k in zip(x, k2)]
        k3 = f(x3, u(t + dt / 2)); x4 = [a + dt * k for a, k in zip(x, k3)]
        k4 = f(x4, u(t + dt))
        x = [a + dt / 6 * (p + 2 * q + 2 * r + w) for a, p, q, r, w in zip(x, k1, k2, k3, k4)]
        t += dt
        xs.append((t, x[0]))
    return xs

car = lambda x, u: [(F * u - b * x[0]) / m]
car_lag = lambda x, u: [(F * x[1] - b * x[0]) / m, (u - x[1]) / tau_a]   # x[1]: throttle reached
wrong_sign = lambda x, u: [(K * u + x[0]) / tau]                         # G = K/(tau s - 1)

def bisect(f, lo, hi):                              # f(lo) > 0 > f(hi)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) > 0 else (lo, mid)
    return 0.5 * (lo + hi)

def simpson(f, a, c, n):
    h = (c - a) / n
    return h / 3 * (f(a) + f(c) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def cross(xs, level):                               # first time the record passes level
    for (t1, v1), (t2, v2) in zip(xs, xs[1:]):
        if v1 < level <= v2:
            return t1 + (level - v1) / (v2 - v1) * (t2 - t1)

# ---- steady gain: four roads ----
dc = G(0).real
step = rk4(car, [0.0], 300.0, 0.1, lambda t: u0)
area = simpson(lambda t: K / tau * math.exp(-t / tau), 0.0, 1000.0, 20000)
print(f"inputs: m = {m:.0f} kg, b = {b:.0f} N s/m, F = {F:.0f} N per unit throttle, actuator lag {tau_a} s")
print(f"model: K = F/b = {K:.1f} m/s per unit throttle, tau = m/b = {tau:.1f} s, step u0 = {u0}")
print(f"road 1  G(0) x u0                 {dc * u0:10.5f} m/s = {dc * u0 * 3.6:.1f} km/h")
for s in (0.1, 0.01, 0.001, 1e-6):
    print(f"road 2  s Y(s) at s = {s:<9g}   {(s * G(s) * u0 / s).real:10.5f} m/s")
print(f"road 3  RK4 speed at t = 300 s    {step[-1][1]:10.5f} m/s")
print(f"        exact 20(1 - e^-12)       {K * u0 * (1 - math.exp(-300 / tau)):10.5f} m/s")
print(f"road 4  area of impulse response  {area:10.5f} m/s per unit")
print("chart, step at t (s) " + " ".join(f"{t:6.0f}" for t, v in step[::250][:7]))
print("chart, speed (m/s)   " + " ".join(f"{v:6.2f}" for t, v in step[::250][:7]))

# ---- bandwidth: three roads ----
wb_form = 1 / tau
wb_bis = bisect(lambda w: abs(G(1j * w)) - dc / math.sqrt(2), 1e-6, 10.0)
wig = 0.1
sim = rk4(car, [0.0], 40 * math.pi / wb_form, 0.05, lambda t: wig * math.sin(wb_form * t))
tail = [v for t, v in sim if t > 30 * math.pi / wb_form]
amp = 0.5 * (max(tail) - min(tail))
print(f"bandwidth 1/tau                   {wb_form:10.5f} rad/s = {wb_form / (2 * math.pi):.6f} Hz")
print(f"bandwidth, bisection on |G(jw)|   {wb_bis:10.5f} rad/s")
print(f"wiggle 0.1 at 0.04 rad/s: speed swing +-{amp:.4f} m/s, ratio to DC {amp / (dc * wig):.4f}")
print(f"  1/sqrt(2) = {1 / math.sqrt(2):.4f}; phase at w_b {math.degrees(math.atan2(G(1j * wb_form).imag, G(1j * wb_form).real)):.1f} deg")
print(f"period at bandwidth 2 pi/w_b      {2 * math.pi / wb_form:10.2f} s")
for w in (0.004, 0.01, 0.02, 0.04, 0.1, 0.2, 0.4):
    print(f"chart, w = {w:<5} rad/s  gain {abs(G(1j * w)):8.4f} m/s per unit  {20 * math.log10(abs(G(1j * w))):6.2f} dB")
w10 = 2 * math.pi / 10
print(f"10 s throttle wiggle: gain {abs(G(1j * w10)):.4f} m/s per unit throttle")
t10, t90 = cross(step, 0.1 * K * u0), cross(step, 0.9 * K * u0)
print(f"rise 10-90 by simulation          {t90 - t10:10.3f} s;  tau ln 9 = {tau * math.log(9):.3f} s")
print(f"bandwidth x rise time             {wb_form * (t90 - t10):10.4f};  ln 9 = {math.log(9):.4f}")

# ---- a second lag: the 2 s actuator ----
two = (tau, tau_a)
A, B = tau ** 2 * tau_a ** 2, tau ** 2 + tau_a ** 2
wb2_form = math.sqrt((-B + math.sqrt(B * B + 4 * A)) / (2 * A))
wb2_bis = bisect(lambda w: abs(G(1j * w, two)) - G(0, two).real / math.sqrt(2), 1e-6, 10.0)
step2 = rk4(car_lag, [0.0, 0.0], 300.0, 0.1, lambda t: u0)
print(f"with 2 s actuator: G(0) u0 = {G(0, two).real * u0:.5f} m/s, RK4 at 300 s = {step2[-1][1]:.5f} m/s")
print(f"  bandwidth: quadratic {wb2_form:.6f} rad/s, bisection {wb2_bis:.6f} rad/s")

# ---- what breaks ----
bad = rk4(wrong_sign, [0.0], 100.0, 0.1, lambda t: u0)
fvt_bad = (K / (tau * 1e-9 - 1) * u0).real
print(f"wrong-sign loop: FVT says {fvt_bad:.3f} m/s; RK4 at 100 s {bad[-1][1]:.2f} m/s; exact {K * u0 * (math.exp(100 / tau) - 1):.2f} m/s")
sy = 1e-6 * G(1e-6) * wig * wb_form / (1e-12 + wb_form ** 2)   # s Y(s), Y = G(s) x transform of the wiggle
print(f"wiggle forever: s Y(s) at s = 1e-6 is {abs(sy):.6f} m/s; the swing stays +-{amp:.4f} m/s")
sat = rk4(car, [0.0], 300.0, 0.1, lambda t: min(30.0 / K, 1.0))
print(f"ask 30 m/s: linear FVT {30.0:.2f} m/s needs u = {30.0 / K:.2f}; clamped at 1.0 it settles at {sat[-1][1]:.3f} m/s")
print(f"half the gain (-6 dB) instead of -3 dB: w = sqrt(3)/tau = {math.sqrt(3) / tau:.5f} rad/s")
print(f"0.04 read as Hz: {2 * math.pi * 0.04:.5f} rad/s, 6.28 times too fast")

wb_heavy = bisect(lambda w: abs(G(1j * w, (2 * m / b,))) - dc / math.sqrt(2), 1e-6, 10.0)
wb_slow = bisect(lambda w: abs(G(1j * w, (tau, tau))) - dc / math.sqrt(2), 1e-6, 10.0)
print(f"try: m = 3000 kg: G(0) u0 still {dc * u0:.5f} m/s, bandwidth {wb_heavy:.5f} rad/s")
print(f"try: actuator lag 25 s: bandwidth {wb_slow:.6f} rad/s")

assert abs(step[-1][1] - dc * u0) < 1e-3                      # simulation vs transform at s = 0
assert abs(area - dc) < 1e-6                                   # impulse-response area vs G(0)
assert abs(wb_bis - wb_form) < 1e-9                            # bisection vs 1/tau
assert abs(amp / (dc * wig) - 1 / math.sqrt(2)) < 1e-3         # simulated wiggle vs -3 dB
assert abs(t90 - t10 - tau * math.log(9)) < 0.05               # simulated rise vs tau ln 9
assert abs(wb2_bis - wb2_form) < 1e-9                          # bisection vs the quadratic
assert abs(step2[-1][1] - G(0, two).real * u0) < 1e-3          # two-state RK4 vs G(0)
assert abs(bad[-1][1] / (K * u0 * (math.exp(100 / tau) - 1)) - 1) < 1e-6   # unstable run vs e^(t/tau)
print("ALL CHECKS PASS")
