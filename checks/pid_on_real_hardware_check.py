# PID in practice: a room, a slow radiator pipe, and a valve that stops at fully open. Standard library only.
# Units: minutes, °C, kW; valve opening 0 (shut) to 1 (wide open). Simulations: RK4, 0.01 min step.
# Road 1: closed forms (pinned valve solved exactly, integral-area identity, lag formulas). Road 2: simulation
# of the same room, no formula inside it. Derivative noise: variance formula, Parseval, Monte Carlo.
import math

G, C, QM, TQ = 0.2, 6.0, 6.0, 4.0     # loss kW/°C, heat capacity kW·min/°C, radiator max kW, radiator lag min
TR, DT = C / G, 0.01                   # room time constant: 30 min; simulation step, min
KP, KI = 0.125, 0.125 / 15.0           # valve per °C; valve per °C per min (integral time 15 min)
KPO, KIO, KIN = KP * QM, KI * QM, 8.0 / QM   # cascade: outer asks for kW; inner valve per kW, integral time TQ

def sim(r, T0, tout0, tout, d, tend, limit=True, aw=False, ff=0.0, cascade=False, fb=True):
    """Steady at room T0, outdoor tout0; at t = 0 outdoor becomes tout and the radiator loses d kW."""
    Q0 = G * (T0 - tout0)
    x = [T0, Q0, Q0 - ff * Q0 if cascade else (Q0 - ff * Q0) / QM, Q0 / QM]
    sat = lambda v, hi: min(max(v, 0.0), hi) if limit else v
    def f(x):
        T, Q, xo, xi = x
        e = r - T if fb else 0.0
        if cascade:                                    # outer PI asks for heat; inner PI moves the valve
            qv = ff * G * (r - tout) + KPO * e + xo; qr = sat(qv, QM); eq = qr - Q
            v = KIN * eq + xi; u = sat(v, 1.0)
            dxo = 0.0 if aw and qv != qr and e * (qv - qr) > 0 else KIO * e
            dxi = 0.0 if aw and v != u and eq * (v - u) > 0 else KIN / TQ * eq
        else:
            v = ff * G * (r - tout) / QM + KP * e + xo; u = sat(v, 1.0)
            dxo, dxi = (0.0 if aw and v != u and e * (v - u) > 0 else KI * e), 0.0
        return [(Q - G * (T - tout)) / C, (QM * u - d - Q) / TQ, dxo, dxi], v
    out = [[T0], [Q0], [x[2]], []]                     # room, radiator, outer integral, valve demand
    for _ in range(int(round(tend / DT))):
        k1, v = f(x)
        k2 = f([a + DT / 2 * b for a, b in zip(x, k1)])[0]
        k3 = f([a + DT / 2 * b for a, b in zip(x, k2)])[0]
        k4 = f([a + DT * b for a, b in zip(x, k3)])[0]
        x = [a + DT / 6 * (p + 2 * q + 2 * w + z) for a, p, q, w, z in zip(x, k1, k2, k3, k4)]
        out[0].append(x[0]); out[1].append(x[1]); out[2].append(x[2]); out[3].append(v)
    return out
def bisect(fn, lo, hi):
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if (fn(lo) > 0) == (fn(mid) > 0) else (lo, mid)
    return (lo + hi) / 2
def cross(ys, level):                     # first time ys falls through level, interpolated
    i = next(i for i in range(1, len(ys)) if ys[i] <= level)
    return (i - 1 + (ys[i - 1] - level) / (ys[i - 1] - ys[i])) * DT
def peak(ys, sign=1):
    i = max(range(len(ys)), key=lambda i: sign * ys[i])
    return ys[i], i * DT
