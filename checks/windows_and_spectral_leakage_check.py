# Windows and spectral leakage -- the check behind the card.  Standard library only.
# One frame of a guitar recording at 44.1 kHz holds a loud 440 Hz note and a faint
# 470 Hz buzz, 40 dB quieter.  Roads to each windowed spectrum: the FFT of the samples
# (written out below), the closed form (shifted copies of the plain window's spectrum),
# a direct sum at one bin, and the large-N shortcut used by hand.  Nothing imported knows the answer.
from math import cos, sin, pi, log10

FS, N = 44100.0, 8192                      # sampling rate (Hz) and frame length (samples)
BIN = FS / N                               # bin spacing, Hz
WIN = {"rect": (1.0, 0.0, 0.0), "Hann": (0.5, 0.5, 0.0),
       "Hamming": (0.54, 0.46, 0.0), "Blackman": (0.42, 0.5, 0.08)}   # w = a0 - a1 cos + a2 cos 2x
LOUD, BUZZ = (1.0, 440.0), (0.01, 470.0)   # (amplitude in volts, frequency in Hz)

def window(a, n=N):
    return [a[0] - a[1] * cos(2 * pi * i / n) + a[2] * cos(4 * pi * i / n) for i in range(n)]

def fft(x):                                # radix-2, length a power of two
    a, n, j = list(x), len(x), 0
    for i in range(1, n):                  # bit-reversed order first
        b = n >> 1
        while j & b: j ^= b; b >>= 1
        j |= b
        if i < j: a[i], a[j] = a[j], a[i]
    size = 2
    while size <= n:
        h = size // 2
        tw = [complex(cos(2 * pi * k / size), -sin(2 * pi * k / size)) for k in range(h)]
        for s in range(0, n, size):
            for k in range(h):
                u, v = a[s + k], a[s + k + h] * tw[k]
                a[s + k], a[s + k + h] = u + v, u - v
        size *= 2
    return a

def kernel(d, n=N):                        # the plain window's spectrum, d bins off centre
    if abs(d - round(d)) < 1e-12 and round(d) % n == 0: return complex(n, 0)
    ph = -pi * d * (n - 1) / n
    return complex(cos(ph), sin(ph)) * (sin(pi * d) / sin(pi * d / n))

def W(a, d, n=N):                          # any cosine window = shifted plain kernels
    return (a[0] * kernel(d, n) - a[1] / 2 * (kernel(d - 1, n) + kernel(d + 1, n))
            + a[2] / 2 * (kernel(d - 2, n) + kernel(d + 2, n)))

def closed(a, tones, k, n=N):              # X at bin k (may be fractional), by closed form
    return sum(A / 2 * (W(a, k - f * n / FS, n) + W(a, k + f * n / FS, n)) for A, f in tones)

def db(z, a, n=N): return 20 * log10(2 * abs(z) / (a[0] * n))   # dB relative to 1 volt

def signal(tones, n=N): return [sum(A * cos(2 * pi * f * i / FS) for A, f in tones) for i in range(n)]

x = signal((LOUD, BUZZ))
print(f"frame {N} samples = {1000 * N / FS:.1f} ms, bin spacing {BIN:.3f} Hz")
print(f"note at bin {440 / BIN:.4f}, buzz at bin {470 / BIN:.4f}, {30 / BIN:.2f} bins apart")
print(f"cycles of 440 Hz in the frame {440 * N / FS:.2f}; seam jump {1 - cos(2 * pi * 440 * N / FS):.3f} V")

# ---- each window's own shape, measured on its closed-form spectrum ----
print("window     a0    a1    a2  null_bins  sidelobe_dB  falloff_dB/oct  ENBW_bins  scallop_dB")
props = {}
for name, a in WIN.items():
    w = window(a)
    enbw = N * sum(v * v for v in w) / sum(w) ** 2
    mag = lambda d: abs(W(a, d)) / abs(W(a, 0))
    grid = [i / 100 for i in range(1, 2001)]
    null = next(d for d in grid if mag(d) < 1e-6)            # first zero of the main lobe
    side = 20 * log10(max(mag(d) for d in grid if d > null))
    env = lambda lo: max(mag(lo + i / 100) for i in range(101))
    props[name] = (null, side, 20 * log10(env(8) / env(16)), enbw, -20 * log10(mag(0.5)))
    print(f"{name:<9}{a[0]:5.2f} {a[1]:5.2f} {a[2]:5.2f} {null:7.2f} {side:11.2f} {props[name][2]:13.2f} "
          f"{enbw:12.4f} {props[name][4]:10.2f}")
lo, hi = 1.3, 1.49                          # plain window's first sidelobe: tan(pi x) = pi x
for _ in range(60):
    xs = (lo + hi) / 2
    lo, hi = (xs, hi) if sin(pi * xs) / cos(pi * xs) < pi * xs else (lo, xs)
side_theory = 20 * log10(abs(sin(pi * xs) / (pi * xs)))
print(f"plain first sidelobe from sin(pi x)/(pi x): x = {xs:.4f} bins, {side_theory:.2f} dB; "
      f"tails 1/d and 1/d^3 fall {20 * log10(2):.2f} and {60 * log10(2):.2f} dB per doubling")

