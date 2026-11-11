# Gain scheduling and adaptive control -- the check behind the card.  Standard library only.
# Conveyor: torque u (N m) -> drive lag tau -> belt inertia J, friction b -> speed v (rad/s).
# Load m (kg) on the belt adds m r^2 to the inertia: J = 0.20 + 0.0025 m kg m^2 (drive roller r = 0.05 m).
# Part A, gain schedule: PI gains Kp = J/Tc, Ki = b/Tc from the load cell.  Roads: closed form vs RK4.
# Part B, adaptive: sampled every Ts, recursive least squares (RLS) learns v[k+1] = a v[k] + g u[k], and the
# controller makes the loop copy a reference model.  Roads: RLS vs weighted batch least squares, vs physics.
from math import exp, log, sqrt, pi

J0, B, TAU, R2, TC, TS, LAM = 0.20, 0.40, 0.02, 0.0025, 0.25, 0.05, 0.98
AM = exp(-TS / TC)                                   # reference model pole: a 0.25 s lag, sampled
def J_of(m): return J0 + R2 * m
def ab(J): a = exp(-B * TS / J); return a, (1 - a) / B   # exact sampled plant (drive lag left out)
def hold(J, v, u, h=TS / 50):   # road 3: RK4 of J dv/dt = u - b v over one sample, torque held
    f = lambda x: (u - B * x) / J
    for _ in range(50): k1 = f(v); k2 = f(v + h / 2 * k1); k3 = f(v + h / 2 * k2); v += h / 6 * (k1 + 2 * k2 + 2 * k3 + f(v + h * k3))
    return v

def step(J, kp, ki, r=5.0, t_end=3.0, dt=1e-4, every=1000):
    """RK4 on drive torque q, speed v, integral z after a speed step r; overshoot %, 2% settle, samples."""
    def f(x):
        q, v, z = x
        return ((kp * (r - v) + ki * z - q) / TAU, (q - B * v) / J, r - v)
    x, peak, settle, pts = [0.0] * 3, 0.0, 0.0, [0.0]
    for k in range(int(round(t_end / dt))):
        k1 = f(x); k2 = f([a + dt / 2 * d for a, d in zip(x, k1)])
        k3 = f([a + dt / 2 * d for a, d in zip(x, k2)]); k4 = f([a + dt * d for a, d in zip(x, k3)])
        x = [a + dt / 6 * (p + 2 * q + 2 * s + t) for a, p, q, s, t in zip(x, k1, k2, k3, k4)]
        peak = max(peak, x[1])
        if abs(x[1] - r) > 0.02 * r: settle = (k + 1) * dt
        if (k + 1) % every == 0: pts.append(x[1])
    return max(0.0, 100 * (peak - r) / r), settle, pts

def closed_form(tc):   # Kp = J/Tc cancels the belt pole: v/r = 1/(Tc tau s^2 + Tc s + 1) for every load
    d = sqrt(tc * tc - 4 * tc * TAU)
    p1, p2 = (-tc + d) / (2 * tc * TAU), (-tc - d) / (2 * tc * TAU)
    y = lambda t: 1 - (p2 * exp(p1 * t) - p1 * exp(p2 * t)) / (p2 - p1)
    lo, hi = 0.0, 10.0
    for _ in range(60):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if y(mid) < 0.98 else (lo, mid)
    return p1, p2, lo

def sm64(s):
    s = (s + 0x9E3779B97F4A7C15) & (2**64 - 1); z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1); z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return s, z ^ (z >> 31)

