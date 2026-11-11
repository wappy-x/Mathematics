# Sampling and the Nyquist theorem -- the check behind the card.  Standard library only.
# A 15 kHz tone sampled 20,000 times a second returns as 5 kHz.  Four roads to that 5 kHz:
# the folding formula; the samples compared one by one; a brute-force search of the
# samples' spectrum; the sinc sum rebuilding the wave between samples.  Then the filter
# that must go before the converter, sized by formula and by its poles.
import math

def rnd(x): return math.floor(x + 0.5)                  # round half up, the same in both languages
def fold(f, fs): return abs(f - fs * rnd(f / fs))       # frequency heard, between 0 and fs/2
def signed(f, fs): return f - fs * rnd(f / fs)          # negative: the pattern turns backwards
def clean(v, d): return 0.0 if abs(v) < 0.5 * 10 ** -d else v
def row(label, vals, d): print(label + " " + " ".join(f"{clean(v, d):.{d}f}" for v in vals))

def atten_formula(ratio, n):                            # Butterworth loss in dB, ratio = f / corner
    return 10 * math.log10(1 + ratio ** (2 * n))

def atten_poles(ratio, n):                              # the same loss from distances to the n poles
    gain = 1.0
    for k in range(1, n + 1):
        ang = math.pi * (2 * k + n - 1) / (2 * n)       # poles on a half circle, left half plane
        gain /= math.hypot(-math.cos(ang), ratio - math.sin(ang))
    return -20 * math.log10(gain)

def order_formula(A, ratio):
    return math.ceil(math.log10(10 ** (A / 10) - 1) / (2 * math.log10(ratio)))

def order_search(A, ratio):                             # smallest n whose poles give A dB
    n = 1
    while atten_poles(ratio, n) < A: n += 1
    return n

# ---- the example: 15 kHz tone, 20 kHz sampling (kHz and milliseconds throughout) ----
fs, f, N = 20.0, 15.0, 400
print(f"spacing T = {1000 / fs:.1f} us; Nyquist frequency fs/2 = {fs / 2:.1f} kHz; Nyquist rate of the tone 2f = {2 * f:.1f} kHz")
alias = fold(f, fs)
print(f"road 1, folding: |{f:.0f} - {fs:.0f} x {rnd(f / fs)}| = {alias:.2f} kHz")
print(f"angle turned per sample: 15 kHz {360 * f / fs:.0f} deg, the same point as {360 * f / fs - 360:.0f}; 5 kHz {360 * alias / fs:.0f} deg")
x15 = [math.cos(2 * math.pi * f * n / fs) for n in range(N)]
x5 = [math.cos(2 * math.pi * alias * n / fs) for n in range(N)]
gap = max(abs(a - b) for a, b in zip(x15, x5))
flip = max(abs(math.sin(2 * math.pi * f * n / fs) + math.sin(2 * math.pi * alias * n / fs)) for n in range(N))
small = lambda v: "below 1e-9" if v < 1e-9 else f"{v:.3f}"
print(f"road 2, {N} samples: largest gap, 15 vs 5 kHz cosine, {small(gap)}; sine 15 plus sine 5, {small(flip)}")
row("first samples, 15 kHz cosine", x15[:5], 2)
best, peak = 0.0, -1.0
for i in range(201):                                    # 0 to 10 kHz in 50 Hz steps
    g = 0.05 * i
    re = sum(x * math.cos(2 * math.pi * g * n / fs) for n, x in enumerate(x15))
    im = sum(x * math.sin(2 * math.pi * g * n / fs) for n, x in enumerate(x15))
    amp = 2 * math.hypot(re, im) / N
    if amp > peak: best, peak = g, amp
print(f"road 3, spectrum of the samples, 0 to 10 kHz: peak at {best:.2f} kHz, amplitude {peak:.3f}")
M = 50000                                               # sinc terms each side of t = 0
rebuilt = []
for u in (0.25, 0.75, 1.6):                             # times in sample spacings
    s = sum((-1) ** (n % 2) * math.cos(2 * math.pi * f * n / fs) / (math.pi * (u - n)) for n in range(-M, M + 1)) * math.sin(math.pi * u)
    t = u / fs
    rebuilt.append((u, s, math.cos(2 * math.pi * alias * t), math.cos(2 * math.pi * f * t)))
    print(f"road 4, sinc sum at t = {1000 * t:6.2f} us: rebuilt {s:.5f}; 5 kHz {rebuilt[-1][2]:.5f}; 15 kHz {rebuilt[-1][3]:.5f}")
