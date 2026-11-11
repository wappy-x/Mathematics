# Digital filters, FIR and IIR -- the check behind the card.  Standard library only.
# Remove 50 Hz mains hum from an ECG sampled at FS = 500 Hz.  One spec for both filters:
# keep half the power or more up to 20 Hz; cut 49.8 to 50.2 Hz by at least 40 dB.
# FIR: a 10-tap moving average.  IIR: a 5th-order Butterworth by the bilinear transform.
# Roads: closed-form gain against H(z) summed from the coefficients; a simulated sine
# measured once settled; group delay from the phase slope against the pole formula.
import math, cmath
FS, HUM, FP, FLO, FHI, ATT = 500.0, 50.0, 20.0, 49.8, 50.2, 40.0
def db(g): return 20 * math.log10(g) if g > 1e-12 else -math.inf
def H(b, a, f, fs=FS):                            # road 1: H(z) on the unit circle
    w = 2 * math.pi * f / fs                      # radians per sample; z^-k = e^(-j w k)
    def poly(c): return sum(v * cmath.exp(-1j * w * k) for k, v in enumerate(c))
    return poly(b) / poly(a)
def run(b, a, x):                                 # road 3: the difference equation
    y = []
    for n in range(len(x)):
        acc = sum(b[k] * x[n - k] for k in range(len(b)) if n >= k)
        y.append(acc - sum(a[k] * y[n - k] for k in range(1, len(a)) if n >= k))
    return y
def settled_amp(b, a, f, secs=6):                 # amplitude over the last 5 s, whole cycles
    x = [math.sin(2 * math.pi * f * n / FS) for n in range(int(secs * FS))]
    y = run(b, a, x)[-int(5 * FS):]
    n0 = int((secs - 5) * FS)
    s = sum(v * math.sin(2 * math.pi * f * (n0 + i) / FS) for i, v in enumerate(y))
    c = sum(v * math.cos(2 * math.pi * f * (n0 + i) / FS) for i, v in enumerate(y))
    return 2 * math.hypot(s, c) / len(y)
def gdelay(b, a, f, d=1e-4):                      # group delay, ms, from the phase slope
    dph = cmath.phase(H(b, a, f + d) / H(b, a, f - d))
    return -dph / (2 * math.pi * 2 * d) * 1000
# ---- the FIR: average one full mains cycle ----
M = round(FS / HUM)
ma = [1.0 / M] * M
def ma_formula(f):                                # road 2: sin(M w/2) / (M sin(w/2))
    w = 2 * math.pi * f / FS
    return abs(math.sin(M * w / 2) / (M * math.sin(w / 2))) if f else 1.0
# ---- the IIR: Butterworth poles on a circle, mapped by the bilinear transform ----
def butter(N, fc):
    Wc = math.tan(math.pi * fc / FS)              # prewarped cutoff
    s = [Wc * cmath.exp(1j * math.pi * (2 * k + N + 1) / (2 * N)) for k in range(N)]
    poles = [(1 + p) / (1 - p) for p in s]
    a = [1 + 0j]
    for p in poles:
        a = [u - p * v for u, v in zip(a + [0], [0] + a)]
    a = [c.real for c in a]
    b = [float(math.comb(N, k)) for k in range(N + 1)]   # N zeros at z = -1
    g = sum(a) / sum(b)                           # unit gain at 0 Hz
    return [g * c for c in b], a, poles, Wc
def bw_formula(f, N, Wc): return 1 / math.sqrt(1 + (math.tan(math.pi * f / FS) / Wc) ** (2 * N))
Ws = math.tan(math.pi * FLO / FS) / math.tan(math.pi * FP / FS)
N = math.ceil(math.log10(10 ** (ATT / 10) - 1) / (2 * math.log10(Ws)))
b, a, poles, Wc = butter(N, FP)
band = [FLO + (FHI - FLO) * i / 40 for i in range(41)]
def meets(bb, aa): return min(-db(abs(H(bb, aa, f))) for f in band) >= ATT and abs(H(bb, aa, FP)) ** 2 >= 0.5 - 1e-9
brute = next(n for n in range(1, 12) if meets(*butter(n, FP)[:2]))
print(f"spec: fs {FS:.0f} Hz; half power or more to {FP:.0f} Hz; {ATT:.0f} dB off over {FLO:.1f}-{FHI:.1f} Hz")
print(f"moving average: M = {M} taps = {M / FS * 1000:.0f} ms, one mains cycle")
print(f"Butterworth: warped edge ratio {Ws:.4f}; order by formula {N}, by search {brute}")
tp, ts = math.tan(math.pi * FP / FS), math.tan(math.pi * FLO / FS)
print(f"by hand: tan(pi {FLO:.1f}/500) {ts:.5f}, tan(pi {FP:.0f}/500) {tp:.5f}, log10(9999) {math.log10(9999):.5f}, "
      f"2 log10(ratio) {2 * math.log10(Ws):.4f}, N >= {math.log10(9999) / (2 * math.log10(Ws)):.3f}")