def adaptive(cmd, lam=LAM, known=None, dmax=0.3, seed=7, n=800):
    """Belt empty for 20 s, then 80 kg land.  Ripple d uniform in +-dmax N m.  known: 'true' or 'empty' model, no RLS."""
    s, th, P, v, vm, log_, e2, data = seed, [0.5, 0.5], [[100.0, 0.0], [0.0, 100.0]], 0.0, 0.0, [], [0.0, 0.0], []
    for k in range(n):
        a, g = ab(J_of(0 if k < n // 2 else 80)); r = cmd(k * TS)
        ah, gh = {'true': (a, g), 'empty': ab(J0)}.get(known, (th[0], max(th[1], 0.02)))
        u = ((AM - ah) * v + (1 - AM) * r) / gh                    # model matching on the estimates
        s, x = sm64(s); d = dmax * (2 * (x >> 11) / 2**53 - 1)
        vn, vm = a * v + g * (u + d), AM * vm + (1 - AM) * r
        phi = (v, u); data.append((phi, vn))
        if known is None:
            Pp = [P[0][0] * phi[0] + P[0][1] * phi[1], P[1][0] * phi[0] + P[1][1] * phi[1]]
            K = [p / (lam + phi[0] * Pp[0] + phi[1] * Pp[1]) for p in Pp]
            err = vn - th[0] * phi[0] - th[1] * phi[1]
            th = [th[0] + K[0] * err, th[1] + K[1] * err]
            P = [[(P[i][j] - K[i] * Pp[j]) / lam for j in range(2)] for i in range(2)]
        v = vn; e2[k >= n // 2] += (v - vm) ** 2
        bh = (1 - th[0]) / th[1]; log_.append((th[0], th[1], -bh * TS / log(th[0])))
    return log_, [sqrt(e / (n // 2)) for e in e2], data

def batch(data, lam=LAM):   # road 2: weighted least squares as normal equations, same starting guess as prior
    N = len(data); w0 = lam ** N / 100.0
    R, q = [[w0, 0.0], [0.0, w0]], [w0 * 0.5, w0 * 0.5]
    for k, (phi, y) in enumerate(data):
        w = lam ** (N - 1 - k)
        for i in range(2):
            q[i] += w * phi[i] * y
            for j in range(2): R[i][j] += w * phi[i] * phi[j]
    det = R[0][0] * R[1][1] - R[0][1] * R[1][0]
    return (R[1][1] * q[0] - R[0][1] * q[1]) / det, (R[0][0] * q[1] - R[1][0] * q[0]) / det
def stats(xs): mu = sum(xs) / len(xs); return mu, sqrt(sum((x - mu) ** 2 for x in xs) / len(xs))

print(f"conveyor: b = {B:.2f} N m s/rad, tau = {TAU:.2f} s, J = {J0:.2f} + {R2:.4f} m kg m^2; target lag Tc = {TC:.2f} s")
for m in (0, 40, 60, 80):
    print(f"schedule m = {m:2d} kg: J = {J_of(m):.4f} kg m^2, Kp = {J_of(m) / TC:.3f} N m/(rad/s), Ki = {B / TC:.3f} N m/rad")
p1, p2, ts_cf = closed_form(TC)
print(f"closed form: poles {p1:.3f} and {p2:.3f} 1/s, 2% settle {ts_cf:.3f} s (first-order guess Tc ln 50 = {TC * log(50):.3f} s)")
runs = {}   # (name, true load, load the gains are read for), kg
for name, m, m_read in (("empty", 0, 0), ("half", 40, 40), ("full", 80, 80), ("full, fixed empty gains", 80, 0),
                        ("full, load cell reads 60 kg", 80, 60)):
    runs[name] = step(J_of(m), J_of(m_read) / TC, B / TC, every=1000)
    print(f"step 5 rad/s, {name}: overshoot {runs[name][0]:.2f} %, 2% settle {runs[name][1]:.3f} s")
assert all(abs(runs[n][1] - ts_cf) < 2e-4 and runs[n][0] < 1e-6 for n in ("empty", "half", "full"))   # sim = formula
assert runs["full, fixed empty gains"][1] > 1.5 * ts_cf
print("chartA t = 0.0..3.0 s by 0.1, scheduled:", ", ".join(f"{v:.2f}" for v in runs["full"][2]))
print("chartA t = 0.0..3.0 s by 0.1, fixed    :", ", ".join(f"{v:.2f}" for v in runs["full, fixed empty gains"][2]))
zeta = 0.5 * sqrt(0.02 / TAU); os_cf = 100 * exp(-pi * zeta / sqrt(1 - zeta * zeta))
os_sim = step(J_of(0), J_of(0) / 0.02, B / 0.02)[0]
print(f"too fast, Tc = 0.02 s: zeta {zeta:.3f}, overshoot formula {os_cf:.2f} %, simulated {os_sim:.2f} %;"
      f" Kp = {J_of(0) / 0.02:.1f} asks {5 * J_of(0) / 0.02:.0f} N m")
assert abs(os_cf - os_sim) < 0.05
# ---- Part B: adaptive ----
a0, g0 = ab(J_of(0)); a1, g1 = ab(J_of(80))
print(f"sampled: Ts = {TS:.2f} s, a_m = {AM:.6f}; empty a = {a0:.6f}, g = {g0:.6f}; full a = {a1:.6f}, g = {g1:.6f}")
kv, kr = (AM - a1) / g1, (1 - AM) / g1
print(f"full-belt match: u = {kv:.5f} v + {kr:.5f} r; loop pole {a1 + g1 * kv:.6f}, RK4 over one sample {hold(J_of(80), 1.0, kv):.6f}")
pf = a1 + g1 * (AM - a0) / g0
print(f"empty-belt controller on full belt: pole {pf:.6f}, lag {-TS / log(pf):.4f} s instead of {TC:.2f} s")
assert abs(hold(J_of(80), 1.0, kv) - AM) < 1e-9 and -TS / log(pf) > 2 * TC
sq = lambda t: 4.0 if int(t / 2) % 2 == 0 else 6.0     # speed command: 4 and 6 rad/s, 2 s each
lg, rms, data = adaptive(sq)
(ph, uh), y1 = data[0]
print(f"first RLS step: phi = ({ph:.4f}, {uh:.4f}), v1 = {y1:.4f}, error {y1 - 0.5 * uh:.4f},"
      f" gain {100 * uh / (LAM + 100 * uh * uh):.5f}, g_hat {lg[0][1]:.4f}, a_hat {lg[0][0]:.4f}")
print("chartB J_hat at t = 2..40 s by 2:", ", ".join(f"{lg[40 * i - 1][2]:.3f}" for i in range(1, 21)))
e_m, e_s = stats([x[2] for x in lg[200:400]]); f_m, f_s = stats([x[2] for x in lg[600:800]])
print(f"J_hat over 10-20 s: {e_m:.4f} +- {e_s:.4f}; over 30-40 s: {f_m:.4f} +- {f_s:.4f} kg m^2 (true 0.20, 0.40)")
print(f"load read back: {(f_m - J0) / R2:.1f} kg (true 80 kg); b_hat at 40 s {(1 - lg[-1][0]) / lg[-1][1]:.4f} N m s/rad")
assert abs(e_m - 0.20) < 3 * e_s and abs(f_m - 0.40) < 3 * f_s
tb = batch(data); tb20 = batch(data[:400])
gap = max(abs(tb[0] - lg[-1][0]), abs(tb[1] - lg[-1][1]), abs(tb20[0] - lg[399][0]), abs(tb20[1] - lg[399][1]))
print(f"RLS vs batch weighted least squares, at 20 s and 40 s: agree to 1e-8: {gap < 1e-8}")
assert gap < 1e-8
t_in = (next(k for k in range(400, 800) if all(abs(x[2] - 0.40) < 0.04 for x in lg[k:])) + 1) * TS - 20
print(f"after the parcels land, J_hat within 10% of 0.40 to stay after {t_in:.2f} s")
orc, fix = adaptive(sq, known="true")[1], adaptive(sq, known="empty")[1]
print(f"tracking error rms (rad/s), empty | full: adaptive {rms[0]:.4f} | {rms[1]:.4f};"
      f" true model {orc[0]:.4f} | {orc[1]:.4f}; empty model kept {fix[0]:.4f} | {fix[1]:.4f}")
assert rms[0] < 1.1 * orc[0] and fix[1] > 2 * rms[1]
nof, rms1, _ = adaptive(sq, lam=1.0)
print(f"no forgetting, lambda = 1: J_hat at 40 s {nof[-1][2]:.4f}, full-belt rms {rms1[1]:.4f} rad/s")
assert nof[-1][2] < 0.32 and rms1[1] > 2 * rms[1]
pe, rmsc, _ = adaptive(lambda t: 5.0)
lo_, hi_ = min(x[2] for x in pe[600:]), max(x[2] for x in pe[600:])
print(f"constant 5 rad/s command: J_hat over 30-40 s wanders {lo_:.3f} to {hi_:.3f} (square wave: "
      f"{min(x[2] for x in lg[600:]):.3f} to {max(x[2] for x in lg[600:]):.3f})")
assert hi_ - lo_ > 3 * (max(x[2] for x in lg[600:]) - min(x[2] for x in lg[600:]))
pw = [a1 + g1 * (AM - x[0]) / max(x[1], 0.02) for x in pe[600:]]   # full-belt pole, controller frozen on each estimate
print(f"constant command, full-belt loop pole on those estimates: {min(pw):.3f} to {max(pw):.3f}, lag {-TS / log(min(pw)):.3f}"
      f" to {-TS / log(max(pw)):.3f} s (designed {AM:.3f}, {TC:.2f} s); lowest g_hat {min(x[1] for x in pe):.4f}, floor 0.02")
print(f"try: lambda 0.99 -> J_hat sd {stats([x[2] for x in adaptive(sq, lam=0.99)[0][600:]])[1]:.4f};"
      f" ripple 0.6 N m -> sd {stats([x[2] for x in adaptive(sq, dmax=0.6)[0][600:]])[1]:.4f};"
      f" Tc 0.5 s -> settle {closed_form(0.5)[2]:.3f} s")
print("ALL CHECKS PASS")
