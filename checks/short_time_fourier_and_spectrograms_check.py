# Spectrograms -- the check behind the card.  Standard library only.
# A rising whistle is cut into overlapping Hann-windowed slices, and each slice
# goes through the FFT written out below.  Nothing imported knows the answer.
from math import sin, cos, pi, sqrt, log

FS, N, F0, C = 16000, 8000, 2000.0, 4000.0     # samples/s, samples (0.5 s), start Hz, sweep Hz/s
M = 8192                                        # zero-padded length for measuring a slice finely

def whistle(c):                                 # pitch F0 + c t, so the phase is 2 pi (F0 t + c t^2 / 2)
    return [sin(2 * pi * (F0 * n / FS + 0.5 * c * (n / FS) ** 2)) for n in range(N)]

def fft(a, sign=-1):                            # radix-2 FFT; sign=+1 runs it backwards
    a = list(a); n = len(a); j = 0
    for i in range(1, n):                       # bit-reversed order first
        b = n >> 1
        while j & b:
            j ^= b; b >>= 1
        j |= b
        if i < j:
            a[i], a[j] = a[j], a[i]
    size = 2
    while size <= n:
        h = size // 2
        tw = [complex(cos(2 * pi * k / size), sign * sin(2 * pi * k / size)) for k in range(h)]
        for s in range(0, n, size):
            for k in range(h):
                u, v = a[s + k], a[s + k + h] * tw[k]
                a[s + k], a[s + k + h] = u + v, u - v
        size *= 2
    return a

def hann(L):  return [0.5 - 0.5 * cos(2 * pi * n / L) for n in range(L)]