row = lambda lab, ys: print(f"{lab:<24}" + " ".join(f"{ys[i]:.2f}" for i in range(0, 9001, 500)))
trap = lambda ys, n: sum((2 * r - ys[i] - ys[i + 1]) * DT / 2 for i in range(n))   # area of the error
# ---- 1. cold morning: outdoor -5 °C, setpoint raised from 15 to 21 °C ----
r, T0, to = 21.0, 15.0, -5.0
Q0, Teq, x0, x1 = G * (T0 - to), to + QM / G, G * (T0 - to) / QM, G * (r - to) / QM
B = (QM - Q0) / C * TQ * TR / (TR - TQ); D = T0 - Teq - B   # open-valve room: Teq + B e^(-t/TQ) + D e^(-t/TR)
T_open = lambda t: Teq + B * math.exp(-t / TQ) + D * math.exp(-t / TR)
area_open = lambda t: (r - Teq) * t - B * TQ * (1 - math.exp(-t / TQ)) - D * TR * (1 - math.exp(-t / TR))
xo_open = lambda t: x0 + KI * area_open(t)
t_wind = bisect(lambda t: KP * (r - T_open(t)) + xo_open(t) - 1.0, 0.0, 200.0)
t_clamp = bisect(lambda t: KP * (r - T_open(t)) + x0 - 1.0, 0.0, 200.0)
t_c = bisect(lambda t: T_open(t) - r, 0.0, 200.0)
lin, wnd, clp = (sim(r, T0, to, to, 0.0, 300, limit=lim, aw=aw) for lim, aw in ((False, False), (True, False), (True, True)))
print(f"before: radiator {Q0:.2f} kW, valve {x0:.4f}; after: needs {G * (r - to):.2f} kW, valve {x1:.4f}")
print(f"first valve demand {KP * (r - T0) + x0:.4f}; wide open the room heads for {Teq:.2f} °C")
print(f"open-valve room: T = {Teq:.2f} + {B:.4f} e^(-t/{TQ:.0f}) {D:+.4f} e^(-t/{TR:.0f})")
ar = [trap(run[0], len(run[0]) - 1) for run in (lin, wnd, clp)]; sw = cross(wnd[3], 1.0)
print(f"windup: valve pinned until {t_wind:.3f} min (formula), {sw:.3f} min (sim)")
print(f"windup: room crosses 21 at {t_c:.3f} min; integral peaks at {xo_open(t_c):.4f} (formula), {max(wnd[2]):.4f} (sim)")
print(f"windup: area banked while pinned {area_open(t_wind):.1f} °C·min (formula), {trap(wnd[0], round(t_wind / DT)):.1f} (sim)")
print(f"clamped: valve pinned until {t_clamp:.3f} min (formula), {cross(clp[3], 1.0):.3f} min (sim), room {r - (1 - x0) / KP:.3f} °C")
print(f"area identity: change in valve / KI = ({x1:.4f} - {x0:.4f}) / {KI:.6f} = {(x1 - x0) / KI:.3f} °C·min; "
      f"left to repay after the valve frees {area_open(t_wind) - (x1 - x0) / KI:.1f} °C·min")
for lab, run, a in (("no valve limit", lin, ar[0]), ("limit, no anti-windup", wnd, ar[1]), ("limit, clamping", clp, ar[2])):
    pk, tp = peak(run[0])
    st = max(i for i in range(len(run[0])) if abs(run[0][i] - r) > 0.2) * DT
    print(f"{lab:<22} peak {pk:.2f} °C at {tp:5.1f} min, within 0.2 °C after {st:5.1f} min, area {a:6.3f}")
row("chart, no valve limit", lin[0]); row("chart, no anti-windup", wnd[0]); row("chart, clamping", clp[0])
# ---- 2. cold front: outdoor 0 -> -6 °C with the room at 21 °C; feedforward from an outdoor sensor ----
dto, tstar = -6.0, math.log(TR / TQ) * TR * TQ / (TR - TQ)
ffpk = dto * TQ / (TR - TQ) * (math.exp(-tstar / TR) - math.exp(-tstar / TQ))
runs = {k: sim(r, r, 0.0, dto, 0.0, 300, ff=g, fb=fb) for k, g, fb in
        (("feedback only", 0.0, True), ("feedforward only", 1.0, False), ("both", 1.0, True),
         ("ff 30% low, alone", 0.7, False), ("ff 30% low, with fb", 0.7, True))}
print(f"feedforward only, formula: dip {ffpk:.4f} °C at {tstar:.3f} min; steady error if 30% low {0.3 * dto:.2f} °C")
for k, run in runs.items():
    pk, tp = peak(run[0], -1)
    print(f"cold front, {k:<20} lowest {pk:.4f} °C at {tp:6.2f} min, at 300 min {run[0][-1]:.4f} °C")
for k in ("feedback only", "feedforward only", "both"): row("chart, " + k, runs[k][0])
# ---- 3. supply water cools: the radiator loses 1.2 kW at the same valve; one loop against a cascade ----
dq, ts = 1.2, TQ * math.log(8.0) / 7.0
qpk = -dq / 7.0 * (math.exp(-ts / TQ) - math.exp(-8.0 * ts / TQ))
qmin, tq_ = peak(sim(r, r, 0.0, 0.0, dq, 30, cascade=True, fb=False)[1], -1)
print(f"inner loop time {TQ / (KIN * QM):.2f} min; inner loop alone: radiator dips {qpk:.4f} kW at {ts:.3f} min (formula), {qmin - G * r:.4f} kW at {tq_:.3f} (sim)")
for lab, cas in (("single loop", False), ("cascade", True)):
    run = sim(r, r, 0.0, 0.0, dq, 300, cascade=cas, aw=True)
    pk, tp = peak(run[0], -1)
    print(f"supply drop, {lab:<12} room lowest {pk:.4f} °C at {tp:6.2f} min, radiator lowest {min(run[1]):.4f} kW")
