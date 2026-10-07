# Step response specs -- the check behind the card.  Standard library only.
# One panel of a centre-opening lift door: mass m on a rail, a closing spring k_s, and a
# drive pushing F = K_p (r - x) - b v (b lumps the drive's velocity feedback and the rail):
#   m x'' + b x' + (K_p + k_s) x = K_p r,   r = 0.45 m of commanded travel.
# The four numbers by three roads: the closed form; an RK4 step test read off like a scope
# trace; and the poles recovered from the measured overshoot and peak time.
import math

m, b, k_s, K_p, r = 40.0, 300.0, 40.0, 960.0, 0.45    # kg, N s/m, N/m, N/m, m
RISE, OVER, SETTLE, ERR = 0.5, 0.05, 1.5, 0.01 * r     # the written spec: s, fraction, s, m

def bisect(f, lo, hi):                                  # f changes sign on [lo, hi]
    neg = f(lo) < 0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if (f(mid) < 0) == neg: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def unit_step(t, z):                                    # prototype step, omega_n = 1, final 1
    if z == 1.0: return 1 - math.exp(-t) * (1 + t)
    wd = math.sqrt(1 - z * z)
    return 1 - math.exp(-z * t) * (math.cos(wd * t) + z / wd * math.sin(wd * t))

def rise_norm(z):                                       # omega_n x (10-90% rise time)
    return bisect(lambda t: unit_step(t, z) - 0.9, 0, 6) - bisect(lambda t: unit_step(t, z) - 0.1, 0, 6)

def step_test(Kp=K_p, bb=b, tau_m=0.0, fmax=1e9, T=6.0, dt=1e-3):
    def f(s):                                           # state: position, speed, drive force
        x, v, F = s
        Fc = max(-fmax, min(fmax, Kp * (r - x) - bb * v))
        Fd, dF = (Fc, 0.0) if tau_m == 0 else (F, (Fc - F) / tau_m)
        return [v, (Fd - k_s * x) / m, dF]
    s, rec = [0.0, 0.0, 0.0], [(0.0, 0.0)]
    for i in range(int(round(T / dt))):
        k1 = f(s); k2 = f([a + 0.5 * dt * d for a, d in zip(s, k1)])
        k3 = f([a + 0.5 * dt * d for a, d in zip(s, k2)]); k4 = f([a + dt * d for a, d in zip(s, k3)])
        s = [a + dt / 6 * (p + 2 * q + 2 * u + w) for a, p, q, u, w in zip(s, k1, k2, k3, k4)]
        rec.append(((i + 1) * dt, s[0]))
    return rec

def measure(rec):                                       # read the four numbers off a trace
    yf = rec[-1][1]
    def cross(level):
        for (t0, x0), (t1, x1) in zip(rec, rec[1:]):
            if x1 >= level: return t0 + (level - x0) / (x1 - x0) * (t1 - t0)
    tp, peak = max(rec, key=lambda p: p[1])
    band, ts = 0.02 * yf, 0.0
    for (t0, x0), (t1, x1) in zip(rec, rec[1:]):
        e0, e1 = abs(x0 - yf), abs(x1 - yf)
        if e0 > band >= e1: ts = t0 + (e0 - band) / (e0 - e1) * (t1 - t0)
    return cross(0.9 * yf) - cross(0.1 * yf), peak / yf - 1, ts, r - yf, tp, peak, yf

def show(label, q):
    tr, ov, ts, er = q[:4]
    print(f"{label:<26} rise {tr:6.3f} s  over {100 * ov:6.2f} %  settle {ts:6.3f} s  error {1000 * er:6.2f} mm")

