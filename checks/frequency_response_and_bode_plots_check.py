# Bode plots -- the check behind the card.  Standard library only.
# A car on cruise control: throttle (%) in, road speed (m/s) out, small changes
# about a steady cruise.  G(s) = K / ((tau1 s + 1)(tau2 s + 1)) with K = 1 (m/s)/%,
# tau1 = 10 s (the car's mass against its drag), tau2 = 0.5 s (the engine's lag).
# Three roads to the gain and phase at each angular frequency w (rad/s):
#   1. closed form, factor by factor;  2. complex arithmetic on the expanded
#   polynomial at s = jw;  3. simulate the car with RK4, wobble the throttle,
#   and measure the settled speed wobble.  A fourth line is the asymptote sketch.
from math import sqrt, atan, atan2, log10, sin, cos, pi, degrees, ceil

K, T1, T2 = 1.0, 10.0, 0.5

def db(g): return 20 * log10(g)

def road1(w, t1=T1, t2=T2, delay=0.0):         # one factor at a time: gains multiply, phases add
    g = K / sqrt(1 + (w * t1) ** 2) / sqrt(1 + (w * t2) ** 2)
    return g, degrees(-atan(w * t1) - atan(w * t2) - w * delay)

def road2(w, den=(T1 * T2, T1 + T2, 1.0)):      # Horner on the denominator, here tau1 tau2 s^2 + (tau1 + tau2) s + 1
    v = 0j
    for c in den:
        v = v * complex(0, w) + c
    g = K / v
    return abs(g), degrees(atan2(g.imag, g.real))

def sketch(w, corners=(1 / T1, 1 / T2)):        # straight lines: 0 then -20 dB/decade per pole;
    m = p = 0.0                                 # phase 0, then -45 deg/decade for two decades, then -90
    for c in corners:
        if w > c: m -= 20 * log10(w / c)
        r = log10(w / c)
        p -= 0.0 if r <= -1 else (90.0 if r >= 1 else 45.0 * (r + 1))
    return m + db(K), p

def run(w, dt, steps, a1=1.0, delay=0.0, every=0):
    # tau2 f' = -f + u(t - delay);  tau1 v' = -a1 v + K f.  a1 = -1 makes the car's pole unstable.
    def rhs(t, f, v):
        u = sin(w * (t - delay)) if t >= delay else 0.0
        return (-f + u) / T2, (-a1 * v + K * f) / T1
    f = v = 0.0; vs = []
    for k in range(steps):
        t = k * dt
        vs.append(v)
        k1 = rhs(t, f, v)
        k2 = rhs(t + dt / 2, f + dt / 2 * k1[0], v + dt / 2 * k1[1])
        k3 = rhs(t + dt / 2, f + dt / 2 * k2[0], v + dt / 2 * k2[1])
        k4 = rhs(t + dt, f + dt * k3[0], v + dt * k3[1])
        f += dt / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        v += dt / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    vs.append(v)
    return vs

def road3(w, delay=0.0):                        # settle at least 150 s, then project one period on sin and cos
    period = 2 * pi / w
    n = max(200, ceil(period / 0.01)); dt = period / n
    settle = ceil(150 / period) * n
    vs = run(w, dt, settle + n, delay=delay)[settle:settle + n]
    a = 2 / n * sum(y * sin(w * (settle + k) * dt) for k, y in enumerate(vs))
    b = 2 / n * sum(y * cos(w * (settle + k) * dt) for k, y in enumerate(vs))
    return sqrt(a * a + b * b), degrees(atan2(b, a))

print("car: K = 1 (m/s)/%, tau1 = 10 s, tau2 = 0.5 s; corners 1/tau1 = 0.1 rad/s, 1/tau2 = 2 rad/s")
print("road 1 = closed form, road 2 = complex arithmetic, road 3 = RK4 simulation; sketch = asymptotes")
print("  w rad/s    f Hz  period s |  |G| road1  road2  road3 |   dB    sketch | phase deg road1  road2  road3  sketch")
for w in (0.01, 0.1, 0.5, 1.0, 2.0, 10.0):
    g1, p1 = road1(w); g2, p2 = road2(w); g3, p3 = road3(w); sm, sp = sketch(w)
    print(f"{w:9.2f} {w / (2 * pi):7.4f} {2 * pi / w:9.2f} | {g1:11.4f} {g2:6.4f} {g3:6.4f} | {db(g1):7.2f} {sm:7.2f} |"
          f" {p1:15.2f} {p2:6.2f} {p3:6.2f} {sp:7.2f}")
    assert abs(g1 - g2) < 1e-12                                  # two algebraic roads, gain
    assert abs(p1 - p2) < 1e-9                                   # and phase
    assert abs(g3 - g1) < 2e-4 * max(g1, 0.01)                   # the simulated car agrees, gain
    assert abs(p3 - p1) < 0.05                                   # and phase
g, p = road1(0.1)
print(f"at 0.1 rad/s: 1% throttle wobble -> speed wobble {g:.4f} m/s, lag {-p:.2f} deg = {-p / degrees(0.1):.2f} s")
g, p = road1(1.0)
print(f"at 1 rad/s:   1% throttle wobble -> speed wobble {g:.4f} m/s, lag {-p:.2f} deg = {-p / degrees(1.0):.2f} s")
print(f"hand, w = 1: factor 1 {db(1 / sqrt(101)):.2f} dB {degrees(-atan(10)):.3f} deg;"
      f" factor 2 {db(1 / sqrt(1.25)):.2f} dB {degrees(-atan(0.5)):.3f} deg")
