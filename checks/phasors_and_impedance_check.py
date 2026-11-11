# Phasors and impedance -- the check behind the card.  Standard library only.
# 230 V rms, 50 Hz mains through a 40-ohm resistor and a 95.49 mH coil in series.
# Roads to the current: one complex division; the same sum done with real cosine and
# sine coefficients; and an RK4 simulation of L di/dt + R i = v(t), measured like a meter.
from math import pi, sqrt, cos, sin, atan2, exp, degrees

F, VRMS, R = 50.0, 230.0, 40.0              # hertz, volts rms, ohms
L = 0.3 / pi                                # henries: 95.49 mH, so 30 ohms at 50 Hz
W = 2 * pi * F                              # angular frequency, rad/s
VPK = VRMS * sqrt(2)                        # peak of the mains wave

def current(f, r, l, c=None, vrms=VRMS):    # road 1: phasor I = V / Z, rms
    w = 2 * pi * f
    z = complex(r, w * l - (1 / (w * c) if c else 0.0))
    return vrms / z, z

def real_pair(f, r, l):                     # road 2: i = a cos wt + b sin wt, peak amps
    x = 2 * pi * f * l                      # match cos and sin terms: r a + x b = VPK, -x a + r b = 0
    a = VPK * r / (r * r + x * x)
    return a, VPK * x / (r * r + x * x)

def simulate(cycles=10, n=2000):            # road 3: RK4 from switch-on at a voltage peak
    T = 1 / F; h = T / n
    rhs = lambda t, i: (VPK * cos(W * t) - R * i) / L
    t, i, trace = 0.0, 0.0, [0.0]
    for _ in range(cycles * n):
        k1 = rhs(t, i); k2 = rhs(t + h / 2, i + h * k1 / 2)
        k3 = rhs(t + h / 2, i + h * k2 / 2); k4 = rhs(t + h, i + h * k3)
        i += h * (k1 + 2 * k2 + 2 * k3 + k4) / 6; t += h
        trace.append(i)
    last = range(len(trace) - 1 - n, len(trace) - 1)       # the final whole cycle
    ca = 2 / n * sum(trace[k] * cos(W * k * h) for k in last)
    cb = 2 / n * sum(trace[k] * sin(W * k * h) for k in last)
    irms = sqrt(sum(trace[k] ** 2 for k in last) / n)
    vr = sqrt(sum((R * trace[k]) ** 2 for k in last) / n)
    vl = sqrt(sum((VPK * cos(W * k * h) - R * trace[k]) ** 2 for k in last) / n)
    return trace, h, ca, cb, irms, vr, vl

I, Z = current(F, R, L)
X = W * L
mag, lag = abs(I), -atan2(I.imag, I.real)
VR, VL = I * R, I * complex(0, X)
a, b = real_pair(F, R, L)
trace, h, ca, cb, irms_sim, vr_sim, vl_sim = simulate()
tau = L / R
ipk = mag * sqrt(2)
steady = lambda t: ipk * cos(W * t - lag)
first = max(abs(v) for v in trace[:2001])
t10 = int(round(0.010 / h))
gap10 = trace[t10] - steady(t10 * h)
gap10_exact = -ipk * cos(lag) * exp(-0.010 / tau)

wrong_add = VRMS / (R + X)                  # R and X added as plain ohms
wrong_noL = VRMS / R                        # coil ignored
wrong_fL = abs(current(F, R, L / (2 * pi))[0])   # X = f L, the 2 pi forgotten
wrong_meters = abs(VR) + abs(VL)            # the two meter readings added

I60 = current(60.0, R, L)[0]
I2L = current(F, R, 2 * L)[0]
C = 1 / (W * X)                             # the capacitor whose -30 ohms cancels the coil
Icap = current(F, R, L, C)[0]

