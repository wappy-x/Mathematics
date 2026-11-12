# Symplectic steps -- the check behind the card.  Standard library only (math's sin, cos, sqrt, acos, asin).
# A frictionless clock pendulum, omega = pi rad/s, released at 20 degrees, run for a million swings.
# Roads: the exact swing time by the arithmetic-geometric mean; Verlet and RK4 at several steps (observed
# orders); the modified energy of backward error analysis; one step's area factor by finite differences
# against RK4's closed form 1 - z^6/72 + z^8/576; the clock's lead against the rotation-angle estimate.
from math import sin, cos, sqrt, acos, asin, pi

W2, TH0, G = pi * pi, 20 * pi / 180, 9.81      # omega^2 = g/L (1/s^2); release angle (rad); g (m/s^2)
a, b = 1.0, cos(TH0 / 2)
for _ in range(6): a, b = (a + b) / 2, sqrt(a * b)
TS = 1 / a                                     # exact swing time (half period) = pi / (omega AGM), s

def energy(th, p): return p * p / 2 + W2 * (1 - cos(th))    # per unit m L^2; p = angular speed, rad/s
def e2(th, p):                                               # the h^2 term of the modified energy
    s = sin(th); return p * p * W2 * cos(th) / 12 - W2 * W2 * s * s / 24
def amp(e): return acos(1 - e / W2) * 180 / pi               # the swing's reach, degrees, from its energy
def verlet(th, p, h):                                        # half kick, drift, half kick
    p -= h / 2 * W2 * sin(th); th += h * p
    return th, p - h / 2 * W2 * sin(th)
def rk4(th, p, h):
    hh = h / 2; k1 = -W2 * sin(th); k2 = -W2 * sin(th + hh * p)
    k3 = -W2 * sin(th + hh * (p + hh * k1)); k4 = -W2 * sin(th + h * (p + hh * k2))
    return th + h * (p + h / 6 * (k1 + k2 + k3)), p + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
def sci(x, d): return f"{x:.{d}e}"
def run_verlet(s, swings):           # energy band, modified-energy band, zero crossings, reach every 100k swings
    h = TS / s; hh = h / 2; th, p = TH0, 0.0; f = -W2 * sin(th); e0 = energy(th, p); m0 = e0 + h * h * e2(th, p)
    lo = hi = 0.0; mlo = mhi = 0.0; cross = 0; pts = [amp(e0)]
    for n in range(1, s * swings + 1):
        old = th; p += hh * f; th += h * p; f = -W2 * sin(th); p += hh * f
        c = cos(th); e = p * p / 2 + W2 * (1 - c); m = e + h * h * (p * p * W2 * c / 12 - f * f / 24)
        lo, hi, mlo, mhi = min(lo, e - e0), max(hi, e - e0), min(mlo, m - m0), max(mhi, m - m0)
        if (old > 0) != (th > 0): cross += 1
        if n % (s * 100000) == 0: pts.append(amp(e))
    return (hi - lo) / e0, (mhi - mlo) / e0, lo / e0, hi / e0, cross, pts
def run_rk4(s, swings):
    h = TS / s; th, p = TH0, 0.0; cross = 0; e0 = energy(th, p); pts = [amp(e0)]; es = [e0]
    for n in range(1, s * swings + 1):
        old = th; th, p = rk4(th, p, h)
        if (old > 0) != (th > 0): cross += 1
        if n % (s * 100000) == 0: es.append(energy(th, p)); pts.append(amp(es[-1]))
    return es, cross, pts
def area_factor(step, th, p, h, d=1e-5):     # determinant of one step's Jacobian, by central differences
    a1, a2 = step(th + d, p, h), step(th - d, p, h); b1, b2 = step(th, p + d, h), step(th, p - d, h)
    return ((a1[0] - a2[0]) * (b1[1] - b2[1]) - (b1[0] - b2[0]) * (a1[1] - a2[1])) / (4 * d * d)

h, e0 = TS / 20, energy(TH0, 0.0); z = pi * h
print(f"pendulum: g = {G} m/s^2, L = g/omega^2 = {G / W2:.4f} m, release 20 deg; exact swing time {TS:.9f} s")
print(f"a million swings = {1e6 * TS / 86400:.2f} days; energy at release E0 = {e0:.6f} per m L^2 (1/s^2)")
print(f"20 steps a swing: h = {h:.7f} s, z = omega h = {z:.6f}")
errs = {}
for s in (10, 20, 40):
    out = []
    for step in (verlet, rk4):
        th, p = TH0, 0.0
        for _ in range(s): th, p = step(th, p, TS / s)
        out.append(sqrt((th + TH0) ** 2 + (p / pi) ** 2))
    errs[s] = out
    print(f"one swing, {s} steps: Verlet error {sci(out[0], 3)} rad, RK4 error {sci(out[1], 3)} rad")
