# Damping ratio and natural frequency -- the check behind the card.  Standard library only.
# One corner of a car: sprung mass m on a spring k and a shock absorber c.
#   m x'' + c x' + k x = F,  wn = sqrt(k/m),  zeta = c / (2 sqrt(k m)).
# Roads: the formulas; the quadratic formula on m s^2 + c s + k; an RK4 drop test read
# back into (zeta, wn); a frequency sweep and a simulated shaker at wn.
import math

m, f_n, zeta = 400.0, 1.0, 0.7          # kg on one corner, Hz, damping ratio
g, load = 9.80665, 80.0                  # m/s^2 standard gravity (CGPM), kg in the boot
wn = 2 * math.pi * f_n                   # rad/s
k = m * wn ** 2                          # N/m
c = 2 * zeta * math.sqrt(k * m)          # N s/m
F = load * g                             # N
sag = F / k                              # m, the static drop

def roots(m, c, k):                      # quadratic formula on m s^2 + c s + k, as (re, im)
    d = c * c - 4 * m * k
    if d < 0:
        return (-c / (2 * m), math.sqrt(-d) / (2 * m))
    return ((-c + math.sqrt(d)) / (2 * m), 0.0)

def overshoot(z):                        # peak above final value, fraction, step input, no zero
    return math.exp(-math.pi * z / math.sqrt(1 - z * z)) if z < 1 else 0.0

def rk4(f, x, dt, n):                    # RK4 on a list state, x' = f(t, x); returns samples
    out, t = [x], 0.0
    for _ in range(n):
        k1 = f(t, x); k2 = f(t + dt / 2, [a + dt / 2 * b for a, b in zip(x, k1)])
        k3 = f(t + dt / 2, [a + dt / 2 * b for a, b in zip(x, k2)])
        k4 = f(t + dt, [a + dt * b for a, b in zip(x, k3)])
        x = [a + dt / 6 * (p + 2 * q + 2 * r + s) for a, p, q, r, s in zip(x, k1, k2, k3, k4)]
        t += dt; out.append(x)
    return out

def peak(ys, dt):                        # largest sample, refined by a parabola through 3 points
    i = max(range(1, len(ys) - 1), key=lambda j: ys[j])
    a, b, d = ys[i - 1], ys[i], ys[i + 1]
    h = 0.5 * (a - d) / (a - 2 * b + d)
    return b - 0.25 * (a - d) * h, (i + h) * dt

def settle(ys, dt, final, band=0.02):    # last exit from +-2% of the final value, interpolated
    last = max(i for i, y in enumerate(ys) if abs(y - final) > band * final)
    e0, e1 = (abs(ys[j] - final) - band * final for j in (last, last + 1))
    return (last + e0 / (e0 - e1)) * dt

def drop(cc, dt=1e-4, T=5.0):            # body drop x(t) after the load lands, damper cc
    xs = rk4(lambda t, x: [x[1], (F - cc * x[1] - k * x[0]) / m], [0.0, 0.0], dt, round(T / dt))
    return [x[0] for x in xs]

# ---- road 1: formulas ----
sig, wd = zeta * wn, wn * math.sqrt(1 - zeta ** 2)
print(f"inputs: m = {m:.0f} kg, f_n = {f_n:.1f} Hz, zeta = {zeta:.1f}, load {load:.0f} kg, g = {g} m/s^2")
print(f"model: wn = {wn:.4f} rad/s, k = {k:.1f} N/m, c = {c:.1f} N s/m, F = {F:.2f} N")
print(f"static sag F/k = {sag * 1000:.2f} mm")
print(f"poles from (zeta, wn): {-sig:.4f} +- {wd:.4f}j rad/s; damped f_d = {wd / (2 * math.pi):.4f} Hz")
print(f"formula overshoot {100 * overshoot(zeta):.2f} % = {overshoot(zeta) * sag * 1000:.2f} mm, "
      f"peak time pi/wd {math.pi / wd:.4f} s, settle 4/(zeta wn) {4 / sig:.4f} s")
