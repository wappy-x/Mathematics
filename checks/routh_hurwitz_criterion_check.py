# Routh-Hurwitz on a thermostat loop: slow pipe, radiator, room. Standard library only.
# Time in hours. Plant G(s) = 5 / ((s + 1)(s + 2)(s + 3)) in degC per kW; thermostat u = K e, K in kW per degC.
# Road 1: Routh array, sign changes in its first column.  Road 2: roots by Durand-Kerner.
# Road 3: frequency response, gain where the phase reaches -180 deg.  Road 4: RK4 simulation.
import math

def routh(c, eps=1e-9):            # c: coefficients, highest power first -> (first column, notes)
    n, w = len(c) - 1, (len(c) + 1) // 2
    rows = [c[0::2] + [0.0] * (w - len(c[0::2])), c[1::2] + [0.0] * (w - len(c[1::2]))]
    notes = []
    for i in range(2, n + 1):
        a, b = rows[-2], rows[-1]
        if all(abs(x) < eps for x in b):              # whole row zero: auxiliary polynomial
            p = n - i + 2                              # power of the row above
            rows[-1] = b = [(p - 2 * j) * a[j] for j in range(w)]
            notes.append(f"zero row at s^{p - 1}, auxiliary from s^{p}")
        if abs(b[0]) < eps:                            # first entry zero: replace by a small epsilon
            b[0] = eps
            notes.append(f"zero pivot at s^{n - i + 1}, epsilon used")
        rows.append([(b[0] * a[j + 1] - a[0] * b[j + 1]) / b[0] if j + 1 < w else 0.0 for j in range(w)])
    return [r[0] for r in rows], notes

changes = lambda col: sum(1 for x, y in zip(col, col[1:]) if x * y < 0)   # sign changes down the column

def roots(c, iters=800):           # Durand-Kerner, all roots at once
    c = [x / c[0] for x in c]
    n = len(c) - 1
    z = [complex(1.0, 0.0)]
    for k in range(1, n):
        z.append(z[-1] * complex(0.4, 0.9))
    for _ in range(iters):
        nz = []
        for i in range(n):
            v, d = complex(0.0, 0.0), complex(1.0, 0.0)
            for a in c:
                v = v * z[i] + a                          # Horner
            for j in range(n):
                d = d * (z[i] - z[j]) if j != i else d
            nz.append(z[i] - v / d)
        z = nz
    z = [complex(0.0 if abs(r.real) < 5e-9 else r.real, 0.0 if abs(r.imag) < 5e-9 else r.imag) for r in z]
    return sorted(z, key=lambda r: (round(r.real, 9), r.imag))

char = lambda K: [1.0, 6.0, 11.0, 6.0 + 5.0 * K]       # (s+1)(s+2)(s+3) + 5K
rhp = lambda c: sum(1 for r in roots(c) if r.real > 1e-7)

def bisect(f, lo, hi, n=60):       # f(lo) false, f(hi) true
    for _ in range(n):
        m = 0.5 * (lo + hi)
        lo, hi = (lo, m) if f(m) else (m, hi)
    return 0.5 * (lo + hi)

def G(w, delay=False):             # plant at s = j w; the pipe is a lag 3/(s+3) or a delay e^(-s/3)
    s = complex(0.0, w)
    pipe = complex(math.cos(-w / 3), math.sin(-w / 3)) if delay else 3 / (s + 3)
    return (5 / 6) * pipe * (2 / (s + 2)) * (1 / (s + 1))

def phase(w, delay=False):         # unwrapped phase in rad, summed factor by factor
    return -math.atan(w) - math.atan(w / 2) - (w / 3 if delay else math.atan(w / 3))

def simulate(K, T, dt, delay=False):  # set point up 1 degC at t = 0; returns room temperature change
    x, out = [0.0, 0.0, 0.0], [0.0]
    D = int(round(1 / 3 / dt))
    def f(x, ud):
        u = ud if delay else K * (1.0 - x[2])
        return [0.0 if delay else 3 * (u - x[0]), 2 * ((ud if delay else x[0]) - x[1]), (5 / 6) * x[1] - x[2]]
    for i in range(int(round(T / dt))):
        ud = K * (1.0 - 0.5 * (out[i - D] + out[i - D + 1])) if delay and i >= D else 0.0
        k1 = f(x, ud)
        k2 = f([x[m] + dt / 2 * k1[m] for m in range(3)], ud)
        k3 = f([x[m] + dt / 2 * k2[m] for m in range(3)], ud)
        k4 = f([x[m] + dt * k3[m] for m in range(3)], ud)
        x = [x[m] + dt / 6 * (k1[m] + 2 * k2[m] + 2 * k3[m] + k4[m]) for m in range(3)]
        out.append(x[2])
    return out

def peaks(y, dt, after):           # times and heights of local maxima after a settling time
    return [(i * dt, y[i]) for i in range(1, len(y) - 1) if i * dt > after and y[i - 1] < y[i] >= y[i + 1]]

def growth(K, delay=False, T=40.0, dt=0.002):   # growth rate per hour, from the last two peaks
    pk = peaks(simulate(K, T, dt, delay), dt, 8.0)
    ss = 5 * K / (6 + 5 * K)
    (t1, y1), (t2, y2) = pk[-2], pk[-1]
    return math.log((y2 - ss) / (y1 - ss)) / (t2 - t1), t2 - t1