def slice_power(x, start, w, size):             # one column of the spectrogram, |X|^2, 0 .. FS/2
    seg = [x[start + i] * w[i] for i in range(len(w))] + [0.0] * (size - len(w))
    return [abs(z) ** 2 for z in fft(seg)[:size // 2]]

def centroid_spread(P):                         # power-weighted mean and standard deviation, Hz
    f = [k * FS / M for k in range(len(P))]; tot = sum(P)
    mean = sum(a * p for a, p in zip(f, P)) / tot
    return mean, sqrt(sum((a - mean) ** 2 * p for a, p in zip(f, P)) / tot)

def window_spreads(L):                          # time spread and frequency spread of the window itself
    w = hann(L); e = sum(v * v for v in w)
    dt = sqrt(sum(((n - L / 2) / FS) ** 2 * w[n] ** 2 for n in range(L)) / e)
    slope = [pi * FS / L * sin(2 * pi * n / L) for n in range(L)]           # dw/dt, exactly
    return dt, sqrt(sum(s * s for s in slope) / e) / (2 * pi)

def zero_cross_hz(x, start, L):                 # no Fourier at all: count the half-cycles
    t = [(n + x[n] / (x[n] - x[n + 1])) / FS for n in range(start, start + L - 1)
         if (x[n] < 0) != (x[n + 1] < 0)]
    return (len(t) - 1) / (2 * (t[-1] - t[0]))

x = whistle(C)
L, HOP = 512, 256
w = hann(L)
frames = (N - L) // HOP + 1
print(f"whistle: {FS} samples/s, {N} samples = {N / FS:.3f} s, pitch {F0:.0f} -> {F0 + C * N / FS:.0f} Hz, sweep {C:.0f} Hz/s")
print(f"spectrogram: Hann window {L} samples = {1000 * L / FS:.1f} ms, hop {HOP} = {1000 * HOP / FS:.1f} ms, "
      f"{frames} slices, bins {FS / L:.2f} Hz apart")
print("slice  centre_ms  whistle_Hz  centroid_Hz  peak_Hz  zero_cross_Hz")
worst_c = worst_p = 0.0
for m in range(frames):
    s = m * HOP; t = (s + L / 2) / FS
    cen, _ = centroid_spread(slice_power(x, s, w, M))
    P = slice_power(x, s, w, L); k = max(range(1, L // 2 - 1), key=P.__getitem__)
    a, b, c = log(P[k - 1]), log(P[k]), log(P[k + 1])
    peak = (k + 0.5 * (a - c) / (a - 2 * b + c)) * FS / L                   # fit a bell to 3 bins
    zc = zero_cross_hz(x, s, L)
    worst_c, worst_p = max(worst_c, abs(cen - F0 - C * t)), max(worst_p, abs(peak - F0 - C * t))
    assert abs(zc - F0 - C * t) < 2.0 and abs(peak - zc) < 3.0             # three roads agree
    if m % 5 == 0 or m == frames - 1:
        print(f"{m:5d}  {1000 * t:9.1f}  {F0 + C * t:10.2f}  {cen:11.2f}  {peak:7.2f}  {zc:13.2f}")
print(f"worst over {frames} slices: centroid off by {worst_c:.2f} Hz, peak off by {worst_p:.2f} Hz")
assert worst_c < 0.5 and worst_p < 3.0

P = slice_power(x, 4000 - L // 2, w, L)         # the slice centred on 250 ms, the spectrogram's own bins
top = max(P)
print("bars, Hz " + " ".join(f"{k * FS / L:7.2f}" for k in range(92, 101)))
print("bars, %  " + " ".join(f"{100 * P[k] / top:7.1f}" for k in range(92, 101)))

print("window  ms  spread_Hz  formula_Hz  steady_tone_Hz  sweep_part_Hz")
tone = whistle(0.0)
spreads = {}
for Lw in (32, 64, 128, 256, 512, 1024, 2048):
    dt, df = window_spreads(Lw)
    _, B = centroid_spread(slice_power(x, 4000 - Lw // 2, hann(Lw), M))
    _, B0 = centroid_spread(slice_power(tone, 4000 - Lw // 2, hann(Lw), M))
    spreads[Lw] = B
    print(f"{Lw:6d} {1000 * Lw / FS:5.1f} {B:9.2f} {sqrt(df ** 2 + (C * dt) ** 2):11.2f} {B0:15.2f} {C * dt:14.2f}")
    assert abs(B - sqrt(df ** 2 + (C * dt) ** 2)) < 0.1 and abs(B0 - df) < 0.3     # measured = formula
    assert abs(dt * df - (1 / 12 - 5 / (8 * pi * pi)) ** 0.5 / 3 ** 0.5) < 1e-4    # Hann, closed form
dt, df = window_spreads(L)
T = L / FS
print(f"Hann at {L}: time spread {1000 * dt:.4f} ms (closed form {1000 * T * sqrt(1 / 12 - 5 / (8 * pi * pi)):.4f}), "
      f"frequency spread {df:.3f} Hz (closed form {1 / (sqrt(3) * T):.3f})")
a, b = df * T, dt / T                           # spreads in units of 1/T and of T
print(f"a = {a:.5f}, b = {b:.5f}, product {dt * df:.5f} at every length; Gabor's floor 1/(4 pi) = {1 / (4 * pi):.5f}")
best = sqrt(a / (b * C))
print(f"best Hann window for this whistle: {best * FS:.0f} samples = {1000 * best:.1f} ms, spread {sqrt(2 * a * b * C):.2f} Hz;"
      f" no real window beats {sqrt(C / (2 * pi)):.2f} Hz")
assert min(spreads, key=spreads.get) == 512 and sqrt(C / (2 * pi)) < spreads[512] < sqrt(2 * a * b * C) + 0.05
for Lw in (64, 512, 2048):                      # the picture: each column's centre +- spread, slices centred 192 .. 320 ms
    cb = [centroid_spread(slice_power(x, 16 * t - Lw // 2, hann(Lw), M)) for t in (192, 224, 256, 288, 320)]
    print(f"picture, {Lw // 16} ms slice, centre + B: " + ", ".join(f"{c + d:.1f}" for c, d in cb))
    print(f"picture, {Lw // 16} ms slice, centre - B: " + ", ".join(f"{c - d:.1f}" for c, d in cb))

def overlap_add(x, L, hop):                     # forward FFT, backward FFT, add the slices back up
    y, wsum, w = [0.0] * N, [0.0] * N, hann(L)
    for s in range(0, N - L + 1, hop):
        back = fft(fft([x[s + i] * w[i] for i in range(L)]), +1)
        for i in range(L):
            y[s + i] += back[i].real / L; wsum[s + i] += w[i]
    mid = range(L, N - L)
    return min(wsum[n] for n in mid), max(wsum[n] for n in mid), max(abs(y[n] - x[n]) for n in mid)
lo, hi, err = overlap_add(x, L, HOP)
print(f"overlap-add, hop {HOP}: window sum {lo:.6f} to {hi:.6f}, rebuild error {err:.9f}")
lo2, hi2, err2 = overlap_add(x, L, L)
print(f"mistake, hop {L} (no overlap): window sum {lo2:.3f} to {hi2:.3f}, rebuild error {err2:.3f}")
assert err < 1e-9 and abs(lo - 1) < 1e-9 and err2 > 0.9
cs = 15 * HOP + L / 2
print(f"mistake, label by start: slice centred {1000 * cs / FS:.1f} ms read as {1000 * (cs - L / 2) / FS:.1f} ms: "
      f"whistle at centre {F0 + C * cs / FS:.2f} Hz, at start {F0 + C * (cs - L / 2) / FS:.2f} Hz")
Pr, Ph = slice_power(x, 4000 - L // 2, [1.0] * L, M), slice_power(x, 4000 - L // 2, w, M)
k5 = round(3500 * M / FS)
print(f"mistake, no taper: power 500 Hz from the ridge {10 * log(Pr[k5] / max(Pr), 10):.1f} dB (Hann {10 * log(Ph[k5] / max(Ph), 10):.1f} dB)")

x8 = whistle(8000.0)
b8 = {Lw: centroid_spread(slice_power(x8, 4000 - Lw // 2, hann(Lw), M))[1] for Lw in (256, 512)}
print(f"try, sweep 8000 Hz/s: best {sqrt(a / (b * 8000)) * FS:.0f} samples = {1000 * sqrt(a / (b * 8000)):.1f} ms, "
      f"spread {sqrt(2 * a * b * 8000):.2f} Hz; measured at 256: {b8[256]:.2f}, at 512: {b8[512]:.2f}")
_, b0 = centroid_spread(slice_power(tone, 4000 - 1024, hann(2048), M))
print(f"try, steady 2000 Hz tone, window 2048: spread {b0:.2f} Hz")
print(f"try, hop {L // 4}: window sum {sum(w[i] for i in range(0, L, L // 4)):.3f}")
print("ALL CHECKS PASS")