# ---- 4. derivative on a noisy thermometer: KD = KP x 2 min, sensor noise 0.05 °C rms, seed 2026 ----
KD, SIG, M64, state = KP * 2.0, 0.05, (1 << 64) - 1, 2026
def unif():                                        # SplitMix64, mapped to (0, 1)
    global state
    state = z = (state + 0x9E3779B97F4A7C15) & M64
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
gauss = lambda: math.sqrt(-2.0 * math.log(unif())) * math.cos(2.0 * math.pi * unif())   # Box-Muller
noise, pms = [], []
for h in (0.1, 0.01):
    for tf in (0.0, 0.2):
        a, b, n = tf / (tf + h), KD / (tf + h), 2000
        formula = b * SIG * math.sqrt(2.0 / (1.0 + a))
        hp = lambda th: b * b * (2 - 2 * math.cos(th)) / (1 - 2 * a * math.cos(th) + a * a)
        par = SIG * math.sqrt(sum((1 if j in (0, n) else 4 if j % 2 else 2) * hp(j * math.pi / n)
                                  for j in range(n + 1)) * (math.pi / n) / 3 / math.pi)
        prev, dv, acc = gauss() * SIG, 0.0, 0.0
        for k in range(100100):
            y = gauss() * SIG
            dv, prev = a * dv + b * (y - prev), y
            acc += dv * dv if k >= 100 else 0.0
        noise.append((formula, par, math.sqrt(acc / 100000)))
        print(f"derivative, h {h:.2f} min, filter {tf:.1f} min, a {a:.4f}, b {b:.4f}: jitter {formula:.4f} formula, "
              f"{par:.4f} Parseval, {noise[-1][2]:.4f} Monte Carlo")
print(f"radiator law (Tw - T)^1.3, water 60 °C: output at 25 °C room / at 15 °C room = {(35 / 45) ** 1.3:.4f}")
def lm(w, kd, tf):                                 # |L| and arg L of the loop with no valve limit, C(jw) G(jw)
    cr, ci = KP + kd * tf * w * w / (1 + tf * tf * w * w), kd * w / (1 + tf * tf * w * w) - KI / w
    return math.sqrt(cr * cr + ci * ci) * QM / G / math.sqrt((1 + TQ * TQ * w * w) * (1 + TR * TR * w * w)), math.atan2(ci, cr) - math.atan(TQ * w) - math.atan(TR * w)
for lab, kd, tf in (("PI", 0.0, 0.0), ("PID, raw derivative", KD, 0.0), ("PID, D filtered 0.2 min", KD, 0.2)):
    wc = bisect(lambda w: lm(w, kd, tf)[0] - 1.0, 0.01, 1.0); pms.append(180.0 + math.degrees(lm(wc, kd, tf)[1]))
    print(f"margins, {lab:<23} crossover {wc:.4f} rad/min, phase margin {pms[-1]:.2f} deg")

assert abs(t_wind - sw) < 0.01, "pinned-valve time: exact solution against simulation"
assert abs(ar[1] - (x1 - x0) / KI) < 0.01, "windup run must pay back exactly the identity's area"
assert abs(xo_open(t_c) - max(wnd[2])) < 1e-4, "integral peak: exact solution against simulation"
assert abs(t_clamp - cross(clp[3], 1.0)) < 0.01, "clamped release time: exact solution against simulation"
assert abs(ffpk - peak(runs["feedforward only"][0], -1)[0] + r) < 1e-4, "feedforward dip: formula against sim"
assert abs(runs["ff 30% low, alone"][0][-1] - r - 0.3 * dto) < 1e-3, "30% low feedforward: steady error against sim"
assert abs(qpk - (qmin - G * r)) < 1e-4, "inner-loop dip: formula against sim"
assert all(abs(p - f) < 1e-6 for f, p, m in noise), "Parseval integral against the variance formula"
assert all(abs(m - f) < 0.03 * f for f, p, m in noise), "Monte Carlo within 3% (a few standard errors)"
assert abs(pms[2] - pms[1]) < 1.0, "a 0.2 min derivative filter moves the phase margin by under 1 deg"
print("ALL CHECKS PASS")