# ---- road 1: closed form from the coefficients ----
k = K_p + k_s
wn = math.sqrt(k / m); z = b / (2 * m * wn); sig = z * wn; wd = wn * math.sqrt(1 - z * z)
yinf = K_p / k * r
tp1, Mp1, tr1 = math.pi / wd, math.exp(-sig * math.pi / wd), rise_norm(z) / wn
ex = lambda t: abs(yinf * unit_step(wn * t, z) - yinf) - 0.02 * yinf
t_out = next(i * 1e-3 for i in range(4000, 0, -1) if ex(i * 1e-3) > 0)
ts1 = bisect(ex, t_out, t_out + 1e-3)
print(f"door: m = {m:.0f} kg, b = {b:.0f} N s/m, k_s = {k_s:.0f} N/m, K_p = {K_p:.0f} N/m, command r = {1000 * r:.0f} mm")
print(f"zeta = {z:.4f}, omega_n = {wn:.4f} rad/s, sigma = {sig:.4f} 1/s, omega_d = {wd:.4f} rad/s")
print(f"final {1000 * yinf:.2f} mm = K_p/(K_p + k_s) r; steady error {1000 * (r - yinf):.2f} mm = {100 * (r - yinf) / r:.2f} % of travel")
print(f"hand: 4 m k - b^2 = {4 * m * k - b * b:.0f}, sqrt(1 - zeta^2) = {math.sqrt(1 - z * z):.4f}, sigma pi/omega_d = {sig * math.pi / wd:.4f}, ln 0.05 = {math.log(OVER):.4f}, sqrt(pi^2 + ln^2 0.05) = {math.sqrt(math.pi ** 2 + math.log(OVER) ** 2):.4f}, ln 50 = {math.log(50):.4f}")
print(f"road 1 closed form:  rise {tr1:.4f} s  peak time {tp1:.4f} s  over {100 * Mp1:.4f} %  settle {ts1:.4f} s")
print(f"  rise in omega_n units {rise_norm(z):.4f}; settle rules: 4/sigma {4 / sig:.4f} s, envelope {(math.log(50) - 0.5 * math.log(1 - z * z)) / sig:.4f} s")

# ---- road 2: the step test, measured off the simulated trace ----
rec = step_test()
q = measure(rec)
print(f"road 2 RK4 trace:    rise {q[0]:.4f} s  peak time {q[4]:.4f} s  over {100 * q[1]:.4f} %  settle {q[2]:.4f} s")
print(f"  peak {1000 * q[5]:.2f} mm, final {1000 * q[6]:.2f} mm, error {1000 * q[3]:.2f} mm")

# ---- road 3: the poles, recovered from the measured trace and from the polynomial ----
L = math.log(q[1])
z_id = -L / math.sqrt(math.pi ** 2 + L * L); wn_id = math.pi / (q[4] * math.sqrt(1 - z_id ** 2))
re, im = -b / (2 * m), math.sqrt(4 * m * k - b * b) / (2 * m)          # roots of m s^2 + b s + k
print(f"road 3 poles from trace: zeta {z_id:.4f}, omega_n {wn_id:.4f} rad/s -> {-z_id * wn_id:.4f} +- {wn_id * math.sqrt(1 - z_id ** 2):.4f} j")
print(f"       roots of 40 s^2 + 300 s + 1000: {re:.4f} +- {im:.4f} j, |p| = {math.hypot(re, im):.4f}, zeta = {-re / math.hypot(re, im):.4f}")
print("chart, t (s)  " + " ".join(f"{t:.1f}" for t, x in rec[0:2001:100]))
print("chart, x (mm) " + " ".join(f"{1000 * x:.2f}" for t, x in rec[0:2001:100]))
print(f"chart, 2% band {1000 * 1.02 * q[6]:.2f} and {1000 * 0.98 * q[6]:.2f} mm")

# ---- the written spec turned into a target region for the poles ----
zmin = -math.log(OVER) / math.sqrt(math.pi ** 2 + math.log(OVER) ** 2)
zmin_b = bisect(lambda u: math.exp(-math.pi * u / math.sqrt(1 - u * u)) - OVER, 0.01, 0.99)
th = math.degrees(math.acos(zmin))
print(f"spec over < 5 %:    zeta >= {zmin:.4f} (bisection {zmin_b:.4f}), within {th:.2f} deg of the negative real axis")
print(f"spec settle 1.5 s:  sigma >= 4/1.5 = {4 / SETTLE:.4f} 1/s (rule); envelope at zeta_min {(math.log(50) - 0.5 * math.log(1 - zmin ** 2)) / SETTLE:.4f} 1/s")
for zz in (zmin, 0.75, 1.0):
    print(f"spec rise 0.5 s:    at zeta {zz:.4f}, omega_n t_r = {rise_norm(zz):.4f}, so omega_n >= {rise_norm(zz) / RISE:.4f} rad/s")
