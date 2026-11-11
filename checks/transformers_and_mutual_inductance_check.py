# Transformers and mutual inductance -- the check behind the card.  Standard library only.
# Mains 230 V, 50 Hz down to 12 V for a doorbell chime (6 ohm + j8 ohm).  Every number on
# the card is printed here.  Road 1: phasor algebra, the ideal rule and the coupled coils.
# Road 2: simulate the shared flux and the turns, step by step (RK4).  Road 3: simulate
# the coils as L1, L2 and M (RK4); it also handles leaky coupling, k below 1.
from math import pi, sqrt, cos, sin, atan2, degrees, radians

V1, f, N1, N2 = 230.0, 50.0, 1150, 60        # rms volts, hertz, turns
R, X = 6.0, 8.0                              # chime: resistance, reactance at 50 Hz, ohm
L1, A = 30.0, 7.5e-4                         # primary self-inductance (H), core area (m^2)
w, n = 2 * pi * f, N1 / N2                   # rad/s, turns ratio
ZL, Ll = complex(R, X), X / w                # chime impedance, chime inductance (H)

def coupled(k, L1, ZL=ZL):                   # road 1: phasor equations of two coupled coils
    L2 = L1 / n**2; M = k * sqrt(L1 * L2)
    Zin = 1j * w * L1 + (w * M)**2 / (ZL + 1j * w * L2)
    I1 = V1 / Zin; I2 = 1j * w * M * I1 / (ZL + 1j * w * L2)
    return Zin, I1, I2, ZL * I2

def rk4(fun, y, t, h):
    k1 = fun(t, y); k2 = fun(t + h/2, [a + h/2 * b for a, b in zip(y, k1)])
    k3 = fun(t + h/2, [a + h/2 * b for a, b in zip(y, k2)]); k4 = fun(t + h, [a + h * b for a, b in zip(y, k3)])
    return [a + h/6 * (b + 2*c + 2*d + e) for a, b, c, d, e in zip(y, k1, k2, k3, k4)]

def v1(t): return sqrt(2) * V1 * cos(w * t)  # switched on at a voltage peak
def simulate(fun, out, steps=2000, cycles=20):
    # run from rest, then take each signal's 50 Hz phasor (rms size) over the last cycle
    h, y, ph, Pm = 1 / f / steps, [0.0, 0.0], [0j, 0j], 0.0
    for s in range(steps * cycles):
        t = s * h
        if s >= steps * (cycles - 1):
            sig = out(t, y)
            ph = [p + sqrt(2) / steps * x * complex(cos(w * t), -sin(w * t)) for p, x in zip(ph, sig)]
            Pm += sig[0] * sig[2] / steps if len(sig) > 2 else 0.0
        y = rk4(fun, y, t, h)
    return ph, Pm

def flux_road(L1):                           # road 2: state = core flux, chime current
    Lam = L1 / N1**2                         # permeance: flux per ampere-turn
    fun = lambda t, y: [v1(t) / N1, (N2 * v1(t) / N1 - R * y[1]) / Ll]
    out = lambda t, y: [(y[0] / Lam + N2 * y[1]) / N1, N2 * v1(t) / N1, v1(t)]
    (I1, V2), Pin = simulate(fun, out)
    return V1 / I1, I1, V2, Pin

def coil_road(k):                            # road 3: state = i1, i2; matrix of L1, L2, M
    L2 = L1 / n**2; M = k * sqrt(L1 * L2); det = M * M - L1 * (L2 + Ll)
    fun = lambda t, y: [(M * R * y[1] - (L2 + Ll) * v1(t)) / det, (L1 * R * y[1] - M * v1(t)) / det]
    out = lambda t, y: [y[0], R * y[1] + Ll * fun(t, y)[1]]
    (I1, V2), _ = simulate(fun, out)
    return I1, V2

