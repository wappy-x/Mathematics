# H-infinity design in outline -- the check behind the card.  Standard library only.
# Conveyor: drive torque u (N m) -> roller speed v (rad/s).  P(s) = 1/((J s + b)(tau s + 1)).
# A load bump d = 0.5 sin(2 pi 2 t) N m acts on the belt, so it reaches the speed through 1/(J s + b) times S.
# Controller family: K(s) = Kp + Ki/s + Kr s/(s^2 + w0^2), with w0 the bump's 2 Hz in rad/s.
from math import pi, sqrt, hypot, sin
J0, JH, JF, B, TAU, D0 = 0.20, 0.30, 0.40, 0.40, 0.02, 0.5   # kg m^2 (empty, half, full), N m s/rad, s, N m
W0, WB, M, A = 4 * pi, 4.0, 2.0, 0.01                         # rad/s (2 Hz); the spec from Robust tests
FINE = [10 ** (-2 + 5 * i / 2000) for i in range(2001)]       # 0.01 to 1000 rad/s
COARSE = FINE[::8]

def wp(w, zd):   # performance weight |W_P|: 1/|W_P| is the |S| allowed; zd = 0 means no 2 Hz peak
    v = abs(complex(WB, w / M)) / abs(complex(WB * A, w))
    return v * abs(complex(W0 * W0 - w * w, 2 * 0.5 * W0 * w)) / abs(complex(W0 * W0 - w * w, 2 * zd * W0 * w)) if zd else v

def wm(w): return 0.5 * w / hypot(w, 1.0)   # model-error envelope |W|, from Writing down model error

def loop(w, k, J=J0):   # |S|, |T|, |K S|, |speed per N m of load|; products only, no complex division
    kp, ki, kr = k
    q = W0 * W0 - w * w if kr else 1.0
    dp = complex(B, J * w) * complex(1.0, TAU * w)
    nk, dk = complex(ki * q - kr * w * w, kp * w * q), complex(0.0, w * q)
    dd = abs(dk * dp + nk)
    return abs(dk * dp) / dd, abs(nk) / dd, abs(nk * dp) / dd, abs(dk * complex(1.0, TAU * w)) / dd

def stack(w, k, sp):   # the mixed-sensitivity stack [W_P S; W_U K S; W T] at one frequency; sp = (zd, wt, wu)
    s, t, ks, _ = loop(w, k)
    a, b, c = wp(w, sp[0]) * s, sp[2] * ks, sp[1] * wm(w) * t
    return sqrt(a * a + b * b + c * c)

def norm(k, sp, grid=FINE):   # the H-infinity norm: the peak over frequency, with where it sits
    return max((stack(w, k, sp), w) for w in grid)

def design(sp, res=True):   # coarse grid of controllers, then a pattern search; res=False keeps Kr = 0
    best = min((norm([a * 1.0, b * 1.0, c * 4.0], sp, COARSE)[0], [a * 1.0, b * 1.0, c * 4.0])
               for a in range(13) for b in range(13) for c in range(11 if res else 1))
    g, k, step = norm(best[1], sp)[0], best[1], 0.5
    while step > 1e-3:
        moved = False
        for i in range(3 if res else 2):
            for d in (step, -step):
                y = k[:]; y[i] = max(0.0, y[i] + d)
                gy = norm(y, sp)[0]
                if gy < g: g, k, moved = gy, y, True
        if not moved: step /= 2
    return k

def floor(w, sp):   # Step 3: the least the stack can be at w over every complex S, since S + T = 1 and K S = T/P
    a, ct = wp(w, sp[0]), sp[1] * wm(w)
    cu = sp[2] * abs(complex(B, J0 * w) * complex(1.0, TAU * w))
    c = sqrt(cu * cu + ct * ct)
    return a * c / sqrt(a * a + c * c)

def brute(w, sp):   # the same least value by brute force: the stack at each S on a grid, then a 100x finer grid round the best
    pinv = complex(B, J0 * w) * complex(1.0, TAU * w)          # 1/P at jw, so K S = T/P = (1 - S)/P
    def f(x, y):
        a, b, c = wp(w, sp[0]) * hypot(x, y), sp[2] * abs(complex(1 - x, -y) * pinv), sp[1] * wm(w) * hypot(1 - x, y)
        return sqrt(a * a + b * b + c * c)
    x, y = 0.5, 0.0
    for h in (0.01, 1e-4):
        v, x, y = min((f(x + i * h, y + k * h), x + i * h, y + k * h) for i in range(-100, 101) for k in range(-100, 101))
    return v

