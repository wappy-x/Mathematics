# RLC resonance: a series tuner picking 98.5 MHz. Three roads to f0 and Q:
# the formulas, a frequency sweep of the complex impedance, and a time-domain simulation.
import math

L, R, F_STATION, V_ANT = 100e-9, 0.5, 98.5e6, 10e-6   # henry, ohm, hertz, volt (antenna EMF)
C_LIGHT = 299792458.0                                   # m/s, exact by the SI definition

def show(label, value, unit, dp=4):
    print(f"{label:<44}{value:>14.{dp}f} {unit}".rstrip())

# ---- road 1: the formulas ----
C = 1.0 / ((2 * math.pi * F_STATION) ** 2 * L)          # capacitance that tunes the station
w0 = 1.0 / math.sqrt(L * C); f0 = w0 / (2 * math.pi)
Q = w0 * L / R
BW = R / (2 * math.pi * L)
zeta = (R / 2) * math.sqrt(C / L)                       # spring road: c / (2 sqrt(k m)), m=L, c=R, k=1/C
print(f"inputs: L {L*1e9:.0f} nH, R {R:.1f} ohm, station {F_STATION/1e6:.1f} MHz, antenna {V_ANT*1e6:.0f} uV")
print("FM band 88 to 108 MHz, channels 200 kHz apart; speed of light 299792458 m/s")
show(f"C that tunes {F_STATION/1e6:.1f} MHz", C * 1e12, "pF")
show("w0 = 1/sqrt(LC)", w0 / 1e6, "million rad/s")
show("f0 = 1/(2 pi sqrt(LC))", f0 / 1e6, "MHz")
show("reactance of the coil at f0, w0 L", w0 * L, "ohm")
show("Q = w0 L / R", Q, "")
show("bandwidth R/(2 pi L)", BW / 1e3, "kHz")
show("spring road: zeta = (R/2) sqrt(C/L)", zeta, "", 6)
show("spring road: Q = 1/(2 zeta)", 1 / (2 * zeta), "")
show("car corner, zeta 0.7: Q = 1/(2 zeta)", 1 / 1.4, "")
show("current at f0, V/R", V_ANT / R * 1e6, "uA")
show("capacitor voltage at f0, Q V", Q * V_ANT * 1e3, "mV")

# ---- road 2: frequency domain, complex impedance written out ----
def Z(f):
    w = 2 * math.pi * f
    return complex(R, w * L - 1 / (w * C))

def gain(f, r=R):                                       # |I(f)| / |I(f0)| for resistance r
    w = 2 * math.pi * f
    return r / abs(complex(r, w * L - 1 / (w * C)))

lo, hi, g = 0.9 * F_STATION, 1.1 * F_STATION, (math.sqrt(5) - 1) / 2   # golden-section search for the smallest |Z|
for _ in range(200):
    a, b = hi - g * (hi - lo), lo + g * (hi - lo)
    if abs(Z(a)) < abs(Z(b)): hi = b
    else: lo = a
f_peak = (lo + hi) / 2

def edge(level, lo, hi):                                # bisection for gain(f) = level
    for _ in range(200):
        mid = (lo + hi) / 2
        if (gain(lo) - level) * (gain(mid) - level) <= 0: hi = mid
        else: lo = mid
    return (lo + hi) / 2

f1, f2 = edge(1 / math.sqrt(2), 0.9 * F_STATION, f_peak), edge(1 / math.sqrt(2), f_peak, 1.1 * F_STATION)
h1, h2 = edge(0.5, 0.9 * F_STATION, f_peak), edge(0.5, f_peak, 1.1 * F_STATION)
show("sweep: frequency of smallest |Z|", f_peak / 1e6, "MHz")
show("sweep: lower half-power edge", f1 / 1e6, "MHz")
show("sweep: upper half-power edge", f2 / 1e6, "MHz")
show("sweep: bandwidth f2 - f1", (f2 - f1) / 1e3, "kHz")
show("sweep: Q = f0 / bandwidth", f_peak / (f2 - f1), "")
show("sweep: sqrt(f1 f2)", math.sqrt(f1 * f2) / 1e6, "MHz")
for fs in (98.7e6, 100.5e6):
    show(f"gain at {fs/1e6:.1f} MHz", gain(fs), "")
    show(f"  in decibels", 20 * math.log10(gain(fs)), "dB", 2)

# ---- road 3: time domain, RK4 on L i' = v(t) - R i - q/C ----
def step(q, i, t, h, drive):
    def d(q, i, t):
        return i, (drive(t) - R * i - q / C) / L
    k1 = d(q, i, t); k2 = d(q + h / 2 * k1[0], i + h / 2 * k1[1], t + h / 2)
    k3 = d(q + h / 2 * k2[0], i + h / 2 * k2[1], t + h / 2)
    k4 = d(q + h * k3[0], i + h * k3[1], t + h)
    return (q + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]),
            i + h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]))

