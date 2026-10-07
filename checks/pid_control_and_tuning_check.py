# PID control and tuning -- the check behind the card.  Standard library only.
# A small room heated by a radiator through a slow pipe.  Input u: radiator heat, kW, as a change
# from the 1.5 kW that holds 20 C.  Output y: room temperature change, C.  Time in minutes.
# True room: first order plus dead time, gain 2 C/kW, lag 3 min, pipe delay 1 min.
# Roads: (1) fit the model from a noisy bump test two ways; (2) the frequency domain (margins,
# ultimate gain) in closed form; (3) time-domain simulation of the loop, exact step by step.
from math import exp, atan, sqrt, pi, log

K, TAU, TH, DT, M64 = 2.0, 3.0, 1.0, 0.01, (1 << 64) - 1

def splitmix(seed):                              # SplitMix64: uniform numbers in [0, 1)
    s = seed
    def nxt():
        nonlocal s
        s = (s + 0x9E3779B97F4A7C15) & M64
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (z ^ (z >> 31)) / 2.0 ** 64
    return nxt

# ---- road 1: the bump test.  Heat 1.5 -> 2.5 kW at t = 0; thermometer noise +-0.02 C ----
rnd = splitmix(2026)
ts = [n / 10 - 2 for n in range(221)]                       # -2 .. 20 min, every 0.1 min
data = [20 + (K * (1 - exp(-(t - TH) / TAU)) if t > TH else 0) + 0.04 * (rnd() - 0.5) for t in ts]
base = sum(data[:20]) / 20; final = sum(data[-21:]) / 21
def cross(f):                                    # first time the rise passes fraction f, interpolated
    lvl = base + f * (final - base)
    i = next(i for i, v in enumerate(data) if v >= lvl)
    return ts[i - 1] + (lvl - data[i - 1]) / (data[i] - data[i - 1]) * 0.1
t28, t63 = cross(0.283), cross(0.632)
kA, tauA = final - base, 1.5 * (t63 - t28); thA = t63 - tauA
best = None                                      # least squares: grid over delay and lag, gain in closed form
for i in range(81):
    for j in range(201):
        th, tau = 0.8 + 0.005 * i, 2.5 + 0.005 * j
        f = [1 - exp(-(t - th) / tau) if t > th else 0.0 for t in ts]
        k = sum(a * (v - base) for a, v in zip(f, data)) / sum(a * a for a in f)
        sse = sum((v - base - k * a) ** 2 for a, v in zip(f, data))
        if best is None or sse < best[0]: best = (sse, k, tau, th)
print("room: K = 2 C/kW, tau = 3 min, theta = 1 min; bump 1.5 -> 2.5 kW at t = 0; noise +-0.02 C")
print(f"bump, read off: base {base:.3f} C, final {final:.3f} C, t28 {t28:.3f} min, t63 {t63:.3f} min")
print(f"fit, two-point:     K {kA:.3f} C/kW  tau {tauA:.3f} min  theta {thA:.3f} min  (t63 - t28 = {t63 - t28:.4f} min)")
print(f"two-point constants: ln(1/(1 - 0.283)) = {-log(1 - 0.283):.4f}, ln(1/(1 - 0.632)) = {-log(1 - 0.632):.4f}")
_, kB, tauB, thB = best; print(f"fit, least squares: K {kB:.3f} C/kW  tau {tauB:.3f} min  theta {thB:.3f} min")
assert abs(kA - K) < 0.03 and abs(tauA - TAU) < 0.1 and abs(thA - TH) < 0.05   # recovers the room
assert abs(kB - K) < 0.02 and abs(tauB - TAU) < 0.05 and abs(thB - TH) < 0.03

# ---- road 2: frequency domain.  L(jw) = C(jw) K e^(-j w theta) / (1 + j w tau) ----
def L(w, kp, ti, td, k=K, tau=TAU, th=TH):
    c = td * w - (1 / (ti * w) if ti else 0.0)                  # PID: kp (1 + j c)
    return kp * sqrt(1 + c * c) * k / sqrt(1 + (w * tau) ** 2), atan(c) - atan(w * tau) - w * th
def first(fn, lo=0.01):                          # scan up for a sign change of fn, then bisect it
    w = lo
    while fn(w) * fn(w * 1.01) > 0: w *= 1.01
    a, b = w, w * 1.01
    for _ in range(60):
        m = (a + b) / 2
        if fn(a) * fn(m) <= 0: b = m
        else: a = m
    return a