wn_err = math.sqrt(k_s * r / (m * ERR))                # error = r k_s / (m omega_n^2) while m, k_s are fixed
print(f"spec error 4.5 mm:  K_p/(K_p + k_s) >= {1 - ERR / r:.2f}, so K_p >= {k_s * (r - ERR) / ERR:.0f} N/m; with m, k_s fixed, omega_n >= {wn_err:.4f} rad/s")
for name, ok in (("rise", q[0] <= RISE), ("overshoot", q[1] < OVER), ("settle", q[2] <= SETTLE), ("steady error", q[3] <= ERR)):
    print(f"door A {name:<13} {'meets' if ok else 'FAILS'} the spec")
S, X0, Y0 = 25.0, 320.0, 120.0                         # svg: 25 px per 1/s, origin at (320, 120)
px = lambda a, w: f"({X0 + S * a:.1f},{Y0 - S * w:.1f})"
im2 = math.sqrt(4 * m * k - 200.0 ** 2) / (2 * m)
edge = Y0 / math.tan(math.radians(th))
curve = [(zz, rise_norm(zz) / RISE) for zz in (zmin, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0)]
print(f"figure, poles {px(re, im)} {px(re, -im)}; b = 200 poles {px(-200 / (2 * m), im2)} {px(-200 / (2 * m), -im2)}")
print(f"figure, wedge to ({X0 - edge:.1f},0) and ({X0 - edge:.1f},240); 4/1.5 line x = {X0 - S * 4 / SETTLE:.1f}")
print("figure, rise edge " + " ".join(px(-w * zz, w * math.sqrt(1 - zz * zz)) for zz, w in curve))
ax = math.sqrt(wn_err ** 2 - (Y0 / S) ** 2)
print(f"figure, error arc radius {S * wn_err:.1f}: {px(-ax, Y0 / S)} {px(-wn_err, 0)} {px(-ax, -Y0 / S)}")

# ---- what breaks, and the try-changing runs ----
qa = measure(step_test(tau_m=0.1))
show("drive lag 0.1 s", qa)
print(f"  prototype formula from zeta, omega_n still says over {100 * Mp1:.2f} %")
print(f"overshoot read against the 450 mm command: {100 * (q[5] / r - 1):.2f} %")
show("drive force capped 100 N", measure(step_test(fmax=100.0)))
show("try K_p = 3960", measure(step_test(Kp=3960.0)))
show("try b = 400 (zeta 1)", measure(step_test(bb=400.0)))
show("try b = 200 (zeta 0.5)", measure(step_test(bb=200.0)))
q4 = measure(step_test(Kp=3960.0, bb=600.0))
show("try K_p = 3960, b = 600", q4)
wn4 = math.hypot(-600 / (2 * m), math.sqrt(4 * m * 4000 - 600 ** 2) / (2 * m))
print(f"  K_p = 3960: zeta {b / (2 * math.sqrt(m * 4000)):.4f}, omega_n {math.sqrt(4000 / m):.4f} rad/s; with b = 600: zeta {600 / (2 * math.sqrt(m * 4000)):.4f}")
print(f"  drive force at t = 0: {K_p * r:.0f} N for door A, {3960 * r:.0f} N for K_p = 3960")

assert abs(q[0] - tr1) < 1e-3                              # 10-90 rise, trace vs bisection on the closed form
assert abs(q[4] - tp1) < 2e-3                              # peak time, trace vs pi / omega_d
assert abs(q[1] - Mp1) < 1e-5                              # measured overshoot vs exp(-pi zeta / sqrt(1 - zeta^2))
assert abs(q[2] - ts1) < 1e-3                              # last exit from the band, trace vs bisection
assert abs(z_id - (-re / math.hypot(re, im))) < 1e-3       # poles from the trace vs roots of the polynomial
assert abs(wn_id - math.hypot(re, im)) < 2e-3            # omega_n from the trace vs |root|
assert abs(zmin - zmin_b) < 1e-9                           # inverse overshoot formula vs bisection
assert abs(q[6] - yinf) < 1e-6                             # settled trace vs K_p r / (K_p + k_s)
assert abs(q4[3] - r * k_s / (m * wn4 ** 2)) < 1e-6        # stiff door: trace error vs r k_s / (m |pole|^2)
print("ALL CHECKS PASS")
