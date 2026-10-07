# Nyquist criterion and stability margins -- the check behind the card.  Standard library only.
# Thermostat loop, time in minutes.  Valve opening u (%) -> hot water through 2 min of pipe ->
# radiator (lag 2 min) -> room (lag 20 min).  Plant 0.4 degC per %, thermostat gain 16 % per degC.
# Loop gain L(s) = K e^(-s TH) / ((T1 s + 1)(T2 s + 1)), K = 6.4.  Three roads to "stable, and by how much":
#   1. Nyquist: wind L(jw) round -1 for w from -inf to +inf; margins from the frequency response.
#   2. Closed-loop poles: Newton's method on (T1 s + 1)(T2 s + 1) + K e^(-s TH) = 0.
#   3. Time domain: simulate the room with RK4 and a delay buffer; measure peaks.
from math import pi, sin, cos, atan, atan2, exp, log, log10, sqrt, degrees, tan

T1, T2, TH, KP, KC = 20.0, 2.0, 2.0, 0.4, 16.0
K = KP * KC

def cexp(z): return exp(z.real) * complex(cos(z.imag), sin(z.imag))
def L(s, k=K, th=TH): return k * cexp(-s * th) / ((T1 * s + 1) * (T2 * s + 1))
def mag(w, k=K, t1=T1, t2=T2): return k / sqrt((1 + (w * t1) ** 2) * (1 + (w * t2) ** 2))
def phase(w, th=TH, t1=T1, t2=T2): return -atan(w * t1) - atan(w * t2) - w * th        # unwrapped, radians

def bisect(f, lo, hi):
    for _ in range(200):
        mid = (lo + hi) / 2
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return (lo + hi) / 2

def winding(Lf, n=200000):          # clockwise turns of Lf(jw) round -1, w = tan(u), u across (-pi/2, pi/2)
    total, prev = 0.0, None
    for i in range(1, n):
        z = 1 + Lf(1j * tan(-pi / 2 + pi * i / n))
        a = atan2(z.imag, z.real)
        if prev is not None:
            d = a - prev
            d -= 2 * pi * round(d / (2 * pi))
            total += d
        prev = a
    return -round(total / (2 * pi))

def root(k, th, s=0.45j):           # Newton on f(s) = (T1 s+1)(T2 s+1) + k e^(-s th)
    for _ in range(100):
        e = cexp(-s * th)
        s -= ((T1 * s + 1) * (T2 * s + 1) + k * e) / (T1 * (T2 * s + 1) + T2 * (T1 * s + 1) - k * th * e)
    return s

def simulate(k, th, t_end=240.0, dt=0.01):   # 1 degC setpoint step at t = 0; returns room temperature list
    kc = k / KP; lag = round(th / dt); n = round(t_end / dt)
    y = r = 0.0; ys, us = [], []
    def ud(i2):                     # valve opening at half-step index i2/2, delayed by th; 0 before start
        j = i2 / 2 - lag
        if j < 0: return 0.0
        a = int(j); return us[a] if j == a else (us[a] + us[a + 1]) / 2
    def rhs(i2, r, y): return (-r + KP * ud(i2)) / T2, (-y + r) / T1
    for i in range(n + 1):
        ys.append(y); us.append(kc * (1.0 - y))
        if i == n: break
        k1 = rhs(2 * i, r, y); k2 = rhs(2 * i + 1, r + dt / 2 * k1[0], y + dt / 2 * k1[1])
        k3 = rhs(2 * i + 1, r + dt / 2 * k2[0], y + dt / 2 * k2[1]); k4 = rhs(2 * i + 2, r + dt * k3[0], y + dt * k3[1])
        r += dt / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]); y += dt / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return ys
def peaks(ys, k, dt=0.01):          # times of maxima, and the ratio of the 3rd to the 2nd swing above the final value
    yinf = k / (1 + k)
    ix = [i for i in range(1, len(ys) - 1) if ys[i] > ys[i - 1] and ys[i] >= ys[i + 1]]
    return (ix[2] - ix[1]) * dt, (ys[ix[2]] - yinf) / (ys[ix[1]] - yinf), ys[ix[0]] - yinf

