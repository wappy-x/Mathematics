# Changing rate -- the check behind the card.  Standard library only: the
# filters, the sine-wave meter and the rate changers are all written out below.
from math import sin, cos, pi, sqrt, log10, gcd
FS = 48000                                          # the studio rate, samples a second
TONES = [(440, 0.5), (3000, 0.25), (15000, 0.1), (23000, 0.1)]   # hertz, amplitude
def add(vals):                                      # plain left-to-right sum
    s = 0.0
    for v in vals:
        s += v
    return s
def x(k):                                           # the studio recording at sample k
    return add(a * sin(2 * pi * f * k / FS) for f, a in TONES)
def lowpass(fc, fs, taps, gain):                    # windowed sinc, centred on tap 0
    c = (taps - 1) // 2
    g = []
    for j in range(-c, c + 1):
        s = 2 * fc / fs if j == 0 else sin(2 * pi * fc * j / fs) / (pi * j)
        w = 0.42 + 0.5 * cos(pi * j / c) + 0.08 * cos(2 * pi * j / c)   # Blackman window
        g.append(s * w)
    t = add(g)
    return [gain * v / t for v in g], c
def resp(g, c, f, fs, gain):                        # filter's gain at f, from its taps
    return abs(add(v * cos(2 * pi * f * (j - c) / fs) for j, v in enumerate(g))) / gain
def amp(sig, f, fs):                                # size of the f-hertz sine in sig
    re = add(v * cos(2 * pi * f * n / fs) for n, v in enumerate(sig))
    im = add(v * sin(2 * pi * f * n / fs) for n, v in enumerate(sig))
    return 2 * sqrt(re * re + im * im) / len(sig)
def fold(f, fs):                                    # where f lands after sampling at fs
    f = f % fs
    return min(f, fs - f)
