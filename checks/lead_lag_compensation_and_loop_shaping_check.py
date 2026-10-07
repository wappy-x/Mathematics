# Loop shaping -- the check behind the card.  Standard library only.
# A camera gimbal's tilt axis: motor torque u (N m) turns inertia J = 0.01 kg m^2, so the
# plant is G(s) = 1/(J s^2), angle in rad.  Target: loop crossover 10 rad/s.  A lead
# C1 = Kc (T s + 1)/(alpha T s + 1) adds 45 deg there; a lag C2 = beta (Tl s + 1)/(beta Tl s + 1)
# multiplies the low-frequency gain by beta = 10.  Roads: closed-form design; complex
# arithmetic with a search and a bisection; RK4 simulation in time; the Bode sensitivity integral.
from math import sqrt, sin, cos, atan, atan2, log, log10, exp, pi, degrees, radians

J, WC, PHI, BETA, TL, TD = 0.01, 10.0, radians(45.0), 10.0, 1.0, 0.02   # TD: imbalance torque, N m
ALPHA = (1 - sin(PHI)) / (1 + sin(PHI))                 # road 1: the design formulas
T, KC = 1 / (WC * sqrt(ALPHA)), J * WC ** 2 * sqrt(ALPHA)

def lead(w, kc=KC, al=ALPHA, t=T):
    return kc * complex(1, w * t) / complex(1, al * w * t)
def lag(w, b=BETA, tl=TL):
    return b * complex(1, w * tl) / complex(1, b * w * tl)
def loop(w, uselag=True, delay=0.0, k=0.0, **kw):          # k > 0: top-heavy payload, J s^2 - k
    c = lead(w, **kw) * (lag(w) if uselag else 1)
    return c * complex(cos(w * delay), -sin(w * delay)) / (-J * w * w - k)
def deg(z): return degrees(atan2(z.imag, z.real))
def crossover(f, lo=0.5, hi=500.0):                          # bisection on |L| = 1, in log w
    for _ in range(100):
        m = sqrt(lo * hi)
        lo, hi = (m, hi) if abs(f(m)) > 1 else (lo, m)
    w = sqrt(lo * hi)
    return w, (deg(f(w)) + 360) % 360 - 180                  # phase margin: angle above -180 deg
def golden(f, lo, hi):                                       # maximise f on [lo, hi], searching in log w
    g, lo, hi = (sqrt(5) - 1) / 2, log(lo), log(hi)
    for _ in range(200):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        lo, hi = (lo, b) if f(exp(a)) > f(exp(b)) else (a, hi)
    return exp((lo + hi) / 2)
def rk4(f, x, dt, n, every):                                 # returns x[0] every `every` steps
    out = [x[0]]
    for i in range(1, n + 1):
        k1 = f(x); k2 = f([a + dt / 2 * b for a, b in zip(x, k1)])
        k3 = f([a + dt / 2 * b for a, b in zip(x, k2)]); k4 = f([a + dt * b for a, b in zip(x, k3)])
        x = [a + dt / 6 * (p + 2 * q + 2 * r + s) for a, p, q, r, s in zip(x, k1, k2, k3, k4)]
        if i % every == 0: out.append(x[0])
    return out
def gimbal(uselag, d, r, tend, every, kc=KC, al=ALPHA, t=T, k=0.0):   # states: angle, rate, lead state, lag state
    def f(x):
        e = r - x[0]
        v = kc * (e / al + (1 - 1 / al) * x[2])              # lead = KC/alpha + KC(1 - 1/alpha)/(alpha T s + 1)
        u = v + (BETA - 1) * x[3] if uselag else v           # lag = 1 + (beta - 1)/(beta Tl s + 1)
        return [x[1], (u + d + k * x[0]) / J, (e - x[2]) / (al * t), (v - x[3]) / (BETA * TL)]   # k: top-heavy pull
    return rk4(f, [0.0] * 4, 0.001, int(round(tend * 1000)), every)