wpc = bisect(lambda w: phase(w) + pi, 1e-6, 2.0)
gm = 1 / mag(wpc)
wgc = bisect(lambda w: mag(w) - 1, 1e-6, wpc)
pm = phase(wgc) + pi
dm = pm / wgc
print(f"loop: K = {KP} degC/% x {KC} %/degC = {K:.1f}; room lag {T1:.0f} min, radiator lag {T2:.0f} min, pipe delay {TH:.0f} min")
print(f"hand, phase crossover w = {wpc:.4f} rad/min: room {degrees(atan(wpc * T1)):.2f} deg, radiator {degrees(atan(wpc * T2)):.2f} deg, "
      f"pipe {degrees(wpc * TH):.2f} deg")
print(f"hand, total lag {-degrees(phase(wpc)):.2f} deg; |L| there = {K:.1f} / ({sqrt(1 + (wpc * T1) ** 2):.4f} x "
      f"{sqrt(1 + (wpc * T2) ** 2):.4f}) = {mag(wpc):.4f}")
print(f"gain margin  GM = {gm:.4f} = {20 * log10(gm):.2f} dB (a factor 2 is {20 * log10(2):.2f} dB); "
      f"real-axis crossing at {L(1j * wpc).real:.4f}")
print(f"hand, gain crossover w = {wgc:.4f} rad/min: room {degrees(atan(wgc * T1)):.2f} deg, radiator {degrees(atan(wgc * T2)):.2f} deg, "
      f"pipe {degrees(wgc * TH):.2f} deg")
print(f"phase margin PM = {degrees(pm):.2f} deg = {pm:.4f} rad; unit-circle crossing at {L(1j * wgc).real:.4f} {L(1j * wgc).imag:+.4f}j")
print(f"delay margin PM / wgc = {dm:.4f} min; periods 2 pi / wpc = {2 * pi / wpc:.2f} min, 2 pi / wgc = {2 * pi / wgc:.2f} min")
print(f"closest approach to -1: |1 + L| = {min(abs(1 + L(1j * i / 10000)) for i in range(1, 30000)):.4f}")
# ---- road 1: encirclements; road 2: rightmost closed-loop pole; road 3: simulation ----
reactor = lambda s: 2.0 / (s - 1.0)
print("case                         N cw   P   Z=N+P   Newton pole           sim period  swing ratio")
cases = (("thermostat K = 6.4", K, TH), ("gain x 2.1", 2.1 * K, TH), ("gain x 1.5, pipe +1 min", 1.5 * K, TH + 1.0))
res = {}
for name, k, th in cases:
    n = winding(lambda s: L(s, k, th)); s = root(k, th); per, ratio, first = peaks(simulate(k, th), k)
    res[name] = (n, s, per, ratio, first)
    print(f"{name:<27} {n:4d} {0:3d} {n:6d}    {s.real:+.4f} {s.imag:+.4f}j    {per:8.2f}  {ratio:9.4f}")
nr = winding(reactor)
print(f"{'reactor 2/(s - 1)':<27} {nr:4d} {1:3d} {nr + 1:6d}    {1.0 - 2.0:+.4f} {0.0:+.4f}j    {'-':>8}  {'-':>9}")
# ---- the two margins, by a second and third road ----
kcrit = bisect(lambda k: root(k, TH).real, K, 3 * K)
thcrit = bisect(lambda th: root(K, th).real, TH, 3 * TH)
pk, rk, _ = peaks(simulate(kcrit, TH), kcrit); pt, rt, _ = peaks(simulate(K, thcrit), K)
print(f"pole on the axis at gain {kcrit:.4f}: GM = {kcrit / K:.4f}, pole {root(kcrit, TH).imag:.4f}j; sim period {pk:.2f} min, ratio {rk:.4f}")
print(f"pole on the axis at delay {thcrit:.4f} min: margin {thcrit - TH:.4f} min, pole {root(K, thcrit).imag:.4f}j; "
      f"sim period {pt:.2f} min, ratio {rt:.4f}")
n0, s0, per0, ratio0, first0 = res["thermostat K = 6.4"]
ys = simulate(K, TH); yinf = K / (1 + K)
settle = max(i for i, y in enumerate(ys) if abs(y - yinf) > 0.02 * yinf) * 0.01
ipk = max(range(len(ys)), key=lambda i: ys[i])
print(f"1 degC step: settles at {yinf:.4f} degC; peak {ys[ipk]:.4f} degC at {ipk * 0.01:.2f} min, {first0:+.4f} above; "
      f"within 2% after {settle:.2f} min")