edge = max(abs(math.sin(2 * math.pi * 10.0 * n / fs)) for n in range(N))
print(f"10 kHz sine sampled at exactly 20 kHz: largest sample {edge:.6f}")
print("fold at 20 kHz: " + ", ".join(f"{g:.0f} -> {fold(g, fs):.0f}" for g in (9, 11, 15, 19, 21, 25, 35)))

# ---- the filter before the converter: keep 0-5 kHz, crush what folds onto it by 60 dB ----
fp, A = 5.0, 60.0
stop = fs - fp
n7, n7s = order_formula(A, stop / fp), order_search(A, stop / fp)
print(f"filter: pass to {fp:.0f} kHz, stop from fs - fp = {stop:.0f} kHz, ratio {stop / fp:.0f}, {A:.0f} dB = height / {10 ** (A / 20):.0f}")
print(f"  order by formula {n7} ({math.log10(10 ** (A / 10) - 1) / (2 * math.log10(stop / fp)):.3f} rounded up), by pole search {n7s}; loss at {stop:.0f} kHz: order 6 {atten_poles(3, 6):.2f} dB, order 7 {atten_poles(3, 7):.2f} dB")
print(f"  loss at the {fp:.0f} kHz band edge {atten_poles(1, 7):.2f} dB, amplitude {10 ** (-atten_poles(1, 7) / 20):.4f}")
print(f"  15 kHz tone after the order-7 filter: amplitude {10 ** (-atten_poles(3, 7) / 20):.6f}, still heard at {alias:.0f} kHz")
print(f"  sized at the Nyquist frequency instead, 60 dB at 10 kHz: order {order_formula(A, 10 / fp)}")

# ---- the house example: a ten second guitar chord at 44.1 kHz ----
fh, ph = 44.1, 20.0
Ah = 20 * math.log10(2 ** 16)                           # one step of a 16-bit converter
print(f"guitar: {round(10 * fh * 1000)} samples in 10 s; Nyquist {fh / 2:.2f} kHz; stop edge {fh - ph:.1f} kHz; {Ah:.2f} dB")
print(f"  top E string 329.63 Hz: harmonics below Nyquist {math.floor(fh / 2 / 0.32963)}; a 30 kHz pick click returns at {fold(30, fh):.1f} kHz")
orders = []
for m in (1, 2, 4, 8):
    r = (m * fh - ph) / ph
    orders.append((order_formula(Ah, r), order_search(Ah, r)))
    print(f"  sampling {m} x 44.1 = {m * fh:6.1f} kHz: stop edge {m * fh - ph:6.1f} kHz, order {orders[-1][0]} (pole search {orders[-1][1]})")
print(f"phone: 8 kHz sampling, 3.4 kHz kept, stop edge {8 - 3.4:.1f} kHz; film: 22 turns/s at 24 frames/s looks like {signed(22, 24):.0f}")
print(f"try: 25 kHz -> {fold(25, fs):.0f}; 19 kHz -> {fold(19, fs):.0f}; 15 kHz at 40 kHz -> {fold(15, 40):.0f}; 90 dB needs order {order_formula(90, 3)}; fs 40: Nyquist {40 / 2:.0f} kHz, stop edge {40 - fp:.0f} kHz, order {order_formula(A, (40 - fp) / fp)}")
row("chart, true kHz", [2.5 * i for i in range(17)], 1)
row("chart, heard kHz", [fold(2.5 * i, fs) for i in range(17)], 1)
row("chart, time us", [6.25 * i for i in range(33)], 2)
row("chart, 15 kHz wave", [math.cos(2 * math.pi * f * 6.25e-3 * i) for i in range(33)], 2)
row("chart, 5 kHz wave", [math.cos(2 * math.pi * alias * 6.25e-3 * i) for i in range(33)], 2)

assert alias == 5.0 and abs(best - alias) < 1e-9 and abs(peak - 1) < 1e-9, "spectrum search must find the folded tone"
assert gap < 1e-9 and flip < 1e-9, "15 and 5 kHz must give the same samples"
assert all(abs(s - c5) < 1e-4 and abs(s - c15) > 0.1 for _, s, c5, c15 in rebuilt), "sinc rebuild must give 5 kHz"
assert all(abs(atten_poles(r, n) - atten_formula(r, n)) < 1e-7 for r in (1, 2, 3, 7.82) for n in range(1, 61))
assert n7 == n7s == 7 and atten_poles(3, 6) < A <= atten_poles(3, 7), "order 7 is the smallest that reaches 60 dB"
assert all(a == b for a, b in orders) and [a for a, _ in orders] == [60, 10, 6, 4], "house orders by both roads"
assert edge < 1e-9, "a sine at exactly fs/2 is sampled at its zeros"
print("ALL CHECKS PASS")
