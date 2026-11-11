# AC power and three phases -- the check behind the card.  Standard library only.
# A 5 kW motor at power factor 0.8 on 230 V, 50 Hz.  Every number on the card is
# printed here.  Road 1: the formulas.  Road 2: sample v(t) and i(t) over one cycle
# and average.  Road 3: simulate the motor as a resistor and inductor (RK4) and
# measure the power it draws.  Then three phases, sampled instant by instant.
from math import sqrt, cos, sin, acos, pi, degrees

V, f, P, pf = 230.0, 50.0, 5000.0, 0.8        # rms volts, hertz, watts, cos(phi)
w = 2 * pi * f                                # angular frequency, radians per second
T = 1 / f                                     # one cycle, seconds
phi = acos(pf)                                # current lags the voltage by phi

# ---- road 1: the formulas ----
S = P / pf
Q = S * sin(phi)
I = S / V
R, X = P / I**2, Q / I**2                     # the motor seen as resistance and reactance
L = X / w

def v(t, shift=0.0): return sqrt(2) * V * cos(w * t - shift)
def i(t, shift=0.0): return sqrt(2) * I * cos(w * t - phi - shift)

# ---- road 2: sample one cycle and average ----
n = 40000
ts = [k * T / n for k in range(n)]
P_avg = sum(v(t) * i(t) for t in ts) / n
S_rms = sqrt(sum(v(t)**2 for t in ts) / n) * sqrt(sum(i(t)**2 for t in ts) / n)
Q_avg = sum(v(t - T / 4) * i(t) for t in ts) / n        # voltage a quarter cycle late
def rms(g): return sqrt(sum(g(t)**2 for t in ts) / n)
p_one = [v(t) * i(t) for t in ts]

# ---- road 3: L di/dt = v - R i, from rest, ten cycles by RK4 ----
def didt(t, cur): return (v(t) - R * cur) / L
h, cur, t, P_sim, V2_sim, I2_sim = T / 2000, 0.0, 0.0, 0.0, 0.0, 0.0
for k in range(10 * 2000):
    if k >= 9 * 2000:
        P_sim += v(t) * cur / 2000                       # average over the last cycle
        V2_sim += v(t)**2 / 2000; I2_sim += cur**2 / 2000
    if L == 0:                                           # pf 1: no inductance, current follows v / R
        cur = v(t + h) / R; t += h; continue
    k1 = didt(t, cur); k2 = didt(t + h/2, cur + h*k1/2)
    k3 = didt(t + h/2, cur + h*k2/2); k4 = didt(t + h, cur + h*k3)
    cur += h * (k1 + 2*k2 + 2*k3 + k4) / 6
    t += h
pf_sim = P_sim / (sqrt(V2_sim) * sqrt(I2_sim))           # power factor, measured back

# ---- three phases: 230 V to neutral, 120 degrees apart, a third of the load each ----
sh = [0.0, 2*pi/3, 4*pi/3]
I3 = (P / 3) / pf / V
def i3(t, k, size=I3): return sqrt(2) * size * cos(w * t - phi - sh[k])
VL = sqrt(3) * V
VL_s = rms(lambda t: v(t) - v(t, sh[1]))
P3 = sqrt(3) * VL * I3 * pf
IN_ph = sqrt(sum(cos(phi + s) for s in sh)**2 + sum(sin(phi + s) for s in sh)**2) * I3
IN_s = max(abs(sum(i3(t, k) for k in range(3))) for t in ts)
p3 = [sum(v(t, sh[k]) * i3(t, k) for k in range(3)) for t in ts]
loss1, loss3 = 2 * I**2 * 0.1, 3 * I3**2 * 0.1          # 0.1 ohm in every wire
IN_off = rms(lambda t: i3(t, 0) + i3(t, 1))                     # phase c switched off
IN_half = rms(lambda t: i3(t, 0) + i3(t, 1) + i3(t, 2, I3 / 2))
IN_h3 = rms(lambda t: sum(sqrt(2) * 3 * cos(3 * (w * t - s)) for s in sh))