def db(a): return 20 * log10(a)
def show(name, v): print(f"{name:<52}{v:>12}")
# ---- 1. decimate by 3: 48 kHz down to 16 kHz -------------------------------
g3, c3 = lowpass(7500, FS, 265, 1.0)
X0 = 400
xs = [x(k) for k in range(-X0, 5200)]               # x(k) is xs[k + X0]
naive = [xs[3 * n + X0] for n in range(1600)]       # drop two samples in three, 0.1 s
D0 = 60
dec = [add(g3[j] * xs[3 * n - (j - c3) + X0] for j in range(2 * c3 + 1)) for n in range(-D0, 1660)]
dec_s = dec[D0:D0 + 1600]
found = [(10 * b, amp(naive, 10 * b, 16000)) for b in range(800)]
found = [(f, a) for f, a in found if a > 0.01]
print("tones in the 16 kHz signal, samples simply dropped:")
print("  " + ", ".join(f"{f} Hz {a:.4f}" for f, a in found))
print(f"folding predicts 15000 -> {fold(15000, 16000)} Hz and 23000 -> {fold(23000, 16000)} Hz")
show("filtered first: 440 Hz", f"{amp(dec_s, 440, 16000):.4f}")
show("filtered first: 3000 Hz", f"{amp(dec_s, 3000, 16000):.4f}")
a1k = amp(dec_s, 1000, 16000)
show("filtered first: 1000 Hz alias, millionths, measured", f"{a1k * 1e6:.4f}")
show("  0.1 x filter gain at 15 kHz, predicted", f"{0.1 * resp(g3, c3, 15000, FS, 1) * 1e6:.4f}")
show("  the alias in decibels below 0.1", f"{db(a1k / 0.1):.1f}")
xp = [0.1 * sin(2 * pi * 9000 * k / FS) for k in range(-X0, 5200)]   # a lone probe just above 8 kHz
a7k = amp([add(g3[j] * xp[3 * n - (j - c3) + X0] for j in range(2 * c3 + 1)) for n in range(1600)], fold(9000, 16000), 16000)
show("9000 Hz probe at 0.1: 7000 Hz alias, millionths", f"{a7k * 1e6:.4f}")
show("  0.1 x filter gain at 9 kHz, predicted", f"{0.1 * resp(g3, c3, 9000, FS, 1) * 1e6:.4f}")
show("multiplies per 16 kHz sample: filter all, then drop", f"{3 * len(g3)}")
show("multiplies per 16 kHz sample: only the kept ones", f"{len(g3)}")
# ---- 2. interpolate by 3: 16 kHz back up to 48 kHz -------------------------
stuffed = [dec[i // 3 + D0] if i % 3 == 0 else 0.0 for i in range(-3 * D0, 4980)]
S0 = 3 * D0                                         # stuffed[i + S0] is sample i
st = stuffed[S0:S0 + 4800]
print("zero-stuffed 48 kHz signal, before smoothing:")
print("  " + ", ".join(f"{f} Hz {amp(st, f, FS):.4f}" for f in (440, 3000, 13000, 15560, 16440, 19000)))
up = [3 * add(g3[j] * stuffed[i - (j - c3) + S0] for j in range(2 * c3 + 1)) for i in range(4800)]
up_pp = []                                          # polyphase: skip the zeros
for i in range(4800):
    lo, hi = -((c3 - i) // 3), (i + c3) // 3       # k with |i - 3k| <= c3
    up_pp.append(3 * add(dec[k + D0] * g3[i - 3 * k + c3] for k in range(lo, hi + 1)))
d_up = max(abs(a - b) for a, b in zip(up, up_pp))
show("smoothed, gain 3: 3000 Hz", f"{amp(up, 3000, FS):.4f}")
show("smoothed, gain 3: 13000 Hz image, millionths", f"{amp(up, 13000, FS) * 1e6:.4f}")
show("smoothed, gain 1 by mistake: 3000 Hz", f"{amp(up, 3000, FS) / 3:.4f}")
low = [0.5 * sin(2 * pi * 440 * i / FS) + 0.25 * sin(2 * pi * 3000 * i / FS) for i in range(4800)]
err_rt = max(abs(a - b) for a, b in zip(up, low))
show("round trip vs the 440 + 3000 Hz part, worst, millionths", f"{err_rt * 1e6:.4f}")
show("multiplies per 48 kHz sample: through the zeros", f"{len(g3)}")
show("multiplies per 48 kHz sample: polyphase, about", f"{len(g3) / 3:.1f}")
# ---- 3. 48 kHz to 44.1 kHz: up by L, one low-pass, down by M --------------
F2 = 44100
L, M = F2 // gcd(FS, F2), FS // gcd(FS, F2)
FH = FS * L                                         # the imagined in-between rate
print(f"gcd {gcd(FS, F2)} Hz, so L = {L}, M = {M}, in-between rate {FH} Hz")
g, c = lowpass(21025, FH, 129 * L, L)
show("Blackman rule: 5.5 x rate / (22050 - 20000) Hz", f"{5.5 * FH / (22050 - 20000):.1f}")
show("taps in the one low-pass, 129 per phase", f"{len(g)}")
def rate_pp(n):                                     # polyphase: y[n] = sum x[k] g(nM - kL)
    lo, hi = -((c - n * M) // L), (n * M + c) // L
    return add(xs[k + X0] * g[n * M - k * L + c] for k in range(lo, hi + 1))
def rate_literal(n):                                # stuff 146 zeros, filter, keep 1 in 160
    s = 0.0
    for j in range(-c, c + 1):
        i = n * M - j                               # in-between sample index
        if i % L == 0:
            s += g[j + c] * xs[i // L + X0]
        else:
            s += g[j + c] * 0.0
    return s
cd = [rate_pp(n) for n in range(4410)]
d_rate = max(abs(cd[n] - rate_literal(n)) for n in range(25))
lin = []
for n in range(4410):                               # the shortcut: draw straight lines
    k, r = divmod(n * M, L)
    lin.append(xs[k + X0] * (L - r) / L + xs[k + 1 + X0] * r / L)
ideal = [add(a * sin(2 * pi * f * n / F2) for f, a in TONES[:3]) for n in range(4410)]
err_cd = max(abs(a - b) for a, b in zip(cd, ideal))
for name, sig in (("one low-pass", cd), ("straight lines", lin)):
    print(f"{name}: " + ", ".join(f"{f} Hz {amp(sig, f, F2):.4f}" for f in (440, 3000, 15000, 11100, 19100)))
a21 = amp(cd, fold(23000, F2), F2)
show(f"one low-pass: {fold(23000, F2)} Hz alias, millionths, measured", f"{a21 * 1e6:.4f}")
show("  0.1 x filter gain at 23 kHz, predicted", f"{0.1 * resp(g, c, 23000, FH, L) * 1e6:.4f}")
show("  the alias in decibels below 0.1", f"{db(a21 / 0.1):.1f}")
sinc2 = lambda f: (sin(pi * f / FS) / (pi * f / FS)) ** 2
al = amp(lin, 21100, F2)
show("straight lines: 21100 Hz alias, measured", f"{al:.5f}")
show("  0.1 x triangle gain at 23 kHz, predicted", f"{0.1 * sinc2(23000):.5f}")
GRID = [0, 4000, 8000, 12000, 16000, 18000, 20000, 21000, 22050, 23000, 24000]
print("low-pass gain in dB at " + ", ".join(f"{f // 1000}k" if f % 1000 == 0 else f"{f / 1000}k" for f in GRID) + ":")
print("  " + ", ".join(f"{db(resp(g, c, f, FH, L)):.1f}".replace("-0.0", "0.0") for f in GRID))
show("worst error vs the ideal 44.1 kHz recording, millionths", f"{err_cd * 1e6:.4f}")
show("multiplies per 44.1 kHz sample: literal", f"{M * len(g)}")
show("multiplies per 44.1 kHz sample: polyphase", f"{-(-len(g) // L)}")
assert [f for f, a in found] == sorted([440, 3000, fold(15000, 16000), fold(23000, 16000)])
assert abs(a1k - 0.1 * resp(g3, c3, 15000, FS, 1)) < 1e-12 and a1k < 1e-6
assert abs(a7k - 0.1 * resp(g3, c3, 9000, FS, 1)) < 1e-12 and a7k < 1e-5
assert abs(al - 0.1 * sinc2(23000)) < 1e-5 and a21 < 1e-4
assert abs(a21 - 0.1 * resp(g, c, 23000, FH, L)) < 1e-12
assert d_up < 1e-12 and d_rate < 1e-12 and err_rt < 0.01 and err_cd < 0.01
print("ALL CHECKS PASS")
