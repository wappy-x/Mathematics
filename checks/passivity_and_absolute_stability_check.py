# Passivity and absolute stability -- the check behind the card.  Standard library only.
# A conveyor belt (mass M) under a PI speed loop, with sticking friction at low speed.
# Roads: the band test by formula; a frequency sweep with bisection; simulations (RK4).
import math

M, KP, KI = 500.0, 2000.0, 4000.0                   # kg, N*s/m, N/m
FS, FC, VS, B, EPS = 600.0, 400.0, 0.1, 200.0, 0.002  # N, N, m/s, N*s/m, m/s

def fric(v, fs=FS):  # Stribeck friction, N: sticking dip below VS, smoothed through 0
    return math.tanh(v / EPS) * (FC + (fs - FC) * math.exp(-(v / VS) ** 2)) + B * v

def slope(v, fs=FS, h=1e-6):
    return (fric(v + h, fs) - fric(v - h, fs)) / (2 * h)

def sim(v0, e0, kp, m=M, ki=KI, fs=FS, T=10.0, dt=0.001, lin=None):
    # e = speed error (m/s), z = integral of e (m); M e' = -Kp e - Ki z - phi(e), z' = e
    phi = (lambda e: -lin * e) if lin is not None else (lambda e: fric(v0 + e, fs) - fric(v0, fs))
    f = lambda e, z: ((-kp * e - ki * z - phi(e)) / m, e)
    e, z, out = e0, 0.0, []
    for k in range(int(round(T / dt)) + 1):
        out.append((k * dt, e, z))
        a1, b1 = f(e, z); a2, b2 = f(e + dt / 2 * a1, z + dt / 2 * b1)
        a3, b3 = f(e + dt / 2 * a2, z + dt / 2 * b2); a4, b4 = f(e + dt * a3, z + dt * b3)
        e += dt / 6 * (a1 + 2 * a2 + 2 * a3 + a4); z += dt / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
    return out

V = lambda e, z, m=M, ki=KI: 0.5 * m * e * e + 0.5 * ki * z * z      # stored energy, J
settle = lambda out: max([t for t, e, z in out if abs(e) > 0.001] + [0.0])  # last time |e| > 1 mm/s
def swing(out, since):
    v = [e for t, e, z in out if t >= since]
    return min(v), max(v)

def steepest(fs):  # closed form: largest downhill slope of the friction curve, at v = VS/sqrt 2
    return (fs - FC) * math.sqrt(2) / VS * math.exp(-0.5) - B

print(f"plant: M {M:.0f} kg, Kp {KP:.0f} N*s/m, Ki {KI:.0f} N/m; wn {math.sqrt(KI / M):.4f} rad/s, damping ratio {KP / (2 * math.sqrt(KI * M)):.4f}")
vs_chart = [0.0, 0.02, 0.04, 0.06, 0.08, 0.1, 0.15, 0.2, 0.3, 0.5, 1.0]
print("chart, speed m/s    " + " ".join(f"{v:6.2f}" for v in vs_chart))
print("chart, friction N   " + " ".join(f"{fric(v):6.1f}" for v in vs_chart))

# ---- the band: the friction curve's steepest downhill slope ----
a = steepest(FS)
grid = [i * 1e-4 for i in range(1, 20001)]
a_scan = -min(slope(v) for v in grid)
assert abs(a - a_scan) < 1e-3, "closed-form steepest slope disagrees with the scan"
loc = B - (FS - FC) * 2 * 0.05 / VS ** 2 * math.exp(-0.25)
assert abs(loc - slope(0.05)) < 1e-3
print(f"steepest downhill slope a: formula {a:.4f}, scan {a_scan:.4f} N*s/m, at {VS / math.sqrt(2):.4f} m/s")
print(f"hand: {FS - FC:.0f} x {math.sqrt(2) / VS:.4f} x {math.exp(-0.5):.4f} = {a + B:.4f}, minus b {B:.0f} -> a {a:.4f}")
print(f"hand: local at 0.05 m/s: {B:.0f} - {FS - FC:.0f} x 10 x {math.exp(-0.25):.4f} = {B:.0f} - {B - loc:.4f}")
print(f"local slope: at 0.05 m/s {loc:.4f}, at 1.00 m/s {slope(1.0):.4f} N*s/m")
for v0 in (0.05, 1.0):  # worst chord from each operating speed, over every other speed 0..2 m/s
    ch = min((fric(v) - fric(v0)) / (v - v0) for v in grid if abs(v - v0) > 1e-9)
    assert ch >= -a - 1e-6, "a chord steeper than the steepest tangent: mean value theorem broken"
    print(f"worst chord from {v0:.2f} m/s: {ch:.4f} N*s/m (band floor -{a:.4f})")
