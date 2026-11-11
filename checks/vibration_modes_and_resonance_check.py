# Vibration modes and resonance -- the check behind the card.  Standard library only.
# A two-span steel footbridge, its sideways sway lumped into two masses on three springs:
#   M x'' + C x' + K x = F sin(W t),  modes from K v = lam M v,  f = sqrt(lam) / (2 pi).
# Roads to the modes: the quadratic det(K - lam M) = 0; inverse iteration; a free-swing RK4 run.
# Roads to the sway: modal superposition; a direct complex solve; an RK4 run of the crowd.
import math

m1, m2, k = 60000.0, 40000.0, 2.0e6           # kg (spans of 60 m and 40 m), N/m per spring
zeta = 0.01                                   # damping ratio of each mode
walkers, push, f_walk = 100, 25.0, 1.0        # people, N sideways each, Hz sideways
M, K = [m1, m2], [[2 * k, -k], [-k, 2 * k]]
F = [push * walkers * 0.6, push * walkers * 0.4]   # in-step crowd, spread evenly: N on each span
W = 2 * math.pi * f_walk

def solve(A, b):                              # 2x2 solve by Cramer's rule (works for complex)
    d = A[0][0] * A[1][1] - A[0][1] * A[1][0]
    return [(b[0] * A[1][1] - A[0][1] * b[1]) / d, (A[0][0] * b[1] - b[0] * A[1][0]) / d]

def dotm(u, v): return M[0] * u[0] * v[0] + M[1] * u[1] * v[1]
def dotk(u, v): return sum(u[i] * K[i][j] * v[j] for i in range(2) for j in range(2))

# ---- modes, road A: det(K - lam M) = 0 is a quadratic in lam ----
a, b, c = m1 * m2, -(m1 * K[1][1] + m2 * K[0][0]), K[0][0] * K[1][1] - K[0][1] ** 2
lam = [(-b - math.sqrt(b * b - 4 * a * c)) / (2 * a), (-b + math.sqrt(b * b - 4 * a * c)) / (2 * a)]
w = [math.sqrt(l) for l in lam]
v = [[1.0, (K[0][0] - l * m1) / k] for l in lam]   # first row of (K - lam M) v = 0, span 1 = 1
mr = [dotm(u, u) for u in v]; kr = [dotk(u, u) for u in v]; pr = [u[0] * F[0] + u[1] * F[1] for u in v]
print(f"inputs: m1 = {m1:.0f} kg, m2 = {m2:.0f} kg, k = {k:.0f} N/m each, zeta = {zeta}")
print(f"quadratic, in units of 1e9: {a / 1e9:.1f} lam^2 - {-b / 1e9:.1f} lam + {c / 1e9:.1f} = 0")
for r in range(2):
    print(f"mode {r + 1}: lam = {lam[r]:.4f} 1/s^2, w = {w[r]:.4f} rad/s, f = {w[r] / (2 * math.pi):.4f} Hz, "
          f"shape (1, {v[r][1]:.4f})")
    print(f"mode {r + 1}: modal mass {mr[r]:.0f} kg, modal stiffness {kr[r]:.0f} N/m, modal force {pr[r]:.1f} N")
print(f"orthogonality: |v1 . M v2| = {abs(dotm(v[0], v[1])):.6f} kg, |v1 . K v2| = {abs(dotk(v[0], v[1])):.6f} N/m; "
      f"{v[0][1]:.4f} x {-v[1][1]:.4f} = {-v[0][1] * v[1][1]:.4f} = m1/m2")
# ---- modes, road B: inverse iteration, mode 2 kept M-orthogonal to mode 1 ----
it = []
for r in range(2):
    x = [1.0, 0.3]
    for _ in range(60):
        x = solve(K, [M[0] * x[0], M[1] * x[1]])
        if r == 1:
            s = dotm(it[0], x) / dotm(it[0], it[0]); x = [x[i] - s * it[0][i] for i in range(2)]
        x = [x[0] / x[0], x[1] / x[0]]
    it.append(x)
    print(f"inverse iteration mode {r + 1}: shape (1, {x[1]:.4f}), Rayleigh quotient {dotk(x, x) / dotm(x, x):.4f} 1/s^2")

