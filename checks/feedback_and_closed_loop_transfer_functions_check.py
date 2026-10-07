# Feedback and closed-loop transfer functions -- the check behind the card.  Standard library only.
# A room heated by a radiator, read by a thermostat, round one loop.  Time in minutes, s in 1/min.
# Deviations from 20 C inside, 5 C outside, 1500 W of heat.  Blocks:
#   radiator 5 q' = -q + u (W), room 20 T' = -T + q/100 + d (C), sensor 1 m' = -m + T (C), u = Kc (r - m).
# Roads: block algebra and residues at the closed-loop poles; an RK4 simulation of the wired-up loop
# that never uses a transfer function; the frequency response against a sine-driven simulation.
import math

TR, TM, TS, UA, KC = 5.0, 20.0, 1.0, 100.0, 500.0   # lags min, loss W/K, thermostat gain W/K
DT, QLO, QHI = 0.01, -1500.0, 1000.0                # RK4 step min; radiator range 0..2500 W as a deviation

def poly_mul(a, b):                                  # product of two polynomials, highest power first
    out = [0.0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] += x * y
    return out
def peval(a, s):                                     # Horner's rule, real or complex s
    v = 0j
    for c in a:
        v = v * s + c
    return v
def roots(a, iters=500):                             # Durand-Kerner: all roots at once
    a = [c / a[0] for c in a]
    n = len(a) - 1
    r = [complex(0.4, 0.9) ** i for i in range(n)]
    for _ in range(iters):
        new = []
        for i, x in enumerate(r):
            den = 1 + 0j
            for j in range(n):
                if j != i:
                    den *= x - r[j]
            new.append(x - peval(a, x) / den)
        r = new
    return sorted(r, key=lambda z: (z.real, z.imag))

OPEN = poly_mul(poly_mul([TR, 1.0], [TM, 1.0]), [TS, 1.0])   # (5s+1)(20s+1)(s+1)
def char(k):                                         # closed-loop denominator: open-loop one plus k
    return OPEN[:-1] + [OPEN[-1] + k]

def L(s): return KC / (TR * s + 1) / UA / (TM * s + 1) / (TS * s + 1)   # loop: thermostat, radiator, room, sensor
def tyr(s): return KC / (TR * s + 1) / UA / (TM * s + 1) / (1 + L(s))   # setpoint to room: forward path over 1 + L
def tyd(s): return 1 / (TM * s + 1) / (1 + L(s))                        # outside air to room: its path over 1 + L

def step_by_residues(num, k, t):                     # inverse transform of num(s)/(s char(s))
    den = char(k)
    dd = [c * (len(den) - 1 - i) for i, c in enumerate(den[:-1])]
    y = peval(num, 0).real / den[-1]
    for p in roots(den):
        y += (peval(num, p) / (p * peval(dd, p)) * math.e ** (p * t)).real
    return y

def clean(v): return round(v, 9) + 0.0              # round off float dust so -0.0000 never prints

def loop(r, d, kc=KC, sat=False, sensor=True, sign=1.0):
    def f(t, x):
        q, temp, m = x
        u = kc * (r(t) - sign * (m if sensor else temp))
        u = min(QHI, max(QLO, u)) if sat else u
        f.peak = max(f.peak, abs(u))
        return [(u - q) / TR, (q / UA - temp + d(t)) / TM, (temp - m) / TS if sensor else 0.0]
    f.peak = 0.0
    return f

def run(f, t_end, x=(0.0, 0.0, 0.0)):                # RK4; returns room temperature at every step
    x, out = list(x), [x[1]]
    for i in range(round(t_end / DT)):
        t = i * DT
        k1 = f(t, x)
        k2 = f(t + DT / 2, [a + DT / 2 * b for a, b in zip(x, k1)])
        k3 = f(t + DT / 2, [a + DT / 2 * b for a, b in zip(x, k2)])
        k4 = f(t + DT, [a + DT * b for a, b in zip(x, k3)])
        x = [a + DT / 6 * (p + 2 * q + 2 * w + z) for a, p, q, w, z in zip(x, k1, k2, k3, k4)]
        out.append(x[1])
    return out