print(f"band test: Kp {KP:.0f} - a {a:.4f} = margin {KP - a:.4f} N*s/m -> {'PASS' if KP > a else 'FAIL'}")

# ---- road 2: frequency sweep, G(jw) = jw / (Ki - M w^2 + j Kp w), bisection on a ----
ws = [10 ** (-3 + 6 * i / 2000) for i in range(2001)]
G = lambda w, kp=KP: 1j * w / (KI - M * w * w + 1j * kp * w)
def band_ok(x, kp=KP):  # G / (1 - x G) positive real at every swept frequency?
    return all((G(w, kp) / (1 - x * G(w, kp))).real >= 0 for w in ws)
lo, hi = 0.0, 5000.0
for _ in range(60):
    lo, hi = ((lo + hi) / 2, hi) if band_ok((lo + hi) / 2) else (lo, (lo + hi) / 2)
assert abs(lo - KP) < 1e-3, "frequency road disagrees with a* = Kp"
c = 1 / (2 * KP)
rad = [abs(G(w) - c) for w in ws]
assert max(rad) - min(rad) < 1e-12 and abs(max(rad) - c) < 1e-12, "Nyquist plot of G is not the circle"
print(f"frequency road: largest band a* by bisection {lo:.4f} N*s/m (formula: Kp {KP:.4f})")
print(f"Nyquist of G: circle centre {c:.6f}, radius {max(rad):.6f}, diameter 1/Kp {2 * c:.6f} m/(N*s); band disk diameter 1/a {1 / a:.6f}")

# ---- road 3: a straight-line friction of slope -x, just inside and just outside Kp ----
for x in (0.99 * KP, 1.01 * KP):
    o = sim(0.05, -0.03, KP, lin=x, T=30)
    r = V(o[-1][1], o[-1][2]) / V(o[0][1], o[0][2])
    assert (r < 1) == (x < KP), "linear road disagrees with the band edge"
    print(f"linear friction slope -{x:.0f}: V(30 s)/V(0) = {r:.4f}, real part {-(KP - x) / (2 * M):+.4f} 1/s")