print(f"plant: steady gain {5 / 6:.4f} degC per kW (room loses {6 / 5:.4f} kW per degC), lags {60 / 1:.0f}, {60 / 2:.0f}, {60 / 3:.0f} min")
col, _ = routh(char(4.0))
print("Routh first column, K = 4:", " ".join(f"{v:.4f}" for v in col))
print(f"Hurwitz minor a2 a1 - a3 a0, K = 4: {6 * 11 - (6 + 5 * 4.0):.4f}")
col12, notes12 = routh(char(12.0))
print("Routh first column, K = 12:", " ".join(f"{v:.4f}" for v in col12), "|", "; ".join(notes12))
print(f"auxiliary 6 s^2 + 66 = 0: s = +-j {math.sqrt(66 / 6):.6f} rad/h, period {2 * math.pi / math.sqrt(11) * 60:.2f} min")
print(" K      sign changes  RHP roots  roots")
for K in (-2.0, -1.0, 0.0, 4.0, 11.0, 12.0, 13.0, 14.0):
    rs = roots(char(K))
    print(f"{K:5.1f}  {changes(routh(char(K))[0]):12d}  {rhp(char(K)):9d}  " + "  ".join(f"{r.real:+.4f}{r.imag:+.4f}j" for r in rs))
quart = [1.0, 1.0, 3.0, 3.0, 3.0]
qc, qn = routh(quart)
print(f"s^4+s^3+3s^2+3s+3: sign changes {changes(qc)}, RHP roots {rhp(quart)}, {'; '.join(qn)}")

k1 = bisect(lambda K: changes(routh(char(K))[0]) > 0, 0.0, 50.0)
k2 = bisect(lambda K: max(r.real for r in roots(char(K), 300)) > 0, 0.0, 50.0, 40)
wc = bisect(lambda w: phase(w) < -math.pi, 0.1, 20.0)
k3 = 1 / abs(G(wc))
print(f"road 1 Routh, K_cr          {k1:.6f} kW/degC")
print(f"road 2 Durand-Kerner, K_cr  {k2:.6f} kW/degC")
print(f"road 3 phase -180 deg at {wc:.6f} rad/h, |G| = {abs(G(wc)):.6f}, K_cr {k3:.6f} kW/degC")
k4 = bisect(lambda K: growth(K)[0] > 0, 10.0, 14.0, 22)
print(f"road 4 simulation, K_cr     {k4:.4f} kW/degC")
r12, per12 = growth(12.0)
print(f"simulated K = 12: growth {r12:+.5f} per h, peak spacing {per12 * 60:.1f} min")
for K in (11.0, 13.0):
    g, per = growth(K)
    print(f"K = {K:.0f}: simulated growth {g:+.5f} per h, roots say {max(r.real for r in roots(char(K))):+.5f} per h, spacing {per * 60:.1f} min")
    assert abs(g - max(r.real for r in roots(char(K)))) < 1e-3, "simulated growth rate against the roots"
print(f"steady room change per degC of set point, K = 4: {20 / 26:.4f} degC; gain margin 12/4 = {12 / 4:.1f} ({20 * math.log10(3):.2f} dB)")
print(f"lower limit 6 + 5K = 0: K = {-6 / 5:.1f} kW/degC; K = 13 coefficients all positive: {char(13.0)}")

wd = bisect(lambda w: phase(w, True) < -math.pi, 0.1, 20.0)
kd = 1 / abs(G(wd, True))
print(f"pipe as a 20 min delay: phase -180 deg at {wd:.4f} rad/h, K_cr {kd:.4f} kW/degC, period {2 * math.pi / wd * 60:.1f} min")
gd = {K: growth(K, True, 60.0, 1 / 3000)[0] for K in (6.0, 6.6, 10.0)}
print("delay model, simulated growth per h: " + ", ".join(f"K = {K:.1f}: {g:+.4f}" for K, g in gd.items()))
dt = 0.002
ts = [0.25 * i for i in range(33)]
print("chart, t (h)  " + " ".join(f"{t:5.2f}" for t in ts))
for K in (4.0, 12.0, 14.0):
    y = simulate(K, 10.0, dt)
    print(f"chart, K = {K:2.0f} " + " ".join(f"{19 + y[int(round(t / dt))]:5.2f}" for t in ts))
px = lambda r: f"({290 + 30 * r.real:.1f},{120 - 30 * r.imag:.1f})"
print("figure, 30 px per unit: " + "; ".join(f"K={K:.0f} " + " ".join(px(r) for r in roots(char(K))) for K in (0.0, 4.0, 12.0)))

assert abs(k1 - k3) < 1e-6, "Routh critical gain against the frequency road"
assert abs(k2 - k3) < 1e-6, "root-finder critical gain against the frequency road"
assert abs(k4 - k1) < 0.02, "simulated critical gain against Routh"
assert all(changes(routh(char(K))[0]) == rhp(char(K)) for K in (-2.0, 0.0, 4.0, 11.0, 13.0, 14.0)) and changes(qc) == rhp(quart), "sign changes count RHP roots"
assert abs(per12 - 2 * math.pi / math.sqrt(66 / 6)) < 0.01, "simulated swing period against the auxiliary polynomial"
assert abs(col12[2] - 2 * 6.0) < 1e-9, "auxiliary-derivative row: A'(s) = 12 s replaces the zero s^1 row"
assert gd[6.0] < 0.0 < gd[6.6] and 6.0 < kd < 6.6, "delay model: simulation brackets the frequency-road critical gain"
print("ALL CHECKS PASS")