print(f"by hand: sin(0.4 pi) {math.sin(0.4 * math.pi):.4f}, 10 sin(0.04 pi) {10 * math.sin(0.04 * math.pi):.4f}, average at 20 Hz "
      f"{ma_formula(20):.4f}; 1/sin(pi/10) {1 / math.sin(math.pi / 10):.3f}; Butterworth at 50.2 Hz {bw_formula(50.2, N, Wc):.4f}")
print("b x 10^4 =", " ".join(f"{c * 1e4:.6f}" for c in b))
print("a =", " ".join(f"{c:.6f}" for c in a))
print("pole radii", " ".join(f"{abs(p):.4f}" for p in poles))
print("gain dB      f(Hz):  10.0   15.0   20.0   30.0   49.8   50.0   50.2   75.0")
fs_ = [10, 15, 20, 30, 49.8, 50, 50.2, 75]
for name, bb, aa in [("moving avg", ma, [1.0]), ("Butterworth", b, a)]:
    print(f"{name:12s}        " + " ".join(f"{db(abs(H(bb, aa, f))):6.2f}" for f in fs_))
amp = {f: (settled_amp(ma, [1.0], f), settled_amp(b, a, f)) for f in (20.0, 50.2, 75.0)}
for f, (u, v) in amp.items():
    print(f"simulated sine {f:4.1f} Hz, settled amplitude: moving avg {u:.6f}, Butterworth {v:.6f}")
print(f"0.5 mV of hum at {FHI:.1f} Hz leaves: moving avg {500 * amp[50.2][0]:.2f} uV, Butterworth {500 * amp[50.2][1]:.2f} uV")
grid = [0.25 * i for i in range(1001)]
e1 = max(abs(abs(H(ma, [1.0], f)) - ma_formula(f)) for f in grid)
e2 = max(abs(abs(H(b, a, f)) - bw_formula(f, N, Wc)) for f in grid[:-1])
print(f"formula and H(z) agree to 1e-12 (moving avg), 1e-9 (Butterworth): {'yes' if e1 < 1e-12 and e2 < 1e-9 else 'no'}")
for f in (49.5, 50.5, 51.0):
    print(f"mains drifts to {f:.1f} Hz: moving avg {db(ma_formula(f)):.2f} dB, Butterworth {db(bw_formula(f, N, Wc)):.2f} dB")
gd0 = 1000 / (math.sin(math.pi / (2 * N)) * 2 * FS * Wc)
gds = [gdelay(b, a, f) for f in (0.01, 5, 10, 15)]
peak = max((gdelay(b, a, 0.1 * i), 0.1 * i) for i in range(1, 251))
print(f"group delay ms: moving avg {gdelay(ma, [1.0], 5):.3f} at 5 Hz, {gdelay(ma, [1.0], 30):.3f} at 30 Hz")
print(f"Butterworth at 0, 5, 10, 15 Hz: " + ", ".join(f"{g:.2f}" for g in gds) + f"; peak {peak[0]:.2f} at {peak[1]:.1f} Hz")
print(f"Butterworth at 0 Hz by the pole formula: {gd0:.2f} ms")
# ---- what it would cost to match the Butterworth everywhere with linear phase ----
def hamming_fir(L, fc, fs=FS):
    h = [(0.54 - 0.46 * math.cos(2 * math.pi * k / (L - 1))) *
         (math.sin(2 * math.pi * fc / fs * (k - (L - 1) / 2)) / (math.pi * (k - (L - 1) / 2)) if 2 * k != L - 1 else 2 * fc / fs)
         for k in range(L)]
    return [v / sum(h) for v in h]
stop = [FLO + 0.4 * i for i in range(501)]
def full_spec(h, fs=FS): return abs(H(h, [1.0], FP, fs)) ** 2 >= 0.5 and max(abs(H(h, [1.0], f, fs)) for f in stop) <= 10 ** (-ATT / 20)
L = next(L for L in range(11, 201, 2) if full_spec(hamming_fir(L, (FP + FLO) / 2)))
print(f"Hamming-window FIR meeting 40 dB at every f >= {FLO:.1f} Hz: {L} taps, delay {(L - 1) / 2 / FS * 1000:.0f} ms")
print(f"multiplies per sample: moving avg {M} (1 as a running sum), Butterworth {len(b) + len(a) - 1}, Hamming FIR {L}")
def cos_gain(h, f):                               # road 2 for a symmetric FIR: a real cosine sum (Step 2)
    return abs(sum(v * math.cos(2 * math.pi * f / FS * (k - (len(h) - 1) / 2)) for k, v in enumerate(h)))