rv, rr = errs[10][0] / errs[20][0], errs[20][0] / errs[40][0]
qv, qr = errs[10][1] / errs[20][1], errs[20][1] / errs[40][1]
print(f"error ratio per halving: Verlet {rv:.2f}, {rr:.2f} (order 2); RK4 {qv:.2f}, {qr:.2f} (order 4)")
print(f"one swing, 20 steps: Verlet error / RK4 error = {errs[20][0] / errs[20][1]:.0f}")
pb = sqrt(2 * e0)
for name, step in (("Verlet", verlet), ("RK4", rk4)):
    print(f"area factor - 1, one step: {name} at release {sci(area_factor(step, TH0, 0.0, h) - 1, 2)}, "
          f"at the bottom {sci(area_factor(step, 0.0, pb, h) - 1, 2)}, small swing {sci(area_factor(step, 0.01, 0.0, h) - 1, 2)}")
lin = 1 - z ** 6 / 72 + z ** 8 / 576
print(f"RK4 small-swing formula 1 - z^6/72 + z^8/576 - 1 = {sci(lin - 1, 4)}; per 100k swings (2000000 steps) {lin ** 2000000:.4f}")
band, mband, vlo, vhi, vcross, vpts = run_verlet(20, 1000000)
es, rcross, rpts = run_rk4(20, 1000000)
pred = h * h * (e2(0.0, pb) - e2(TH0, 0.0)) / e0       # the dip at the bottom that the modified energy predicts
print(f"Verlet, 1e6 swings: energy {100 * (1 + vlo):.3f}% to {100 * (1 + vhi):.3f}% of E0; band {100 * band:.3f}%, "
      f"predicted {100 * pred:.3f}%")
print(f"Verlet, 1e6 swings: modified energy E + h^2 E2 moves by {100 * mband:.5f}% of E0; ratio {band / mband:.0f}")
print(f"RK4, 1e6 swings: energy left {100 * es[-1] / e0:.3f}%, reach {rpts[-1]:.2f} deg; last 100k swings x{es[-1] / es[-2]:.4f}")
print("chart, reach in degrees every 100k swings, Verlet: " + ", ".join(f"{x:.2f}" for x in vpts))
print("chart, reach in degrees every 100k swings, RK4: " + ", ".join(f"{x:.2f}" for x in rpts))
lead = 1e6 * (2 * asin(pi / 40) / (pi / 20) - 1)
print(f"clock: Verlet counts {vcross} swings, ahead by {vcross - 1000000}; estimate {lead:.0f}; RK4 counts {rcross}")
print(f"cost for 1e6 swings (20000000 steps): Verlet {20 * 1000000 + 1} sines, RK4 {4 * 20 * 1000000} sines")   # 1 a step + 1; 4 a step
bands = {20: (band, mband)}
for s in (10, 40):
    bb, mb, _, _, _, _ = run_verlet(s, 100000); bands[s] = (bb, mb)
    print(f"Verlet, {s} steps a swing, 1e5 swings: energy band {100 * bb:.4f}%, modified-energy band {sci(100 * mb, 3)}%")
print(f"band ratios per halving: energy {bands[10][0] / band:.2f}, {band / bands[40][0]:.2f}; "
      f"modified {bands[10][1] / mband:.1f}, {mband / bands[40][1]:.1f}")
es40, _, _ = run_rk4(40, 100000)
print(f"RK4, 40 steps a swing, 1e5 swings: energy lost {100 * (1 - es40[1] / e0):.3f}%; at 20 steps {100 * (1 - es[1] / e0):.2f}%")
th, p, t = TH0, 0.0, 0.0                     # what breaks: a step that depends on the state
for _ in range(2000000):
    hs = h * (1 + 0.2 * abs(th)); th, p = verlet(th, p, hs); t += hs
print(f"Verlet with step h(1 + 0.2|theta|): after {t / TS:.0f} swings energy {100 * energy(th, p) / e0:.2f}% of E0")
th, p, lo, hi = TH0, 0.0, e0, e0
for _ in range(2000000):
    p -= h * W2 * sin(th); th += h * p; e = energy(th, p); lo, hi = min(lo, e), max(hi, e)
print(f"symplectic Euler (one kick, one drift), 1e5 swings: energy {100 * lo / e0:.2f}% to {100 * hi / e0:.2f}% of E0")
th, p, n = TH0, 0.0, 0
while energy(th, p) <= 2 * W2: th, p, n = th + h * p, p - h * W2 * sin(th), n + 1
print(f"forward Euler: over the top after {n} steps, swing {n / 20:.1f}")
assert 3.9 < rv < 4.1 and 3.9 < rr < 4.1 and 15 < qv < 17 and 15 < qr < 17     # orders 2 and 4 vs the AGM
assert abs(area_factor(verlet, TH0, 0.0, h) - 1) < 1e-9                          # Verlet keeps area
assert abs((area_factor(rk4, 0.01, 0.0, h) - 1) / (lin - 1) - 1) < 0.01          # RK4 shrinks it as the formula says
assert abs((es[-1] / es[-2]) / lin ** 2000000 - 1) < 0.01                        # the drift rate is that shrinkage
assert abs(band / pred - 1) < 0.01 and band / mband > 100 and 3.8 < band / bands[40][0] < 4.2    # band ~ h^2, modified energy h^4
assert 14 < mband / bands[40][1] < 18 and abs((vcross - 1e6) / lead - 1) < 0.01  # clock lead as estimated
assert es[-1] / e0 < 0.05 and vpts[-1] > 19.9                                    # RK4 runs down, Verlet does not
print("ALL CHECKS PASS")