def margins(kp, ti, td, **kw):
    wc = first(lambda w: L(w, kp, ti, td, **kw)[0] - 1)
    w180 = first(lambda w: L(w, kp, ti, td, **kw)[1] + pi)
    return 1 / L(w180, kp, ti, td, **kw)[0], (pi + L(wc, kp, ti, td, **kw)[1]) * 180 / pi, wc, w180
_, _, _, wu = margins(1.0, None, 0.0)
ku, pu = sqrt(1 + (wu * TAU) ** 2) / K, 2 * pi / wu
print(f"ultimate, frequency domain: wu {wu:.4f} rad/min  Ku {ku:.4f} kW/C  Pu {pu:.4f} min")

# ---- road 3: simulate the loop.  Exact step for the lag, a buffer for the pipe delay ----
def loop(kp, ti, td, k=K, tau=TAU, th=TH, r=1.0, dist=-0.5, tdist=20.0, tend=40.0, umax=None, aw=True, dt=DT):
    a, nd = exp(-dt / tau), round(th / dt); buf = [0.0] * nd; y = yp = ip = 0.0; ys = []
    for n in range(round(tend / dt) + 1):
        ys.append(y); e = r - y
        ui = ip + (kp / ti * e * dt if ti else 0.0)            # integral term
        u = kp * e + ui - kp * td * (y - yp) / dt              # derivative acts on the measurement
        if umax is not None and abs(u) > umax:
            u = umax if u > 0 else -umax
            if aw: ui = ip                                     # anti-windup: stop integrating
        ip, yp = ui, y
        ud = buf[n % nd]; buf[n % nd] = u
        y = a * y + (1 - a) * k * (ud + (dist if n * dt >= tdist else 0.0))
    return ys
def growth(kp, ti, td, **kw):                    # swing in 40..60 min over swing in 20..40 min, no disturbance
    ys, n = loop(kp, ti, td, dist=0.0, tend=60.0, **kw), round(20 / kw.get("dt", DT))
    return max(abs(v - 1) for v in ys[2 * n:]) / max(abs(v - 1) for v in ys[n:2 * n])
lo, hi = 2.0, 3.5
for _ in range(40):
    m = (lo + hi) / 2
    if growth(m, None, 0.0) > 1: hi = m
    else: lo = m
ys = loop(lo, None, 0.0, dist=0.0, tend=60.0)
up = [n * DT for n in range(3001, 6000) if ys[n - 1] < 1 <= ys[n]]
print(f"ultimate, simulation:       Ku {lo:.4f} kW/C  Pu {(up[-1] - up[0]) / (len(up) - 1):.4f} min")
assert abs(lo / ku - 1) < 0.01 and abs((up[-1] - up[0]) / (len(up) - 1) / pu - 1) < 0.01

TUNE = {"ZN PID": (1.2 * TAU / (K * TH), 2 * TH, 0.5 * TH), "lambda PI": (TAU / (K * (1.0 + TH)), TAU, 0.0)}   # lambda = 1 min
for name, g in TUNE.items():
    gm, pm, wc, w180 = margins(*g)
    ys = loop(*g)
    ov, settle = max(ys[:2000]) - 1, max(n for n in range(2000) if abs(ys[n] - 1) > 0.02) * DT
    dip, iae = 1 - min(ys[2000:]), sum(abs(1 - v) for v in ys[2000:]) * DT
    print(f"{name:9s}: Kp {g[0]:.3f} kW/C  Ti {g[1]:.3f} min  Td {g[2]:.3f} min  Ki {g[0] / g[1]:.3f}  Kd {g[0] * g[2]:.3f}")
    print(f"{name:9s}: GM {gm:.3f}  PM {pm:.2f} deg  wc {wc:.4f}  w180 {w180:.4f} rad/min")
    ie = sum(1 - v for v in loop(*g, tend=60.0)[2000:]) * DT
    print(f"{name:9s}: overshoot {ov:.3f} C  settles (2%) {settle:.2f} min  door dip {dip:.3f} C  IAE {iae:.3f} C min")
    print(f"{name:9s}: error at 40 min {abs(1 - ys[-1]):.4f} C; door error, integrated {ie:.4f} C min (0.5/Ki = {0.5 * g[1] / g[0]:.4f})")
    assert abs(1 - ys[-1]) < 0.005 and abs(ie / (0.5 * g[1] / g[0]) - 1) < 0.002   # integral action: no offset
    assert growth(g[0] * gm * 0.98, g[1], g[2]) < 1 < growth(g[0] * gm * 1.02, g[1], g[2])   # GM is the edge