# ---- road 2: quadratic formula on (m, c, k), then poles back to the two numbers ----
pr, pi_ = roots(m, c, k)
wn_p, z_p = math.hypot(pr, pi_), -pr / math.hypot(pr, pi_)
print(f"poles from (m, c, k):  {pr:.4f} +- {pi_:.4f}j rad/s")
print(f"back from poles: wn = |p| = {wn_p:.4f} rad/s = {wn_p / (2 * math.pi):.4f} Hz, "
      f"zeta = -Re p/|p| = {z_p:.4f}, angle {math.degrees(math.acos(z_p)):.2f} deg")
# ---- road 3: RK4 drop test, read back ----
dt = 1e-4
xs = drop(c)
xp, tp = peak(xs, dt)
Mp = xp / sag - 1
z_s = -math.log(Mp) / math.sqrt(math.pi ** 2 + math.log(Mp) ** 2)
wn_s = math.pi / tp / math.sqrt(1 - z_s ** 2)
ts = settle(xs, dt, sag)
print(f"RK4 drop: peak {xp * 1000:.2f} mm at {tp:.4f} s, overshoot {100 * Mp:.2f} %, 2% settle {ts:.4f} s")
print(f"read back from the drop: zeta = {z_s:.4f}, wn = {wn_s:.4f} rad/s = {wn_s / (2 * math.pi):.4f} Hz")
tc = [i / 10 for i in range(0, 21, 2)]
worn = drop(2 * 0.3 * math.sqrt(k * m))
print("chart, t (s)       " + " ".join(f"{t:6.2f}" for t in tc))
print("chart, zeta 0.7 mm " + " ".join(f"{xs[round(t / dt)] * 1000:6.2f}" for t in tc))
print("chart, zeta 0.3 mm " + " ".join(f"{worn[round(t / dt)] * 1000:6.2f}" for t in tc))
wp, wtp = peak(worn, dt)
print(f"worn damper zeta 0.3: formula {100 * overshoot(0.3):.2f} %, RK4 {100 * (wp / sag - 1):.2f} % at {wtp:.4f} s, "
      f"2% settle {settle(worn, dt, sag):.4f} s")
# ---- overshoot depends on zeta alone: formula vs simulation with wn = 1 rad/s ----
sweep = []
for z in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]:
    ys = [x[0] for x in rk4(lambda t, x: [x[1], 1 - 2 * z * x[1] - x[0]], [0.0, 0.0], 1e-3, 20000)]
    sim = max(max(ys) - 1, 0.0)
    sweep.append((z, overshoot(z), sim))
    print(f"chart, zeta {z:.1f}: overshoot formula {100 * overshoot(z):6.2f} %, simulated {100 * sim:6.2f} %")
# ---- road 4: frequency domain ----
G = lambda w: complex(k, 0) / complex(k - m * w * w, c * w)
lo, hi = 0.1, 100.0
for _ in range(100):                     # bisection on the phase: where is it -90 degrees?
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if math.atan2(G(mid).imag, G(mid).real) > -math.pi / 2 else (lo, mid)
w90 = 0.5 * (lo + hi)
print(f"sweep: phase -90 deg at {w90:.4f} rad/s; gain there {abs(G(w90)):.4f} = 1/(2 zeta) -> zeta {1 / (2 * abs(G(w90))):.4f}")
wr = max((i * 1e-4 for i in range(1, 100000)), key=lambda w: abs(G(w)))
print(f"resonant peak: |G| max {abs(G(wr)):.4f} at {wr:.4f} rad/s; formula {1 / (2 * zeta * math.sqrt(1 - zeta ** 2)):.4f} "
      f"at {wn * math.sqrt(1 - 2 * zeta ** 2):.4f} rad/s")
