# The retarded Green's function -- the check behind the card.  Standard library only.
# A closed-box loudspeaker (a monopole) in a hall, air at 20 C, switched on at t = 0
# at 440 Hz.  p = sound pressure, Pa.  Roads for the Green's function: the point
# formula; the retarded integral over a small smooth source, by spherical shells;
# a leapfrog grid for r*p; the equation's residual; the flux out of a small sphere.
# Then one hall mode, (88, 0, 0): its ODE by RK4 against the closed forms.
import math
C, RHO, F0 = 343.0, 1.2, 440.0                 # m/s, kg/m^3, Hz
W = 2 * math.pi * F0                           # rad/s
CONE, VC = 0.05, 0.25                          # cone radius m, peak cone speed m/s
Q0 = math.pi * CONE ** 2 * VC                  # peak volume velocity, m^3/s
RL = 17.15                                     # speaker to listener, m
def p_dir(r, t, lag=1.0):                      # road 1: p = rho Q'(t - r/c) / (4 pi r)
    s = t - lag * r / C
    return RHO * Q0 * W * math.cos(W * s) / (4 * math.pi * r) if s >= 0 else 0.0
def sci(v):                                    # e-notation with the same digits in Rust
    e = math.floor(math.log10(abs(v))); m = v / 10 ** e
    return f"{m:.3f}e{'-' if e < 0 else '+'}{abs(e):02d}"
P0 = RHO * Q0 * W / (4 * math.pi * RL)
print(f"omega = {W:.4f} rad/s; wavelength = {C / F0:.4f} m; ka = {W / C * CONE:.4f}; Q0 = {sci(Q0)} m^3/s")
print(f"listener at {RL} m: arrival {1000 * RL / C:.3f} ms; amplitude {P0:.6f} Pa; level {20 * math.log10(P0 / math.sqrt(2) / 2e-5):.2f} dB")
assert abs(P0 - p_dir(RL, RL / C)) < 1e-9 * P0                # the headline amplitude is road 1 at arrival
print(f"by hand: pi a^2 = {math.pi * CONE ** 2:.6f} m^2; rho omega Q0 = {RHO * Q0 * W:.6f}; 4 pi r = {4 * math.pi * RL:.4f} m")
print(f"floor echo, both 1.5 m up: path {math.hypot(RL, 3.0):.4f} m, arrives {1000 * math.hypot(RL, 3.0) / C:.3f} ms")
print("chart, p at listener, 48..54 ms by 0.5 ms: " + ", ".join(f"{1000 * p_dir(RL, 0.048 + 0.0005 * i):.2f}" for i in range(13)))
for t in (0.0499, 0.0505, 0.051):
    print(f"p({RL} m, {1000 * t:.1f} ms) = {p_dir(RL, t):+.6f} Pa")
# ---- the Green's function tested with a click: Q'(t) a Gaussian, peak 1 m^3/s^2 ----
SIG, T0 = 2e-4, 1e-3
def qd(t): return math.exp(-((t - T0) / SIG) ** 2)
def point(r, t): return RHO * qd(t - r / C) / (4 * math.pi * r)
def bump(a): return 105 / (32 * math.pi * a ** 3)       # (1 - rho^2/a^2)^2 bump, total 1
def shells(r, t, a, n=400):                    # road 2: spherical shells round the listener
    h, tot = 2.0 / n, 0.0
    for i in range(n + 1):
        w = -1 + i * h; wt = 1 if i in (0, n) else (4 if i % 2 else 2)
        tot += wt * qd(t - (r + a * w) / C) * (1 - w * w) ** 3
    return RHO / (2 * r) * bump(a) * a ** 3 / 6 * tot * h / 3
def grid(dr, a, ro, te, rmax=1.2):             # road 3: leapfrog for w = r p, w(0) = 0
    n = round(rmax / dr); steps = math.ceil(te * C / (0.5 * dr)); dt = te / steps
    lam2 = (C * dt / dr) ** 2; cb = bump(a)
    src = [RHO * C * C * i * dr * cb * (1 - (i * dr / a) ** 2) ** 2 * dt * dt if i * dr < a else 0.0 for i in range(n + 1)]
    w0, w1 = [0.0] * (n + 1), [0.0] * (n + 1)
    for k in range(1, steps):
        g = qd(k * dt)
        w2 = [0.0] + [2 * w1[i] - w0[i] + lam2 * (w1[i + 1] - 2 * w1[i] + w1[i - 1]) + g * src[i] for i in range(1, n)] + [0.0]
        w0, w1 = w1, w2
    return w1[round(ro / dr)] / ro
