# Regular perturbation -- the check behind the card.  Standard library only.
# A seconds pendulum (small-swing period exactly 2 s) released from rest at
# 10 degrees.  Its period is found three ways: the perturbation series in
# eps = a^2, Gauss's arithmetic-geometric mean, and RK4 stepping of the swing.
from math import pi, sin, cos, sqrt

G = 9.80665                          # standard gravity, m/s^2 (NIST conventional value)
L = G / (pi * pi)                    # rod length giving a 2 s small-swing period, m
T0 = 2.0 * pi * sqrt(L / G)          # small-swing period, s
DAY = 86400.0                        # seconds in a day
D = pi / 180.0                       # radians per degree

def series(a, n):                    # T/T0 from the series, keeping n corrections
    e = a * a
    return (1.0, 1.0 + e / 16.0, 1.0 + e / 16.0 + 11.0 * e * e / 3072.0)[n]

def agm(x, y):                       # Gauss's arithmetic-geometric mean, written out
    for _ in range(30):
        x, y = 0.5 * (x + y), sqrt(x * y)
    return x

def exact(a):                        # T/T0 = 1 / AGM(1, cos(a/2)): no series anywhere
    return 1.0 / agm(1.0, cos(0.5 * a))

def step(th, w, h):                  # one RK4 step of th' = w, w' = -sin th
    k1t, k1w = w, -sin(th)
    k2t, k2w = w + 0.5 * h * k1w, -sin(th + 0.5 * h * k1t)
    k3t, k3w = w + 0.5 * h * k2w, -sin(th + 0.5 * h * k2t)
    k4t, k4w = w + h * k3w, -sin(th + h * k3t)
    return (th + h * (k1t + 2.0 * k2t + 2.0 * k3t + k4t) / 6.0,
            w + h * (k1w + 2.0 * k2w + 2.0 * k3w + k4w) / 6.0)

def rk4_ratio(a, h=0.001):           # time from rest at a to the bottom, times 4, over 2 pi
    th, w, n = a, 0.0, 0
    while True:
        th2, w2 = step(th, w, h)
        if th2 <= 0.0:
            break
        th, w, n = th2, w2, n + 1
    lo, hi = 0.0, h                  # bisect the last step to land on the bottom
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if step(th, w, mid)[0] > 0.0:
            lo = mid
        else:
            hi = mid
    return 4.0 * (n * h + lo) / (2.0 * pi)

def strained(a, t):                  # two-term solution, frequency expanded too
    e = a * a
    tau = (1.0 - e / 16.0 + e * e / 3072.0) * t
    return a * (cos(tau) + e * (cos(tau) - cos(3.0 * tau)) / 192.0)

def naive(a, t):                     # two-term solution, frequency held at 1
    e = a * a
    return a * (cos(t) + e * ((cos(t) - cos(3.0 * t)) / 192.0 + t * sin(t) / 16.0))

a = 10.0 * D
e = a * a
s = [series(a, n) for n in range(3)]
x, r = exact(a), rk4_ratio(a)
print(f"pendulum: l = {L:.6f} m, g = {G:.5f} m/s^2, T0 = {T0:.9f} s, time unit sqrt(l/g) = {sqrt(L / G):.6f} s")
print(f"amplitude a = 10 deg = {a:.6f} rad; eps = a^2 = {e:.6f}")
print(f"first correction eps/16 = {e / 16.0:.9f}; second 11 eps^2/3072 = {11.0 * e * e / 3072.0:.9f}")
for label, v in (("0 corrections", s[0]), ("1 correction", s[1]), ("2 corrections", s[2]),
                 ("exact, by AGM", x), ("exact, by RK4", r)):
    print(f"period, {label:<15} {v * T0:.9f} s")
for n in range(3):
    err = (x - s[n]) / x
    print(f"error, keeping {n}       {err * 1e6:11.4f} ppm   clock off by {DAY * err:9.4f} s/day")
for d in (9.0, 10.0, 11.0):
    print(f"clock at {d:4.1f} deg loses {DAY * (1.0 - 1.0 / exact(d * D)):7.2f} s/day vs the small-swing 2 s")
print(f"near 10 deg the loss changes by {DAY * (1.0 / exact(9.0 * D) - 1.0 / exact(11.0 * D)) / 2.0:.2f} s/day per degree")
print("shrink: amplitude deg   eps        error 1 corr ppm   error 2 corr ppb")
errs = {}
for d in (20.0, 10.0, 5.0, 2.5):
    b = d * D
    xb = exact(b)
    errs[d] = (xb - series(b, 2)) / xb
    print(f"shrink: {d:12.1f}   {b * b:.6f}   {(xb - series(b, 1)) / xb * 1e6:16.4f}   {errs[d] * 1e9:16.4f}")
