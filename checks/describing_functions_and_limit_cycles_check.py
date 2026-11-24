# Describing functions and limit cycles -- the check behind the card.  Standard library only.
# A tray conveyor's position loop: drive command u (V) -> belt position y (cm), G(s) = 1/(s(s+1)(s+2)).
# Roads: (1) describing function, closed form and by numerical Fourier integral; (2) the exact relay
# oscillation as a sum over every odd harmonic; (3) RK4 simulation of the loop with the nonlinearity.
import math
PI = math.pi

def G(w):  # G(jw) = 1/(-3w^2 + j w (2 - w^2)), returned as (re, im)
    a, b = -3*w*w, w*(2 - w*w); d = a*a + b*b
    return a/d, -b/d

def phase(w):  # degrees, unwrapped: -90 - atan w - atan(w/2)
    return -90 - math.degrees(math.atan(w) + math.atan(w/2))

def bisect(f, lo, hi, n=100):  # root of f between lo and hi (f changes sign)
    for _ in range(n):
        m = (lo + hi)/2
        if (f(lo) > 0) == (f(m) > 0): lo = m
        else: hi = m
    return (lo + hi)/2

def relay(e): return 1.0 if e > 0 else -1.0
def sat(K): return lambda e: max(-1.0, min(1.0, K*e))
def df_num(nl, A, n=20000):  # first Fourier sine coefficient of nl(A sin t), divided by A
    return sum(nl(A*math.sin((i + 0.5)*2*PI/n))*math.sin((i + 0.5)*2*PI/n) for i in range(n))*2/n/A
def df_sat(K, A):  # saturation of slope K and output limit 1 V, closed form
    r = 1/(K*A)
    return K if r >= 1 else 2*K/PI*(math.asin(r) + r*math.sqrt(1 - r*r))

def sim(nl, y0, tend, dt=1e-4):  # u = -nl(y); returns upward zero crossings and y samples
    x = [y0, 0.0, 0.0]; t = 0.0; ups = []; ys = []
    f = lambda x, u: (x[1], x[2], u - 3*x[2] - 2*x[1])
    while t < tend - 1e-9:
        u = -nl(x[0]); yp = x[0]
        k1 = f(x, u); k2 = f([x[i] + dt/2*k1[i] for i in range(3)], u)
        k3 = f([x[i] + dt/2*k2[i] for i in range(3)], u); k4 = f([x[i] + dt*k3[i] for i in range(3)], u)
        x = [x[i] + dt/6*(k1[i] + 2*k2[i] + 2*k3[i] + k4[i]) for i in range(3)]; t += dt
        if yp < 0 <= x[0]: ups.append(t - dt*x[0]/(x[0] - yp))
        ys.append(x[0])
    return ups, ys

def cycle(ups, ys, dt=1e-4):  # period and amplitude over the last full cycle
    T = ups[-1] - ups[-2]; seg = ys[int(ups[-2]/dt):int(ups[-1]/dt)]
    return T, (max(seg) - min(seg))/2

# ---- the plant: where the phase reaches -180 degrees ----
w180 = bisect(lambda w: phase(w) + 180, 0.1, 10)
g180 = math.hypot(*G(w180))
print(f"plant: phase -180 deg at w {w180:.4f} rad/s (sqrt 2 = {math.sqrt(2):.4f}), |G| {g180:.4f} cm/V = 1/{1/g180:.4f}")
assert abs(w180 - math.sqrt(2)) < 1e-9 and abs(g180 - 1/6) < 1e-9 and abs(math.degrees(math.atan2(G(1)[1], G(1)[0])) - phase(1)) < 1e-9

# ---- road 1: describing function of the relay ----
c1 = df_num(relay, 1.0)
print(f"relay: first harmonic of a +-1 V square wave {c1:.4f} V (4/pi = {4/PI:.4f})")
assert abs(c1 - 4/PI) < 1e-6
A_df = 4/(PI*(1/g180)); T_df = 2*PI/w180
print(f"describing function: 4/(pi A) = {1/g180:.4f}  ->  A {A_df:.4f} cm, period {T_df:.4f} s")
r3 = math.hypot(*G(3*w180))/math.hypot(*G(w180))/3
print(f"third harmonic in y, relative to the fundamental: (1/3) x {r3*3:.4f} = {r3:.4f}")

