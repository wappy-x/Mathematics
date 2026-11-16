# Wiener-Khinchin -- the check behind the card.  Standard library only.
# Tape hiss, modelled as white noise of level N0 = 100 uV^2/Hz (two-sided),
# goes through a first-order hiss filter with corner 5 kHz.  Its power spectrum
# is found four ways: gain squared, the transform of the autocorrelation, the
# windowed definition E|X_T^|^2 / T, and a simulation.  All integrals written out.
from math import exp, cos, sin, pi, sqrt, atan

N0, XC = 100.0, 5000.0          # hiss level, uV^2/Hz; filter corner, Hz
A = 2 * pi * XC                 # filter h(t) = A e^(-A t), t >= 0; gain h^(xi) = 1/(1 + i xi/XC)
R0 = N0 * pi * XC               # R_Y(0), the output variance, uV^2
R_Y = lambda tau: R0 * exp(-A * abs(tau))
gain2 = lambda xi: 1 / (1 + (xi / XC) * (xi / XC))
out = []
def show(label, v, fmt="14.6f"):
    out.append(f"{label:<46}{v:{fmt}}")

def simpson(f, a, b, n):
    h = (b - a) / n
    s = 0.0                     # plain loops, not sum(): Python's sum() rounds differently from Rust
    for k in range(1, n):
        s += (4 if k % 2 else 2) * f(a + k * h)
    return (f(a) + f(b) + s) * h / 3

def transform_R(xi, cut, n):    # S_Y(xi) = int R_Y(tau) e^(-2 pi i xi tau) dtau; R_Y even, so a cosine integral
    return 2 * simpson(lambda t: R_Y(t) * cos(2 * pi * xi * t), 0.0, cut, n)

def windowed(xi, T, n=40000):   # the proof's middle line: E|X_T^(xi)|^2 / T = int (1 - |tau|/T) R_Y(tau) e^(...) dtau
    cut = min(T, 2e-3)          # beyond 2 ms, R_Y < e^(-62) of its peak
    return 2 * simpson(lambda t: (1 - t / T) * R_Y(t) * cos(2 * pi * xi * t), 0.0, cut, n)

for xi in (5000.0, 10000.0):
    show(f"gain squared at {xi / 1000:.0f} kHz", gain2(xi))
    show(f"S_Y({xi / 1000:.0f} kHz) = N0 x gain squared, uV^2/Hz", N0 * gain2(xi))
    show(f"  transform of R_Y, 2000 steps to 2 ms", transform_R(xi, 2e-3, 2000))
    show(f"  transform of R_Y, 4000 steps to 2 ms", transform_R(xi, 2e-3, 4000))
show("R_Y(0) = N0 pi xi_c, output variance, uV^2", R0, "14.2f")
X = 200000.0                    # area under S_Y: sums to 200 kHz plus the closed-form tail beyond
area = 2 * simpson(lambda x: N0 * gain2(x), 0.0, X, 20000)
tail = 2 * N0 * XC * (pi / 2 - atan(X / XC))
show("  area of S_Y by sums to 200 kHz", area, "14.2f")
show("  plus the closed-form tail beyond 200 kHz", area + tail, "14.2f")
show("output rms, uV", sqrt(R0), "14.2f")
show("hiss rms in the audible band +-20 kHz, uV", sqrt(N0 * 40000), "14.2f")
show("output rms in the audible band, uV", sqrt(2 * N0 * XC * atan(4)), "14.2f")
S10 = N0 * gain2(10000.0)
for T in (1e-4, 1e-3, 1e-2, 1e-1):
    show(f"windowed E|X_T^|^2/T at 10 kHz, T = {T * 1000:g} ms", windowed(10000.0, T))
w2 = 2 * pi * 10000.0
lead = -2 * R0 * (A * A - w2 * w2) / ((A * A + w2 * w2) * (A * A + w2 * w2))   # T x (windowed - S) as T grows
show("T x gap at T = 100 ms, uV^2", 0.1 * (windowed(10000.0, 0.1) - S10), "14.9f")
show("  closed form -2 R0 (a^2-w^2)/(a^2+w^2)^2", lead, "14.9f")

# ---- simulation: independent samples at fs stand in for white noise ----
def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, (z ^ (z >> 31)) >> 11

FS, N, K = 100000.0, 1000, 1000   # 100 kHz sampling; records of 10 ms; 1000 records
C = exp(-A / FS)                  # y[n] = C y[n-1] + (1 - C) x[n]: the hiss filter, sampled
amp = sqrt(12 * N0 * FS)          # uniform samples of variance N0 fs: flat spectrum N0 up to fs/2
TAB = [(cos(2 * pi * k / 40), sin(2 * pi * k / 40)) for k in range(40)]
FREQS = list(range(0, 9))         # bins at 2.5 kHz steps: 0, 2.5, ..., 20 kHz
state, y = 2026, 0.0
for _ in range(500):              # burn-in, so the filter starts in its steady state
    state, u = splitmix(state)
    y = C * y + (1 - C) * amp * (u * 2.0 ** -53 - 0.5)