# ---- the kick: at creep speed 0.05 m/s a parcel slows the belt to 0.02 m/s ----
o = sim(0.05, -0.03, KP)
Vs = [V(e, z) for t, e, z in o]
assert all(Vs[i + 1] <= Vs[i] + 1e-12 for i in range(len(Vs) - 1)), "stored energy rose"
ph = fric(0.02) - fric(0.05)
print(f"at the kick: F(0.02) {fric(0.02):.1f} - F(0.05) {fric(0.05):.1f} = phi {ph:.1f} N; V' = {-KP * 0.03 ** 2:.4f} + {0.03 * ph:.4f} = {-KP * 0.03 ** 2 + 0.03 * ph:.4f} W; floor {-(KP - a) * 0.03 ** 2:.4f} W")
ie2 = sum(e * e for t, e, z in o[:-1]) * 0.001
assert Vs[0] - Vs[-1] >= (KP - a) * ie2 * 0.999, "energy fell slower than the margin promises"
print("kick, V in J at 0..5 s: " + " ".join(f"{Vs[k * 1000]:.4f}" for k in range(6)) + f"; settles in {settle(o):.3f} s")
print(f"energy drained {Vs[0] - Vs[-1]:.4f} J >= margin x integral of e^2 = {(KP - a) * ie2:.4f} J")
ke = [0.5 * M * e * e for t, e, z in o]
i0 = next(i for i, (t, e, z) in enumerate(o) if e > 0)
ipk = max(range(i0, len(o)), key=lambda i: ke[i])
print(f"kinetic energy alone: {ke[i0]:.6f} J at {o[i0][0]:.3f} s rises to {ke[ipk]:.6f} J at {o[ipk][0]:.3f} s")
o1 = sim(0.05, -0.03, 1000.0, T=40)
print("chart, time s       " + " ".join(f"{k / 2:6.1f}" for k in range(17)))
print("chart, Kp 2000 m/s  " + " ".join(f"{0.05 + o[k * 500][1]:6.4f}" for k in range(17)))
print("chart, Kp 1000 m/s  " + " ".join(f"{0.05 + o1[k * 500][1]:6.4f}" for k in range(17)))
lo1, hi1 = swing(o1, 20)
ups = [t for (t, e, z), (t2, e2, z2) in zip(o1, o1[1:]) if t >= 20 and e < 0 <= e2]
period = (ups[-1] - ups[0]) / (len(ups) - 1)
assert hi1 - lo1 > 0.05, "Kp 1000 should judder"
print(f"Kp 1000 at 0.05 m/s: speed swings {0.05 + lo1:.4f} to {0.05 + hi1:.4f} m/s, period {period:.3f} s")

# ---- every load and every friction curve inside the band ----
print("settle s after the kick   " + "  ".join(f"Fs {fs:.0f} N (a {steepest(fs):.1f})" for fs in (600.0, 500.0, 400.0)))
for m in (200.0, 500.0, 800.0):
    row = []
    for fs in (600.0, 500.0, 400.0):
        oc = sim(0.05, -0.03, KP, m=m, fs=fs, T=20)
        assert abs(oc[-1][1]) < 1e-4, "a covered case failed to settle"
        row.append(f"{settle(oc):19.3f}")
    print(f"load {m:3.0f} kg            " + " ".join(row))

# ---- what breaks ----
w2 = swing(sim(VS / math.sqrt(2), -0.03, 1400.0, T=40), 30)
print(f"break, Kp 1400 at 0.0707 m/s: swings {VS / math.sqrt(2) + w2[0]:.4f} to {VS / math.sqrt(2) + w2[1]:.4f} m/s")
o3 = sim(0.05, -0.03, 1400.0, T=100)   # fails the band at creep speed (worst chord -1477.0), yet settles
assert abs(o3[-1][1]) < 1e-3, "Kp 1400 at creep speed should still settle, slowly"
print(f"break, Kp 1400 at 0.05 m/s: below the worst chord there, no guarantee, yet settles in {settle(o3):.3f} s")

# ---- try changing ----
a7 = steepest(700.0)
w7 = swing(sim(VS / math.sqrt(2), -0.03, KP, fs=700.0, T=40), 30)
print(f"try Fs 700 N: a {a7:.4f} N*s/m; at 0.0707 m/s swings {VS / math.sqrt(2) + w7[0]:.4f} to {VS / math.sqrt(2) + w7[1]:.4f} m/s")
print(f"try Kp 1600: margin {1600 - a:.4f} N*s/m, settles in {settle(sim(0.05, -0.03, 1600.0, T=40)):.3f} s")
print(f"try Ki 8000: settles in {settle(sim(0.05, -0.03, KP, ki=8000.0, T=20)):.3f} s")
print(f"try belt stopped dead, e0 -0.05 m/s: settles in {settle(sim(0.05, -0.05, KP, T=20)):.3f} s")
print(f"figure, circle Kp 2000 c {1 / 4000:.6f} r {1 / 4000:.6f}; circle Kp 1000 c {1 / 2000:.6f} r {1 / 2000:.6f}; band c {1 / (2 * a):.6f} r {1 / (2 * a):.6f}")
print("ALL CHECKS PASS")