def simulate(k, J, wd=W0, t_end=30.0, dt=1e-3):   # RK4 on torque q, speed v, integral z, resonator r1, r2
    kp, ki, kr = k
    def f(t, x):
        q, v, z, r1, r2 = x
        return [(kp * -v + ki * z + kr * r2 - q) / TAU, (q - B * v - D0 * sin(wd * t)) / J, -v, r2, -W0 * W0 * r1 - v]
    x, lo, hi, n = [0.0] * 5, 0.0, 0.0, int(round(t_end / dt))
    for i in range(n):
        t = i * dt
        k1 = f(t, x); k2 = f(t + dt / 2, [a + dt / 2 * b for a, b in zip(x, k1)])
        k3 = f(t + dt / 2, [a + dt / 2 * b for a, b in zip(x, k2)]); k4 = f(t + dt, [a + dt * b for a, b in zip(x, k3)])
        x = [a + dt / 6 * (p + 2 * q + 2 * r + s) for a, p, q, r, s in zip(x, k1, k2, k3, k4)]
        if i >= n - 5000: lo, hi = min(lo, x[1]), max(hi, x[1])
    return (hi - lo) / 2   # half the peak-to-peak speed swing over the last 5 s

def routh(k, J):   # s (s^2 + w0^2)(J s + b)(tau s + 1) + Kp s (s^2 + w0^2) + Ki (s^2 + w0^2) + Kr s^2
    kp, ki, kr = k
    a = [J * TAU, J + B * TAU, B + J * TAU * W0 * W0 + kp, (J + B * TAU) * W0 * W0 + ki + kr, (B + kp) * W0 * W0, ki * W0 * W0]
    rows = [a[0::2], a[1::2]]
    while len(rows) < len(a):
        r0, r1 = rows[-2], rows[-1] + [0.0]
        rows.append([(r1[0] * r0[i + 1] - r0[0] * r1[i + 1]) / r1[0] for i in range(len(r0) - 1)])
    return min(r[0] for r in rows)   # stable when every first-column entry is positive

FLAT, PEAK = (0.0, 1.0, 0.05), (0.1, 1.0, 0.05)
print(f"conveyor: J = {J0:.2f} to {JF:.2f} kg m^2, b = {B:.2f} N m s/rad, tau = {TAU:.2f} s; bump {D0:.1f} N m at 2 Hz = {W0:.4f} rad/s")
ga = hypot(B, J0 * W0)
print(f"no control: |{B:.2f} + {J0 * W0:.4f}j| = {ga:.4f}; ripple = {D0:.1f}/{ga:.4f} = {D0 / ga:.4f} rad/s")
print(f"weights: M = {M:.0f}, wB = {WB:.0f} rad/s, A = {A:.2f}; 2 Hz peak {0.5 / 0.1:.0f}x (zn = 0.5, zd = 0.1); W_U = 0.05, 1/W_U = {1 / 0.05:.0f} N m per rad/s")
ka, kb = design(FLAT), design(PEAK)
for name, k, sp in (("A, flat weight ", ka, FLAT), ("B, 2 Hz peak   ", kb, PEAK)):
    g, wg = norm(k, sp)
    fl, wf = max((floor(w, sp), w) for w in FINE)                # no controller of any form gets below this
    print(f"design {name}: Kp = {k[0]:.3f}, Ki = {k[1]:.3f}, Kr = {k[2]:.3f}; gamma = {g:.4f} at {wg:.2f} rad/s; floor {fl:.4f} at {wf:.2f} rad/s")
    gd, bf = norm(k, sp, [10 ** (-2 + 5 * i / 8000) for i in range(8001)])[0], brute(wf, sp)
    print(f"  floor at {wf:.2f} rad/s: formula {fl:.4f}, brute force over complex S {bf:.4f}")
    assert fl <= g < 1 and abs(gd - g) < 1e-3 and abs(bf - fl) < 1e-5   # under 1; above the floor; finer grids agree
assert abs(max(floor(w, FLAT) for w in FINE) - 1 / M) < 1e-3              # flat weight: the floor is the high-frequency limit 1/M
s, t, ks, gd = loop(W0, ka)
kA, dA = complex(ka[0], -ka[1] / W0), complex(B, J0 * W0) * complex(1.0, TAU * W0)   # K(j w0); the plant's bottom, 1/P(j w0)
p, n2 = kA * dA.conjugate(), dA.real * dA.real + dA.imag * dA.imag; LA = complex(p.real / n2, p.imag / n2)   # L = K/bottom
print(f"hand A at 2 Hz: K = {kA.real:.4f} {kA.imag:+.4f}j, bottom = {dA.real:.4f} {dA.imag:+.4f}j, L = K/bottom = {LA.real:.5f} {LA.imag:+.5f}j, |L| = {abs(LA):.4f}, |K| = {abs(kA):.4f}, |1 + L| = {abs(1 + LA):.5f}")
print(f"hand A at 2 Hz: |S| = {s:.4f}, |T| = {t:.4f}, |K S| = {ks:.4f}, |W_P| = {wp(W0, 0.0):.4f}, |W| = {wm(W0):.4f}")
a2, b2, c2 = wp(W0, 0.0) * s * (wp(W0, 0.0) * s), 0.05 * ks * (0.05 * ks), wm(W0) * t * (wm(W0) * t)
print(f"hand A at 2 Hz: stack = sqrt({a2:.4f} + {b2:.4f} + {c2:.4f}) = {sqrt(a2 + b2 + c2):.4f}; ripple = {D0:.1f} x {s:.4f}/{ga:.4f} = {D0 * gd:.4f} rad/s")
assert abs(s / ga - gd) < 1e-12 and abs(sqrt(a2 + b2 + c2) - stack(W0, ka, FLAT)) < 1e-12 and abs(abs(1 + LA) * s - 1) < 1e-12 and abs(LA * dA - kA) < 1e-12
s, t, ks, gd = loop(W0, kb)
print(f"hand B at 2 Hz: |S| = {s:.4f}, |T| = {t:.4f}, |K S| = {ks:.4f}, |W_P| = {wp(W0, 0.1):.4f}; stack = {stack(W0, kb, PEAK):.4f}")
print("chart: w (rad/s), allowed 1/|W_P|, |S| A, |S| B empty, |S| B full")
for w in (1.0, 2.0, 4.0, 6.0, 8.0, 10.0, 11.0, W0, 14.0, 16.0, 20.0, 40.0, 100.0):
    print(f"chart, {w:7.3f}, {1 / wp(w, 0.1):.3f}, {loop(w, ka)[0]:.3f}, {loop(w, kb)[0]:.3f}, {loop(w, kb, JF)[0]:.3f}")