gm, pm, wc, _ = margins(*TUNE["lambda PI"])
print(f"lambda PI, by hand: GM = pi = {pi:.3f}  PM = 90 - 0.5 rad = {90 - 0.5 * 180 / pi:.2f} deg  wc = 0.5")
assert abs(gm - pi) < 1e-6 and abs(pm - (90 - 0.5 * 180 / pi)) < 1e-6 and abs(wc - 0.5) < 1e-6

# ---- what breaks ----
ys = loop(1.8, None, 0.0, dist=0.0, tend=80.0)
print(f"wrong: P only, Kp 1.8: error left {1 - ys[-1]:.4f} C (formula 1/(1 + K Kp) = {1 / (1 + K * 1.8):.4f})")
assert abs(1 - ys[-1] - 1 / (1 + K * 1.8)) < 1e-3
print(f"wrong: P only at 1.1 Ku = {1.1 * ku:.3f}: swing grows x{growth(1.1 * ku, None, 0.0):.2f} per 20 min")
for aw in (False, True):
    ys = loop(*TUNE["lambda PI"], r=2.5, dist=0.0, umax=1.5, aw=aw)
    print(f"windup: lambda PI, 2.5 C step, heater 0..3 kW, anti-windup {'on ' if aw else 'off'}:"
          f" overshoot {max(max(ys) - 2.5, 0.0):.3f} C, settles (2%) {max(n for n in range(4001) if abs(ys[n] - 2.5) > 0.05) * DT:.2f} min")
for name, g in TUNE.items():
    gm, pm, _, _ = margins(*g, th=2.0)
    print(f"wrong: pipe delay 2 min, {name:9s}: GM {gm:.3f}  PM {pm:.2f} deg  swing x{growth(*g, th=2.0):.3f} per 20 min")
    assert (gm > 1) == (growth(*g, th=2.0) < 1)                # frequency domain and simulation agree
print(f"outside the model: 4 C setpoint asks {4 / K:.1f} kW extra; heater gives 1.5, room tops out at {20 + 1.5 * K:.1f} C")
print(f"try: lambda = 3 min: Kp {TAU / (K * 4):.4f}  GM {margins(TAU / (K * 4), TAU, 0.0)[0]:.3f}")
g3 = growth(*TUNE["ZN PID"], k=3.0); print(f"try: ZN PID on K = 3 room: GM {margins(*TUNE['ZN PID'], k=3.0)[0]:.3f}  swing x{g3:.3f} per 20 min")
assert g3 > 1 and growth(1.1 * ku, None, 0.0) > 1              # GM below 1: the simulation grows too
zf = loop(*TUNE["ZN PID"], dt=0.001); print(f"finer step 0.001 min, ZN PID: overshoot {max(zf[:20000]) - 1:.3f} C  settles (2%) {max(n for n in range(20000) if abs(zf[n] - 1) > 0.02) * 0.001:.2f} min  swing x{growth(*TUNE['ZN PID'], k=3.0, dt=0.001):.2f} (K = 3), x{growth(*TUNE['ZN PID'], th=2.0, dt=0.001):.2f} (delay 2 min)")
print(f"try: lambda PI, longest pipe delay it survives: {1 + (pi / 2 - 0.5) / 0.5:.3f} min")
assert growth(*TUNE["lambda PI"], th=3.10) < 1 < growth(*TUNE["lambda PI"], th=3.20)   # simulation agrees
print("chart, bump t min    " + " ".join(f"{ts[n]:5.0f}" for n in range(0, 221, 10)))
print("chart, bump data C   " + " ".join(f"{data[n]:5.2f}" for n in range(0, 221, 10)))
print("chart, bump fit C    " + " ".join(f"{base + (kA * (1 - exp(-(ts[n] - thA) / tauA)) if ts[n] > thA else 0):5.2f}" for n in range(0, 221, 10)))
zn, lam = loop(*TUNE["ZN PID"]), loop(*TUNE["lambda PI"])
print("chart, loop t min    " + " ".join(f"{n:5d}" for n in range(41)))
print("chart, ZN PID C      " + " ".join(f"{20 + zn[n * 100]:5.2f}" for n in range(41)))
print("chart, lambda PI C   " + " ".join(f"{20 + lam[n * 100]:5.2f}" for n in range(41)))
print("ALL CHECKS PASS")