ratio = errs[10.0] / errs[5.0]
print(f"halving the amplitude cuts the 2-correction error by {ratio:.2f} (eps^3 predicts 64)")
r1 = lambda b: (exact(b) - 1.0) / (b * b)                          # left over after 1, per eps
r2 = lambda b: (exact(b) - 1.0 - b * b / 16.0) / (b * b * b * b)   # after 1 + eps/16, per eps^2
c1 = (4.0 * r1(0.5 * D) - r1(1.0 * D)) / 3.0                       # Richardson: cancel the next term
c2 = (4.0 * r2(2.0 * D) - r2(4.0 * D)) / 3.0
print(f"coefficient of eps, read off the AGM:   {c1:.10f}   derived 1/16    = {1.0 / 16.0:.10f}")
print(f"coefficient of eps^2, read off the AGM: {c2:.10f}   derived 11/3072 = {11.0 / 3072.0:.10f}")

N = 4000                             # one exact period, sampled for the third harmonic
P = 2.0 * pi * x
th, w, b3 = a, 0.0, 0.0
for k in range(N):
    b3 += th * cos(3.0 * 2.0 * pi * k / N)
    th, w = step(th, w, P / N)
b3 = 2.0 * b3 / N / a
print(f"third harmonic, share of the swing: RK4 {b3:.7f}   derived -eps/192 = {-e / 192.0:.7f}")

M = 2000                             # 100 swings: both expansions against RK4
th, w, worst, chart = a, 0.0, 0.0, {0: (a, a, a, a)}
for n in range(1, 101):
    for k in range(M):
        th, w = step(th, w, P / M)
        t = ((n - 1) * M + k + 1) * (P / M)
        worst = max(worst, abs(th - strained(a, t)))
    chart[n] = (th, a * cos(t), naive(a, t), strained(a, t))
for n in (1, 10, 100):
    v = [c / D for c in chart[n]]
    print(f"after {n:3d} swings: RK4 {v[0]:7.4f} deg  small-angle {v[1]:8.4f}  naive {v[2]:8.4f}  strained {v[3]:7.4f}")
print(f"worst gap, strained expansion vs RK4, 100 swings ({100.0 * P * sqrt(L / G):.2f} s): {worst / D:.6f} deg")
ns = [10 * i for i in range(11)]
print("chart, swing number   " + " ".join(f"{n:6d}" for n in ns))
for j, lab in enumerate(("RK4 deg        ", "small-angle deg", "naive deg      ", "strained deg   ")):
    print("chart, " + lab + " " + " ".join(f"{chart[n][j] / D:6.2f}" for n in ns))

print("beyond: amplitude deg   eps      exact s   2 corrections s   error %")
for d in (30.0, 60.0, 90.0, 120.0, 150.0, 170.0):
    b = d * D
    xb, sb = exact(b), series(b, 2)
    print(f"beyond: {d:12.0f}   {b * b:6.3f}   {xb * T0:7.4f}   {sb * T0:15.4f}   {(xb - sb) / xb * 100.0:7.2f}")
amps = [15.0 * i for i in range(11)]
print("chart, amplitude deg     " + " ".join(f"{d:6.0f}" for d in amps))
print("chart, exact period s    " + " ".join(f"{exact(d * D) * T0:6.2f}" for d in amps))
print("chart, 2 corrections s   " + " ".join(f"{series(d * D, 2) * T0:6.2f}" for d in amps))

ed = 10.0 * 10.0                     # mistakes, all at the 10 degree swing
print(f"wrong: eps in degrees, 100      period {T0 * (1.0 + ed / 16.0 + 11.0 * ed * ed / 3072.0):.4f} s")
print(f"wrong: eps = a, not a^2         period {T0 * (1.0 + a / 16.0 + 11.0 * a * a / 3072.0):.6f} s")
print(f"wrong: frequency read as period period {T0 * (1.0 - e / 16.0 + e * e / 3072.0):.6f} s")

assert abs(r - x) < 1e-10, "RK4 period must match the AGM period"
assert abs(c1 - 1.0 / 16.0) < 1e-9, "first coefficient read off the AGM must be 1/16"
assert abs(c2 - 11.0 / 3072.0) < 1e-8, "second coefficient read off the AGM must be 11/3072"
assert 60.0 < ratio < 70.0, "two-correction error must fall about 64-fold per halving"
assert abs(b3 + e / 192.0) < 2e-6, "RK4 third harmonic must match the first correction"
assert worst < 1e-5 * D, "strained expansion must stay on the RK4 swing for 100 swings"
assert chart[100][2] - a > 4.0 * D, "naive expansion must drift by over 4 degrees by swing 100"
print("ALL CHECKS PASS")