# ---- road 2: the exact symmetric relay oscillation, every odd harmonic ----
def y_ex(t, w): return sum(4/(k*PI)*(G(k*w)[0]*math.sin(k*w*t) + G(k*w)[1]*math.cos(k*w*t)) for k in range(1, 2000, 2))
w_ex = bisect(lambda w: sum(G(k*w)[1]/k for k in range(1, 2000, 2)), 1.0, 2.0, 60)
T_ex = 2*PI/w_ex; A_ex = max(abs(y_ex(i*T_ex/2000, w_ex)) for i in range(1000))
print(f"exact harmonic sum: w {w_ex:.4f} rad/s, period {T_ex:.4f} s, A {A_ex:.4f} cm")

# ---- road 3: simulate the relay loop from a small and a large start ----
for y0 in (1.0, 0.01):
    ups, ys = sim(relay, y0, 60)
    T_s, A_s = cycle(ups, ys)
    print(f"simulation from y0 {y0:.2f} cm: period {T_s:.4f} s, A {A_s:.4f} cm")
    assert abs(T_s - T_ex) < 2e-3 and abs(A_s - A_ex) < 2e-4
print(f"describing function vs simulation: A {100*(A_df/A_s - 1):+.1f}%, period {100*(T_df/T_s - 1):+.1f}%")
assert abs(A_df/A_s - 1) < 0.05 and abs(T_df/T_s - 1) < 0.03 and abs(A_df/A_s - 1) > 0.01
t0 = ups[-2]; pts = [ys[int((t0 + 0.25*i)/1e-4)] for i in range(19)]
print("chart, simulated y:", " ".join(f"{p:.3f}" for p in pts))
print("chart, DF sine:    ", " ".join(f"{A_df*math.sin(w180*0.25*i):.3f}" for i in range(19)))

# ---- saturation: proportional gain K V/cm, drive limited to +-1 V ----
for Kg in (10.0, 5.0):
    print(f"saturation K {Kg:.0f}: N(0.3 cm) closed form {df_sat(Kg, 0.3):.4f}, integral {df_num(sat(Kg), 0.3):.4f} V/cm")
    assert abs(df_sat(Kg, 0.3) - df_num(sat(Kg), 0.3)) < 1e-4
A_sat = bisect(lambda A: df_sat(10.0, A) - 6, 0.1, 10)
ups, ys = sim(sat(10.0), 0.01, 80); T_s10, A_s10 = cycle(ups, ys)
print(f"saturation K 10: predicted A {A_sat:.4f} cm, period {T_df:.4f} s; simulated A {A_s10:.4f} cm, period {T_s10:.4f} s")
assert abs(A_sat/A_s10 - 1) < 0.05
ups, ys = sim(sat(5.0), 0.3, 80)
print(f"saturation K 5: N <= 5 < 6, no crossing; after 80 s |y| <= {max(abs(v) for v in ys[-50000:]):.5f} cm")
assert max(abs(v) for v in ys[-50000:]) < 1e-2

# ---- relay autotune -> PID, then test it on a 1 mm step and a load change ----
Ku, Tu = 4/(PI*A_s), T_s; wu = 2*PI/Tu
print(f"relay test: Ku {Ku:.4f} V/cm (true 6.0000), Tu {Tu:.4f} s (true {T_df:.4f}); plant phase at wu {wu:.4f} rad/s {phase(wu):.1f} deg")
def pid_test(name, Kp, Ti, Td):
    Ki, Kd = Kp/Ti, Kp*Td
    ph = lambda w: phase(w) + math.degrees(math.atan2(Kd*w - Ki/w, Kp))
    mag = lambda w: math.hypot(*G(w))*math.hypot(Kp, Kd*w - Ki/w)
    wgc = bisect(lambda w: mag(w) - 1, 0.3, 20); PM = 180 + ph(wgc)
    low = min(ph(0.01*1.01**i) for i in range(926))  # phase from 0.01 to 100 rad/s
    x = [0.0]*4; dt = 1e-3; peak = umax = dip = 0.0  # x = y, y', y'', integral of the error
    f = lambda x, d: (x[1], x[2], Kp*(0.1 - x[0]) + Ki*x[3] - Kd*x[1] + d - 3*x[2] - 2*x[1], 0.1 - x[0])
    for i in range(60000):
        d = -0.1 if i >= 30000 else 0.0
        k1 = f(x, d); k2 = f([x[j] + dt/2*k1[j] for j in range(4)], d)
        k3 = f([x[j] + dt/2*k2[j] for j in range(4)], d); k4 = f([x[j] + dt*k3[j] for j in range(4)], d)
        x = [x[j] + dt/6*(k1[j] + 2*k2[j] + 2*k3[j] + k4[j]) for j in range(4)]
        umax = max(umax, abs(Kp*(0.1 - x[0]) + Ki*x[3] - Kd*x[1]))
        if i < 30000: peak = max(peak, x[0])
        else: dip = max(dip, 0.1 - x[0])
    print(f"{name}: Kp {Kp:.4f} V/cm, Ti {Ti:.4f} s, Td {Td:.4f} s; PM {PM:.2f} deg at {wgc:.4f} rad/s; lowest phase to 100 rad/s {low:.1f} deg")
    print(f"  1 mm step: overshoot {100*(peak/0.1 - 1):.1f}%; 0.1 V load at 30 s: dip {10*dip:.3f} mm; y(60 s) {10*x[0]:.4f} mm; max |u| {umax:.3f} V")
    assert low > -180 and abs(x[0] - 0.1) < 1e-3 and umax < 1
    return PM