def bode_integral(f, sign=0):                                # integral of ln|S| dw, w = e^u, Simpson
    lo, hi, n = log(1e-6), log(1e7), 40000
    h, tot = (hi - lo) / n, 0.0
    for i in range(n + 1):
        w = exp(lo + i * h); v = log(abs(1 / (1 + f(w))))
        v = v if sign == 0 else (min(v, 0.0) if sign < 0 else max(v, 0.0))
        tot += (1 if i in (0, n) else (4 if i % 2 else 2)) * v * w
    return tot * h / 3

print(f"gimbal: J = {J} kg m^2, plant 1/(J s^2); target crossover {WC:.0f} rad/s = {WC / 2 / pi:.4f} Hz")
print(f"target: phase margin at least 35 deg, pointing error under 0.5 deg for a {TD} N m imbalance torque")
print(f"road 1, lead formulas: alpha {ALPHA:.6f}  T {T:.6f} s  zero {1 / T:.4f} rad/s  pole {1 / (ALPHA * T):.4f} rad/s  Kc {KC:.6f} N m/rad")
wm = golden(lambda w: deg(lead(w)), 0.1, 1000.0)
print(f"road 2, search: lead phase peaks at {deg(lead(wm)):.4f} deg at {wm:.4f} rad/s; gain there {abs(lead(wm)) / KC:.4f} (1/sqrt(alpha) {1 / sqrt(ALPHA):.4f})")
n = 20000; dt = 2 * pi / WC / 2000                           # road 3: a 10 rad/s sine through the lead's ODE
x, ys, e = 0.0, [], lambda t: sin(WC * t)
for i in range(n):                                           # alpha T x' = -x + e,  y = e/alpha + (1 - 1/alpha) x
    t = i * dt
    k1 = (e(t) - x) / (ALPHA * T); k2 = (e(t + dt / 2) - x - dt / 2 * k1) / (ALPHA * T)
    k3 = (e(t + dt / 2) - x - dt / 2 * k2) / (ALPHA * T); k4 = (e(t + dt) - x - dt * k3) / (ALPHA * T)
    ys.append(e(t) / ALPHA + (1 - 1 / ALPHA) * x); x += dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
last = range(n - 2000, n); sa = sum(ys[i] * sin(WC * i * dt) for i in last) / 1000; ca = sum(ys[i] * cos(WC * i * dt) for i in last) / 1000
print(f"road 3, simulation: the sine comes out {sqrt(sa * sa + ca * ca):.4f} times bigger and {degrees(atan2(ca, sa)):.2f} deg early")
w1, pm1 = crossover(lambda w: loop(w, uselag=False))
print(f"lead loop: crossover {w1:.4f} rad/s, phase margin {pm1:.2f} deg, delay margin {radians(pm1) / w1 * 1000:.1f} ms")
lagc = deg(lag(WC)); rule = -degrees((1 - 1 / BETA) / (WC * TL))
print(f"lag: beta {BETA:.0f}, zero {1 / TL:.4f} rad/s, pole {1 / (BETA * TL):.4f} rad/s; phase at 10 rad/s {lagc:.2f} deg (rule of thumb {rule:.2f})")
print(f"hand: sin 45 deg {sin(PHI):.5f}; error, lead only {TD / KC:.6f} rad; arctan 10 = {degrees(atan(10)):.3f} deg,"
      f" arctan 100 = {degrees(atan(100)):.3f} deg; lag gain at 10 rad/s {abs(lag(WC)):.4f}; 20 ms at 10 rad/s = {degrees(0.2):.2f} deg")
w2, pm2 = crossover(lambda w: loop(w))
print(f"lead-lag loop: crossover {w2:.4f} rad/s, phase margin {pm2:.2f} deg, delay margin {radians(pm2) / w2 * 1000:.1f} ms")
lo, hi = 1.0, 5.0                                            # where the lead-lag loop's phase crosses -180 deg
for _ in range(100):
    m = (lo + hi) / 2; lo, hi = (m, hi) if loop(m).imag > 0 else (lo, m)