V2i = V1 / n; I2i = V2i / abs(ZL); I1i = I2i / n; Zi = n**2 * ZL
Zc, I1c, I2c, V2c = coupled(1.0, L1)
Zs, I1s, V2s, Pin = flux_road(L1)
Zbig = flux_road(3.0e6)[0]                   # nearly ideal core: 100,000 times the inductance
I1r, V2r = coil_road(1.0)
_, _, _, V2k = coupled(0.97, L1); _, _, _, V2k0 = coupled(0.97, L1, ZL=1e12)
I1rk, V2rk = coil_road(0.97)
Im = V1 / (w * L1); Phi = sqrt(2) * V1 / (w * N1)
sh, mg = V1 / Zi, V1 / (1j * w * L1)         # chime's share and magnetizing current, as phasors
lag_s, lag_m = -degrees(atan2(sh.imag, sh.real)), -degrees(atan2(mg.imag, mg.real))
rows = [("turns ratio n = N1/N2", n), ("n^2", n**2), ("omega = 2 pi f, rad/s", w),
  ("V2 = V1/n, V", V2i), ("I2 = V2/|ZL|, A", I2i),
  ("chime power I2^2 R, W", I2i**2 * R), ("chime volt-amperes V2 I2, VA", V2i * I2i),
  ("I1 = I2/n, mA", 1000 * I1i), ("ideal Zin = n^2 ZL, real part, ohm", Zi.real),
  ("ideal Zin, imaginary part, ohm", Zi.imag), ("ideal |Zin|, ohm", abs(Zi)),
  ("L2 = L1/n^2, H", L1 / n**2), ("M = sqrt(L1 L2), H", sqrt(L1 * L1 / n**2)),
  ("permeance L1/N1^2, microhenry", 1e6 * L1 / N1**2), ("magnetizing current V1/(w L1), mA", 1000 * Im),
  ("primary reactance w L1, ohm", w * L1),
  ("1 phasor  Zin real part, ohm", Zc.real), ("1 phasor  Zin imaginary part, ohm", Zc.imag),
  ("1 phasor  |I1|, mA", 1000 * abs(I1c)), ("1 phasor  I1 lag behind V1, degrees", -degrees(atan2(I1c.imag, I1c.real))),
  ("1 phasor  |V2|, V", abs(V2c)), ("1 parallel form |I1|, mA", 1000 * abs(V1 / Zi + Im * -1j)),
  ("2 flux    Zin real part, ohm", Zs.real), ("2 flux    Zin imaginary part, ohm", Zs.imag),
  ("2 flux    |I1|, mA", 1000 * abs(I1s)), ("2 flux    |V2|, V", abs(V2s)),
  ("2 flux    power in, mean v1 i1, W", Pin), ("2 flux, L1 = 3e6 H: Zin real, ohm", Zbig.real),
  ("2 flux, L1 = 3e6 H: Zin imaginary, ohm", Zbig.imag),
  ("3 coils   |I1|, mA", 1000 * abs(I1r)), ("3 coils   |V2|, V", abs(V2r)),
  ("peak flux, mWb", 1000 * Phi), ("peak flux density, T", Phi / A), ("turns per volt N1/V1", N1 / V1),
  ("volts per turn V1/N1, V", V1 / N1), ("sqrt(2) pi, the designers' 4.44", sqrt(2) * pi),
  ("k = 0.97: open-circuit V2, V", abs(V2k0)), ("k = 0.97: V2 with chime, phasor, V", abs(V2k)),
  ("k = 0.97: V2 with chime, simulated, V", abs(V2rk)), ("DC: 230 V into 100 ohm winding, A", V1 / 100),
  ("DC: heat in that winding, W", V1**2 / 100),
  ("wrong: ratio upside down, V2, V", V1 * n), ("wrong: Zin = n ZL, |Zin|, ohm", n * abs(ZL)),
  ("wrong: I1 = n I2, A", n * I2i), ("wrong: I1 = n I2, volt-amperes in, VA", V1 * n * I2i),
   ("wrong: 115 and 6 turns, peak B, T", sqrt(2) * V1 / (w * 115) / A),
  ("wrong: no magnetizing current, mA", 1000 * I1i),
  ("try: 60 Hz, peak B, T", sqrt(2) * V1 / (2 * pi * 60 * N1) / A),
  ("try: 60 Hz, magnetizing current, mA", 1000 * V1 / (2 * pi * 60 * L1)),
  ("try: N2 = 30, V2, V", V1 * 30 / N1), ("try: L1 = 300 H, |I1|, mA", 1000 * abs(coupled(1.0, 300.0)[1]))]
for label, val in rows:
    print(f"{label:<42}{val:12.4f}")
print(f"phase behind V1, deg: chime share {lag_s:.4f}, magnetizing {lag_m:.4f}, apart {lag_m - lag_s:.4f}; "
      f"sizes end to end {1000 * (abs(sh) + abs(mg)):.4f} mA")
print(f"figure, N1 {N1} turns, N2 {N2} turns, V1 {V1:.0f} V, V2 {V2i:.1f} V, I1 {1000*abs(I1c):.1f} mA, I2 {I2i:.2f} A")

assert abs(V2c - V2i) < 1e-9,                            "k = 1: V2 is V1/n exactly, at finite L1"
assert abs(Zs - Zc) < 0.05,                              "flux simulation vs phasor algebra"
assert abs(V2s - V2i) < 1e-6,                            "phasor read-out of the known wave N2 v1/N1"
assert abs(I1r - I1c) < 1e-5 and abs(V2r - V2i) < 1e-6,  "L-M simulation vs phasor algebra"
assert abs(Zbig - Zi) / abs(Zi) < 1e-4,                  "huge L1: Zin tends to n^2 ZL"
assert abs(Pin - I2i**2 * R) < 1e-4,                     "power in = power into the chime"
assert abs(V1 / Zc - (V1 / Zi - 1j * Im)) < 1e-9,        "Zin = n^2 ZL in parallel with j w L1"
assert abs(sqrt(abs(sh)**2 + abs(mg)**2 + 2 * abs(sh) * abs(mg) * cos(radians(lag_m - lag_s))) - abs(I1c)) < 1e-9, \
    "the two currents add as sides of a triangle"
assert abs(abs(V2rk) - abs(V2k)) < 1e-4 and abs(V2k) < V2i, "leaky coupling sags V2"
print("ALL CHECKS PASS")