one, zero, cold = (lambda t: 1.0), (lambda t: 0.0), (lambda t: -5.0)
k = KC / UA
print(f"room: lags radiator {TR:.0f} min, room {TM:.0f} min (heat capacity {TM * 60 * UA / 1000:.0f} kJ/K), thermostat {TS:.0f} min; loss {UA:.0f} W/K; Kc {KC:.0f} W/K")
print(f"operating point: 20 C inside, 5 C outside, {UA * 15:.0f} W of heat; radiator range 0 to {UA * 15 + QHI:.0f} W")
print(f"loop gain L(s) = {k:.0f} / ((5s+1)(20s+1)(s+1)), s in 1/min; L(0) = {L(0).real:.0f}")
print(f"closed-loop denominator: {char(k)[0]:.0f} s^3 + {char(k)[1]:.0f} s^2 + {char(k)[2]:.0f} s + {char(k)[3]:.0f}")
p = roots(char(k))
print(f"closed-loop poles (1/min): {p[0].real:.4f} and {p[1].real:.4f} +/- {abs(p[1].imag):.4f}j")
print(f"dominant pair: decay time {-1 / p[1].real:.2f} min, swing period {2 * math.pi / abs(p[1].imag):.2f} min, damping ratio {-p[1].real / abs(p[1]):.3f}")
print(f"steady state: setpoint +1 C gives room {tyr(0).real:.4f} C, error {1 / (1 + k):.4f} C; outside 5 C colder gives room {-5 * tyd(0).real:.4f} C, open loop -5.0000 C")
fr, fd = loop(one, zero), loop(zero, cold)
yr, yd = run(fr, 400.0), run(fd, 400.0)
print(f"simulated at 400 min: setpoint +1 C -> {yr[-1]:.4f} C; outside 5 C colder -> {yd[-1]:.4f} C")
print(f"largest radiator demand: {fr.peak:.0f} W and {fd.peak:.0f} W, inside the {QHI:.0f} W of headroom")
print("t min | setpoint +1 C: residues | RK4 | heater +100 W, no loop | outside 5 C colder: residues | RK4 | no loop")
rows = []
for t in range(0, 81, 5):
    a, b = step_by_residues([k * TS, k], k, t), yr[round(t / DT)]
    c, e = -5 * step_by_residues(poly_mul([TR, 1.0], [TS, 1.0]), k, t), yd[round(t / DT)]
    o1, o2 = 1 - (TM * math.exp(-t / TM) - TR * math.exp(-t / TR)) / (TM - TR), -5 * (1 - math.exp(-t / TM))
    rows.append((a, b, o1, c, e, o2))
    print(f"{t:2d} | {clean(a):.4f} | {b:.4f} | {o1:.4f} | {clean(c):.4f} | {clean(e):.4f} | {clean(o2):.4f}")
for lab, i in (("setpoint +1 C, loop", 0), ("heater +100 W, no loop", 2), ("outside 5 C colder, loop", 3), ("outside 5 C colder, no loop", 5)):
    print(f"figure, {lab}, every 5 min: " + ", ".join(f"{clean(row[i]):.2f}" for row in rows))
fine = [step_by_residues([k * TS, k], k, i / 100) for i in range(4001)]
pk = max(range(4001), key=lambda i: fine[i])
print(f"setpoint +1 C peak: {fine[pk]:.4f} C at {pk / 100:.2f} min (residues), {max(yr):.4f} C (RK4)")
print("frequency response, setpoint to room: period | gain formula | gain from sine-driven RK4 | phase deg formula | RK4")
freq = []
for per in (60.0, 20.0):
    w = 2 * math.pi / per
    g = tyr(1j * w)
    y = run(loop(lambda t: math.sin(w * t), zero), 600.0)
    n, j0 = round(per / DT), len(y) - 1 - round(per / DT)    # project the last full cycle on sin and cos
    a = sum(y[j] * math.sin(w * j * DT) for j in range(j0, j0 + n)) * 2 / n
    b = sum(y[j] * math.cos(w * j * DT) for j in range(j0, j0 + n)) * 2 / n
    freq.append((abs(g), math.hypot(a, b), math.degrees(math.atan2(g.imag, g.real)), math.degrees(math.atan2(b, a))))
    print(f"{per:.0f} min ({w:.4f} rad/min) | {freq[-1][0]:.4f} | {freq[-1][1]:.4f} | {freq[-1][2]:.2f} | {freq[-1][3]:.2f}")
