# Robust stability and robust performance -- the check behind the card.  Standard library only.
# Conveyor: torque u (N m) -> belt speed y (rad/s).  P_J(s) = 1 / ((J s + b)(tau s + 1)).  PI: C(s) = Kp + Ki/s.
# Model P0: the empty belt, J0 = 0.20 kg m^2.  Family: J from 0.20 (empty) to 0.40 kg m^2 (full).
from math import log, exp

J0, JH, JF, B, TAU = 0.20, 0.30, 0.40, 0.40, 0.02   # kg m^2 (empty, half, full), N m s/rad, s
KP, KI, M, WB, A = 3.0, 4.0, 2.0, 4.0, 0.01          # N m/(rad/s), N m/rad; spec: peak, rad/s, steady error
GRID = [10 ** (-2 + 6 * i / 6000) for i in range(6001)]   # 0.01 to 10^4 rad/s

def plant(J, s): return 1 / ((J * s + B) * (TAU * s + 1))
def ctrl(s, kp, ki): return kp + ki / s
def w_env(s, j=JF): return (j - J0) * s / (j * s + B)    # envelope: belt j's relative error; JF gives 0.5 s/(s + 1)
def w_p(s, wb=WB): return (s / M + wb) / (s + wb * A)   # specification: |S| must stay under 1/|W_P|

def tests(kp=KP, ki=KI, wb=WB, j=JF):
    """Model loop on P0; returns peaks (value, rad/s) of |W T|, |W_P S| and of their sum."""
    best = [(0.0, 0.0)] * 3
    for w in GRID:
        s = 1j * w
        L = plant(J0, s) * ctrl(s, kp, ki)
        a, c = abs(w_env(s, j) * L / (1 + L)), abs(w_p(s, wb) / (1 + L))
        best = [max(bv, (v, w)) for bv, v in zip(best, (a, c, a + c))]
    return best

def belt(J, kp=KP, ki=KI):
    """Direct road: the real plant J.  Peak |W_P S_J| and peak |S_J|, each with its frequency."""
    pk, ms = (0.0, 0.0), (0.0, 0.0)
    for w in GRID:
        s = 1j * w
        S = 1 / (1 + plant(J, s) * ctrl(s, kp, ki))
        pk, ms = max(pk, (abs(w_p(s) * S), w)), max(ms, (abs(S), w))
    return pk, ms

def hurwitz(J, kp=KP, ki=KI):
    """Closed loop: J tau s^3 + (J + b tau) s^2 + (b + Kp) s + Ki.  Stable when all > 0 and a2 a1 > a3 a0."""
    return (J + B * TAU) * (B + kp) / (J * TAU * ki)

def simulate(J, kp=KP, ki=KI, r=5.0, t_end=6.0, dt=1e-4):
    """Time road: RK4 on drive torque q, belt speed v and integral z, after a speed step of r rad/s."""
    def f(x):
        q, v, z = x
        return ((kp * (r - v) + ki * z - q) / TAU, (q - B * v) / J, r - v)
    x, peak, settle = [0.0] * 3, 0.0, 0.0
    for k in range(int(round(t_end / dt))):
        k1 = f(x); k2 = f([a + dt / 2 * d for a, d in zip(x, k1)])
        k3 = f([a + dt / 2 * d for a, d in zip(x, k2)]); k4 = f([a + dt * d for a, d in zip(x, k3)])
        x = [a + dt / 6 * (p + 2 * q + 2 * s + t) for a, p, q, s, t in zip(x, k1, k2, k3, k4)]
        peak = max(peak, x[1])
        if abs(x[1] - r) > 0.02 * r: settle = (k + 1) * dt
    return max(0.0, 100 * (peak - r) / r), settle, abs(x[1] - r)

print(f"design: Kp = {KP:.1f} N m/(rad/s), Ki = {KI:.1f} N m/rad; model J0 = {J0:.2f} kg m^2 (empty)")
print(f"plant: J = {J0:.2f}, {JH:.2f}, {JF:.2f} kg m^2, b = {B:.2f} N m s/rad, tau = {TAU:.2f} s;"
      f" spec: M = {M:.0f}, wB = {WB:.0f} rad/s, A = {A:.2f}")
s = 10j                                                   # the by-hand table, at 10 rad/s
den, c10 = (J0 * s + B) * (TAU * s + 1), ctrl(s, KP, KI)
L = c10 / den
print(f"hand at 10 rad/s: den = {den.real:.2f} {den.imag:+.2f}j, C = {c10.real:.1f} {c10.imag:+.1f}j,"
      f" L = {L.real:.4f} {L.imag:+.4f}j, |L| = {abs(L):.4f}, |1+L| = {abs(1 + L):.4f}")
print(f"hand at 10 rad/s: |S| = {abs(1 / (1 + L)):.4f}, |T| = {abs(L / (1 + L)):.4f},"
      f" |W| = {abs(w_env(s)):.4f}, |W_P| = {abs(w_p(s)):.4f}")
print("chart: w (rad/s) |W T| |W_P S| sum")
for w in (0.1, 0.178, 0.316, 0.562, 1, 1.78, 3.16, 5.62, 10, 17.8, 31.6, 56.2, 100, 178, 316):
    s = 1j * w
    L = plant(J0, s) * ctrl(s, KP, KI)
    a, c = abs(w_env(s) * L / (1 + L)), abs(w_p(s) / (1 + L))
    print(f"chart, {w:7.3f}, {a:.3f}, {c:.3f}, {a + c:.3f}")