print(f"lead-lag: phase crosses -180 deg at {lo:.4f} rad/s where |L| = {abs(loop(lo)):.3f}: gain may fall to {100 / abs(loop(lo)):.1f}% of design")
e1, e2 = gimbal(False, TD, 0.0, 20.0, 20000), gimbal(True, TD, 0.0, 20.0, 20000)
print(f"imbalance {TD} N m, steady pointing error: formula {degrees(TD / KC):.4f} deg lead, {degrees(TD / (KC * BETA)):.4f} deg lead-lag;"
      f" simulated at 20 s {degrees(e1[-1]):.4f}, {degrees(e2[-1]):.4f}")
s1, s2 = gimbal(False, 0.0, 0.1, 5.0, 1), gimbal(True, 0.0, 0.1, 5.0, 1)
print(f"0.1 rad step: overshoot {100 * (max(s1) / 0.1 - 1):.1f}% lead, {100 * (max(s2) / 0.1 - 1):.1f}% lead-lag")
print(f"noise: lead's high-frequency gain is {1 / ALPHA:.4f} times its low ({20 * log10(1 / ALPHA):.2f} dB);"
      f" a 0.5 rad step asks {0.5 * KC / ALPHA:.2f} N m at once")
I1, I2 = bode_integral(lambda w: loop(w, uselag=False)), bode_integral(loop)
print(f"waterbed, integral of ln|S| dw (theorem: 0): lead {I1:.4f}, lead-lag {I2:.4f} rad/s")
for name, uselag in (("lead", False), ("lead-lag", True)):
    f = lambda w: loop(w, uselag=uselag)
    pk = golden(lambda w: abs(1 / (1 + f(w))), 1.0, 100.0)
    print(f"  {name:<8} area below 0 {bode_integral(f, -1):8.4f}, above 0 {bode_integral(f, 1):7.4f} rad/s;"
          f" peak |S| {20 * log10(abs(1 / (1 + f(pk)))):.2f} dB at {pk:.2f} rad/s")
K3 = 9 * J; a3, a2, a1, a0 = ALPHA * T * J, J, KC * T - K3 * ALPHA * T, KC - K3                 # pole at sqrt(K3/J) = 3 rad/s
I3 = bode_integral(lambda w: loop(w, uselag=False, k=K3))
print(f"top-heavy payload, k = {K3:.2f} N m/rad, pole at +{sqrt(K3 / J):.0f} rad/s: Routh a2 a1 - a3 a0 = {a2 * a1 - a3 * a0:.6f} > 0;"
      f" integral {I3:.4f} (theorem pi x 3 = {3 * pi:.4f})")