def rk4(Cm, force, x0, dt, n, every):         # M x'' + Cm x' + K x = force(t); returns x samples
    def acc(t, s):
        f = force(t)
        return [s[2], s[3]] + [(f[i] - sum(Cm[i][j] * s[2 + j] + K[i][j] * s[j] for j in range(2))) / M[i] for i in range(2)]
    s, out = x0[:], [x0[:2]]
    for i in range(n):
        t = i * dt
        k1 = acc(t, s); k2 = acc(t + dt / 2, [p + dt / 2 * q for p, q in zip(s, k1)])
        k3 = acc(t + dt / 2, [p + dt / 2 * q for p, q in zip(s, k2)]); k4 = acc(t + dt, [p + dt * q for p, q in zip(s, k3)])
        s = [p + dt / 6 * (e + 2 * f + 2 * g + h) for p, e, f, g, h in zip(s, k1, k2, k3, k4)]
        if (i + 1) % every == 0: out.append(s[:2])
    return out
# ---- modes, road C: release the deck in mode 1's shape and time the swing ----
fr = rk4([[0, 0], [0, 0]], lambda t: [0, 0], [0.01, 0.01 * v[0][1], 0, 0], 1e-3, 20000, 1)
up = [i * 1e-3 for i in range(1, len(fr)) if fr[i - 1][0] > 0 >= fr[i][0]]
T = (up[-1] - up[0]) / (len(up) - 1)
print(f"free swing in mode 1: period {T:.4f} s = {1 / T:.4f} Hz, span 2 / span 1 peaks "
      f"{max(p[1] for p in fr) / max(p[0] for p in fr):.4f}")
# ---- damping: Rayleigh C = al M + be K gives zeta in both modes ----
al, be = 2 * zeta * w[0] * w[1] / (w[0] + w[1]), 2 * zeta / (w[0] + w[1])
C = [[al * M[i] * (i == j) + be * K[i][j] for j in range(2)] for i in range(2)]
zr = [sum(u[i] * C[i][j] * u[j] for i in range(2) for j in range(2)) / (2 * m * ww) for u, m, ww in zip(v, mr, w)]
print(f"Rayleigh damping: alpha {al:.5f} 1/s, beta {be:.6f} s; modal zeta {zr[0]:.4f}, {zr[1]:.4f}")

def modal(Om, z=zeta, F=F):                   # sway amplitudes (m) by modal superposition
    q = [(u[0] * F[0] + u[1] * F[1]) / kk / complex(1 - (Om / ww) ** 2, 2 * z * Om / ww) for u, kk, ww in zip(v, kr, w)]
    return [abs(q[0] * v[0][i] + q[1] * v[1][i]) for i in range(2)], q

def direct(Om):                               # (K - Om^2 M + j Om C) X = F, complex 2x2 solve
    A = [[complex(K[i][j] - Om * Om * M[i] * (i == j), Om * C[i][j]) for j in range(2)] for i in range(2)]
    return [abs(x) for x in solve(A, F)]
X, q = modal(W); Xd = direct(W)
print(f"crowd in step: {walkers} walkers x {push:.0f} N at {f_walk:.2f} Hz ({W:.4f} rad/s), F = ({F[0]:.0f}, {F[1]:.0f}) N")
print(f"spread evenly on spans of 60 m and 40 m: {walkers * 0.6:.0f} and {walkers * 0.4:.0f} walkers; "
      f"resonance gain 1/(2 zeta) = {1 / (2 * zeta):.2f}")
for r in range(2):
    Hr = 1 / abs(complex(1 - (W / w[r]) ** 2, 2 * zeta * W / w[r]))
    print(f"mode {r + 1} at {f_walk:.2f} Hz: f/f_r {W / w[r]:.5f}, gain {Hr:.2f}, static {pr[r] / kr[r] * 1000:.4f} mm, "
          f"modal sway {abs(q[r]) * 1000:.2f} mm")
print(f"sway at {f_walk:.2f} Hz, modal: span 1 {X[0] * 1000:.2f} mm, span 2 {X[1] * 1000:.2f} mm; "
      f"accel span 1 {X[0] * W * W:.3f} m/s^2")
