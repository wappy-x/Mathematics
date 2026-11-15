# Sobolev and Poincare -- the check behind the card.  Standard library only.
# Example (illustrative): a river level h(t) over one day, L = 24 h. It rises
# 1.00 -> 1.60 m in 6 h, then drains to 1.12 m by hour 24: straight pieces with a kink.
from fractions import Fraction as F
from math import sqrt, pi, sin, cos, log

L = 24
KNOTS = [(F(0), F(1)), (F(6), F(8, 5)), (F(24), F(28, 25))]   # (hour, metres)

def stats(knots):
    # Road 1: exact fractions.  On a straight piece, int y^2 = width*(y0^2+y0*y1+y1^2)/3.
    segs = list(zip(knots, knots[1:]))
    mean = sum((t1 - t0) * (y0 + y1) / 2 for (t0, y0), (t1, y1) in segs) / L
    sq3 = lambda a, b: (a * a + a * b + b * b) / 3
    dev2 = sum((t1 - t0) * sq3(y0 - mean, y1 - mean) for (t0, y0), (t1, y1) in segs)
    raw2 = sum((t1 - t0) * sq3(y0, y1) for (t0, y0), (t1, y1) in segs)
    slopes = [(y1 - y0) / (t1 - t0) for (t0, y0), (t1, y1) in segs]
    pieces = [s * s * (t1 - t0) for s, ((t0, _), (t1, _)) in zip(slopes, segs)]  # int h'^2
    return mean, dev2, raw2, slopes, pieces

mean, dev2, raw2, slopes, pieces = stats(KNOTS)
slope2 = sum(pieces)

# Road 2: brute force, a midpoint sum on 240,000 slices, slope by finite differences.
n_fine = 240000
dt = L / n_fine
def hf(t): return 1.0 + 0.1 * t if t <= 6 else 1.6 - (t - 6) * 0.48 / 18
hv = [hf((i + 0.5) * dt) for i in range(n_fine)]
mean_bf = sum(hv) * dt / L
dev2_bf = sum((v - mean_bf) ** 2 for v in hv) * dt
slope2_bf = sum(((hf((i + 1) * dt) - hf(i * dt)) / dt) ** 2 for i in range(n_fine)) * dt

rms_dev, rms_slope = sqrt(dev2 / L), sqrt(slope2 / L)
CP = L / pi
rows = [("slope on the rise, m/h", float(slopes[0])), ("slope on the drain, m/h", float(slopes[1])),
        ("mean level, m", float(mean)), ("int (h - mean)^2, m^2 h", float(dev2)),
        ("int h'^2 on the rise, m^2/h", float(pieces[0])), ("int h'^2 on the drain, m^2/h", float(pieces[1])),
        ("int h'^2, m^2/h", float(slope2)), ("  brute force mean", mean_bf),
        ("  brute force int (h - mean)^2", dev2_bf), ("  brute force int h'^2", slope2_bf),
        ("||h'||_2, m/sqrt(h)", sqrt(slope2)),
        ("RMS deviation, m", rms_dev), ("RMS slope, m/h", rms_slope),
        ("C_P = L/pi, h", CP), ("Poincare bound C_P * RMS slope, m", CP * rms_slope),
        ("ratio RMS dev / RMS slope, h", rms_dev / rms_slope),
        ("largest |h - mean|, m", float(max(abs(y - mean) for _, y in KNOTS))),
        ("sup bound L * RMS slope, m", L * rms_slope),
        ("MVT bound L * max|h'|, m", L * float(max(abs(s) for s in slopes))),
        ("rise 0-6 h: actual, m", float(KNOTS[1][1] - KNOTS[0][1])),
        ("rise: local bound sqrt(6)*sqrt(int_0^6 h'^2)", sqrt(6 * pieces[0])),
        ("rise: global bound sqrt(6)*||h'||_2", sqrt(6 * slope2))]
for name, v in rows:
    print(f"{name:<46} {v:>12.6f}")
print(f"{'deviation from mean at hours 0, 6, 24, m':<46} " + " ".join(f"{float(y - mean):.6f}" for _, y in KNOTS))

# Hourly averages: the finite rehearsal.  Every pair of hours obeys the Holder bound.
u = [hf(i + 0.5) for i in range(24)]
worst = max(abs(u[i] - u[j]) / (sqrt(abs(i - j)) * sqrt(slope2))
            for i in range(24) for j in range(24) if i != j)
print(f"{'hourly pairs: worst |u_i - u_j| / bound':<46} {worst:>12.6f}")

# Discrete Poincare constant for N readings: smallest nonzero eigenvalue of the path
# matrix (diagonal 1,2,...,2,1; off-diagonal -1), by Sturm-count bisection.
def below(x, n):                              # how many eigenvalues lie below x
    d = 1.0 - x
    count = int(d < 0)
    for i in range(1, n):
        a = (1.0 if i == n - 1 else 2.0) - x
        d = a - 1.0 / (d if d != 0 else 1e-300)
        count += d < 0
    return count
