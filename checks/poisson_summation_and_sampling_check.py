# Poisson summation and sampling -- the check behind the card.  Standard library only.
# A click f(t) = 1/(1 + (t/a)^2), half height 25 microseconds either side of its peak,
# sampled 48,000 times a second.  Its transform is pi a exp(-2 pi a |xi|), xi in hertz.
# Roads: the sum of samples, the sum of spectrum values at the copy positions, and the
# closed form pi b coth(pi b); the sampled spectrum by brute force, by adding copies, and
# by a geometric series; the sinc rebuild against the integral of the copies; a tone
# folded by formula, by comparing samples and by a spectrum search; and the shutter's
# gate, where the theorem's hypothesis fails.
import math

A, FS = 25e-6, 48000.0               # click half-width (s); sampling rate (samples/s)
T, b = 1 / FS, A * FS                # sample spacing (s); b = a / T, a dimensionless width
C = 2 * math.pi * A                  # decay rate of the transform, seconds
def f(t): u = t / A; return 1 / (1 + u * u)
def fhat(xi): return math.pi * A * math.exp(-C * abs(xi))
def sinc(u): return 1.0 if u == 0 else math.sin(math.pi * u) / (math.pi * u)
def clean(v): return 0.0 if abs(v) < 5e-13 else v
def us(v): return f"{v * 1e6:.6f}"
def total(vals):                     # plain left-to-right sum, as in the Rust twin
    s = 0.0
    for v in vals: s += v
    return s

print(f"click a = 25 us, fs = 48000 Hz, T = {us(T)} us, b = a/T = {b:.6f}")
print("-- Poisson summation: sum of samples = fs * sum of transform at k fs")
closed = math.pi * b / math.tanh(math.pi * b)
for n_max in (10, 1000, 100000):
    s = 1 + 2 * total(f(n * T) for n in range(1, n_max + 1))
    bound = 2 * b * b / n_max         # sum over |n| > N of b^2/n^2 is below 2 b^2 / N
    print(f"samples |n|<={n_max}: {s:.9f}  tail bound {bound:.12f}  gap {closed - s:.12f}")
    assert 0 < closed - s < bound
for k_max in (0, 1, 3):
    c = FS * total(fhat(k * FS) for k in range(-k_max, k_max + 1))
    print(f"copies |k|<={k_max}: {c:.11f}")
print(f"closed form pi b coth(pi b): {closed:.11f}")
assert abs(c - closed) < 1e-12
k0 = FS * fhat(0)
print(f"copy at 48 kHz adds {FS * fhat(FS):.9f} on each side; without the copies: {k0:.9f}")

print("-- copies: T * sum f(nT) cos(2 pi xi n T) = sum over k of fhat(xi - k fs)")
q = math.exp(-C * FS)
def s_closed(xi): return math.pi * A * (math.exp(-C * xi) + math.exp(-C * (FS - xi))) / (1 - q)
def s_copies(xi): return total(fhat(xi - k * FS) for k in range(-20, 21))
N = 100000
for xi in (0.0, 12000.0, 24000.0):
    brute = T * (1 + 2 * total(f(n * T) * math.cos(2 * math.pi * xi * n * T) for n in range(1, N + 1)))
    tail = T * 2 * b * b / N
    print(f"xi {xi:.0f} Hz: fhat {us(fhat(xi))}  samples {us(brute)} (tail < {us(tail)})"
          f"  copies {us(s_copies(xi))}  closed {us(s_closed(xi))}  ratio {s_closed(xi) / fhat(xi):.6f}")
    assert abs(brute - s_closed(xi)) < tail and abs(s_copies(xi) - s_closed(xi)) < 1e-15
grid = [6000.0 * j for j in range(9)]
print("chart xi kHz: " + ", ".join(f"{g / 1000:.0f}" for g in grid))
print("chart fhat:   " + ", ".join(f"{fhat(g) * 1e6:.2f}" for g in grid))
print("chart copy:   " + ", ".join(f"{fhat(g - FS) * 1e6:.2f}" for g in grid))
print("chart sum:    " + ", ".join(f"{s_closed(g) * 1e6:.2f}" for g in grid))