# ---- the example, 8192 samples: FFT of the samples against the closed form ----
spec, gap = {}, 0.0
for name, a in WIN.items():
    X = fft([complex(v * s, 0) for v, s in zip(window(a), x)])
    gap = max(gap, max(abs(X[k] - closed(a, (LOUD, BUZZ), k)) / N for k in range(60, 110)))
    spec[name] = [db(X[k], a) for k in range(N // 2)]
print(f"chart, Hz      " + " ".join(f"{k * BIN:6.1f}" for k in range(76, 97)))
for name in WIN:
    print(f"chart, {name:<8}" + " ".join(f"{spec[name][k]:6.1f}" for k in range(76, 97)))
k87, hw = round(470 / BIN), window(WIN["Hann"])
direct = sum(v * s * complex(cos(2 * pi * k87 * i / N), -sin(2 * pi * k87 * i / N))
             for i, (v, s) in enumerate(zip(hw, x)))
print(f"FFT vs closed form, bins 60-109: agree to 1e-9: {'yes' if gap < 1e-9 else 'no'}; "
      f"Hann bin {k87} by direct sum {db(direct, WIN['Hann']):.2f} dB")
print("window    bin87_dB  leak_only_dB  buzz_only_dB  margin_dB  note_peak_dB")
show = {}
for name, a in WIN.items():
    leak, own = db(closed(a, (LOUD,), k87), a), db(closed(a, (BUZZ,), k87), a)
    show[name] = own - leak
    print(f"{name:<9}{spec[name][k87]:9.2f} {leak:12.2f} {own:13.2f} {own - leak:10.2f} {max(spec[name][78:86]):12.2f}")
d, e = k87 - 440 / BIN, 470 / BIN - k87     # the same three Hann numbers by the large-N shortcut
sinc = lambda t: sin(pi * t) / (pi * t)
print(f"by hand: d = {d:.4f}, delta = {e:.4f} bins, plain leak {20 * log10(abs(sinc(d))):.1f} dB, Hann leak "
      f"{20 * log10(abs(sinc(d) / (1 - d * d))):.1f} dB, Hann buzz {20 * log10(0.01 * sinc(e) / (1 - e * e)):.1f} dB")

# ---- the trade: frame length against window, buzz margin over the worst nearby leakage ----
print("frame      ms   bins_apart    rect    Hann  Hamming  Blackman  (margin_dB)")
marg = {}
for n in (2048, 4096, 8192, 16384):
    sep = 30 * n / FS
    m = [-40 - 20 * log10(max(abs(W(a, sep + (i - 50) / 100, n)) for i in range(101)) / (a[0] * n))
         for a in WIN.values()]
    marg[n] = dict(zip(WIN, m))
    print(f"{n:6d} {1000 * n / FS:7.1f} {sep:10.2f} " + " ".join(f"{v:7.1f}" for v in m))
n = 8192
while -40 - 20 * log10(max(abs(kernel(30 * n / FS + (i - 50) / 100, n)) for i in range(101)) / n) < 0:
    n += 1
print(f"plain window first shows the buzz at {n} samples = {n / FS:.2f} s")
hx = [complex(v * s, 0) for v, s in zip(window(WIN["Hann"], 4096), signal((LOUD, BUZZ), 4096))]
plain, pad = fft(hx), fft(hx + [0j] * 3 * 4096)    # zero padding x4: the same curve, sampled finer
kz = round(4 * 470 * 4096 / FS)
zgap = max(max(abs(pad[4 * k] - plain[k]) for k in range(4096)),
           max(abs(pad[kz + i] - closed(WIN["Hann"], (LOUD, BUZZ), (kz + i) / 4, 4096)) for i in range(-8, 9))) / 4096
print(f"Hann, 4096 frame padded x4 to {FS / 16384:.3f} Hz bins: same curve as unpadded and closed form "
      f"to 1e-9: {'yes' if zgap < 1e-9 else 'no'}")
on = max(abs(closed(WIN["rect"], ((1.0, 82 * BIN),), k)) / N for k in range(60, 110) if k != 82)
print(f"plain window, tone exactly on bin 82 ({82 * BIN:.2f} Hz): every other bin below 1e-9: {'yes' if on < 1e-9 else 'no'}")
print(f"mistake: Hann read without dividing by a0: note peak {spec['Hann'][82] + 20 * log10(0.5):.2f} dB")
print(f"mistake: noise per bin with Hann, no ENBW correction: {10 * log10(props['Hann'][3]):.2f} dB high")
loud_buzz = db(closed(WIN["rect"], ((0.1, 470.0),), k87), WIN["rect"]) - db(closed(WIN["rect"], (LOUD,), k87), WIN["rect"])
print(f"try: buzz raised to 0.1 V (20 dB down), plain-window margin at bin 87 {loud_buzz:.2f} dB")

assert gap < 1e-9,                                          "FFT must equal the shifted-kernel closed form"
assert abs(db(direct, WIN["Hann"]) - spec["Hann"][k87]) < 1e-9, "direct sum must equal the FFT bin"
assert zgap < 1e-9,                                         "zero padding samples the same curve"
assert abs(props["rect"][1] - side_theory) < 0.01,          "plain sidelobe vs the sinc's first peak"
assert abs(props["Hann"][3] - 1.5) < 1e-9,                  "Hann ENBW vs (a0^2 + a1^2/2)/a0^2"
assert abs(20 * log10(abs(sinc(d) / (1 - d * d))) - (db(closed(WIN["Hann"], (LOUD,), k87), WIN["Hann"]))) < 0.2, "shortcut"
assert show["rect"] < -6 and show["Hann"] > 6 and show["Blackman"] > 6, "plain hides the buzz; tapers show it"
assert marg[4096]["Hamming"] > 0 > marg[4096]["Blackman"] and marg[8192]["Blackman"] > marg[8192]["Hamming"], "trade"
assert on < 1e-9,                                           "a whole number of cycles leaks nothing"
print("ALL CHECKS PASS")