def lam1(n):
    lo, hi = 1e-15, 4.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if below(mid, n) >= 2 else (mid, hi)
    return (lo + hi) / 2
print()
print(f"{'N':>5} {'C_N bisection':>14} {'C_N formula':>14} {'Rayleigh cos':>14} {'(C_N-L/pi)*N^2':>15}")
table = []
for N in (6, 24, 96, 384):
    d_t = L / N
    cb = d_t / sqrt(lam1(N))
    cf = d_t / (2 * sin(pi / (2 * N)))
    w = [cos(pi * (i + 0.5) / N) for i in range(N)]   # sampled cos(pi t / L); its mean is 0
    num = sum(x * x for x in w) * d_t
    den = sum(((w[i + 1] - w[i]) / d_t) ** 2 for i in range(N - 1)) * d_t
    cr = sqrt(num / den)
    table.append((N, cb, cf, cr))
    print(f"{N:>5} {cb:>14.6f} {cf:>14.6f} {cr:>14.6f} {(cb - CP) * N * N:>15.6f}")
ubar = sum(u) / 24
dev24 = sqrt(sum((x - ubar) ** 2 for x in u))
sl24 = sqrt(sum((u[i + 1] - u[i]) ** 2 for i in range(23)))
print(f"hourly data: spread {dev24:.6f}  slope {sl24:.6f}  ratio {dev24 / sl24:.6f}  C_24 {table[1][1]:.6f}")

# What breaks.
print()
print(f"{'break: RMS of h itself, no mean removed, m':<46} {sqrt(raw2 / L):>12.6f}")
for eps in (1.0, 0.01, 0.0001):              # a sluice gate: 0.6 m jump over eps hours
    print(f"break: jump 0.6 m over {eps:.4f} h, ||h'||_2 = {0.6 / sqrt(eps):>12.6f}")
for LL in (24, 240, 2400):                   # same cosine wave, longer and longer river record
    print(f"break: record of {LL:>5} h, best constant L/pi = {LL / pi:>12.6f}")
energies = []
for k in (2, 8, 32):                         # 2-D: u = log log(e/r) on the unit disc, cut at r = 10^-k
    e_closed = 2 * pi * (1 - 1 / (1 + k * log(10)))
    m, a, b = 20000, 1.0, 1 + k * log(10)    # energy = 2 pi int_1^{log(e/eps)} ds/s^2, midpoint sum
    e_num = 2 * pi * sum(1 / (a + (j + 0.5) * (b - a) / m) ** 2 for j in range(m)) * (b - a) / m
    energies.append((e_closed, e_num))
    print(f"break: 2-D, r = 1e-{k:<2}: u = {log(1 + k * log(10)):.6f}  energy {e_closed:.6f}  midpoint {e_num:.6f}")
print(f"{'break: 2-D energy ceiling 2 pi':<46} {2 * pi:>12.6f}")

# Try changing.
print()
m1, d1, _, _, _ = stats([(t, y + 1) for t, y in KNOTS])
print(f"try: sensor offset +1 m: mean {float(m1):.6f}  RMS dev {sqrt(d1 / L):.6f}")
m2, d2, _, s2, p2 = stats([(F(0), F(1)), (F(2), F(8, 5)), (F(24), F(28, 25))])
r2d, r2s = sqrt(d2 / L), sqrt(sum(p2) / L)
print(f"try: peak at hour 2: mean {float(m2):.6f}  RMS dev {r2d:.6f}  RMS slope {r2s:.6f}  ratio {r2d / r2s:.6f}")

print()
print("chart, hour   " + " ".join(f"{t:5d}" for t in range(0, 25, 2)))
print("chart, level  " + " ".join(f"{hf(t):5.2f}" for t in range(0, 25, 2)))

assert abs(mean_bf - float(mean)) < 1e-9, "exact mean vs brute force"
assert abs(dev2_bf - float(dev2)) < 1e-8, "exact spread vs brute force"
assert abs(slope2_bf - float(slope2)) < 1e-6, "exact slope energy vs brute force"
assert rms_dev <= CP * rms_slope and r2d <= CP * r2s, "Poincare inequality on both rivers"
assert worst <= 1.0, "Holder bound on every pair of hourly readings"
for N, cb, cf, cr in table:
    assert abs(cb - cf) < 1e-9 and abs(cr - cb) < 1e-9, "bisection vs formula vs Rayleigh"
assert abs(table[-1][1] - CP) < 1e-4 and table[0][1] > table[-1][1] > CP, "C_N falls to L/pi"
assert dev24 / sl24 <= table[1][1], "discrete Poincare on the hourly data"
assert all(abs(a - b) < 1e-4 for a, b in energies) and energies[-1][0] < 2 * pi, "2-D energy"
assert abs(sqrt(d1 / L) - rms_dev) < 1e-12, "an offset leaves the deviation alone"
print("ALL CHECKS PASS")