print("-- rebuild halfway between samples, t = T/2, by the sinc sum")
t = T / 2
rebuilt = total(f(n * T) * sinc(t / T - n) for n in range(-N, N + 1))
m = 4000                              # Simpson on 0..fs/2 of 2 S(xi) cos(2 pi xi t)
h = (FS / 2) / m
w = [1 if j in (0, m) else (4 if j % 2 else 2) for j in range(m + 1)]
integral = h / 3 * total(w[j] * 2 * s_closed(j * h) * math.cos(2 * math.pi * j * h * t) for j in range(m + 1))
bound = 2 * math.exp(-math.pi * b)    # twice the transform's area beyond fs/2
print(f"true f(T/2) {f(t):.6f}  sinc sum {rebuilt:.6f}  integral of copies {integral:.6f}")
print(f"error {rebuilt - f(t):.6f}  bound 2 exp(-pi b) {bound:.6f}  ratio {(rebuilt - f(t)) / bound:.6f}")
assert abs(rebuilt - integral) < 1e-4 and abs(rebuilt - f(t)) < bound

print("-- a 30 kHz tone sampled at 48 kHz")
f0 = 30000.0
alias = abs(f0 - FS * math.floor(f0 / FS + 0.5))
diff = max(abs(math.cos(2 * math.pi * f0 * n * T) - math.cos(2 * math.pi * alias * n * T)) for n in range(48))
best, peak = 0.0, -1.0
for freq in range(0, 24001, 1000):        # 48 samples = 1 ms, so 1 kHz steps are exact bins
    re = total(math.cos(2 * math.pi * f0 * n * T) * math.cos(2 * math.pi * freq * n * T) for n in range(48))
    im = total(math.cos(2 * math.pi * f0 * n * T) * math.sin(2 * math.pi * freq * n * T) for n in range(48))
    amp = 2 * math.hypot(re, im) / 48
    if amp > peak: best, peak = freq, amp
print(f"fold formula {alias:.0f} Hz  largest sample gap to 18 kHz {clean(diff):.6f}"
      f"  spectrum peak {best} Hz height {peak:.6f}")
assert best == alias and diff < 1e-9
print(f"same tone at 44100: heard at {abs(f0 - 44100 * math.floor(f0 / 44100 + 0.5)):.0f} Hz")
print("-- a band away from zero, 40 to 48 kHz, sampled at 16 kHz: twice the band's width")
fb = 16000.0
tones = [40500.0 + 1000.0 * j for j in range(8)]
heard = [abs(x - fb * math.floor(x / fb + 0.5)) for x in tones]
gap_b = max(abs(math.cos(2 * math.pi * x * n / fb) - math.cos(2 * math.pi * y * n / fb)) for x, y in zip(tones, heard) for n in range(16))
print("tones kHz " + ", ".join(f"{x / 1000:.1f}" for x in tones) + "  heard at " + ", ".join(f"{y / 1000:.1f}" for y in heard)
      + f"  largest sample gap {gap_b:.6f}")
assert len(set(heard)) == len(tones) and max(heard) < fb / 2 and gap_b < 1e-9   # each tone lands in a place of its own

print("-- shutter gate, open 0 to 1 ms, read every 1 ms (units: ms and kHz)")
M = 1000
def gate(t, edge):                   # 1 while open, 0 outside, the value `edge` at the two jumps
    return edge if t in (0, 1) else (1.0 if 0 < t < 1 else 0.0)
def gate_hat(k):                     # transform at k kHz by the midpoint rule on -1..2 ms
    ts = [(j + 0.5) / M for j in range(-M, 2 * M)]
    re = total(gate(t, 1.0) * math.cos(2 * math.pi * k * t) for t in ts) / M
    im = -total(gate(t, 1.0) * math.sin(2 * math.pi * k * t) for t in ts) / M
    return re, im
hats = {k: gate_hat(k) for k in range(-5, 6)}
side = total(hats[k][0] for k in hats)
shift = total(hats[k][0] * math.cos(math.pi * k) - hats[k][1] * math.sin(math.pi * k) for k in hats)
closed_s, mid_s = (total(gate(n, e) for n in range(-5, 6)) for e in (1.0, 0.5))
shift_s = total(gate(n + 0.5, 1.0) for n in range(-5, 6))
print(f"transform at 1 kHz {clean(hats[1][0]):.6f} {clean(hats[1][1]):.6f}  transform side |k|<=5 {side:.6f}")
print(f"samples, gate closed at both ends: {closed_s:.6f}   with 1/2 at each jump: {mid_s:.6f}")
print(f"grid shifted by 0.5 ms: samples {shift_s:.6f}  transform side {shift:.6f}")
assert abs(side - 1) < 1e-9 and abs(shift - 1) < 1e-9   # the exact transform: 1 at 0 kHz, 0 at other whole kHz
assert abs(closed_s - side - 1) < 1e-9                  # a jump on the grid: the samples exceed the transform side by 1
assert abs(mid_s - side) < 1e-9 and abs(shift_s - shift) < 1e-9   # midpoint values, or a shifted grid: equal
print("ALL CHECKS PASS")