print(f"sway at {f_walk:.2f} Hz, direct: span 1 {Xd[0] * 1000:.2f} mm, span 2 {Xd[1] * 1000:.2f} mm")
cr = rk4(C, lambda t: [F[0] * math.sin(W * t), F[1] * math.sin(W * t)], [0, 0, 0, 0], 1e-3, 160000, 1)
tail = cr[150000:]
Xs = [0.5 * (max(p[i] for p in tail) - min(p[i] for p in tail)) for i in range(2)]
print(f"sway at {f_walk:.2f} Hz, RK4 after 150 s: span 1 {Xs[0] * 1000:.2f} mm, span 2 {Xs[1] * 1000:.2f} mm")
env = [max(abs(p[0]) for p in cr[max(0, 1000 * t - 1000):1000 * t + 1]) * 1000 for t in range(0, 65, 5)]
print("chart, build-up t (s) " + " ".join(f"{t:5d}" for t in range(0, 65, 5)))
print("chart, span 1 env mm  " + " ".join(f"{e:5.2f}" for e in env))
print(f"time constant 1/(zeta w1) {1 / (zeta * w[0]):.2f} s")
fs = [0.5 + 0.1 * i for i in range(21)]
sw = [modal(2 * math.pi * f)[0] for f in fs]
print("chart, f (Hz)    " + " ".join(f"{f:5.1f}" for f in fs))
for i in range(2):
    print(f"chart, span {i + 1} mm " + " ".join(f"{s[i] * 1000:5.2f}" for s in sw))
pk = [modal(ww)[0] for ww in w]
print(f"peaks: at f1 span 1 {pk[0][0] * 1000:.2f} mm, span 2 {pk[0][1] * 1000:.2f} mm; "
      f"at f2 span 1 {pk[1][0] * 1000:.2f} mm, span 2 {pk[1][1] * 1000:.2f} mm")
print(f"dampers, zeta 0.10: span 1 at f1 {modal(w[0], 0.10)[0][0] * 1000:.2f} mm, at {f_walk:.2f} Hz {modal(W, 0.10)[0][0] * 1000:.2f} mm")
# ---- what breaks ----
X0 = modal(W, 0.0)[0]
print(f"no damping at {f_walk:.2f} Hz: span 1 {X0[0] * 1000:.2f} mm; at f1 the formula divides by zero")
lm = [k / 50000.0, 3 * k / 50000.0]           # equal 50 t masses: shapes (1, 1) and (1, -1)
Xe = abs(sum(pp / kk / complex(1 - W * W / l, 2 * zeta * W / math.sqrt(l)) for pp, kk, l in zip([2500.0, 500.0], [2 * k, 6 * k], lm)))
print(f"equal masses 50000 kg: f = {math.sqrt(lm[0]) / (2 * math.pi):.4f}, {math.sqrt(lm[1]) / (2 * math.pi):.4f} Hz; "
      f"span 1 sway {Xe * 1000:.2f} mm")
xs = solve(K, F)
print(f"static push: span 1 {xs[0] * 1000:.4f} mm, span 2 {xs[1] * 1000:.4f} mm")
Xr = modal(W, zeta, [f / math.sqrt(walkers) for f in F])[0]
print(f"out of step, 25 sqrt(N) = {push * math.sqrt(walkers):.0f} N: span 1 {Xr[0] * 1000:.2f} mm")
X2k = modal(W, zeta, [f * 2000 / walkers for f in F])[0]
print(f"2000 walkers in step: linear model says span 1 {X2k[0] * 1000:.0f} mm")
print(f"figure, mode 1 (160.0, 60.0) (360.0, {110 - 50 * v[0][1]:.1f}); mode 2 (160.0, 230.0) (360.0, {280 - 50 * v[1][1]:.1f})")

assert all(abs(it[r][1] - v[r][1]) < 1e-9 for r in range(2))             # inverse iteration vs quadratic
assert abs(1 / T - w[0] / (2 * math.pi)) < 1e-4                           # free swing vs quadratic
assert abs(dotm(v[0], v[1])) < 1e-6 * m1                                  # modes are M-orthogonal
assert all(abs(z - zeta) < 1e-12 for z in zr)                             # Rayleigh C gives zeta per mode
assert all(abs(X[i] - Xd[i]) < 1e-9 for i in range(2))                    # modal sum vs direct solve
assert all(abs(Xs[i] - X[i]) < 1e-3 * X[0] for i in range(2))             # RK4 vs modal sum
assert all(abs(modal(2 * math.pi * f)[0][0] - direct(2 * math.pi * f)[0]) < 1e-9 for f in fs)
print("ALL CHECKS PASS")