print(f"pole predicts swing ratio exp(re x period) = {exp(s0.real * 2 * pi / s0.imag):.4f}, period {2 * pi / s0.imag:.2f} min")
# ---- what breaks ----
print(f"wrong: drop the pipe delay: phase only nears -180 deg; PM {degrees(pm + wgc * TH):.2f} deg, GM none")
s6 = root(6 * K, TH, 0.6j)
print(f"wrong: read 6 dB as 'times 6': gain {6 * K:.1f}, pole {s6.real:+.4f} {s6.imag:+.4f}j, N = {winding(lambda s: L(s, 6 * K))}")
print(f"outside the model: a 10 degC setpoint step asks the valve for {KC * 10:.0f}% open")
# ---- try changing ----
for lab, k, th, t1, t2 in (("try: pipe 4 min", K, 4.0, T1, T2), ("try: gain 3.2", 3.2, TH, T1, T2),
                          ("try: room lag 25 min", K, TH, 25.0, T2), ("try: radiator lag 4 min", K, TH, T1, 4.0)):
    w1 = bisect(lambda w: phase(w, th, t1, t2) + pi, 1e-6, 2.0); w2 = bisect(lambda w: mag(w, k, t1, t2) - 1, 1e-6, w1)
    print(f"{lab}: GM {20 * log10(1 / mag(w1, k, t1, t2)):.2f} dB, PM {degrees(phase(w2, th, t1, t2) + pi):.2f} deg")
# ---- figures ----
full = (0, .005, .01, .015, .02, .03, .04, .05, .06, .08, .1, .12, .15, .18, .22, .26, .3, .35, .4, .47, .55, .65, .8, 1, 1.3, 1.7, 2.2, 3)
print("figure, full (px = 76 + 40 Re, py = 40 - 40 Im):", " ".join(f"{76 + 40 * L(1j * w).real:.1f},{40 - 40 * L(1j * w).imag:.1f}" for w in full))
zoom = (.19, .21, .24, .27, .3, .34, .38, .42, .47, .52, .58, .65, .73, .82, .92, 1.05, 1.2)
print("figure, zoom (px = 250 + 130 Re, py = 70 - 130 Im):", " ".join(f"{250 + 130 * L(1j * w).real:.1f},{70 - 130 * L(1j * w).imag:.1f}" for w in zoom))
print(f"figure, zoom marks: crossing {250 + 130 * L(1j * wpc).real:.1f},70.0  unit circle {250 + 130 * L(1j * wgc).real:.1f},"
      f"{70 - 130 * L(1j * wgc).imag:.1f}")
names = ("nominal", "gain x GM", "both at once")
runs = (simulate(K, TH), simulate(kcrit, TH), simulate(1.5 * K, TH + 1.0))
print("chart, t min       " + " ".join(f"{3 * i:5d}" for i in range(41)))
for nm, ys in zip(names, runs):
    print(f"chart, {nm:<12}" + " ".join(f"{ys[300 * i]:5.2f}" for i in range(41)))
for name, (n, s, per, ratio, first) in res.items():           # three roads agree on every verdict
    assert (n == 0) == (s.real < 0), name                      # encirclements vs the rightmost pole
    assert (s.real < 0) == (ratio < 1), name                   # the pole vs the simulated room
assert res["gain x 2.1"][0] == 2                               # two closed-loop poles cross over
assert nr == -1                                               # reactor: N = -1, P = 1 -> Z = 0, pole at -1
assert abs(kcrit / K - gm) < 1e-6                             # GM: frequency response vs pole on the axis
assert abs(root(kcrit, TH).imag - wpc) < 1e-6
assert abs((thcrit - TH) - dm) < 1e-6                         # PM: delay margin vs pole on the axis
assert abs(pk - 2 * pi / wpc) < 0.05                          # simulated at GM: swing at the crossover period
assert abs(rk - 1) < 0.01                                     # ... neither growing nor dying
assert abs(pt - 2 * pi / wgc) < 0.05                          # simulated at the delay margin, likewise
assert abs(rt - 1) < 0.01
assert abs(ratio0 - exp(s0.real * 2 * pi / s0.imag)) < 0.01   # simulated decay vs the Newton pole
print("ALL CHECKS PASS")