F0 = 100.0
sh = rk4(lambda t, x: [x[1], (F0 * math.sin(wn * t) - c * x[1] - k * x[0]) / m], [0.0, 0.0], 1e-3, 20000)
tail = [x[0] for x in sh[15000:]]
amp = 0.5 * (max(tail) - min(tail)) / (F0 / k)
print(f"shaker at wn, 100 N: amplitude ratio {amp:.4f} -> zeta {1 / (2 * amp):.4f}")
# ---- what breaks ----
r0 = 0.05                                # a 5 cm kerb under the wheel: G = (c s + k)/(m s^2 + c s + k)
kz = rk4(lambda t, x: [x[1], (r0 - c * x[1] - k * x[0]) / m], [0.0, 0.0], dt, 50000)
ky = [c * x[1] + k * x[0] for x in kz]   # body height = c z' + k z
kp, ktp = peak(ky, dt)
y0 = lambda t: 1 - math.exp(-sig * t) * (math.cos(wd * t) + sig / wd * math.sin(wd * t))
y0d = lambda t: wn ** 2 / wd * math.exp(-sig * t) * math.sin(wd * t)
cf = max(r0 * (y0(i * 1e-4) + 2 * zeta / wn * y0d(i * 1e-4)) for i in range(20000))
print(f"kerb 5 cm: RK4 overshoot {100 * (kp / r0 - 1):.2f} % at {ktp:.4f} s; closed form {100 * (cf / r0 - 1):.2f} %; "
      f"formula said {100 * overshoot(zeta):.2f} %; zero at {-k / c:.4f} rad/s")
print(f"1 Hz read as 1 rad/s: k = {m * 1.0:.1f} N/m, sag {F / m:.3f} m")
c2 = zeta * math.sqrt(k * m)
z2 = c2 / (2 * math.sqrt(k * m))
print(f"the 2 dropped: c = {c2:.1f} N s/m, real zeta {z2:.2f}, overshoot {100 * overshoot(z2):.2f} %")
hv = drop(2 * 1.5 * math.sqrt(k * m))
print(f"zeta 1.5: no overshoot (peak {max(hv) / sag:.4f} of sag), 2% settle {settle(hv, dt, sag):.4f} s; "
      f"4/(zeta wn) says {4 / (1.5 * wn):.4f} s")
cr = drop(2 * math.sqrt(k * m))
print(f"zeta 1.0: 2% settle {settle(cr, dt, sag):.4f} s")
s0, s1 = 330.0, 15.0                      # figure: origin (px), px per rad/s
print(f"figure, poles 0.7 ({s0 + s1 * pr:.1f}, {120 - s1 * pi_:.1f}) ({s0 + s1 * pr:.1f}, {120 + s1 * pi_:.1f}); "
      f"radius {s1 * wn:.1f}")
q = roots(m, 2 * 0.3 * math.sqrt(k * m), k)
print(f"figure, poles 0.3 ({s0 + s1 * q[0]:.1f}, {120 - s1 * q[1]:.1f}) ({s0 + s1 * q[0]:.1f}, {120 + s1 * q[1]:.1f}); "
      f"critical ({s0 - s1 * wn:.1f}, 120.0)")

assert abs(z_s - zeta) < 1e-3                                     # drop test read back vs design zeta
assert abs(wn_s - wn) < 1e-3                                      # drop test read back vs design wn
assert abs(pi_ - wd) < 1e-9                                       # quadratic formula vs wn sqrt(1 - zeta^2)
assert all(abs(f - s) < 1e-4 for z, f, s in sweep)                # overshoot formula vs simulation
assert abs(tp - math.pi / wd) < 1e-4                              # simulated peak time vs pi/wd
assert abs(w90 - wn) < 1e-6                                       # phase sweep vs sqrt(k/m)
assert abs(amp - 1 / (2 * zeta)) < 2e-3                           # simulated shaker vs 1/(2 zeta)
assert abs(abs(G(w90)) - amp) < 2e-3                             # complex gain vs simulated shaker
assert abs(kp - cf) < 1e-6                                        # kerb: RK4 vs closed form
print("ALL CHECKS PASS")