pm_zn = pid_test("ZN PID", 0.6*Ku, Tu/2, Tu/8)
print(f"ZN moves the point -1/Ku to phase {-180 + math.degrees(math.atan(PI/4 - 1/PI)):.2f} deg at wu")
t45 = math.tan(PI/4); Td45 = (t45 + math.sqrt(t45*t45 + 1))/2/wu  # Ti = 4 Td, phase lead 45 deg at wu
pm_ah = pid_test("45-deg relay PID", Ku*math.cos(PI/4), 4*Td45, Td45)
assert 40 < pm_ah < 50 and pm_zn < 30

# ---- what breaks ----
print(f"break, no 4/pi: A {g180:.4f} cm, {100*(g180/A_s - 1):+.1f}% against the simulation")
r = bisect(lambda s: s**3 + 3*s*s + 2*s + 10, -5, 0)  # real root of s^3 + 3s^2 + 2s + 10
b, c = 3 + r, -10/r; grow, wl = -b/2, math.sqrt(c - b*b/4)  # the other two: s^2 + b s + c
print(f"break, K 10 treated as linear: poles {r:.4f}, {grow:.4f} +- {wl:.4f}j; swing x{math.exp(grow*2*PI/wl):.1f} per cycle; real swing stays at {A_s10:.4f} cm")
assert grow > 0
yd, buf, n = 0.0, [-1.0]*1000, 0; ymax = 0.0  # integrator plus 1 s delay, step 1 ms, relay through the delay
for i in range(20000):
    u = buf[n % 1000]; buf[n % 1000] = -relay(yd); n += 1; yd += 1e-3*u
    if i > 10000: ymax = max(ymax, abs(yd))
print(f"break, integrator + 1 s delay: describing function A {4/PI*2/PI:.4f} cm, period 4 s; exact triangle A {1.0*1000*1e-3:.4f} cm (1 cm/s for 1 s), simulated {ymax:.4f} cm")
assert abs(ymax - 1) < 5e-3
ups, ys = sim(lambda e: 2*relay(e), 0.01, 60); T2, A2 = cycle(ups, ys)
print(f"try relay +-2 V: describing function A {2*A_df:.4f} cm; simulated A {A2:.4f} cm, period {T2:.4f} s")
ups, ys = sim(sat(20.0), 0.01, 80); T20, A20 = cycle(ups, ys)
print(f"try K 20: predicted A {bisect(lambda A: df_sat(20.0, A) - 6, 0.05, 10):.4f} cm; simulated A {A20:.4f} cm, period {T20:.4f} s")
t60 = math.tan(PI/3); Td60 = (t60 + math.sqrt(t60*t60 + 1))/2/wu
pid_test("try 60-deg relay PID", Ku*math.cos(PI/3), 4*Td60, Td60)
print(f"figure, nyquist", " ".join(f"{w}:{G(w)[0]:.4f},{G(w)[1]:.4f}" for w in (0.8, 1.0, 1.4142, 2.0, 3.0)),
      "; -1/N(A)", " ".join(f"{A}:{-PI*A/4:.4f}" for A in (0.1, 0.2122, 0.5, 0.9)))
print("ALL CHECKS PASS")
