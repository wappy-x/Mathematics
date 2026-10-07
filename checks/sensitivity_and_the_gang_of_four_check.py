# Sensitivity and the gang of four -- the check behind the card.  Standard library only.
# A room on a thermostat.  Time in minutes, temperature in degC, heat in kW.
# Room: tau y' = -y + K (u + d), K = 2 degC/kW, tau = 20 min.  P(s) = K / (tau s + 1).
# Controller: PI, u = Kp (b r - ym) + Ki * integral(r - ym), ym = y + n (sensor reading).
# Inputs, one at a time: setpoint r, draught d (kW of heat lost), sensor noise n (degC).
# Roads: 1. the four transfer functions by complex arithmetic;  2. RK4 simulation of the loop,
# each input alone, gains read off the settled output;  3. time-domain closed forms and the
# integral identity for the draught;  4. noise spread: simulated against a frequency integral.
from math import sqrt, exp, sin, cos, atan, atan2, pi, log, log10

K, TAU, KP, KI = 2.0, 20.0, 2.0, 0.2

def gang(w, kp=KP, ki=KI, pipe=0.0):           # S, T, PS, CS at s = jw; pipe = optional extra lag, min
    s = complex(0.0, w)
    P, C = K / (TAU * s + 1) / (pipe * s + 1), kp + ki / s
    S = 1 / (1 + P * C)
    return S, P * C * S, P * S, C * S

def sim(inp, dt, steps, kp=KP, ki=KI, b=1.0):
    # state: room y and integral z.  inp(t, k) -> (r, d, n).  Records y, u, e = r - y each step.
    def f(t, k, y, z):
        r, d, n = inp(t, k)
        u = kp * (b * r - (y + n)) + ki * z
        return (-y + K * (u + d)) / TAU, r - (y + n), u, r - y
    y = z = 0.0; Y, U, E = [], [], []
    for k in range(steps):
        t = k * dt
        a1, b1, u, e = f(t, k, y, z); Y.append(y); U.append(u); E.append(e)
        a2, b2, _, _ = f(t + dt / 2, k, y + dt / 2 * a1, z + dt / 2 * b1)
        a3, b3, _, _ = f(t + dt / 2, k, y + dt / 2 * a2, z + dt / 2 * b2)
        a4, b4, _, _ = f(t + dt, k, y + dt * a3, z + dt * b3)
        y += dt / 6 * (a1 + 2 * a2 + 2 * a3 + a4); z += dt / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
    return Y, U, E

def phasor(w, which, slot):                     # drive one input with sin(wt), read one output's phasor
    per = 2 * pi / w; n = 2000; dt = per / n; settle = n * (int(150 / per) + 1)
    inp = lambda t, k: tuple(sin(w * t) if i == which else 0.0 for i in range(3))
    out = sim(inp, dt, settle + n)[slot][settle:]
    a = 2 / n * sum(v * sin(w * (settle + k) * dt) for k, v in enumerate(out))
    c = 2 / n * sum(v * cos(w * (settle + k) * dt) for k, v in enumerate(out))
    return complex(a, c)

print("room K = 2 degC/kW, tau = 20 min; PI Kp = 2 kW/degC, Ki = 0.2 kW/(degC min); w in rad/min")
print("   w   |S| form  sim | |T| form  sim | |PS| form  sim | |CS| form  sim | |S+T| sim")
for w in (0.01, 0.05, 0.1, 0.2, 0.5, 2.0):
    S, T, PS, CS = gang(w)
    sS, sT = phasor(w, 0, 2), -phasor(w, 2, 0)            # e from r;  y from n is -T
    sPS, sCS = phasor(w, 1, 0), phasor(w, 0, 1)           # y from d;  u from r
    print(f"{w:5.2f} {abs(S):8.4f} {abs(sS):6.4f} {abs(T):8.4f} {abs(sT):6.4f} {abs(PS):9.4f} {abs(sPS):6.4f}"
          f" {abs(CS):9.4f} {abs(sCS):6.4f}   {abs(sS + sT):7.4f}")
    for x, y in ((S, sS), (T, sT), (PS, sPS), (CS, sCS)):
        assert abs(x - y) < 1e-4 * max(1.0, abs(x)), "simulated loop must match the formula"
    assert abs(sS + sT - 1) < 1e-4, "S + T = 1, from two separate simulations"