def driven_amplitude(fd, periods=600, n=100):           # steady current amplitude, from rest
    w, h = 2 * math.pi * fd, 1 / (fd * n)
    q = i = 0.0
    drive = lambda t: V_ANT * math.sin(w * t)
    for k in range(periods * n):
        q, i = step(q, i, k * h, h, drive)
    s = c = 0.0
    for k in range(n):                                  # project the last period on sin and cos
        t = (periods * n + k) * h
        s += i * math.sin(w * t); c += i * math.cos(w * t)
        q, i = step(q, i, t, h, drive)
    return 2 * math.hypot(s, c) / n

amps = {}
for fs in (98.5e6, 98.7e6, 100.5e6):
    amps[fs] = driven_amplitude(fs)
    show(f"simulated current at {fs/1e6:.1f} MHz", amps[fs] * 1e6, "uA")
    show(f"  phasor V/|Z|", V_ANT / abs(Z(fs)) * 1e6, "uA")

alpha = R / (2 * L); wd = math.sqrt(w0 ** 2 - alpha ** 2)    # ring-down: charge C to Q V, let go
Td, n, cycles = 2 * math.pi / wd, 200, 124
q, i = C * Q * V_ANT, 0.0
energy = lambda q, i: L * i * i / 2 + q * q / (2 * C)
E0, h, E1 = energy(q, i), Td / n, None
for k in range(cycles * n):
    q, i = step(q, i, k * h, h, lambda t: 0.0)
    if k == n - 1: E1 = energy(q, i)
E_end = energy(q, i)
Q_ring = w0 * cycles * Td / -math.log(E_end / E0)
show("ring-down: energy lost in one cycle", 100 * (1 - E1 / E0), "%", 3)
show("  2 pi / Q, the high-Q estimate of it", 100 * 2 * math.pi / Q, "%", 3)
show(f"ring-down: amplitude left after {cycles} cycles", 100 * math.sqrt(E_end / E0), "%", 3)
show("  e^-pi, the target after Q cycles", 100 * math.exp(-math.pi), "%", 3)
show("ring-down: Q from the decay rate", Q_ring, "")

# ---- the band, the neighbour, the range ----
for fb in (88e6, 108e6):
    show(f"C to tune {fb/1e6:.0f} MHz", 1e12 / ((2 * math.pi * fb) ** 2 * L), "pF")
    show(f"  Q there", 2 * math.pi * fb * L / R, "")
x = 98.7 / 98.5 - 98.5 / 98.7; Q_need = math.sqrt(1 / 0.1 ** 2 - 1) / x
show("Q to cut 98.7 MHz to 0.1 of the peak", Q_need, "", 1)
show("  series R that needs", w0 * L / Q_need * 1e3, "mohm", 1); show("Q with a 75 ohm antenna wired into the loop", w0 * L / (R + 75), "")
show("wavelength at 98.5 MHz", C_LIGHT / 98.5e6, "m")
show("wavelength at 2.45 GHz", C_LIGHT / 2.45e9 * 100, "cm", 2)

# ---- what breaks ----
show("wrong: 1/sqrt(LC) read as hertz", 1 / math.sqrt(L * C) / 1e6, "MHz", 2)
show("wrong: half-amplitude width", (h2 - h1) / 1e3, "kHz", 2)
show("wrong: Q = 1/zeta", 1 / zeta, "")
show("  its bandwidth f0/Q", f0 * zeta / 1e3, "kHz", 2)
show("wrong: bandwidth R/L read as hertz", R / L / 1e6, "MHz", 2)

print("chart, MHz                " + " ".join(f"{f:6.1f}" for f in [96 + 0.5 * k for k in range(11)]))
for r in (R, 2.0):
    print(f"chart, R {r:.1f} ohm, Q {w0 * L / r:5.1f} " + " ".join(f"{gain((96 + 0.5 * k) * 1e6, r):6.3f}" for k in range(11)))

assert abs(f_peak - f0) / f0 < 1e-9, "sweep peak must sit at 1/(2 pi sqrt(LC))"
assert abs((f2 - f1) - BW) / BW < 1e-9, "half-power width must equal R/(2 pi L)"
assert abs((h2 - h1) - math.sqrt(3) * BW) / BW < 1e-9, "half-amplitude width is sqrt(3) bandwidths"
assert abs(math.sqrt(f1 * f2) - f0) / f0 < 1e-12, "f0 is the geometric mean of the edges"
assert abs(1 / (2 * zeta) - Q) / Q < 1e-12, "spring road and circuit road give one Q"
for fs, a in amps.items():
    assert abs(a - V_ANT / abs(Z(fs))) / a < 1e-4, "simulation must match the phasor"
assert abs(Q_ring - Q) / Q < 1e-3, "ring-down Q must match w0 L / R"
print("ALL CHECKS PASS")