rows = [("phase angle phi, degrees", degrees(phi)), ("sin phi", sin(phi)),
        ("omega, rad/s", w), ("peak V, V", sqrt(2) * V), ("peak I, A", sqrt(2) * I),
        ("1 formula   S = P / pf, VA", S), ("1 formula   Q = S sin phi, var", Q),
        ("1 formula   I = S / V, A", I), ("  I sin phi, quarter-cycle part, A", I * sin(phi)),
        ("2 samples   P = mean of v i, W", P_avg), ("2 samples   S = rms v x rms i, VA", S_rms),
        ("2 samples   Q = mean of v(t-T/4) i, var", Q_avg),
        ("3 circuit   P drawn by R and L, W", P_sim),
        ("3 circuit   pf = P / (rms v x rms i)", pf_sim),
        ("  R, ohm", R), ("  X, ohm", X), ("  L, mH", L * 1000),
        ("  p(t) lowest sample, W", min(p_one)), ("  p(t) highest sample, W", max(p_one)),
        ("current at pf 1, A", P / V), ("wire loss ratio pf 0.8 : pf 1", (I / (P / V))**2),
        ("three-phase current per line, A", I3), ("line voltage sqrt3 V, V", VL),
        ("line voltage, sampled, V", VL_s), ("P = sqrt3 V_L I_L pf, W", P3),
        ("neutral, phasor sum, A", IN_ph), ("neutral, largest sample, A", IN_s),
        ("three-phase p(t) lowest, W", min(p3)), ("three-phase p(t) highest, W", max(p3)),
        ("wire loss single-phase, W", loss1), ("wire loss three-phase, W", loss3),
        ("unbalanced: phase c off, neutral, A", IN_off),
        ("unbalanced: phase c half, neutral, A", IN_half),
        ("third harmonic 3 A each, neutral, A", IN_h3),
        ("wrong: P = V I, W", V * I), ("wrong: S = P + Q, VA", P + Q),
        ("wrong: I = P / (3 V_L pf), A", P / (3 * VL * pf)),
        ("wrong: neutral = sum of sizes, A", 3 * I3),
        ("wrong: peak V x peak I x pf, W", 2 * V * I * pf),
        ("try: pf 0.5, current, A", P / 0.5 / V), ("try: pf 0.5, S, VA", P / 0.5), ("try: pf 1, Q, var", P / 1.0 * sin(acos(1.0))),
        ("try: 60 Hz, L, mH", X / (2 * pi * 60) * 1000)]
for label, val in rows:
    print(f"{label:<40}{val:12.4f}")
ms = [k * n // 20 for k in range(21)]                     # 0, 1, ..., 20 ms
print("chart, single-phase p(t), W " + " ".join(str(round(p_one[k % n])) for k in ms))
print("chart, three-phase p(t), W  " + " ".join(str(round(p3[k % n])) for k in ms))

assert abs(P_avg - P) < 1e-6 and abs(S_rms - S) < 1e-6,   "sampled averages vs formulas"
assert abs(Q_avg - Q) < 1e-6,                             "quarter-cycle average vs S sin phi"
assert abs(P_sim - P) < 0.01,                             "simulated motor draws 5 kW"
assert abs(pf_sim - pf) < 1e-5,                           "simulated motor's power factor is 0.8"
assert abs(VL_s - VL) < 1e-6,                             "sampled line voltage vs sqrt3 V"
assert IN_ph < 1e-9 and IN_s < 1e-9,                      "balanced neutral carries nothing"
assert max(p3) - min(p3) < 1e-6 and abs(p3[0] - P) < 1e-6, "three-phase power is flat at P"
assert abs(min(p_one) - (P - S)) < 1e-3,                  "single-phase dips to P - S"
assert abs(loss1 / loss3 - 6) < 1e-9,                     "three wires: a sixth of the loss"
print("ALL CHECKS PASS")