print(f"sketch corners: at 2 rad/s {sketch(2.0)[0]:.2f} dB, at 20 rad/s {sketch(20.0)[0]:.2f} dB")
slope = db(road1(1000.0)[0]) - db(road1(100.0)[0])
print(f"slope, 100 to 1000 rad/s: {slope:.3f} dB per decade")
assert abs(slope + 40) < 0.01                                    # two poles: -40 dB/decade far out
sweep = [10 ** (k / 1000 - 3) for k in range(4001)]             # one pole, corner 0.1 rad/s
worst = max(abs(db(road1(w, t2=0.0)[0]) - sketch(w, (1 / T1,))[0]) for w in sweep)
worstp = max(abs(road1(w, t2=0.0)[1] - sketch(w, (1 / T1,))[1]) for w in sweep)
print(f"one pole, worst sketch error over 0.001..10 rad/s: {worst:.4f} dB (10 log10 2 = {10 * log10(2):.4f}),"
      f" {worstp:.3f} deg (arctan 0.1 = {degrees(atan(0.1)):.3f})")
assert abs(worst - 10 * log10(2)) < 1e-4                         # the sweep finds the corner's 3.01 dB
assert abs(worstp - degrees(atan(0.1))) < 1e-3                   # and the phase sketch's 5.71 deg
far = [abs(db(road1(w)[0]) - sketch(w)[0]) for w in (1e-4, 1e3)]
print(f"sketch against exact, far from both corners: {far[0]:.4f} dB at 0.0001 rad/s, {far[1]:.4f} dB at 1000 rad/s")
assert max(far) < 0.01                                           # the asymptotes are the right lines
z, i1, i10 = complex(1, 1.0 * T1), road2(1.0, (1.0, 0.0)), road2(10.0, (1.0, 0.0))   # integrator 1/s by road 2
print(f"zero 1 + tau1 s at 1 rad/s: {db(abs(z)):+.2f} dB {degrees(atan2(z.imag, z.real)):+.3f} deg;"
      f" integrator 1/s: {db(i1[0]):.2f} dB at 1 rad/s, {db(i10[0]):.2f} dB at 10 rad/s,"
      f" {i10[1]:.2f} deg")
assert abs(db(abs(z)) + db(road1(1.0, t2=0.0)[0])) < 1e-12       # a zero is a pole turned upside down
assert abs(db(i10[0]) - db(i1[0]) + 20) < 1e-12                  # integrator: -20 dB per decade
# ---- what breaks ----
print(f"wrong: 10 log10 instead of 20 log10 at 1 rad/s: {10 * log10(road1(1.0)[0]):.2f} dB (right {db(road1(1.0)[0]):.2f})")
print(f"wrong: read the sketch at the corner 0.1 rad/s: {10 ** (sketch(0.1)[0] / 20):.4f} m/s (right {road1(0.1)[0]:.4f})")
gd, pd = road1(1.0, delay=1.0); g3, p3 = road3(1.0, delay=1.0)
print(f"wrong: ignore a 1 s delay at 1 rad/s: phase {road1(1.0)[1]:.2f} deg (right {pd:.2f}, simulated {p3:.2f}); gain {g3:.4f}")
assert abs(p3 - pd) < 0.05                                       # delay: more lag ...
assert abs(g3 - gd) < 2e-4                                       # ... and the same gain
vu = run(0.1, 0.01, 20000, a1=-1.0)                              # 20000 steps of 0.01 s: vu[-1] is at 200 s
gu, pu = road2(0.1, (T1 * T2, T1 - T2, -1.0))                    # the unstable car, (tau1 s - 1)(tau2 s + 1)
print(f"wrong: unstable car, pole at +0.1 rad/s: formula |G| at 0.1 rad/s {gu:.4f}, angle {pu:.2f} deg;"
      f" simulated speed at 200 s {vu[-1] / 1e6:.1f} million m/s")
assert abs(vu[-1]) > 100 * gu                                     # no settled sine to measure
print(f"outside the model: 50% throttle wobble at 0.01 rad/s -> {50 * road1(0.01)[0]:.1f} m/s swing predicted")
# ---- try changing ----
print(f"try: tau1 = 20 s, gain at 1 rad/s {road1(1.0, t1=20.0)[0]:.4f} ({db(road1(1.0, t1=20.0)[0]):.2f} dB)")
print(f"try: 2 s delay, phase at 1 rad/s {road1(1.0, delay=2.0)[1]:.2f} deg")
print(f"try: K = 2, every dB value moves by {db(2.0):.2f} dB")
# ---- chart points ----
ws = [10 ** (k / 2) for k in range(-6, 5)]
print("chart, w rad/s      " + " ".join(f"{w:8.4f}" for w in ws))
print("chart, exact dB     " + " ".join(f"{db(road1(w)[0]):8.2f}" for w in ws))
print("chart, sketch dB    " + " ".join(f"{sketch(w)[0]:8.2f}" for w in ws))
print("chart, exact deg    " + " ".join(f"{road1(w)[1]:8.2f}" for w in ws))
print("chart, sketch deg   " + " ".join(f"{sketch(w)[1]:8.2f}" for w in ws))
vt = run(0.1, 0.01, 12001)
print("chart, t s          " + " ".join(f"{5 * k:5d}" for k in range(25)))
print("chart, throttle %   " + " ".join(f"{sin(0.5 * k):5.2f}" for k in range(25)))
print("chart, speed m/s    " + " ".join(f"{vt[500 * k]:5.2f}" for k in range(25)))
print("ALL CHECKS PASS")