ro, te = 1.0, 1.0 / C + T0
pp = point(ro, te)
print(f"click at 1 m, peak time {1000 * te:.4f} ms: point formula {pp:.6f} Pa")
diffs = []
for a in (0.04, 0.02, 0.01):
    sh = shells(ro, te, a); diffs.append(pp - sh)
    print(f"smooth source radius {100 * a:.0f} cm: shells {sh:.6f} Pa, point minus shells {sci(pp - sh)} Pa")
assert all(3.6 < diffs[i] / diffs[i + 1] < 4.4 for i in range(2))   # shrinks as a^2
sh4, errs = shells(ro, te, 0.04), []
for dr in (0.002, 0.001, 0.0005):
    g = grid(dr, 0.04, ro, te); errs.append(abs(g - sh4))
    print(f"grid, step {1000 * dr:.1f} mm: {g:.6f} Pa, error {sci(errs[-1])} Pa")
orders = [math.log2(errs[i] / errs[i + 1]) for i in range(2)]
assert errs[-1] < 1e-3 * sh4 and all(1.8 < o < 2.2 for o in orders)
print("grid observed order: " + ", ".join(f"{o:.2f}" for o in orders))
for h in (0.01, 0.005):                         # road 4: residual of road 1 at the listener
    r, t, k = RL, 0.051, h / C
    ptt = (p_dir(r, t + k) - 2 * p_dir(r, t) + p_dir(r, t - k)) / k ** 2
    lap = (p_dir(r + h, t) - 2 * p_dir(r, t) + p_dir(r - h, t)) / h ** 2 + (p_dir(r + h, t) - p_dir(r - h, t)) / (h * r)
    assert abs(ptt - C * C * lap) < 1e-6 * abs(ptt)
    print(f"residual, step {1000 * h:.0f} mm: p_tt = {ptt:.2f} Pa/s^2, |p_tt - c^2 Lap p| < 1e-6 p_tt")
for r in (0.01, 0.001):                        # road 5: flux out of a small sphere = rho Q'(t)
    t, h = 2 / F0, r * 1e-4
    flux = -4 * math.pi * r * r * (p_dir(r + h, t) - p_dir(r - h, t)) / (2 * h)
    print(f"flux -4 pi r^2 p_r at r = {100 * r:.1f} cm, t = {1000 * t:.4f} ms: {flux:.6f} kg/s^2; rho Q'(t) = {RHO * Q0 * W:.6f}")
assert abs(flux - RHO * Q0 * W) < 1e-4 * RHO * Q0 * W
# ---- the hall: 34.3 m x 20 m x 12 m, rigid walls; mode (88, 0, 0) = cos(88 pi x / LX) ----
LX, LY, LZ = 34.3, 20.0, 12.0; VOL = LX * LY * LZ; XS, XL = 3.43, 20.58
def phi(x): return math.cos(88 * math.pi * x / LX)
def drive(t60=2.0, w=W):                        # forcing per unit mode amplitude, growth rate, cap
    fm = RHO * C * C * Q0 * w * phi(XS) / (VOL / 2); g = 3 * math.log(10) / t60
    return fm, fm / (2 * W), fm / (2 * g * W), g
FM, GROW, CAP, GAM = drive()
print(f"by hand: rho c^2 = {RHO * C * C:.1f} Pa; V/2 = {VOL / 2:.1f} m^3; rho c^2 Q0 omega = {RHO * C * C * Q0 * W:.2f}")
n, hs, tot = 1760, LX / 1760, 0.0               # mode size N = integral of phi^2 over the hall, by Simpson
for i in range(n + 1): tot += (1 if i in (0, n) else (4 if i % 2 else 2)) * phi(i * hs) ** 2
NS = LY * LZ * tot * hs / 3
print(f"mode size by Simpson, Ly Lz * integral of phi^2 dx = {NS:.4f} m^3")
assert abs(FM - RHO * C * C * Q0 * W * phi(XS) / NS) < 1e-6 * abs(FM)
print(f"mode (88,0,0): {88 * C / (2 * LX):.4f} Hz; phi(speaker) = {phi(XS):.6f}, phi(listener) = {phi(XL):.6f}")
print(f"forcing {FM:.4f} Pa/s^2; undamped growth {GROW:.6f} Pa/s; T60 2 s: gamma {GAM:.4f} 1/s, cap {CAP:.6f} Pa")
def rk4(gam, t_out, n_per=128):                # a'' = FM cos(W t) - 2 gam a' - W^2 a, from rest
    dt = 1 / (F0 * n_per); f = lambda t, a, v: FM * math.cos(W * t) - 2 * gam * v - W * W * a
    a = v = t = 0.0; outs = []; k = 0
    for tk in t_out:
        while k < round(tk / dt):
            k1a, k1v = v, f(t, a, v); k2a, k2v = v + dt / 2 * k1v, f(t + dt / 2, a + dt / 2 * k1a, v + dt / 2 * k1v)
            k3a, k3v = v + dt / 2 * k2v, f(t + dt / 2, a + dt / 2 * k2a, v + dt / 2 * k2v)
            k4a, k4v = v + dt * k3v, f(t + dt, a + dt * k3a, v + dt * k3v)
            a += dt / 6 * (k1a + 2 * k2a + 2 * k3a + k4a); v += dt / 6 * (k1v + 2 * k2v + 2 * k3v + k4v); k += 1; t = k * dt
        outs.append(a)
    return outs