print("gain sweep: k = L(0) | steady error per 1 C | room drop for outside 5 C colder | largest pole real part 1/min")
crit = sum((TR, TM, TS)) * sum((1 / TR, 1 / TM, 1 / TS)) - 1
for kk in (1.0, 5.0, 10.0, 20.0, crit, 35.0):
    print(f"k = {kk:4.1f} | {1 / (1 + kk):.4f} C | {5 / (1 + kk):.4f} C | {clean(roots(char(kk))[-1].real):+.4f}")
print(f"critical loop gain from the coefficients: k = (sum of lags)(sum of 1/lags) - 1 = {crit:.1f}, Kc = {crit * UA:.0f} W/K")
pos, ypos, ycap = roots(char(-k))[-1].real, run(loop(one, zero, sign=-1.0), 30.0), run(loop(one, zero, sign=-1.0, sat=True), 600.0)
print(f"mistake 1, feedback sign flipped: 1+L becomes 1-L, L/(1-L) at s=0 reads {k / (1 - k):.2f}; pole +{pos:.4f} 1/min; room after 30 min {ypos[-1]:+.1f} C; radiator capped, after 600 min {ycap[-1]:+.1f} C, full open")
yhi, ycyc = run(loop(one, zero, kc=3500.0), 300.0), run(loop(one, zero, kc=3500.0, sat=True), 750.0)
sw = [max(abs(v - 35 / 36) for v in yhi[round(a / DT):round((a + 100) / DT)]) for a in (0.0, 100.0, 200.0)]
cy = [f(ycyc[round(a / DT):round((a + 250) / DT)]) for a in (250.0, 500.0) for f in (min, max)]   # capped: the swing in two later windows
print(f"mistake 2, Kc = 3500 W/K (k = 35): swing about {35 / 36:.4f} C, largest in 0-100, 100-200, 200-300 min: {sw[0]:.3f}, {sw[1]:.3f}, {sw[2]:.3f} C; radiator capped, room between {cy[0]:.3f} and {cy[1]:.3f} C in 250-500 min, {cy[2]:.3f} and {cy[3]:.3f} C in 500-750 min")
cold15 = lambda t: -15.0
lin, sat = run(loop(zero, cold15), 400.0), run(loop(zero, cold15, sat=True), 400.0)
hand = (1500.0 + QHI) / UA + (5.0 - 15.0) - 20.0     # radiator flat out: 100 (T + 10) = 2500 W
print(f"mistake 3, outside 15 C colder (-10 C), radiator capped at 2500 W: linear loop {lin[-1]:.4f} C, capped {sat[-1]:.4f} C, hand {hand:.4f} C")
nos = run(loop(one, zero, sensor=False), 400.0)
print(f"mistake 4, thermostat lag left out: peak {max(nos):.4f} C, true loop {max(yr):.4f} C; steady {nos[-1]:.4f} C both")
for a, b, _, c, e, _ in rows:                              # residues of the closed-loop ratio against the wired-up loop
    assert abs(a - b) < 1e-6 and abs(c - e) < 1e-6
assert abs(yr[-1] - KC / UA / (1 + KC / UA)) < 1e-6 and abs(yd[-1] + 5 / (1 + KC / UA)) < 1e-6
for g, gs, ph, phs in freq:                          # frequency response against sine-driven simulation
    assert abs(g - gs) < 1e-4 and abs(ph - phs) < 0.05
assert abs(roots(char(crit))[-1].real) < 1e-9 and roots(char(crit - 0.5))[-1].real < 0 < roots(char(crit + 0.5))[-1].real
assert abs(sat[-1] - hand) < 1e-3 and sw[2] > sw[1] > sw[0] and ypos[-1] > 10.0 and abs(ycap[-1] - QHI / UA) < 1e-3
print("ALL CHECKS PASS")