for name, k in (("A", ka), ("B", kb)):
    for J in (J0, JF):
        r_f, r_t = D0 * loop(W0, k, J)[3], simulate(k, J)
        print(f"ripple {name}, J = {J:.2f}: formula {r_f:.4f} rad/s, RK4 after 30 s {r_t:.4f} rad/s")
        assert abs(r_f - r_t) < 1e-4                               # frequency road and time road agree
print("Routh, design B, lowest first-column entry: " + ", ".join(f"J = {J:.2f}: {routh(kb, J):.4f}" for J in (J0, JH, JF)))
assert min(routh(kb, J) for J in (J0, JH, JF)) > 0
rs = max((wm(w) * loop(w, kb)[1], w) for w in FINE)
rp = max((wp(w, 0.1) * loop(w, kb)[0] + wm(w) * loop(w, kb)[1], w) for w in FINE)
real = [max((wp(w, 0.1) * loop(w, kb, J)[0], w) for w in FINE) for J in (J0, JH, JF)]
print(f"design B: peak |W T| = {rs[0]:.4f} at {rs[1]:.2f} rad/s; peak |W_P S| + |W T| = {rp[0]:.4f} at {rp[1]:.2f} rad/s; sqrt(2) x gamma = {sqrt(2) * norm(kb, PEAK)[0]:.4f}")
print("design B, real belts, peak |W_P S_J|: " + ", ".join(f"{v:.4f} at {w:.2f} rad/s" for v, w in real))
assert rs[0] < norm(kb, PEAK)[0] < 1 < rp[0] < sqrt(2) and real[2][0] > 1   # stability certified, performance not
print(f"wrong: 11-point grid gives gamma = {norm(kb, PEAK, FINE[::200])[0]:.4f}")
kpi = design(PEAK, res=False); gpi, wpi = norm(kpi, PEAK); hump = max((stack(w, kpi, PEAK), w) for w in FINE if w > 30)
print(f"wrong: peaked weight, plain PI: Kp = {kpi[0]:.3f}, Ki = {kpi[1]:.3f}; gamma = {gpi:.4f} at {wpi:.2f} rad/s, {hump[0]:.4f} at {hump[1]:.2f} rad/s; at 2 Hz |S| = {loop(W0, kpi)[0]:.4f}, stack {stack(W0, kpi, PEAK):.4f}")
kw = design((0.1, 0.0, 0.05))
print(f"wrong: no model-error weight: Kp = {kw[0]:.3f}, Ki = {kw[1]:.3f}, Kr = {kw[2]:.3f}; gamma {norm(kw, (0.1, 0.0, 0.05))[0]:.4f}, with W restored {norm(kw, PEAK)[0]:.4f}")
assert hump[0] > 1 > loop(W0, kpi)[0] * wp(W0, 0.1) and norm(kw, PEAK)[0] > 1 > norm(kw, (0.1, 0.0, 0.05))[0]   # PI meets 2 Hz, not the stack
w24 = 2 * pi * 2.4
r24 = [D0 * loop(w24, k, J)[3] for k in (ka, kb) for J in (J0, JF)]
print(f"wrong: bump at 2.4 Hz: A {r24[0]:.4f}, {r24[1]:.4f}; B {r24[2]:.4f}, {r24[3]:.4f} rad/s (empty, full); no control {D0 / hypot(B, J0 * w24):.4f}")
assert abs(simulate(kb, JF, w24) - r24[3]) < 1e-4 and r24[3] > r24[1]
print(f"outside the range: a 3 rad/s speed step asks Kp x 3 = {kb[0] * 3:.1f} N m at once, over a 20 N m drive")
for label, sp in (("peak 2.5x (zd = 0.2)", (0.2, 1.0, 0.05)), ("peak 10x (zd = 0.05)", (0.05, 1.0, 0.05)), ("torque weight 0.1", (0.1, 1.0, 0.1))):
    k = design(sp)
    print(f"try: {label}: Kp = {k[0]:.3f}, Ki = {k[1]:.3f}, Kr = {k[2]:.3f}; gamma = {norm(k, sp)[0]:.4f}")
print("ALL CHECKS PASS")