t1, t3 = 1 + 1 / (4 * F0), 3 + 1 / (4 * F0)
u1, = rk4(0.0, [t1]); d1, d3 = rk4(GAM, [t1, t3])
c1, cd1 = FM * t1 * math.sin(W * t1) / (2 * W), CAP * (1 - math.exp(-GAM * t1))
print(f"mode at {t1:.6f} s: undamped RK4 {u1:.6f}, t sin t form {c1:.6f}; damped RK4 {d1:.6f}, envelope {cd1:.6f} Pa")
print(f"mode at {t3:.6f} s: damped RK4 {d3:.6f}, steady cap {CAP:.6f} Pa")
assert abs(u1 - c1) < 1e-3 * abs(c1) and abs(u1 - GROW * t1) < 1e-3 * abs(u1) and abs(d1 - cd1) < 2e-3 * abs(cd1) and abs(d3 - CAP) < 1e-3 * abs(CAP)
L = abs(phi(XL))
print(f"at the listener: undamped growth {abs(GROW) * L:.6f} Pa/s; cap with T60 = 2 s {abs(CAP) * L:.6f} Pa")
print("chart, mode at listener, 0..2 s by 0.2 s, undamped: " + ", ".join(f"{1000 * abs(GROW) * L * 0.2 * i:.2f}" for i in range(11)))
print("chart, same, T60 = 2 s: " + ", ".join(f"{1000 * abs(CAP) * L * (1 - math.exp(-GAM * 0.2 * i)):.2f}" for i in range(11)))
bw = GAM / math.pi; cnt = 0; fs = 2000 * math.sqrt(2 / VOL)
for l in range(90):
    for m in range(53):
        for n in range(32):
            if abs(C / 2 * math.sqrt((l / LX) ** 2 + (m / LY) ** 2 + (n / LZ) ** 2) - F0) <= bw / 2: cnt += 1
weyl = 4 * math.pi * VOL * F0 ** 2 / C ** 3 * bw
assert abs(cnt - weyl) < 0.1 * weyl
print(f"half-power width {bw:.4f} Hz; modes inside it: counted {cnt}, Weyl estimate {weyl:.1f}; Schroeder {fs:.2f} Hz, "
      f"{4 * math.pi * VOL * fs ** 2 / C ** 3 * bw:.2f} modes per half-power width there")
print(f"wrong: no delay, p at 10 ms = {RHO * Q0 * W * math.cos(W * 0.01) / (4 * math.pi * RL):+.6f} Pa (retarded {p_dir(RL, 0.01):+.6f} Pa)")
print(f"wrong: advanced, p at -10 ms, before switch-on = {p_dir(RL, -0.01, -1.0):+.6f} Pa (retarded {p_dir(RL, -0.01):+.6f} Pa)")
print(f"wrong: hertz for rad/s {RHO * Q0 * F0 / (4 * math.pi * RL):.6f} Pa; 1/r^2 spreading {P0 / RL:.6f} Pa")
print(f"wrong: undamped mode at listener after 10 s {abs(GROW) * L * 10:.6f} Pa")
cap1 = drive(1.0)[2]; w2 = 2 * math.pi * 437.5
print(f"try: listener at 34.3 m {RHO * Q0 * W / (4 * math.pi * 34.3):.6f} Pa, arrives {1000 * 34.3 / C:.3f} ms; 2 kHz ka = {2 * math.pi * 2000 / C * CONE:.4f}")
print(f"try: T60 = 1 s cap at listener {abs(cap1) * L:.6f} Pa; drive 437.5 Hz, undamped peak {2 * abs(drive(w=w2)[0]) / (W * W - w2 * w2) * L:.6f} Pa")
print("ALL CHECKS PASS")