# ---- what breaks ----
wb1 = crossover(lambda w: loop(w, uselag=False, kc=J * WC ** 2))
print(f"wrong: keep the plain-gain Kc = {J * WC ** 2:.2f}: crossover {wb1[0]:.2f} rad/s, margin {wb1[1]:.2f} deg")
af = 1 / ALPHA; tf = 1 / (WC * sqrt(af)); kf = J * WC ** 2 * sqrt(af)
wb2 = crossover(lambda w: loop(w, uselag=False, kc=kf, al=af, t=tf))
print(f"wrong: alpha flipped to {af:.4f}: margin {wb2[1]:.2f} deg; Routh a2 a1 - a3 a0 = {J * kf * tf - af * tf * J * kf:.6f}")
sk, sf = gimbal(False, 0.0, 0.1, 5.0, 1, k=K3), gimbal(False, 0.0, 0.1, 5.0, 1, kc=kf, al=af, t=tf); print(f"Routh by simulation, 0.1 rad step: top-heavy settles at {sk[-1]:.4f} rad (0.1 Kc/(Kc - k) = {0.1 * KC / (KC - K3):.4f}); flipped alpha passes 1 rad at {next(i for i, v in enumerate(sf) if abs(v) > 1) * 0.001:.3f} s")
wb3 = crossover(lambda w: lead(w) * lag(w, tl=0.2) / (-J * w * w))
print(f"wrong: lag zero at 5 rad/s, not 1: crossover {wb3[0]:.2f} rad/s, margin {wb3[1]:.2f} deg")
wb4 = crossover(lambda w: loop(w, delay=0.02))
print(f"wrong: ignore a 20 ms sensing delay: margin {wb4[1]:.2f} deg, not {pm2:.2f}")
wt = crossover(lambda w: lead(w) * lag(w, b=30.0) / (-J * w * w))
print(f"try: beta 30: error {degrees(TD / (KC * 30)):.4f} deg, margin {wt[1]:.2f} deg")
a60 = (1 - sin(radians(60))) / (1 + sin(radians(60))); print(f"try: lead of 60 deg: alpha {a60:.4f}, high-frequency gain {1 / a60:.2f} times the low")
# ---- chart points ----
ws = [10 ** (k / 4) for k in range(-4, 9)]
def row(label, vals, w): return f"{label:<23}" + " ".join(f"{v:{w}.2f}" for v in vals)
ph = lambda w, l: -180 + degrees(atan(w * T) - atan(ALPHA * w * T)) + l * degrees(atan(w * TL) - atan(BETA * w * TL))
print(row("chart, w rad/s", ws, 7))
print(row("chart, phase gain deg", [(deg(J * WC ** 2 / complex(-J * w * w, 0)) + 360) % 360 - 360 for w in ws], 7))
print(row("chart, phase lead deg", [ph(w, 0) for w in ws], 7))
print(row("chart, phase l-lag deg", [ph(w, 1) for w in ws], 7))
print(row("chart, |S| lead dB", [20 * log10(abs(1 / (1 + loop(w, uselag=False)))) for w in ws], 7))
print(row("chart, |S| l-lag dB", [20 * log10(abs(1 / (1 + loop(w)))) for w in ws], 7))
c1, c2 = gimbal(False, TD, 0.0, 6.0, 250), gimbal(True, TD, 0.0, 6.0, 250)
print(row("chart, t s", [0.25 * i for i in range(25)], 5))
print(row("chart, error lead deg", [degrees(v) for v in c1], 5))
print(row("chart, error l-lag deg", [degrees(v) for v in c2], 5))
assert abs(deg(lead(wm)) - 45.0) < 1e-6; assert abs(wm - WC) < 1e-4   # search finds the formula's peak, at its frequency
assert abs(degrees(atan2(ca, sa)) - 45.0) < 0.05                    # simulated sine leads by 45 deg
assert abs(sqrt(sa * sa + ca * ca) - 1 / sqrt(ALPHA)) < 1e-3       # ... and is 1/sqrt(alpha) bigger
assert abs(pm1 - 45.0) < 1e-6                                      # bisection lands on the design
assert abs(e2[-1] - TD / (KC * BETA)) < 1e-6 * TD / KC              # simulated error = beta-fold smaller
assert abs(I2) < 1e-3                                              # waterbed: net area zero
assert abs(I3 - 3 * pi) < 1e-3                                     # unstable pole: net area pi p
assert (max(abs(v) for v in sf) > 1.0) == (J * kf * tf - af * tf * J * kf < 0)   # flipped alpha: Routh verdict = simulation
assert (abs(sk[-1] - 0.1 * KC / (KC - K3)) < 1e-6) == (a2 * a1 - a3 * a0 > 0)    # top-heavy: Routh verdict = simulation
assert abs(wb2[1] + 45.0) < 1e-6                                   # ... and bisection finds -45 deg margin
assert pm2 >= 35.0 and degrees(e2[-1]) < 0.5                       # lead-lag meets both targets
print("ALL CHECKS PASS")