hL, hL2 = hamming_fir(L, (FP + FLO) / 2), hamming_fir(L - 2, (FP + FLO) / 2)
pk, pk2 = [max(cos_gain(h, FLO + 0.05 * i) for i in range(4001)) for h in (hL, hL2)]   # 0.05 Hz steps to 249.8 Hz
print(f"  by cosine sum, 0.05 Hz grid: worst stopband gain {L} taps {db(pk):.2f} dB, {L - 2} taps {db(pk2):.2f} dB; {L} taps at {FP:.0f} Hz {db(cos_gain(hL, FP)):.2f} dB")
# ---- one heartbeat with 0.5 mV of hum, through both filters ----
def ecg(t):
    g = lambda amp, mu, sd: amp * math.exp(-((t - mu) / sd) ** 2 / 2)
    return g(0.15, -0.2, 0.025) + g(1.0, 0.0, 0.012) + g(0.3, 0.25, 0.04)
T0 = 250                                          # the R wave is at sample 250, t = 0
clean = [ecg((n - T0) / FS) for n in range(500)]
noisy = [v + 0.5 * math.sin(2 * math.pi * HUM * (n - T0) / FS) for n, v in enumerate(clean)]
y_ma, y_bw = run(ma, [1.0], noisy), run(b, a, noisy)
y_zp = run(b, a, run(b, a, noisy)[::-1])[::-1]   # forward, then backward in time
for name, y in [("clean", clean), ("moving avg", y_ma), ("Butterworth", y_bw), ("forward-backward", y_zp)]:
    k = max(range(T0 - 50, T0 + 50), key=lambda i: y[i])
    dip = min(y[k:k + 40]) - min(clean[k:k + 40])
    print(f"R peak {name:16s}: {y[k]:.3f} mV at {(k - T0) / FS * 1000:+5.0f} ms; dip below clean {dip:+.3f} mV")
idx = range(T0 - 20, T0 + 41)
print("chart, t ms   " + " ".join(f"{(i - T0) * 2:5d}" for i in idx))
for name, y in [("noisy", noisy), ("moving avg", y_ma), ("Butterworth", y_bw)]:
    print(f"chart, {name:11s} " + " ".join(f"{y[i]:5.2f}" for i in idx))
print("chart, f Hz   " + " ".join(f"{5 * i:4d}" for i in range(51)))
for name, bb, aa in [("moving avg", ma, [1.0]), ("Butterworth", b, a)]:
    print(f"chart, {name:11s} " + " ".join(f"{round(max(db(abs(H(bb, aa, 5 * i))), -100)):4d}" for i in range(51)))
# ---- what breaks ----
m9 = abs(H([1 / 9] * 9, [1.0], HUM))
b4, a4 = butter(N - 1, FP)[:2]
print(f"breaks: 8-tap average at 60 Hz {db(abs(H([1 / 8] * 8, [1.0], 60))):.2f} dB; 9-tap average at 50 Hz {db(m9):.2f} dB; order {N - 1} Butterworth at {FLO:.1f} Hz {db(abs(H(b4, a4, FLO))):.2f} dB")
order = lambda fs, fp: math.ceil(math.log10(10 ** (ATT / 10) - 1) / (2 * math.log10(math.tan(math.pi * FLO / fs) / math.tan(math.pi * fp / fs))))
L1k = next(L for L in range(11, 401, 2) if full_spec(hamming_fir(L, (FP + FLO) / 2, 1000.0), 1000.0))
print(f"try: fs 1000 Hz: average {round(1000 / HUM)} taps, Butterworth order {order(1000.0, FP)} ({2 * order(1000.0, FP) + 1} multiplies), "
      f"Hamming FIR {L1k} taps; FP 25 Hz: Butterworth order {order(FS, 25.0)} ({2 * order(FS, 25.0) + 1} multiplies)")
assert abs(H(ma, [1.0], HUM)) < 1e-12 and N == 5 == brute and e1 < 1e-12 and e2 < 1e-9
assert all(abs(u - abs(H(ma, [1.0], f))) < 1e-9 and abs(v - bw_formula(f, N, Wc)) < 1e-6 for f, (u, v) in amp.items())
assert abs(gds[0] - gd0) < 1e-3 and abs(gdelay(ma, [1.0], 30) - (M - 1) / 2 / FS * 1000) < 1e-6
assert meets(ma, [1.0]) and meets(b, a) and not meets(b4, a4) and max(abs(p) for p in poles) < 1
assert pk <= 10 ** (-ATT / 20) < pk2 and cos_gain(hL, FP) ** 2 >= 0.5 and not full_spec(ma)
print("ALL CHECKS PASS")