rows = [
    ("mains peak, V", VPK), ("omega, rad/s", W), ("coil L, mH", L * 1000), ("reactance X, ohm", X),
    ("Z real, ohm", Z.real), ("Z imag, ohm", Z.imag), ("|Z|, ohm", abs(Z)),
    ("angle of Z, deg", degrees(atan2(Z.imag, Z.real))),
    ("1 phasor: I real, A rms", I.real), ("1 phasor: I imag, A rms", I.imag),
    ("1 phasor: |I|, A rms", mag), ("1 phasor: lag, deg", degrees(lag)),
    ("  lag, rad", lag), ("  lag, ms", lag / W * 1000), ("  peak current, A", ipk),
    ("2 real pair: cos part a, A", a), ("2 real pair: sin part b, A", b),
    ("2 real pair: peak, A", sqrt(a * a + b * b)), ("2 real pair: lag, deg", degrees(atan2(b, a))),
    ("3 simulated: cos part, A", ca), ("3 simulated: sin part, A", cb),
    ("3 simulated: rms current, A", irms_sim), ("3 simulated: lag, deg", degrees(atan2(cb, ca))),
    ("resistor voltage |VR|, V rms", abs(VR)), ("coil voltage |VL|, V rms", abs(VL)),
    ("3 simulated meter on R, V rms", vr_sim), ("3 simulated meter on L, V rms", vl_sim),
    ("VR + VL as arrows: real, V", (VR + VL).real), ("VR + VL as arrows: imag, V", (VR + VL).imag),
    ("heat in the resistor, W", mag * mag * R),
    ("wrong: R + X as ohms, A", wrong_add), ("wrong: coil ignored, A", wrong_noL),
    ("wrong: X = f L, A", wrong_fL), ("wrong: meters added, V", wrong_meters),
    ("wrong: 230 V taken as the peak, A rms", VRMS / sqrt(2) / abs(Z)),
    ("try: 60 Hz, A", abs(I60)), ("try: 60 Hz lag, deg", -degrees(atan2(I60.imag, I60.real))),
    ("try: coil doubled, A", abs(I2L)), ("try: coil doubled lag, deg", -degrees(atan2(I2L.imag, I2L.real))),
    ("try: series C, uF", C * 1e6), ("try: series C, A", abs(Icap)),
    ("try: series C lag, deg", round(-degrees(atan2(Icap.imag, Icap.real)), 9) + 0.0),
    ("switch-on: tau = L/R, ms", tau * 1000), ("switch-on: largest |i|, 1st cycle, A", first),
    ("switch-on: sim minus phasor at 10 ms, A", gap10), ("  closed form, A", gap10_exact),
]
for name, v in rows:
    print(f"{name:<40} {v:>11.4f}")
ms = range(0, 21, 2)
print("chart, ms         " + " ".join(f"{m:>6d}" for m in ms))
print("chart, simulated  " + " ".join(f"{trace[m * 100]:>6.2f}" for m in ms))
print("chart, phasor     " + " ".join(f"{steady(m / 1000):>6.2f}" for m in ms))
S = 1.0                                     # figure: 1 unit per volt, origin (60, 60), y down
print(f"figure, VR tip ({60 + S * VR.real:.1f}, {60 - S * VR.imag:.1f}), "
      f"V tip ({60 + S * VRMS:.1f}, 60.0), I tip ({60 + 20 * I.real:.1f}, {60 - 20 * I.imag:.1f})")

assert abs(mag - 230 / 50) < 1e-9,                       "hand value: 230 V over a 3-4-5 triangle of 50 ohms"
assert abs(sqrt(a * a + b * b) - ipk) < 1e-9,            "real-pair road matches the complex division"
assert abs(atan2(b, a) - lag) < 1e-9,                    "real-pair lag matches the phasor's angle"
assert abs(irms_sim - mag) < 1e-4,                       "simulated rms current matches the phasor"
assert abs(atan2(cb, ca) - lag) < 1e-4,                  "simulated lag matches the phasor"
assert abs(sqrt(vr_sim ** 2 + vl_sim ** 2) - VRMS) < 1e-3, "meter readings add as a right triangle"
assert abs(gap10 - gap10_exact) < 1e-6,                  "switch-on gap is the decaying free response"
assert abs(abs(Icap) - wrong_noL) < 1e-9,                "a cancelling capacitor leaves only R"
print("ALL CHECKS PASS")