ws = [10 ** (-2.5 + k / 4) for k in range(13)]
def peak_s(kp, ki, pipe):
    return max((abs(gang(10 ** (-3 + k / 1000), kp, ki, pipe)[0]), 10 ** (-3 + k / 1000)) for k in range(4001))
for kp, ki, pipe in ((KP, KI, 0.0), (KP, KI, 4.0), (8.0, 0.8, 4.0)):
    m, wm = peak_s(kp, ki, pipe)
    print(f"peak |S|, Kp = {kp:.0f}, pipe lag {pipe:.0f} min: {m:.4f} at w = {wm:.4f} rad/min ({20 * log10(m):.2f} dB)")

# ---- the draught: 0.5 kW of heat lost from t = 0 ----
d0, dt = -0.5, 0.01
Y, U, _ = sim(lambda t, k: (0.0, d0, 0.0), dt, 12001)
a, wn2 = (1 + K * KP) / TAU, K * KI / TAU                # closed loop: y'' + a y' + wn2 y = (K d0 / TAU) delta
sg, wd = a / 2, sqrt(wn2 - a * a / 4)
tp = atan(wd / sg) / wd
yp = K * d0 / TAU * exp(-sg * tp) * sin(wd * tp) / wd
k_min = min(range(len(Y)), key=lambda k: Y[k])
area = dt * (sum(Y) - (Y[0] + Y[-1]) / 2)
print(f"draught, no control: room settles {K * d0:.2f} degC low")
print(f"closed loop: {TAU:.0f} s^2 + {1 + K * KP:.0f} s + {K * KI:.1f}; alpha {sg:.4f} /min, wd {wd:.4f} rad/min, zeta {sg / sqrt(wn2):.4f}")
print(f"draught dip, closed form: {yp:.4f} degC at {tp:.2f} min;  simulated: {Y[k_min]:.4f} degC at {k_min * dt:.2f} min")
print(f"draught area, d0/Ki: {d0 / KI:.4f} degC min;  simulated: {area:.4f};  at 120 min y = {Y[-1]:.5f}")
assert abs(Y[k_min] - yp) < 1e-5 and abs(k_min * dt - tp) < 0.02, "dip: simulation vs closed form"
assert abs(area - d0 / KI) < 1e-3, "integral of the dip equals d0 / Ki"
# cancellation design: Kp = 2, Ki = Kp / tau = 0.1 cancels the room's pole; T = 1/(5s+1)
Yc, _, _ = sim(lambda t, k: (0.0, d0, 0.0), dt, 12001, ki=0.1)
yc = lambda t: K * d0 / TAU / ((K * KP - 1) / TAU) * (exp(-t / TAU) - exp(-K * KP * t / TAU))
print(f"cancel design: at 30 min y = {Yc[3000]:.4f} (closed form {yc(30):.4f}); PI design {Y[3000]:.4f}")
print(f"cancel design area: {dt * (sum(Yc) - (Yc[0] + Yc[-1]) / 2):.4f} degC min by 120 min; d0/Ki = {d0 / 0.1:.4f}")
assert abs(Yc[3000] - yc(30)) < 1e-6, "cancellation design: simulation vs closed form"
Rs, _, _ = sim(lambda t, k: (1.0, 0.0, 0.0), dt, 6001)
Rc, _, _ = sim(lambda t, k: (1.0, 0.0, 0.0), dt, 6001, ki=0.1)
Rf, Uf, _ = sim(lambda t, k: (1.0, 0.0, 0.0), dt, 6001, b=0.0)
print(f"setpoint +1 degC: overshoot PI {max(Rs) - 1:.4f}, cancel {max(Rc) - 1:.4f}, 2DOF b=0 {max(Rf) - 1:.4f} degC")
print(f"setpoint +1 degC: y at 10 min PI {Rs[1000]:.4f}, cancel {Rc[1000]:.4f} (1-e^-2 = {1 - exp(-2):.4f}), 2DOF {Rf[1000]:.4f}")
Df, _, _ = sim(lambda t, k: (0.0, d0, 0.0), dt, 12001, b=0.0)
print(f"2DOF draught dip {min(Df):.4f} degC (same loop, same S);  heater kick at t = 0: 1DOF {KP:.2f} kW, 2DOF {Uf[0]:.2f} kW")
zeta = sg / sqrt(wn2)                                      # b = 0: FT = K Ki / (tau s^2 + ...), no zero
assert abs(max(Rf) - 1 - exp(-pi * zeta / sqrt(1 - zeta ** 2))) < 1e-4, "2DOF"