rs, np_, rp = tests()
print(f"robust stability   peak |W T|     = {rs[0]:.3f} at {rs[1]:.2f} rad/s")
print(f"nominal perf       peak |W_P S|   = {np_[0]:.3f} at {np_[1]:.2f} rad/s")
print(f"robust perf        peak of sum    = {rp[0]:.3f} at {rp[1]:.2f} rad/s")
print(f"wrong: add the two peaks         = {rs[0] + np_[0]:.3f}")
assert rp[0] < 1 < rs[0] + np_[0] and rs[1] < rp[1] < np_[1]   # the peaks sit at different frequencies
peaks = {}
for name, J in (("empty", J0), ("half", JH), ("full", JF)):
    (pk, wpk), (ms, wms) = belt(J)
    os_, ts, err = simulate(J)
    peaks[name] = pk
    print(f"belt {name:5s} J={J:.2f}: Hurwitz ratio {hurwitz(J):.3f}, peak |W_P S| {pk:.3f} at {wpk:.2f} rad/s,"
          f" peak |S| {ms:.3f} at {wms:.2f} rad/s, overshoot {os_:.1f} %, 2% settle {ts:.2f} s")
    assert hurwitz(J) > 1 and err < 1e-3                  # algebra and simulation both say: stable
    assert pk < 1                                          # the real belt meets the specification
worst, slack, top = 0.0, 1.0, [0.0] * 21
for k in range(21):                                        # sweep the whole family, not just three belts
    J = J0 + (JF - J0) * k / 20
    for w in GRID[::10]:
        s = 1j * w
        L = plant(J0, s) * ctrl(s, KP, KI)
        bound = abs(w_p(s) / (1 + L)) / (1 - abs(w_env(s) * L / (1 + L)))
        real = abs(w_p(s) / (1 + plant(J, s) * ctrl(s, KP, KI)))
        worst, slack, top[k] = max(worst, real), min(slack, bound - real), max(top[k], real)
print(f"family sweep, 21 inertias: worst |W_P S_J| = {worst:.3f}; real never above the bound: {slack >= -1e-12}")
assert slack >= -1e-12 and worst < rp[0] < 1               # Step 4's bound holds; the test is pessimistic
assert abs(worst - max(peaks.values())) < 2e-3
assert abs(top[10] - peaks["half"]) < 2e-3 and abs(top[20] - peaks["full"]) < 2e-3   # the sweep's belts are the real ones
# Bode's sensitivity integral: integral of ln|S| over w is 0 here (no right-half-plane poles, L ~ 1/s^2)
lo, hi, n = log(1e-8), log(1e9), 200000
h, below, above = (hi - lo) / n, 0.0, 0.0
for i in range(n + 1):
    w = exp(lo + i * h)
    v = log(abs(1 / (1 + plant(J0, 1j * w) * ctrl(1j * w, KP, KI)))) * w * h * (0.5 if i in (0, n) else 1)
    below, above = below + min(v, 0.0), above + max(v, 0.0)
print(f"Bode integral: area below 0 = {below:.3f}, above 0 = {above:.3f}, |total| = {abs(below + above):.4f} (rad/s)")
assert abs(below + above) < 1e-3 * above
# What breaks
mrn = tests(kp=10.0, ki=50.0)                              # the controller from the small-gain card
mb = [belt(J, 10.0, 50.0)[0][0] for J in (J0, JH, JF)]
print(f"morning controller Kp = 10, Ki = 50: RS {mrn[0][0]:.4f}, NP {mrn[1][0]:.3f}, sum {mrn[2][0]:.3f};"
      f" real belts {mb[0]:.3f}, {mb[1]:.3f}, {mb[2]:.3f}")
assert mrn[0][0] < 1 < mrn[2][0] and max(mb) < 1           # not proved by the test, true for the real belts
soft = tests(kp=1.5, ki=5.0)
(spk, swp), (sms, _) = belt(JF, 1.5, 5.0)
os_, ts, err = simulate(JF, 1.5, 5.0)
print(f"wrong: Kp = 1.5, Ki = 5, two tests only: RS {soft[0][0]:.3f}, NP {soft[1][0]:.3f}, sum {soft[2][0]:.3f};"
      f" full belt peak |W_P S| {spk:.3f} at {swp:.2f} rad/s, overshoot {os_:.1f} %, settle {ts:.2f} s")
assert soft[0][0] < 1 and soft[1][0] < 1 and soft[2][0] > 1 and spk > 1
half_env = tests(j=JH)                                     # envelope drawn from the half-loaded belt
print(f"wrong: envelope from half belt: RS {half_env[0][0]:.3f}; at 10 rad/s it allows {abs(w_env(10j, JH)):.3f},"
      f" full belt's real error is {abs(w_env(10j)):.3f}")
assert abs(w_env(10j, JH)) < abs(w_env(10j))
print(f"saturation: a 10 rad/s step asks {KP * 10:.0f} N m at once, over a {20.0:.0f} N m drive;"
      f" the 5 rad/s step asks {KP * 5:.0f} N m")
print("try: Ki = 8 -> sum {:.3f}; Kp = 5, Ki = 10 -> sum {:.3f}; wB = 6 rad/s -> sum {:.3f}".format(
    tests(ki=8.0)[2][0], tests(kp=5.0, ki=10.0)[2][0], tests(wb=6.0)[2][0]))
print("ALL CHECKS PASS")