sumP, sumP2, sumvar = [0.0] * 9, [0.0] * 9, 0.0
for r in range(K):
    rec = []
    for n in range(N):
        state, u = splitmix(state)
        y = C * y + (1 - C) * amp * (u * 2.0 ** -53 - 0.5)
        rec.append(y)
    for m in FREQS:
        re = im = 0.0
        for n, v in enumerate(rec):
            re += v * TAB[(m * n) % 40][0]
            im += v * TAB[(m * n) % 40][1]
            if m == 0:
                sumvar += v * v
        P = (re * re + im * im) / (N * FS)
        sumP[m] += P
        sumP2[m] += P * P
mean = [sumP[m] / K for m in FREQS]
se = [sqrt((sumP2[m] / K - mean[m] * mean[m]) / K) for m in FREQS]
g = lambda h: N0 * FS * (1 - C) * (1 - C) / (1 - C * C) * C ** abs(h)   # autocovariance of the sampled output
def expect(xi):                   # exact E P for a 1000-sample record: the triangle-weighted sum
    s = 0.0
    for h in range(-N + 1, N):
        s += (1 - abs(h) / N) * g(h) * cos(2 * pi * xi * h / FS)
    return s / FS
def sampled_S(xi, fs):            # N0 |H_d|^2: the sampled filter's spectrum, record length infinite
    c = exp(-A / fs)
    return N0 * (1 - c) * (1 - c) / (1 - 2 * c * cos(2 * pi * xi / fs) + c * c)
for m in (2, 4):
    xi = 2500.0 * m
    show(f"sim {xi / 1000:.0f} kHz: mean of 1000 periodograms", mean[m])
    show("  its standard error", se[m])
    show("  exact expectation, 10 ms records", expect(xi))
    show("  sampled spectrum N0 |H_d|^2", sampled_S(xi, FS))
    show("  continuous S_Y", N0 * gain2(xi))
show("sim output variance, uV^2", sumvar / (N * K), "14.2f")
show("  sampled output variance g(0), uV^2", g(0), "14.2f")
for fs in (50e3, 100e3, 200e3, 400e3):
    c = exp(-A / fs)
    out.append(f"settle fs {fs / 1000:3.0f} kHz: input var {N0 * fs:11.0f}  output var {N0 * fs * (1 - c) / (1 + c):11.2f}"
               f"  S(10k) {sampled_S(1e4, fs):9.6f}")
# ---- what breaks ----
show("mistake: gain not squared at 10 kHz", N0 / sqrt(1 + 4))
show("mistake: S_Y over positive frequencies only", R0 / 2, "14.2f")
show("  its rms, uV", sqrt(R0 / 2), "14.2f")
HUM = 1000.0                      # 50 Hz hum, amplitude 1 mV, random phase: R = (HUM^2/2) cos(2 pi 50 tau)
hum = lambda T: 2 * simpson(lambda t: (1 - t / T) * HUM * HUM / 2 * cos(2 * pi * 50 * t) * cos(2 * pi * 50 * t), 0.0, T, 20000)
for T in (0.1, 1.0, 10.0):
    show(f"hum: windowed value at 50 Hz, T = {T:g} s", HUM * HUM * T / 4, "14.2f")
for T in (0.1, 1.0):
    show(f"  T = {T:g} s by sums", hum(T), "14.2f")
# ---- try changing ----
show("try: corner 2.5 kHz, S_Y(10 kHz)", N0 / (1 + 16))
show("try: corner 2.5 kHz, output rms, uV", sqrt(N0 * pi * 2500), "14.2f")
show("try: N0 = 400, output rms, uV", sqrt(400 * pi * XC), "14.2f")
out.append("chart, frequency (kHz) " + " ".join(f"{2.5 * m:5.1f}" for m in FREQS))
out.append("chart, S_Y closed      " + " ".join(f"{N0 * gain2(2500.0 * m):5.1f}" for m in FREQS))
out.append("chart, sampled filter  " + " ".join(f"{sampled_S(2500.0 * m, FS):5.1f}" for m in FREQS))
out.append("chart, S_Y simulated   " + " ".join(f"{mean[m]:5.1f}" for m in FREQS))
print("\n".join(out))

assert abs(transform_R(10000.0, 2e-3, 4000) - S10) < 1e-6        # transform of R_Y meets N0 |h^|^2
assert abs(transform_R(5000.0, 2e-3, 4000) - 50.0) < 1e-6
assert abs(area + tail - R0) < 1e-3                                  # variance = area under S_Y
assert abs(windowed(10000.0, 0.01) - S10) < abs(windowed(10000.0, 0.001) - S10) / 5   # the window settles
assert abs(0.1 * (windowed(10000.0, 0.1) - S10) - lead) < 1e-8      # with the proof's 1/T gap
for m in FREQS:
    assert abs(mean[m] - expect(2500.0 * m)) < 4 * se[m]               # simulation meets the formula
assert abs(sumvar / (N * K) - g(0)) < 0.02 * g(0)
assert all(abs(hum(T) - HUM * HUM * T / 4) < 1e-3 for T in (0.1, 1.0))  # sums confirm the growth: no density
print("ALL CHECKS PASS")