# ---- the noisy sensor: 0.1 degC rms, a new independent reading every 0.1 min ----
st = 0x2026_0930
def rnd():
    global st
    st = (st + 0x9E3779B97F4A7C15) & (2 ** 64 - 1); z = st
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
SIG, HOLD, N = 0.1, 0.1, 30000
noise = []
for _ in range(N // 2):
    u1, u2 = 1.0 - rnd(), rnd()
    rr = sqrt(-2 * log(u1)); noise += [SIG * rr * cos(2 * pi * u2), SIG * rr * sin(2 * pi * u2)]
def noise_rms(kp, ki):
    Yn, Un, _ = sim(lambda t, k: (0.0, 0.0, noise[k // 5]), HOLD / 5, 5 * N, kp=kp, ki=ki)
    keep = 5 * 500                                         # drop the first 50 min
    rms = lambda v: sqrt(sum(x * x for x in v[keep:]) / len(v[keep:]))
    # frequency road: var = (1/pi) * int_0^inf |H|^2 SIG^2 HOLD sinc^2(w HOLD / 2) dw, H = T or CS
    h, W = 0.01, 400.0; acc = [0.0, 0.0]
    for i in range(int(W / h) + 1):
        w = max(i * h, 1e-9); wt = 1 if i in (0, int(W / h)) else (4 if i % 2 else 2)
        x = w * HOLD / 2; sinc2 = (sin(x) / x) ** 2
        _, T, _, CS = gang(w, kp, ki)
        acc[0] += wt * abs(T) ** 2 * sinc2; acc[1] += wt * abs(CS) ** 2 * sinc2
    tail = 2 / (pi * HOLD * W)                             # sinc^2 tail beyond W, where |CS| -> kp, |T| -> 0
    vy = SIG ** 2 * HOLD / pi * h / 3 * acc[0]
    vu = SIG ** 2 * HOLD / pi * h / 3 * acc[1] + kp * kp * SIG ** 2 * tail
    return rms(Yn), sqrt(vy), rms(Un), sqrt(vu)
for kp, ki in ((KP, KI), (8.0, 0.8)):
    sy, fy, su, fu = noise_rms(kp, ki)
    print(f"noise, Kp = {kp:.0f}: room jitter sim {sy:.4f} formula {fy:.4f} degC; heater jitter sim {su:.4f} formula {fu:.4f} kW")
    assert abs(su - fu) < 0.03 * fu and abs(sy - fy) < 0.15 * fy, "noise: simulation vs frequency integral"
Y8, _, _ = sim(lambda t, k: (0.0, d0, 0.0), dt, 12001, kp=8.0, ki=0.8)
print(f"Kp = 8, Ki = 0.8: draught dip {min(Y8):.4f} degC, area {dt * (sum(Y8) - (Y8[0] + Y8[-1]) / 2):.4f} degC min")
print(f"outside the model: a 5 degC setpoint step asks the heater for {KP * 5:.1f} kW at t = 0, against a 3 kW rating")

# ---- chart points ----
print("chart, w rad/min " + " ".join(f"{w:7.4f}" for w in ws))
print("chart, |S| dB    " + " ".join(f"{20 * log10(abs(gang(w)[0])):7.2f}" for w in ws))
print("chart, |T| dB    " + " ".join(f"{20 * log10(abs(gang(w)[1])):7.2f}" for w in ws))
print("chart, t min     " + " ".join(f"{5 * k:5d}" for k in range(13)))
print("chart, no ctrl   " + " ".join(f"{K * d0 * (1 - exp(-5 * k / TAU)):5.2f}" for k in range(13)))
print("chart, PI        " + " ".join(f"{Y[500 * k]:5.2f}" for k in range(13)))
print("chart, cancel    " + " ".join(f"{Yc[500 * k]:5.2f}" for k in range(13)))
print("ALL CHECKS PASS")
